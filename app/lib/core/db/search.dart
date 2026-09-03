import 'package:drift/drift.dart';

import 'database.dart';
import 'day_note_repository.dart';
import 'entry_repository.dart';

/// The invisible characters that fence a match inside a snippet.
///
/// U+0001 and U+0002 — control codes that cannot occur in anything a person
/// types, so they can never collide with real content. FTS5 is asked to emit
/// the same pair by `snippet(…, char(1), char(2), …)`, which is why one
/// renderer in the search screen handles a text hit and a filename hit alike.
const String markStart = '';
const String markEnd = '';

/// What one search turned up.
class SearchHits {
  const SearchHits({
    required this.days,
    required this.namedDays,
    required this.entries,
    required this.folders,
  });

  static const empty =
      SearchHits(days: [], namedDays: [], entries: [], folders: []);

  /// Dates the query could be naming. Shown first and separately, because
  /// "16 March 2006" is a navigation instruction, not a search term.
  final List<DateTime> days;

  /// Days the user gave a line to, whose line matches. **`PLAN.md` §7.0-E.**
  ///
  /// Beside [days] rather than mixed into [entries], because a day note is not
  /// an entry — it has no time, it cannot be opened, and the only useful thing
  /// to do with it is go to the day. Both lists lead to the same place, so
  /// they are drawn under one heading and de-duplicated in the screen.
  final List<DayNoteHit> namedDays;

  final List<SearchHit> entries;

  /// Folders whose name matches. A folder name is often the thing somebody is
  /// actually reaching for — "Kavya" means the folder far more often than it
  /// means the word inside a sentence.
  final List<Folder> folders;

  bool get isEmpty =>
      days.isEmpty &&
      namedDays.isEmpty &&
      entries.isEmpty &&
      folders.isEmpty;
}

/// A day whose own line matched.
class DayNoteHit {
  const DayNoteHit({required this.date, required this.snippet});

  final DateTime date;

  /// The line, with the matched part fenced in [markStart] and [markEnd] so
  /// the search screen's one renderer bolds it like every other kind of hit.
  final String snippet;
}

/// One search result: the entry, and why it matched.
class SearchHit {
  const SearchHit({
    required this.entry,
    required this.snippet,
    required this.reason,
  });

  final Entry entry;

  /// The matched phrase with a little of what surrounds it. The match is
  /// wrapped in [markStart] and [markEnd] so the UI can bold it without a
  /// regex that would have to re-implement FTS5's own idea of a word boundary.
  final String snippet;

  final HitReason reason;
}

enum HitReason {
  /// The words matched.
  text,

  /// The name of an attached file matched.
  filename,

  /// It was said out loud in a recording. **ISSUE 15.**
  spoken,
}

/// Which kinds of thing to include.
///
/// `UX-FLOWS.md` flow 4 asks for filter chips and they were left out of the
/// first pass because "a filter row above two results is furniture". That was
/// true when search only looked at text. Now that it also finds photographs by
/// filename and days by date, the kinds genuinely differ and narrowing them is
/// the fastest way to a specific memory: *"the voice note from that week"*.
enum SearchKind {
  writing('Writing', 'text'),
  voice('Voice', 'voice'),
  photos('Photos', 'photo'),
  video('Video', 'video'),
  files('Files', 'file');

  const SearchKind(this.label, this.type);

  final String label;
  final String type;
}

