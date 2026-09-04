import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sodium/sodium_sumo.dart';

import '../backup/vault_file.dart' show BackupKey;
import '../platform/biometrics.dart';
import '../crypto/keyring.dart';
import '../crypto/mnemonic.dart';
import '../crypto/vault_crypto.dart';
import '../db/database.dart';
import '../storage/attachment_store.dart';

/// Whether the vault is open, and how it got that way.
enum VaultState {
  /// No vault on this device yet. First launch.
  uninitialised,

  /// A vault exists and is sealed. Keys are not in memory.
  locked,

  /// Open. The DEK and the database key are in RAM, and only in RAM.
  unlocked,
}

/// The lock/unlock state machine and the lifetime of every key.
///
/// WHAT THIS OWNS
///
/// The single answer to "is the vault open, and if so what may I use?". Feature
/// code asks this object for a database or an attachment store and never sees a
/// key — `CLAUDE.md` rule 5 requires that nothing outside `core/crypto` touches
/// raw key material, and this is the boundary that enforces it.
///
/// WHEN IT LOCKS
///
/// `03-product/UX-FLOWS.md` flow 7: immediately on backgrounding, which is
/// non-negotiable, plus an idle timeout defaulting to one minute. Both exist
/// because `02-security/THREAT-MODEL.md` ranks "the person who picks up the
/// unlocked phone" as by far the most likely adversary — a partner, a sibling,
/// someone at a party. That threat is defeated by locking early, not by
/// cryptography.
///
/// THE HONEST LIMIT ON ZEROING
///
/// `SECURITY-ARCHITECTURE.md` §8 states it and we repeat it here rather than
/// pretending otherwise: Dart is garbage-collected, so we cannot *guarantee*
/// a key is gone from memory. libsodium's `SecureKey` uses locked, guarded
/// allocations and is wiped on dispose, which is meaningfully better than a
/// plain list — but a determined attacker with the phone unlocked and RAM
/// access is outside what any managed runtime defends against. This applies
/// equally to most of the field. It belongs in the public threat model.
class Vault extends ChangeNotifier {
  Vault({
    required SodiumSumo sodium,
    required Directory root,
    Duration idleTimeout = const Duration(minutes: 1),
  })  : _sodium = sodium,
        _crypto = VaultCrypto(sodium),
        _root = root,
        _idleTimeout = idleTimeout,
        _keyringStore = KeyringStore(File('${root.path}/keyring.json'));

  final SodiumSumo _sodium;
  final VaultCrypto _crypto;
  final Directory _root;
  final KeyringStore _keyringStore;

  Duration _idleTimeout;
  Timer? _idleTimer;
  /// Fires a little before [_idleTimer], to raise [aboutToLock]. **ISSUE 21.**
  Timer? _warningTimer;

  /// True while the user is being *set up*, between [beginSetup] and
  /// [endSetup]. See [beginSetup] for why the idle clock does not run then.
  bool _inSetup = false;

  VaultState _state = VaultState.locked;
  SecureKey? _dek;
  VaultDatabase? _db;
  AttachmentStore? _attachments;

  /// The key silent backups are sealed with, for this session only.
  ///
  /// WHY THIS EXISTS AND WHAT IT COSTS
  ///
  /// A silent backup has to encrypt under something derived from the passcode,
  /// and the passcode is only in our hands for the instant of an unlock. The
  /// three options are: keep the passcode (a Dart `String`, which cannot be
  /// wiped and which the garbage collector may have copied — worse than a key,
  /// and it opens the vault as well as the backups); ask for it again every
  /// time (which is not silent); or derive the backup key once and keep that.
  ///
  /// This is the third. It is a libsodium `SecureKey` — locked, guarded, wiped
  /// on dispose — and it is narrower than the passcode, because it opens backup
  /// files and nothing else. It lives exactly as long as the DEK does and is
  /// destroyed by the same [lock] that destroys it. If the vault is locked,
  /// there is no silent backup key in memory either.
  ///
  /// Null when the user has not turned silent backups on, so someone who does
  /// not use the feature does not carry its key.
  BackupKey? _sessionBackupKey;

  /// The salt that key was derived from, kept so every silent backup file
  /// records the salt its own key came from. Reused across a session on
  /// purpose: re-deriving would mean another 256 MiB of Argon2id, and a salt
  /// exists to stop precomputation across *users*, which one per device does.
  Uint8List? _sessionBackupSalt;

  BackupKey? get sessionBackupKey => _sessionBackupKey;

  Uint8List? get sessionBackupSalt => _sessionBackupSalt;

  /// Called at unlock, while the passcode is still in scope.
  void keepSessionBackupKey(BackupKey key) {
    _sessionBackupKey?.dispose();
    _sessionBackupKey = key;
    _sessionBackupSalt = key.salt;
  }

  VaultState get state => _state;
  bool get isUnlocked => _state == VaultState.unlocked;

  /// Where everything lives. Needed by the backup writer, which reads the
  /// vault's files as bytes and never as rows.
  Directory get root => _root;

  /// The primitives, for the backup format.
  ///
  /// **These are algorithms, not keys.** `CLAUDE.md` rule 5 keeps raw key
  /// material inside `core/crypto` and out of feature code, and that still
  /// holds: `core/backup` derives its own key from a passcode the user has just
  /// typed and never sees the vault's DEK, which is exactly the property that
  /// makes a compromised backup file cost only that file.
  SodiumSumo get sodium => _sodium;

