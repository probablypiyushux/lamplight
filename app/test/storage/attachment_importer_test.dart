import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **`CLAUDE.md` rule 2: "Every import path must scrub its temp file and there
/// must be a test proving it."** This is that test.
///
/// WHY IT MATTERS MORE THAN IT LOOKS
///
/// Android hands content over as a file. The camera writes a JPEG; the document
/// picker copies bytes into a path we named. For a few hundred milliseconds the
/// user's photograph exists on disk in the clear, and the importer's whole job
/// is to make that window as short as possible and then close it — every time,
/// including the times something goes wrong.
///
/// The success path is the easy one and it is not the one that would ever leak.
/// **The failure paths are.** An import that throws halfway is exactly when a
/// plaintext photo gets left behind in the cache, and it is exactly the case
/// nobody tests. So most of this file is about failure.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;
  late EntryRepository repo;

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_import');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: const Duration(hours: 1),
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    importer = AttachmentImporter(vault);
    repo = EntryRepository(vault.database, attachments: vault.attachments);
  });

  tearDown(() async {
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// A stand-in for what the camera or the picker leaves in the cache.
  ///
  /// Deliberately recognisable bytes: the test then goes looking for exactly
  /// this pattern across the whole of the app's storage, which is a stronger
  /// claim than "the file we knew about is gone".
  final marker = Uint8List.fromList(
      List.generate(9000, (i) => 'PLAINTEXT-SECRET'.codeUnitAt(i % 16)));

  CapturedFile stage(String name, String mime) {
    final dir = Directory('${tmp.path}/cache')..createSync(recursive: true);
    final file = File('${dir.path}/$name')..writeAsBytesSync(marker);
    return CapturedFile(file: file, name: name, mimeType: mime);
  }

  /// Scans every byte of the vault and the cache for the marker.
  ///
  /// The same shape of check as the Phase 1 exit test, and for the same reason:
  /// "the file is deleted" is a claim about one path, while "the bytes are
  /// nowhere" is a claim about the property we actually care about.
  Future<List<String>> filesContainingMarker() async {
    final needle = 'PLAINTEXT-SECRET'.codeUnits;
    final hits = <String>[];
    for (final root in [tmp]) {
      if (!root.existsSync()) continue;
      await for (final entity in root.list(recursive: true)) {
        if (entity is! File) continue;
        final bytes = await entity.readAsBytes();
        for (var i = 0; i + needle.length <= bytes.length; i++) {
          var match = true;
          for (var j = 0; j < needle.length; j++) {
            if (bytes[i + j] != needle[j]) {
              match = false;
              break;
            }
          }
          if (match) {
            hits.add(entity.path);
            break;
          }
        }
      }
    }
    return hits;
  }

  // ═════════════════════════════════════════════════════════════════════════
  group('a successful import', () {
    test('the temp file is gone and its bytes are nowhere on disk', () async {
      final captured = stage('holiday.jpg', 'image/jpeg');
      final path = captured.file.path;

      await importer.importCaptured(
          captured: captured, dayKey: '2026-08-19');

      expect(File(path).existsSync(), isFalse,
          reason: 'the plaintext temp file must be deleted');
      expect(await filesContainingMarker(), isEmpty,
          reason: 'the plaintext bytes must not survive anywhere, including '
              'inside the encrypted blob — which would mean it was not '
              'actually encrypted');
    });

    test('the entry and its attachment row are both there', () async {
      final id = await importer.importCaptured(
        captured: stage('holiday.jpg', 'image/jpeg'),
        dayKey: '2026-08-19',
      );

      final entry = await repo.entryById(id);
      expect(entry, isNotNull);
      expect(entry!.type, 'photo');
      expect(entry.attachmentId, isNotNull);

      final attachment = await importer.attachmentFor(entry);
      expect(attachment, isNotNull);
      // The real name lives in the encrypted database and never on disk.
      expect(attachment!.originalName, 'holiday.jpg');
      expect(attachment.byteSize, marker.length);
    });

    test('the content comes back out byte for byte', () async {
      final id = await importer.importCaptured(
        captured: stage('report.pdf', 'application/pdf'),
        dayKey: '2026-08-19',
      );
      final entry = await repo.entryById(id);
      final attachment = await importer.attachmentFor(entry!);

      expect(await importer.bytesOf(attachment!), equals(marker));
    });

    test('the blob on disk gives nothing away', () async {
      await importer.importCaptured(
        captured: stage('tax-return-2026.pdf', 'application/pdf'),
        dayKey: '2026-08-19',
      );

      final blobs = Directory('${vault.root.path}/attachments').listSync();
      expect(blobs, hasLength(1));
      final name = blobs.single.uri.pathSegments.last;

      // A random UUID and `.enc`. No extension, no hint, no original name.
      // Someone browsing app storage cannot tell a voice note from a photo
      // from a tax return, which SECURITY-ARCHITECTURE.md §6 calls a design
      // goal rather than a side effect.
      expect(name, matches(RegExp(r'^[0-9a-f-]{36}\.enc$')));
      expect(name.contains('tax'), isFalse);
      expect(name.contains('pdf'), isFalse);
    });

    test('the MIME type decides the kind, and video is its own kind', () async {
      for (final (mime, type) in [
        ('image/png', 'photo'),
        ('image/jpeg', 'photo'),
        ('audio/aac', 'voice'),
        ('application/pdf', 'file'),
        ('text/plain', 'file'),
        // Was 'file' until videos got their own block. Filing a clip as a grey
        // document chip gave no hint there was anything to watch.
        ('video/mp4', 'video'),
        ('video/quicktime', 'video'),
      ]) {
        expect(AttachmentImporter.typeForMime(mime), type);
      }
    });

    test('the filename is the fallback when the picker will not say', () {
      // Some pickers hand back application/octet-stream for a video they could
      // not identify. Guessing from an extension is not something to be proud
      // of; being wrong about what a file *is* is worse.
      const vague = 'application/octet-stream';
      expect(AttachmentImporter.typeForMime(vague, 'holiday.MP4'), 'video');
      expect(AttachmentImporter.typeForMime(vague, 'note.m4a'), 'voice');
      expect(AttachmentImporter.typeForMime(vague, 'scan.HEIC'), 'photo');
      expect(AttachmentImporter.typeForMime(vague, 'accounts.xlsx'), 'file');
      // No name, no clue, no guess.
      expect(AttachmentImporter.typeForMime(vague), 'file');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('when it goes wrong', () {
    test('a locked vault still scrubs the plaintext', () async {
      // The failure that would actually happen: the idle timeout fires, or the
      // phone is backgrounded, while the picker is open. The import throws —
      // and the photograph must not be left sitting in the cache because of it.
      final captured = stage('private.jpg', 'image/jpeg');
      final path = captured.file.path;
      await vault.lock();

      await expectLater(
        importer.importCaptured(captured: captured, dayKey: '2026-08-19'),
        throwsA(anything),
      );

      expect(File(path).existsSync(), isFalse,
          reason: 'the finally in importCaptured is the only thing standing '
              'between a failed import and a plaintext photo left on disk');
      expect(await filesContainingMarker(), isEmpty);
    });

    test('a file that vanishes mid-import scrubs and leaves no orphan',
        () async {
      final captured = stage('gone.jpg', 'image/jpeg');
      captured.file.deleteSync();

      await expectLater(
        importer.importCaptured(captured: captured, dayKey: '2026-08-19'),
        throwsA(anything),
      );

      // Nothing half-written. An encrypted blob with no row pointing at it is
      // not a leak — it is unreadable — but it is space nothing will ever
      // reclaim, and a vault that grows on every failure is a bug.
      final attachments = Directory('${vault.root.path}/attachments');
      final blobs = attachments.existsSync()
          ? attachments.listSync().where((f) => f.path.endsWith('.enc'))
          : const <FileSystemEntity>[];
      expect(blobs, isEmpty);
    });

    test('scrubbing something already gone is not an error', () async {
      // The double-scrub. importCaptured always scrubs in its `finally`, and a
      // caller that scrubs again on its own error path must not blow up.
      final captured = stage('twice.jpg', 'image/jpeg');
      await captured.scrub();
      await captured.scrub();
      expect(captured.file.existsSync(), isFalse);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('deleting', () {
    test('purging an entry takes its encrypted blob with it', () async {
      // Without this, deleting a photo forever removes the row and leaves the
      // file on disk — unreadable by anyone, unremovable by anything, growing
      // for the life of the app.
      final id = await importer.importCaptured(
        captured: stage('holiday.jpg', 'image/jpeg'),
        dayKey: '2026-08-19',
      );
      final attachments = Directory('${vault.root.path}/attachments');
      expect(attachments.listSync(), hasLength(1));

      await repo.purge(id);

      expect(attachments.listSync(), isEmpty);
      expect(await repo.entryById(id), isNull);
    });

    test('a discarded capture leaves nothing behind at all', () async {
      final id = await importer.importCaptured(
        captured: stage('oops.jpg', 'image/jpeg'),
        dayKey: '2026-08-19',
      );

      await importer.discardEntry(id);

      expect(await repo.entryById(id), isNull);
      expect(Directory('${vault.root.path}/attachments').listSync(), isEmpty);
      // Straight out, not into the trash: nothing here was ever finished.
      expect(await repo.watchTrash().first, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('a recording, which never exists as a file', () {
    test('a stream is encrypted straight in and its length recorded', () async {
      // The voice path. There is no temp file to scrub because there was never
      // a file — the bytes go from the pipe into libsodium. That is what
      // TECH-STACK.md means by streaming-encrypted recording being a hard
      // requirement, and this is the shape of it in one test.
      final chunks = [
        Uint8List.fromList(List.filled(4096, 0x41)),
        Uint8List.fromList(List.filled(4096, 0x42)),
        Uint8List.fromList(List.filled(1000, 0x43)),
      ];

      final id = await importer.importStream(
        source: Stream.fromIterable(chunks),
        dayKey: '2026-08-19',
        type: 'voice',
        originalName: 'Voice note.aac',
        mimeType: 'audio/aac',
      );
      await importer.setDuration(id, 42000);

      final entry = await repo.entryById(id);
      expect(entry!.type, 'voice');

      final attachment = await importer.attachmentFor(entry);
      expect(attachment!.byteSize, 4096 + 4096 + 1000);
      expect(attachment.durationMs, 42000);

      final back = await importer.bytesOf(attachment);
      expect(back.length, 4096 + 4096 + 1000);
      expect(back.first, 0x41);
      expect(back.last, 0x43);
    });
  });
}