/// Everything the search box can find.
///
/// ── WHY THIS IS FOUR SEARCHES AND NOT ONE ────────────────────────────────
///
/// A person typing into one box is not writing a query, they are naming a
/// thing they are trying to get back to — and the thing they name is one of
/// four kinds:
///
///   * **words they wrote** — `FTS5`, which the schema has carried since v1;
///   * **a date** — "16 March 2006", "march 2006", "2006", "16/3/06",
///     "yesterday". A journal is organised by date, so a date is the single
///     most likely thing to be typed, and the old search could not find one at
///     all: `MATCH '"16" AND "march"*'` searches the *body text* of entries for
///     the word "march", which is almost never what was meant;
///   * **a filename** — "scan.pdf", "IMG_2831". The name is in the encrypted
///     database, has always been there, and nothing has ever looked at it;
///   * **a folder** — the name of a person or a phase.
///
/// Running four cheap queries and labelling the results is far better than one
/// clever query that half-answers all of them. They are also genuinely cheap:
/// the FTS one is indexed, the other three are scans over small tables.
extension VaultSearch on EntryRepository {
  Future<SearchHits> searchEverything(
    String query, {
    Set<SearchKind> kinds = const {},
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return SearchHits.empty;

    final results = await Future.wait([
      _searchText(trimmed, kinds),
      _searchFilenames(trimmed, kinds),
      _searchFolders(trimmed),
      _searchTranscripts(trimmed, kinds),
      _searchDayNotes(trimmed, kinds),
    ]);

    final text = results[0] as List<SearchHit>;
    final names = results[1] as List<SearchHit>;
    final folders = results[2] as List<Folder>;
    final spoken = results[3] as List<SearchHit>;
    final named = results[4] as List<DayNoteHit>;

    // Filename matches after text ones, and never twice: an entry whose words
    // *and* whose attachment name both matched is one result, and the words
    // are the more useful thing to show.
    //
    // ISSUE 15. Transcripts sit between the two: what somebody *said* is much
    // closer to what they wrote than a filename is, and it is the thing they
    // are actually reaching for when they search a voice note. Above filenames,
    // below writing.
    final seen = text.map((h) => h.entry.id).toSet();
    final merged = [
      ...text,
      ...spoken.where((h) => seen.add(h.entry.id)),
      ...names.where((h) => seen.add(h.entry.id)),
    ];

    return SearchHits(
      days: parseDates(trimmed),
      namedDays: named,
      entries: merged,
      folders: folders,
    );
  }

  /// Days whose own line matched. **`PLAN.md` §7.0-E, day notes.**
  ///
  /// Skipped entirely when the user has narrowed to a kind, because every
  /// [SearchKind] names a kind of *entry* and a day note is not one. Returning
  /// them anyway would mean ticking "Photos" and still being shown a day whose
  /// line mentions the word — which reads as the filter being broken.
  Future<List<DayNoteHit>> _searchDayNotes(
      String query, Set<SearchKind> kinds) async {
    if (kinds.isNotEmpty) return const [];
    final rows = await DayNoteRepository(db).search(query);
    return [
      for (final r in rows)
        if (_dateOfKey(r.dayKey) case final date?)
          DayNoteHit(date: date, snippet: _markMatch(r.body, query)),
    ];
  }

  /// `YYYY-MM-DD` back to a date, or null if the key is not one.
  ///
  /// Null rather than throwing: the key is the primary key of a table that has
  /// been in the schema since version 1, and a vault restored from somewhere
  /// odd should lose one search result rather than every one of them.
  static DateTime? _dateOfKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Where one word ends and the next begins, **in any script**.
  ///
  /// ══ ROUND NINE, ISSUE 11 — "ALL LANGUAGES SUPPORT IN WRITING" ═══════════
  ///
  /// He was right, and the failure was one character wide.
  ///
  /// This was `RegExp(r'[^\w]+')`, and in Dart — as in JavaScript, and even
  /// with the unicode flag set — **`\w` means `[A-Za-z0-9_]` and nothing
  /// else.** So every character of every non-Latin script counted as a word
  /// *separator*, and splitting on separators threw the words away:
  ///
  /// ```
  /// 'कल main office नहीं गया'  →  ['main', 'office']
  /// ```
  ///
  /// A search for a Hindi word produced an **empty** term list, and an empty
  /// term list returns no results at all — so it did not look like a bad
  /// search, it looked like the app having nothing written in Hindi.
  ///
  /// The index was never the problem. FTS5's `unicode61` tokenizer classifies
  /// by Unicode category and had been indexing Devanagari, Tamil, Arabic and
  /// Cyrillic correctly since schema version 1. Everything he wrote was in
  /// there. Only the question was being asked in English.
  ///
  /// ── WHY `\p{M}` IS IN THE LIST ───────────────────────────────────────────
  ///
  /// Combining marks: Devanagari matras, Tamil vowel signs, Arabic
  /// diacritics — `Mn` and `Mc` rather than `L`. Without them a word breaks at
  /// its own vowel: नहीं would come apart into नह and , which matches nothing
  /// and is worse than not searching.
  ///
  /// ── AND WHAT IT STILL CANNOT DO, HONESTLY ────────────────────────────────
  ///
  /// Japanese and Chinese are written without spaces, so 今日はいい日でした is
  /// one term here and one token in the index. It matches when the whole run is
  /// typed and not when a word inside it is. Fixing that needs a dictionary
  /// tokenizer — a real dependency, against `CLAUDE.md` rule 4 — and it is a
  /// different job from this one. **Writing, storing, exporting and restoring
  /// those scripts all work**; it is finding a word inside a run of them that
  /// does not, and saying so is better than implying otherwise.
  static final RegExp _wordBreak =
      RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

  Future<List<SearchHit>> _searchText(
      String query, Set<SearchKind> kinds) async {
    final terms = query
        .toLowerCase()
        .split(_wordBreak)
        .where((w) => w.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];

    // Every word required, the last one as a prefix so results narrow while
    // you are still typing rather than only when you stop. Each term is
    // quoted, which makes it a literal — otherwise an apostrophe in "dad's
    // birthday" is an FTS5 syntax error and a perfectly ordinary phrase
    // returns nothing at all.
    final match = [
      for (var i = 0; i < terms.length; i++)
        i == terms.length - 1 ? '"${terms[i]}"*' : '"${terms[i]}"',
    ].join(' AND ');

    final typeFilter = kinds.isEmpty
        ? ''
        : "AND e.type IN (${kinds.map((k) => "'${k.type}'").join(',')})";

    final rows = await db.customSelect(
      '''
      SELECT e.*,
             snippet(entry_search, 0, char(1), char(2), '…', 14) AS snippet
      FROM entry_search
      JOIN entries e ON e.rowid = entry_search.rowid
      WHERE entry_search MATCH ?1
        AND e.deleted_at IS NULL
        $typeFilter
      ORDER BY bm25(entry_search), e.created_at DESC
      LIMIT 150
      ''',
      variables: [Variable<String>(match)],
      readsFrom: {db.entries},
    ).get();

    return [
      for (final row in rows)
        SearchHit(
          entry: db.entries.map(row.data),
          snippet: row.read<String>('snippet'),
          reason: HitReason.text,
        ),
    ];
  }

  /// Recordings in which the query was said out loud. **ISSUE 15.**
  ///
  /// ── WHY THIS IS A `LIKE` AND NOT PART OF THE FTS INDEX ────────────────────
  ///
  /// `entry_search` is an **external-content** FTS5 table over `entries`, which
  /// means SQLite keeps it in step with exactly one table's exactly one column.
  /// A transcript lives on `attachments`. Folding it in would mean either a
  /// second index with its own triggers, or denormalising the transcript into
  /// `entries.body` — where it would then be drawn on the day as if the user
  /// had typed it.
  ///
  /// Neither is worth it at this size. This is the same trade `_searchFilenames`
  /// already makes and documents: a leading-wildcard `LIKE` cannot use an index,
  /// which would matter over millions of rows and does not over the few thousand
  /// recordings a decade of journalling produces. If somebody ever has a hundred
  /// thousand voice notes, the answer is a second FTS table, and this comment is
  /// where they should start.
  Future<List<SearchHit>> _searchTranscripts(
      String query, Set<SearchKind> kinds) async {
    // If the user has narrowed to kinds that cannot have a transcript, there is
    // nothing here to find and the query is skipped rather than run.
    if (kinds.isNotEmpty && !kinds.contains(SearchKind.voice)) return const [];

    // The same escaping as `_searchFilenames`, for the same reason: so that
    // searching for "100%" finds the word rather than everything.
    final safe = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final rows = await db.customSelect(
      '''
      SELECT e.*, a.transcript AS said
      FROM entries e
      JOIN attachments a ON a.id = e.attachment_id
      WHERE e.deleted_at IS NULL
        AND a.transcript IS NOT NULL
        AND a.transcript != ''
        AND a.transcript LIKE ?1 ESCAPE '\\'
      ORDER BY e.created_at DESC
      LIMIT 60
      ''',
      variables: [Variable<String>('%$safe%')],
      readsFrom: {db.entries, db.attachments},
    ).get();

    return [
      for (final row in rows)
        SearchHit(
          entry: db.entries.map(row.data),
          snippet: _markMatch(row.read<String>('said'), query),
          reason: HitReason.spoken,
        ),
    ];
  }

  /// Attachments whose original name contains the query.
  ///
  /// A plain `LIKE`, deliberately. Filenames are short, there are not many of
  /// them, and FTS5's tokeniser splits `IMG_2831.jpg` into pieces that do not
  /// match what somebody types. `LIKE` with a leading wildcard cannot use an
  /// index, which would matter over millions of rows and does not over the
  /// few thousand attachments a decade of journalling produces.
  Future<List<SearchHit>> _searchFilenames(
      String query, Set<SearchKind> kinds) async {
    // Escape the two characters LIKE treats as wildcards, so searching for
    // "100%" finds a file called that rather than everything.
    final safe = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final typeFilter = kinds.isEmpty
        ? ''
        : "AND e.type IN (${kinds.map((k) => "'${k.type}'").join(',')})";

    final rows = await db.customSelect(
      '''
      SELECT e.*, a.original_name AS attachment_name
      FROM entries e
      JOIN attachments a ON a.id = e.attachment_id
      WHERE e.deleted_at IS NULL
        AND a.original_name LIKE ?1 ESCAPE '\\'
        $typeFilter
      ORDER BY e.created_at DESC
      LIMIT 60
      ''',
      variables: [Variable<String>('%$safe%')],
      readsFrom: {db.entries, db.attachments},
    ).get();

    return [
      for (final row in rows)
        SearchHit(
          entry: db.entries.map(row.data),
          snippet: _markMatch(row.read<String>('attachment_name'), query),
          reason: HitReason.filename,
        ),
    ];
  }

  Future<List<Folder>> _searchFolders(String query) async {
    final safe = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return (db.select(db.folders)
          ..where((t) => t.name.like('%$safe%'))
          ..limit(12))
        .get();
  }

  /// Wraps the matched part in the same sentinels FTS5 uses, so one renderer
  /// handles both kinds of hit.
  static String _markMatch(String text, String query) {
    final at = text.toLowerCase().indexOf(query.toLowerCase());
    if (at < 0) return text;
    return '${text.substring(0, at)}$markStart'
        '${text.substring(at, at + query.length)}$markEnd'
        '${text.substring(at + query.length)}';
  }
}

/// Dates the query might be naming.
///
/// ── WHY THIS IS A HAND-WRITTEN PARSER AND NOT A PACKAGE ──────────────────
///
/// `CLAUDE.md` rule 4: every package added can read all of the user's notes,
/// and a natural-language date library is a large surface for a small job. The
/// set of things people actually type into a journal's search box is small and
/// closed, and it is written out below.
///
/// Returns a list rather than one date because a query can genuinely be
/// several: "3/4" is 3 April to most of the world and 4 March in the United
/// States, and there is no way to know which was meant. Offering both is
/// honest; silently picking one and being wrong sends somebody to an empty day
/// and tells them they wrote nothing.
///
/// Anything that resolves to a whole month or a whole year returns its first
/// day — landing on 1 March 2006 is a perfectly good starting point for
/// somebody who typed "march 2006", and the calendar is one tap away.
List<DateTime> parseDates(String query, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  DateTime day(int y, int m, int d) => DateTime(y, m, d);
  bool valid(int y, int m, int d) {
    if (y < 1600 || y > 2400 || m < 1 || m > 12 || d < 1 || d > 31) return false;
    // Rejects 31 February rather than letting DateTime roll it into March,
    // which would send somebody to a day they did not ask for.
    return day(y, m, d).month == m && day(y, m, d).day == d;
  }

  // The words first, because they are unambiguous and the most common.
  switch (q) {
    case 'today':
      return [DateTime(now.year, now.month, now.day)];
    case 'yesterday':
      final d = now.subtract(const Duration(days: 1));
      return [DateTime(d.year, d.month, d.day)];
    case 'tomorrow':
      final d = now.add(const Duration(days: 1));
      return [DateTime(d.year, d.month, d.day)];
  }

  const months = <String, int>{
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  final out = <DateTime>[];
  void add(DateTime d) {
    if (!out.contains(d)) out.add(d);
  }

  // ── "16 March 2006", "March 16 2006", "march 2006", "16 march" ──────────
  final words = q.split(RegExp(r'[\s,]+')).where((w) => w.isNotEmpty).toList();
  int? namedMonth;
  final numbers = <int>[];
  for (final w in words) {
    // "16th" and "3rd" — people type ordinals.
    final bare = w.replaceAll(RegExp(r'(st|nd|rd|th)$'), '');
    final m = months[w] ?? months[bare];
    if (m != null && namedMonth == null) {
      namedMonth = m;
      continue;
    }
    final n = int.tryParse(bare);
    if (n != null) numbers.add(n);
  }

  if (namedMonth != null) {
    final dayNumbers = numbers.where((n) => n >= 1 && n <= 31).toList();
    final years = numbers.where((n) => n >= 1600 && n <= 2400).toList();
    // A bare two-digit year after a month — "march 06" — is genuinely
    // ambiguous with a day, so it is read as a day. That is the more common
    // intent and the calendar fixes the other case in one tap.
    if (dayNumbers.isEmpty && years.isEmpty) {
      add(day(now.year, namedMonth, 1));
    } else if (years.isEmpty) {
      for (final d in dayNumbers.take(2)) {
        if (valid(now.year, namedMonth, d)) add(day(now.year, namedMonth, d));
      }
    } else if (dayNumbers.isEmpty) {
      add(day(years.first, namedMonth, 1));
    } else {
      for (final d in dayNumbers.take(2)) {
        if (valid(years.first, namedMonth, d)) {
          add(day(years.first, namedMonth, d));
        }
      }
    }
    return out;
  }

  // ── "16/3/2006", "2006-03-16", "16.3.06" ─────────────────────────────────
  final parts = q.split(RegExp(r'[/\-.]')).where((p) => p.isNotEmpty).toList();
  if (parts.length == 3 && parts.every((p) => int.tryParse(p) != null)) {
    final a = int.parse(parts[0]);
    final b = int.parse(parts[1]);
    var cRaw = int.parse(parts[2]);
    // Two digits is this century unless that is in the future by more than a
    // year, in which case it is the last one. "99" is 1999, "06" is 2006.
    if (parts[2].length <= 2) {
      cRaw = cRaw + (cRaw + 2000 > now.year + 1 ? 1900 : 2000);
    }

    if (a >= 1600) {
      // Unambiguous: year first, so ISO.
      if (valid(a, b, cRaw)) add(day(a, b, cRaw));
    } else {
      // Both readings, day-first offered before month-first because most of
      // the world writes it that way and the owner of this app is in India.
      if (valid(cRaw, b, a)) add(day(cRaw, b, a));
      if (valid(cRaw, a, b)) add(day(cRaw, a, b));
    }
    return out;
  }

  // ── A bare year: "2006" ──────────────────────────────────────────────────
  final year = int.tryParse(q);
  if (year != null && year >= 1600 && year <= 2400) {
    add(day(year, 1, 1));
  }

  return out;
}
