import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/cbor.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/mnemonic.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 17 — the twelve words open the `.vault` file.**
///
/// > *"Backup phrase is only able to open the app! I want that phrase to open
/// > the backup (.vault) file. Backup phrase should also be able to open the
/// > backup file (.vault)."*
///
/// The hole he found is worse than an inconvenience. The words were sold —
/// correctly — as the way back in when the passcode is gone. They opened the
/// app **on that phone**. Lose the phone, and the only copy of a life was a
/// file that could be opened by a passcode which, by definition, had been
/// forgotten. The recovery phrase recovered the one thing that did not need
/// recovering.
///
/// Format v2 adds a second wrapper of the same file key. These tests are the
/// guarantee: either secret opens the file, neither opens somebody else's, and
/// v1 files still open with the passcode — which `BACKUP-FILE-FORMAT.md` says
/// is a promise that lasts forever.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_recovery'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  VaultFile format() => VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));
  VaultCrypto crypto() => VaultCrypto(sodium);

  const passcode = 'a passphrase you can remember';

  /// A directory shaped like a vault. Fixed seed: this is test data, not key
  /// material, and a reproducible failure is worth more than a novel one.
  Future<Directory> fakeVault() async {
    final root = Directory('${tmp.path}/vault')..createSync(recursive: true);
    File('${root.path}/keyring.json').writeAsStringSync('{"version":1}');
    final rng = math.Random(42);
    File('${root.path}/vault.db').writeAsBytesSync(
      Uint8List.fromList(List.generate(200000, (_) => rng.nextInt(256))),
    );
    Directory('${root.path}/attachments').createSync();
    File('${root.path}/attachments/a.enc').writeAsBytesSync(
      Uint8List.fromList(List.generate(4096, (j) => j % 256)),
    );
    return root;
  }

  /// A recovery phrase and the key derived from it, the way the real vault
  /// does — through the mnemonic, so a change to either half is caught here.
  (List<String>, Uint8List) makePhrase() {
    final entropy = crypto().generateRecoveryEntropy();
    return (Mnemonic.fromEntropy(entropy), entropy);
  }

  Future<File> writeBackup(
    Directory root, {
    Uint8List? recoveryEntropy,
    String secret = passcode,
  }) async {
    final file = File('${tmp.path}/out.vault');
    final kek = recoveryEntropy == null
        ? null
        : crypto().deriveKeyFromRecoveryEntropy(recoveryEntropy);
    try {
      await format().write(
        destination: file,
        passcode: secret,
        recoveryKek: kek,
        vaultRoot: root,
        counts: {'entry_count': 7, 'day_count': 3, 'attachment_count': 1},
      );
    } finally {
      kek?.dispose();
    }
    return file;
  }

  Future<void> extractWithWords(File file, List<String> words) async {
    final kek =
        crypto().deriveKeyFromRecoveryEntropy(Mnemonic.toEntropy(words));
    try {
      await format().extract(
        source: file,
        staging: Directory('${tmp.path}/staging-${words.first}'),
        recoveryKek: kek,
      );
    } finally {
      kek.dispose();
    }
  }

  group('the thing he asked for', () {
    test('THE POINT: the twelve words open the backup file', () async {
      final (words, entropy) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root, recoveryEntropy: entropy);

      final kek = crypto()
          .deriveKeyFromRecoveryEntropy(Mnemonic.toEntropy(words));
      final summary = await format().extract(
        source: file,
        staging: Directory('${tmp.path}/staging'),
        recoveryKek: kek,
      );
      kek.dispose();

      expect(summary.entryCount, 7);
      // And the contents really came back, not just the header.
      final restored =
          File('${summary.staging.path}/vault.db').readAsBytesSync();
      final original = File('${root.path}/vault.db').readAsBytesSync();
      expect(restored, original,
          reason: 'the words have to produce the vault, not merely be accepted');
    });

    test('and the passcode still opens the very same file', () async {
      final (_, entropy) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root, recoveryEntropy: entropy);

      final summary = await format().extract(
        source: file,
        staging: Directory('${tmp.path}/staging-p'),
        passcode: passcode,
      );
      expect(summary.entryCount, 7,
          reason: 'adding a second way in must not remove the first');
    });

    test('the header says so, and the body moved to make room', () async {
      final (_, entropy) = makePhrase();
      final root = await fakeVault();

      final withPhrase = await writeBackup(root, recoveryEntropy: entropy);
      final infoWith = await format().inspect(withPhrase);
      expect(infoWith.header['recovery'], isTrue);
      expect(infoWith.hasRecoveryWrapper, isTrue);
      expect(infoWith.header['format_version'], 2);

      final without = File('${tmp.path}/plain.vault');
      await format().write(
        destination: without,
        passcode: passcode,
        vaultRoot: root,
        counts: {'entry_count': 7, 'day_count': 3, 'attachment_count': 1},
      );
      final infoWithout = await format().inspect(without);
      expect(infoWithout.header['recovery'], isFalse);
      expect(infoWithout.hasRecoveryWrapper, isFalse);

      // 24-byte nonce + 32-byte key + 16-byte tag.
      expect(infoWith.bodyStart - infoWithout.bodyStart, 72,
          reason: 'exactly one extra wrapper, and the reader must know where '
              'the body starts before it decrypts anything');
    });
  });

  group('and the things that must still be refused', () {
    test('somebody else\'s twelve words do not open it', () async {
      final (_, mine) = makePhrase();
      final (theirs, _) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root, recoveryEntropy: mine);

      await expectLater(
        extractWithWords(file, theirs),
        throwsA(isA<BackupError>()),
      );
    });

    test('the wrong passcode still does not open it', () async {
      final (_, entropy) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root, recoveryEntropy: entropy);

      await expectLater(
        format().extract(
          source: file,
          staging: Directory('${tmp.path}/s2'),
          passcode: 'not the passphrase',
        ),
        throwsA(isA<BackupError>()),
      );
    });

    test('words are refused politely on a file that has no recovery wrapper',
        () async {
      // The case that matters for anybody who has been using the app: their
      // older backups cannot be opened this way, and the app has to say which
      // it is rather than "wrong phrase".
      final (words, _) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root);

      await expectLater(
        extractWithWords(file, words),
        throwsA(
          isA<BackupError>().having(
            (e) => e.message,
            'message',
            contains('before recovery phrases could open backup files'),
          ),
        ),
      );
    });

    test('tampering with the recovery flag breaks the file', () async {
      // Flipping `recovery` to false would move the body by 72 bytes. The
      // header is authenticated as AAD on both wrappers AND covered by the
      // footer hash, so this must fail rather than produce garbage.
      final (_, entropy) = makePhrase();
      final root = await fakeVault();
      final file = await writeBackup(root, recoveryEntropy: entropy);

      final bytes = await file.readAsBytes();
      // The CBOR key "recovery" followed by CBOR true (0xf5).
      final needle = Cbor.encode('recovery');
      var at = -1;
      for (var i = 0; i + needle.length < bytes.length; i++) {
        var match = true;
        for (var j = 0; j < needle.length; j++) {
          if (bytes[i + j] != needle[j]) {
            match = false;
            break;
          }
        }
        if (match) {
          at = i + needle.length;
          break;
        }
      }
      expect(at, greaterThan(0), reason: 'the flag is in the header');
      expect(bytes[at], 0xf5, reason: 'CBOR true');
      bytes[at] = 0xf4; // CBOR false
      await file.writeAsBytes(bytes, flush: true);

      await expectLater(
        format().extract(
          source: file,
          staging: Directory('${tmp.path}/s3'),
          passcode: passcode,
        ),
        throwsA(isA<BackupError>()),
      );
    });
  });
}
