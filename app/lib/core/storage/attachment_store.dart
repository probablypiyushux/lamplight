import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import '../crypto/vault_crypto.dart';
import '../db/database.dart' show uuidV4;

/// Encrypted storage for photos, voice notes, PDFs and documents.
/// `02-security/SECURITY-ARCHITECTURE.md` §6.
///
/// WHAT SOMEONE SEES IF THEY BROWSE THE APP'S STORAGE
///
/// A flat pile of identically-shaped, random-named blobs. They cannot tell a
/// voice note from a photo from a tax PDF, cannot count how many are photos,
/// and cannot read a single filename. The real name, MIME type and dimensions
/// live as columns in the encrypted database. **The filesystem layout itself
/// leaks nothing** — that is a design goal, not a side effect.
///
/// WHY STREAMING, NOT "READ THE FILE AND ENCRYPT IT"
///
/// `03-product/FEATURES-IN-AND-OUT.md` projects about 4 GB per year of voice
/// and photos. A 500 MB video must encrypt and decrypt without ever being
/// fully in RAM, or the app dies on the exact devices most of its users have.
///
/// WHY libsodium's secretstream RATHER THAN THE HAND-ROLLED FRAMING IN §6
///
/// §6 describes building this by hand: 64 KiB chunks, a nonce derived from a
/// random file nonce plus the chunk index, and a flag on the final chunk so
/// truncation is detected. libsodium's `crypto_secretstream` **is** that
/// construction, implemented and reviewed by the library rather than by us. It
/// binds each chunk to its position, so a reordered or duplicated chunk fails,
/// and it tags the final chunk, so a truncated file fails. §2 of the same
/// document opens by saying we will not be clever; rebuilding a framing format
/// the library already ships is exactly the kind of clever it means.
class AttachmentStore {
  AttachmentStore({
    required this.directory,
    required SodiumSumo sodium,
    required VaultCrypto crypto,
  })  : _sodium = sodium,
        _crypto = crypto;

  /// Where the `.enc` blobs live. App-private storage, never external.
  final Directory directory;

  final SodiumSumo _sodium;
  final VaultCrypto _crypto;

  /// 64 KiB, per §6.
  ///
  /// The trade-off it settles: bigger chunks mean less per-chunk overhead but
  /// more memory held at once and coarser resume; smaller chunks mean more
  /// authentication tags. 64 KiB is the documented figure and there is no
  /// reason to differ from it.
  static const int chunkSize = 64 * 1024;

  File fileFor(String id) => File('${directory.path}/$id.enc');

  /// Encrypts [source] into a new blob and returns its id and key.
  ///
  /// The caller must store [StoredAttachment.fileKey] in the database. Lose it
  /// and the blob is unrecoverable — which is the intended property, not a
  /// hazard: the key exists only inside the encrypted database.
  ///
  /// Each attachment gets its **own** random key rather than sharing one. If a
  /// single file's key were ever exposed, it exposes that one file and nothing
  /// else.
  Future<StoredAttachment> write(Stream<List<int>> source) async {
    await directory.create(recursive: true);
    final id = uuidV4(_crypto.randomBytes);
    final fileKeyBytes = _crypto.randomBytes(32);
    final fileKey = SecureKey.fromList(_sodium, fileKeyBytes);

    final target = fileFor(id);
    // Write to a temporary name first. A half-written attachment that is never
    // referenced by the database is litter; one that IS referenced is a broken
    // entry. Renaming into place at the end means the final path either does
    // not exist or is complete.
    final temp = File('${target.path}.part');
    final sink = temp.openWrite();
    var bytesWritten = 0;

    try {
      final cipherStream = _sodium.crypto.secretStream.pushChunked(
        messageStream: source,
        key: fileKey,
        chunkSize: chunkSize,
      );
      await for (final chunk in cipherStream) {
        sink.add(chunk);
        bytesWritten += chunk.length;
      }
      await sink.flush();
      await sink.close();
      await temp.rename(target.path);
    } catch (_) {
      await sink.close().catchError((_) {});
      if (temp.existsSync()) await temp.delete();
      fileKey.dispose();
      rethrow;
    }

    fileKey.dispose();
    return StoredAttachment(
      id: id,
      fileKey: fileKeyBytes,
      cipherBytes: bytesWritten,
    );
  }

  /// Convenience for content already in memory — a captured photo, a thumbnail.
  Future<StoredAttachment> writeBytes(List<int> bytes) =>
      write(Stream.value(bytes));

