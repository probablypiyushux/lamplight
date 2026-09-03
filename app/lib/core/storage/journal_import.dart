import 'package:flutter/foundation.dart';

import '../db/entry_repository.dart';
import '../platform/document_store.dart';

/// Bringing somebody's existing journal in from a folder of text files.
///
/// ── WHY THIS MATTERS MORE THAN IT LOOKS ─────────────────────────────────────
///
/// The person who goes looking for a journal app already journals. They have
/// two, five, ten years of it in Day One, Journey, Obsidian, Google Keep, or a
/// folder of `.txt` files on a laptop. Before this existed, adopting Lamplight
/// meant leaving all of it behind — to use an app whose entire emotional
/// promise is *remembering your past*.
///
/// It also broke the features that make anyone stay. "On this day" needs old
/// days to find. The calendar needs a history to have a shape. A brand new
/// vault has neither, so the app is at its least convincing for exactly as long
/// as somebody is deciding whether to keep it.
///
/// ── WHY IT ONLY ACCEPTS DATES IT IS SURE OF ─────────────────────────────────
///
/// `03-04-2026` is the third of April in most of the world and the fourth of
/// March in the United States, and nothing in the filename says which. Guessing
/// would file a year of somebody's life on the wrong days — silently, in a way
/// they would not notice for months, and could not easily undo.
///
/// So only unambiguous forms are read: `2026-08-24`, `2026_08_24`, `2026.08.24`
/// and `20260824`, anywhere in the path. Everything else is reported as
/// **"I could not read a date"** and skipped, with the count shown before
/// anything is written. A skipped file is a file the user still has. A
/// misfiled one is a small lie inside their own record.
///
/// ── WHY IT CAN BE RUN TWICE ─────────────────────────────────────────────────
///
/// People will run it twice. They will import, wonder whether it worked, and
/// import again — and an import that duplicates everything on the second run
/// turns a good day into an afternoon of deleting things by hand. So an entry
/// whose day and text already exist is counted as *already here* rather than
/// written again.
abstract final class JournalImport {
  /// Reads the folder and works out what would happen, without writing.
  ///
  /// Separate from [run] on purpose. `ETHICAL-DESIGN.md` is against surprises,
  /// and this is the largest single write the app will ever make to somebody's
  /// vault — it deserves a screen that says "412 files, 397 I can date, 15 I
  /// cannot" **before** the button rather than a report afterwards.
  static Future<ImportPlan> plan(
    ImportSource source, {
    /// Put files whose name says nothing about when they happened on the day
    /// the file was last written. **ROUND EIGHT, ISSUE 11.**
    ///
    /// *"I want you to make the importing 100% possible! At all times! Accept
    /// everything!"*
    ///
    /// **Off by default, and offered rather than assumed.** A modification
    /// time is a real fact about a file and it is not the same fact as when
    /// something happened — copying a folder between phones rewrites every one
    /// of them to today. Doing this silently would file somebody's whole
    /// journal on the day they moved it, which is precisely the failure the
    /// day/month rule below exists to avoid.
    ///
    /// Offered, though, because "skipped" is not an answer to *"accept
    /// everything"* and because the user is the one who knows whether their
    /// folder has been copied about. The screen says exactly what the rule is
    /// and shows the count before anything is written.
    bool useFileDates = false,
  }) async {
    final files = await source.scan();
    final dated = <PlannedFile>[];
    final undated = <String>[];

    for (final f in files) {
      var dayKey = dayKeyIn(f.path);
      // ISSUE 11. Only when asked, and only when the platform actually gave a
      // time — zero means the provider would not say, and 1 January 1970 is
      // not a day anybody wrote a diary entry on.
      if (dayKey == null && useFileDates && f.modified > 0) {
        dayKey = EntryRepository.dayKeyFor(
            DateTime.fromMillisecondsSinceEpoch(f.modified));
      }
      if (dayKey == null) {
        undated.add(f.path);
      } else {
        dated.add(PlannedFile(index: f.index, path: f.path, dayKey: dayKey));
      }
    }

    // Oldest first, so a partial import leaves a contiguous history rather
    // than a scattering. If it stops halfway the user has everything up to a
    // date, which is a thing they can reason about.
    dated.sort((a, b) {
      final byDay = a.dayKey.compareTo(b.dayKey);
      return byDay != 0 ? byDay : a.path.compareTo(b.path);
    });
    return ImportPlan(dated: dated, undated: undated);
  }

