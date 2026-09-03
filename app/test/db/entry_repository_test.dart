import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:sodium/sodium_sumo.dart';

/// The rules about entries that every screen depends on being the same.
///
/// The value of putting these in one class was that the rules stop being
/// re-derived per screen — but a rule written once is only better than a rule
/// written four times if it is also *right*, which is what this file is for.
/// The two that would cause real harm if wrong are the delete being reversible
/// and the revision coalescing, so both get more than one test.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late VaultDatabase db;
  late EntryRepository repo;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_repo');
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    db = await openVaultDatabase(path: '${tmp.path}/vault.db', key: key);
    repo = EntryRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  var counter = 0;
  String nextId() => 'id-${counter++}';

  Future<String> add(String dayKey, String body) async {
    final id = nextId();
    await repo.createText(id: id, dayKey: dayKey, body: body);
    return id;
  }

  group('day keys', () {
    test('are zero-padded, so they sort as dates', () {
      // A key that disagrees by one character puts an entry on a day nobody
      // can find, and the calendar's range query is a string comparison.
      expect(EntryRepository.dayKeyFor(DateTime(2026, 8, 3)), '2026-08-03');
      expect(EntryRepository.dayKeyFor(DateTime(2026, 12, 25)), '2026-12-25');
      expect(EntryRepository.dayKeyFor(DateTime(999, 1, 1)), '0999-01-01');
    });
  });

  group('reading a day', () {
    test('oldest first, because a day is a record and not a feed', () async {
      await add('2026-08-18', 'first');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await add('2026-08-18', 'second');

      final entries = await repo.watchDay('2026-08-18').first;
      expect(entries.map((e) => e.body), ['first', 'second']);
    });

    test('other days are not in it', () async {
      await add('2026-08-18', 'today');
      await add('2026-08-17', 'yesterday');
      final entries = await repo.watchDay('2026-08-18').first;
      expect(entries.single.body, 'today');
    });

    test('deleted entries are invisible', () async {
      final id = await add('2026-08-18', 'gone');
      await add('2026-08-18', 'still here');
      await repo.softDelete(id);

      final entries = await repo.watchDay('2026-08-18').first;
      expect(entries.single.body, 'still here');
    });
  });

  group('delete is reversible', () {
    test('a soft delete can be undone and the entry comes back whole',
        () async {
      final id = await add('2026-08-18', 'a mis-tap');
      await repo.softDelete(id);
      expect(await repo.watchDay('2026-08-18').first, isEmpty);

      await repo.restore(id);
      final back = await repo.watchDay('2026-08-18').first;
      expect(back.single.body, 'a mis-tap');
      expect(back.single.deletedAt, isNull);
    });

    test('deleted entries wait in the trash', () async {
      final id = await add('2026-08-18', 'deleted');
      await repo.softDelete(id);
      final trash = await repo.watchTrash().first;
      expect(trash.single.id, id);
    });

    test('the trash empties itself only after 30 days', () async {
      final recent = await add('2026-08-18', 'deleted today');
      await repo.softDelete(recent);

      // Nothing yet — a thirty-day hold has to actually hold.
      expect(await repo.purgeExpired(), 0);
      expect(await repo.watchTrash().first, hasLength(1));

      // A zero-length hold makes everything overdue, which is the same code
      // path a real thirty-day-old entry takes without waiting a month.
      expect(await repo.purgeExpired(hold: Duration.zero), 1);
      expect(await repo.watchTrash().first, isEmpty);
    });

    test('a purge takes the revisions with it', () async {
      final id = await add('2026-08-18', 'version one');
      await repo.updateBody(id, 'version two');
      expect(await repo.revisionsFor(id), hasLength(1));

      await repo.purge(id);
      expect(await repo.revisionsFor(id), isEmpty);
      expect(await repo.entryById(id), isNull);
    });

    test('a purged entry leaves the search index too', () async {
      // Finding a deleted note in search months later would be a genuinely
      // alarming way to discover that "delete for good" did not.
      final id = await add('2026-08-18', 'unmistakeable phrase');
      await repo.purge(id);
      final hits = await db.customSelect(
        "SELECT COUNT(*) AS n FROM entry_search WHERE entry_search MATCH 'unmistakeable'",
      ).getSingle();
      expect(hits.read<int>('n'), 0);
    });
  });

  group('revisions', () {
    test('an edit keeps what was there before', () async {
      final id = await add('2026-08-18', 'the original');
      await repo.updateBody(id, 'the replacement');

      final revisions = await repo.revisionsFor(id);
      expect(revisions.single.body, 'the original');
      expect((await repo.entryById(id))!.body, 'the replacement');
    });

    test('one editing session leaves one revision, not four hundred',
        () async {
      // Autosave fires every 400 ms. Without the coalesce window, typing a
      // paragraph would push the twenty versions that matter out of the window
      // inside a minute, and the feature would exist without ever helping.
      final id = await add('2026-08-18', 'start');
      for (var i = 0; i < 25; i++) {
        await repo.updateBody(id, 'start and then some more, take $i');
      }
      expect(await repo.revisionsFor(id), hasLength(1));
      expect((await repo.revisionsFor(id)).single.body, 'start');
    });

    test('writing the same text again changes nothing', () async {
      final id = await add('2026-08-18', 'unchanged');
      final before = (await repo.entryById(id))!.updatedAt;
      await repo.updateBody(id, 'unchanged');
      expect(await repo.revisionsFor(id), isEmpty);
      expect((await repo.entryById(id))!.updatedAt, before);
    });

    test('an entry that no longer exists is a no-op, not a crash', () async {
      await repo.updateBody('never-existed', 'text');
      expect(await repo.entryById('never-existed'), isNull);
    });
  });

  group('counts for the calendar', () {
    test('only days inside the range, and only entries that exist', () async {
      await add('2026-08-01', 'a');
      await add('2026-08-15', 'b');
      await add('2026-08-15', 'c');
      final deleted = await add('2026-08-15', 'd');
      await add('2026-09-01', 'outside');
      await repo.softDelete(deleted);

      final counts = await repo.countsBetween('2026-08-01', '2026-08-31');
      expect(counts['2026-08-01'], 1);
      expect(counts['2026-08-15'], 2);
      expect(counts.containsKey('2026-09-01'), isFalse);
    });

    test('a day with nothing on it is absent rather than zero', () async {
      // The calendar relies on this: a missing key means "nothing happened",
      // which it draws as absence. A zero would be drawn as a small amount.
      await add('2026-08-01', 'a');
      final counts = await repo.countsBetween('2026-08-01', '2026-08-31');
      expect(counts.containsKey('2026-08-02'), isFalse);
    });

    test('the earliest day bounds the year picker', () async {
      expect(await repo.earliestDayKey(), isNull);
      await add('2023-04-04', 'old');
      await add('2026-08-18', 'new');
      expect(await repo.earliestDayKey(), '2023-04-04');
    });
  });

  group('stats', () {
    test('count entries and the distinct days they sit on', () async {
      await add('2026-08-18', 'a');
      await add('2026-08-18', 'b');
      await add('2026-08-17', 'c');
      final s = await repo.stats();
      expect(s.entries, 3);
      expect(s.days, 2);
    });

    test('deleted entries are not counted', () async {
      final id = await add('2026-08-18', 'a');
      await repo.softDelete(id);
      expect((await repo.stats()).entries, 0);
    });
  });

  test('an abandoned draft is removed outright, not sent to the trash',
      () async {
    // Clearing the composer has to mean "I did not want this". Something that
    // was never finished should not sit in the trash for a month either.
    final id = await add('2026-08-18', 'half a thought');
    await repo.discardDraft(id);
    expect(await repo.entryById(id), isNull);
    expect(await repo.watchTrash().first, isEmpty);
  });
}
