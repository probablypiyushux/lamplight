import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// The lock/unlock state machine, and the Phase 1 exit test in miniature.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_vault'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  // Real Argon2id at 128 MiB is deliberately slow; a suite that takes minutes
  // is a suite that stops being run. The real parameters are measured
  // elsewhere and on the phone.
  Vault newVault({Duration idle = const Duration(minutes: 1)}) => Vault(
        sodium: sodium,
        root: Directory('${tmp.path}/vault'),
        idleTimeout: idle,
      );

  Future<void> addNote(Vault v, String id, String body) async {
    final now = DateTime.now();
    await v.database.into(v.database.entries).insert(
          EntriesCompanion.insert(
            id: id,
            createdAt: now.millisecondsSinceEpoch,
            createdOffsetMinutes: now.timeZoneOffset.inMinutes,
            updatedAt: now.millisecondsSinceEpoch,
            type: 'text',
            body: Value(body),
            dayKey: '2026-08-18',
          ),
        );
  }

  group('lifecycle', () {
    test('a fresh device reports uninitialised', () async {
      final v = newVault();
      await v.initialise();
      expect(v.state, VaultState.uninitialised);
      expect(v.isUnlocked, isFalse);
    });

    test('create opens the vault and returns twelve words', () async {
      final v = newVault();
      await v.initialise();
      final words = await v.create(passcode: '1234');
      expect(words, hasLength(12));
      expect(v.state, VaultState.unlocked);
      await v.lock();
    });

    test('a second vault cannot be created over the first', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: '1234');
      await v.lock();
      expect(() => v.create(passcode: 'other'), throwsStateError);
    });

    test('the database is unreachable while locked', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: '1234');
      await v.lock();
      expect(() => v.database, throwsStateError);
      expect(() => v.attachments, throwsStateError);
    });
  });

  group('the Phase 1 exit test, in miniature', () {
    test('write, lock, reopen, unlock, read it back', () async {
      // The whole of Phase 1 in one test. The real version force-kills the app
      // on a phone; this proves the same path with a fresh Vault object over
      // the same files on disk.
      const note = 'Slept badly again. Third night.';

      final first = newVault();
      await first.initialise();
      await first.create(passcode: 'a quiet room');
      await addNote(first, 'e1', note);
      await first.lock();

      // A completely new object, as if the process had restarted.
      final second = newVault();
      await second.initialise();
      expect(second.state, VaultState.locked);

      await second.unlockWithPasscode('a quiet room');
      final rows = await second.database.select(second.database.entries).get();
      expect(rows.single.body, note);
      await second.lock();
    });

    test('and nothing readable is on disk', () async {
      const canary = 'CANARY_the_thing_I_would_never_say_aloud';
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'x');
      await addNote(v, 'e1', canary);
      await v.attachments.writeBytes(utf8.encode(canary));
      await v.lock();

      // Every file under the vault root, whatever it is. This is the check
      // that would catch a missing SQLCipher key, a plaintext temp file, or a
      // stray cache — the failure modes THREAT-MODEL.md rule 1 exists for.
      final files = Directory('${tmp.path}/vault')
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      expect(files, isNotEmpty);

      for (final f in files) {
        final bytes = f.readAsBytesSync();
        expect(_contains(bytes, utf8.encode(canary)), isFalse,
            reason: 'note text found in ${f.path}');
        expect(_contains(bytes, utf8.encode('CANARY')), isFalse,
            reason: 'partial note text found in ${f.path}');
      }
    });
  });

  group('unlocking', () {
    test('the wrong passcode is refused, in plain language', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'right');
      await v.lock();

      await expectLater(
        v.unlockWithPasscode('wrong'),
        throwsA(isA<WrongSecret>().having((e) => e.message, 'message',
            contains('does not open'))),
      );
      expect(v.state, VaultState.locked);
    });

    test('the recovery phrase opens the same vault', () async {
      // ADR-003 end to end: forget the passcode, use the paper.
      const note = 'the note I would lose';
      final v = newVault();
      await v.initialise();
      final words = await v.create(passcode: 'forgotten');
      await addNote(v, 'e1', note);
      await v.lock();

      final again = newVault();
      await again.initialise();
      await again.unlockWithRecoveryPhrase(words);
      final rows = await again.database.select(again.database.entries).get();
      expect(rows.single.body, note);
      await again.lock();
    });

    test('a mistyped recovery word is refused', () async {
      final v = newVault();
      await v.initialise();
      final words = await v.create(passcode: 'x');
      await v.lock();

      final wrong = [...words]..[0] = 'lamplight';
      await expectLater(v.unlockWithRecoveryPhrase(wrong), throwsA(isA<WrongSecret>()));
    });

    test("another vault's phrase does not open this one", () async {
      final a = newVault();
      await a.initialise();
      await a.create(passcode: 'x');
      await a.lock();

      final otherRoot = Directory('${tmp.path}/other');
      final b = Vault(sodium: sodium, root: otherRoot);
      await b.initialise();
      final otherWords = await b.create(passcode: 'y');
      await b.lock();

      await expectLater(
        a.unlockWithRecoveryPhrase(otherWords),
        throwsA(isA<WrongSecret>()),
      );
    });
  });

  group('changing the passcode', () {
    test('the new one works and the old one stops', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'old');
      await addNote(v, 'e1', 'still here');
      await v.lock();

      await v.changePasscode(currentPasscode: 'old', newPasscode: 'new');

      await v.unlockWithPasscode('new');
      final rows = await v.database.select(v.database.entries).get();
      expect(rows.single.body, 'still here',
          reason: 'the data must survive a passcode change untouched');
      await v.lock();

      await expectLater(v.unlockWithPasscode('old'), throwsA(isA<WrongSecret>()));
    });

    test('the recovery phrase STILL works afterwards', () async {
      // The regression test for a real bug. Both wrappers originally
      // authenticated one shared header containing the Argon2id salt, so
      // changing the passcode silently invalidated the twelve words. Nothing
      // would have surfaced it until someone forgot their passcode and reached
      // for the paper — the worst possible moment to discover it.
      final v = newVault();
      await v.initialise();
      final words = await v.create(passcode: 'old');
      await addNote(v, 'e1', 'written before the change');
      await v.lock();

      await v.changePasscode(currentPasscode: 'old', newPasscode: 'new');

      final again = newVault();
      await again.initialise();
      await again.unlockWithRecoveryPhrase(words);
      final rows = await again.database.select(again.database.entries).get();
      expect(rows.single.body, 'written before the change');
      await again.lock();
    });

    test('a wrong current passcode changes nothing', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'old');
      await v.lock();

      await expectLater(
        v.changePasscode(currentPasscode: 'not-it', newPasscode: 'new'),
        throwsA(isA<WrongSecret>()),
      );
      await v.unlockWithPasscode('old');
      await v.lock();
    });
  });

  group('locking', () {
    test('backgrounding locks immediately', () async {
      // UX-FLOWS.md flow 7 calls this non-negotiable. It is the defence against
      // the most likely adversary in the threat model: someone who picks up the
      // phone while it is unlocked.
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'x');
      expect(v.isUnlocked, isTrue);
      await v.onBackgrounded();
      expect(v.state, VaultState.locked);
    });

    test('idle time locks it', () async {
      final v = newVault(idle: const Duration(milliseconds: 120));
      await v.initialise();
      await v.create(passcode: 'x');
      expect(v.isUnlocked, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(v.state, VaultState.locked);
    });

    test('activity postpones the idle lock', () async {
      final v = newVault(idle: const Duration(milliseconds: 250));
      await v.initialise();
      await v.create(passcode: 'x');
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        v.touch();
      }
      expect(v.isUnlocked, isTrue, reason: 'typing should not lock the vault');
      await v.lock();
    });

    test('locking twice is harmless', () async {
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'x');
      await v.lock();
      await v.lock();
      expect(v.state, VaultState.locked);
    });

    test('lock then unlock then lock, repeatedly', () async {
      // Key lifecycle churn. A double-dispose or a stale handle shows up here.
      final v = newVault();
      await v.initialise();
      await v.create(passcode: 'x');
      await addNote(v, 'e1', 'persistent');
      await v.lock();

      for (var i = 0; i < 5; i++) {
        await v.unlockWithPasscode('x');
        final rows = await v.database.select(v.database.entries).get();
        expect(rows.single.body, 'persistent');
        await v.lock();
      }
    });
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) return false;
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