  /// Decrypts a blob back to a stream of plaintext.
  ///
  /// Throws if the key is wrong, if any chunk was modified, if chunks were
  /// reordered, or if the file was truncated. It never yields partial garbage:
  /// each chunk is authenticated before it is emitted.
  Stream<List<int>> read(String id, Uint8List fileKeyBytes) async* {
    final file = fileFor(id);
    if (!file.existsSync()) {
      throw AttachmentMissing(id);
    }

    // A zero-length or stub file must fail loudly rather than decrypting to
    // nothing. Found by a test: `pullChunked` over an empty stream completes
    // without error and yields no data, so a file truncated to nothing read
    // back as a perfectly valid *empty* attachment. A blank photo with no
    // error is worse than an error — the user would think the content was
    // never there rather than that it was damaged.
    //
    // Even a zero-byte plaintext produces a stream header plus one
    // authenticated final chunk, so anything shorter than that cannot be a
    // file this store wrote.
    final minimum =
        _sodium.crypto.secretStream.headerBytes + _sodium.crypto.secretStream.aBytes;
    final length = file.lengthSync();
    if (length < minimum) {
      throw AttachmentDamaged(id, 'file is $length bytes, shorter than a valid header');
    }

    final fileKey = SecureKey.fromList(_sodium, fileKeyBytes);
    try {
      yield* _sodium.crypto.secretStream.pullChunked(
        cipherStream: file.openRead(),
        key: fileKey,
        chunkSize: chunkSize,
      );
    } finally {
      fileKey.dispose();
    }
  }

