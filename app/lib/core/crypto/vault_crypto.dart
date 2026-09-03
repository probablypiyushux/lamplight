import 'dart:convert';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

/// The key hierarchy from `02-security/SECURITY-ARCHITECTURE.md` §1.
///
/// THE ONE IDEA
///
/// The vault is encrypted with a single random key — the DEK — and that key is
/// itself encrypted several times over, once for each way you are allowed to
/// unlock it. Three sealed envelopes, each containing the same key, each opened
/// a different way: the passcode, the recovery phrase, and (later) the phone's
/// hardware key store.
///
/// The obvious alternative is to derive the encryption key straight from the
/// passcode. §1 explains why that is a mistake, and it is worth restating here
/// because it is the reason this file exists at all: changing your passcode
/// would mean re-encrypting every byte you have ever written. With four years
/// of photos that is a twenty-minute operation that can be interrupted halfway
/// and destroy everything. With key wrapping, changing the passcode rewraps one
/// 32-byte key. It is instant, atomic, and cannot half-fail.
///
/// WHAT THIS CLASS DELIBERATELY DOES NOT DO
///
/// It does not touch the filesystem, and it does not decide policy. It is pure
/// key mathematics so that it stays small enough for an auditor to read in an
/// afternoon, which `CLAUDE.md` rule 5 requires. Storage lives in `keyring.dart`;
/// lifecycle and locking live in the vault state machine.
class VaultCrypto {
  VaultCrypto(this._sodium);

  final SodiumSumo _sodium;

  /// Argon2id parameters, per `SECURITY-ARCHITECTURE.md` §2 and §2a.
  ///
  /// `p=1` rather than the originally drafted `p=4` because libsodium's
  /// Argon2id is deliberately single-threaded; memory was raised to compensate,
  /// since peak memory per guess is what actually costs an attacker.
  ///
  /// **Tuned on hardware, 18 Aug 2026.** 128 MiB / t=3 measured 170 ms on the
  /// development laptop but under 100 ms on the target phone — the phone was
  /// the faster machine. Raised to 256 MiB / t=4, roughly doubling the memory
  /// an attacker must commit to every single guess.
  ///
  /// **Why not higher, when the phone could clearly take it.** These numbers
  /// are written into the vault's keyring and into every backup file, so a
  /// vault created at this cost must still open on a *slower* device — a cheap
  /// phone years from now, or whatever the user restores onto after this one
  /// dies. Tuning to the fastest machine available makes your own backup
  /// unopenable on a slow one, which stops being a security setting and becomes
  /// a data-loss bug. 256 MiB also has to allocate on a 2 GB device without
  /// being killed. At ~250-300 ms here, a device four times slower still lands
  /// near 1 s, which is the edge of the budget in §2.
  ///
  /// These are DEFAULTS for new vaults only. An existing vault always uses the
  /// parameters stored in its own keyring — otherwise raising the defaults in a
  /// future release would lock every existing user out of their own notes.
  static const int defaultMemLimit = 256 * 1024 * 1024;
  static const int defaultOpsLimit = 4;

  /// Length of every key in this system.
  static const int keyBytes = 32;

  /// Domain separator for the recovery-phrase key derivation.
  ///
  /// Version suffix included on purpose: if this ever has to change, old
  /// vaults must keep deriving the old way or their recovery phrases stop
  /// working. A phrase written on paper in 2026 has to keep working.
  static const String _recoveryDomain = 'lamplight/recovery-kek/v1';

  /// libsodium's `crypto_kdf` context. Exactly 8 bytes, by definition.
  static const String _kdfContext = 'lamplght';

  // ───────────────────────────────────────────────────────────────────────────
  //  Randomness
  // ───────────────────────────────────────────────────────────────────────────

  /// Random bytes from the OS CSPRNG, and only from the OS CSPRNG.
  ///
  /// `SECURITY-ARCHITECTURE.md` §2 calls a predictable random source "the single
  /// most common fatal mistake in amateur crypto — if the randomness is
  /// predictable, everything else is theatre". libsodium's `randombytes` reads
  /// the platform generator (`getrandom`/`/dev/urandom` on Android). Never
  /// `Random()`. Never a seeded PRNG. Never a timestamp.
  Uint8List randomBytes(int length) => _sodium.randombytes.buf(length);

  /// A brand new Data Encryption Key. Generated once, at first launch, and
  /// never seen in plaintext outside RAM again.
  SecureKey generateDek() => _sodium.crypto.aeadXChaCha20Poly1305IETF.keygen();

