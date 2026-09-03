import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND FIVE, ISSUE C and ISSUE H.** The rule, as assertions.
///
/// ══ WHY THIS FILE EXISTS ═════════════════════════════════════════════════
///
/// *"I need you to also find a way that these issues never occurs again."*
///
/// Of everything in the round-five document, one item was a genuine
/// data-loss bug rather than a nuisance: `AttachmentImporter.removeAttachment`
/// destroyed the blob and unlinked the row on the spot, and on an entry with no
/// words it hard-deleted the entry as well. He found both halves from the
/// outside —
///
///     *Delete → ends up in Trash / sometimes not*
///     *Remove → vanishes in thin air, never ends up in trash*
///
/// — and the menu's gentlest-sounding option turned out to be its only
/// irreversible one.
///
/// **The whole suite passed before that fix and after it**, which is the fact
/// worth writing down. Four hundred and ninety-five tests and not one of them
/// asked whether a deleted photograph could be recovered. The defect was not
/// that a test failed; it was that the question had never been asked.
///
/// So this file asks it, in the most general form that can be stated:
/// **nothing leaves the vault except through the trash.** That is a property of
/// the app rather than of a method, and it is written here so that the next
/// deletion path somebody adds has something to fail against.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;
  late EntryRepository repo;

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_trash');
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

  /// A photograph on a day, optionally with a caption on the same block.
  Future<String> importPhoto({String? caption}) async {
    final file = File('${tmp.path}/photo-${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(Uint8List.fromList(List.filled(2048, 7)));
    return importer.importCaptured(
      captured: CapturedFile(
        file: file,
        name: 'photo.jpg',
        mimeType: 'image/jpeg',
      ),
      dayKey: '2026-08-23',
      caption: caption,
    );
  }

  Future<List<Entry>> trash() => repo.watchTrash().first;

  group('nothing leaves except through the trash', () {
    test('a photograph with no words is recoverable after it is deleted',
        () async {
      final id = await importPhoto();

      final trashedId = await importer.removeAttachment(id);

      // ── The bug, as an assertion ──────────────────────────────────────
      //
      // This used to hard-delete the entry row and overwrite the blob. The
      // trash was empty, the photograph was gone, and there was nothing
      // anywhere to put back.
      final binned = await trash();
      expect(binned, hasLength(1),
          reason: 'a deleted photograph must be in the trash');
      expect(binned.single.attachmentId, isNotNull,
          reason: 'and must still be carrying its photograph');

      expect(trashedId, isNotNull);
      await repo.restore(trashedId!);

      final back = await repo.entryById(id);
      expect(back, isNotNull);
      expect(back!.attachmentId, isNotNull,
          reason: 'putting it back must return the photograph, not an '
              'empty row where one used to be');
      expect(await trash(), isEmpty);
    });

    test('a photograph with a caption keeps the caption and bins the picture',
        () async {
      final id = await importPhoto(caption: 'the roof, at six');

      final trashedId = await importer.removeAttachment(id);

      // The words stay on the day, on the original row.
      final kept = await repo.entryById(id);
      expect(kept, isNotNull);
      expect(kept!.body, 'the roof, at six');
      expect(kept.attachmentId, isNull,
          reason: 'the picture has gone from this block');
      expect(kept.deletedAt, isNull,
          reason: 'but the block itself has not been deleted');

      // The picture is in the trash, as its own row, on the same day.
      final binned = await trash();
      expect(binned, hasLength(1));
      expect(binned.single.id, trashedId);
      expect(binned.single.attachmentId, isNotNull);
      expect(binned.single.dayKey, kept.dayKey,
          reason: 'it must land back on the day it came from if restored');

      await repo.restore(trashedId!);
      expect(await trash(), isEmpty);
    });

    test('the blob survives until the trash is actually emptied', () async {
      // The property that makes "put back" mean anything. Round four deleted
      // the file the instant the attachment was removed, so even a row that
      // came back pointed at nothing.
      final id = await importPhoto();
      final before = await repo.entryById(id);
      final attachmentId = before!.attachmentId!;

      await importer.removeAttachment(id);

      expect(vault.attachments.fileFor(attachmentId).existsSync(), isTrue,
          reason: 'a file in the trash is still a file');

      final binned = await trash();
      await repo.purge(binned.single.id);

      expect(vault.attachments.fileFor(attachmentId).existsSync(), isFalse,
          reason: 'and emptying the trash must genuinely reclaim the space — '
              'see the missing attachment store on TrashScreen');
    });

    test('deleting the whole block reaches the trash as well', () async {
      // The other half of "Delete → ends up in Trash / sometimes not". Both
      // menu rows must behave the same way, which is the point of them now
      // sharing one word.
      final id = await importPhoto(caption: 'something');
      await repo.softDelete(id);

      final binned = await trash();
      expect(binned, hasLength(1));
      expect(binned.single.id, id);

      await repo.restore(id);
      expect(await trash(), isEmpty);
      expect((await repo.entryById(id))!.body, 'something');
    });
  });
}
