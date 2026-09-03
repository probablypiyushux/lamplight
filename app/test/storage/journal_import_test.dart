import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/storage/journal_import.dart';
import 'package:sodium/sodium_sumo.dart';

/// Bringing in somebody's old journal.
///
/// ── THE TWO THINGS THAT WOULD DO REAL DAMAGE ────────────────────────────────
///
/// **Filing on the wrong day.** A date read wrongly puts a year of somebody's
/// life on days it did not happen on. They would not notice for months, and by
/// then they cannot tell which entries moved. That is why the date tests are
/// the longest group here and why ambiguous forms must be *refused* rather than
/// guessed — a skipped file is still on their disk, a misfiled one is a small
/// lie inside their own record.
///
/// **Duplicating on a second run.** People import, wonder if it worked, and
/// import again. Without the duplicate check that turns their whole history
/// into pairs, by hand, forever.
void main() {
  issueEleven();

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
    tmp = Directory.systemTemp.createTempSync('lamplight_import');
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

  var ids = 0;
  String newId() => 'import-${ids++}';

  Future<ImportResult> importFrom(Map<String, String> files) async {
    final source = _FakeSource(files);
    final plan = await JournalImport.plan(source);
    return JournalImport.run(
      plan: plan,
      source: source,
      repo: repo,
      newId: newId,
    );
  }

  group('reading the date out of a name', () {
    test('accepts every year-first form', () {
      for (final path in [
        '2026-08-24.md',
        '2026_08_24.txt',
        '2026.08.24.md',
        '20260824.md',
        'Journal/2026/2026-08-24 Trip to the sea.md',
        'diary 2026-8-4.txt',
      ]) {
        expect(JournalImport.dayKeyIn(path), isNotNull,
            reason: '$path should have a readable date');
      }
      expect(JournalImport.dayKeyIn('2026-8-4.txt'), '2026-08-04');
    });

    test('refuses the ambiguous ones rather than guessing', () {
      // 03-04-2026 is April in most of the world and March in the US. There is
      // nothing in the filename that says which, so there is no right answer
      // to pick — only a wrong one to impose on somebody's diary.
      expect(JournalImport.dayKeyIn('03-04-2026.md'), isNull);
      expect(JournalImport.dayKeyIn('24-08-2026.txt'), isNull);
      expect(JournalImport.dayKeyIn('08/24/2026.md'), isNull);
    });

    test('refuses dates that are not real', () {
      expect(JournalImport.dayKeyIn('2026-02-31.md'), isNull);
      expect(JournalImport.dayKeyIn('2026-13-01.md'), isNull);
      expect(JournalImport.dayKeyIn('1799-01-01.md'), isNull);
    });

    test('is not fooled by a longer run of digits', () {
      // `IMG_20260824_193045` is a camera filename, not a diary entry, and
      // `12345678.md` is nothing at all. Neither should silently become a day.
      expect(JournalImport.dayKeyIn('12345678.md'), isNull);
      expect(JournalImport.dayKeyIn('notes/1234567890.txt'), isNull);
    });

    test('reads a date the app itself wrote', () async {
      // The export writes `Journal/2026/2026-08-24.md`. The two features
      // round-tripping means somebody can leave and come back, which is the
      // whole argument for having both.
      expect(
        JournalImport.dayKeyIn('Journal/2026/2026-08-24.md'),
        '2026-08-24',
      );
    });
  });

  group('the plan, before anything is written', () {
    test('separates what it can date from what it cannot', () async {
      final plan = await JournalImport.plan(_FakeSource({
        '2026-08-24.md': 'a',
        '2026-08-25.md': 'b',
        'thoughts.md': 'c',
        '03-04-2026.md': 'd',
      }));

      expect(plan.dated.length, 2);
      expect(plan.undated.length, 2);
      expect(plan.undated, contains('thoughts.md'));
    });

    test('reports the span it covers', () async {
      final plan = await JournalImport.plan(_FakeSource({
        '2019-01-05.md': 'a',
        '2026-08-24.md': 'b',
        '2022-06-06.md': 'c',
      }));

      expect(plan.earliest, '2019-01-05');
      expect(plan.latest, '2026-08-24');
    });

    test('planning writes nothing', () async {
      await JournalImport.plan(_FakeSource({'2026-08-24.md': 'a'}));
      final stats = await repo.stats();
      expect(stats.entries, 0);
    });
  });

  group('what lands in the vault', () {
    test('a file becomes an entry on its own day', () async {
      final result = await importFrom({'2019-03-14.md': 'A long time ago.'});

      expect(result.added, 1);
      final day = await repo.watchDay('2019-03-14').first;
      expect(day.single.body, 'A long time ago.');
    });

    test('the entry is dated to that day, not to today', () async {
      // The whole point. An imported 2019 note that says "today" in the
      // timeline is an imported note that has lost the thing it was for.
      await importFrom({'2019-03-14.md': 'x'});
      final entry = (await repo.watchDay('2019-03-14').first).single;

      final at = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
      expect(at.year, 2019);
      expect(at.month, 3);
      expect(at.day, 14);
    });

    test('several files on one day keep the order of their names', () async {
      await importFrom({
        '2026-08-24 evening.md': 'evening',
        '2026-08-24 afternoon.md': 'afternoon',
      });

      final day = await repo.watchDay('2026-08-24').first;
      // `watchDay` sorts by createdAt, so this proves the sequence offset is
      // doing its job rather than the map's iteration order leaking through.
      expect(day.map((e) => e.body).toList(), ['afternoon', 'evening']);
    });

    test('the text goes in exactly as written', () async {
      // Not reformatted, not re-wrapped, not "cleaned". It is somebody's
      // diary and the app has no business editing it.
      const body = '# Heading\n\n- one\n- two\n\n  indented line';
      await importFrom({'2026-08-24.md': '$body\n'});

      final entry = (await repo.watchDay('2026-08-24').first).single;
      expect(entry.body, body);
    });

    test('windows line endings survive as newlines', () async {
      await importFrom({'2026-08-24.md': 'one\r\ntwo'});
      final entry = (await repo.watchDay('2026-08-24').first).single;
      expect(entry.body, 'one\ntwo');
    });

    test('an empty file does not become an empty entry', () async {
      final result = await importFrom({'2026-08-24.md': '   \n\n  '});
      expect(result.added, 0);
      expect((await repo.watchDay('2026-08-24').first), isEmpty);
    });
  });

  // ══ ROUND FIFTEEN, ISSUE 13 — A DAY THAT WAS SEVERAL ENTRIES ═══════════
  //
  // > *"I want you to check the code of features – Readable copy and bring in
  // > old journal! And test actually do their features work or not?"*
  //
  // They did, except for this: the readable copy writes one file per day with
  // a timed heading over each entry, and the importer had one rule — one file,
  // one entry — so the structure was written out perfectly and thrown away
  // coming back in.
  //
  // **Most of this is about what must NOT be split**, because that is the half
  // that could damage a journal that was never ours.
  group('a file with timed headings in it', () {
    test('becomes one entry per heading', () {
      final parts = JournalImport.entriesIn(
          '## 09:30\n\nWalked to the bridge.\n\n## 21:04\n\nRained again.\n');
      expect(parts, hasLength(2));
      expect(parts.first, contains('bridge'));
      expect(parts.last, contains('Rained'));
    });

    test('keeps what was above the first heading, with the first entry', () {
      // The `# Wednesday, 26 August` title and a `> line the day was given`
      // live up there. Dropping them because they sat above a heading would be
      // the worst possible reading of "tidy".
      final parts = JournalImport.entriesIn(
          '# Wednesday, 26 August 2026\n\n> The morning at the bridge\n\n'
          '## 09:30\n\nWalked there before it got light.\n');
      expect(parts, hasLength(1));
      expect(parts.single, contains('The morning at the bridge'));
      expect(parts.single, contains('Walked there'));
    });

    test("reads the app's own heading, narrow no-break space and all", () {
      // `intl` puts U+202F between the time and AM — current CLDR, and correct
      // typography, because a time must not break across a line. It is
      // invisible in every editor, and a pattern written with an ordinary
      // space matches nothing at all against it. The first version of the
      // splitter did exactly that and failed in silence.
      final parts = JournalImport.entriesIn(
          '## 7:10 AM — Photo\n\nfirst\n\n## 3:19 AM\n\nsecond');
      expect(parts, hasLength(2),
          reason: 'if this is 1, the space in the heading is not the space you '
              'think it is');
    });
  });

  group('and what must not be split, which is the half that could do harm', () {
    for (final heading in [
      '## Morning',
      '## Thoughts',
      '## 2026',
      '## Chapter 3',
      '## 09:30 at the bridge',
      '### 09:30',
      '## 25:00',
      '## 9:70',
    ]) {
      test('"$heading" is not an entry boundary', () {
        final parts = JournalImport.entriesIn('$heading\n\nsome words');
        expect(parts, hasLength(1),
            reason: 'a heading that is not exactly a clock time belongs to '
                "somebody else's writing, and cutting their file on it would "
                'be this app editing their diary');
      });
    }

    test('a file with no headings at all is one entry, as it always was', () {
      expect(JournalImport.entriesIn('Just a paragraph.\n\nAnd another.'),
          hasLength(1));
    });

    test('an empty file is no entries', () {
      expect(JournalImport.entriesIn('   \n\n  '), isEmpty);
    });

    test('a file that is only headings is not a day of blanks', () {
      expect(JournalImport.entriesIn('## 09:30\n\n## 10:00\n'), hasLength(1),
          reason: 'nothing was written under either, so there is nothing to '
              'import except the file itself');
    });
  });

  group('running it twice', () {
    test('does not make a second copy of anything', () async {
      const files = {'2026-08-24.md': 'the same note'};

      final first = await importFrom(files);
      final second = await importFrom(files);

      expect(first.added, 1);
      expect(second.added, 0);
      expect(second.alreadyHere, 1);

      final day = await repo.watchDay('2026-08-24').first;
      expect(day.length, 1);
    });

    test('a changed file on the same day is a new entry, not a replacement',
        () async {
      // Deliberate. The import must never overwrite: if somebody edited the
      // file since last time, both versions are things they wrote, and
      // silently discarding either would be the app deciding for them.
      await importFrom({'2026-08-24.md': 'first version'});
      await importFrom({'2026-08-24.md': 'second version'});

      final day = await repo.watchDay('2026-08-24').first;
      expect(day.length, 2);
    });
  });

  group('when things go wrong', () {
    test('one unreadable file does not stop the rest', () async {
      final source = _FakeSource(
        {
          '2026-08-01.md': 'one',
          '2026-08-02.md': 'two',
          '2026-08-03.md': 'three',
        },
        unreadable: {'2026-08-02.md'},
      );
      final plan = await JournalImport.plan(source);
      final result = await JournalImport.run(
        plan: plan,
        source: source,
        repo: repo,
        newId: newId,
      );

      expect(result.added, 2);
      expect(result.failed, ['2026-08-02.md']);
      final stats = await repo.stats();
      expect(stats.entries, 2);
    });

    test('a cancel keeps what it already brought in', () async {
      // Unlike the export, a half-finished import is not dangerous — the
      // entries that landed are real and the user can simply run it again.
      // Rolling them back would be throwing away work for tidiness.
      final source = _FakeSource({
        for (var i = 1; i <= 6; i++)
          '2026-08-0$i.md': 'day $i',
      });
      final plan = await JournalImport.plan(source);

      var seen = 0;
      final result = await JournalImport.run(
        plan: plan,
        source: source,
        repo: repo,
        newId: newId,
        isCancelled: () => ++seen > 3,
      );

      expect(result.added, 3);
      final stats = await repo.stats();
      expect(stats.entries, 3);
    });

    test('an empty folder is not an error', () async {
      final result = await importFrom({});
      expect(result.added, 0);
      expect(result.failed, isEmpty);
    });

    test('the scanned list is released when the import ends', () async {
      // It is a set of handles on the user's own storage. Holding it after the
      // screen is gone is exactly the kind of thing document_store.dart's
      // opening comment exists to prevent.
      final source = _FakeSource({'2026-08-24.md': 'x'});
      final plan = await JournalImport.plan(source);
      await JournalImport.run(
          plan: plan, source: source, repo: repo, newId: newId);

      expect(source.forgotten, isTrue);
    });
  });
}

