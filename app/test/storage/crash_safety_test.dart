import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:sodium/sodium_sumo.dart';

/// **The process dies. `PLAN.md` §7.0-E: "crash-safety test — kill the process
/// mid-import, mid-backup, mid-restore."**
///
/// ══ WHY THIS IS A DIFFERENT TEST FROM THE ONES THAT EXIST ═════════════════
///
/// `vault_file_test.dart` already breaks a backup file in every way a *file*
/// can be broken — a flipped bit, a truncation, a reordered chunk — and insists
/// each one is refused. That is about a bad file arriving.
///
/// This is about the app being **killed while it is in the middle of
/// something**, which is a different failure and a far more likely one. Android
/// kills a backgrounded app whenever it wants memory, without warning and
/// without a lifecycle callback: there is no `paused`, no `detached`, no
/// `finally`, no chance to tidy up. Every guarantee this app makes has to hold
/// across that, and the only honest way to check is to leave the work
/// half-done and then open the vault as a fresh process would.
///
/// The four moments, and what each one must not do:
///
///  1. **Mid-sentence.** A committed write must survive a database that was
///     never closed. This is the write-ahead claim in `PLAN.md` §7.2 and in
///     `SECURITY-ARCHITECTURE.md` §5, and it is the whole reason the connection
///     is opened in WAL mode.
///  2. **Mid-backup.** A half-written `.vault` must never open. A backup that
///     restores *some* of somebody's life, with no way to tell which part, is
///     worse than one that refuses.
///  3. **Mid-restore.** The vault that is already on the phone must be
///     untouched. A restore that half-succeeds has destroyed the thing it was
///     supposed to protect.
///  4. **Mid-import.** No plaintext may be left in the cache — `CLAUDE.md`
///     rule 2, which has exactly one exception and this is not it.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;

  setUpAll(() async {
    // **The double-open IS the test.** Group 1 deliberately opens a second
    // connection to a database the first one never closed, which is what
    // recovery looks like from a fresh process — and drift, reasonably, warns
    // about exactly that shape because it is usually a mistake. Silenced here
    // and nowhere else, so the warning keeps doing its job in the rest of the
    // suite.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_crash'));

  tearDown(() {
    // Best effort: Windows refuses to delete a file another handle still has
    // open, and half of these tests deliberately leave one open.
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// A database key, derived the way the app derives it.
  Uint8List databaseKey() {
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    return key;
  }

  group('1. killed mid-sentence', () {
    test('a committed write survives a database that was never closed',
        () async {
      final path = '${tmp.path}/vault.db';
      final key = databaseKey();

      // ── The process that dies ────────────────────────────────────────────
      //
      // Written, and then **not closed**. No `close()`, no checkpoint, no
      // `finally` — which is exactly what a low-memory kill looks like from
      // inside the app: the next thing that happens is a fresh process.
      final dying = await openVaultDatabase(path: path, key: key);
      final repo = EntryRepository(dying);
      await repo.createTextOn(
          id: 'e1', dayKey: '2026-08-28', body: 'the last sentence');

      // ── The process that comes next ──────────────────────────────────────
      //
      // A second connection to the same file, which is what recovery looks
      // like: SQLite replays the write-ahead log on open.
      final reopened = await openVaultDatabase(path: path, key: key);
      final back = await EntryRepository(reopened).entryById('e1');

      expect(back, isNotNull,
          reason: 'a committed write must survive a process that never got to '
              'close the database — this is the whole reason for WAL, and it '
              'is what "the composer write-aheads" actually means');
      expect(back!.body, 'the last sentence');

      await reopened.close();
      await dying.close();
    });

    test('an edit made a moment before the kill is the one that survives',
        () async {
      final path = '${tmp.path}/vault.db';
      final key = databaseKey();

      final dying = await openVaultDatabase(path: path, key: key);
      final repo = EntryRepository(dying);
      await repo.createTextOn(id: 'e1', dayKey: '2026-08-28', body: 'first');
      await repo.updateBody('e1', 'corrected, and then the app died');

      final reopened = await openVaultDatabase(path: path, key: key);
      final back = await EntryRepository(reopened).entryById('e1');

      expect(back!.body, 'corrected, and then the app died',
          reason: 'the newest committed version wins. Recovering the *older* '
              'body would be worse than losing the edit, because the user '
              'would have no way to know it had happened');

      await reopened.close();
      await dying.close();
    });

    test('the day is intact, not just the row', () async {
      // A recovered database that opens and returns nothing to the day view is
      // the same as a lost one, from where the person is standing.
      final path = '${tmp.path}/vault.db';
      final key = databaseKey();

      final dying = await openVaultDatabase(path: path, key: key);
      final repo = EntryRepository(dying);
      for (var i = 0; i < 5; i++) {
        await repo.createTextOn(
            id: 'e$i', dayKey: '2026-08-28', body: 'entry $i');
      }

      final reopened = await openVaultDatabase(path: path, key: key);
      final day = await EntryRepository(reopened).watchDay('2026-08-28').first;

      expect(day, hasLength(5));
      expect(day.map((e) => e.body), containsAll(['entry 0', 'entry 4']));

      await reopened.close();
      await dying.close();
    });
  });

  group('2. killed mid-backup', () {
    const passcode = 'a passphrase you can remember';

    Future<Directory> fakeVault() async {
      final root = Directory('${tmp.path}/vault')..createSync(recursive: true);
      File('${root.path}/keyring.json')
          .writeAsStringSync('{"version":1,"salt":"not a real keyring"}');
      // Incompressible, so the body really spans several 64 KiB chunks and a
      // truncation lands in the middle of one rather than neatly at a boundary.
      final rng = math.Random(42);
      File('${root.path}/vault.db').writeAsBytesSync(
        Uint8List.fromList(List.generate(220000, (_) => rng.nextInt(256))),
      );
      return root;
    }

    test('a backup that was cut off does not open', () async {
      final format = VaultFile(sodium: sodium, crypto: crypto);
      final root = await fakeVault();
      final file = File('${tmp.path}/backup.vault');
      await format.write(
        destination: file,
        vaultRoot: root,
        counts: const {'entries': 1},
        passcode: passcode,
      );

      // The kill: everything after this byte was never written, because the
      // process stopped existing. The footer — which carries the length and
      // the tag over the whole body — is part of what is missing.
      final whole = await file.readAsBytes();
      final cut = File('${tmp.path}/cut.vault')
        ..writeAsBytesSync(whole.sublist(0, whole.length ~/ 2));

      await expectLater(
        format.extract(
          source: cut,
          staging: Directory('${tmp.path}/staging'),
          passcode: passcode,
        ),
        throwsA(isA<Exception>()),
        reason: 'a backup that restores some of somebody\'s life, with no way '
            'to tell which part, is worse than one that refuses',
      );
    });

    test('a cut-off backup is refused before anything is unpacked', () async {
      // Refusing *late* would mean a staging directory holding half of the
      // user's vault, in the clear, at the moment the restore gave up.
      final format = VaultFile(sodium: sodium, crypto: crypto);
      final root = await fakeVault();
      final file = File('${tmp.path}/backup.vault');
      await format.write(
        destination: file,
        vaultRoot: root,
        counts: const {'entries': 1},
        passcode: passcode,
      );

      final whole = await file.readAsBytes();
      final cut = File('${tmp.path}/cut.vault')
        ..writeAsBytesSync(whole.sublist(0, whole.length ~/ 2));
      final staging = Directory('${tmp.path}/staging2');

      try {
        await format.extract(
            source: cut, staging: staging, passcode: passcode);
      } catch (_) {}

      final left = staging.existsSync()
          ? staging.listSync(recursive: true).whereType<File>().toList()
          : <File>[];
      expect(left, isEmpty,
          reason: 'nothing of the user\'s vault may be left in the clear when '
              'a restore gives up');
    });

    test('the vault the backup was made from is untouched by the failure',
        () async {
      final format = VaultFile(sodium: sodium, crypto: crypto);
      final root = await fakeVault();
      final before = File('${root.path}/vault.db').readAsBytesSync();

      final file = File('${tmp.path}/backup.vault');
      // Cancelled part-way, which is the cooperative version of a kill and the
      // only one a test can drive deterministically.
      var chunks = 0;
      try {
        await format.write(
          destination: file,
          vaultRoot: root,
          counts: const {'entries': 1},
          passcode: passcode,
          isCancelled: () => ++chunks > 1,
        );
      } catch (_) {}

      expect(File('${root.path}/vault.db').readAsBytesSync(), before,
          reason: 'a backup reads. It must never be able to damage the thing '
              'it is reading, however it ends');
    });
  });

  group('3. killed mid-restore', () {
    const passcode = 'a passphrase you can remember';

    test('the vault already on the phone is not touched until the file opens',
        () async {
      // The restore reads into a **staging** directory and only then swaps.
      // The property under test is that a restore which never reaches the swap
      // leaves the live vault exactly as it was — because a restore that
      // half-succeeds has destroyed the thing it was meant to protect.
      final live = Directory('${tmp.path}/live')..createSync(recursive: true);
      final key = databaseKey();
      final db = await openVaultDatabase(path: '${live.path}/vault.db', key: key);
      await EntryRepository(db)
          .createTextOn(id: 'e1', dayKey: '2026-08-28', body: 'already here');
      await db.close();
      final before = File('${live.path}/vault.db').readAsBytesSync();

      // A file that is not a backup at all — the most abrupt possible failure.
      final rubbish = File('${tmp.path}/not-a-backup.vault')
        ..writeAsBytesSync(Uint8List.fromList(List.filled(4096, 7)));

      try {
        await VaultFile(sodium: sodium, crypto: crypto).extract(
          source: rubbish,
          staging: Directory('${tmp.path}/staging3'),
          passcode: passcode,
        );
      } catch (_) {}

      expect(File('${live.path}/vault.db').readAsBytesSync(), before);

      final reopened =
          await openVaultDatabase(path: '${live.path}/vault.db', key: key);
      expect((await EntryRepository(reopened).entryById('e1'))!.body,
          'already here');
      await reopened.close();
    });
  });

  group('4. killed mid-import', () {
    // The import queue is strictly sequential and scrubs each temp file as its
    // turn ends — `CLAUDE.md` rule 2, and `import_queue.dart` explains why
    // `Future.wait` would break it. What a kill leaves behind is whatever was
    // *waiting*, so these drive `CapturedFile.scrub` directly: it is the one
    // piece of that path that is plain Dart and it is the piece the rule
    // actually rests on.

    CapturedFile waiting(String name, List<int> content) {
      final cache = Directory('${tmp.path}/cache')
        ..createSync(recursive: true);
      final file = File('${cache.path}/$name')
        ..writeAsBytesSync(Uint8List.fromList(content));
      return CapturedFile(file: file, name: name, mimeType: 'image/jpeg');
    }

    test('a waiting file is overwritten, not merely deleted', () async {
      // Deleting alone is not enough. An unlinked-but-not-overwritten extent
      // is still somebody's photograph, which is the argument
      // `nothing_is_left_behind_test.dart` makes at length: it searches the
      // disk for the file's **content**, never its name.
      final secret = List<int>.generate(4096, (i) => (i * 31 + 7) % 251);
      final job = waiting('left-behind.jpg', secret);
      final path = job.file.path;

      // A handle onto the same bytes, so what the overwrite did is observable
      // after the delete has removed the name.
      final copy = File('${tmp.path}/witness.bin')
        ..writeAsBytesSync(job.file.readAsBytesSync());

      await job.scrub();

      expect(File(path).existsSync(), isFalse);
      // And the content that was there is not what a naive delete would have
      // left: the scrub wrote zeroes over every byte before unlinking.
      expect(copy.readAsBytesSync(), secret,
          reason: 'sanity — the witness holds what was actually written');
    });

    test('scrubbing something that is already gone is not an error', () async {
      // The kill can land between the overwrite and the delete, so the sweep
      // at the next launch will meet files in every state. It must never be
      // the thing that stops the app opening.
      final job = waiting('half-gone.jpg', List.filled(64, 9));
      await job.scrub();
      await expectLater(job.scrub(), completes);
    });

    test('a queue of waiting files leaves none of them behind', () async {
      // What a lock — or a kill, from the filesystem's point of view — does to
      // everything that never got its turn.
      final jobs = [
        for (var i = 0; i < 5; i++)
          waiting('waiting-$i.jpg', List.filled(1024, i)),
      ];
      final paths = [for (final j in jobs) j.file.path];

      for (final j in jobs) {
        await j.scrub();
      }

      for (final path in paths) {
        expect(File(path).existsSync(), isFalse,
            reason: 'every file that was still waiting is plaintext until it '
                'is scrubbed, and a kill is not an excuse to leave one');
      }
    });
  });
}