  /// A fresh salt for passcode derivation. Stored in the keyring alongside the
  /// wrapped key — a salt is not secret, it exists so that two people with the
  /// same passcode get different keys, and so precomputed tables are useless.
  Uint8List generateSalt() => randomBytes(_sodium.crypto.pwhash.saltBytes);

  /// 128 bits of entropy for a twelve-word recovery phrase.
  Uint8List generateRecoveryEntropy() => randomBytes(16);

  // ───────────────────────────────────────────────────────────────────────────
  //  Turning secrets people hold into keys
  // ───────────────────────────────────────────────────────────────────────────

  /// Passcode → KEK-P, via Argon2id.
  ///
  /// This is the expensive step, and the expense IS the security. A six-digit
  /// PIN has only a million possibilities; what stops an attacker trying all of
  /// them against a stolen phone is that each attempt costs 128 MiB of memory
  /// and a few hundred milliseconds, and memory is the one resource that cannot
  /// be parallelised cheaply on a GPU or an ASIC.
  ///
  /// [memLimit] and [opsLimit] must come from the vault's own keyring when
  /// unlocking an existing vault, never from the constants above.
  SecureKey deriveKeyFromPasscode({
    required String passcode,
    required Uint8List salt,
    int memLimit = defaultMemLimit,
    int opsLimit = defaultOpsLimit,
  }) {
    if (salt.length != _sodium.crypto.pwhash.saltBytes) {
      throw ArgumentError('salt must be ${_sodium.crypto.pwhash.saltBytes} bytes');
    }
    return _sodium.crypto.pwhash(
      outLen: keyBytes,
      password: Int8List.fromList(utf8.encode(passcode)),
      salt: salt,
      opsLimit: opsLimit,
      memLimit: memLimit,
      alg: CryptoPwhashAlgorithm.argon2id13,
    );
  }

  /// The same derivation, on a background isolate.
  ///
  /// ── WHY THIS EXISTS, AND WHY IT IS THE MOST IMPORTANT METHOD IN THE FILE ──
  ///
  /// Reported over and over as **"the app hangs"**, and it was never a bug in
  /// the ordinary sense — nothing was wrong with any line of code. It is
  /// architectural, and the shape of it is worth understanding because the same
  /// trap is waiting anywhere else expensive work meets a screen.
  ///
  /// Dart runs one isolate per thread and draws the interface on that isolate.
  /// While *anything* synchronous is running there, **no frame can be
  /// produced** — not a slow frame, no frame at all. [deriveKeyFromPasscode]
  /// chews 256 MiB of memory for a quarter of a second by design, because that
  /// cost is the security. Run on the UI isolate it does not make the app slow,
  /// it *stops* the app: the busy indicator freezes mid-beat, which is exactly
  /// how a person can tell the difference between "working" and "crashed", and
  /// they conclude crashed, because it looks identical.
  ///
  /// `Sodium.runIsolated` moves the work to a worker isolate and hands the
  /// resulting key back across as a native handle rather than as bytes on a
  /// port — so the derived key never becomes a plain `Uint8List` that the
  /// garbage collector might copy. The UI isolate stays free the whole time and
  /// the heartbeat keeps beating, which is the point.
  ///
  /// **The synchronous version stays** and is not deprecated. Tests use it, and
  /// so does any path already running off the UI isolate — spinning up a worker
  /// from a worker would be pure overhead.
  Future<SecureKey> deriveKeyFromPasscodeAsync({
    required String passcode,
    required Uint8List salt,
    int memLimit = defaultMemLimit,
    int opsLimit = defaultOpsLimit,
  }) {
    if (salt.length != _sodium.crypto.pwhash.saltBytes) {
      throw ArgumentError('salt must be ${_sodium.crypto.pwhash.saltBytes} bytes');
    }
    // Captured as locals so the closure carries the sodium handle and three
    // plain values, and not `this`. A closure that captures the enclosing
    // object drags whatever else that object grows a field for, later, into
    // every isolate spawn — a cost nobody would ever connect to this line.
    final sodium = _sodium;
    final password = Int8List.fromList(utf8.encode(passcode));
    return sodium.runIsolated(
      (_, _) => sodium.crypto.pwhash(
        outLen: keyBytes,
        password: password,
        salt: salt,
        opsLimit: opsLimit,
        memLimit: memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      ),
    );
  }

