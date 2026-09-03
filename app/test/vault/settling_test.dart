import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 5, round nine — "voice doesn't get saved".**
///
/// > *"I am recording the voice ↓ someone enters my room I close the app ↓
/// > voice doesn't get saved! I want you to save the voice!"*
///
/// Round eight shipped a fix for this — backgrounding stops the recorder and
/// saves — and he is reporting the same loss two rounds later. The fix was
/// real; it simply never got to run against an open vault.
///
/// Android reports leaving as three states in a row, `inactive` → `hidden` →
/// `paused`. `app.dart` locks on **hidden**; the recording sheet saved on
/// **paused**. By the time the save ran, the database was closed and the keys
/// were destroyed, so it failed deterministically. Two pieces of correct code,
/// each unaware of the other's timing.
///
/// The recording settles at `inactive` now, and — because settling is a stream
/// to close and a row to write, and `hidden` follows within a frame or two —
/// the lock waits for it. These tests are about that wait, and specifically
/// about the two ways it could be wrong:
///
///   * it does not wait at all, and the bug is back; or
///   * it waits **too long**, and lock-on-background has quietly been turned
///     into lock-eventually-on-background, which is the one property
///     `UX-FLOWS.md` flow 7 calls non-negotiable and the only symptom would be
///     a vault that stays open a bit longer than anybody agreed to.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_settle'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Vault> open() async {
    final v = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await v.initialise();
    await v.create(passcode: 'a passphrase');
    return v;
  }

  test('a write in flight finishes before the vault locks', () async {
    final v = await open();
    var finished = false;
    var lockedWhileWriting = false;

    final writing = v.whileSettling(() async {
      // Stands in for closing the encrypting stream and writing the duration
      // and waveform — a handful of awaits, not a backup.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (!v.isUnlocked) lockedWhileWriting = true;
      }
      finished = true;
    });

    // The app going into the background, which is the whole point: this
    // arrives *while* the save is running, not before or after it.
    final backgrounding = v.onBackgrounded();

    await writing;
    expect(finished, isTrue);
    expect(lockedWhileWriting, isFalse,
        reason: 'the vault was pulled out from under a write it knew about — '
            'which is exactly what lost the recording');

    await backgrounding;
    expect(v.isUnlocked, isFalse, reason: 'and then it locks, as it must');
  });

  // ══ THE COMPOSER'S LAST SENTENCE. `PLAN.md` §7.0-E ══════════════════════
  //
  // "Write-ahead the composer — so an OS kill mid-sentence loses nothing."
  //
  // The composer autosaves every 400 ms, so what a *kill* can cost is bounded
  // and small — `crash_safety_test.dart` group 1 proves a committed write
  // survives a database that was never closed. What was not bounded, and was
  // losing words on **every ordinary exit**, is this: the flush on `inactive`
  // was `unawaited`, the database has been on a worker isolate since 25
  // August, and `hidden` — where the lock happens — follows within a frame or
  // two. It is round nine's ISSUE 5 in the composer rather than the recorder,
  // and it looked like never having typed the words rather than like a bug.
  test("the composer's last words are waited for, like a recording", () async {
    final v = await open();
    var landed = false;
    var lockedMidWrite = false;

    // What `day_screen.didChangeAppLifecycleState` now does on `inactive`:
    // the flush and the in-place editor's flush, together, inside one hold.
    final flushing = v.whileSettling(() async {
      // A round trip to the worker isolate, twice — the draft and the editor.
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (!v.isUnlocked) lockedMidWrite = true;
      }
      landed = true;
    });

    // `hidden`, a frame later.
    final backgrounding = v.onBackgrounded();

    await flushing;
    expect(landed, isTrue);
    expect(lockedMidWrite, isFalse,
        reason: 'the keys were destroyed while the last sentence was still '
            'being written — which is what an unawaited flush did on every '
            'single exit');

    await backgrounding;
    expect(v.isUnlocked, isFalse,
        reason: 'and it still locks. Lock-on-background is non-negotiable and '
            'this must not have quietly become lock-eventually');
  });

  test('it locks anyway if the write never finishes', () async {
    // A recorder that has hung, a stream that never closes. The vault must not
    // stay open because something forgot to come back — a hold that can be
    // held for ever is not a bounded concession, it is a way to disable
    // locking, and it would be reachable by accident.
    final v = await open();
    final never = Completer<void>();
    unawaited(v.whileSettling(() => never.future));

    final started = DateTime.now();
    await v.onBackgrounded();
    final waited = DateTime.now().difference(started);

    expect(v.isUnlocked, isFalse,
        reason: 'a stuck write held the vault open indefinitely');
    // Four seconds is the cap. Ten is generous room for a slow machine while
    // still failing loudly if somebody removes the timeout.
    expect(waited, lessThan(const Duration(seconds: 10)));
    never.complete();
  });

  test('nothing in flight means no delay at all', () async {
    final v = await open();
    final started = DateTime.now();
    await v.onBackgrounded();
    expect(v.isUnlocked, isFalse);
    expect(DateTime.now().difference(started),
        lessThan(const Duration(milliseconds: 500)),
        reason: 'the ordinary case must not pay for the rare one');
  });

  test('several writes at once are all waited for, once', () async {
    // Two attachments finishing together — a photograph importing while a
    // recording stops. The counter has to be a counter and not a flag, or the
    // first one to finish releases the second one's protection.
    final v = await open();
    var done = 0;

    final a = v.whileSettling(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      done++;
    });
    final b = v.whileSettling(() async {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(v.isUnlocked, isTrue,
          reason: 'the shorter write released the longer one');
      done++;
    });

    await v.onBackgrounded();
    await Future.wait([a, b]);
    expect(done, 2);
    expect(v.isUnlocked, isFalse);
  });

  test('a write that throws still releases the hold', () async {
    final v = await open();
    await expectLater(
      v.whileSettling(() async => throw const FormatException('nope')),
      throwsA(isA<FormatException>()),
    );

    final started = DateTime.now();
    await v.onBackgrounded();
    expect(DateTime.now().difference(started),
        lessThan(const Duration(milliseconds: 500)),
        reason: 'a failed save left the vault holding itself open');
    expect(v.isUnlocked, isFalse);
  });
}
