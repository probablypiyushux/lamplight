import 'package:drift/drift.dart';

import '../storage/attachment_store.dart';
import '../../l10n/generated/app_localizations.dart';
import 'database.dart';

/// Every query the app makes about entries, in one place.
///
/// WHY THIS IS NOT SCATTERED THROUGH THE SCREENS
///
/// The first version of the day view built its own queries inline. That was
/// fine while the day view was the only screen. It stops being fine the moment
/// a second surface — the calendar, the trash — has to agree with it about what
/// "an entry that exists" means. Miss `deletedAt.isNull()` in one place and a
/// deleted entry reappears in the calendar's count but not in the day, and the
/// user is looking at an app that contradicts itself.
///
/// So: **the rule that deleted entries are invisible is written once, here.**
///
/// Everything returns a `Stream` rather than a `Future` where the UI shows a
/// list. drift's `watch()` re-runs the query whenever a table it touched
/// changes, which means deleting an entry updates the day, the calendar and the
/// trash together without any screen having to know the others exist.
class EntryRepository {
  EntryRepository(this._db, {AttachmentStore? attachments})
      : _attachments = attachments;

  final VaultDatabase _db;

  /// The database, for the search extension below. Extensions cannot reach a
  /// private field, and the alternative — moving search into this class —
  /// would put a hundred lines of query syntax in the middle of the file that
  /// exists to keep queries short.
  VaultDatabase get db => _db;

  /// Optional, because most callers only read text. Given, a purge also removes
  /// the encrypted blob behind an entry — without it, deleting a photo forever
  /// would remove the row and leave the file on disk, unreadable by anyone and
  /// unremovable by anything, growing for the life of the app.
  final AttachmentStore? _attachments;

  /// A `YYYY-MM-DD` key in local time, the way `DATA-MODEL.md` defines it.
  ///
  /// Here rather than in each screen because it is easy to write four subtly
  /// different versions of this, and a key that disagrees by one character
  /// puts an entry on a day nobody can find.
  static String dayKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ── Reading ────────────────────────────────────────────────────────────────

