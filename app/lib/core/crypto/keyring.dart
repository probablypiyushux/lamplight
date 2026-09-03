import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../l10n/generated/app_localizations.dart';
import '../plain_words.dart';
import 'vault_crypto.dart';

/// Where the wrapped vault key lives on disk.
///
/// WHY THIS FILE EXISTS AT ALL
///
/// No specification document covers it, and there is a reason it is easy to
/// miss: the wrapped DEK cannot live inside the encrypted database, because you
/// need the DEK to open the database. Chicken and egg. So there is exactly one
/// small file that sits outside the encryption, and this is it.
///
/// WHAT IS IN IT, AND WHY THAT IS SAFE
///
/// Nothing secret. The wrapped keys are 32 bytes of noise without a passcode;
/// the salt is not a secret (it exists so two people with the same passcode get
/// different keys); the Argon2id parameters are not secret and *must* be
/// readable before unlocking, because you cannot derive the key without them.
/// Every password-based format has this property — age, LUKS and Signal's own
/// backups all store their KDF parameters in the clear.
///
/// WHAT STOPS SOMEONE EDITING IT
///
/// The parameters are authenticated as associated data on both wrapped keys.
/// An attacker who rewrites `memLimit` to 1 to make brute force cheap breaks
/// the authentication tag, and the vault refuses to open rather than opening
/// weakly. `02-security/SECURITY-ARCHITECTURE.md` §4 calls this out; the backup
/// format in `04-technical/BACKUP-FILE-FORMAT.md` uses the same trick on its
/// header, deliberately, so there is one idea to understand rather than two.
///
/// WHY JSON RATHER THAN THE CBOR THE BACKUP FORMAT USES
///
/// CBOR would mean another dependency for a file that holds six fields. JSON is
/// in the standard library, and being able to open this file in a text editor
/// and see exactly what is stored is worth something to an auditor — and to
/// anyone who wants to check we are not quietly keeping a copy of the key.
class Keyring {
  const Keyring({
    required this.version,
    required this.salt,
    required this.memLimit,
    required this.opsLimit,
    required this.wrappedByPasscode,
    this.wrappedByRecovery,
    this.recoveryKekForBackups,
    this.biometric,
  });

  /// Format version. Bumped only on a breaking change, and every version's
  /// reader stays in the codebase forever — a vault created today must open in
  /// 2035, which is the same promise the backup format makes.
  static const int currentVersion = 1;

  final int version;

  /// Argon2id salt. Not secret.
  final Uint8List salt;

  /// The Argon2id cost used when this vault was created.
  ///
  /// Read from here, never from [VaultCrypto.defaultMemLimit]. If a future
  /// release raises the defaults and we derived with the new numbers, every
  /// existing vault would fail to open with no explanation. Instead the vault
  /// keeps its own parameters until it is deliberately re-keyed.
  final int memLimit;
  final int opsLimit;

  /// The DEK, sealed so the passcode opens it.
  final WrappedKey wrappedByPasscode;

  /// The DEK, sealed so the recovery phrase opens it. ADR-003.
  ///
  /// Nullable only so a vault can be constructed before the user has confirmed
  /// they wrote their words down. It must be non-null by the end of onboarding,
  /// or the user has no way back in after forgetting their passcode.
  final WrappedKey? wrappedByRecovery;

