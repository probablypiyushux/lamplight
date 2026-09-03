import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sodium/sodium_sumo.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_info.dart';
import '../crypto/vault_crypto.dart';
import '../plain_words.dart';
import 'cbor.dart';

/// The `.vault` backup file, exactly as `04-technical/BACKUP-FILE-FORMAT.md`
/// specifies it.
///
/// ```
/// MAGIC        8   "VAULT\x01\x00\x00"
/// HEADER_LEN   4   uint32
/// HEADER           CBOR, cleartext but authenticated
/// WRAPPED_DEK      nonce(24) ‖ ciphertext(32) ‖ tag(16), AAD = HEADER bytes
/// BODY             chunks of len(4) ‖ nonce(24) ‖ ciphertext ‖ tag(16)
/// FOOTER           total_chunks(8) ‖ blake2b256(everything above)
/// ```
///
/// **Every integer in the framing is little-endian**, including the chunk index
/// inside each nonce. One rule with no exceptions, because the point of writing
/// this format down is that a stranger can reimplement it, and every exception
/// is a place they will get it wrong.
///
/// THE THINGS WORTH KNOWING BEFORE CHANGING ANY OF THIS
///
/// **The DEK in this file is not the vault's DEK.** It is generated fresh for
/// each backup, so compromising one backup file compromises that file and
/// nothing else — not the vault, not last month's backup.
///
/// **The header is cleartext and that is unavoidable.** You need the Argon2id
/// parameters before you can derive the key to read anything. Every
/// password-based format has this property; age, LUKS and Signal's backups all
/// do it the same way. It is *authenticated* as the associated data on the
/// wrapped key, so an attacker cannot quietly rewrite `kdf_memory_kib` down to
/// 1 to make brute force cheap — that edit breaks the tag and the file refuses
/// to open.
///
/// **The chunk index is bound into the nonce and verified on read.** Without
/// that check, binding it would be decoration: an attacker could reorder or
/// drop chunks and each one would still decrypt perfectly well on its own. The
/// count is also in the authenticated footer, which catches truncation.
///
/// **There is no password verifier anywhere in this file.** The only way to
/// test a guess is to run the full Argon2id and attempt the unwrap. That is
/// deliberate — a verifier would hand an offline attacker a cheap oracle.
class VaultFile {
  VaultFile({required SodiumSumo sodium, required VaultCrypto crypto})
      : _sodium = sodium,
        _crypto = crypto;

  final SodiumSumo _sodium;
  final VaultCrypto _crypto;

  static final Uint8List magic =
      Uint8List.fromList([0x56, 0x41, 0x55, 0x4C, 0x54, 0x01, 0x00, 0x00]);

  /// Bumped only on a breaking change. Every version's reader stays in this
  /// file forever — reading a v1 file in 2035 is a promise the project made in
  /// writing, and a deleted reader is how that promise gets broken by accident.
  /// **2 as of 24 August 2026.** ISSUE 17 — the recovery phrase opens the
  /// file, through a second wrapper of the same file key.
  ///
  /// v1 files still open, with the passcode, forever. That is not politeness:
  /// `BACKUP-FILE-FORMAT.md` states that every version's reader stays in the
  /// codebase permanently, because somebody restoring in 2035 from a disk they
  /// found in a drawer is the entire point of writing the format down.
  static const int formatVersion = 2;

  /// Plaintext bytes per chunk, before encryption and after compression.
  static const int chunkSize = 65536;

  /// 8 bytes of chunk count, 32 of hash.
  static const int footerLength = 40;

  /// 16 random bytes, then the little-endian chunk index.
  static const int _noncePrefixLength = 16;

  /// The members the inner stream may contain, and the only names a restore
  /// will write.
  ///
  /// **This is a security check, not tidiness.** The inner stream is
  /// attacker-controlled the moment a user opens a file someone sent them, and
  /// a member innocently named `../../../shared_prefs/something` would have a
  /// restore writing outside its staging directory. Names are matched against
  /// this, not sanitised — sanitising is a game you can lose, and a fixed list
  /// is a game with no moves in it.
  /// The attachment segment must **start with a letter or a digit**, which is
  /// the clause that matters. An earlier version allowed any run of
  /// `[A-Za-z0-9._-]`, and a test caught what that lets through: `attachments/..`
  /// is a legal member name under it, and `..` is a directory, not a file.
  /// Requiring the first character to be alphanumeric rules out `.`, `..` and
  /// dotfiles in one clause, and costs nothing — every attachment this app has
  /// ever written is a UUID.
  static final RegExp _allowedMember = RegExp(
      r'^(manifest\.cbor|keyring\.json|vault\.db|attachments/[A-Za-z0-9][A-Za-z0-9._-]{0,63})$');

  /// Whether a member name in the inner stream will be written on restore.
  ///
  /// Public so it can be tested directly. Building a hostile backup file to
  /// prove this rule holds would take more code than the rule, and the code
  /// proving it would itself be the only thing that had ever written such a
  /// file — so the check is exercised where it lives instead.
  static bool isAllowedMemberName(String name) => _allowedMember.hasMatch(name);

  static const String manifestMember = 'manifest.cbor';
  static const String keyringMember = 'keyring.json';
  static const String databaseMember = 'vault.db';

  // ═══════════════════════════════════════════════════════════════════════════
  //  Writing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Derives the key that seals one backup file, from a passcode.
  ///
  /// Separated from [write] so a silent backup can derive it **once, at unlock,
  /// while the passcode is briefly in hand**, and reuse it for the rest of the
  /// session. Argon2id at 256 MiB is a quarter of a second and 256 MiB of
  /// allocation; running it every time the app goes to the background would be
  /// felt.
  ///
  /// The alternative — keeping the passcode itself in memory — is worse. A Dart
  /// `String` cannot be wiped and may be copied by the garbage collector; a
  /// libsodium `SecureKey` is locked, guarded and wiped on dispose. And a key
  /// is narrower than a passcode: it opens backup files and nothing else, while
  /// the passcode opens the vault as well.
  Future<BackupKey> deriveBackupKey(String passcode, {Uint8List? salt}) async {
    final s = salt ?? _crypto.generateSalt();
    return BackupKey(
      kek: await _crypto.deriveKeyFromPasscodeAsync(passcode: passcode, salt: s),
      salt: s,
      memLimit: VaultCrypto.defaultMemLimit,
      opsLimit: VaultCrypto.defaultOpsLimit,
    );
  }