  /// Writes the plan into the vault.
  ///
  /// Returns what actually happened, which is not always what was planned: a
  /// file can be unreadable, or already present.
  static Future<ImportResult> run({
    required ImportPlan plan,
    required ImportSource source,
    required EntryRepository repo,
    required String Function() newId,
    void Function(double fraction, String label)? onProgress,
    bool Function()? isCancelled,
  }) async {
    var added = 0;
    var alreadyHere = 0;
    final failed = <String>[];

    // Several files can land on one day — `2026-08-24 morning.md` and
    // `2026-08-24 evening.md`. The counter keeps them in the order they were
    // named rather than in whatever order they come back in.
    final sequenceForDay = <String, int>{};

    final total = plan.dated.length;
    for (var i = 0; i < total; i++) {
      if (isCancelled?.call() ?? false) break;
      final file = plan.dated[i];

      try {
        final raw = await source.readText(file.index);
        // ── ISSUE 13 — a day that was several entries comes back as several ─
        //
        // See `entriesIn`. A file with timed headings in it is a day with
        // entries on it, and the one-file-one-entry rule was flattening every
        // day of a Lamplight export back into a single block.
        final bodies = entriesIn(raw);
        if (bodies.isEmpty) {
          // An empty file is not an entry. Importing it would put a blank
          // block on a day that otherwise has nothing, which reads as a bug.
          alreadyHere++;
        }
        for (final body in bodies) {
          if (await _exists(repo, file.dayKey, body)) {
            alreadyHere++;
            continue;
          }
          final n = sequenceForDay[file.dayKey] ?? 0;
          sequenceForDay[file.dayKey] = n + 1;
          await repo.createTextOn(
            id: newId(),
            dayKey: file.dayKey,
            body: body,
            sequence: n,
          );
          added++;
        }
      } catch (_) {
        // One unreadable file must not end the import. The user is told how
        // many, and which, at the end — losing 400 good entries because the
        // 41st was locked would be the worst possible trade.
        failed.add(file.path);
      }

      onProgress?.call((i + 1) / total, file.path);
    }

    await source.forget();
    return ImportResult(
      added: added,
      alreadyHere: alreadyHere,
      failed: failed,
      skippedUndated: plan.undated.length,
    );
  }

  /// The entries in one file. **ROUND FIFTEEN, ISSUE 13.**
  ///
  /// > *"I want you to check the code of features – Readable copy and bring in
  /// > old journal! And test actually do their features work or not?"*
  ///
  /// They do, and one thing about them did not: a day that had held three
  /// entries came back as one block. The export writes one Markdown file per
  /// day with a timed heading over each entry, and the importer had one rule —
  /// one file, one entry — so the structure was written out perfectly and
  /// thrown away on the way back in.
  ///
  /// ── WHAT COUNTS AS A HEADING HERE, AND WHY IT IS SO NARROW ─────────────
  ///
  /// A level-2 heading whose text is **a clock time and nothing that is not
  /// part of one**. `## 22:02`, `## 10:02 pm`, and — because that is what the
  /// export writes — a time followed by an em-dash clause and a star:
  /// `## 22:02 — Photograph ★`.
  ///
  /// The obvious worry is that this carves up a diary that was never ours.
  /// It cannot. `## Morning`, `## Thoughts`, `## 2026`, `## Chapter 3` and
  /// `## 09:30 at the bridge` all fail to match, and a file with no matching
  /// heading is one entry exactly as before — which is almost every file
  /// anybody will ever import. A line that is *only* a time, in a file whose
  /// **name is a date**, means the same thing in every journalling app that
  /// writes Markdown: an entry made then. Obsidian's daily notes, Logseq's,
  /// Day One's export and ours all agree, so somebody who has been writing
  /// their days that way by hand gets the same benefit rather than a surprise.
  ///
  /// ── THE LIMIT, WHICH IS REAL AND IS DELIBERATE ────────────────────────
  ///
  /// The export writes the time **in the reader's language**, because the
  /// folder is for reading rather than for round-tripping — Japanese gets
  /// `午後10:02` and Arabic gets Eastern Arabic numerals. Those do not match
  /// here, so an export made in one of those languages comes back a day at a
  /// time rather than an entry at a time.
  ///
  /// That is the right way round. Making the heading machine-readable would
  /// mean either printing 24-hour times to readers who do not use them, or
  /// hiding a marker in the file — and the whole promise of this folder is
  /// that it is **plain**, with nothing in it that is there for the app's
  /// benefit. Losing the entry boundaries is a smaller cost than that, and
  /// nothing is lost: every word still comes back on the right day.
  /// `test/backup/round_trip_test.dart` states both halves.
  ///
  /// Anything above the first timed heading — the `# Wednesday, 26 August`
  /// title, a `> line the day was given` — travels with the first entry rather
  /// than being dropped. Losing somebody's words because they sat above a
  /// heading would be the worst possible reading of "tidy".
  @visibleForTesting
  static List<String> entriesIn(String raw) {
    final whole = _tidy(raw);
    if (whole.isEmpty) return const [];

    final marks = _timedHeading.allMatches(whole).toList();
    if (marks.isEmpty) return [whole];

    final parts = <String>[];
    // Everything above the first heading belongs to the first entry.
    final preamble = whole.substring(0, marks.first.start).trim();
    for (var i = 0; i < marks.length; i++) {
      final from = marks[i].end;
      final to = i + 1 < marks.length ? marks[i + 1].start : whole.length;
      var body = whole.substring(from, to).trim();
      if (i == 0 && preamble.isNotEmpty) {
        body = body.isEmpty ? preamble : '$preamble\n\n$body';
      }
      if (body.isNotEmpty) parts.add(body);
    }
    // A file that is nothing but headings is not a day of empty entries.
    return parts.isEmpty ? [whole] : parts;
  }

