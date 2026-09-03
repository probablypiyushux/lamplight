import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/platform/biometrics.dart';
import '../../core/security/attempt_limiter.dart';
import '../../core/plain_words.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/lamp_mark.dart';
import '../../design/tokens.dart';
import '../backup/silent_backup.dart';

/// The lock screen.
///
/// **The app mark and a passcode field, centred, and nothing else.** No
/// preview, no counts, no "3,847 entries". `03-product/UX-FLOWS.md` flow 7 is
/// explicit: the lock screen should reveal that the app exists and not one
/// thing more. Anything else here is a gift to the person holding someone
/// else's phone.
///
/// The one thing it does say out loud is what to do when the passcode is gone,
/// because the alternative — a person who has forgotten it and does not know
/// the twelve words are an option — is someone who loses everything while
/// holding the thing that would have opened it.
///
/// ── THREE STATES, THREE DIFFERENT MOTIONS ────────────────────────────────
///
/// Waiting, working and refused used to look almost identical, and the middle
/// one is the expensive mistake: unlocking runs Argon2id over 256 MiB, so a
/// correct passcode and a wrong one both produce a pause, and the screen said
/// the same thing during both. Now:
///
///   * **waiting** — the mark is lit and still.
///   * **working** — a heartbeat. Alive, unhurried, obviously not frozen. And
///     since the derivation moved to a worker isolate it genuinely keeps
///     beating, which it could not do before: the beat and the work were on
///     the same thread, so the animation froze exactly when it was needed.
///   * **refused** — the whole card shakes once, with a heavy haptic. The same
///     gesture a head makes. You do not have to read it, or even be looking.
///
/// ── THE BUG THAT WAS REPORTED ────────────────────────────────────────────
///
/// *"When the passcode is empty it still shows the unlock option, and when it
/// is pressed it says: this passcode does not open the vault."*
///
/// Exactly right, and it is a worse bug than it looks. The app took an empty
/// string, spent a quarter of a second running Argon2id on it, failed to
/// unwrap, and then told the user their passcode was **wrong** — when what had
/// actually happened is that they had not typed one. Being told you got
/// something wrong when you have not attempted it is the kind of small lie that
/// makes a person distrust everything else the screen says.
///
/// The button is disabled with nothing in the field. Not hidden — a control
/// that vanishes is a control the user has to rediscover — greyed, so it is
/// visible, obviously not ready, and says why underneath.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.vault,
    required this.settings,
    required this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;

  /// Here for one reason: this screen is one of the only two places in the app
  /// where a passcode exists, and a silent backup needs a key derived from it.
  /// The derivation happens the moment the unlock succeeds and the passcode is
  /// then dropped, so nothing else ever has to hold it.
  final SilentBackup silentBackup;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passcode = TextEditingController();
  final _phrase = TextEditingController();
  bool _busy = false;
  bool _usePhrase = false;
  String? _error;

  /// Bumped on every refusal, which is what drives the shake. A counter rather
  /// than a flag so two wrong passcodes in a row shake twice.
  int _refusals = 0;

  bool _biometricOffered = false;

  late final AttemptLimiter _limiter =
      AttemptLimiter(File('${widget.vault.root.path}/attempts.json'));

  /// Redraws the countdown while a wait is running.
  Timer? _tick;

  /// Whether there is anything in the field. Its own notifier so a keystroke
  /// does not rebuild the whole screen.
  final _hasInput = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _passcode.addListener(_onTyped);
    _phrase.addListener(_onTyped);
    _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _passcode.dispose();
    _phrase.dispose();
    _hasInput.dispose();
    super.dispose();
  }

  void _onTyped() {
    _hasInput.value = _usePhrase
        ? _phrase.text.trim().isNotEmpty
        : _passcode.text.isNotEmpty;
  }

  Future<void> _start() async {
    await _limiter.load();
    if (!mounted) return;
    if (_limiter.isWaiting) _startTicking();
    await _offerBiometrics();
  }

  void _startTicking() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (!_limiter.isWaiting) t.cancel();
      setState(() {});
    });
    setState(() {});
  }

  /// Tries the fingerprint straight away, if this vault has one.
  ///
  /// Offered rather than demanded: the prompt's negative button says "Use
  /// passcode", and dismissing it leaves the field focused and waiting. Nobody
  /// is ever stuck behind a fingerprint that will not read.
  ///
  /// **Unless they have asked it not to.** Settings → Fingerprint → *Ask as
  /// soon as Lamplight opens*, on by default. Off means the button is still
  /// there and nothing opens by itself, for anybody who finds a system dialog
  /// appearing unbidden more intrusive than useful.
  ///
  /// **ISSUE 19.** This used to be a five-minute *window* rather than a switch,
  /// and it was backwards: coming straight back was the case where the prompt
  /// was withheld, so returning quickly cost an extra tap. See
  /// `AppSettings.promptForFingerprint` for the whole story.
  Future<void> _offerBiometrics() async {
    if (!await widget.vault.hasBiometricWrapper) return;
    if (!mounted) return;
    setState(() => _biometricOffered = true);
    if (_limiter.isWaiting) return;
    if (!widget.settings.promptForFingerprint) return;
    await _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    setState(() => _error = null);
    try {
      await widget.vault.unlockWithBiometrics();
      // -- The automatic backup, on the path that never had one -----------
      //
      // 3 September 2026. This method opens the vault without ever seeing a
      // passcode, so it could not derive the backup key and did not ask for a
      // backup - and `_offerBiometrics` runs from `initState`, so on a phone
      // with a fingerprint this is the ordinary way in. The result was a
      // switch that said "on" and a last backup five days old.
      //
      // `recallKey` reads the copy kept sealed under the DEK at the last
      // passcode unlock. Awaited, because `maybeRun` checks for the key and
      // declines quietly when it is not there yet - which is exactly the bug
      // being fixed and would be trivially easy to reintroduce as a race.
      await widget.silentBackup.recallKey();
      widget.silentBackup.maybeRun().ignore();
      await _limiter.recordSuccess();
    } on BiometricInvalidated catch (e) {
      // The phone's fingerprints changed, so the keystore key was destroyed —
      // on purpose, so that somebody who adds their own finger inherits
      // nothing. Say so plainly; the passcode still works.
      if (mounted) {
        setState(() {
          _biometricOffered = false;
          // BiometricInvalidated says its own sentence, and it is one the user
          // is owed — their fingerprints changed and that is why this stopped
          // working. plainFailure lets it through unaltered.
          _error = plainFailure(e,
              fallback: L.of(context).lockFingerprintUnavailable,
              andThen: L.of(context).lockUseYourPasscode,
          words: L.of(context));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = plainFailure(e,
            fallback: L.of(context).lockFingerprintFailed,
            andThen: L.of(context).lockUseYourPasscode,
          words: L.of(context)));
      }
    }
  }

  Future<void> _unlock() async {
    // Never run the key derivation on nothing. See the class comment.
    if (_usePhrase
        ? _phrase.text.trim().isEmpty
        : _passcode.text.isEmpty) {
      return;
    }
    if (_limiter.isWaiting) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_usePhrase) {
        await widget.vault.unlockWithRecoveryPhrase(
          _phrase.text.trim().split(RegExp(r'\s+')),
        );
      } else {
        final passcode = _passcode.text;
        await widget.vault.unlockWithPasscode(passcode);
        // Derived here and only here, while the passcode is still in scope, and
        // kept as a key rather than as the passcode itself.
        //
        // Not done on the recovery-phrase path above: unlocking with the twelve
        // words does not tell us the passcode, and a backup sealed under
        // something the user does not think of as their passcode would be a
        // file they could never open. It resumes at the next normal unlock.
        await widget.silentBackup.rememberKey(passcode);
        widget.silentBackup.maybeRun().ignore();
      }
      await _limiter.recordSuccess();
      _passcode.clear();
      _phrase.clear();
    } on WrongSecret catch (e) {
      await _limiter.recordFailure();
      // Plain language, and it says what to do next. Never "authentication
      // error: invalid credentials" — ACCESSIBILITY.md, cognitive section.
      if (mounted) {
        setState(() {
          _error = e.message;
          _refusals++;
        });
        if (_limiter.isWaiting) _startTicking();
      }
    } catch (e) {
      await _limiter.recordFailure();
      if (mounted) {
        setState(() {
          _error = plainFailure(e,
              fallback: L.of(context).lockWrongPasscode,
              andThen: L.of(context).lockCheckAndRetry,
          words: L.of(context));
          _refusals++;
        });
        if (_limiter.isWaiting) _startTicking();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final waiting = _limiter.wait;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.x6, vertical: Space.x8),
            child: ConstrainedBox(
              // A form, not a page — see the note on `Layout.maxForm`. It was
              // the same number written as a literal; it is a token now, so the
              // lock screen and onboarding cannot drift apart.
              constraints: const BoxConstraints(maxWidth: Layout.maxForm),
              // Everything shakes together — mark, field and message as one
              // card, the way a physical thing would.
              child: LampShake(
                trigger: _refusals,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LampMark(size: 88)),
                    const SizedBox(height: Space.x5),
                    Text(L.of(context).appName,
                        style: t.displaySmall, textAlign: TextAlign.center),
                    const SizedBox(height: Space.x10),

                    if (!_usePhrase)
                      LampPasscodeField(
                        controller: _passcode,
                        hint: 'Passcode',
                        autofocus: true,
                        enabled: !_busy && waiting == Duration.zero,
                        onSubmitted: (_) => _unlock(),
                      )
                    else
                      TextField(
                        controller: _phrase,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        maxLines: 3,
                        style: t.bodyLarge,
                        decoration: InputDecoration(
                          hintText: L.of(context).lockPhraseHint,
                          hintStyle: TextStyle(color: c.inkMuted),
                          filled: true,
                          fillColor: c.surface,
                          contentPadding: const EdgeInsets.all(Space.x4),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.sm),
                            borderSide: BorderSide(color: c.borderStrong),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.sm),
                            borderSide: BorderSide(color: c.accent, width: 2),
                          ),
                        ),
                      ),

                    if (_error != null) ...[
                      const SizedBox(height: Space.x4),
                      LampError(message: _error!),
                    ],

                    const SizedBox(height: Space.x6),

                    if (_busy)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: Space.x2),
                        child: LampBusy(label: L.of(context).lockOpening),
                      )
                    else if (waiting > Duration.zero)
                      _Cooldown(remaining: waiting)
                    else ...[
                      // The button, and the reason it is off.
                      ValueListenableBuilder<bool>(
                        valueListenable: _hasInput,
                        builder: (context, ready, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LampButton(
                              label: L.of(context).lockUnlock,
                              onPressed: ready ? _unlock : null,
                            ),
                            // Only while it is off, and only as a quiet line.
                            // A permanent hint under a working button is
                            // clutter; one that appears the moment the button
                            // is unusable is an explanation.
                            AnimatedSize(
                              duration: Motion.duration(context),
                              alignment: Alignment.topCenter,
                              child: ready
                                  ? const SizedBox(width: double.infinity)
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                          top: Space.x2),
                                      child: Text(
                                        _usePhrase
                                            ? L.of(context).lockTypeTwelveWords
                                            : L.of(context).lockTypePasscode,
                                        textAlign: TextAlign.center,
                                        style: t.labelMedium
                                            ?.copyWith(color: c.inkMuted),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      if (_biometricOffered && !_usePhrase) ...[
                        const SizedBox(height: Space.x3),
                        Center(
                          child: TextButton.icon(
                            onPressed: _tryBiometrics,
                            icon: const Icon(Icons.fingerprint, size: 22),
                            label: Text(L.of(context).lockUseFingerprint),
                            style:
                                TextButton.styleFrom(foregroundColor: c.accent),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: Space.x3),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _usePhrase = !_usePhrase;
                                _error = null;
                              });
                              _onTyped();
                            },
                      child: Text(
                        _usePhrase
                            ? L.of(context).lockUsePasscodeInstead
                            : L.of(context).lockForgot,
                        style: TextStyle(color: c.inkSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The wait after too many wrong tries.
///
/// Says the number of seconds and counts it down, because a disabled button
/// with no explanation is indistinguishable from a broken one — and the person
/// most likely to be sitting in front of this is the owner, who has fat-fingered
/// a long passphrase eleven times and is already annoyed.
///
/// It does **not** say how many attempts are left, and that is deliberate:
/// a countdown of remaining tries is an invitation to a stranger to find out
/// what happens at zero, and here the answer is "nothing, it just gets slower".
/// Saying so would be worse than saying nothing.
class _Cooldown extends StatelessWidget {
  const _Cooldown({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final seconds = remaining.inSeconds + 1;
    // Both forms are plurals in the ARB rather than a `?:` on `== 1`, because
    // "one" is not a category every language has and several have more than
    // English does. See the note on Arabic's six forms in l10n/README.md.
    final text = seconds >= 60
        ? L.of(context).lockTryAgainMinutes((seconds / 60).ceil())
        : L.of(context).lockTryAgainSeconds(seconds);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.x4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          children: [
            Icon(Icons.hourglass_bottom, size: 20, color: c.inkSecondary),
            const SizedBox(height: Space.x2),
            Text(text,
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: c.inkSecondary)),
            const SizedBox(height: Space.x1),
            Text(
              L.of(context).lockNothingDeleted,
              textAlign: TextAlign.center,
              style: t.labelMedium?.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
