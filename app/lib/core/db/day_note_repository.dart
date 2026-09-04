import 'package:drift/drift.dart';

import 'database.dart';
import 'vault_changed.dart';

/// One line about a whole day. **`PLAN.md` §9.6, and §7.0-E's first item.**
///
/// ── WHY THIS TABLE HAS EXISTED, EMPTY, SINCE SCHEMA VERSION 1 ─────────────
///
/// `DATA-MODEL.md` §3 wrote it down and nothing ever used it:
///
/// > *"The exception: an optional `day_notes` table for a one-line summary or
/// > a mood marker attached to the day rather than to any entry."*
///
/// It was right to put the table in early and right not to build the feature
/// until there was an argument for it. The argument is the one thing this app
/// is organised around: **the day is the unit.** Everything else in Lamplight
/// hangs off a `YYYY-MM-DD` key — the stream, the calendar, the year grid, the
/// export's folder layout — and until now the day itself was the only object
/// in the model that could not be given a name. A day could hold twenty things
/// and still be, in the calendar, a number and a density ramp.
///
/// A one-line summary changes what looking back is like more than any feature
/// on the remaining list, because it is the only one that makes a day
/// *legible from outside itself*.
///
/// ── WHY IT IS ITS OWN ROW AND NOT AN ENTRY ────────────────────────────────
///
/// It could have been "an entry with a flag on it", and that would have been
/// cheaper. It would also have been wrong twice over:
///
///   * an entry has a **time**, and the note is about the whole day. Drawn in
///     the stream in time order it would land in the middle of the afternoon,
///     which is not where a title goes;
///   * an entry can be **trashed, restored, filed in a folder and revised**.
///     None of those mean anything for a line that names a day, and every one
///     of them would have needed a special case somewhere else.
///
/// So: a separate table, one row per day, primary-keyed on the day itself.
///
/// ── THE ROW IS CREATED LAZILY AND REMOVED WHEN IT EMPTIES ─────────────────
///
/// `DATA-MODEL.md` is explicit that **days are never rows** — a day exists
/// because something is on it, not because a table says so. A `day_notes` row
/// for every day the user has ever opened would quietly undo that: the vault
/// would grow a row per swipe, and every count that says "how many days does
/// this journal cover" would have to learn to ignore them.
///
/// [setBody] therefore deletes the row when the last thing on it goes away,
/// rather than storing an empty string. An empty note and no note are the same
/// fact and the database should only be able to say it one way.
///
/// ── IT IS IN EVERY BACKUP ALREADY, AND THAT IS NOT LUCK ───────────────────
///
/// The `.vault` format copies `vault.db` whole rather than exporting tables it
/// knows about, so a new table is backed up and restored the day it is written
/// to, with no format change and no version bump. That is the property that
/// design bought and it is worth naming here: **a feature cannot forget to be
/// backed up.** The readable export is the one that had to be taught, because
/// it writes Markdown rather than bytes — see `plain_export.dart`.
class DayNoteRepository {
  DayNoteRepository(this._db);

  final VaultDatabase _db;

  /// The line on one day, live. Null when there is none.
  ///
  /// A stream rather than a future because the day view keeps it on screen
  /// while the user edits it, and drift re-runs the query when the row
  /// changes — so saving and displaying do not need to agree about anything.
  Stream<String?> watch(String dayKey) {
    return (_db.select(_db.dayNotes)..where((t) => t.dayKey.equals(dayKey)))
        .watchSingleOrNull()
        .map((row) {
      final body = row?.body?.trim();
      return (body == null || body.isEmpty) ? null : body;
    });
  }

  /// The line on one day, once.
  Future<String?> read(String dayKey) async {
    final row = await (_db.select(_db.dayNotes)
          ..where((t) => t.dayKey.equals(dayKey)))
        .getSingleOrNull();
    final body = row?.body?.trim();
    return (body == null || body.isEmpty) ? null : body;
  }

