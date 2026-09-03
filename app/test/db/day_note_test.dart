import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/day_note_repository.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/db/search.dart';
import 'package:sodium/sodium_sumo.dart';

/// The one line that names a day. **`PLAN.md` §7.0-E, first item.**
///
/// ── WHAT THIS FILE IS DEFENDING ───────────────────────────────────────────
///
/// Three things, and only one of them is "the feature works":
///
///   1. **Days are still never rows.** `DATA-MODEL.md` says a day exists
///      because something is on it. A `day_notes` row left behind after its
///      line is deleted would be a day that exists because the user once
///      opened it, and every count of "how many days does this journal cover"
///      would slowly drift.
///   2. **It is one line.** Not a second composer. The cap and the newline
///      flattening are the whole difference between a title and a place
///      somebody's actual writing could end up — writing that the entry
///      editor could not then revise, the folder picker could not file, and
///      the export would print as a blockquote.
///   3. **It is findable.** A line nobody can search for is a line that only
///      helps on the day it is written, which is the one day it is not needed.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late VaultDatabase db;
  late DayNoteRepository notes;
  late EntryRepository repo;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_daynote');
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    db = await openVaultDatabase(path: '${tmp.path}/vault.db', key: key);
    notes = DayNoteRepository(db);
    repo = EntryRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<int> rowCount() async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS n FROM day_notes')
        .getSingle();
    return row.read<int>('n');
  }

  group('writing a day down', () {
    test('a day starts with no line', () async {
      expect(await notes.read('2026-08-28'), isNull);
      expect(await rowCount(), 0);
    });

    test('a line is written, read back, and changed', () async {
      await notes.setBody('2026-08-28', 'The day the results came');
      expect(await notes.read('2026-08-28'), 'The day the results came');

      await notes.setBody('2026-08-28', 'Results day');
      expect(await notes.read('2026-08-28'), 'Results day');
      // Changed, not appended: one row per day, forever.
      expect(await rowCount(), 1);
    });

    test('two days keep their own lines', () async {
      await notes.setBody('2026-08-27', 'Rain all afternoon');
      await notes.setBody('2026-08-28', 'Results day');
      expect(await notes.read('2026-08-27'), 'Rain all afternoon');
      expect(await notes.read('2026-08-28'), 'Results day');
    });

    test('the live stream sees a write', () async {
      final seen = notes.watch('2026-08-28');
      await notes.setBody('2026-08-28', 'Results day');
      expect(await seen.first, 'Results day');
    });
  });

  group('a day is still never a row', () {
    test('clearing the line removes the row entirely', () async {
      await notes.setBody('2026-08-28', 'Results day');
      expect(await rowCount(), 1);

      await notes.setBody('2026-08-28', '');
      expect(await rowCount(), 0,
          reason: 'an emptied day note must leave no row behind — '
              'DATA-MODEL.md: days are never rows');
      expect(await notes.read('2026-08-28'), isNull);
    });

    test('null clears it too', () async {
      await notes.setBody('2026-08-28', 'Results day');
      await notes.setBody('2026-08-28', null);
      expect(await rowCount(), 0);
    });

    test('whitespace is not a line', () async {
      await notes.setBody('2026-08-28', '   \n  ');
      expect(await rowCount(), 0);
      expect(await notes.read('2026-08-28'), isNull);
    });

    test('clearing a day that never had a line does nothing', () async {
      await notes.setBody('2026-08-28', '');
      expect(await rowCount(), 0);
    });
  });

  group('it is one line, and stays one line', () {
    test('newlines become spaces', () async {
      await notes.setBody('2026-08-28', 'Results\nday\r\nat last');
      expect(await notes.read('2026-08-28'), 'Results day at last');
    });

    test('runs of whitespace collapse', () async {
      await notes.setBody('2026-08-28', 'Results     day');
      expect(await notes.read('2026-08-28'), 'Results day');
    });

    test('a pasted essay is cut rather than stored', () async {
      final essay = List.filled(50, 'sentence').join(' ');
      await notes.setBody('2026-08-28', essay);
      final stored = await notes.read('2026-08-28');
      expect(stored!.length, lessThanOrEqualTo(DayNoteRepository.maxLength));
    });

    test('a line exactly at the cap survives whole', () async {
      final exact = 'x' * DayNoteRepository.maxLength;
      await notes.setBody('2026-08-28', exact);
      expect(await notes.read('2026-08-28'), exact);
    });

    // The field is a title, not a diary. If this ever passes with a much
    // larger number, somebody has turned it into a second composer and the
    // reasoning in `day_note_repository.dart` needs re-reading first.
    test('the cap is short enough to be a title', () {
      expect(DayNoteRepository.maxLength, lessThanOrEqualTo(200));
    });
  });

  group('every one of them, at once, for the export', () {
    test('all() returns only days that have a line', () async {
      await notes.setBody('2026-08-27', 'Rain');
      await notes.setBody('2026-08-28', 'Results');
      await notes.setBody('2026-08-29', '');

      final all = await notes.all();
      expect(all, {'2026-08-27': 'Rain', '2026-08-28': 'Results'});
    });
  });

  group('finding a day by what it was called', () {
    test('the line is searchable', () async {
      await notes.setBody('2026-08-28', 'The day the results came');
      final hits = await repo.searchEverything('results');
      expect(hits.namedDays, hasLength(1));
      expect(hits.namedDays.first.date, DateTime(2026, 8, 28));
    });

    test('the matched part is fenced so the screen can bold it', () async {
      await notes.setBody('2026-08-28', 'The day the results came');
      final hits = await repo.searchEverything('results');
      expect(hits.namedDays.first.snippet, contains(markStart));
      expect(hits.namedDays.first.snippet, contains(markEnd));
    });

    test('a percent sign is a character, not a wildcard', () async {
      await notes.setBody('2026-08-27', 'Scored 100% at last');
      await notes.setBody('2026-08-28', 'Nothing much');
      final hits = await repo.searchEverything('100%');
      expect(hits.namedDays, hasLength(1));
      expect(hits.namedDays.first.date, DateTime(2026, 8, 27));
    });

    test('Hindi is searchable, because the line is stored not tokenised',
        () async {
      await notes.setBody('2026-08-28', 'कल का दिन');
      final hits = await repo.searchEverything('दिन');
      expect(hits.namedDays, hasLength(1));
    });

    // Every SearchKind names a kind of *entry*. A day note is not one, so
    // narrowing to "Photos" and still being handed a day would read as the
    // filter being broken.
    test('narrowing to a kind of entry hides day lines', () async {
      await notes.setBody('2026-08-28', 'The day the results came');
      final hits = await repo.searchEverything(
        'results',
        kinds: {SearchKind.photos},
      );
      expect(hits.namedDays, isEmpty);
    });

    test('an empty search finds nothing rather than everything', () async {
      await notes.setBody('2026-08-28', 'Results');
      expect(await notes.search('   '), isEmpty);
    });
  });

  group('the header knows whether to offer the line', () {
    test('an empty day reports nothing on it', () async {
      expect(await repo.watchHasEntries('2026-08-28').first, isFalse);
    });

    test('a day with an entry reports something on it', () async {
      await repo.createTextOn(
          id: 'e1', dayKey: '2026-08-28', body: 'something');
      expect(await repo.watchHasEntries('2026-08-28').first, isTrue);
    });

    test('a trashed entry does not count', () async {
      await repo.createTextOn(
          id: 'e1', dayKey: '2026-08-28', body: 'something');
      await repo.softDelete('e1');
      expect(await repo.watchHasEntries('2026-08-28').first, isFalse);
    });
  });
}