  VaultCrypto get crypto => _crypto;

  String get _databasePath => '${_root.path}/vault.db';

  /// The files that together *are* the vault.
  ///
  /// Listed once, here, because both the backup writer and the restore swap
  /// have to agree on them exactly. Forget `vault.db-wal` in one of the two and
  /// you get a backup that is missing the most recent writes, or a restore that
  /// leaves a stale write-ahead log next to a replaced database — which is a
  /// corrupt vault that looks fine until it does not.
  static const List<String> vaultFileNames = [
    'keyring.json',
    'vault.db',
    'vault.db-wal',
    'vault.db-shm',
  ];

  /// The open database. Throws if locked — a caller holding a stale reference
  /// after a lock is a bug we want loud, not silent.
  VaultDatabase get database {
    final db = _db;
    if (db == null) throw StateError('The vault is locked.');
    return db;
  }

  AttachmentStore get attachments {
    final a = _attachments;
    if (a == null) throw StateError('The vault is locked.');
    return a;
  }

  /// A new random id for a row, from the OS CSPRNG.
  ///
  /// Lives here so feature code never has to reach for a random source itself
  /// and risk picking `Random()`. `SECURITY-ARCHITECTURE.md` §2 is blunt about
  /// what a predictable generator costs, and the cheapest way to avoid it is
  /// to leave callers no reason to look elsewhere.
  String newId() => uuidV4(_crypto.randomBytes);

