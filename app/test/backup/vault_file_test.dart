import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/cbor.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// The `.vault` backup format.
///
/// WHAT THESE TESTS ARE FOR
///
/// Not "does it round trip" — that is the easy half and it is the half that
/// passes on the day the format is written. The half that matters is what
/// happens to a file that has been damaged, truncated, reordered, or written by
/// somebody else, because a backup is only ever read on a bad day and a format
/// that returns plausible garbage on that day is worse than one that returns
/// nothing at all.
///
/// So every guarantee the specification claims gets a test that breaks the file
/// in exactly that way and insists it is refused: a flipped bit, a truncation,
/// a reordered chunk, a tampered header, a wrong passcode.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_backup'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  VaultFile format() => VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));

  const passcode = 'a passphrase you can remember';

  /// A directory shaped like a vault, without the cost of making a real one.
  ///
  /// `Random(42)` rather than the CSPRNG on purpose: this is test *data*, not
  /// key material, and a fixed seed means a failure can be reproduced exactly.
  /// `CLAUDE.md` rule 6 is about the app, and nothing here derives a key.
  Future<Directory> fakeVault({
    int attachments = 3,
    int databaseBytes = 220000,
  }) async {
    final root = Directory('${tmp.path}/vault')..createSync(recursive: true);
    File('${root.path}/keyring.json')
        .writeAsStringSync('{"version":1,"salt":"not a real keyring"}');

    // Incompressible, so the body really does span several 64 KiB chunks
    // instead of collapsing to one and leaving the chunking untested.
    final rng = math.Random(42);
    File('${root.path}/vault.db').writeAsBytesSync(
      Uint8List.fromList(List.generate(databaseBytes, (_) => rng.nextInt(256))),
    );

    final dir = Directory('${root.path}/attachments')..createSync();
    for (var i = 0; i < attachments; i++) {
      File('${dir.path}/attachment-$i.enc').writeAsBytesSync(
        Uint8List.fromList(List.generate(4096, (j) => (i * 31 + j) % 256)),
      );
    }
    return root;
  }

  Future<File> writeBackup(Directory root, {String secret = passcode}) async {
    final file = File('${tmp.path}/out.vault');
    await format().write(
      destination: file,
      passcode: secret,
      vaultRoot: root,
      counts: {'entry_count': 7, 'day_count': 3, 'attachment_count': 3},
    );
    return file;
  }

  Future<void> patch(File file, int offset, int Function(int) change) async {
    final bytes = await file.readAsBytes();
    bytes[offset] = change(bytes[offset]);
    await file.writeAsBytes(bytes, flush: true);
  }

  // ═════════════════════════════════════════════════════════════════════════
  group('a good file', () {
    test('every member comes back byte for byte', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);

      final staging = Directory('${tmp.path}/staging');
      final summary = await format()
          .extract(source: file, passcode: passcode, staging: staging);

      expect(summary.entryCount, 7);
      expect(summary.dayCount, 3);

      for (final name in ['keyring.json', 'vault.db']) {
        expect(
          await File('${staging.path}/$name').readAsBytes(),
          equals(await File('${root.path}/$name').readAsBytes()),
          reason: '$name did not survive the round trip',
        );
      }
      for (var i = 0; i < 3; i++) {
        expect(
          await File('${staging.path}/attachments/attachment-$i.enc')
              .readAsBytes(),
          equals(await File('${root.path}/attachments/attachment-$i.enc')
              .readAsBytes()),
        );
      }
    });

    test('verify passes and leaves nothing behind', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final scratch = Directory('${tmp.path}/scratch');

      await format()
          .verify(source: file, passcode: passcode, scratch: scratch);

      // The whole point of the verify step is that it is a real decrypt, and a
      // real decrypt writes real files. Leaving a second copy of the vault in
      // app storage afterwards would be a leak the user never asked for.
      expect(scratch.existsSync(), isFalse);
    });

    test('the header says what the specification says it should', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final info = await format().inspect(file);

      // **2 since 24 August 2026.** ISSUE 17 — the recovery wrapper. v1 files
      // still open with the passcode and always will; see
      // test/backup/recovery_opens_backup_test.dart for both directions.
      expect(info.header['format_version'], 2);
      expect(info.header['kdf'], 'argon2id');
      expect(info.header['cipher'], 'xchacha20poly1305');
      expect(info.header['chunk_size'], 65536);
      expect(info.header['kdf_parallelism'], 1);
      expect(info.header['kdf_salt'], isA<Uint8List>());
      expect(info.chunkCount, greaterThan(1),
          reason: 'the body should span several chunks, or chunking is untested');
    });

    test('the header does NOT say how much the user has written', () async {
      // BACKUP-FILE-FORMAT.md: an entry count in the header would tell anyone
      // holding the file how much you have written. It goes in the encrypted
      // manifest instead. This test is what stops it being "helpfully" added.
      final root = await fakeVault();
      final file = await writeBackup(root);
      final info = await format().inspect(file);

      expect(info.header.keys, isNot(contains('entry_count')));
      expect(info.header.keys, isNot(contains('day_count')));
      expect(info.header.keys, isNot(contains('members')));
    });

    test('two backups of the same vault are different files', () async {
      // Fresh salt, fresh DEK, fresh nonces every time. Identical output would
      // mean a fixed salt somewhere, which is the whole ballgame.
      final root = await fakeVault();
      final first = await writeBackup(root);
      final a = await first.readAsBytes();
      final second = File('${tmp.path}/out2.vault');
      await format().write(
        destination: second,
        passcode: passcode,
        vaultRoot: root,
        counts: const {},
      );
      expect(await second.readAsBytes(), isNot(equals(a)));
    });

    test('a different passcode produces a file the first one cannot open',
        () async {
      final root = await fakeVault();
      final file = await writeBackup(root, secret: 'the other passcode');
      expect(
        () => format().extract(
          source: file,
          passcode: passcode,
          staging: Directory('${tmp.path}/s'),
        ),
        throwsA(isA<BackupError>()),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('a file that has been got at', () {
    test('a damaged file is reported as damaged, and still leaves nothing behind',
        () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final scratch = Directory('${tmp.path}/scratch-damaged');

      final length = await file.length();
      await patch(file, length - VaultFile.footerLength - 64, (b) => b ^ 0x01);
      await _rewriteFooterHash(file, sodium);

      await expectLater(
        format().verify(source: file, passcode: passcode, scratch: scratch),
        throwsA(isA<BackupError>()),
      );

      // Both halves of this used to be wrong, and the second caused the first.
      // A member's sink was left open when the decrypt threw part-way through
      // it; Windows will not delete a directory with an open handle inside it;
      // so the cleanup in `verify` threw a PathAccessException on its way out
      // and that is what the user was shown, instead of the sentence above.
      expect(scratch.existsSync(), isFalse);
    });

    test('a wrong passcode is refused, in the words flow 6 specifies',
        () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      await expectLater(
        format().extract(
          source: file,
          passcode: 'not it',
          staging: Directory('${tmp.path}/s'),
        ),
        throwsA(isA<BackupError>().having(
          (e) => e.message,
          'message',
          "That passcode doesn't open this file.",
        )),
      );
    });

    test('one flipped bit anywhere in the body is caught', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final info = await format().inspect(file);

      // Into the ciphertext of the first chunk: past its length and its nonce.
      await patch(file, info.bodyStart + 4 + 24 + 10, (b) => b ^ 0x01);

      await expectLater(
        format().inspect(file),
        throwsA(isA<BackupError>()),
        reason: 'the footer hash covers the whole file, so this fails early',
      );
    });

    test('a truncated file is refused rather than partly restored', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final bytes = await file.readAsBytes();
      await file.writeAsBytes(bytes.sublist(0, bytes.length - 500), flush: true);

      await expectLater(format().inspect(file), throwsA(isA<BackupError>()));
    });

    test('a reordered chunk is caught, not silently accepted', () async {
      // The index is bound into every nonce AND checked on the way back. Bind
      // it without checking it and the binding is decoration: each chunk would
      // still decrypt perfectly on its own, and the user would restore a vault
      // that is quietly not the one they backed up.
      final root = await fakeVault();
      final file = await writeBackup(root);
      final info = await format().inspect(file);

      // The last byte of the first chunk's nonce is the low byte of its
      // little-endian index. Claim it is chunk 9.
      final indexByte = info.bodyStart + 4 + 16;
      await patch(file, indexByte, (_) => 9);
      // The footer hash would otherwise catch this first, so repair it: this
      // test is about the index check specifically, not about the hash.
      await _rewriteFooterHash(file, sodium);

      await expectLater(
        format().extract(
          source: file,
          passcode: passcode,
          staging: Directory('${tmp.path}/s'),
        ),
        throwsA(isA<BackupError>().having(
          (e) => e.message,
          'message',
          contains('out of order'),
        )),
      );
    });

    test('a tampered header breaks the wrapped key', () async {
      // An attacker's most valuable edit is rewriting kdf_memory_kib down to 1
      // so brute force becomes cheap. The header is the authenticated
      // associated data on the wrapped DEK, so the edit breaks the tag.
      final root = await fakeVault();
      final file = await writeBackup(root);
      final info = await format().inspect(file);

      // Somewhere inside the header, past the magic and the length.
      await patch(file, VaultFile.magic.length + 4 + 20, (b) => b ^ 0x20);
      await _rewriteFooterHash(file, sodium);

      await expectLater(
        format().extract(
          source: file,
          passcode: passcode,
          staging: Directory('${tmp.path}/s'),
        ),
        throwsA(anything),
      );
      expect(info.chunkCount, greaterThan(0));
    });

    test('something that is not a backup at all says so plainly', () async {
      final file = File('${tmp.path}/holiday.jpg')
        ..writeAsBytesSync(Uint8List.fromList(List.filled(4096, 0x42)));
      await expectLater(
        format().inspect(file),
        throwsA(isA<BackupError>().having(
          (e) => e.message,
          'message',
          'This is not a Lamplight backup file.',
        )),
      );
    });

    test('a file from a newer version says to update the app', () async {
      final root = await fakeVault();
      final file = await writeBackup(root);
      final bytes = await file.readAsBytes();

      // Rewrite the header with a version from the future, keeping its length
      // the same so nothing else shifts.
      final headerStart = VaultFile.magic.length + 4;
      final headerLength =
          ByteData.sublistView(bytes).getUint32(VaultFile.magic.length, Endian.little);
      final header = Cbor.decode(
          Uint8List.sublistView(bytes, headerStart, headerStart + headerLength))!
        as Map<String, Object?>;
      header['format_version'] = 99;
      final rewritten = Cbor.encode(header);

      final out = BytesBuilder()
        ..add(bytes.sublist(0, VaultFile.magic.length))
        ..add(Uint8List(4)
          ..buffer.asByteData().setUint32(0, rewritten.length, Endian.little))
        ..add(rewritten)
        ..add(bytes.sublist(headerStart + headerLength));
      await file.writeAsBytes(out.takeBytes(), flush: true);
      await _rewriteFooterHash(file, sodium);

      await expectLater(
        format().inspect(file),
        throwsA(isA<BackupError>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        )),
      );
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('what a restore will and will not write', () {
    test('only the names the format defines', () {
      expect(VaultFile.isAllowedMemberName('vault.db'), isTrue);
      expect(VaultFile.isAllowedMemberName('keyring.json'), isTrue);
      expect(VaultFile.isAllowedMemberName('manifest.cbor'), isTrue);
      expect(
          VaultFile.isAllowedMemberName('attachments/abc-123.enc'), isTrue);
    });

    test('nothing that could escape the staging directory', () {
      // The inner stream is attacker-controlled the moment someone opens a file
      // a stranger sent them. These are the shapes that matter.
      for (final hostile in [
        '../../../shared_prefs/secrets.xml',
        'attachments/../../keyring.json',
        '/etc/passwd',
        'C:\\Windows\\System32\\evil.dll',
        'attachments/..',
        'vault.db/../../x',
        'attachments/a/b',
        '',
      ]) {
        expect(VaultFile.isAllowedMemberName(hostile), isFalse,
            reason: '$hostile must never be written');
      }
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('end to end, with a real vault', () {
    test('write a note, back it up, wipe it, restore it, read it back',
        () async {
      // The whole promise of flow 6, proved in one test. This is the sequence a
      // person performs on the worst day of the year, holding a new phone.
      final root = Directory('${tmp.path}/live');
      final vault =
          Vault(sodium: sodium, root: root, idleTimeout: const Duration(hours: 1));
      await vault.initialise();
      await vault.create(passcode: passcode);

      final db = vault.database;
      final now = DateTime.now();
      await db.into(db.entries).insert(EntriesCompanion.insert(
            id: vault.newId(),
            createdAt: now.millisecondsSinceEpoch,
            createdOffsetMinutes: now.timeZoneOffset.inMinutes,
            updatedAt: now.millisecondsSinceEpoch,
            type: 'text',
            body: const Value('the thing I would be sorry to lose'),
            dayKey: '2026-08-18',
          ));

      await vault.checkpoint();
      final file = File('${tmp.path}/live.vault');
      await format().write(
        destination: file,
        passcode: passcode,
        vaultRoot: vault.root,
        counts: const {'entry_count': 1, 'day_count': 1},
      );
      await vault.lock();

      // Destroy everything, the way a lost phone does.
      for (final name in Vault.vaultFileNames) {
        final f = File('${root.path}/$name');
        if (f.existsSync()) f.deleteSync();
      }
      final attachments = Directory('${root.path}/attachments');
      if (attachments.existsSync()) attachments.deleteSync(recursive: true);
      await vault.initialise();
      expect(vault.state, VaultState.uninitialised,
          reason: 'the vault should now look like a fresh install');

      // Restore.
      final staging = Directory('${tmp.path}/staging');
      final summary = await format()
          .extract(source: file, passcode: passcode, staging: staging);
      expect(summary.entryCount, 1);

      final aside = await vault.swapIn(staging);
      expect(vault.state, VaultState.locked);

      await vault.unlockWithPasscode(passcode);
      await vault.commitSwap(aside);

      final rows = await vault.database.select(vault.database.entries).get();
      expect(rows, hasLength(1));
      expect(rows.single.body, 'the thing I would be sorry to lose');
      expect(aside.existsSync(), isFalse);

      await vault.lock();
    });

    test('a failed restore puts the old vault back exactly as it was',
        () async {
      // The branch that makes the restore screen safe to press. If this is
      // wrong, someone loses everything while trying to recover something.
      final root = Directory('${tmp.path}/live');
      final vault =
          Vault(sodium: sodium, root: root, idleTimeout: const Duration(hours: 1));
      await vault.initialise();
      await vault.create(passcode: passcode);

      final db = vault.database;
      final now = DateTime.now();
      await db.into(db.entries).insert(EntriesCompanion.insert(
            id: vault.newId(),
            createdAt: now.millisecondsSinceEpoch,
            createdOffsetMinutes: now.timeZoneOffset.inMinutes,
            updatedAt: now.millisecondsSinceEpoch,
            type: 'text',
            body: const Value('what was already here'),
            dayKey: '2026-08-18',
          ));
      await vault.checkpoint();
      await vault.lock();

      // Swap in a staging directory holding a vault that will not open — a
      // restore that got as far as the swap and then failed its proof.
      final staging = Directory('${tmp.path}/bad-staging')
        ..createSync(recursive: true);
      File('${staging.path}/keyring.json').writeAsStringSync('{"broken":true}');
      File('${staging.path}/vault.db').writeAsBytesSync(
          Uint8List.fromList(List.filled(4096, 0x00)));

      final aside = await vault.swapIn(staging);
      await expectLater(
        vault.unlockWithPasscode(passcode),
        throwsA(anything),
      );

      await vault.rollbackSwap(aside);
      await vault.unlockWithPasscode(passcode);

      final rows = await vault.database.select(vault.database.entries).get();
      expect(rows.single.body, 'what was already here');
      expect(aside.existsSync(), isFalse);

      await vault.lock();
    });
  });

  test('an empty vault says so instead of writing a useless file', () async {
    final root = Directory('${tmp.path}/nothing')..createSync(recursive: true);
    await expectLater(
      format().write(
        destination: File('${tmp.path}/empty.vault'),
        passcode: passcode,
        vaultRoot: root,
        counts: const {},
      ),
      throwsA(isA<BackupError>()),
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  //  PLAN.md §7.1 — the same work, on a worker isolate.
  //
  //  The wrapper is the only new code, so these tests are about the wrapper
  //  and not about the format: does the file a worker writes open in the
  //  ordinary reader, does progress arrive, does cancelling actually stop it,
  //  and — the one that matters most — does a verify that runs somewhere else
  //  still *fail*. A wrapper that swallowed the exception would report every
  //  corrupt backup as a good one, which is the worst bug this file could have.
  group('off the UI isolate', () {
    test('a file a worker wrote opens in the ordinary reader', () async {
      final root = await fakeVault();
      final file = File('${tmp.path}/worker.vault');
      final key = await format().deriveBackupKey(passcode);

      try {
        final summary = await format().writeOffThread(
          destination: file,
          key: key,
          vaultRoot: root,
          counts: {'entry_count': 7, 'day_count': 3, 'attachment_count': 3},
        );
        expect(summary.chunkCount, greaterThan(1));
        expect(summary.byteSize, await file.length());
      } finally {
        key.dispose();
      }

      // Read back by the plain path, with nothing but the passcode — the same
      // way a restore on a new phone would, months later.
      final staging = Directory('${tmp.path}/staging');
      await format().extract(source: file, passcode: passcode, staging: staging);

      for (final name in ['keyring.json', 'vault.db']) {
        expect(
          await File('${staging.path}/$name').readAsBytes(),
          equals(await File('${root.path}/$name').readAsBytes()),
          reason: '$name did not survive the round trip through a worker',
        );
      }
    });

    test('progress arrives, in order, and ends at one', () async {
      final root = await fakeVault();
      final key = await format().deriveBackupKey(passcode);
      final seen = <double>[];

      try {
        await format().writeOffThread(
          destination: File('${tmp.path}/progress.vault'),
          key: key,
          vaultRoot: root,
          counts: const {},
          onProgress: seen.add,
        );
      } finally {
        key.dispose();
      }

      expect(seen, isNotEmpty);
      expect(seen.last, 1.0);
      // A progress bar that goes backwards is a progress bar nobody believes.
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
    });

    test('cancelling reaches the worker and stops it', () async {
      final root = await fakeVault();
      final key = await format().deriveBackupKey(passcode);
      final file = File('${tmp.path}/cancelled.vault');
      var started = false;

      try {
        await expectLater(
          format().writeOffThread(
            destination: file,
            key: key,
            vaultRoot: root,
            counts: const {},
            // Cancelled the instant the first chunk is reported, which is the
            // real shape of it: a person presses Stop while it is running.
            onProgress: (_) => started = true,
            isCancelled: () => started,
          ),
          throwsA(isA<BackupCancelled>()),
        );
      } finally {
        key.dispose();
      }
    });

    test('a worker verify still refuses a damaged file', () async {
      final root = await fakeVault();
      final file = File('${tmp.path}/damaged.vault');
      final key = await format().deriveBackupKey(passcode);

      try {
        await format().writeOffThread(
          destination: file,
          key: key,
          vaultRoot: root,
          counts: const {},
        );

        // Good first, so the test proves the difference and not just that the
        // wrapper throws at everything.
        await format().verifyOffThread(
          source: file,
          key: key,
          scratch: Directory('${tmp.path}/scratch-good'),
        );

        final length = await file.length();
        await patch(file, length - VaultFile.footerLength - 64, (b) => b ^ 0x01);
        await _rewriteFooterHash(file, sodium);

        await expectLater(
          format().verifyOffThread(
            source: file,
            key: key,
            scratch: Directory('${tmp.path}/scratch-bad'),
          ),
          throwsA(isA<BackupError>()),
        );
      } finally {
        key.dispose();
      }
    });
  });
}

/// Recomputes the footer hash after a test has deliberately edited the body.
///
/// The whole-file hash is checked before anything else, so without this every
/// tampering test would only ever prove that the hash works — which is one
/// test, not five. Repairing it lets each test reach the specific defence it is
/// actually about.
Future<void> _rewriteFooterHash(File file, SodiumSumo sodium) async {
  final bytes = await file.readAsBytes();
  final upTo = bytes.length - 32;
  final digest = sodium.crypto.genericHash(
    message: Uint8List.sublistView(bytes, 0, upTo),
    outLen: 32,
  );
  bytes.setRange(upTo, bytes.length, digest);
  await file.writeAsBytes(bytes, flush: true);
}
