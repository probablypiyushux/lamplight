// Proves the third-party stack does what 02-security/SECURITY-ARCHITECTURE.md
// assumes it does, BEFORE any Lamplight code is written on top of it.
//
// This is not a test of our code — there is none yet. It tests our ASSUMPTIONS.
// 04-technical/TECH-STACK.md carries a checklist saying nothing gets built
// until these are confirmed by running them. Two packages named in the original
// spec turned out to be end-of-life; assuming the rest behave as documented
// would be the same mistake with a longer fuse.
//
// If something here fails, the answer is a different package, not a workaround.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late SodiumSumo sodium;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  group('libsodium', () {
    test('loads and reports its version', () {
      // ignore: avoid_print
      print('  libsodium ${sodium.version}');
      expect(sodium.version.major, greaterThanOrEqualTo(1));
    });

    test('randombytes does not obviously repeat', () {
      // SECURITY-ARCHITECTURE.md section 2 calls predictable randomness "the
      // single most common fatal mistake in amateur crypto". No test can prove
      // an RNG is good, but this proves it is not catastrophically broken.
      final seen = <String>{};
      for (var i = 0; i < 64; i++) {
        final b = sodium.randombytes.buf(32);
        expect(b.length, 32);
        expect(b.every((x) => x == 0), isFalse, reason: 'all-zero draw');
        seen.add(base64.encode(b));
      }
      expect(seen.length, 64, reason: 'a draw repeated');
    });

    test('Argon2id accepts the documented parameters and is deterministic', () {
      // SECURITY-ARCHITECTURE.md section 2a: m=128 MiB, t=3, p=1.
      // The ~500ms-1s budget is for a phone; a laptop is not a phone, so the
      // timing printed here is context, not the real measurement. What this
      // proves is that the parameters are accepted and the key is stable —
      // if it were not, no vault could ever be unlocked twice.
      const memLimit = 128 * 1024 * 1024;
      const opsLimit = 3;

      final salt = sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);
      final password = Int8List.fromList(utf8.encode('a test passcode'));

      final sw = Stopwatch()..start();
      final k1 = sodium.crypto.pwhash(
        outLen: 32,
        password: password,
        salt: salt,
        opsLimit: opsLimit,
        memLimit: memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      );
      sw.stop();
      // ignore: avoid_print
      print('  Argon2id m=128MiB t=3 p=1 -> ${sw.elapsedMilliseconds}ms here');

      expect(k1.length, 32);

      final k2 = sodium.crypto.pwhash(
        outLen: 32,
        password: password,
        salt: salt,
        opsLimit: opsLimit,
        memLimit: memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      );
      expect(k2.extractBytes(), equals(k1.extractBytes()),
          reason: 'same passcode and salt must give the same key');

      final k3 = sodium.crypto.pwhash(
        outLen: 32,
        password: password,
        salt: sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes),
        opsLimit: opsLimit,
        memLimit: memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      );
      expect(k3.extractBytes(), isNot(equals(k1.extractBytes())),
          reason: 'a different salt must give a different key');

      for (final k in [k1, k2, k3]) {
        k.dispose();
      }
    });

    test('XChaCha20-Poly1305 round-trips and fails loudly when it should', () {
      final aead = sodium.crypto.aeadXChaCha20Poly1305IETF;
      final key = aead.keygen();
      final nonce = sodium.randombytes.buf(aead.nonceBytes);
      final message = Uint8List.fromList(utf8.encode('the note body'));

      final cipherText = aead.encrypt(
        message: message,
        nonce: nonce,
        key: key,
      );
      expect(
        aead.decrypt(cipherText: cipherText, nonce: nonce, key: key),
        equals(message),
      );

      // A wrong key must throw, never return garbage. SECURITY-ARCHITECTURE.md
      // section 4 rests on this: a failed unwrap IS the wrong-passcode signal,
      // because we deliberately store no password verifier to test against.
      final wrongKey = aead.keygen();
      expect(
        () => aead.decrypt(cipherText: cipherText, nonce: nonce, key: wrongKey),
        throwsA(anything),
        reason: 'wrong key must fail',
      );

      final tampered = Uint8List.fromList(cipherText);
      tampered[tampered.length ~/ 2] ^= 0x01;
      expect(
        () => aead.decrypt(cipherText: tampered, nonce: nonce, key: key),
        throwsA(anything),
        reason: 'tampered ciphertext must fail',
      );

      final truncated =
          Uint8List.fromList(cipherText.sublist(0, cipherText.length - 1));
      expect(
        () => aead.decrypt(cipherText: truncated, nonce: nonce, key: key),
        throwsA(anything),
        reason: 'truncated ciphertext must fail',
      );

      key.dispose();
      wrongKey.dispose();
    });

    test('empty and 1-byte messages round-trip', () {
      // TECH-STACK.md testing requirement 1 names these sizes explicitly.
      // Boundary handling is where chunking code dies.
      final aead = sodium.crypto.aeadXChaCha20Poly1305IETF;
      final key = aead.keygen();
      for (final size in [0, 1]) {
        final nonce = sodium.randombytes.buf(aead.nonceBytes);
        final message = Uint8List(size);
        final ct = aead.encrypt(message: message, nonce: nonce, key: key);
        expect(
          aead.decrypt(cipherText: ct, nonce: nonce, key: key),
          equals(message),
          reason: 'failed at size $size',
        );
      }
      key.dispose();
    });

    test('BLAKE2b gives the 256-bit digest the spec asks for', () {
      final digest = sodium.crypto.genericHash(
        message: Uint8List.fromList(utf8.encode('whole file integrity')),
        outLen: 32,
      );
      expect(digest.length, 32);
    });

    test('secretStream is available for chunked file encryption', () {
      // SECURITY-ARCHITECTURE.md section 6 describes hand-rolled 64 KiB frames,
      // a nonce built from a file nonce plus chunk index, and a flagged final
      // chunk so truncation is detected. libsodium's secretstream already IS
      // that construction. Confirming it exists, because using the library's
      // version is strictly safer than rebuilding it ourselves.
      expect(sodium.crypto.secretStream.keyBytes, greaterThan(0));
      expect(sodium.crypto.secretStream.headerBytes, greaterThan(0));
    });
  });

  group('SQLCipher', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_verify'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('the bundled build really is SQLCipher, not plain SQLite', () {
      final db = sqlite3.openInMemory();
      final result = db.select('PRAGMA cipher_version;');
      // ignore: avoid_print
      print('  sqlite ${sqlite3.version.libVersion}');
      // ignore: avoid_print
      print('  cipher ${result.isEmpty ? "NONE" : result.first.values.first}');
      expect(
        result,
        isNotEmpty,
        reason: 'PRAGMA cipher_version returned nothing, so this is plain '
            'SQLite and the vault would NOT be encrypted. Check the '
            'hooks/user_defines block in pubspec.yaml.',
      );
      db.close();
    });

    test('FTS5 is available', () {
      // DATA-MODEL.md and ADR-006 both depend on this. TECH-STACK.md says that
      // if the SQLCipher build lags far enough upstream to lose FTS5, we switch
      // to sqlite3mc. This is the test that decides it.
      final db = sqlite3.openInMemory();
      db.execute('CREATE VIRTUAL TABLE t USING fts5(body);');
      db.execute("INSERT INTO t(body) VALUES ('slept badly again');");
      expect(db.select("SELECT * FROM t WHERE t MATCH 'badly';"), hasLength(1));
      db.close();
    });

    test('a keyed database is unreadable on disk and rejects a wrong key', () {
      final path = '${tmp.path}/vault.db';
      const marker = 'PLAINTEXT_CANARY_9f3a2b7c';

      // A raw 256-bit key passed as x'...', so SQLCipher uses it directly
      // rather than running its own KDF over a passphrase. The real key will
      // be HKDF(DEK, "db") per SECURITY-ARCHITECTURE.md section 3 step 7.
      final hexKey = _hex(sodium.randombytes.buf(32));

      var db = sqlite3.open(path);
      db.execute('PRAGMA key = "x\'$hexKey\'";');
      db.execute('CREATE TABLE entries (id INTEGER PRIMARY KEY, body TEXT);');
      db.execute("INSERT INTO entries (body) VALUES ('$marker');");
      db.close();

      final bytes = File(path).readAsBytesSync();
      expect(bytes.length, greaterThan(0));
      expect(
        _contains(bytes, utf8.encode(marker)),
        isFalse,
        reason: 'the note text was found verbatim inside the database file, '
            'so the database is NOT encrypted',
      );
      expect(
        _contains(bytes.sublist(0, 16), utf8.encode('SQLite format 3')),
        isFalse,
        reason: 'plain SQLite header present, so the file is not encrypted',
      );

      db = sqlite3.open(path);
      db.execute('PRAGMA key = "x\'$hexKey\'";');
      expect(db.select('SELECT body FROM entries;').first['body'], marker);
      db.close();

      final wrongHex = _hex(sodium.randombytes.buf(32));
      db = sqlite3.open(path);
      db.execute('PRAGMA key = "x\'$wrongHex\'";');
      expect(
        () => db.select('SELECT body FROM entries;'),
        throwsA(anything),
        reason: 'a wrong key must fail loudly, never return garbage',
      );
      db.close();
    });

    test('WAL mode works on an encrypted database', () {
      // SECURITY-ARCHITECTURE.md section 5 requires WAL for crash safety, and
      // section 7 leans on it for autosave: a power loss mid-write must not
      // corrupt the vault.
      final path = '${tmp.path}/wal.db';
      final hexKey = _hex(sodium.randombytes.buf(32));
      final db = sqlite3.open(path);
      db.execute('PRAGMA key = "x\'$hexKey\'";');
      final mode = db.select('PRAGMA journal_mode=WAL;').first.values.first;
      expect(mode.toString().toLowerCase(), 'wal');
      db.close();
    });
  });
}

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Substring search over bytes, used to prove note text is absent from a file.
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