  /// Call once at startup, before anything else.
  Future<void> initialise() async {
    await _root.create(recursive: true);
    _state = _keyringStore.existsSync()
        ? VaultState.locked
        : VaultState.uninitialised;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Creating a vault
  // ───────────────────────────────────────────────────────────────────────────

  /// First launch. Generates the DEK, wraps it under the passcode and under a
  /// fresh recovery phrase, and opens the database.
  ///
  /// Returns the twelve words. **They are returned exactly once and never
  /// stored.** ADR-003: shown once, confirmed, then gone from our world
  /// entirely — which is what makes them unsubpoenable from us.
  Future<List<String>> create({required String passcode}) async {
    if (_keyringStore.existsSync()) {
      throw StateError('A vault already exists on this device.');
    }

    final dek = _crypto.generateDek();
    final salt = _crypto.generateSalt();

    // Build the keyring header first. Each wrapper authenticates part of it, so
    // the parameters have to be settled before anything is sealed. The
    // placeholder wrapper below is never written — it exists only so the header
    // can be constructed and its authenticated bytes computed.
    final skeleton = Keyring(
      version: Keyring.currentVersion,
      salt: salt,
      memLimit: VaultCrypto.defaultMemLimit,
      opsLimit: VaultCrypto.defaultOpsLimit,
      wrappedByPasscode: WrappedKey(nonce: Uint8List(0), cipherText: Uint8List(0)),
    );

    final kekP = await _crypto.deriveKeyFromPasscodeAsync(
      passcode: passcode,
      salt: salt,
      memLimit: skeleton.memLimit,
      opsLimit: skeleton.opsLimit,
    );
    final wrappedByPasscode =
        _crypto.wrapKey(
      key: dek,
      kek: kekP,
      associatedData: skeleton.associatedDataForPasscode(),
    );
    kekP.dispose();

    final entropy = _crypto.generateRecoveryEntropy();
    final words = Mnemonic.fromEntropy(entropy);
    final kekR = _crypto.deriveKeyFromRecoveryEntropy(entropy);
    final wrappedByRecovery =
        _crypto.wrapKey(
      key: dek,
      kek: kekR,
      associatedData: skeleton.associatedDataForRecovery(),
    );
    // ── ISSUE 17 — KEK-R, kept so backups can carry a recovery wrapper ────
    //
    // Sealed under the DEK, not stored in the clear, and it is the *derived
    // key* rather than the entropy — so it can open backups of this vault and
    // can never be turned back into the twelve words. The long version is on
    // `Keyring.recoveryKekForBackups`.
    //
    // Done here, at creation, because this is the one moment the entropy
    // exists. `unlockWithRecoveryPhrase` fills it in for vaults made before
    // this existed, which is the only other moment it legitimately does.
    final sealedRecoveryKek = _crypto.wrapKey(
      key: kekR,
      kek: dek,
      associatedData: skeleton.associatedDataForBackupKek(),
    );
    kekR.dispose();

    await _keyringStore.write(
      skeleton.copyWith(
        wrappedByPasscode: wrappedByPasscode,
        wrappedByRecovery: wrappedByRecovery,
        recoveryKekForBackups: sealedRecoveryKek,
      ),
    );

    await _open(dek);
    return words;
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Unlocking
  // ───────────────────────────────────────────────────────────────────────────

  /// Unlock with the passcode.
  ///
  /// Throws [WrongSecret] if it is wrong. There is no stored hash to compare
  /// against — §4 is explicit that a password verifier would give an attacker
  /// something cheap to attack. The only test of a guess is the full Argon2id
  /// plus an attempted unwrap, which is exactly as expensive as intended.
  Future<void> unlockWithPasscode(String passcode) async {
    final keyring = await _keyringStore.read();
    final kek = await _crypto.deriveKeyFromPasscodeAsync(
      passcode: passcode,
      salt: keyring.salt,
      // From the keyring, never from our current defaults. Raising the defaults
      // in a future release must not lock existing users out.
      memLimit: keyring.memLimit,
      opsLimit: keyring.opsLimit,
    );
    try {
      final dek = _crypto.unwrapKey(
        wrapped: keyring.wrappedByPasscode,
        kek: kek,
        associatedData: keyring.associatedDataForPasscode(),
      );
      await _open(dek);
    } catch (_) {
      throw const WrongSecret('That passcode does not open this vault.');
    } finally {
      kek.dispose();
    }
  }

  /// Unlock with the twelve words. The other half of ADR-003.
  Future<void> unlockWithRecoveryPhrase(List<String> words) async {
    final keyring = await _keyringStore.read();
    final wrapped = keyring.wrappedByRecovery;
    if (wrapped == null) {
      throw const WrongSecret('This vault has no recovery phrase.');
    }

    // Decode first: a mistyped word is a different failure from a valid phrase
    // for a different vault, and the messages should not be interchangeable.
    final Uint8List entropy;
    try {
      entropy = Mnemonic.toEntropy(words);
    } on MnemonicException catch (e) {
      throw WrongSecret(e.message);
    }

    final kek = _crypto.deriveKeyFromRecoveryEntropy(entropy);
    try {
      final dek = _crypto.unwrapKey(
        wrapped: wrapped,
        kek: kek,
        associatedData: keyring.associatedDataForRecovery(),
      );

      // ── ISSUE 17 — fill in KEK-R for a vault made before it was kept ─────
      //
      // A vault created before this existed has no sealed KEK-R, so its
      // backups cannot carry a recovery wrapper — which would mean the one
      // person who most needs this feature, somebody who has been using the
      // app for months, never gets it.
      //
      // Unlocking with the phrase is the only other moment the app holds the
      // entropy legitimately, so it is written down here. Once, and never
      // overwritten: if it is already there it is already correct.
      if (keyring.recoveryKekForBackups == null) {
        await _keyringStore.write(keyring.copyWith(
          recoveryKekForBackups: _crypto.wrapKey(
            key: kek,
            kek: dek,
            associatedData: keyring.associatedDataForBackupKek(),
          ),
        ));
      }

      await _open(dek);
    } catch (_) {
      throw const WrongSecret(
        'Those words do not open this vault. They may belong to a different one.',
      );
    } finally {
      kek.dispose();
    }
  }

  /// KEK-R, for writing a backup the twelve words can open. **ISSUE 17.**
  ///
  /// Null when the vault has no recovery phrase at all, and null for a vault
  /// created before the sealed copy was kept — in that second case it appears
  /// the first time the user unlocks with their phrase. The backup writer then
  /// simply writes a file with no recovery wrapper, and the restore screen does
  /// not offer the words for it. Offering a way in that a file does not have
  /// would be the cruellest possible place for the invisible-machinery fault.
  ///
  /// The caller owns what comes back and must dispose it.
  Future<SecureKey?> recoveryKekForBackups() async {
    final dek = _dek;
    if (dek == null) return null;
    final keyring = await _keyringStore.read();
    final sealed = keyring.recoveryKekForBackups;
    if (sealed == null) return null;
    try {
      return _crypto.unwrapKey(
        wrapped: sealed,
        kek: dek,
        associatedData: keyring.associatedDataForBackupKek(),
      );
    } catch (_) {
      // A keyring somebody edited by hand. A backup without a recovery wrapper
      // is a working backup; failing the whole thing over this would not be.
      return null;
    }
  }

  // == THE SILENT BACKUP KEY, KEPT SO A FINGERPRINT CAN USE IT =============
  //
  // > *"i have a most concerning problem! automatic backup feature doesn't
  // > works dude! how can you do that? why?"*
  //
  // 3 September 2026, and he was right. His tablet said **"Last backup
  // 29/08/2026"** with the switch **on**, five days and thirty-two entries
  // later.
  //
  // -- WHY IT STOPPED, AND WHY NO TEST COULD SEE IT ------------------------
  //
  // The backup file is sealed with a key derived from the **passcode**, so the
  // person can open it later with the thing they already know. That key is
  // derived in `LockScreen._unlock`, the only place a passcode is ever in
  // scope.
  //
  // `_tryBiometrics` is a different method. It opens the vault through the
  // Android keystore and **never sees a passcode** - so it derived nothing,
  // held nothing, and never asked for a backup. And `_offerBiometrics` runs
  // from `initState`, so on a phone with a fingerprint registered that is the
  // *normal* way in. Every launch. The passcode path he had not used since 29
  // August was the only one that ever backed anything up.
  //
  // Nothing threw and nothing was logged, and the settings screen went on
  // saying the feature was on - because it was on. It simply never became due.
  //
  // -- THE FIX, AND WHY IT IS A SEPARATE FILE ------------------------------
  //
  // The key cannot be re-derived without the passcode, so it has to be kept.
  // It is kept the way `recoveryKekForBackups` is kept: **wrapped under the
  // DEK**, which is itself protected by the passcode and by the keystore. Any
  // unlock that opens the vault can recover it; nothing readable exists on
  // disk without one.
  //
  // In its own file rather than in the keyring, deliberately. The keyring is
  // the one artefact that must still parse in 2035, and a vault is not worth
  // risking for a convenience. This file is optional: absent, the app behaves
  // exactly as it did; corrupt, it is ignored and the next passcode unlock
  // rewrites it.
  //
  // The salt and the Argon2 limits sit beside it in the clear. They are not
  // secret - they are written into the header of every backup file, where
  // anyone holding the file can read them - and they are needed to reproduce
  // the same key from the passcode.
  File get _silentBackupKeyFile => File('${root.path}/silent-backup.key');

  /// Its own domain string, so this envelope can never be mistaken for the
  /// passcode, recovery or backup-KEK ones. Same discipline as `Keyring`'s.
  static final Uint8List _silentBackupAd =
      Uint8List.fromList(utf8.encode('lamplight:silent-backup-key:v1'));

  /// Keeps [key] so a later fingerprint unlock can still write a backup.
  ///
  /// Called from the passcode path only, because that is the only place the
  /// key can be derived. Never throws: failing to cache a key must not fail an
  /// unlock, and the cost of losing it is one skipped backup.
  Future<void> sealSilentBackupKey(BackupKey key) async {
    final dek = _dek;
    if (dek == null) return;
    try {
      final wrapped = _crypto.wrapKey(
        key: key.kek,
        kek: dek,
        associatedData: _silentBackupAd,
      );
      await _silentBackupKeyFile.writeAsString(
        jsonEncode({
          'nonce': base64.encode(wrapped.nonce),
          'key': base64.encode(wrapped.cipherText),
          'salt': base64.encode(key.salt),
          'mem': key.memLimit,
          'ops': key.opsLimit,
        }),
        flush: true,
      );
    } catch (_) {
      // Nothing to do and nothing to say. The next passcode unlock tries again.
    }
  }

  /// The kept silent-backup key, or null if there is none this vault can open.
  ///
  /// The caller owns what comes back and must dispose it.
  Future<BackupKey?> silentBackupKey() async {
    final dek = _dek;
    if (dek == null) return null;
    try {
      final file = _silentBackupKeyFile;
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return BackupKey(
        kek: _crypto.unwrapKey(
          wrapped: WrappedKey(
            nonce: base64.decode(json['nonce']! as String),
            cipherText: base64.decode(json['key']! as String),
          ),
          kek: dek,
          associatedData: _silentBackupAd,
        ),
        salt: base64.decode(json['salt']! as String),
        memLimit: json['mem']! as int,
        opsLimit: json['ops']! as int,
      );
    } catch (_) {
      // Written under an older passcode, edited by hand, or truncated by a
      // phone that died mid-write. A missing key is a skipped backup, not a
      // failure anybody needs to see; the next passcode unlock replaces it.
      return null;
    }
  }

  /// Forgets the kept key, so a feature somebody switched off leaves nothing
  /// of itself behind.
  Future<void> forgetSilentBackupKey() async {
    try {
      final file = _silentBackupKeyFile;
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Change the passcode. Instant, because only 32 bytes are rewrapped.
  ///
  /// §1's whole justification for key wrapping. Deriving the key straight from
  /// the passcode would mean re-encrypting every byte the user owns — a long
  /// operation that can be interrupted and corrupt everything.
  Future<void> changePasscode({
    required String currentPasscode,
    required String newPasscode,
  }) async {
    final keyring = await _keyringStore.read();
    final oldKek = await _crypto.deriveKeyFromPasscodeAsync(
      passcode: currentPasscode,
      salt: keyring.salt,
      memLimit: keyring.memLimit,
      opsLimit: keyring.opsLimit,
    );
    late final SecureKey dek;
    try {
      dek = _crypto.unwrapKey(
        wrapped: keyring.wrappedByPasscode,
        kek: oldKek,
        associatedData: keyring.associatedDataForPasscode(),
      );
    } catch (_) {
      throw const WrongSecret('That passcode does not open this vault.');
    } finally {
      oldKek.dispose();
    }

    // A fresh salt as well as a fresh key, so nothing about the old passcode
    // survives the change.
    //
    // This is safe to do only because the recovery wrapper authenticates its
    // own data and not this salt. With a single shared header — which is how
    // this was first written — changing the salt here would have silently
    // broken the user's twelve words, and they would not have found out until
    // the day they needed them.
    final newSalt = _crypto.generateSalt();
    final rewrapped = keyring.copyWith(salt: newSalt);

    final newKek = await _crypto.deriveKeyFromPasscodeAsync(
      passcode: newPasscode,
      salt: newSalt,
      memLimit: rewrapped.memLimit,
      opsLimit: rewrapped.opsLimit,
    );
    final wrappedByPasscode = _crypto.wrapKey(
      key: dek,
      kek: newKek,
      associatedData: rewrapped.associatedDataForPasscode(),
    );
    newKek.dispose();

    // The recovery wrapper is carried across untouched. It seals the same DEK,
    // under a KEK derived from the phrase, authenticating data that a passcode
    // change does not affect. We could not re-seal it even if we wanted to —
    // that would need the phrase, which we do not have and must never store.
    await _keyringStore.write(
      rewrapped.copyWith(
        wrappedByPasscode: wrappedByPasscode,
        wrappedByRecovery: keyring.wrappedByRecovery,
      ),
    );
    dek.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Locking
  // ───────────────────────────────────────────────────────────────────────────

  /// Seals the vault and wipes the keys.
  Future<void> lock() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    aboutToLock.value = false;

    final db = _db;
    _db = null;
    _attachments = null;
    // Close before disposing the key, so no in-flight query outlives it.
    await db?.close();

    _dek?.dispose();
    _dek = null;

    // The silent-backup key goes with everything else. A locked vault must not
    // leave a key in memory that would let anything encrypt on the user's
    // behalf while they are not there.
    _sessionBackupKey?.dispose();
    _sessionBackupKey = null;
    _sessionBackupSalt = null;

    if (_state != VaultState.uninitialised) {
      _state = VaultState.locked;
    }
    notifyListeners();
  }


  /// The app went to the background. Lock immediately — unless we sent it there.
  ///
  /// ── THE PROBLEM THIS SOLVES ────────────────────────────────────────────
  ///
  /// Locking on background is right, and it broke every capture path in the
  /// app. Tapping the camera launches the camera *app*, which backgrounds us,
  /// which locked the vault and destroyed the keys — so the photo came back to
  /// a locked vault, the import threw, and from the outside it looked like
  /// "I took a photo and the app closed and nothing was saved". The same for
  /// the gallery, the file picker, and choosing a backup folder.
  ///
  /// The rule could not tell the difference between *the user left* and *we
  /// sent them somewhere and are expecting them back*.
  ///
  /// ── WHAT THIS COSTS, STATED PLAINLY ────────────────────────────────────
  ///
  /// It opens a window in which the app is in the background with keys in
  /// memory. `THREAT-MODEL.md`'s most likely adversary — someone who picks up
  /// the unlocked phone — could in principle use it. So it is bounded on every
  /// side that can be bounded:
  ///
  ///   * It only opens when **we** launched a system activity, in code, in
  ///     [expectSystemReturn]. Nothing the user does can open it.
  ///   * It expires by itself after [_excursionLimit], enforced by a real timer
  ///     that locks the vault whether or not we are ever resumed. Walking away
  ///     from the camera app does not leave the vault open indefinitely.
  ///   * It closes the instant the picker returns, in [endSystemReturn].
  ///   * `FLAG_SECURE` still applies, so the recents thumbnail is still blank.
  ///
  /// The alternative was a capture flow that cannot work at all. That is the
  /// trade, and it is the same one every encrypted-notes app with a camera
  /// button has had to make.
  Future<void> onBackgrounded() async {
    if (_awaitingSystemReturn) return;
    // ISSUE 5. A write the user has already committed to gets a moment to
    // land. See `settling` — it is bounded and it is small.
    await _settled;
    await lock();
  }

  // ── ISSUE 5, round nine — "voice doesn't get saved" ───────────────────────
  //
  // > *"I am recording the voice ↓ someone enters my room I close the app ↓
  // > voice doesn't get saved! I want you to save the voice!"*
  //
  // Round eight already made backgrounding stop and save. It did, and the save
  // then failed every single time, for a reason neither piece of code could see
  // on its own.
  //
  // Android reports leaving as three states in a row: `inactive`, `hidden`,
  // `paused`. `app.dart` locks the vault on **hidden**. The recording sheet
  // saved on **paused**. So by the time the recording tried to write itself
  // down, the database was closed and the keys were gone — deterministically,
  // every time, which is why he saw it as simply not working rather than as
  // something intermittent.
  //
  // The recording now settles at `inactive`, before any of that. But settling
  // is asynchronous — a stream to close, a last chunk to encrypt, a duration
  // and a waveform to write — and `hidden` follows within a frame or two. So
  // the lock has to know that a write is in flight and let it finish.
  //
  // ── WHY THIS IS NOT THE TRADE PLAN.md REFUSES ─────────────────────────────
  //
  // `PLAN.md` and the silent-backup code both reject *delaying the lock until
  // the backup completes*, and they are right to: a backup is seconds of work
  // on a whole vault, and waiting for it would keep the DEK alive in memory for
  // exactly as long as the app sat in the background, which is the one thing
  // lock-on-background exists to prevent.
  //
  // This is a different shape and the differences are the whole argument:
  //
  //   * it is **bounded** — [_settleLimit], and the lock happens anyway;
  //   * it is **small** — closing one stream and writing one row;
  //   * it only exists while something is **actually mid-write**, not
  //     speculatively; and
  //   * the alternative is losing something the user made on purpose, which is
  //     the failure the threat model cares least about and the user cares most
  //     about.
  //
  // For comparison, `expectSystemReturn` already holds the vault open for
  // **three minutes** so that taking a photograph works at all. Half a second
  // to finish writing that photograph down is not a new concession.

  /// How long the lock will wait for an in-flight write. A ceiling, not a
  /// promise: whatever has not finished by then is abandoned and the vault
  /// locks regardless.
  static const Duration _settleLimit = Duration(seconds: 4);

  int _settling = 0;
  Completer<void>? _settledSignal;

  /// Completes when nothing is mid-write, or when [_settleLimit] runs out.
  Future<void> get _settled {
    final signal = _settledSignal;
    if (signal == null) return Future<void>.value();
    return signal.future.timeout(_settleLimit, onTimeout: () {});
  }

  /// Runs [work] with the vault held open against a background lock.
  ///
  /// Use it for finishing something the user has already committed to — never
  /// for starting something new. If the vault is already locked this still runs
  /// [work]; it is not a way to get keys, and [work] will fail on its own terms.
  Future<T> whileSettling<T>(Future<T> Function() work) async {
    _settling++;
    _settledSignal ??= Completer<void>();
    try {
      return await work();
    } finally {
      _settling--;
      if (_settling <= 0) {
        _settling = 0;
        final signal = _settledSignal;
        _settledSignal = null;
        if (signal != null && !signal.isCompleted) signal.complete();
      }
    }
  }

  bool _awaitingSystemReturn = false;
  Timer? _excursionTimer;

  /// Long enough to take a photograph or find a file; short enough that a phone
  /// left on a table does not stay unlocked.
  static const Duration _excursionLimit = Duration(minutes: 3);

  bool get awaitingSystemReturn => _awaitingSystemReturn;

  /// About to launch the camera, a picker, or the folder chooser.
  void expectSystemReturn() {
    if (!isUnlocked) return;
    _awaitingSystemReturn = true;
    _excursionTimer?.cancel();
    // Belt and braces: if we are never resumed — the user wandered off from the
    // camera app, the picker was killed — this fires anyway and locks.
    _excursionTimer = Timer(_excursionLimit, () {
      _awaitingSystemReturn = false;
      lock();
    });
  }

  /// The picker came back, or the app resumed. Normal locking applies again.
  void endSystemReturn() {
    _awaitingSystemReturn = false;
    _excursionTimer?.cancel();
    _excursionTimer = null;
    touch();
  }

  /// The user did something. Restart the idle countdown.
  ///
  /// **`Duration.zero` means never, and this is where that has to be honoured.**
  /// Left to `Timer(Duration.zero, lock)`, choosing "Never" in settings would
  /// schedule a lock for the very next tick — so the vault would seal itself on
  /// the first keystroke after unlocking, over and over, which is the exact
  /// opposite of what the user asked for. The setting was already written and
  /// already documented as meaning never; the timer just did not know.
  ///
  /// Found by a widget test failing with a pending timer, which is a strange
  /// way to be told about it and a much better one than a bug report from
  /// someone who had picked the setting that suited them and found the app
  /// unusable.
  // ── ONBOARDING HOLDS THE IDLE CLOCK. Round nineteen. ──────────────────
  //
  // > *"Open it with your fingerprint? Error message is - That did not work!
  // > when i pressed use my fingerprint! If after that i go in settings and
  // > then set up manually fingerprint that works!"*
  //
  // **The fingerprint was never the broken part**, which is why setting it up
  // from Settings a minute later worked perfectly. `create()` ends in
  // `_open()`, `_open()` ends in `touch()`, and `touch()` arms a five-minute
  // timer that only a *pointer down* resets. The passcode step is where the
  // vault is made — and everything after it is reading.
  //
  // So the clock starts, and then onboarding asks the user to **write down
  // twelve words by hand**. Doing that carefully is the single most important
  // thing this app ever asks of anybody, it takes most people longer than five
  // minutes, and it generates no taps at all. The vault locks while they are
  // doing exactly what they were told to do. The next thing they touch is "Use
  // my fingerprint", which reaches `enableBiometricUnlock`, finds no DEK and
  // throws `StateError` — and the onboarding screen has no branch for that, so
  // it prints its generic sentence. **The app punished him for following its
  // own instructions, and then blamed the fingerprint reader.**
  //
  // ── WHY SUSPENDING IT IS THE RIGHT TRADE, AND NOT A HOLE ───────────────
  //
  // `UX-FLOWS.md` flow 7 calls lock-on-background non-negotiable and it is
  // untouched: [onBackgrounded] still locks, immediately, and that is the
  // defence that matters for THREAT-MODEL.md's most likely adversary — the
  // person who picks up the phone. What is suspended here is only the *idle*
  // timer, only while the setup screen is in front, and only between these
  // two calls.
  //
  // What that leaves exposed is one screen with the recovery phrase on it, in
  // a vault that **contains nothing yet**. Weighed against a first run that
  // breaks for anybody thorough enough to write the words down properly, it is
  // not close. The vault is empty, the user is demonstrably present — they
  // typed a passcode a moment ago — and the phrase is on screen precisely
  // because they are meant to be copying it.
  //
  // [endSetup] is called from `dispose` as well as on the way out, so there is
  // no path that leaves the clock held.
  void beginSetup() {
    _inSetup = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    if (aboutToLock.value) aboutToLock.value = false;
  }

  /// Gives the clock back and starts it running again.
  void endSetup() {
    if (!_inSetup) return;
    _inSetup = false;
    touch();
  }

  void touch() {
    if (!isUnlocked) return;
    _idleTimer?.cancel();
    _idleTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    if (aboutToLock.value) aboutToLock.value = false;
    if (_idleTimeout == Duration.zero) return;
    // Onboarding holds the clock. See [beginSetup].
    if (_inSetup) return;
    _idleTimer = Timer(_idleTimeout, lock);

    // ── ISSUE 21 — "the app auto closes while I am watching at it" ──────────
    //
    // *"A good feature but say me how to tame it!"*
    //
    // He is describing the idle lock working exactly as designed, and the
    // design was still wrong, because from the outside there is no difference
    // between an app that locked itself and an app that crashed. Both are: the
    // thing you were reading is gone, with no warning and no explanation, and
    // the second reading is the one anybody reaches for first — which is why
    // he filed it next to "app feels so slow" rather than under settings.
    //
    // A lock that announces itself a few seconds early is a completely
    // different experience of the same behaviour. It stops being something the
    // app did *to* you and becomes something you can decline, and it teaches
    // the setting exists by naming it at the only moment anybody cares.
    //
    // It gives up nothing. The countdown does not extend the timeout — the
    // lock still happens at the same instant it always did — and dismissing
    // the notice is `touch()`, which is the same thing tapping the screen has
    // always done.
    final warnAt = _idleTimeout - warningWindow;
    if (warnAt > Duration.zero) {
      _warningTimer = Timer(warnAt, () {
        if (isUnlocked) aboutToLock.value = true;
      });
    }
  }

  /// How long before the idle lock the warning appears. **ISSUE 21.**
  ///
  /// A third of the timeout, capped at twenty seconds. The cap is what matters
  /// on the long settings — nobody needs a five-minute warning — and the third
  /// is what keeps it sane on the short ones, where twenty seconds of warning
  /// on a fifteen-second timeout would mean the notice was up before the
  /// countdown started.
  Duration get warningWindow {
    if (_idleTimeout == Duration.zero) return Duration.zero;
    final third = _idleTimeout ~/ 3;
    return third > const Duration(seconds: 20)
        ? const Duration(seconds: 20)
        : third;
  }

  /// True while the idle lock is a few seconds away. **ISSUE 21.**
  ///
  /// A `ValueNotifier` rather than a callback because more than one thing may
  /// want to know, and because the widget that shows the notice must be able to
  /// find out that it is no longer true without being told twice.
  final ValueNotifier<bool> aboutToLock = ValueNotifier<bool>(false);

  /// Auto-lock delay. `Duration.zero` means never.
  ///
  /// `08-design/ACCESSIBILITY.md` requires "never" to be available: a short
  /// timeout is a genuine barrier for someone who types slowly, and an app that
  /// locks while you are still composing a sentence is one you stop using.
  set idleTimeout(Duration value) {
    _idleTimeout = value;
    if (isUnlocked) touch();
  }

  Duration get idleTimeout => _idleTimeout;

  // ───────────────────────────────────────────────────────────────────────────
  //  The third envelope: the fingerprint
  // ───────────────────────────────────────────────────────────────────────────

  /// Whether this vault has a fingerprint wrapper on this device.
  Future<bool> get hasBiometricWrapper async {
    if (!_keyringStore.existsSync()) return false;
    try {
      return (await _keyringStore.read()).biometric != null;
    } catch (_) {
      return false;
    }
  }

  /// Adds the fingerprint as a third way in. The vault must be unlocked.
  ///
  /// **The passcode remains the real key and the only recovery.** This wrapper
  /// is a convenience on one device: it is destroyed if the phone's biometrics
  /// change, it cannot be moved to another phone, and it is not in a backup. A
  /// user who relies on it and forgets their passcode has lost nothing, because
  /// the twelve words still work — which is the property that makes offering it
  /// safe at all.
  Future<void> enableBiometricUnlock() async {
    final dek = _dek;
    if (dek == null) throw StateError('The vault is locked.');

    final keyring = await _keyringStore.read();

    // A fresh secret per enrolment. Turning the fingerprint off and on again
    // produces a different one, so an old sealed blob is worthless even if
    // somebody kept a copy of the keyring file.
    final secret = _crypto.randomBytes(VaultCrypto.keyBytes);
    final sealed = await Biometrics.enrol(secret);
    if (sealed == null) return; // Cancelled. Nothing changes.

    final kek = SecureKey.fromList(_sodium, secret);
    try {
      final wrapped = _crypto.wrapKey(
        key: dek,
        kek: kek,
        associatedData: keyring.associatedDataForBiometric(),
      );
      await _keyringStore.write(keyring.copyWith(
        biometric: BiometricWrapper(
          sealed: base64.decode(sealed.sealed),
          iv: base64.decode(sealed.iv),
          wrapped: wrapped,
        ),
      ));
    } finally {
      kek.dispose();
    }
    notifyListeners();
  }

  /// Removes it. The keystore key goes too, so nothing is left behind.
  Future<void> disableBiometricUnlock() async {
    await Biometrics.clear();
    if (!_keyringStore.existsSync()) return;
    final keyring = await _keyringStore.read();
    await _keyringStore.write(keyring.withoutBiometric());
    notifyListeners();
  }

  /// Unlock with the fingerprint.
  ///
  /// Returns false if the user cancelled or chose the passcode — not an error,
  /// and the lock screen simply carries on waiting.
  ///
  /// Throws [BiometricInvalidated] if the phone's biometrics changed since
  /// enrolment. That is the design working: the wrapper is dropped, the
  /// passcode still opens everything, and the user is told plainly.
  Future<bool> unlockWithBiometrics() async {
    final keyring = await _keyringStore.read();
    final wrapper = keyring.biometric;
    if (wrapper == null) return false;

    final Uint8List? secret;
    try {
      secret = await Biometrics.unlock(
        sealed: base64.encode(wrapper.sealed),
        iv: base64.encode(wrapper.iv),
      );
    } on BiometricInvalidated {
      // Drop the dead wrapper so the app stops offering something that cannot
      // work, then re-throw so the screen can explain.
      await _keyringStore.write(keyring.withoutBiometric());
      rethrow;
    }
    if (secret == null) return false;

    final kek = SecureKey.fromList(_sodium, secret);
    try {
      final dek = _crypto.unwrapKey(
        wrapped: wrapper.wrapped,
        kek: kek,
        associatedData: keyring.associatedDataForBiometric(),
      );
      await _open(dek);
      return true;
    } catch (_) {
      throw const WrongSecret(
        'That fingerprint did not open this vault. Use your passcode.',
      );
    } finally {
      kek.dispose();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Backup and restore
  // ───────────────────────────────────────────────────────────────────────────

  /// Folds the write-ahead log back into the database file.
  ///
  /// **Run this before every backup.** WAL mode means recent writes live in
  /// `vault.db-wal` rather than in `vault.db`, so copying the database on its
  /// own would silently produce a backup missing everything written since the
  /// last automatic checkpoint. The backup does copy the WAL as well, and this
  /// still runs first — a smaller, simpler thing to get right is worth doing
  /// even when the belt and the braces are both on.
  Future<void> checkpoint() async {
    final db = _db;
    if (db == null) return;
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  /// Puts a restored vault in place of the current one, reversibly.
  ///
  /// THE ORDER HERE IS THE WHOLE POINT
  ///
  /// `UX-FLOWS.md` flow 6: "Never leave a half-restored vault." So nothing is
  /// deleted. The existing vault is *moved aside* into a directory this method
  /// returns, the restored files are moved in, and the caller then proves the
  /// result actually opens before calling [commitSwap]. If it does not,
  /// [rollbackSwap] puts everything back exactly as it was.
  ///
  /// Moves, not copies: a rename inside one filesystem is atomic and instant,
  /// so there is no window where a vault is half in place, and no moment where
  /// two copies of a 1 GB vault have to fit on the phone at once.
  Future<Directory> swapIn(Directory staging) async {
    await lock();

    final aside = Directory(
        '${_root.path}/replaced-${DateTime.now().millisecondsSinceEpoch}');
    await aside.create(recursive: true);

    for (final name in vaultFileNames) {
      final f = File('${_root.path}/$name');
      if (await f.exists()) await f.rename('${aside.path}/$name');
    }
    final attachments = Directory('${_root.path}/attachments');
    if (await attachments.exists()) {
      await attachments.rename('${aside.path}/attachments');
    }

    for (final name in vaultFileNames) {
      final f = File('${staging.path}/$name');
      if (await f.exists()) await f.rename('${_root.path}/$name');
    }
    final staged = Directory('${staging.path}/attachments');
    if (await staged.exists()) {
      await staged.rename('${_root.path}/attachments');
    }

    await initialise();
    return aside;
  }

  /// The restore worked. Let go of what was there before.
  Future<void> commitSwap(Directory aside) async {
    if (await aside.exists()) await aside.delete(recursive: true);
  }

  /// The restore did not work. Put the old vault back, exactly.
  Future<void> rollbackSwap(Directory aside) async {
    await lock();

    for (final name in vaultFileNames) {
      final f = File('${_root.path}/$name');
      if (await f.exists()) await f.delete();
    }
    final attachments = Directory('${_root.path}/attachments');
    if (await attachments.exists()) await attachments.delete(recursive: true);

    for (final name in vaultFileNames) {
      final f = File('${aside.path}/$name');
      if (await f.exists()) await f.rename('${_root.path}/$name');
    }
    final asideAttachments = Directory('${aside.path}/attachments');
    if (await asideAttachments.exists()) {
      await asideAttachments.rename('${_root.path}/attachments');
    }

    if (await aside.exists()) await aside.delete(recursive: true);
    await initialise();
  }

  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _open(SecureKey dek) async {
    final dbKey = _crypto.deriveSubkey(dek, KeyPurpose.database);
    try {
      _db = await openVaultDatabase(
        path: _databasePath,
        key: dbKey.extractBytes(),
      );
    } finally {
      // The subkey has served its purpose the moment the database is open.
      dbKey.dispose();
    }

    _attachments = AttachmentStore(
      directory: Directory('${_root.path}/attachments'),
      sodium: _sodium,
      crypto: _crypto,
    );

    _dek = dek;
    _state = VaultState.unlocked;
    touch();
    notifyListeners();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _dek?.dispose();
    _dek = null;
    super.dispose();
  }
}

/// A wrong passcode or a wrong recovery phrase.
///
/// The message is written for a person to read. `08-design/ACCESSIBILITY.md`:
/// "That passcode doesn't open this file", never "Authentication error:
/// invalid credentials".
class WrongSecret implements Exception {
  const WrongSecret(this.message);

  final String message;

  @override
  String toString() => message;
}