  /// `## 22:02`, `## 10:02 am`, `## 22:02 — Photograph ★`, and nothing else.
  ///
  /// Written out rather than assembled, so the one thing that matters is
  /// visible: after the time, the only things allowed are an em-dash clause
  /// and a star. That is what stops `## 09:30 at the bridge` being treated as
  /// a heading and having its own words taken off it.
  ///
  /// ── [_sp] IS NOT TIDINESS. IT IS WHY THE FIRST VERSION SILENTLY FAILED ──
  ///
  /// `intl` formats an English twelve-hour time as `7:10 AM` where that space
  /// is **U+202F, a narrow no-break space** — current CLDR, and correct
  /// typography, because a time must not be allowed to break across a line. It
  /// is invisible in every editor and in every `print`; the string looks
  /// exactly like one you would type by hand. A pattern written with `[ \t]`
  /// matches nothing at all against it, and the only symptom is that the split
  /// quietly does not happen — which is what the first version of this did,
  /// and it took printing the code units to see.
  ///
  /// `\s` would cover it and cannot be used here: it matches a newline, and
  /// every anchor in this pattern depends on `^` and `$` meaning the ends of a
  /// **line**. The escapes are read by the regexp engine rather than by Dart,
  /// which is why they survive a raw string.
  static const String _sp = r'[ \t\u00A0\u2007\u2009\u202F]';

  static final RegExp _timedHeading = RegExp(
    '^##$_sp+'
    r'(?:[01]?\d|2[0-3]):[0-5]\d'
    '(?:$_sp*'
    r'[ap]\.?m\.?)?'
    '(?:$_sp*'
    r'[—–][^\n]*)?'
    '(?:$_sp*★)?'
    '$_sp*'
    r'$',
    multiLine: true,
    caseSensitive: false,
  );

  /// Whether this exact text is already on this day.
  static Future<bool> _exists(
      EntryRepository repo, String dayKey, String body) async {
    final existing = await repo.watchDay(dayKey).first;
    for (final e in existing) {
      if (e.type == 'text' && (e.body ?? '').trim() == body) return true;
    }
    return false;
  }

  /// Trims the outside and normalises line endings, and nothing else.
  ///
  /// Deliberately not "cleaning up" the Markdown. It is the user's writing and
  /// it goes in as they wrote it; a reformatter would be this app editing
  /// somebody's diary, which it has no business doing.
  static String _tidy(String raw) =>
      raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