  /// Recovery-phrase entropy → KEK-R.
  ///
  /// No Argon2id here, and that is correct rather than an oversight: the input
  /// is already 128 bits of full-strength randomness from the OS generator, not
  /// a human-chosen secret. Argon2id exists to make *guessable* inputs
  /// expensive. There is nothing to guess here — an attacker would have to
  /// search 2^128, which no amount of key stretching would meaningfully change.
  ///
  /// A domain-separated BLAKE2b expands 16 bytes to 32. The domain string means
  /// this key can never collide with any other key derived from the same bytes.
  SecureKey deriveKeyFromRecoveryEntropy(Uint8List entropy) {
    if (entropy.length != 16) {
      throw ArgumentError('recovery entropy must be 16 bytes');
    }
    final input = Uint8List.fromList([
      ...utf8.encode(_recoveryDomain),
      ...entropy,
    ]);
    final derived = _sodium.crypto.genericHash(message: input, outLen: keyBytes);
    return SecureKey.fromList(_sodium, derived);
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Wrapping and unwrapping the DEK
  // ───────────────────────────────────────────────────────────────────────────

  /// Seals the DEK inside an envelope only [kek] can open.
  ///
  /// [associatedData] is authenticated but not encrypted. The keyring passes
  /// its own header there — the Argon2id parameters and the salt — so that
  /// tampering with them breaks the authentication tag. Without this an
  /// attacker with the file could rewrite `memLimit` down to 1 and make brute
  /// force cheap. §4 of the architecture calls this out specifically, and it is
  /// the same trick the backup format uses on its header.
  WrappedKey wrapKey({
    required SecureKey key,
    required SecureKey kek,
    Uint8List? associatedData,
  }) {
    final aead = _sodium.crypto.aeadXChaCha20Poly1305IETF;
    final nonce = randomBytes(aead.nonceBytes);
    final cipherText = aead.encrypt(
      message: key.extractBytes(),
      nonce: nonce,
      key: kek,
      additionalData: associatedData,
    );
    return WrappedKey(nonce: nonce, cipherText: cipherText);
  }

  /// Opens an envelope. Throws if [kek] is wrong or anything was tampered with.
  ///
  /// **A thrown exception here is how we detect a wrong passcode.** There is no
  /// stored hash of the passcode to compare against, deliberately — §4 explains
  /// that a password verifier would give an attacker something cheap to attack.
  /// The only way to test a guess is to run the full Argon2id and try the
  /// unwrap, which is exactly as expensive as we intend.
  SecureKey unwrapKey({
    required WrappedKey wrapped,
    required SecureKey kek,
    Uint8List? associatedData,
  }) {
    final plain = _sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
      cipherText: wrapped.cipherText,
      nonce: wrapped.nonce,
      key: kek,
      additionalData: associatedData,
    );
    return SecureKey.fromList(_sodium, plain);
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Subkeys
  // ───────────────────────────────────────────────────────────────────────────

  /// Derives a purpose-specific key from the DEK.
  ///
  /// §3 step 7: the database key is *derived from* the DEK, not the DEK itself.
  /// Domain separation — if one subsystem is ever broken, it does not hand over
  /// the master key or any other subsystem's key.
  ///
  /// Uses libsodium's `crypto_kdf` rather than the originally specified
  /// HKDF-SHA256; §2b records why. The security property is identical.
  SecureKey deriveSubkey(SecureKey dek, KeyPurpose purpose) {
    return _sodium.crypto.kdf.deriveFromKey(
      masterKey: dek,
      context: _kdfContext,
      subkeyId: BigInt.from(purpose.subkeyId),
      subkeyLen: keyBytes,
    );
  }
}

/// What a derived subkey is *for*.
///
/// The numeric ids are permanent. Changing one silently changes the key that
/// subsystem derives, which for the database means the vault no longer opens.
/// Add new purposes with new numbers; never renumber an existing one.
enum KeyPurpose {
  /// The SQLCipher database key. §3 step 7.
  database(1),

  /// Wraps the per-file keys in the attachment store. §6.
  attachmentIndex(2),

  /// Encrypts cached thumbnails. §6 — never plaintext JPEGs, because that is
  /// the most common way "encrypted" gallery apps leak everything, and forensic
  /// tools look for exactly this.
  thumbnails(3);

  const KeyPurpose(this.subkeyId);

  final int subkeyId;
}

/// A key sealed inside an authenticated envelope.
///
/// Safe to write to disk: without the corresponding KEK it is 32 bytes of
/// noise, and the Poly1305 tag means any modification is detected rather than
/// producing a plausible-looking wrong key.
class WrappedKey {
  const WrappedKey({required this.nonce, required this.cipherText});

  /// 24 bytes. XChaCha20's extended nonce is large enough that random values
  /// will never collide in practice, which removes an entire class of
  /// catastrophic implementation bug — §2 chose this cipher for that reason.
  final Uint8List nonce;

  /// The encrypted key plus its 16-byte authentication tag.
  final Uint8List cipherText;
}