  /// KEK-R, sealed under the DEK, so backups can be written with a recovery
  /// wrapper. **ISSUE 17.**
  ///
  /// ── WHY THIS EXISTS, AND WHY IT IS NOT THE ENTROPY ──────────────────────
  ///
  /// He asked for the twelve words to open the `.vault` file, not only the app.
  /// To write that second wrapper into a backup, the app needs KEK-R at backup
  /// time — and the recovery entropy is generated once at creation, shown once,
  /// and deliberately never stored. That is correct and is not being changed.
  ///
  /// So what is stored is **the derived key, not the words**. `KEK-R =
  /// BLAKE2b("lamplight/recovery-kek/v1" ‖ entropy)` is one-way: anybody who
  /// gets this value can open backups of this vault, and can never work out the
  /// twelve words from it.
  ///
  /// ── WHAT IT COSTS, SAID PLAINLY ─────────────────────────────────────────
  ///
  /// It is sealed under the DEK, so reading it requires having already unlocked
  /// the vault. An attacker who has done that can decrypt every note, every
  /// photograph and every recording, and can make their own backup of all of
  /// it. Handing them KEK-R gives them the ability to open backup files of the
  /// same vault — which contain the data they are already holding.
  ///
  /// **What it does not give them is the phrase.** They cannot use it to
  /// recover the words, so they cannot use it to unlock the app after a
  /// passcode change, and they cannot write it down and come back in a year.
  /// That is the line that matters, and a hash is what keeps it.
  ///
  /// Null for every vault created before this existed. Filled in the next time
  /// the user unlocks with their recovery phrase, which is the only other
  /// moment the app legitimately holds the entropy.
  final WrappedKey? recoveryKekForBackups;

  /// The third envelope: the DEK sealed under a per-device secret that Android
  /// keeps in the secure element and will not release without a fingerprint.
  ///
  /// Null until somebody turns it on, and null again the moment a new biometric
  /// is enrolled on the phone — the keystore key is destroyed by design when
  /// that happens, so anyone who adds their own finger inherits nothing.
  final BiometricWrapper? biometric;