  /// The stream of entries on one day, oldest first.
  ///
  /// Oldest first because this is a record of a day as it happened, not a feed.
  /// Newest-first would put this morning at the bottom of last night.
  Stream<List<Entry>> watchDay(String dayKey) {
    return (_db.select(_db.entries)
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Whether anything at all is on one day, live.
  ///
  /// For the header's day line, which offers to name a day only once the day
  /// has something on it — see `day_line.dart` for why that rule exists.
  ///
  /// **Not `watchDay(key).map((l) => l.isNotEmpty)`.** That would hand the
  /// header the full row of every entry on the day, including bodies, so that
  /// it could look at a boolean; on a day of long writing that is the whole
  /// day's text decrypted a second time for one bit of information. `EXISTS`
  /// stops at the first matching row and uses `idx_entries_day`.
  ///
  /// `.distinct()` because the caller rebuilds on it: without it, every
  /// keystroke that autosaves re-emits `true` and the header rebuilds on a
  /// value that has not changed.
  Stream<bool> watchHasEntries(String dayKey) {
    return _db
        .customSelect(
          'SELECT EXISTS(SELECT 1 FROM entries '
          'WHERE day_key = ?1 AND deleted_at IS NULL) AS any_entries',
          variables: [Variable<String>(dayKey)],
          readsFrom: {_db.entries},
        )
        .watchSingle()
        .map((row) => row.read<int>('any_entries') == 1)
        .distinct();
  }

  Future<Entry?> entryById(String id) =>
      (_db.select(_db.entries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// How many entries sit on each day between two keys, inclusive.
  ///
  /// Feeds the calendar. Returned as a map rather than a list of rows so a
  /// missing key means "nothing happened" — the calendar then has no way to
  /// accidentally render an empty day as level zero of the ramp instead of as
  /// the neutral, which `DESIGN-SYSTEM.md` is specific about.
  Future<Map<String, int>> countsBetween(String fromKey, String toKey) async {
    final rows = await _db.customSelect(
      'SELECT day_key, COUNT(*) AS n FROM entries '
      'WHERE deleted_at IS NULL AND day_key >= ?1 AND day_key <= ?2 '
      'GROUP BY day_key',
      variables: [Variable<String>(fromKey), Variable<String>(toKey)],
      readsFrom: {_db.entries},
    ).get();
    return {
      for (final r in rows) r.read<String>('day_key'): r.read<int>('n'),
    };
  }

  /// The day key of the oldest surviving entry, or null if the vault is empty.
  ///
  /// Bounds the year picker in the calendar. Offering years the user has
  /// nothing in would be offering them a list of empty rooms.
  Future<String?> earliestDayKey() async {
    final row = await _db.customSelect(
      'SELECT MIN(day_key) AS k FROM entries WHERE deleted_at IS NULL',
      readsFrom: {_db.entries},
    ).getSingle();
    return row.read<String?>('k');
  }

  /// Whether this vault has **never** held anything, live.
  ///
  /// Not "is today empty" — `watchHasEntries` answers that. This is the
  /// difference between *a quiet Tuesday* and *the first minute anybody has
  /// ever spent in this app*, and they deserve different pages: one is a fact
  /// about a day, the other is somebody standing in a room they have just been
  /// given the key to.
  ///
  /// Watched rather than read once, because the answer changes exactly once in
  /// the life of a vault and the moment it changes is the moment the first
  /// thing is written — which is a moment the screen is already on.
  ///
  /// **Deleted entries count as having been written.** Somebody who wrote
  /// something and threw it away has used this app; showing them the welcome
  /// again would be the app forgetting them, which is the one thing it is for
  /// not doing.
  Stream<bool> watchIsBrandNew() {
    return _db
        .customSelect(
          'SELECT NOT EXISTS(SELECT 1 FROM entries) AS brand_new',
          readsFrom: {_db.entries},
        )
        .watchSingle()
        .map((row) => row.read<int>('brand_new') == 1)
        .distinct();
  }

  /// What happened on this date in earlier years.
  ///
  /// ── THE EMOTIONAL ENGINE, AND IT IS ONE QUERY ────────────────────────────
  ///
  /// `PLAN.md` §3 argues at length that the honest way to make somebody open a
  /// private journal for years is not a streak or a notification — it is
  /// **their own forgotten material**. The strongest reaction anybody has to
  /// their own records is to something they did not remember writing, and
  /// nothing else in this app can produce that feeling.
  ///
  /// It is also the cheapest feature in the file. `day_key` is `YYYY-MM-DD`, so
  /// "the same date in another year" is a suffix match, and `idx_entries_day`
  /// does not help with a suffix — but a `LIKE '%-08-19'` over a few thousand
  /// rows is sub-millisecond and this runs once when a day opens.
  ///
  /// Ordered newest first, so "last year" comes before "four years ago". Text
  /// entries only: a photograph with no words resurfaced out of context is a
  /// puzzle rather than a memory, and the card has room for one line.
  Future<List<Entry>> onThisDay(DateTime day) async {
    final suffix = '-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final thisYear = day.year.toString().padLeft(4, '0');
    return (_db.select(_db.entries)
          ..where((t) => t.dayKey.like('%$suffix'))
          ..where((t) => t.dayKey.isSmallerThanValue('$thisYear-'))
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.body.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.dayKey)])
          ..limit(8))
        .get();
  }

  /// What *kinds* of thing are on each day in a range, and one photo per day.
  ///
  /// Feeds the calendar. `PLAN.md` §8.4: "every day should look like itself" —
  /// right now every day is a number and a bar, so August looks like March.
  /// With this, a day with a photograph shows the photograph, and the kinds
  /// present are marked by **shape** rather than by colour.
  ///
  /// One query rather than one per day. A month grid asking 31 questions is 31
  /// round trips into SQLCipher before the first frame, which is exactly the
  /// kind of thing that makes a calendar feel heavy to open.
  Future<Map<String, DaySummary>> summariesBetween(
      String fromKey, String toKey) async {
    final rows = await _db.customSelect(
      '''
      SELECT e.day_key AS day_key,
             COUNT(*) AS n,
             MAX(e.type = 'text')  AS has_text,
             MAX(e.type = 'voice') AS has_voice,
             MAX(e.type = 'photo') AS has_photo,
             MAX(e.type = 'video') AS has_video,
             MAX(e.type = 'file')  AS has_file,
             MAX(e.marker)         AS marker,
             (SELECT p.attachment_id FROM entries p
               WHERE p.day_key = e.day_key AND p.type = 'photo'
                 AND p.deleted_at IS NULL AND p.attachment_id IS NOT NULL
               ORDER BY p.created_at LIMIT 1) AS photo_id
      FROM entries e
      WHERE e.deleted_at IS NULL AND e.day_key >= ?1 AND e.day_key <= ?2
      GROUP BY e.day_key
      ''',
      variables: [Variable<String>(fromKey), Variable<String>(toKey)],
      readsFrom: {_db.entries},
    ).get();

    return {
      for (final r in rows)
        r.read<String>('day_key'): DaySummary(
          count: r.read<int>('n'),
          hasText: r.read<int>('has_text') == 1,
          hasVoice: r.read<int>('has_voice') == 1,
          hasPhoto: r.read<int>('has_photo') == 1,
          hasVideo: r.read<int>('has_video') == 1,
          hasFile: r.read<int>('has_file') == 1,
          marker: r.read<String?>('marker'),
          photoAttachmentId: r.read<String?>('photo_id'),
        ),
    };
  }

  /// The attachment rows the calendar needs to draw its thumbnails.
  Future<List<Attachment>> attachmentsByIds(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const [];
    return (_db.select(_db.attachments)..where((t) => t.id.isIn(list))).get();
  }

  /// The deleted entries still inside their 30 days, newest deletion first.
  Stream<List<Entry>> watchTrash() {
    return (_db.select(_db.entries)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .watch();
  }

  /// Earlier versions of one entry, newest first.
  Future<List<Revision>> revisionsFor(String entryId) {
    return (_db.select(_db.revisions)
          ..where((t) => t.entryId.equals(entryId))
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .get();
  }

  /// Totals for the settings screen and the backup summary.
  Future<({int entries, int days})> stats() async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS n, COUNT(DISTINCT day_key) AS d '
      'FROM entries WHERE deleted_at IS NULL',
      readsFrom: {_db.entries},
    ).getSingle();
    return (entries: row.read<int>('n'), days: row.read<int>('d'));
  }

  /// Every surviving entry, oldest day first and oldest entry within each day.
  ///
  /// For the readable export, and for nothing else. It is the one query in the
  /// app that deliberately loads the whole vault, which is why it is named for
  /// its single caller rather than offered as a general `all()` that a screen
  /// might one day reach for.
  ///
  /// The rows are small — text, timestamps and ids. The heavy content is in the
  /// attachment blobs, which the export streams one chunk at a time and never
  /// holds. A vault with ten thousand entries is a few megabytes here.
  Future<List<Entry>> allForExport() {
    return (_db.select(_db.entries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.dayKey),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  /// Which folders each entry is filed in, by entry id.
  ///
  /// One query with a join rather than one per entry. Only entries that are
  /// filed somewhere appear, so a missing key means "not filed" and the caller
  /// never has to distinguish that from an empty list.
  Future<Map<String, List<String>>> folderNamesByEntry() async {
    final rows = await _db.customSelect(
      'SELECT ef.entry_id AS entry_id, f.name AS name '
      'FROM entry_folders ef JOIN folders f ON f.id = ef.folder_id '
      'ORDER BY f.sort_order, f.name',
      readsFrom: {_db.entryFolders, _db.folders},
    ).get();
    final out = <String, List<String>>{};
    for (final r in rows) {
      (out[r.read<String>('entry_id')] ??= []).add(r.read<String>('name'));
    }
    return out;
  }

  // ── Writing ────────────────────────────────────────────────────────────────

  /// Writes a new text entry and returns its id.
  ///
  /// [dayKey] comes from the day being *viewed*, not from the clock. Write
  /// something into yesterday at one in the morning and it belongs to
  /// yesterday, which is what you meant.
  Future<void> createText({
    required String id,
    required String dayKey,
    required String body,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.entries).insert(
          EntriesCompanion.insert(
            id: id,
            createdAt: now.millisecondsSinceEpoch,
            // The local offset at creation, stored alongside the instant.
            // "What time did I think it was" matters in a journal, and travel
            // breaks a naive timestamp.
            createdOffsetMinutes: now.timeZoneOffset.inMinutes,
            updatedAt: now.millisecondsSinceEpoch,
            type: 'text',
            body: Value(body),
            dayKey: dayKey,
          ),
        );
  }

  /// A text entry that belongs to a past day, for the import.
  ///
  /// ── WHY THIS IS NOT JUST `createText` WITH A DIFFERENT dayKey ─────────────
  ///
  /// [createText] stamps `createdAt` from the clock, which is right for
  /// something being written now and wrong for a file from 2019: the entry
  /// would sit on the correct day showing this afternoon's time, and the day
  /// would order by when it was imported rather than by anything real.
  ///
  /// ── WHAT TIME AN IMPORTED NOTE HAPPENED AT, AND SAYING SO HONESTLY ────────
  ///
  /// We do not know. A filename gives a date and nothing else. The options
  /// were to invent a plausible time, which is a small lie inside somebody's
  /// own record, or to put them all at the start of their day, which is
  /// visibly a convention rather than a fact.
  ///
  /// The second one, with [sequence] adding seconds so several files on one
  /// day keep the order they were named in. Seconds rather than minutes
  /// because the day view shows `HH:MM` — so they all read `00:00`, which is
  /// the honest answer, while still sorting stably underneath.
  ///
  /// The import screen says this in words before anybody agrees to it.
  Future<void> createTextOn({
    required String id,
    required String dayKey,
    required String body,
    int sequence = 0,
  }) async {
    final parts = dayKey.split('-');
    final midnight = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).add(Duration(seconds: sequence));

    await _db.into(_db.entries).insert(
          EntriesCompanion.insert(
            id: id,
            createdAt: midnight.millisecondsSinceEpoch,
            createdOffsetMinutes: midnight.timeZoneOffset.inMinutes,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            type: 'text',
            body: Value(body),
            dayKey: dayKey,
          ),
        );
  }

  /// Replaces the body of an existing entry, keeping the old one.
  ///
  /// THE REVISION RULE, AND WHY IT IS NOT "SAVE EVERY VERSION"
  ///
  /// Autosave fires every 400 ms while someone is typing. Writing a revision on
  /// each of those would produce several hundred rows for one paragraph and
  /// push the twenty versions that matter out of the window within a minute —
  /// the feature would technically exist and would never once help anybody.
  ///
  /// So a revision is written only if the newest one for this entry is older
  /// than [_revisionCoalesce]. One editing session therefore leaves one
  /// revision: the text as it stood when you started changing it. That is the
  /// version a person actually wants back.
  Future<void> updateBody(String id, String body) async {
    final existing = await entryById(id);
    if (existing == null) return;
    final previous = existing.body ?? '';
    if (previous == body) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      if (previous.isNotEmpty) {
        final newest = await (_db.select(_db.revisions)
              ..where((t) => t.entryId.equals(id))
              ..orderBy([(t) => OrderingTerm.desc(t.savedAt)])
              ..limit(1))
            .getSingleOrNull();
        final stale = newest == null ||
            now - newest.savedAt > _revisionCoalesce.inMilliseconds;
        if (stale) {
          await _db.into(_db.revisions).insert(
                RevisionsCompanion.insert(
                  entryId: id,
                  body: previous,
                  savedAt: now,
                ),
              );
          await _pruneRevisions(id);
        }
      }
      await (_db.update(_db.entries)..where((t) => t.id.equals(id))).write(
        EntriesCompanion(body: Value(body), updatedAt: Value(now)),
      );
    });
  }