  /// The `YYYY-MM-DD` key a path names, or null if it does not name one.
  ///
  /// Searches the whole relative path, not just the filename, so a folder
  /// layout like `2026/2026-08-24 Trip.md` works — and so does the folder
  /// Lamplight's own readable export produces, which makes the two features
  /// round-trip.
  static String? dayKeyIn(String path) {
    for (final pattern in _patterns) {
      for (final match in pattern.allMatches(path)) {
        final y = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final d = int.parse(match.group(3)!);
        final key = _key(y, m, d);
        if (key != null) return key;
      }
    }

    // ISSUE 11. Month names, tried after the numeric forms so that a path
    // carrying both — `2026-08-24 August walk.md` — is read from the part
    // that was meant as a date.
    for (var i = 0; i < _named.length; i++) {
      final dayFirst = i == 0;
      for (final match in _named[i].allMatches(path)) {
        final word = (dayFirst ? match.group(2) : match.group(1))!;
        final month = _months[word.toLowerCase().substring(0, 3)];
        if (month == null) continue;
        // Guard against a three-letter run that happens to look like a month
        // in the middle of a longer word: "Marathon" starts with "mar".
        final full = word.toLowerCase();
        if (full.length > 3 && !_isMonthWord(full)) continue;
        final day = int.parse((dayFirst ? match.group(1) : match.group(2))!);
        final year = int.parse(match.group(3)!);
        final key = _key(year, month, day);
        if (key != null) return key;
      }
    }
    return null;
  }

  /// The key, or null when those three numbers are not a real day.
  static String? _key(int y, int m, int d) => _isRealDate(y, m, d)
      ? '${y.toString().padLeft(4, '0')}-'
          '${m.toString().padLeft(2, '0')}-'
          '${d.toString().padLeft(2, '0')}'
      : null;

  /// Whether a word is actually a month rather than merely starting like one.
  static bool _isMonthWord(String lower) => const {
        'january', 'february', 'march', 'april', 'may', 'june', 'july',
        'august', 'september', 'october', 'november', 'december',
        'sept',
      }.contains(lower);

  /// Every shape of date that cannot be misread. **Widened for ISSUE 11.**
  ///
  /// *"Accept everything!"* — and this is as far as "everything" can honestly
  /// go, which is further than it went before but not all the way.
  ///
  /// **What is still refused, and why that is not laziness.** `03-04-2026` is
  /// the third of April in most of the world and the fourth of March in the
  /// United States, and nothing in the filename says which. Accepting it means
  /// picking one, silently, for a year of somebody's life — they would not
  /// notice for months and could not easily undo it. A skipped file is a file
  /// the user still has. A misfiled one is a small lie inside their own record.
  ///
  /// **What was being refused for no good reason**, and now is not:
  ///
  ///   * `2026/08/24/entry.md` — a folder tree. Year first, so there is no
  ///     question at all, and it is how a great many journals are laid out.
  ///     The separator class simply never included the path separator.
  ///   * `24 August 2026`, `August 24, 2026`, `24-Aug-2026`, `Aug 24 2026` —
  ///     **a month name cannot be misread as a day**, so the ordering question
  ///     disappears and every one of these is safe. Day One and Journey both
  ///     export like this, which makes them the two most likely folders
  ///     somebody would point this at.
  ///
  /// Order matters: the most specific patterns are tried first, and the bare
  /// `YYYYMMDD` run is last and anchored against longer digit runs, or
  /// `IMG_20260824_193045.md` would match and `12345678.md` would become
  /// 1234-56-78 — which [_isRealDate] rejects anyway, but being rejected for
  /// the right reason is cheaper to debug.
  static final _patterns = <RegExp>[
    RegExp(r'(\d{4})[-_./](\d{1,2})[-_./](\d{1,2})'),
    RegExp(r'(?<!\d)(\d{4})(\d{2})(\d{2})(?!\d)'),
  ];

  /// Month names, in the two orders English writes them.
  ///
  /// Both are unambiguous because the month is a word. The year is required to
  /// be four digits, so "24 August" on its own is still skipped — a date with
  /// no year is not a date.
  static final _named = <RegExp>[
    // 24 August 2026 · 24-Aug-2026 · 24 Aug, 2026
    RegExp(
      r'(?<!\d)(\d{1,2})[\s\-_.,]*([A-Za-z]{3,9})[\s\-_.,]+(\d{4})(?!\d)',
    ),
    // August 24, 2026 · Aug 24 2026 · August-24-2026
    RegExp(
      r'([A-Za-z]{3,9})[\s\-_.,]+(\d{1,2})[\s\-_.,]+(\d{4})(?!\d)',
    ),
  ];