  /// What the **passcode** wrapper authenticates.
  ///
  /// Built from the parameters that decide how expensive an attack is, because
  /// those are exactly what an attacker would want to weaken. Rewriting
  /// `memLimit` to 1 in this file breaks the tag and the vault refuses to open.
  ///
  /// The salt is in here, which means it cannot change without rewrapping.
  Uint8List associatedDataForPasscode() => Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'v': version,
            'wrapper': 'passcode',
            'alg': 'argon2id',
            'mem': memLimit,
            'ops': opsLimit,
            'salt': base64.encode(salt),
          }),
        ),
      );

  /// What the sealed KEK-R authenticates. **ISSUE 17.**
  ///
  /// Its own domain string, so this envelope can never be confused with the
  /// passcode or recovery ones — the same discipline `associatedDataForRecovery`
  /// applies, for the same reason.
  Uint8List associatedDataForBackupKek() => Uint8List.fromList(
        utf8.encode(
            jsonEncode({'v': version, 'wrapper': 'recovery-kek-for-backups'})),
      );

  /// What the **recovery** wrapper authenticates.
  ///
  /// Deliberately separate, and this is not a stylistic choice — it is a bug
  /// fix. Both wrappers originally authenticated one shared header containing
  /// the Argon2id salt. Changing the passcode changes that salt, which would
  /// have silently invalidated the recovery wrapper: the twelve words would
  /// stop working, with no error and no warning, and nobody would discover it
  /// until the day they forgot their passcode and reached for the paper. That
  /// is the worst possible time to find out.
  ///
  /// The recovery wrapper has no KDF parameters of its own — the phrase is
  /// already full-strength entropy, so there is nothing to weaken. It
  /// authenticates its version and its role, and nothing that a passcode
  /// change touches.
  Uint8List associatedDataForRecovery() => Uint8List.fromList(
        utf8.encode(jsonEncode({'v': version, 'wrapper': 'recovery'})),
      );

  /// Authenticated data for the biometric wrapper — the third envelope.
  ///
  /// Its own, like the other two, and for the same reason: nothing that a
  /// passcode change touches may appear here, or changing the passcode would
  /// silently break the fingerprint and nobody would find out until the morning
  /// it stopped working.
  Uint8List associatedDataForBiometric() => Uint8List.fromList(
        utf8.encode(jsonEncode({'v': version, 'wrapper': 'biometric'})),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'kdf': 'argon2id',
        'salt': base64.encode(salt),
        'memLimit': memLimit,
        'opsLimit': opsLimit,
        'passcode': {
          'nonce': base64.encode(wrappedByPasscode.nonce),
          'key': base64.encode(wrappedByPasscode.cipherText),
        },
        if (wrappedByRecovery != null)
          'recovery': {
            'nonce': base64.encode(wrappedByRecovery!.nonce),
            'key': base64.encode(wrappedByRecovery!.cipherText),
          },
        // ISSUE 17. Additive, and the version deliberately does not move for
        // it, for the same reason the biometric wrapper below does not: an
        // older build ignores the field and opens the vault exactly as before.
        if (recoveryKekForBackups != null)
          'recoveryKekForBackups': {
            'nonce': base64.encode(recoveryKekForBackups!.nonce),
            'key': base64.encode(recoveryKekForBackups!.cipherText),
          },
        // Additive, and the version deliberately does not move for it. An older
        // build reading this file ignores the field and opens the vault with
        // the passcode exactly as before — which is the whole point of the
        // format being a map rather than a struct. The worst an old build can
        // do is drop the field on a rewrite, and the cost of that is setting
        // the fingerprint up again.
        if (biometric != null) ...biometric!.toJson(),
      };

  factory Keyring.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int;
    if (version > currentVersion) {
      throw KeyringException(
        'This vault was made by a newer version of Lamplight. Update the app to '
        'open it.',
        problem: KeyringProblem.newerVersion,
      );
    }
    WrappedKey read(Map<String, dynamic> m) => WrappedKey(
          nonce: base64.decode(m['nonce'] as String),
          cipherText: base64.decode(m['key'] as String),
        );
    final recovery = json['recovery'] as Map<String, dynamic>?;
    final backupKek =
        json['recoveryKekForBackups'] as Map<String, dynamic>?;
    final biometric = json['biometric'] as Map<String, dynamic>?;
    return Keyring(
      version: version,
      salt: base64.decode(json['salt'] as String),
      memLimit: json['memLimit'] as int,
      opsLimit: json['opsLimit'] as int,
      wrappedByPasscode: read(json['passcode'] as Map<String, dynamic>),
      wrappedByRecovery: recovery == null ? null : read(recovery),
      recoveryKekForBackups: backupKek == null ? null : read(backupKek),
      biometric:
          biometric == null ? null : BiometricWrapper.fromJson(biometric),
    );
  }

  Keyring copyWith({
    BiometricWrapper? biometric,
    WrappedKey? wrappedByPasscode,
    WrappedKey? wrappedByRecovery,
    WrappedKey? recoveryKekForBackups,
    Uint8List? salt,
    int? memLimit,
    int? opsLimit,
  }) =>
      Keyring(
        version: version,
        salt: salt ?? this.salt,
        memLimit: memLimit ?? this.memLimit,
        opsLimit: opsLimit ?? this.opsLimit,
        wrappedByPasscode: wrappedByPasscode ?? this.wrappedByPasscode,
        wrappedByRecovery: wrappedByRecovery ?? this.wrappedByRecovery,
        recoveryKekForBackups:
            recoveryKekForBackups ?? this.recoveryKekForBackups,
        biometric: biometric ?? this.biometric,
      );
}

/// Reads and writes the keyring file.
class KeyringStore {
  const KeyringStore(this.file);

  final File file;

  bool existsSync() => file.existsSync();

  Future<Keyring> read() async {
    final text = await file.readAsString();
    try {
      return Keyring.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on KeyringException {
      rethrow;
    } catch (e) {
      // A keyring we cannot parse means a vault we cannot open. Say so plainly
      // rather than throwing a FormatException at a person — the message goes
      // in front of someone who may have just lost years of writing.
      throw const KeyringException(
        'The vault key file is damaged and cannot be read. If you have a backup '
        'file, restore from it.',
        problem: KeyringProblem.damaged,
      );
    }
  }

  /// Writes atomically: a new file, flushed, then renamed over the old one.
  ///
  /// A half-written keyring is an unopenable vault. `rename` within a directory
  /// is atomic on every filesystem we target, so at no point does the real path
  /// contain a partial file — a power cut leaves either the old keyring or the
  /// new one, never a broken one.
  Future<void> write(Keyring keyring) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.new');
    final handle = await temp.open(mode: FileMode.writeOnly);
    try {
      await handle.writeString(jsonEncode(keyring.toJson()));
      await handle.flush();
    } finally {
      await handle.close();
    }
    await temp.rename(file.path);
  }
}

