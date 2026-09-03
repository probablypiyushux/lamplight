import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Making a stolen phone expensive to guess at.
///
/// ── WHY ARGON2ID IS NOT ALREADY ENOUGH ───────────────────────────────────
///
/// It very nearly is. Each guess costs a quarter of a second and 256 MiB, which
/// makes a dictionary attack against a decent passphrase hopeless. What it does
/// not defend against is the **shoulder-surfing partner** — the adversary
/// `THREAT-MODEL.md` ranks most likely — who has seen most of the passcode and
/// needs a few dozen tries to fill in the rest. A quarter of a second each is
/// nothing to that person.
///
/// So attempts back off. Ten free, then a wait that doubles, capped at five
/// minutes. Somebody who knows the passcode never meets it; somebody guessing
/// gets 12 attempts in the first minute and about 40 in the first hour.
///
/// ── WHAT THIS DELIBERATELY DOES NOT DO ───────────────────────────────────
///
/// **It does not wipe the vault after N failures.** That feature exists in
/// other apps and it is wrong here, for a reason that is specific to what this
/// app is rather than to security in general:
///
///   * The thing being protected is *a record of a life*, and it cannot be
///     re-downloaded from anywhere. `PLAN.md` §1: "losing it must be
///     impossible — not unlikely, impossible."
///   * The realistic trigger is not an attacker. It is a child with the phone,
///     a pocket, or the owner themselves on a bad morning.
///   * And it does not work. Anyone capable of an offline attack copies
///     `/data/data` first and attacks the copy, where no counter exists. A
///     wipe-on-failure only ever fires on the honest user.
///
/// The delay is honest about this too: it is enforced by the app, so an
/// attacker with a rooted phone can delete the file below and reset it. That
/// is fine. **The delay is not what protects the vault** — Argon2id is. This
/// is a speed bump for the person holding the phone in their hand, which is
/// exactly the adversary it is aimed at, and it makes no claim beyond that.
///
/// ── WHY IT IS ON DISK ────────────────────────────────────────────────────
///
/// A counter in memory is reset by force-quitting the app, which takes two
/// seconds and is the first thing anybody tries. On disk it survives that. The
/// file holds two integers and reveals nothing: how many times somebody has got
/// the passcode wrong is not information about what is in the vault.
class AttemptLimiter {
  AttemptLimiter(this._file);

  final File _file;

  int _failures = 0;
  DateTime? _lastFailure;

  /// Free attempts before any wait at all.
  ///
  /// Ten, which is generous on purpose. A long passphrase typed on a phone
  /// keyboard goes wrong honestly, often, and the person it goes wrong for is
  /// the owner. Making the first mistake cost a wait would punish the only
  /// person who is definitely not an attacker.
  static const int _free = 10;

  static const Duration _base = Duration(seconds: 5);
  static const Duration _ceiling = Duration(minutes: 5);

  Future<void> load() async {
    try {
      if (!await _file.exists()) return;
      final data = jsonDecode(await _file.readAsString());
      if (data is! Map) return;
      _failures = (data['failures'] as int?) ?? 0;
      final ms = data['lastFailure'];
      _lastFailure = ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    } catch (_) {
      // A damaged counter file means no delay, which is the safe direction to
      // fail: the alternative is a corrupt file locking the owner out of their
      // own notes forever, and that is a far worse outcome than a few free
      // guesses for an attacker who is already up against Argon2id.
    }
  }

  /// How long before another attempt is allowed. Zero means now.
  Duration get wait {
    if (_failures <= _free) return Duration.zero;
    final at = _lastFailure;
    if (at == null) return Duration.zero;
    final penalty = _penaltyFor(_failures);
    final elapsed = DateTime.now().difference(at);
    final left = penalty - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isWaiting => wait > Duration.zero;

  int get failures => _failures;

  /// Doubles per failure past the free ones, capped.
  static Duration _penaltyFor(int failures) {
    final over = failures - _free;
    if (over <= 0) return Duration.zero;
    // 5s, 10s, 20s, 40s … capped at five minutes. `min` on the exponent as
    // well as on the result, so a very large counter cannot overflow the
    // multiplication on the way to being clamped.
    final steps = math.min(over - 1, 20);
    final ms = _base.inMilliseconds * math.pow(2, steps).toInt();
    return Duration(milliseconds: math.min(ms, _ceiling.inMilliseconds));
  }

  Future<void> recordFailure() async {
    _failures++;
    _lastFailure = DateTime.now();
    await _save();
  }

  /// A correct passcode clears everything. It is the only thing that does.
  Future<void> recordSuccess() async {
    if (_failures == 0) return;
    _failures = 0;
    _lastFailure = null;
    await _save();
  }

  Future<void> _save() async {
    try {
      await _file.parent.create(recursive: true);
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(
        jsonEncode({
          'failures': _failures,
          'lastFailure': _lastFailure?.millisecondsSinceEpoch,
        }),
        flush: true,
      );
      // Rename is atomic, so being killed mid-write leaves the old counter
      // rather than a truncated file that fails to parse.
      await tmp.rename(_file.path);
    } catch (_) {
      // Same reasoning as `load`. A counter that cannot be written is a
      // counter that does not delay anybody, which is the direction to fail in.
    }
  }
}
