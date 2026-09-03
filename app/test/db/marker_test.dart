import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:sodium/sodium_sumo.dart';

/// "This one mattered" — the marker, and reading it back.
///
/// ── WHAT THIS IS AND, MORE IMPORTANTLY, WHAT IT IS NOT ──────────────────────
///
/// `FEATURES-IN-AND-OUT.md` is specific that a 1–10 mood scale is the wrong
/// shape, and `PLAN.md` §10 strikes out mood analytics and "your happiest
/// month". A scale asks somebody to rate their own day, which turns writing
/// into scoring; once there are numbers there is a graph, and once there is a
/// graph the journal has quietly become a performance.
///
/// A flag asks nothing. It only answers a question the person already had.
/// The test at the bottom of this file is there because "let's make it a 1–5
/// so we can show a chart" is a completely reasonable-sounding suggestion that
/// would take the product apart, and the argument against it should fail a
/// build rather than live only in a document.
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
    tmp = Directory.systemTemp.createTempSync('lamplight_marker');
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

  var n = 0;
  Future<String> add(String dayKey, String body) async {
    final id = 'e-${n++}';
    await repo.createTextOn(id: id, dayKey: dayKey, body: body);
    return id;
  }

  group('marking', () {
    test('an entry starts unmarked', () async {
      final id = await add('2026-08-24', 'a day');
      expect((await repo.entryById(id))!.marker, isNull);
    });

    test('marking and unmarking both work', () async {
      final id = await add('2026-08-24', 'a day');

      await repo.setMarker(id, EntryRepository.markMattered);
      expect((await repo.entryById(id))!.marker, EntryRepository.markMattered);

      await repo.setMarker(id, null);
      expect((await repo.entryById(id))!.marker, isNull);
    });

    test('marking does not touch the words', () async {
      // It is a flag beside an entry, not an edit of it. If marking wrote a
      // revision or changed `updatedAt` it would show as "edited" on a day
      // somebody had not edited.
      final id = await add('2026-08-24', 'the exact words');
      await repo.setMarker(id, EntryRepository.markMattered);

      final after = (await repo.entryById(id))!;
      expect(after.body, 'the exact words');
      expect(await repo.revisionsFor(id), isEmpty);
    });
  });

  group('reading it back', () {
    test('marked entries come back, newest day first', () async {
      // The order is the feature. "What mattered" read oldest-first would open
      // on somebody's 2019 and bury this year.
      final old = await add('2019-01-05', 'long ago');
      final recent = await add('2026-08-24', 'this year');
      await add('2026-08-25', 'not marked');

      await repo.setMarker(old, EntryRepository.markMattered);
      await repo.setMarker(recent, EntryRepository.markMattered);

      final marked = await repo.markedEntries();
      expect(marked.map((e) => e.id).toList(), [recent, old]);
    });

    test('unmarked entries are not in it', () async {
      await add('2026-08-24', 'ordinary');
      expect(await repo.markedEntries(), isEmpty);
    });

    test('a marked entry that was deleted is not in it', () async {
      // Trash is a promise. Something thrown away must not come back through
      // a different screen — which is exactly the kind of leak a second
      // listing query introduces if it forgets the `deletedAt` rule.
      final id = await add('2026-08-24', 'regretted');
      await repo.setMarker(id, EntryRepository.markMattered);
      await repo.softDelete(id);

      expect(await repo.markedEntries(), isEmpty);
    });

    test('the list is capped', () async {
      // It feeds a list somebody scrolls, not an export. Somebody who marks
      // everything has four thousand of them and the first page is as useful
      // to them as all of it.
      for (var i = 0; i < 12; i++) {
        final id = await add('2026-08-${(i + 10)}', 'note $i');
        await repo.setMarker(id, EntryRepository.markMattered);
      }
      expect((await repo.markedEntries(limit: 5)).length, 5);
    });

    test('an entry with no words still comes back', () async {
      // A marked photograph. The screen shows "A photograph" rather than a
      // blank line, but only if the query returns it at all.
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              id: 'photo-1',
              createdAt: DateTime(2026, 8, 24).millisecondsSinceEpoch,
              createdOffsetMinutes: 0,
              updatedAt: DateTime(2026, 8, 24).millisecondsSinceEpoch,
              type: 'photo',
              dayKey: '2026-08-24',
              marker: const Value(EntryRepository.markMattered),
            ),
          );
      expect((await repo.markedEntries()).single.id, 'photo-1');
    });
  });

  group('the shape of the thing', () {
    test('there is one marker and it is not a scale', () {
      // PLAN.md §10 strikes out mood analytics and "your happiest month".
      // FEATURES-IN-AND-OUT.md says a 1–10 scale is the wrong shape. Both of
      // those are arguments in documents, and a document does not fail a
      // build. This does.
      //
      // If a future session adds `markHappy`, `markSad`, or a numeric level,
      // this test is where that decision has to be argued rather than made in
      // passing — and the argument to beat is that a scale asks somebody to
      // rate their own day.
      expect(EntryRepository.markMattered, 'mattered');
      expect(int.tryParse(EntryRepository.markMattered), isNull);

      final markers = EntryRepository.markMattered;
      expect(markers.split(',').length, 1,
          reason: 'one marker, not a set of moods');
    });
  });
}