/// Why a keyring could not be opened. **ROUND FIFTEEN.**
///
/// Same argument as `BackupProblem`: this is thrown from `core/`, where there
/// is no `BuildContext`, and it is read by somebody at the lock screen — one of
/// the two worst moments to be handed a language they do not use.
enum KeyringProblem {
  /// The vault was written by a newer Lamplight than this one.
  newerVersion,

  /// The keyring file itself will not parse.
  damaged,
}

class KeyringException implements Exception, PlainlySaid, Localisable {
  const KeyringException(this.message, {this.problem});

  final String message;

  /// What went wrong, for a screen that can translate it. Null on the
  /// programmer-facing throws, which a person never sees.
  final KeyringProblem? problem;

  @override
  String get plainMessage => message;

  @override
  String describeIn(L l) => switch (problem) {
        null => message,
        KeyringProblem.newerVersion => l.vaultKeyringNewerVersion,
        KeyringProblem.damaged => l.vaultKeyringDamaged,
      };

  @override
  String toString() => message;
}

/// The DEK sealed by Android's keystore, plus what is needed to open it again.
///
/// Two layers, and both matter:
///
///  * `sealed`/`iv` are what the **keystore** produced when it encrypted our
///    per-device biometric secret. Only the secure element can undo that, and
///    only after a fingerprint.
///  * `wrapped` is the DEK inside our own XChaCha20-Poly1305 envelope, keyed by
///    that secret, authenticating [Keyring.associatedDataForBiometric].
///
/// The second layer is what makes this envelope structurally identical to the
/// passcode and recovery ones rather than a special case — and it means the
/// thing crossing the platform channel is a per-device secret rather than the
/// key to everything the user has ever written.
class BiometricWrapper {
  const BiometricWrapper({
    required this.sealed,
    required this.iv,
    required this.wrapped,
  });

  /// The biometric secret, encrypted by the keystore key.
  final Uint8List sealed;

  /// The GCM nonce the keystore chose. Not secret; required to decrypt.
  final Uint8List iv;

  /// The DEK, wrapped under the biometric secret.
  final WrappedKey wrapped;

  Map<String, dynamic> toJson() => {
        'biometric': {
          'sealed': base64.encode(sealed),
          'iv': base64.encode(iv),
          'nonce': base64.encode(wrapped.nonce),
          'key': base64.encode(wrapped.cipherText),
        }
      };

  factory BiometricWrapper.fromJson(Map<String, dynamic> m) => BiometricWrapper(
        sealed: base64.decode(m['sealed'] as String),
        iv: base64.decode(m['iv'] as String),
        wrapped: WrappedKey(
          nonce: base64.decode(m['nonce'] as String),
          cipherText: base64.decode(m['key'] as String),
        ),
      );
}

/// Drops the biometric wrapper.
///
/// A separate method rather than `copyWith(biometric: null)` because copyWith's
/// null means "leave it alone" — there is no way to express "remove it" with
/// optional named parameters, and a `copyWith` that silently cannot clear a
/// field is a trap somebody falls into once per project.
extension KeyringWithoutBiometric on Keyring {
  Keyring withoutBiometric() => Keyring(
        version: version,
        salt: salt,
        memLimit: memLimit,
        opsLimit: opsLimit,
        wrappedByPasscode: wrappedByPasscode,
        wrappedByRecovery: wrappedByRecovery,
      );
}