  /// Every day that has a line, by key. For the export, which writes them all.
  ///
  /// One query rather than one per day: a ten-year journal is 3,650 day files
  /// and asking the database 3,650 questions during an export is the
  /// difference between a progress bar that moves and one that does not.
  Future<Map<String, String>> all() async {
    final rows = await _db.select(_db.dayNotes).get();
    return {
      for (final r in rows)
        if ((r.body?.trim() ?? '').isNotEmpty) r.dayKey: r.body!.trim(),
    };
  }

  /// Writes the line, or takes it away.
  ///
  /// Trimmed and collapsed to a single line before it is stored. It is
  /// **one line about a day** — a title, not a second composer — and a
  /// paragraph pasted into it would break the layout of the header it is drawn
  /// in and, worse, would tempt somebody to keep their actual writing in a
  /// field the entry editor cannot revise, cannot file and cannot search the
  /// way it searches everything else.
  ///
  /// The cap is generous rather than tight: 140 characters is long enough for
  /// any sentence that names a day and short enough that nothing else can grow
  /// into it.
  Future<void> setBody(String dayKey, String? body) async {
    final clean = _oneLine(body ?? '');

    if (clean.isEmpty) {
      // The marker column is reserved by `DATA-MODEL.md` and unused today. If
      // it is ever written, this must stop deleting rows that still carry one
      // — so it checks rather than assuming, and the assumption is written
      // down here rather than being invisible in a `delete`.
      final row = await (_db.select(_db.dayNotes)
            ..where((t) => t.dayKey.equals(dayKey)))
          .getSingleOrNull();
      final marker = row?.marker;
      if (marker == null || marker.isEmpty) {
        await (_db.delete(_db.dayNotes)..where((t) => t.dayKey.equals(dayKey)))
            .go();
      } else {
        await (_db.update(_db.dayNotes)
              ..where((t) => t.dayKey.equals(dayKey)))
            .write(const DayNotesCompanion(body: Value(null)));
      }
      return;
    }

    await _db.into(_db.dayNotes).insertOnConflictUpdate(
          DayNotesCompanion.insert(
            dayKey: dayKey,
            body: Value(clean),
          ),
        );
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }

  /// The longest a day's line may be.
  static const int maxLength = 140;

  /// Newlines become spaces, runs of whitespace collapse, and the whole thing
  /// is cut to [maxLength].
  ///
  /// Cutting rather than refusing: somebody pasting two paragraphs in has made
  /// a mistake about what this field is, and silently keeping the first
  /// sentence is a kinder correction than an error message about a limit they
  /// did not know existed. The field itself also stops accepting keystrokes at
  /// the cap, so typing never reaches this.
  static String _oneLine(String raw) {
    final flat = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= maxLength ? flat : flat.substring(0, maxLength).trim();
  }

  /// Days whose line contains [query], newest first.
  ///
  /// ── WHY A `LIKE` AND NOT THE FTS INDEX ────────────────────────────────────
  ///
  /// The same trade `search.dart` makes for filenames and transcripts, and for
  /// the same reason: `entry_search` is an **external-content** FTS5 table over
  /// `entries`, so it can only ever index one column of one table. Folding day
  /// notes in would mean a second index with its own triggers, migrated onto
  /// every existing vault, to search a table that holds at most one short row
  /// per day — 3,650 of them after a decade. A scan over that is not
  /// measurable.
  Future<List<({String dayKey, String body})>> search(String query,
      {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    // The two characters LIKE treats as wildcards, so "100%" finds the word.
    final safe = trimmed
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final rows = await _db.customSelect(
      '''
      SELECT day_key, body FROM day_notes
      WHERE body IS NOT NULL AND body != ''
        AND body LIKE ?1 ESCAPE '\\'
      ORDER BY day_key DESC
      LIMIT ?2
      ''',
      variables: [Variable<String>('%$safe%'), Variable<int>(limit)],
      readsFrom: {_db.dayNotes},
    ).get();

    return [
      for (final r in rows)
        (dayKey: r.read<String>('day_key'), body: r.read<String>('body')),
    ];
  }
}
