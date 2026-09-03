import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/storage/orphan_sweep.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// Files with no row, and rows with no file. **`PLAN.md` §7.2.**
///
/// Storing an attachment is two writes that cannot be one — a blob to the
/// filesystem, a row to the encrypted database — with no transaction spanning
/// both, because SQLite can roll back its own table and cannot roll back a
/// file. A phone killed for memory mid-import lands between them.
///
/// The two halves are simulated here by doing exactly what a crash does: taking
/// one of them away.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;
  late EntryRepository repo;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_sweep');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    importer = AttachmentImporter(vault);
    repo = EntryRepository(vault.database, attachments: vault.attachments);
  });

  tearDown(() async {
    await vault.lock();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Puts one recording in, the ordinary way, and hands back its ids.
  Future<({String entryId, String attachmentId})> addOne() async {
    final entryId = await importer.importStream(
      source: Stream.value(List<int>.filled(2048, 7)),
      dayKey: '2026-08-27',
      type: 'voice',
      originalName: 'Voice 2026-08-27 10-00-00.aac',
      mimeType: 'audio/aac',
    );
    final entry = await repo.entryById(entryId);
    return (entryId: entryId, attachmentId: entry!.attachmentId!);
  }

  test('a healthy vault is left completely alone', () async {
    await addOne();
    final before = vault.attachments.listIds().toSet();

    final result = await OrphanSweep.run(vault);

    expect(result.isEmpty, isTrue);
    expect(vault.attachments.listIds().toSet(), before,
        reason: 'the sweep must never touch a file that has a row');
    final rows = await vault.database.select(vault.database.attachments).get();
    expect(rows, hasLength(1));
  });

  test('a blob with no row is removed', () async {
    // What a crash between the blob write and the row insert leaves: a file
    // nothing can ever read, because its key was in the row that never landed.
    // Not a leak — it is encrypted under a key that no longer exists anywhere —
    // but it is space, and on a video it is a great deal of space.
    final stray = await vault.attachments.write(
      Stream.value(List<int>.filled(4096, 3)),
    );
    expect(vault.attachments.fileFor(stray.id).existsSync(), isTrue);

    final result = await OrphanSweep.run(vault);

    expect(result.strayFiles, 1);
    expect(result.strayRows, 0);
    expect(vault.attachments.fileFor(stray.id).existsSync(), isFalse);
  });

  test('a row with no blob loses the row and keeps the entry', () async {
    // The other half, and the one the user can actually see: the day view draws
    // a block, the block tries to decrypt a file that is not there, and there is
    // a broken thing in somebody's journal with no way to make it go away.
    final ids = await addOne();
    // A crash, or a file the system reclaimed.
    vault.attachments.fileFor(ids.attachmentId).deleteSync();

    final result = await OrphanSweep.run(vault);

    expect(result.strayRows, 1);
    expect(result.strayFiles, 0);

    final rows = await vault.database.select(vault.database.attachments).get();
    expect(rows, isEmpty, reason: 'the row described a file that is not there');

    // ── The property worth protecting ────────────────────────────────────
    //
    // The entry survives, with its day and anything written on it. Deleting it
    // to tidy up after a crash would be the app destroying the only part that
    // did survive.
    final entry = await repo.entryById(ids.entryId);
    expect(entry, isNotNull);
    expect(entry!.attachmentId, isNull);
    expect(entry.dayKey, '2026-08-27');
  });

  test('running it twice finds nothing the second time', () async {
    final stray = await vault.attachments.write(Stream.value([1, 2, 3, 4]));
    expect((await OrphanSweep.run(vault)).strayFiles, 1);
    expect((await OrphanSweep.run(vault)).isEmpty, isTrue);
    expect(vault.attachments.fileFor(stray.id).existsSync(), isFalse);
  });

  test('it does nothing at all on a locked vault', () async {
    // Called from the unlock path, so this should never happen — but a sweep
    // that touched a locked vault would be reaching for a database with no key.
    await vault.lock();
    final result = await OrphanSweep.run(vault);
    expect(result.isEmpty, isTrue);
  });
}
