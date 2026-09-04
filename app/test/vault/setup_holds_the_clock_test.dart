import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND NINETEEN — the vault locked while he wrote the words down.**
///
/// > *"Open it with your fingerprint? Error message is - That did not work!
/// > when i pressed use my fingerprint! If after that i go in settings and then
/// > set up manually fingerprint that works!"*
///
/// The fingerprint was never the broken part, and the fact that Settings
/// worked a minute later is the clue rather than a separate observation.
///
/// `create()` ends in `_open()`, `_open()` ends in `touch()`, and `touch()`
/// arms a five-minute timer that only a **pointer down** resets. The passcode
/// step is where the vault gets made — and every step after it is reading.
/// Onboarding's next act is to show twelve recovery words and ask the user to
/// write them down, which is the most important thing the app ever asks of
/// anybody, takes longer than five minutes to do properly, and produces no
/// taps whatsoever.
///
/// So the vault locked, `enableBiometricUnlock` found no DEK, threw
/// `StateError`, and the screen printed a sentence blaming the reader.
/// **The app punished him for following its own instructions.**
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_setup'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Vault> newVault({required Duration idle}) async {
    final v = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: idle,
    );
    await v.initialise();
    return v;
  }

  // The bug, reproduced. This is what onboarding did before the fix: create
  // the vault, then go quiet for longer than the timeout while somebody
  // copies twelve words onto paper.
  test('THE BUG: creating a vault and then reading locks it', () async {
    final v = await newVault(idle: const Duration(milliseconds: 120));
    await v.create(passcode: 'a passphrase');
    expect(v.isUnlocked, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(v.isUnlocked, isFalse,
        reason: 'this is the fault, kept so the fix below is measured against '
            'something real rather than against nothing');
    await v.lock();
  });

  test('setup holds the clock, so the same wait is survivable', () async {
    final v = await newVault(idle: const Duration(milliseconds: 120));
    v.beginSetup();
    await v.create(passcode: 'a passphrase');

    // Long enough to write twelve words down, in miniature.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(v.isUnlocked, isTrue,
        reason: 'the vault must still be open when the fingerprint step is '
            'reached, or enableBiometricUnlock throws StateError');
    await v.lock();
  });

  test('and gives it back, so the clock runs again afterwards', () async {
    final v = await newVault(idle: const Duration(milliseconds: 120));
    v.beginSetup();
    await v.create(passcode: 'a passphrase');
    v.endSetup();

    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(v.isUnlocked, isFalse,
        reason: 'suspending the idle lock for onboarding must not leave it '
            'suspended for the life of the process');
  });

  test('endSetup twice is harmless', () async {
    final v = await newVault(idle: Duration.zero);
    v.beginSetup();
    await v.create(passcode: 'a passphrase');
    v.endSetup();
    v.endSetup();
    expect(v.isUnlocked, isTrue);
    await v.lock();
  });

  // ── The half that must NOT have been relaxed ──────────────────────────
  //
  // `UX-FLOWS.md` flow 7 calls lock-on-background non-negotiable, and it is
  // the defence that actually matters for the most likely adversary in
  // THREAT-MODEL.md — somebody picking up the phone. Suspending the *idle*
  // clock for onboarding is only defensible while this still holds.
  test('backgrounding still locks, even mid-setup', () async {
    final v = await newVault(idle: const Duration(minutes: 5));
    v.beginSetup();
    await v.create(passcode: 'a passphrase');
    expect(v.isUnlocked, isTrue);

    await v.onBackgrounded();

    expect(v.isUnlocked, isFalse,
        reason: 'onboarding may hold the idle timer and may never hold this');
  });
}
