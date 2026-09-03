import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// "Never" has to mean never.
///
/// `UX-FLOWS.md` flow 7 offers a range from 15 seconds to never, and
/// `ACCESSIBILITY.md` insists the "never" end exists — a short timeout is a real
/// barrier for someone who types slowly, and an app that locks mid-sentence is
/// one you stop using.
///
/// It was written as `Duration.zero` and then handed to `Timer(_idleTimeout,
/// lock)`, which schedules a lock for the next tick. So the setting meant to
/// switch idle-locking off was in fact the most aggressive one available: the
/// vault sealed itself on the first keystroke after every unlock. It was found
/// by a widget test complaining about a pending timer, which is an odd route to
/// a bug this bad, so it gets its own test where someone will look for it.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_idle'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Vault> openVault({required Duration idle}) async {
    final v = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: idle,
    );
    await v.initialise();
    await v.create(passcode: 'a passphrase');
    return v;
  }

  test('Duration.zero means never, not immediately', () async {
    final v = await openVault(idle: Duration.zero);
    expect(v.isUnlocked, isTrue);

    // Activity, the way typing produces it.
    v.touch();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    v.touch();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(v.isUnlocked, isTrue,
        reason: 'the vault locked itself despite auto-lock being set to never');
    await v.lock();
  });

  test('a real timeout still locks', () async {
    // The other half. A test that only proved "never" works would pass just as
    // happily if idle locking had been removed altogether.
    final v = await openVault(idle: const Duration(milliseconds: 120));
    v.touch();
    expect(v.isUnlocked, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(v.isUnlocked, isFalse);
  });

  test('activity postpones it, and switching to never cancels it', () async {
    final v = await openVault(idle: const Duration(milliseconds: 200));
    v.touch();

    // Changing the setting mid-session is a thing people do the first time the
    // app locks on them, and it has to take effect without a restart.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    v.idleTimeout = Duration.zero;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(v.isUnlocked, isTrue,
        reason: 'a countdown started under the old setting was never cancelled');
    await v.lock();
  });

  test('backgrounding still locks, whatever auto-lock is set to', () async {
    // UX-FLOWS flow 7 calls this non-negotiable and not configurable. If
    // "never" ever switched this off too, the setting would become a way to
    // disable the single most effective defence in the threat model.
    final v = await openVault(idle: Duration.zero);
    await v.onBackgrounded();
    expect(v.isUnlocked, isFalse);
  });

  // ══ ISSUE 21 — "the app auto closes while I am watching at it" ═════════════
  //
  // *"A good feature but say me how to tame it!"* The taming is a warning a few
  // seconds before, so an idle lock stops being indistinguishable from a crash.
  //
  // What these check is the part that would be easy to get wrong quietly: that
  // the warning is **only** a warning. If it ever bought the session extra
  // time, `UX-FLOWS.md` flow 7 would have been renegotiated by accident, and
  // the only symptom would be a vault that stays open slightly longer than
  // anybody chose — which nobody would ever notice or report.
  group('the warning before an idle lock', () {
    test('goes up before the lock, and the lock still happens on time',
        () async {
      final v = await openVault(idle: const Duration(milliseconds: 600));
      // warningWindow is a third of the timeout, so 200ms: up at 400.
      expect(v.warningWindow, const Duration(milliseconds: 200));
      v.touch();

      expect(v.aboutToLock.value, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(v.aboutToLock.value, isFalse,
          reason: 'the notice appeared long before it was due');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(v.aboutToLock.value, isTrue,
          reason: 'no warning was given at all');
      expect(v.isUnlocked, isTrue,
          reason: 'the warning is not the lock');

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(v.isUnlocked, isFalse,
          reason: 'the warning delayed the lock, which it must never do');
      expect(v.aboutToLock.value, isFalse,
          reason: 'the notice outlived the thing it was warning about');
    });

    test('being there takes it back down', () async {
      final v = await openVault(idle: const Duration(milliseconds: 600));
      v.touch();
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(v.aboutToLock.value, isTrue);

      // Which is what any tap on the screen does — see the Listener in app.dart.
      v.touch();
      expect(v.aboutToLock.value, isFalse);
      expect(v.isUnlocked, isTrue);

      // And the countdown really did start again rather than merely being
      // hidden: a full timeout later it is still open at the old deadline.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(v.isUnlocked, isTrue);
      await v.lock();
    });

    test('"never" gives no warning, because there is nothing to warn about',
        () async {
      final v = await openVault(idle: Duration.zero);
      expect(v.warningWindow, Duration.zero);
      v.touch();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(v.aboutToLock.value, isFalse);
      await v.lock();
    });

    test('the window is capped, so a long setting does not warn for minutes',
        () async {
      final v = await openVault(idle: const Duration(minutes: 15));
      // A third would be five minutes, which is not a warning, it is a mood.
      expect(v.warningWindow, const Duration(seconds: 20));
      await v.lock();
    });
  });
}