  static const Duration _revisionCoalesce = Duration(minutes: 5);

  /// Keeps the newest [_maxRevisions] and drops the rest.
  ///
  /// Unbounded history on a phone is a slow leak: an entry edited daily for
  /// three years would carry a thousand copies of itself inside an encrypted
  /// database the user has to back up.
  static const int _maxRevisions = 20;

  Future<void> _pruneRevisions(String entryId) async {
    await _db.customStatement(
      'DELETE FROM revisions WHERE entry_id = ?1 AND id NOT IN ('
      '  SELECT id FROM revisions WHERE entry_id = ?1 '
      '  ORDER BY saved_at DESC LIMIT ?2'
      ')',
      [entryId, _maxRevisions],
    );
  }

  /// The one marker this app has: **this one mattered**.
  ///
  /// ── WHY IT IS A FLAG AND NOT A SCALE ──────────────────────────────────────
  ///
  /// `FEATURES-IN-AND-OUT.md` is specific that a 1–10 mood scale is the wrong
  /// shape, and `PLAN.md` §10 rules out mood analytics and "your happiest
  /// month" entirely. The reasoning is worth keeping next to the code: a scale
  /// asks you to rate your own day, which turns writing into scoring, and once
  /// there are numbers there is a graph, and once there is a graph the journal
  /// is quietly a performance.
  ///
  /// A single flag asks nothing. It only answers a question the person already
  /// had — *where was that one* — and it is the whole of what makes
  /// [markedEntries] useful.
  ///
  /// Stored as text rather than a boolean because the column is text and
  /// because a later kind of mark ("a photograph of this", "answered") would
  /// otherwise need a migration. [markMattered] is the only value written
  /// today and nothing reads the string except to test it for null.
  static const String markMattered = 'mattered';