  /// Reads a whole attachment into memory, **on the calling isolate**.
  ///
  /// Prefer [readAllBytesOffThread] anywhere a screen is on the other end.
  /// This one stays for tests and for code already running on a worker.
  Future<Uint8List> readAllBytes(String id, Uint8List fileKeyBytes) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in read(id, fileKeyBytes)) {
      out.add(chunk);
    }
    return out.takeBytes();
  }

  /// The same read, on a worker isolate.
  ///
  /// WHY A PHOTO USED TO FREEZE THE SCROLL
  ///
  /// Decrypting a 4 MB photograph is sixty-odd chunks of XChaCha20-Poly1305
  /// plus sixty file reads, and every one of them ran on the isolate that draws
  /// the screen. One photo is a hitch. **Two photos on the same day is a
  /// visible stall**, reported exactly that way — "when I am scrolling and it
  /// has two images then it just hangs". It was not the images. It was that
  /// nothing could be drawn while they were being opened.
  ///
  /// Moving it here does two things at once: the crypto leaves the UI isolate,
  /// and so does the file I/O, which on a phone with a busy flash controller is
  /// the slower half of the two.
  ///
  /// The key crosses as a native `SecureKey` handle rather than as bytes on a
  /// port, so it is never a plain `Uint8List` that the collector could copy.
  /// The plaintext comes back as bytes, which is unavoidable — the caller is
  /// going to hand them to an image decoder — and it is the same exposure the
  /// synchronous version always had.
  Future<Uint8List> readAllBytesOffThread(
      String id, Uint8List fileKeyBytes) async {
    final file = fileFor(id);
    if (!file.existsSync()) throw AttachmentMissing(id);
    final minimum = _sodium.crypto.secretStream.headerBytes +
        _sodium.crypto.secretStream.aBytes;
    final length = file.lengthSync();
    if (length < minimum) {
      throw AttachmentDamaged(
          id, 'file is $length bytes, shorter than a valid header');
    }

    final key = SecureKey.fromList(_sodium, fileKeyBytes);
    try {
      return await _sodium.runIsolated<Uint8List>(
        _reader(sodium: _sodium, path: file.path),
        secureKeys: [key],
      );
    } finally {
      key.dispose();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Why the workers below are built by `static` methods
  // ───────────────────────────────────────────────────────────────────────────
  //
  //  `Isolate.run` copies the callback, and a Dart closure has no context of
  //  its own — sibling closures written in the same function **share** one, and
  //  the whole shared context is copied whether the worker reads it or not.
  //  Round nine's ISSUE 2 was that bug in `vault_file.dart`: one sibling
  //  closure touched a widget's State and every backup in the app died with a
  //  page of `object is unsendable — Class: _Timer`. The long version is in the
  //  note above `VaultFile._writeWorker`.
  //
  //  Nothing in this file has that problem today. It is written this way so it
  //  cannot acquire one: a `static` method has no enclosing context to share,
  //  so the worker can reach nothing but its own parameters. That matters here
  //  specifically because ISSUE 12 asks for import progress, and a progress
  //  callback is precisely the sibling closure that would reintroduce it.
  // ───────────────────────────────────────────────────────────────────────────

  static SodiumIsolateCallback<Uint8List> _reader({
    required SodiumSumo sodium,
    required String path,
  }) {
    return (keys, _) async {
      // The key handed to a worker is a COPY of the caller's, so this isolate
      // owns it and has to release it. Nothing collects locked libsodium
      // memory for us when the isolate goes away.
      try {
        final out = BytesBuilder(copy: false);
        final stream = sodium.crypto.secretStream.pullChunked(
          cipherStream: File(path).openRead(),
          key: keys.single,
          chunkSize: chunkSize,
        );
        await for (final chunk in stream) {
          out.add(chunk);
        }
        return out.takeBytes();
      } finally {
        keys.single.dispose();
      }
    };
  }

  static SodiumIsolateCallback<int> _writer({
    required SodiumSumo sodium,
    required String target,
    required Uint8List bytes,
    SendPort? reply,
  }) {
    return (keys, _) async {
      final temp = File('$target.part');
      final sink = temp.openWrite();
      var n = 0;
      try {
        final cipher = sodium.crypto.secretStream.pushChunked(
          messageStream: Stream<List<int>>.value(bytes),
          key: keys.single,
          chunkSize: chunkSize,
        );
        await for (final chunk in cipher) {
          sink.add(chunk);
          n += chunk.length;
          // ISSUE 12. Bytes sealed so far, so the caller can say something
          // truthful about a large import rather than showing a bar that
          // moves on a timer.
          reply?.send(n);
        }
        await sink.flush();
        await sink.close();
        await temp.rename(target);
      } catch (_) {
        await sink.close().catchError((_) {});
        if (temp.existsSync()) await temp.delete();
        rethrow;
      } finally {
        // The worker owns its copy of the key. See the note on the read side —
        // nothing releases locked libsodium memory for us.
        keys.single.dispose();
      }
      return n;
    };
  }

  /// Encrypts [bytes] into a new blob, on a worker isolate.
  ///
  /// The write side of the same problem. Importing twenty photographs meant
  /// twenty encryptions on the UI isolate, back to back, and the capture bar
  /// sat frozen through all of them — which is precisely when a person is
  /// most likely to think the app has died and force-quit it, taking the
  /// import with them.
  Future<StoredAttachment> writeBytesOffThread(
    Uint8List bytes, {
    /// **ISSUE 12.** Called with the number of bytes sealed so far. The caller
    /// turns that into something the user can watch; nothing here knows or
    /// cares what.
    void Function(int sealed)? onProgress,
  }) async {
    await directory.create(recursive: true);
    final id = uuidV4(_crypto.randomBytes);
    final fileKeyBytes = _crypto.randomBytes(32);
    final key = SecureKey.fromList(_sodium, fileKeyBytes);
    final target = fileFor(id).path;

    // Only opened when somebody is listening. A port costs a little, and a
    // silent import is still the common case.
    final fromWorker = onProgress == null ? null : ReceivePort();
    final listening = fromWorker?.listen((m) {
      if (m is int) onProgress?.call(m);
    });

    try {
      final written = await _sodium.runIsolated<int>(
        _writer(
          sodium: _sodium,
          target: target,
          bytes: bytes,
          reply: fromWorker?.sendPort,
        ),
        secureKeys: [key],
      );
      return StoredAttachment(
          id: id, fileKey: fileKeyBytes, cipherBytes: written);
    } finally {
      await listening?.cancel();
      fromWorker?.close();
      key.dispose();
    }
  }

  /// Overwrites the blob before unlinking it.
  ///
  /// §7 requires a purge that actually reclaims space rather than leaving the
  /// content in free blocks. Honest caveat, and it belongs in the public threat
  /// model rather than being quietly assumed away: on a flash device with
  /// wear levelling, overwriting a file does **not** reliably erase the
  /// physical blocks — the controller may write elsewhere and leave the
  /// original cells intact. What genuinely protects deleted attachments is that
  /// they were only ever written encrypted. The overwrite is defence in depth,
  /// not the defence.
  Future<void> delete(String id) async {
    final file = fileFor(id);
    if (!file.existsSync()) return;
    final length = await file.length();
    final handle = await file.open(mode: FileMode.writeOnly);
    try {
      var remaining = length;
      final blank = Uint8List(chunkSize);
      while (remaining > 0) {
        final n = remaining < chunkSize ? remaining : chunkSize;
        await handle.writeFrom(blank, 0, n);
        remaining -= n;
      }
      await handle.flush();
    } finally {
      await handle.close();
    }
    await file.delete();
  }

  /// Every blob id currently on disk. Used to find orphans — files with no
  /// database row, which a crash between writing a blob and committing its row
  /// would leave behind.
  List<String> listIds() {
    if (!directory.existsSync()) return const [];
    return directory
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.enc'))
        .map((n) => n.substring(0, n.length - 4))
        .toList();
  }
}

/// The result of storing one attachment.
class StoredAttachment {
  const StoredAttachment({
    required this.id,
    required this.fileKey,
    required this.cipherBytes,
  });

  /// Random UUID. Also the filename, with no extension and no hint.
  final String id;

  /// This file's own 256-bit key. Belongs in the encrypted database and
  /// nowhere else.
  final Uint8List fileKey;

  /// Size on disk, which is slightly larger than the plaintext because of the
  /// stream header and one authentication tag per chunk.
  final int cipherBytes;
}

class AttachmentMissing implements Exception {
  const AttachmentMissing(this.id);

  final String id;

  @override
  String toString() =>
      'That attachment is missing from storage. It may have been removed by a '
      'restore, or the vault may be damaged.';
}

/// The blob exists but cannot be a file this store wrote.
///
/// Kept separate from [AttachmentMissing] because the two mean different things
/// to a person: "it is gone" versus "it is here and broken". The second is the
/// one where an older backup is worth trying.
class AttachmentDamaged implements Exception {
  const AttachmentDamaged(this.id, this.detail);

  final String id;
  final String detail;

  @override
  String toString() =>
      'That attachment is damaged and cannot be opened. If you have an older '
      'backup, try that.';
}