  static const _months = <String, int>{
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Rejects the 31st of February, and years nothing in this app can show.
  ///
  /// The calendar reaches 1900–2100 (`calendar_sheet.dart`). An entry outside
  /// that is an entry the user could never navigate to, so importing it would
  /// be hiding their writing rather than keeping it.
  static bool _isRealDate(int y, int m, int d) {
    if (y < 1900 || y > 2100) return false;
    if (m < 1 || m > 12 || d < 1 || d > 31) return false;
    final made = DateTime(y, m, d);
    return made.year == y && made.month == m && made.day == d;
  }
}

/// One text file found in the chosen folder.
class ImportFile {
  const ImportFile({
    required this.index,
    required this.path,
    required this.size,
    this.modified = 0,
  });

  /// Its position in the platform's list. **Not a URI** — see `Import.kt` for
  /// why Dart is never given one.
  final int index;

  /// Relative to the folder the user chose.
  final String path;

  final int size;

  /// When the file was last written, in milliseconds since the epoch, or **0
  /// when the platform would not say**. **ROUND EIGHT, ISSUE 11.**
  ///
  /// Zero rather than null so the record stays cheap, and zero means *unknown*
  /// — never 1 January 1970, which is not a day anybody wrote a diary entry
  /// on. Used only when the user has asked for undated files to be filed by
  /// their file date; see `JournalImport.plan`.
  final int modified;
}

/// A file that is going to be imported, and the day it will land on.
class PlannedFile {
  const PlannedFile({
    required this.index,
    required this.path,
    required this.dayKey,
  });

  final int index;
  final String path;
  final String dayKey;
}

/// What an import would do, shown before it does it.
class ImportPlan {
  const ImportPlan({required this.dated, required this.undated});

  final List<PlannedFile> dated;

  /// Paths with no date anybody could read. Kept as paths rather than a count
  /// so the screen can show which ones, and the user can decide whether the
  /// answer is "fine" or "wait, those are the important ones".
  final List<String> undated;

  bool get isEmpty => dated.isEmpty && undated.isEmpty;

  /// The span the import covers, for the confirmation line.
  String? get earliest => dated.isEmpty ? null : dated.first.dayKey;
  String? get latest => dated.isEmpty ? null : dated.last.dayKey;
}

/// What an import actually did.
class ImportResult {
  const ImportResult({
    required this.added,
    required this.alreadyHere,
    required this.failed,
    required this.skippedUndated,
  });

  final int added;
  final int alreadyHere;
  final List<String> failed;
  final int skippedUndated;
}

/// Where imported text comes from.
///
/// An interface for the same reason the export has one: the real
/// implementation is a method channel that cannot run in `flutter test`, and
/// the date parsing and duplicate handling are exactly the parts that need
/// testing.
abstract interface class ImportSource {
  Future<List<ImportFile>> scan();
  Future<String> readText(int index);
  Future<void> forget();
}

/// The real one, over the Storage Access Framework.
/// The same import, from files the person picked one at a time.
///
/// The scan has already happened by the time this exists — `pickTextFiles`
/// returns the rows, because the picking *is* the scanning — so [scan] simply
/// hands back what it was given. Everything after that is identical, including
/// [forget], because the platform keeps one list whichever door filled it.
///
/// It exists because Android will not hand any app the root of internal
/// storage, an SD-card root, or Downloads, and Downloads is where a journal
/// exported from another app arrives. See `DocumentStore.pickTextFiles`.
class PickedFilesImportSource implements ImportSource {
  const PickedFilesImportSource(this.files);

  final List<ImportFile> files;

  @override
  Future<List<ImportFile>> scan() async => files;

  @override
  Future<String> readText(int index) => DocumentStore.folderReadText(index);

  @override
  Future<void> forget() => DocumentStore.folderForget();
}

class DocumentStoreImportSource implements ImportSource {
  const DocumentStoreImportSource(this.treeUri);

  final String treeUri;

  @override
  Future<List<ImportFile>> scan() async {
    final rows = await DocumentStore.folderScan(treeUri);
    return [
      for (final r in rows)
        ImportFile(
          index: r.index,
          path: r.path,
          size: r.size,
          modified: r.modified,
        ),
    ];
  }

  @override
  Future<String> readText(int index) => DocumentStore.folderReadText(index);

  @override
  Future<void> forget() => DocumentStore.folderForget();
}