  Future<void> setMarker(String id, String? marker) async {
    await (_db.update(_db.entries)..where((t) => t.id.equals(id))).write(
      EntriesCompanion(marker: Value(marker)),
    );
  }

  /// Everything marked, newest day first.
  ///
  /// The payoff, and the reason the flag exists at all. Without somewhere to
  /// read them back, marking an entry is a gesture into nothing — which is
  /// what this column has been since the first commit.
  ///
  /// Limited, because this feeds a list somebody scrolls rather than an
  /// export. A vault with four thousand marked entries has a person who marks
  /// everything, and the first two hundred are as useful to them as all of it.
  Future<List<Entry>> markedEntries({int limit = 200}) {
    return (_db.select(_db.entries)
          ..where((t) => t.marker.isNotNull())
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.dayKey),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Moves an entry to the trash.
  ///
  /// Soft, always. `ETHICAL-DESIGN.md` requires destructive actions to be
  /// reversible, and this is the only destructive action in the app that a
  /// person can reach by accident with one thumb.
  Future<void> softDelete(String id) async {
    await (_db.update(_db.entries)..where((t) => t.id.equals(id))).write(
      EntriesCompanion(deletedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.entries)..where((t) => t.id.equals(id))).write(
      const EntriesCompanion(deletedAt: Value(null)),
    );
  }

  /// Removes an entry and its history for good.
  ///
  /// The row and every revision of it. The FTS index is maintained by the
  /// triggers in `database.dart`, so the deleted text leaves the search index
  /// in the same transaction rather than lingering there to be found by a
  /// search months later — which would be a genuinely alarming way to discover
  /// that "delete forever" did not.
  Future<void> purge(String id) async {
    final entry = await entryById(id);
    final attachmentId = entry?.attachmentId;

    // ── The poster frame goes with the video it belongs to ────────────────
    //
    // A video's thumbnail is a second attachment row that no entry points at
    // (ISSUE 8). Deleting the video without it would leave a row and a blob
    // that nothing can ever reach again — not a leak, because it is encrypted
    // with a key that is about to be deleted too, but space that would grow
    // forever and travel in every backup.
    final posterId = attachmentId == null
        ? null
        : (await (_db.select(_db.attachments)
                  ..where((t) => t.id.equals(attachmentId)))
                .getSingleOrNull())
            ?.thumbnailId;

    await _db.transaction(() async {
      await (_db.delete(_db.revisions)..where((t) => t.entryId.equals(id))).go();
      await (_db.delete(_db.entryFolders)..where((t) => t.entryId.equals(id)))
          .go();
      await (_db.delete(_db.entries)..where((t) => t.id.equals(id))).go();
      for (final gone in [attachmentId, posterId]) {
        if (gone == null) continue;
        await (_db.delete(_db.attachments)..where((t) => t.id.equals(gone)))
            .go();
      }
    });

    // The blobs last, and outside the transaction, because a filesystem cannot
    // be rolled back. Rows first means the worst case is an orphaned encrypted
    // file that nothing points at — wasted space. Blob first would mean a row
    // pointing at a file that is gone, which is a broken entry the user sees.
    for (final gone in [attachmentId, posterId]) {
      if (gone == null) continue;
      await _attachments?.delete(gone).catchError((_) {});
    }
  }

  /// Empties everything whose 30 days are up.
  ///
  /// Called at unlock rather than on a timer. A background job would need the
  /// vault open, and the vault is only open when the user is here — so "when
  /// they arrive" is the only honest moment to do this.
  Future<int> purgeExpired({Duration hold = const Duration(days: 30)}) async {
    final cutoff =
        DateTime.now().subtract(hold).millisecondsSinceEpoch;
    final doomed = await (_db.select(_db.entries)
          ..where((t) => t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(cutoff)))
        .get();
    for (final e in doomed) {
      await purge(e.id);
    }
    return doomed.length;
  }

  /// Deletes a draft row outright.
  ///
  /// Clearing the composer has to mean "I did not want this", not "keep an
  /// empty one forever" — and an entry that was never finished should not
  /// occupy the trash either.
  Future<void> discardDraft(String id) async {
    await (_db.delete(_db.entries)..where((t) => t.id.equals(id))).go();
  }
}

/// What one day in the calendar has on it.
///
/// Deliberately not just a count. A count answers "how much" and every other
/// question a person actually has about a month is "which day was the one
/// with…" — `PLAN.md` §8.4. Kinds are carried as booleans and drawn as shapes,
/// never as colour alone.
class DaySummary {
  const DaySummary({
    required this.count,
    required this.hasText,
    required this.hasVoice,
    required this.hasPhoto,
    required this.hasVideo,
    required this.hasFile,
    this.marker,
    this.photoAttachmentId,
  });

