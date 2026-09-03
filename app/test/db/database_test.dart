import 'dart:convert';
import 'dart:io';


import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:sodium/sodium_sumo.dart';

/// The encrypted database, per ADR-006 and `03-product/DATA-MODEL.md`.
///
/// The test that matters most here is the plaintext scan: after writing a note,
/// the note's text must not appear anywhere in the bytes on disk. That is the
/// second half of the Phase 1 exit test, and it is the one that would fail
/// silently if the SQLCipher key were ever not applied.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late Uint8List dbKey;
  late String dbPath;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_db');
    dbPath = '${tmp.path}/vault.db';
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    dbKey = sub.extractBytes();
    dek.dispose();
    sub.dispose();
  });

  tearDown(() {
    // Only ever the temp directory this test created.
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<VaultDatabase> open() async =>
      openVaultDatabase(path: dbPath, key: dbKey);

  Entry makeEntry(String id, String body, {String dayKey = '2026-03-04'}) {
    final now = DateTime.now();
    return Entry(
      id: id,
      createdAt: now.millisecondsSinceEpoch,
      createdOffsetMinutes: now.timeZoneOffset.inMinutes,
      updatedAt: now.millisecondsSinceEpoch,
      type: 'text',
      body: body,
      dayKey: dayKey,
      isPinned: false,
    );
  }

  group('schema', () {
    test('creates, and every table is present', () async {
      final db = await open();
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final names = tables.map((r) => r.read<String>('name')).toSet();
      for (final expected in [
        'entries',
        'folders',
        'entry_folders',
        'attachments',
        'revisions',
        'day_notes',
        'entry_search',
      ]) {
        expect(names, contains(expected));
      }
      await db.close();
    });

    test('WAL mode is on', () async {
      // SECURITY-ARCHITECTURE.md §5. A power loss mid-write must not corrupt
      // the vault, and §7's autosave depends on it.
      final db = await open();
      final mode =
          await db.customSelect('PRAGMA journal_mode').getSingle();
      expect(mode.data.values.first.toString().toLowerCase(), 'wal');
      await db.close();
    });

    test('foreign keys are enforced', () async {
      // Off by default in SQLite. Without them, deleting a folder silently
      // leaves orphaned join rows pointing nowhere.
      final db = await open();
      final on = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(on.data.values.first, 1);
      await expectLater(
        db.into(db.entryFolders).insert(
              EntryFoldersCompanion.insert(
                entryId: 'no-such-entry',
                folderId: 'no-such-folder',
                addedAt: 0,
              ),
            ),
        throwsA(anything),
      );
      await db.close();
    });

    test('schemaVersion is 5', () async {
      // Pinned in two places on purpose — see the long note in
      // migration_test.dart. v5 added attachments.last_page, so a document
      // opens where it was left (ROUND EIGHT, ISSUE 1B); v4 added
      // attachments.original_size for ISSUE 12.
      final db = await open();
      expect(db.schemaVersion, 5);
      await db.close();
    });
  });

  group('writing and reading back', () {
    test('a note survives a close and reopen', () async {
      // This is the Phase 1 exit test in miniature: write, shut everything
      // down, open again with the key, read it back.
      var db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'Slept badly again.'));
      await db.close();

      db = await open();
      final rows = await db.select(db.entries).get();
      expect(rows, hasLength(1));
      expect(rows.single.body, 'Slept badly again.');
      await db.close();
    });

    test('day_key groups entries, and days are never rows', () async {
      // DATA-MODEL.md: a Day is a query, not a table. Nothing creates them.
      final db = await open();
      await db.into(db.entries).insert(makeEntry('a', 'morning', dayKey: '2026-03-04'));
      await db.into(db.entries).insert(makeEntry('b', 'evening', dayKey: '2026-03-04'));
      await db.into(db.entries).insert(makeEntry('c', 'next day', dayKey: '2026-03-05'));

      final march4 = await (db.select(db.entries)
            ..where((t) => t.dayKey.equals('2026-03-04')))
          .get();
      expect(march4, hasLength(2));

      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE name='days'")
          .get();
      expect(tables, isEmpty, reason: 'there must be no days table');
      await db.close();
    });

    test('one entry can sit in many folders without duplication', () async {
      // The join is what makes "one pile, two lenses" work. If filing copied
      // the entry, the day view and the folder view would drift apart.
      final db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'Called Ma.'));
      for (final f in ['people', 'kavya']) {
        await db.into(db.folders).insert(
              FoldersCompanion.insert(id: f, name: f, createdAt: 0),
            );
        await db.into(db.entryFolders).insert(
              EntryFoldersCompanion.insert(entryId: 'e1', folderId: f, addedAt: 0),
            );
      }
      expect(await db.select(db.entries).get(), hasLength(1));
      expect(await db.select(db.entryFolders).get(), hasLength(2));
      await db.close();
    });

    test('full-text search finds an entry', () async {
      // Phase 3 gives search a UI, but the index has to work from day one —
      // retrofitting FTS5 later means reindexing every entry on the user's
      // phone, on battery.
      final db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'slept badly again'));
      await db.into(db.entries).insert(makeEntry('e2', 'called Ma today'));

      final hits = await db
          .customSelect(
            "SELECT rowid FROM entry_search WHERE entry_search MATCH 'badly'",
          )
          .get();
      expect(hits, hasLength(1));
      await db.close();
    });

    test('the search index follows edits and deletes', () async {
      final db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'slept badly again'));

      await (db.update(db.entries)..where((t) => t.id.equals('e1')))
          .write(const EntriesCompanion(body: Value('slept well for once')));
      var stale = await db
          .customSelect("SELECT rowid FROM entry_search WHERE entry_search MATCH 'badly'")
          .get();
      expect(stale, isEmpty, reason: 'the index kept a word that was edited out');

      final fresh = await db
          .customSelect("SELECT rowid FROM entry_search WHERE entry_search MATCH 'well'")
          .get();
      expect(fresh, hasLength(1));

      await (db.delete(db.entries)..where((t) => t.id.equals('e1'))).go();
      stale = await db
          .customSelect("SELECT rowid FROM entry_search WHERE entry_search MATCH 'well'")
          .get();
      expect(stale, isEmpty, reason: 'deleted entry still searchable');
      await db.close();
    });
  });

  group('the file on disk', () {
    test('contains no plaintext after writing a note', () async {
      // Half of the Phase 1 exit test. If SQLCipher were ever not keyed, this
      // is the test that catches it — everything else would still pass.
      const secret = 'CANARY_the_thing_I_would_never_say_aloud';
      final db = await open();
      await db.into(db.entries).insert(makeEntry('e1', secret));
      await db.close();

      // Every file the database may have produced, not just the main one. The
      // WAL and shared-memory files are the classic leak: the note is written
      // to the WAL first, and a naive check of only vault.db would miss it.
      final produced = tmp
          .listSync()
          .whereType<File>()
          .toList();
      expect(produced, isNotEmpty);

      for (final f in produced) {
        final bytes = f.readAsBytesSync();
        expect(
          _contains(bytes, utf8.encode(secret)),
          isFalse,
          reason: 'the note text was found in ${f.path}',
        );
        expect(
          _contains(bytes, utf8.encode('CANARY')),
          isFalse,
          reason: 'part of the note text was found in ${f.path}',
        );
      }
    });

    test('does not carry the plain SQLite header', () async {
      final db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'x'));
      await db.close();
      final header = File(dbPath).readAsBytesSync().sublist(0, 16);
      expect(_contains(header, utf8.encode('SQLite format 3')), isFalse);
    });

    test('a wrong key cannot open it', () async {
      var db = await open();
      await db.into(db.entries).insert(makeEntry('e1', 'private'));
      await db.close();

      final wrongDek = crypto.generateDek();
      final wrongSub = crypto.deriveSubkey(wrongDek, KeyPurpose.database);
      final wrongKey = wrongSub.extractBytes();
      wrongDek.dispose();
      wrongSub.dispose();

      await expectLater(
        openVaultDatabase(path: dbPath, key: wrongKey),
        throwsA(anything),
        reason: 'a wrong key must fail at open, not silently later',
      );
    });

    test('a key of the wrong length is refused before touching the file', () {
      expect(
        () => openVaultDatabase(path: dbPath, key: Uint8List(16)),
        throwsArgumentError,
      );
    });
  });

  group('uuid', () {
    test('is well formed and never repeats', () {
      final seen = <String>{};
      for (var i = 0; i < 2000; i++) {
        final id = uuidV4(crypto.randomBytes);
        expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
              .hasMatch(id),
          isTrue,
          reason: id,
        );
        seen.add(id);
      }
      expect(seen, hasLength(2000));
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
