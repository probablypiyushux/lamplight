import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND EIGHT, ISSUE 1B — where you had got to.**
///
/// *"What it misses? Page numbers, it doesn't remembers what was the last page
/// when I closed that PDF."*
///
/// The page indicator is a widget and is asserted in the viewer's own tests.
/// This file is the other half — the part that has to survive the app being
/// closed — and it is worth its own file because it is the first thing in the
/// project to write a *reading habit* into the vault. The column comment on
/// `Attachments.lastPage` argues why that belongs in the encrypted database
/// rather than in `settings.json`; these tests are what make it true.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_pdf_reading');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    importer = AttachmentImporter(vault);
  });

  tearDownAll(() async {
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  var seq = 0;

  /// A document in the vault, with a real encrypted blob behind it.
  Future<Attachment> document() async {
    final id = 'doc${seq++}';
    final stored = await vault.attachments
        .writeBytes(List<int>.generate(256, (i) => i % 256));
    await vault.database.into(vault.database.attachments).insert(
          AttachmentsCompanion.insert(
            id: stored.id,
            fileKey: stored.fileKey,
            originalName: '$id.pdf',
            mimeType: 'application/pdf',
            byteSize: 256,
          ),
        );
    return (vault.database.select(vault.database.attachments)
          ..where((t) => t.id.equals(stored.id)))
        .getSingle();
  }

  test('a document nobody has opened starts at the beginning', () async {
    final doc = await document();
    // Null, not zero. They are the same place to open at and they are not the
    // same fact: null is "never read", and the viewer clamps it to zero itself.
    expect(doc.lastPage, isNull);
  });

  test('closing on a page and coming back opens there', () async {
    final doc = await document();
    await importer.rememberPage(doc.id, 211);

    final again = await importer.attachmentById(doc.id);
    expect(again!.lastPage, 211,
        reason: '"it doesn\'t remembers what was the last page when I '
            'closed that PDF"');
  });

  test('the cached row is not left believing the old page', () async {
    // `rememberPage` calls `forget`, and this is why. Attachment rows are
    // cached so that scrolling a day back into view costs nothing; a cache that
    // still held the page from two sessions ago would send the reader to the
    // wrong place every time after the first.
    final doc = await document();
    await importer.attachmentById(doc.id);
    await importer.rememberPage(doc.id, 40);
    expect((await importer.attachmentById(doc.id))!.lastPage, 40);

    await importer.rememberPage(doc.id, 41);
    expect((await importer.attachmentById(doc.id))!.lastPage, 41,
        reason: 'the second write must be visible too');
  });

  test('it survives the vault being locked and opened again', () async {
    // The actual request. Not "within a session" — closed, locked, reopened,
    // which is what happens when he puts the phone down.
    final doc = await document();
    await importer.rememberPage(doc.id, 97);

    await vault.lock();
    await vault.unlockWithPasscode('a passphrase');

    final after = AttachmentImporter(vault);
    expect((await after.attachmentById(doc.id))!.lastPage, 97);
  });

  test('each document remembers its own place', () async {
    final a = await document();
    final b = await document();
    await importer.rememberPage(a.id, 12);
    await importer.rememberPage(b.id, 340);

    expect((await importer.attachmentById(a.id))!.lastPage, 12);
    expect((await importer.attachmentById(b.id))!.lastPage, 340);
  });

  test('page zero is remembered as a real answer, not as nothing', () async {
    // Somebody who reads a page and scrolls back to the top has said something.
    // Writing 0 has to be distinguishable from never having written at all, or
    // the column could be `int` with a sentinel and this would be a bug waiting
    // for a document whose reader went home.
    final doc = await document();
    await importer.rememberPage(doc.id, 5);
    await importer.rememberPage(doc.id, 0);
    expect((await importer.attachmentById(doc.id))!.lastPage, 0);
    expect((await importer.attachmentById(doc.id))!.lastPage, isNot(isNull));
  });

  test('nothing else about the file is disturbed', () async {
    // Rule 3 of the migration rules, at the row level: remembering a page
    // changes where you are in a document and nothing else about it.
    final doc = await document();
    await importer.rememberPage(doc.id, 8);
    final after = (await importer.attachmentById(doc.id))!;

    expect(after.originalName, doc.originalName);
    expect(after.mimeType, doc.mimeType);
    expect(after.byteSize, doc.byteSize);
    expect(after.fileKey, doc.fileKey);
  });

  test('the bytes are still readable afterwards', () async {
    // The paranoid one. `fileKey` is a blob on the same row being written to,
    // and a document that opens at the right page but can no longer be
    // decrypted would be a spectacular way to fail this feature.
    final doc = await document();
    await importer.rememberPage(doc.id, 3);
    final after = (await importer.attachmentById(doc.id))!;
    final bytes = await importer.bytesOf(after);
    expect(Uint8List.fromList(bytes), hasLength(256));
    expect(bytes.first, 0);
    expect(bytes[7], 7);
  });
}