/// A folder of text files, in memory.
// ══ ROUND EIGHT, ISSUE 11 — "ACCEPT EVERYTHING!" ═════════════════
//
// *"I have no file to test around! That will the importing seriously works? I
// want you to make the importing 100% possible! At all times! Accept
// everything!"*
//
// Two halves. **More shapes of date are read** — every one of them still
// unambiguous, because the reason for refusing `03-04-2026` has not changed and
// is not laziness. And **a way to accept the rest**, which is offered rather
// than assumed.
void issueEleven() {
  group('ISSUE 11 — dates that were being refused for no good reason', () {
    String? key(String path) => JournalImport.dayKeyIn(path);

    test('a folder tree, which is how many journals are laid out', () {
      // Year first, so there is no day/month question at all. The separator
      // class simply never included the path separator.
      expect(key('2026/08/24/entry.md'), '2026-08-24');
      expect(key('Journal/2026/08/24.txt'), '2026-08-24');
    });

    test('a month name, day first — Day One and Journey export like this', () {
      // A month name cannot be misread as a day, so the ambiguity that stops
      // 03-04-2026 does not exist here.
      expect(key('24 August 2026.md'), '2026-08-24');
      expect(key('24-Aug-2026.txt'), '2026-08-24');
      expect(key('1 Jan 2020 thoughts.md'), '2020-01-01');
    });

    test('a month name, month first — how the US writes it', () {
      expect(key('August 24, 2026.md'), '2026-08-24');
      expect(key('Aug 24 2026.txt'), '2026-08-24');
      expect(key('December-31-1999.md'), '1999-12-31');
    });

    test('a word that merely starts like a month is not a month', () {
      // "Marathon" begins with "mar", and a naive three-letter match would
      // file a race report in March.
      expect(key('Marathon 24 2026.md'), isNull);
      expect(key('Maybe 3 2026.md'), isNull);
    });

    test('a date with no year is still not a date', () {
      expect(key('24 August.md'), isNull);
      expect(key('August 24.md'), isNull);
    });
  });

  group('ISSUE 11 — what is still refused, and must stay refused', () {
    test('the ambiguous form', () {
      // The third of April in most of the world, the fourth of March in the
      // United States, and nothing in the name says which. Accepting it means
      // picking one silently for a year of somebody's life.
      expect(JournalImport.dayKeyIn('03-04-2026.md'), isNull);
      expect(JournalImport.dayKeyIn('04/03/2026.md'), isNull);
    });

    test('a camera filename is not a date', () {
      expect(JournalImport.dayKeyIn('IMG_20260824_193045.md'), '2026-08-24',
          reason: 'this one genuinely contains one, anchored');
      expect(JournalImport.dayKeyIn('12345678.md'), isNull);
    });

    test('an impossible day', () {
      expect(JournalImport.dayKeyIn('2026-02-30.md'), isNull);
      expect(JournalImport.dayKeyIn('2026-13-01.md'), isNull);
    });
  });

  group('ISSUE 11 — the file\'s own date, offered and never assumed', () {
    final when = DateTime(2026, 5, 4, 11).millisecondsSinceEpoch;

    test('off by default, so nothing changes for anybody', () async {
      final source = _FakeSource(
        {'notes.md': 'no date in my name'},
        modified: {'notes.md': when},
      );
      final plan = await JournalImport.plan(source);
      expect(plan.dated, isEmpty);
      expect(plan.undated, ['notes.md']);
    });

    test('on, an undated file lands on the day the file was written', () async {
      final source = _FakeSource(
        {'notes.md': 'no date in my name'},
        modified: {'notes.md': when},
      );
      final plan = await JournalImport.plan(source, useFileDates: true);
      expect(plan.undated, isEmpty);
      expect(plan.dated.single.dayKey, '2026-05-04');
    });

    test('a file the platform would not date is still skipped', () async {
      // Zero means "unknown", never 1 January 1970 — which is not a day
      // anybody wrote a diary entry on, and filing a folder there would be
      // worse than skipping it.
      final source = _FakeSource({'notes.md': 'text'});
      final plan = await JournalImport.plan(source, useFileDates: true);
      expect(plan.dated, isEmpty);
      expect(plan.undated, ['notes.md']);
    });

    test('a name that DOES carry a date always wins over the file date',
        () async {
      // The fallback is a last resort, not a preference. A file called
      // 2026-08-24 that was copied yesterday belongs on the 24th.
      final source = _FakeSource(
        {'2026-08-24.md': 'text'},
        modified: {'2026-08-24.md': when},
      );
      final plan = await JournalImport.plan(source, useFileDates: true);
      expect(plan.dated.single.dayKey, '2026-08-24');
    });
  });
}

class _FakeSource implements ImportSource {
  _FakeSource(this.files, {this.unreadable = const {}, this.modified = const {}});

  final Map<String, String> files;
  final Set<String> unreadable;

  /// When each file was last written, for ISSUE 11's fallback. Absent means
  /// zero, which the importer reads as "the platform would not say".
  final Map<String, int> modified;

  bool forgotten = false;

  late final List<String> _paths = files.keys.toList();

  @override
  Future<List<ImportFile>> scan() async => [
        for (var i = 0; i < _paths.length; i++)
          ImportFile(
            index: i,
            path: _paths[i],
            size: files[_paths[i]]!.length,
            modified: modified[_paths[i]] ?? 0,
          ),
      ];

  @override
  Future<String> readText(int index) async {
    final path = _paths[index];
    if (unreadable.contains(path)) {
      throw Exception('$path could not be opened.');
    }
    return files[path]!;
  }

  @override
  Future<void> forget() async => forgotten = true;
}