  final int count;
  final bool hasText;
  final bool hasVoice;
  final bool hasPhoto;
  final bool hasVideo;
  final bool hasFile;

  /// How the day felt, if the user ever said. See `PLAN.md` §9.3.
  final String? marker;

  /// The first photograph on the day, so the cell can show it. This is the
  /// single highest-value thing on the calendar: a month with pictures in it
  /// becomes navigable by memory rather than by date.
  final String? photoAttachmentId;

  /// A full sentence for a screen reader. `PLAN.md` §8.4 asks for exactly this
  /// rather than "3" — "16 March 2006, 3 entries, a photo and a voice note".
  String describeIn(L l) {
    final kinds = <String>[
      if (hasText) l.dayHasWriting,
      if (hasPhoto) l.dayHasPhoto,
      if (hasVideo) l.dayHasVideo,
      if (hasVoice) l.dayHasVoice,
      if (hasFile) l.dayHasFile,
    ];
    if (kinds.isEmpty) return l.countEntries(count);
    // "writing, a photo and a voice note". The last join is its own word
    // because every language puts it somewhere different, and three of the ten
    // do not use a comma before it at all.
    final what = kinds.length == 1
        ? kinds.first
        : l.listAnd(kinds.take(kinds.length - 1).join(l.listSeparator),
            kinds.last);
    return l.dayEntriesAndKinds(l.countEntries(count), what);
  }
}

/// Runs of consecutive entries that were captured together.
///
/// A run is only formed from **adjacent** entries with the same non-null
/// `groupId`. Adjacency matters: if somebody imports six photos, writes a
/// paragraph in the middle of them, and then imports more, the paragraph
/// splits the album rather than being swallowed by it — the order things
/// happened in is the one thing a day view must never rearrange.
///
/// Everything else comes back as a run of one, so the caller has a single
/// shape to iterate rather than two.
///
/// ── ISSUE 7: a video belongs in the album ──────────────────────────────
///
/// This used to require `type == 'photo'` on **both** the incoming entry and
/// the run it might join, so one multi-select containing a single clip came
/// apart into an album *plus* a stray grey video row underneath it. That is
/// exactly what his ISSUE 7 screenshot shows, and it is why the fix belongs
/// here rather than in the grid: the grid was never given the video to draw.
///
/// Photos and videos are both *pictures of a moment* and go in together, the
/// way they do in WhatsApp, Telegram, Signal and Snapchat. Documents and
/// voice notes stay their own blocks — those apps do the same, and a grey
/// rectangle where a picture should be is not an album.
const _albumTypes = {'photo', 'video'};

List<List<Entry>> groupIntoAlbums(List<Entry> entries) {
  final runs = <List<Entry>>[];
  for (final e in entries) {
    final id = e.groupId;
    if (id != null &&
        runs.isNotEmpty &&
        runs.last.first.groupId == id &&
        _albumTypes.contains(e.type) &&
        _albumTypes.contains(runs.last.first.type)) {
      runs.last.add(e);
    } else {
      runs.add([e]);
    }
  }
  return runs;
}
