import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/mnemonic.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:sodium/sodium_sumo.dart';

/// Tests for the key hierarchy in `02-security/SECURITY-ARCHITECTURE.md` §1.
///
/// `04-technical/TECH-STACK.md` says these matter more than the app code,
/// because a bug here does not annoy someone — it makes their four-year record
/// permanently unreadable. So the emphasis is on the failure paths: wrong key,
/// tampered envelope, downgraded parameters. Anything that must fail is tested
/// for failing, not just for succeeding.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;

  // Argon2id at 128 MiB is slow by design. Tests that do not care about the
  // real parameters use the cheapest legal ones so the suite stays fast enough
  // to run constantly — a test suite nobody waits for is a test suite nobody
  // runs. The real parameters are exercised in stack_verification_test.dart and
  // measured again on the phone.
  late int fastMem;
  late int fastOps;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
    fastMem = sodium.crypto.pwhash.memLimitMin;
    fastOps = sodium.crypto.pwhash.opsLimitMin;
  });

  group('randomness', () {
    test('never returns the same bytes twice', () {
      final seen = <String>{};
      for (var i = 0; i < 128; i++) {
        seen.add(crypto.randomBytes(32).join(','));
      }
      expect(seen, hasLength(128));
    });

    test('generated keys and salts are the right size', () {
      final dek = crypto.generateDek();
      expect(dek.length, VaultCrypto.keyBytes);
      expect(crypto.generateSalt(), hasLength(sodium.crypto.pwhash.saltBytes));
      expect(crypto.generateRecoveryEntropy(), hasLength(16));
      dek.dispose();
    });

    test('two DEKs are never equal', () {
      final a = crypto.generateDek();
      final b = crypto.generateDek();
      expect(a.extractBytes(), isNot(equals(b.extractBytes())));
      a.dispose();
      b.dispose();
    });
  });

  group('passcode → key', () {
    test('same passcode and salt give the same key', () {
      final salt = crypto.generateSalt();
      final a = crypto.deriveKeyFromPasscode(
          passcode: 'correct horse', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      final b = crypto.deriveKeyFromPasscode(
          passcode: 'correct horse', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      expect(a.extractBytes(), equals(b.extractBytes()));
      a.dispose();
      b.dispose();
    });

    test('a different passcode gives a different key', () {
      final salt = crypto.generateSalt();
      final a = crypto.deriveKeyFromPasscode(
          passcode: 'correct horse', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      final b = crypto.deriveKeyFromPasscode(
          passcode: 'correct horsf', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      expect(a.extractBytes(), isNot(equals(b.extractBytes())));
      a.dispose();
      b.dispose();
    });

    test('a different salt gives a different key', () {
      // Why salts exist: two people who pick the same passcode must not end up
      // with the same key, and precomputed tables must be useless.
      final a = crypto.deriveKeyFromPasscode(
          passcode: 'same', salt: crypto.generateSalt(), memLimit: fastMem, opsLimit: fastOps);
      final b = crypto.deriveKeyFromPasscode(
          passcode: 'same', salt: crypto.generateSalt(), memLimit: fastMem, opsLimit: fastOps);
      expect(a.extractBytes(), isNot(equals(b.extractBytes())));
      a.dispose();
      b.dispose();
    });

    test('a wrong-sized salt is refused', () {
      expect(
        () => crypto.deriveKeyFromPasscode(passcode: 'x', salt: Uint8List(4)),
        throwsArgumentError,
      );
    });

    test('an empty passcode still derives a key', () {
      // We must not crash on it. Policy about weak passcodes belongs in the UI:
      // SECURITY-ARCHITECTURE.md §9 says show honest strength feedback but never
      // block, because blocking just makes people quit.
      final key = crypto.deriveKeyFromPasscode(
          passcode: '', salt: crypto.generateSalt(), memLimit: fastMem, opsLimit: fastOps);
      expect(key.length, VaultCrypto.keyBytes);
      key.dispose();
    });

    test('unicode passcodes work', () {
      // A passphrase in Hindi, or with emoji, must behave like any other.
      final salt = crypto.generateSalt();
      final a = crypto.deriveKeyFromPasscode(
          passcode: 'मेरा पासकोड 🔑', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      final b = crypto.deriveKeyFromPasscode(
          passcode: 'मेरा पासकोड 🔑', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      expect(a.extractBytes(), equals(b.extractBytes()));
      a.dispose();
      b.dispose();
    });
  });

  group('recovery phrase → key', () {
    test('same entropy gives the same key', () {
      final entropy = crypto.generateRecoveryEntropy();
      final a = crypto.deriveKeyFromRecoveryEntropy(entropy);
      final b = crypto.deriveKeyFromRecoveryEntropy(entropy);
      expect(a.extractBytes(), equals(b.extractBytes()));
      a.dispose();
      b.dispose();
    });

    test('different entropy gives a different key', () {
      final a = crypto.deriveKeyFromRecoveryEntropy(crypto.generateRecoveryEntropy());
      final b = crypto.deriveKeyFromRecoveryEntropy(crypto.generateRecoveryEntropy());
      expect(a.extractBytes(), isNot(equals(b.extractBytes())));
      a.dispose();
      b.dispose();
    });

    test('wrong-sized entropy is refused', () {
      expect(() => crypto.deriveKeyFromRecoveryEntropy(Uint8List(32)), throwsArgumentError);
    });

    test('a phrase written down and typed back derives the same key', () {
      // The whole point of ADR-003, end to end: entropy becomes twelve words,
      // the words go on paper, the paper is typed back years later, and the
      // same key comes out.
      final entropy = crypto.generateRecoveryEntropy();
      final onPaper = Mnemonic.fromEntropy(entropy).join(' ');

      final typedBack = Mnemonic.toEntropy(onPaper.split(' '));
      final original = crypto.deriveKeyFromRecoveryEntropy(entropy);
      final recovered = crypto.deriveKeyFromRecoveryEntropy(typedBack);

      expect(recovered.extractBytes(), equals(original.extractBytes()));
      original.dispose();
      recovered.dispose();
    });
  });

  group('wrapping the DEK', () {
    test('round-trips', () {
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final wrapped = crypto.wrapKey(key: dek, kek: kek);
      final unwrapped = crypto.unwrapKey(wrapped: wrapped, kek: kek);
      expect(unwrapped.extractBytes(), equals(dek.extractBytes()));
      for (final k in [dek, kek, unwrapped]) {
        k.dispose();
      }
    });

    test('the wrapped bytes do not contain the key', () {
      // If this ever fails, the "envelope" is transparent and the whole design
      // is decorative.
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final wrapped = crypto.wrapKey(key: dek, kek: kek);
      final raw = dek.extractBytes();
      expect(_contains(wrapped.cipherText, raw), isFalse);
      expect(_contains(wrapped.nonce, raw), isFalse);
      dek.dispose();
      kek.dispose();
    });

    test('the wrong KEK fails, and that IS the wrong-passcode signal', () {
      // SECURITY-ARCHITECTURE.md §4: there is no stored password verifier, so a
      // failed unwrap is the only way a wrong passcode is detected. It must
      // throw, never return plausible garbage.
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final wrongKek = crypto.generateDek();
      final wrapped = crypto.wrapKey(key: dek, kek: kek);
      expect(
        () => crypto.unwrapKey(wrapped: wrapped, kek: wrongKek),
        throwsA(anything),
      );
      for (final k in [dek, kek, wrongKek]) {
        k.dispose();
      }
    });

    test('every single-bit change to the envelope is detected', () {
      // Not one flipped bit in one place — every byte position, both in the
      // ciphertext and in the nonce. Tamper-evidence with a gap is not
      // tamper-evidence.
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final wrapped = crypto.wrapKey(key: dek, kek: kek);

      for (var i = 0; i < wrapped.cipherText.length; i++) {
        final bytes = Uint8List.fromList(wrapped.cipherText)..[i] ^= 0x01;
        expect(
          () => crypto.unwrapKey(
            wrapped: WrappedKey(nonce: wrapped.nonce, cipherText: bytes),
            kek: kek,
          ),
          throwsA(anything),
          reason: 'flipping a bit in ciphertext byte $i went undetected',
        );
      }

      for (var i = 0; i < wrapped.nonce.length; i++) {
        final bytes = Uint8List.fromList(wrapped.nonce)..[i] ^= 0x01;
        expect(
          () => crypto.unwrapKey(
            wrapped: WrappedKey(nonce: bytes, cipherText: wrapped.cipherText),
            kek: kek,
          ),
          throwsA(anything),
          reason: 'flipping a bit in nonce byte $i went undetected',
        );
      }

      dek.dispose();
      kek.dispose();
    });

    test('a truncated envelope is refused', () {
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final wrapped = crypto.wrapKey(key: dek, kek: kek);
      for (var cut = 1; cut <= 4; cut++) {
        final short = Uint8List.fromList(
          wrapped.cipherText.sublist(0, wrapped.cipherText.length - cut),
        );
        expect(
          () => crypto.unwrapKey(
            wrapped: WrappedKey(nonce: wrapped.nonce, cipherText: short),
            kek: kek,
          ),
          throwsA(anything),
          reason: 'truncating by $cut bytes went undetected',
        );
      }
      dek.dispose();
      kek.dispose();
    });

    test('two wraps of the same key look completely different', () {
      // A fresh random nonce each time. If these matched, an observer could
      // tell that a passcode change had not actually changed anything.
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final a = crypto.wrapKey(key: dek, kek: kek);
      final b = crypto.wrapKey(key: dek, kek: kek);
      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.cipherText, isNot(equals(b.cipherText)));
      dek.dispose();
      kek.dispose();
    });
  });

  group('associated data — the parameter-downgrade defence', () {
    test('tampering with authenticated data breaks the unwrap', () {
      // The attack this stops: someone edits the keyring on disk to say
      // "Argon2id with 1 KiB of memory", making brute force cheap. Because the
      // parameters are authenticated as associated data, that edit breaks the
      // tag and the vault refuses to open at all.
      final dek = crypto.generateDek();
      final kek = crypto.generateDek();
      final header = Uint8List.fromList('memLimit=134217728;opsLimit=3'.codeUnits);
      final tamperedHeader = Uint8List.fromList('memLimit=00000001;opsLimit=1'.codeUnits);

      final wrapped = crypto.wrapKey(key: dek, kek: kek, associatedData: header);

      expect(
        crypto.unwrapKey(wrapped: wrapped, kek: kek, associatedData: header).extractBytes(),
        equals(dek.extractBytes()),
      );
      expect(
        () => crypto.unwrapKey(wrapped: wrapped, kek: kek, associatedData: tamperedHeader),
        throwsA(anything),
      );
      expect(
        () => crypto.unwrapKey(wrapped: wrapped, kek: kek),
        throwsA(anything),
        reason: 'omitting the associated data entirely must also fail',
      );

      dek.dispose();
      kek.dispose();
    });
  });

  group('subkeys', () {
    test('are deterministic for a given DEK and purpose', () {
      final dek = crypto.generateDek();
      final a = crypto.deriveSubkey(dek, KeyPurpose.database);
      final b = crypto.deriveSubkey(dek, KeyPurpose.database);
      expect(a.extractBytes(), equals(b.extractBytes()));
      dek.dispose();
      a.dispose();
      b.dispose();
    });

    test('different purposes give different keys', () {
      // Domain separation, §3 step 7. Breaking one subsystem must not hand over
      // any other.
      final dek = crypto.generateDek();
      final keys = <String>{};
      for (final purpose in KeyPurpose.values) {
        final k = crypto.deriveSubkey(dek, purpose);
        keys.add(k.extractBytes().join(','));
        k.dispose();
      }
      expect(keys, hasLength(KeyPurpose.values.length));
      dek.dispose();
    });

    test('no subkey equals the DEK it came from', () {
      // If a subkey were the master key, the separation would be theatre.
      final dek = crypto.generateDek();
      final master = dek.extractBytes();
      for (final purpose in KeyPurpose.values) {
        final k = crypto.deriveSubkey(dek, purpose);
        expect(k.extractBytes(), isNot(equals(master)), reason: purpose.name);
        k.dispose();
      }
      dek.dispose();
    });

    test('a different DEK gives entirely different subkeys', () {
      final a = crypto.generateDek();
      final b = crypto.generateDek();
      final ka = crypto.deriveSubkey(a, KeyPurpose.database);
      final kb = crypto.deriveSubkey(b, KeyPurpose.database);
      expect(ka.extractBytes(), isNot(equals(kb.extractBytes())));
      for (final k in [a, b, ka, kb]) {
        k.dispose();
      }
    });

    test('purpose ids are permanent and must never be renumbered', () {
      // A guard rather than a behaviour test. Renumbering silently changes the
      // database key, which means an existing vault stops opening with no error
      // that points at the cause.
      expect(KeyPurpose.database.subkeyId, 1);
      expect(KeyPurpose.attachmentIndex.subkeyId, 2);
      expect(KeyPurpose.thumbnails.subkeyId, 3);
    });
  });

  group('the whole hierarchy, end to end', () {
    test('either the passcode or the recovery phrase opens the same vault', () {
      // This is ADR-003 in one test: two independent ways in, one vault, and
      // the same database key out of both. If this fails, someone who forgets
      // their passcode loses everything despite having done the responsible
      // thing we told them to do at setup.
      final dek = crypto.generateDek();

      final salt = crypto.generateSalt();
      final kekP = crypto.deriveKeyFromPasscode(
          passcode: 'a quiet room', salt: salt, memLimit: fastMem, opsLimit: fastOps);
      final wrappedByPasscode = crypto.wrapKey(key: dek, kek: kekP);

      final entropy = crypto.generateRecoveryEntropy();
      final phrase = Mnemonic.fromEntropy(entropy);
      final kekR = crypto.deriveKeyFromRecoveryEntropy(entropy);
      final wrappedByPhrase = crypto.wrapKey(key: dek, kek: kekR);

      // Route one: the passcode.
      final viaPasscode = crypto.unwrapKey(
        wrapped: wrappedByPasscode,
        kek: crypto.deriveKeyFromPasscode(
            passcode: 'a quiet room', salt: salt, memLimit: fastMem, opsLimit: fastOps),
      );

      // Route two: twelve words off a piece of paper.
      final viaPhrase = crypto.unwrapKey(
        wrapped: wrappedByPhrase,
        kek: crypto.deriveKeyFromRecoveryEntropy(
          Mnemonic.toEntropy(phrase),
        ),
      );

      expect(viaPasscode.extractBytes(), equals(dek.extractBytes()));
      expect(viaPhrase.extractBytes(), equals(dek.extractBytes()));

      // And both routes must produce the same database key, or the vault opens
      // one way and is unreadable the other.
      final dbViaPasscode = crypto.deriveSubkey(viaPasscode, KeyPurpose.database);
      final dbViaPhrase = crypto.deriveSubkey(viaPhrase, KeyPurpose.database);
      expect(dbViaPasscode.extractBytes(), equals(dbViaPhrase.extractBytes()));

      for (final k in [dek, kekP, kekR, viaPasscode, viaPhrase, dbViaPasscode, dbViaPhrase]) {
        k.dispose();
      }
    });

    test('changing the passcode rewraps without touching the DEK', () {
      // §1's whole justification for key wrapping: changing a passcode must be
      // instant and atomic, not a re-encryption of every byte the user owns.
      final dek = crypto.generateDek();
      final oldSalt = crypto.generateSalt();
      final oldKek = crypto.deriveKeyFromPasscode(
          passcode: 'old', salt: oldSalt, memLimit: fastMem, opsLimit: fastOps);
      final oldWrapped = crypto.wrapKey(key: dek, kek: oldKek);

      // Rewrap: unwrap with the old, wrap with the new. One 32-byte operation.
      final recovered = crypto.unwrapKey(wrapped: oldWrapped, kek: oldKek);
      final newSalt = crypto.generateSalt();
      final newKek = crypto.deriveKeyFromPasscode(
          passcode: 'new', salt: newSalt, memLimit: fastMem, opsLimit: fastOps);
      final newWrapped = crypto.wrapKey(key: recovered, kek: newKek);

      // The new passcode opens it, and the DEK is unchanged, so every byte
      // already written stays readable.
      final viaNew = crypto.unwrapKey(wrapped: newWrapped, kek: newKek);
      expect(viaNew.extractBytes(), equals(dek.extractBytes()));

      // The old passcode no longer opens the new envelope.
      expect(
        () => crypto.unwrapKey(wrapped: newWrapped, kek: oldKek),
        throwsA(anything),
      );

      for (final k in [dek, oldKek, newKek, recovered, viaNew]) {
        k.dispose();
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