  /// Writes a backup of [vaultRoot] to [destination].
  ///
  /// Does **not** verify it. `BACKUP-FILE-FORMAT.md` step 6 requires reading the
  /// file back and decrypting it end to end before anyone is told it worked,
  /// and that is a separate call — see [verify] — so that it is impossible to
  /// report success without having done it.
  Future<BackupSummary> write({
    required File destination,
    required Directory vaultRoot,
    required Map<String, Object?> counts,
    String? passcode,
    BackupKey? key,
    /// KEK-R, so the twelve words open this file too. **ISSUE 17.**
    ///
    /// The derived key rather than the entropy, because the entropy is shown
    /// once at creation and deliberately never stored — see
    /// `Keyring.recoveryKekForBackups` for how the app has this at all, and for
    /// why keeping a one-way hash of the phrase is not the same as keeping the
    /// phrase.
    ///
    /// Null writes a file with no recovery wrapper, which is a v1 file in all
    /// but the version number — correct for a vault that has no recovery
    /// phrase, and for one created before this was kept.
    SecureKey? recoveryKek,
    void Function(double fraction)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if ((passcode == null) == (key == null)) {
      throw ArgumentError('pass exactly one of passcode or key');
    }
    final members = await _collectMembers(vaultRoot);
    if (members.isEmpty) {
      throw const BackupError('There is nothing in this vault to back up yet.',
            problem: BackupProblem.nothingToBackUp);
    }

    // ── Pass one: hash every member ──────────────────────────────────────────
    // The manifest carries a hash per member and the manifest is written first,
    // so the hashes have to exist before a byte of body is produced. It costs a
    // read of the vault. It buys the difference between "this file is intact"
    // and "this file's members are the ones we wrote", which is what lets a
    // restore refuse *before* it starts replacing anything.
    final entries = <Object?>[];
    var totalBytes = 0;
    for (final m in members) {
      final hash = await _hashFile(m.file);
      entries.add(<String, Object?>{
        'name': m.name,
        'size': m.size,
        'hash': hash,
      });
      totalBytes += m.size;
    }

    final manifest = Cbor.encode(<String, Object?>{
      ...counts,
      'members': entries,
    });

    // ── The header ───────────────────────────────────────────────────────────
    // A fresh key per file when a passcode was given; a reused session key for
    // a silent backup, which then reuses its salt too — the salt has to be the
    // one the key was derived from or nothing will ever open the file.
    final backupKey = key ?? await deriveBackupKey(passcode!);
    final salt = backupKey.salt;
    final header = Cbor.encode(<String, Object?>{
      'format_version': formatVersion,
      'kdf': 'argon2id',
      'kdf_salt': salt,
      'kdf_memory_kib': backupKey.memLimit ~/ 1024,
      'kdf_iterations': backupKey.opsLimit,
      'kdf_parallelism': 1,
      'cipher': 'xchacha20poly1305',
      'chunk_size': chunkSize,
      // gzip, not zstd. See the note in BACKUP-FILE-FORMAT.md: zstd would mean
      // a native dependency, and gzip is in the Dart SDK at no cost in
      // packages. A reader must accept both this and 'none'.
      'compression': 'gzip',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'app_version': kAppVersion,
      'backup_id': _uuid(),
      // ── ISSUE 17 — whether the twelve words open this file ──────────────
      //
      // In the header, so it is authenticated as AAD on both wrappers and so a
      // reader knows where the body starts before it has decrypted anything.
      // An attacker who flipped this to `false` would move the body by 72 bytes
      // and break the tag on the wrapper they were trying to use, which is the
      // point of it being in here rather than inferred from the file's length.
      'recovery': recoveryKek != null,
    });

    // ── The key for this file, and this file only ────────────────────────────
    // The DEK is always fresh, even when the KEK is a reused session key.
    // Compromising one backup file must not compromise the next one, and that
    // property comes from this line rather than from the passcode derivation.
    final fileKey = _sodium.crypto.aeadXChaCha20Poly1305IETF.keygen();
    final wrapped = _crypto.wrapKey(
        key: fileKey, kek: backupKey.kek, associatedData: header);
    // Only dispose a key we derived ourselves. A caller's session key belongs
    // to the caller and is disposed when the vault locks.
    if (key == null) backupKey.dispose();

    // ── ISSUE 17 — the same file key, wrapped a second time ────────────────
    //
    // *"Backup phrase is only able to open the app! I want that phrase to open
    // the backup (.vault) file."*
    //
    // He found a real hole and it is worse than an inconvenience: the twelve
    // words were sold as the way back in when the passcode is gone, and they
    // only opened the app *on that phone*. Lose the phone and the words were
    // useless — the only copy of his life was a file openable by a passcode he
    // had, by definition, forgotten. The recovery phrase recovered the one
    // thing that did not need recovering.
    //
    // The **same** DEK, wrapped again under a KEK derived from the phrase. Not
    // a second copy of the body, not a second file: one file key, two ways in,
    // exactly as the on-device keyring has worked since ADR-003.
    //
    // No Argon2id on this one, matching `deriveKeyFromRecoveryEntropy` and for
    // its reason: the input is already 128 bits from the OS generator, and
    // stretching exists to make *guessable* inputs expensive.
    final wrappedByRecovery = recoveryKek == null
        ? null
        : _crypto.wrapKey(
            key: fileKey,
            kek: recoveryKek,
            // The same header both wrappers authenticate, so the KDF
            // parameters cannot be rewritten under either one.
            associatedData: header,
          );

    final sink = destination.openWrite();
    final footerHash = _sodium.crypto.genericHash.createConsumer(outLen: 32);
    var chunkCount = 0;

    // Everything written above the footer goes through here, so the footer hash
    // cannot fall out of step with the file by anyone forgetting to add to it.
    void put(List<int> bytes) {
      final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      sink.add(b);
      footerHash.add(b);
    }

    try {
      put(magic);
      put(_u32(header.length));
      put(header);
      put(wrapped.nonce);
      put(wrapped.cipherText);
      // ISSUE 17. Immediately after, at the same fixed size, so the body's
      // offset is a fixed arithmetic step from the header rather than a search.
      if (wrappedByRecovery != null) {
        put(wrappedByRecovery.nonce);
        put(wrappedByRecovery.cipherText);
      }

      // ── The body ───────────────────────────────────────────────────────────
      final noncePrefix = _crypto.randomBytes(_noncePrefixLength);
      final aead = _sodium.crypto.aeadXChaCha20Poly1305IETF;
      var written = 0;

      final plain = gzip.encoder.bind(_innerStream(manifest, members));
      await for (final block in _rechunk(plain, chunkSize)) {
        // Checked between chunks, so cancelling never interrupts a write
        // part-way through one. The half-written file is deleted by the caller;
        // there is no state anywhere else to unwind.
        if (isCancelled?.call() ?? false) throw const BackupCancelled();

        final nonce = _nonceFor(noncePrefix, chunkCount);
        final sealed = aead.encrypt(
          message: block,
          nonce: nonce,
          key: fileKey,
          additionalData: header,
        );
        put(_u32(sealed.length));
        put(nonce);
        put(sealed);
        chunkCount++;

        // Progress is reported against the *uncompressed* total, which is the
        // only number known in advance. It therefore runs slightly ahead of
        // reality on a compressible vault, and finishing early is the direction
        // to be wrong in.
        written += block.length;
        onProgress?.call(
            totalBytes == 0 ? 1 : (written / totalBytes).clamp(0.0, 1.0));
      }

      // ── The footer ─────────────────────────────────────────────────────────
      // The count first, hashed, and then the hash of everything before it.
      put(_u64(chunkCount));
      final digest = await footerHash.close();
      sink.add(digest);

      await sink.flush();
    } finally {
      fileKey.dispose();
      await sink.close();
    }

    onProgress?.call(1);
    return BackupSummary(
      file: destination,
      byteSize: await destination.length(),
      memberCount: members.length,
      chunkCount: chunkCount,
    );
  }

  /// The inner stream: the manifest, then each member, length-prefixed.
  ///
  /// A tar-like sequence rather than an actual tar, because none of tar's
  /// filesystem semantics — permissions, owners, symlinks, device nodes — are
  /// wanted here, and several of them are things you would have to defend
  /// against on the way back in.
  ///
  /// ```
  /// name_len(2) ‖ name ‖ data_len(8) ‖ data
  /// ```
  Stream<List<int>> _innerStream(
      Uint8List manifest, List<_Member> members) async* {
    yield* _record(manifestMember, Stream.value(manifest), manifest.length);
    for (final m in members) {
      yield* _record(m.name, m.file.openRead(), m.size);
    }
  }

  Stream<List<int>> _record(
      String name, Stream<List<int>> data, int size) async* {
    final nameBytes = utf8.encode(name);
    yield _u16(nameBytes.length);
    yield nameBytes;
    yield _u64(size);
    var seen = 0;
    await for (final block in data) {
      seen += block.length;
      yield block;
    }
    // A member that changed size while we were reading it would corrupt every
    // record after it, because the reader trusts the length prefix. Better to
    // fail here, loudly, than to write a file that is wrong from this point on.
    if (seen != size) {
      throw BackupError(
          '$name changed while it was being backed up ($seen bytes, expected $size)',
            problem: BackupProblem.changedWhileBackingUp,
            detail: name);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Reading
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reads the header and checks the file's own integrity, without a passcode.
  ///
  /// This is the "Verifying…" step in flow 6. It answers "is this one of our
  /// files, can this version read it, and has it survived" — all before asking
  /// anyone to type a passcode, because being asked for a passcode and *then*
  /// told the file is damaged is a small cruelty.
  Future<BackupInfo> inspect(File source) async {
    final length = await source.length();
    if (length < magic.length + 4 + footerLength) {
      throw const BackupError(
          'This file is too small to be a Lamplight backup.',
            problem: BackupProblem.tooSmall);
    }

    final head = await _readRange(source, 0, magic.length + 4);
    for (var i = 0; i < magic.length; i++) {
      if (head[i] != magic[i]) {
        throw const BackupError('This is not a Lamplight backup file.',
            problem: BackupProblem.notALamplightFile);
      }
    }
    final headerLength = _readU32(head, magic.length);
    if (headerLength <= 0 || headerLength > 1 << 20) {
      throw const BackupError('This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
    }

    final headerStart = magic.length + 4;
    final headerBytes = await _readRange(
        source, headerStart, headerStart + headerLength);

    final Map<String, Object?> header;
    try {
      header = Cbor.decode(headerBytes)! as Map<String, Object?>;
    } catch (_) {
      throw const BackupError('This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
    }

    final version = header['format_version'];
    if (version is! int) {
      throw const BackupError('This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
    }
    if (version > formatVersion) {
      throw const BackupError(
          'This backup was made with a newer version of Lamplight. Update the '
          'app, then try again.',
            problem: BackupProblem.newerVersion);
    }

    final compression = header['compression'];
    if (compression != 'gzip' && compression != 'none') {
      throw const BackupError(
          'This backup uses a compression this version does not know how to '
          'read.',
            problem: BackupProblem.unknownCompression);
    }

    // ── The footer, and the whole-file hash ──────────────────────────────────
    // Checked before a single byte is decrypted, because flow 6 requires a
    // corrupt file to be refused cleanly rather than discovered halfway through
    // replacing the vault.
    final footer = await _readRange(source, length - footerLength, length);
    final claimedChunks = _readU64(footer, 0);
    final claimedHash = Uint8List.sublistView(footer, 8);

    final actual = await _sodium.crypto.genericHash.stream(
      messages: source
          .openRead(0, length - footerLength + 8)
          .map((b) => b is Uint8List ? b : Uint8List.fromList(b)),
      outLen: 32,
    );
    if (!_constantTimeEquals(actual, claimedHash)) {
      throw const BackupError(
          'This file is damaged and cannot be opened. If you have an older '
          'backup, try that one.',
            problem: BackupProblem.damagedTryOlder);
    }

    // ISSUE 17. One wrapper in v1, two when the header says the recovery
    // wrapper is there. Read from the header rather than inferred from the
    // file's length, so a truncated file fails its footer hash rather than
    // being silently reinterpreted.
    final hasRecoveryWrapper = header['recovery'] == true;
    final wrapperBytes = _sodium.crypto.aeadXChaCha20Poly1305IETF.nonceBytes +
        VaultCrypto.keyBytes +
        _sodium.crypto.aeadXChaCha20Poly1305IETF.aBytes;

    return BackupInfo(
      header: header,
      headerBytes: headerBytes,
      hasRecoveryWrapper: hasRecoveryWrapper,
      bodyStart: headerStart +
          headerLength +
          wrapperBytes * (hasRecoveryWrapper ? 2 : 1),
      bodyEnd: length - footerLength,
      chunkCount: claimedChunks,
      createdAt: DateTime.tryParse(header['created_at'] as String? ?? ''),
      appVersion: header['app_version'] as String?,
    );
  }

  /// Decrypts [source] into [staging] and returns what it found.
  ///
  /// Writes nothing outside [staging] and touches nothing live. The caller
  /// decides whether to swap it in — which is the only way to guarantee flow
  /// 6's "never leave a half-restored vault".
  Future<RestoreSummary> extract({
    required File source,
    required Directory staging,
    String? passcode,
    BackupKey? key,
    /// KEK-R, derived from the twelve words the user just typed.
    /// **ISSUE 17** — the other way in.
    SecureKey? recoveryKek,
    void Function(double fraction)? onProgress,
  }) async {
    final ways = [passcode != null, key != null, recoveryKek != null]
        .where((given) => given)
        .length;
    if (ways != 1) {
      throw ArgumentError(
          'pass exactly one of passcode, key or recoveryKek');
    }
    final info = await inspect(source);

    // ── The key ──────────────────────────────────────────────────────────────
    // Using the parameters stored in the file, never our current defaults. A
    // backup written by an older version with cheaper Argon2id settings still
    // has to open, or raising the defaults would quietly destroy every backup
    // anyone had already made.
    // ── ISSUE 17 — either secret opens the file ────────────────────────────
    //
    // The recovery wrapper first, when words were given, because it is the
    // cheap one: no Argon2id, just a BLAKE2b of entropy the caller already
    // holds. A passcode restore is unchanged in every respect.
    final SecureKey fileKey;
    final nonceBytes = _sodium.crypto.aeadXChaCha20Poly1305IETF.nonceBytes;
    final wrapperBytes =
        nonceBytes + VaultCrypto.keyBytes + _sodium.crypto.aeadXChaCha20Poly1305IETF.aBytes;
    final firstWrapperStart = magic.length + 4 + info.headerBytes.length;

    if (recoveryKek != null) {
      if (!info.hasRecoveryWrapper) {
        throw const BackupError(
            'This backup was made before recovery phrases could open backup '
            'files. Its passcode is the only way in.',
            problem: BackupProblem.madeBeforeRecoveryPhrases);
      }
      try {
        final bytes = await _readRange(
          source,
          firstWrapperStart + wrapperBytes,
          firstWrapperStart + wrapperBytes * 2,
        );
        fileKey = _crypto.unwrapKey(
          wrapped: WrappedKey(
            nonce: Uint8List.sublistView(bytes, 0, nonceBytes),
            cipherText: Uint8List.sublistView(bytes, nonceBytes),
          ),
          kek: recoveryKek,
          associatedData: info.headerBytes,
        );
      } catch (_) {
        throw const BackupError(
            'Those words do not open this file. They may belong to a '
            'different vault.',
            problem: BackupProblem.wordsDoNotOpenIt);
      }
    } else {
      // ── The passcode path, unchanged ─────────────────────────────────────
      //
      // The KDF parameters come out of the file rather than from our current
      // defaults, so a backup made when the defaults were lower still opens —
      // and the header is authenticated, so nobody can quietly rewrite
      // `kdf_memory_kib` down to 1 and make the derivation cheap.
      final salt = info.header['kdf_salt'];
      if (salt is! Uint8List) {
        throw const BackupError('This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
      }
      // A session key is only usable on a file written under the same salt —
      // which is exactly the case a silent backup verifying its own output is
      // in. Anything else falls back to deriving from the passcode.
      final reuse = key != null && _constantTimeEquals(key.salt, salt);
      final kek = reuse
          ? key.kek
          : await _crypto.deriveKeyFromPasscodeAsync(
              passcode: passcode ?? '',
              salt: salt,
              memLimit: (info.header['kdf_memory_kib'] as int) * 1024,
              opsLimit: info.header['kdf_iterations'] as int,
            );
      try {
        final bytes = await _readRange(
            source, firstWrapperStart, firstWrapperStart + wrapperBytes);
        fileKey = _crypto.unwrapKey(
          wrapped: WrappedKey(
            nonce: Uint8List.sublistView(bytes, 0, nonceBytes),
            cipherText: Uint8List.sublistView(bytes, nonceBytes),
          ),
          kek: kek,
          associatedData: info.headerBytes,
        );
      } catch (_) {
        throw const BackupError("That passcode doesn't open this file.",
            problem: BackupProblem.wrongPasscode);
      } finally {
        // Only dispose a key derived here. A caller's session key stays alive
        // until the vault locks.
        if (!reuse) kek.dispose();
      }
    }

    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    final writer = _MemberWriter(staging);
    try {
      final plain = _decryptBody(
        source: source,
        info: info,
        key: fileKey,
        onProgress: onProgress,
      );
      final inner = info.header['compression'] == 'gzip'
          ? gzip.decoder.bind(plain)
          : plain;
      await writer.consume(inner);
    } finally {
      fileKey.dispose();
    }

    final manifestFile = File('${staging.path}/$manifestMember');
    if (!await manifestFile.exists()) {
      throw const BackupError('This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
    }
    final manifest =
        Cbor.decode(await manifestFile.readAsBytes())! as Map<String, Object?>;

    // ── Every member, checked against the manifest ───────────────────────────
    final declared = (manifest['members'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    for (final m in declared) {
      final name = m['name'] as String;
      final file = File('${staging.path}/$name');
      if (!await file.exists()) {
        throw BackupError('This backup is missing part of itself ($name).',
            problem: BackupProblem.missingPart,
            detail: name);
      }
      if (await file.length() != m['size']) {
        throw BackupError('This backup is damaged ($name is the wrong size).',
            problem: BackupProblem.partWrongSize,
            detail: name);
      }
      final hash = await _hashFile(file);
      if (!_constantTimeEquals(hash, m['hash']! as Uint8List)) {
        throw BackupError('This backup is damaged ($name does not match).',
            problem: BackupProblem.partDoesNotMatch,
            detail: name);
      }
    }

    if (!await File('${staging.path}/$keyringMember').exists() ||
        !await File('${staging.path}/$databaseMember').exists()) {
      throw const BackupError(
          'This backup does not contain a vault. It may have been made by a '
          'different app.',
            problem: BackupProblem.noVaultInside);
    }

    onProgress?.call(1);
    return RestoreSummary(
      staging: staging,
      entryCount: manifest['entry_count'] as int? ?? 0,
      dayCount: manifest['day_count'] as int? ?? 0,
      attachmentCount: manifest['attachment_count'] as int? ?? 0,
      createdAt: info.createdAt,
    );
  }

  /// Confirms a file we just wrote can be read back and decrypted end to end.
  ///
  /// `BACKUP-FILE-FORMAT.md` step 6, and `UX-FLOWS.md` flow 5 step 4: **do not
  /// report success until this passes.** It is the difference between a backup
  /// and the belief that you have one, and that difference only ever shows up
  /// on the day it is too late to find out.
  Future<void> verify({
    required File source,
    required Directory scratch,
    String? passcode,
    BackupKey? key,
  }) async {
    try {
      await extract(
        source: source,
        staging: scratch,
        passcode: passcode,
        key: key,
      );
    } finally {
      if (await scratch.exists()) await scratch.delete(recursive: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  The same two operations, off the UI isolate
  // ═══════════════════════════════════════════════════════════════════════════
  //
  //  PLAN.md §7.1. Everything above this line runs wherever it is called from,
  //  and when that is the isolate drawing the screen, the screen stops. A
  //  backup gzips, encrypts and BLAKE2b-hashes every byte of the vault — for a
  //  vault with photographs in it, that is seconds of solid CPU. It is chunked
  //  at 64 KiB with an `await` between chunks, so it is not one long freeze; it
  //  is a few hundred small ones, which is worse, because the app looks broken
  //  rather than busy.
  //
  //  The two wrappers below move the *existing* code to a worker isolate
  //  without changing a byte of what it produces. That is deliberate: the file
  //  format is the one thing in this project that must never quietly change,
  //  and the way to be sure is for the byte-producing path to remain the path
  //  399 tests already cover. Only the plumbing around it is new.
  // ═══════════════════════════════════════════════════════════════════════════

  /// The one message the worker ever receives. Its content does not matter;
  /// its arrival does.
  static const String _cancelMessage = 'cancel';

  // ───────────────────────────────────────────────────────────────────────────
  //  Why the two callbacks below are built by `static` methods
  // ───────────────────────────────────────────────────────────────────────────
  //
  //  **ISSUE 2, round nine, and it is the worst bug this project has had.**
  //  Every backup failed — by hand and automatically — with a page and a half
  //  of this:
  //
  //      Illegal argument in isolate message: object is unsendable —
  //      Library:'dart:isolate' Class: _Timer
  //       <- Instance of 'Vault'  <- Instance of 'LamplightApp'  <- … 200 more
  //       <- Context num_variables 3  <- _BackupScreenState.run.<anonymous>
  //       <- Context num_variables 10 <- VaultFile.writeOffThread.<anonymous>
  //
  //  Read the chain from the bottom. `Isolate.run` copies the callback, so it
  //  copies everything the callback's **context** holds — and a Dart closure
  //  does not get a context of its own. Sibling closures written in the same
  //  function *share* one. `writeOffThread` had two: the isolate body, and the
  //  `fromWorker.listen` handler that reads progress. The listener touches
  //  `isCancelled`, and `isCancelled` is `() => _cancelRequested` — a closure
  //  over the backup screen's State. So the shared context held the State, the
  //  State held its element, the element held the widget tree, the tree held
  //  `LamplightApp`, that held `Vault`, and `Vault` holds `_idleTimer`.
  //
  //  A `Timer` cannot cross an isolate boundary. Nothing else about the backup
  //  was wrong: the format, the crypto and the chunking were all correct and
  //  none of them were ever reached. **The whole failure was one shared
  //  context, ten variables wide, and one of them was the entire app.**
  //
  //  Note what makes it so nasty: it only bites when an idle timer happens to
  //  be armed, which is to say on a real phone with a lock timeout set, and
  //  never on a laptop test where `isCancelled` closes over a plain `bool`.
  //  877 passing tests said the backup worked.
  //
  //  A `static` method has no enclosing context to share. The closure it
  //  returns can reach nothing but that method's own parameters, and every one
  //  of those is a path, an int, a plain map or a `SendPort`. There is no
  //  "be careful what you capture" left to get wrong later, which is the
  //  point — the previous code had a comment saying exactly that and it was
  //  already untrue when it was written.
  //
  //  `test/backup/isolate_carries_nothing_test.dart` hands `writeOffThread` an
  //  `isCancelled` that closes over a live `Timer` and insists the backup
  //  still finishes. It fails on the old code.
  // ───────────────────────────────────────────────────────────────────────────

  /// The body of the write worker. **Static: see the note above.**
  static SodiumIsolateCallback<List<int>> _writeWorker({
    required SodiumSumo sodium,
    required SendPort reply,
    required String destinationPath,
    required String rootPath,
    required Map<String, Object?> counts,
    required Uint8List salt,
    required int memLimit,
    required int opsLimit,
  }) {
    return (keys, _) async {
      final inbox = ReceivePort();
      var cancelled = false;
      // The writer awaits between chunks, so this listener gets its turn and
      // the flag is seen on the next one.
      final incoming = inbox.listen((_) => cancelled = true);
      reply.send(inbox.sendPort);

      final worker = VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));
      try {
        final summary = await worker.write(
          destination: File(destinationPath),
          vaultRoot: Directory(rootPath),
          counts: counts,
          key: BackupKey(
            kek: keys.first,
            salt: salt,
            memLimit: memLimit,
            opsLimit: opsLimit,
          ),
          // ISSUE 17. Present only when the caller sent one, which is why the
          // list is indexed by length rather than by position.
          recoveryKek: keys.length > 1 ? keys[1] : null,
          onProgress: reply.send,
          isCancelled: () => cancelled,
        );
        // Three integers, not the summary. A `BackupSummary` carries a `File`,
        // and the safe assumption about anything crossing a port is that it
        // does not travel — the caller already holds the file it named, so
        // there is nothing to send.
        return <int>[
          summary.byteSize,
          summary.memberCount,
          summary.chunkCount,
        ];
      } finally {
        await incoming.cancel();
        inbox.close();
        // The keys handed to a worker are copies, and nothing collects locked
        // libsodium memory when an isolate goes away. All of them, not just
        // the first — ISSUE 17 added a second.
        for (final k in keys) {
          k.dispose();
        }
      }
    };
  }

  /// The body of the verify worker. **Static: see the note above.**
  static SodiumIsolateCallback<bool> _verifyWorker({
    required SodiumSumo sodium,
    required String sourcePath,
    required String scratchPath,
    required Uint8List salt,
    required int memLimit,
    required int opsLimit,
  }) {
    return (keys, _) async {
      final worker = VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));
      try {
        await worker.verify(
          source: File(sourcePath),
          scratch: Directory(scratchPath),
          key: BackupKey(
            kek: keys.single,
            salt: salt,
            memLimit: memLimit,
            opsLimit: opsLimit,
          ),
        );
        return true;
      } finally {
        keys.single.dispose();
      }
    };
  }

  /// [write], on a worker isolate.
  ///
  /// Takes a [BackupKey] rather than a passcode, and that is the only
  /// difference in the interface. Deriving the key is already asynchronous —
  /// [deriveBackupKey] runs Argon2id on its own worker — so a caller holding a
  /// passcode calls that first and this second. Two isolate hops for two
  /// separate quarter-second costs, rather than one closure that has to know
  /// about both.
  ///
  /// **Progress and cancellation both cross the boundary, in opposite
  /// directions and by different means.** Progress is a `double` sent up a
  /// port. Cancellation cannot be, because `isCancelled` is a closure over a
  /// widget's state and a closure is not sendable — so the worker announces a
  /// port of its own, and this side answers *its* progress messages with a
  /// cancel when the flag flips. The check therefore happens at most one chunk
  /// late, which for a 64 KiB chunk is imperceptible.
  Future<BackupSummary> writeOffThread({
    required File destination,
    required Directory vaultRoot,
    required Map<String, Object?> counts,
    required BackupKey key,
    /// **ISSUE 17.** Travels alongside the passcode KEK as a second secure key,
    /// so the worker can write the recovery wrapper. Null writes a file with
    /// one wrapper, exactly as before.
    SecureKey? recoveryKek,
    void Function(double fraction)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final fromWorker = ReceivePort();
    final reply = fromWorker.sendPort;
    SendPort? toWorker;
    var cancelSent = false;

    final listening = fromWorker.listen((message) {
      // The worker's first message is the port to answer on. Everything after
      // it is a progress fraction.
      if (message is SendPort) {
        toWorker = message;
        return;
      }
      if (message is! double) return;
      onProgress?.call(message);
      if (!cancelSent && (isCancelled?.call() ?? false)) {
        cancelSent = true;
        toWorker?.send(_cancelMessage);
      }
    });

    try {
      final result = await _sodium.runIsolated<List<int>>(
        // Built by a static method, so the only things that cross are the
        // eight arguments below. See the note above `_writeWorker`.
        _writeWorker(
          sodium: _sodium,
          reply: reply,
          destinationPath: destination.path,
          rootPath: vaultRoot.path,
          counts: counts,
          salt: key.salt,
          memLimit: key.memLimit,
          opsLimit: key.opsLimit,
        ),
        secureKeys: [key.kek, ?recoveryKek],
      );

      return BackupSummary(
        file: destination,
        byteSize: result[0],
        memberCount: result[1],
        chunkCount: result[2],
      );
    } finally {
      await listening.cancel();
      fromWorker.close();
    }
  }

  /// [verify], on a worker isolate.
  ///
  /// Verifying is a full read-back — every chunk decrypted, every member
  /// hashed and compared — so it costs about what writing cost, and until now
  /// it spent that on the isolate drawing the screen, immediately after the
  /// write had finished doing the same. That is the "Checking it opens…" stage
  /// sitting motionless.
  ///
  /// Nothing to report and nothing to cancel: it either comes back or it
  /// throws, and `BACKUP-FILE-FORMAT.md` step 6 says nobody is told a backup
  /// worked until it does.
  Future<void> verifyOffThread({
    required File source,
    required Directory scratch,
    required BackupKey key,
  }) async {
    await _sodium.runIsolated<bool>(
      _verifyWorker(
        sodium: _sodium,
        sourcePath: source.path,
        scratchPath: scratch.path,
        salt: key.salt,
        memLimit: key.memLimit,
        opsLimit: key.opsLimit,
      ),
      secureKeys: [key.kek],
    );
  }

  /// The chunk reader. Yields plaintext, one chunk at a time.
  Stream<Uint8List> _decryptBody({
    required File source,
    required BackupInfo info,
    required SecureKey key,
    void Function(double fraction)? onProgress,
  }) async* {
    final aead = _sodium.crypto.aeadXChaCha20Poly1305IETF;
    final nonceBytes = aead.nonceBytes;
    final buffer = _ByteQueue();
    var index = 0;

    await for (final block in source.openRead(info.bodyStart, info.bodyEnd)) {
      buffer.add(block);
      while (true) {
        if (buffer.length < 4) break;
        final len = _readU32(buffer.peek(4), 0);
        if (len < aead.aBytes || len > chunkSize + aead.aBytes) {
          throw const BackupError(
              'This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
        }
        if (buffer.length < 4 + nonceBytes + len) break;

        buffer.skip(4);
        final nonce = buffer.take(nonceBytes);
        final sealed = buffer.take(len);

        // The index really is checked, not merely written. Without this, a file
        // whose chunks had been reordered or had one dropped would decrypt
        // perfectly — each chunk is independently valid — and the user would
        // restore a vault that is quietly not the one they backed up.
        final claimed = _readU64(nonce, _noncePrefixLength);
        if (claimed != index) {
          throw const BackupError(
              'This file is damaged: its contents are out of order.',
            problem: BackupProblem.outOfOrder);
        }

        final Uint8List plain;
        try {
          plain = aead.decrypt(
            cipherText: sealed,
            nonce: nonce,
            key: key,
            additionalData: info.headerBytes,
          );
        } catch (_) {
          throw const BackupError(
              'This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
        }
        index++;
        if (info.chunkCount > 0) {
          onProgress?.call((index / info.chunkCount).clamp(0.0, 1.0));
        }
        yield plain;
      }
    }

    if (!buffer.isEmpty) {
      throw const BackupError('This file is damaged: it ends part-way through.',
            problem: BackupProblem.endsPartWay);
    }
    // The count lives in the authenticated footer, so a truncated file is
    // caught here even though every chunk that survived was perfectly valid.
    if (index != info.chunkCount) {
      throw BackupError(
          'This file is incomplete — it has $index of ${info.chunkCount} parts.',
            problem: BackupProblem.incomplete,
            detail: '\$index / \${info.chunkCount}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Bits and pieces
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<_Member>> _collectMembers(Directory root) async {
    final members = <_Member>[];

    // Order matters on the way back in: the keyring is what makes the database
    // openable, so it goes first and a truncated file is more likely to still
    // be diagnosable.
    for (final name in [keyringMember, databaseMember]) {
      final f = File('${root.path}/$name');
      if (await f.exists()) {
        members.add(_Member(name, f, await f.length()));
      }
    }

    final attachments = Directory('${root.path}/attachments');
    if (await attachments.exists()) {
      final files = await attachments
          .list()
          .where((e) => e is File)
          .cast<File>()
          .toList();
      // Sorted, so two backups of an unchanged vault differ only in their
      // random salt and nonces rather than in the order the filesystem felt
      // like listing things.
      files.sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        final name = 'attachments/${p.basename(f.path)}';
        if (!_allowedMember.hasMatch(name)) continue;
        members.add(_Member(name, f, await f.length()));
      }
    }
    return members;
  }

  Future<Uint8List> _hashFile(File file) => _sodium.crypto.genericHash.stream(
        messages: file
            .openRead()
            .map((b) => b is Uint8List ? b : Uint8List.fromList(b)),
        outLen: 32,
      );

  Uint8List _nonceFor(Uint8List prefix, int index) {
    final nonce = Uint8List(_noncePrefixLength + 8);
    nonce.setRange(0, _noncePrefixLength, prefix);
    nonce.setRange(_noncePrefixLength, nonce.length, _u64(index));
    return nonce;
  }

  String _uuid() {
    final b = _crypto.randomBytes(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String hex(int s, int e) => b
        .sublist(s, e)
        .map((x) => x.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}

// ── Framing helpers ──────────────────────────────────────────────────────────

Uint8List _u16(int v) => Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);

Uint8List _u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);

Uint8List _u64(int v) => Uint8List(8)..buffer.asByteData().setUint64(0, v, Endian.little);

int _readU32(Uint8List b, int offset) =>
    ByteData.sublistView(b).getUint32(offset, Endian.little);

int _readU64(Uint8List b, int offset) =>
    ByteData.sublistView(b).getUint64(offset, Endian.little);

Future<Uint8List> _readRange(File file, int start, int end) async {
  final out = BytesBuilder(copy: false);
  await for (final block in file.openRead(start, end)) {
    out.add(block);
  }
  return out.takeBytes();
}

/// Compares two digests without leaking where they first differ.
///
/// Overkill for a hash the attacker already has, and it costs nothing. The
/// habit is what matters: the day this function is reached for on something
/// that *is* secret, it should already be the one that is there.
bool _constantTimeEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Regroups a byte stream into fixed-size blocks.
///
/// gzip hands back whatever size it feels like; the format wants 64 KiB
/// plaintext chunks. The last block is short, which is fine — its length is
/// written in front of it.
Stream<Uint8List> _rechunk(Stream<List<int>> source, int size) async* {
  final queue = _ByteQueue();
  await for (final block in source) {
    queue.add(block);
    while (queue.length >= size) {
      yield queue.take(size);
    }
  }
  if (!queue.isEmpty) yield queue.take(queue.length);
}

/// A first-in-first-out byte buffer.
///
/// Deliberately plain. A cleverer rope or ring buffer would be faster and would
/// be the sort of thing that has an off-by-one in it that only shows up on a
/// 5 GB restore, which is the worst possible day to find one.
class _ByteQueue {
  final _blocks = <Uint8List>[];
  int _offset = 0;
  int _length = 0;

  int get length => _length;

  bool get isEmpty => _length == 0;

  void add(List<int> bytes) {
    if (bytes.isEmpty) return;
    _blocks.add(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    _length += bytes.length;
  }

  Uint8List peek(int n) => _read(n, consume: false);

  Uint8List take(int n) => _read(n, consume: true);

  void skip(int n) => _read(n, consume: true);

  Uint8List _read(int n, {required bool consume}) {
    if (n > _length) throw StateError('asked for $n bytes, have $_length');
    final out = Uint8List(n);
    var written = 0;
    var block = 0;
    var offset = _offset;
    while (written < n) {
      final b = _blocks[block];
      final available = b.length - offset;
      final wanted = n - written;
      final take = available < wanted ? available : wanted;
      out.setRange(written, written + take, b, offset);
      written += take;
      offset += take;
      if (offset == b.length) {
        block++;
        offset = 0;
      }
    }
    if (consume) {
      _blocks.removeRange(0, block);
      _offset = offset;
      _length -= n;
      if (_length == 0) {
        _blocks.clear();
        _offset = 0;
      }
    }
    return out;
  }
}

/// Turns the inner stream back into files under a staging directory.
///
/// A state machine rather than "read it all and then split it", because
/// `BACKUP-FILE-FORMAT.md` goal 3 is that a 5 GB vault restores without being
/// loaded into RAM, and the obvious implementation quietly breaks that.
class _MemberWriter {
  _MemberWriter(this.staging);

  final Directory staging;

  final _queue = _ByteQueue();
  _MemberState _state = _MemberState.nameLength;
  String? _name;
  int _remaining = 0;
  IOSink? _sink;

  Future<void> consume(Stream<List<int>> stream) async {
    try {
      await for (final block in stream) {
        _queue.add(block);
        await _drain();
      }
      await _sink?.flush();
      await _sink?.close();
      _sink = null;
    } finally {
      // A member still being written when something throws leaves an open file
      // handle behind, and on Windows an open handle makes the whole staging
      // directory undeletable. That matters twice over: `verify` cleans up in
      // a `finally`, so its cleanup throws, and the deletion error *replaces*
      // the real one — the user is told "Deletion failed, path = …" about a
      // file that is actually damaged, which `UX-FLOWS.md` flow 6 exists to
      // prevent. And the staging copy survives, when the one thing `verify`
      // promises is that it leaves nothing behind.
      await _closeSink();
    }
    if (_state != _MemberState.nameLength || _remaining != 0) {
      throw const BackupError('This file is damaged: it ends part-way through.',
            problem: BackupProblem.endsPartWay);
    }
  }

  /// Closes whatever member was open, swallowing anything it says.
  ///
  /// Only ever called on the way out. If we are here because the file was
  /// damaged, that is the error worth reporting, and a complaint from a sink
  /// on a half-written file would bury it.
  Future<void> _closeSink() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      await sink.close();
    } catch (_) {}
  }

  Future<void> _drain() async {
    while (true) {
      switch (_state) {
        case _MemberState.nameLength:
          if (_queue.length < 2) return;
          _remaining = ByteData.sublistView(_queue.take(2))
              .getUint16(0, Endian.little);
          if (_remaining == 0 || _remaining > 256) {
            throw const BackupError(
                'This file is damaged and cannot be opened.',
            problem: BackupProblem.damaged);
          }
          _state = _MemberState.name;

        case _MemberState.name:
          if (_queue.length < _remaining) return;
          final name = utf8.decode(_queue.take(_remaining));
          if (!VaultFile._allowedMember.hasMatch(name)) {
            // Refused rather than skipped. A file containing a member we did
            // not write is a file we do not understand, and quietly ignoring
            // the parts of it we dislike is how path traversal gets shipped.
            throw BackupError(
                'This backup contains something Lamplight will not open ($name).',
            problem: BackupProblem.willNotOpen,
            detail: name);
          }
          _name = name;
          _state = _MemberState.dataLength;

        case _MemberState.dataLength:
          if (_queue.length < 8) return;
          _remaining = ByteData.sublistView(_queue.take(8))
              .getUint64(0, Endian.little);
          final file = File('${staging.path}/$_name');
          await file.parent.create(recursive: true);
          _sink = file.openWrite();
          if (_remaining == 0) {
            await _sink!.flush();
            await _sink!.close();
            _sink = null;
            _state = _MemberState.nameLength;
          } else {
            _state = _MemberState.data;
          }

        case _MemberState.data:
          if (_queue.isEmpty) return;
          final take =
              _queue.length < _remaining ? _queue.length : _remaining;
          _sink!.add(_queue.take(take));
          _remaining -= take;
          if (_remaining == 0) {
            await _sink!.flush();
            await _sink!.close();
            _sink = null;
            _state = _MemberState.nameLength;
          }
      }
    }
  }
}

enum _MemberState { nameLength, name, dataLength, data }

class _Member {
  const _Member(this.name, this.file, this.size);

  final String name;
  final File file;
  final int size;
}

// ── Results ──────────────────────────────────────────────────────────────────

class BackupSummary {
  const BackupSummary({
    required this.file,
    required this.byteSize,
    required this.memberCount,
    required this.chunkCount,
  });

  final File file;
  final int byteSize;
  final int memberCount;
  final int chunkCount;
}

class BackupInfo {
  const BackupInfo({
    required this.header,
    required this.headerBytes,
    this.hasRecoveryWrapper = false,
    required this.bodyStart,
    required this.bodyEnd,
    required this.chunkCount,
    required this.createdAt,
    required this.appVersion,
  });

  final Map<String, Object?> header;
  final Uint8List headerBytes;

  /// Whether the twelve words open this file. **ISSUE 17.**
  ///
  /// False for every v1 file, and for a v2 file written by a vault that has no
  /// recovery phrase. The restore screen reads this to decide whether to offer
  /// the words at all — offering a way in that the file does not have would be
  /// the invisible-machinery fault in its most painful possible place.
  final bool hasRecoveryWrapper;

  final int bodyStart;
  final int bodyEnd;
  final int chunkCount;
  final DateTime? createdAt;
  final String? appVersion;
}

class RestoreSummary {
  const RestoreSummary({
    required this.staging,
    required this.entryCount,
    required this.dayCount,
    required this.attachmentCount,
    required this.createdAt,
  });

  final Directory staging;
  final int entryCount;
  final int dayCount;
  final int attachmentCount;
  final DateTime? createdAt;
}

/// The Argon2id output that seals a backup file, and the salt it came from.
///
/// The two travel together because they have to: the salt goes in the file's
/// header, and a key derived from a different salt will never open it. Keeping
/// them in one object removes the possibility of pairing the wrong two.
class BackupKey {
  const BackupKey({
    required this.kek,
    required this.salt,
    required this.memLimit,
    required this.opsLimit,
  });

  final SecureKey kek;
  final Uint8List salt;
  final int memLimit;
  final int opsLimit;

  void dispose() => kek.dispose();
}

/// Something went wrong with a backup file, said in words a person can act on.
///
/// `UX-FLOWS.md` flow 6 lists the failure cases and requires each to have a
/// distinct and honest message — wrong passcode, corrupt file, newer format,
/// interrupted. Every `throw` in this file carries one of those sentences
/// rather than an exception class name, because the sentence is what the user
/// will see.
/// Why a backup or a restore could not go on. **ROUND FIFTEEN.**
///
/// ── WHY THE EXCEPTION CARRIES A KEY AND NOT ONLY A SENTENCE ──────────────
///
/// > *"LOCALISATION I WANT YOU TO AIM FOR 100% LOCALISATION, don't even leave
/// > a tiny bits now bro!"*
///
/// These were the last English strings a person could see, and they are the
/// ones that matter most: **the sentence shown when a backup or a restore
/// fails.** Somebody reading the app in Hindi does not switch to English at the
/// moment their notes are at stake.
///
/// They could not simply become `L.of(context).…` like every other string,
/// because they are thrown from `core/`, where there is no `BuildContext` and
/// should not be one — this file runs inside isolates, from background paths,
/// and from tests with no widget tree at all. So the exception carries **what
/// went wrong** and the screen, which has a context, decides how to say it.
///
/// The English sentence stays on [BackupError.message] as well. It is what the
/// tests assert against, what `assert`s print, and the fallback for a caller
/// with no `L` in hand — the same rule the ARB files follow, where a missing
/// key falls back to English rather than failing the build.
enum BackupProblem {
  nothingToBackUp,

  /// The vault changed under the backup. [BackupError.detail] names the file.
  changedWhileBackingUp,
  tooSmall,
  notALamplightFile,

  /// The catch-all, and deliberately one message rather than seven. A person
  /// cannot act on *which* header field failed to parse, and `UX-FLOWS.md`
  /// flow 6 asks for a distinct message per *case somebody can do something
  /// about* rather than per branch.
  damaged,
  newerVersion,
  unknownCompression,
  damagedTryOlder,
  madeBeforeRecoveryPhrases,
  wordsDoNotOpenIt,
  wrongPasscode,

  /// [BackupError.detail] names the missing member.
  missingPart,
  partWrongSize,
  partDoesNotMatch,
  noVaultInside,
  outOfOrder,
  endsPartWay,

  /// [BackupError.detail] is "3 / 7".
  incomplete,

  /// [BackupError.detail] names the member.
  willNotOpen,
}

class BackupError implements Exception, PlainlySaid, Localisable {
  const BackupError(this.message, {this.problem, this.detail});

  /// The English sentence. See [BackupProblem] for why both exist.
  final String message;

  /// What went wrong, for a screen that can translate it.
  final BackupProblem? problem;

  /// A filename, or a count — whatever the sentence names.
  ///
  /// **Never translated.** A filename is a filename in every language, and a
  /// count of parts is digits. Passing it through the ARB as a placeholder
  /// keeps it out of the translated text, where a translator would have no way
  /// to know it was not a word.
  final String? detail;

  @override
  String get plainMessage => message;

  @override
  String describeIn(L l) {
    final what = detail ?? '';
    return switch (problem) {
      null => message,
      BackupProblem.nothingToBackUp => l.vaultNothingToBackUp,
      BackupProblem.changedWhileBackingUp => l.vaultChangedWhileBackingUp(what),
      BackupProblem.tooSmall => l.vaultTooSmall,
      BackupProblem.notALamplightFile => l.vaultNotALamplightFile,
      BackupProblem.damaged => l.vaultDamaged,
      BackupProblem.newerVersion => l.vaultNewerVersion,
      BackupProblem.unknownCompression => l.vaultUnknownCompression,
      BackupProblem.damagedTryOlder => l.vaultDamagedTryOlder,
      BackupProblem.madeBeforeRecoveryPhrases => l.vaultBeforeRecoveryPhrases,
      BackupProblem.wordsDoNotOpenIt => l.vaultWordsDoNotOpenIt,
      BackupProblem.wrongPasscode => l.vaultWrongPasscode,
      BackupProblem.missingPart => l.vaultMissingPart(what),
      BackupProblem.partWrongSize => l.vaultPartWrongSize(what),
      BackupProblem.partDoesNotMatch => l.vaultPartDoesNotMatch(what),
      BackupProblem.noVaultInside => l.vaultNoVaultInside,
      BackupProblem.outOfOrder => l.vaultOutOfOrder,
      BackupProblem.endsPartWay => l.vaultEndsPartWay,
      BackupProblem.incomplete => l.vaultIncomplete(what),
      BackupProblem.willNotOpen => l.vaultWillNotOpen(what),
    };
  }

  @override
  String toString() => message;
}

/// The user stopped it. Not a failure, and never shown as one.
class BackupCancelled implements Exception {
  const BackupCancelled();

  @override
  String toString() => 'Backup cancelled.';
}
