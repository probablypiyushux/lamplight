import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// `DriftRemoteException` only. It is what the worker isolate wraps a failure
// in, and unwrapping it at the boundary is what keeps the worker invisible to
// every caller in the app -- see the note in `openVaultDatabase`.
//
// drift marks this library experimental. The alternative is matching on
// `runtimeType.toString()`, which would compile forever and break silently the
// day drift renames anything -- exactly the failure mode this import exists to
// prevent. If drift ever removes it, the build stops and says so, which is the
// louder and therefore safer way to find out.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
// For `CommonDatabase`, the handle `_prepare` is handed inside the worker.
import 'package:sqlite3/common.dart';
import '../../l10n/generated/app_localizations.dart';
import '../plain_words.dart';

part 'database.g.dart';

/// The encrypted database. Schema from `03-product/DATA-MODEL.md`.
///
/// THE ONE STRUCTURAL IDEA
///
/// There is exactly one kind of object: the Entry. Its timestamp puts it on a
/// Day automatically — days are never created, deleted or managed, they exist
/// because time exists, so there is no `days` table here and there never will
/// be. A day is a query. Filing an entry into a Folder is a *link*, not a move:
/// the entry stays on its day forever and appears in the folder too.
///
/// That is what makes "recording things about a particular phase or particular
/// person" fall out for free rather than being a second feature.
///
/// WHY THE WHOLE DATABASE IS ENCRYPTED RATHER THAN INDIVIDUAL FIELDS
///
/// ADR-006. SQLCipher decrypts transparently at the page level, so from
/// SQLite's point of view this is an ordinary database and every feature keeps
/// working — indexes, joins, and full-text search. Encrypting field by field
/// would make search impossible without decrypting every note in the vault, and
/// by year three with 5,000 entries the app would be unusable. Searchability is
/// a feature we would have lost forever by getting this decision wrong.

/// One captured thing. The atom of the whole model.
class Entries extends Table {
  /// UUID v4, generated from the OS CSPRNG.
  TextColumn get id => text()();

  /// The UTC instant, in milliseconds.
  IntColumn get createdAt => integer()();

  /// Minutes offset from UTC at the moment of creation.
  ///
  /// Stored alongside the instant because "what time did *I* think it was"
  /// matters in a journal, and travel breaks naive timestamps.
  IntColumn get createdOffsetMinutes => integer()();

  IntColumn get updatedAt => integer()();

  /// `text` · `voice` · `photo` · `file`.
  TextColumn get type => text()();

  /// The note itself. Encrypted with the database, not separately.
  TextColumn get body => text().nullable()();

  TextColumn get attachmentId => text().nullable()();

  /// `YYYY-MM-DD` in the LOCAL timezone at creation.
  ///
  /// **Fixed at creation and never recalculated.** DATA-MODEL.md is emphatic
  /// about this and it is the one modelling decision that cannot be fixed
  /// later: if you wrote it on what felt like Tuesday, it stays on Tuesday
  /// forever, in every timezone and every future version. Recomputing it would
  /// make entries jump days when someone flies Delhi to London, and produce bug
  /// reports that cannot be fixed without rewriting history.
  TextColumn get dayKey => text()();

  /// One optional tap: this one mattered. Not a 1–10 mood scale, not an emotion
  /// wheel — FEATURES-IN-AND-OUT.md is specific that a scale is the wrong shape.
  TextColumn get marker => text().nullable()();

  /// Photos chosen in one go share this. Schema v3.
  ///
  /// ── WHY THIS IS NOT A SECOND ATTACHMENT COLUMN ─────────────────────────
  ///
  /// Reported as: *"I don't need 15 different blocks if I upload multiple
  /// photos — I need one block, with the photos grouped."* Right, and that is
  /// how every messaging app on earth has worked for a decade.
  ///
  /// The obvious model is one entry with many attachments, which means a join
  /// table and rewriting every query that touches `attachmentId`. The cheaper
  /// model — and, once you look at it, the more honest one — is that **six
  /// photographs taken in one moment really are six things**, and what the user
  /// is asking for is a *presentation* change, not a data change.
  ///
  /// So each photo stays its own entry, with its own timestamp, its own key and
  /// its own blob. They carry a shared id, and the day view draws consecutive
  /// entries with the same one as a single album tile. Delete one and the
  /// others are untouched. Delete the block and they all go. Nothing else in
  /// the app has to know this column exists.
  ///
  /// Null for everything imported before this, and for anything captured on its
  /// own — which is most things.
  TextColumn get groupId => text().nullable()();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Soft delete. Trash holds for 30 days before a secure purge, so a
  /// mis-tapped delete is recoverable — ETHICAL-DESIGN.md requires destructive
  /// actions to be reversible.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A thread that accumulates across years of days.
class Folders extends Table {
  TextColumn get id => text()();

  /// NULL means root. Self-referencing tree, arbitrary depth.
  TextColumn get parentId => text().nullable()();

  /// Encrypted with the database like everything else, because **folder names
  /// are content**. THREAT-MODEL.md ranks them High: `Dr. Mehta — therapy`
  /// gives away more than the entries inside it.
  TextColumn get name => text()();

  TextColumn get icon => text().nullable()();
  TextColumn get colour => text().nullable()();

  /// Manual ordering, because people care where their folders sit.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The join that makes the whole model work: one entry, many folders, zero
/// duplication.
class EntryFolders extends Table {
  TextColumn get entryId => text().references(Entries, #id)();
  TextColumn get folderId => text().references(Folders, #id)();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {entryId, folderId};
}

/// Metadata for one encrypted file on disk.
class Attachments extends Table {
  /// Also the on-disk filename: `attachments/<id>.enc`. A random UUID and
  /// nothing else — no extension, no hint. Someone browsing the app's storage
  /// sees a flat pile of identically-shaped blobs and cannot tell a voice note
  /// from a photo from a tax PDF.
  TextColumn get id => text()();

  /// This file's own 256-bit key. Safe here precisely because the database it
  /// sits in is encrypted.
  BlobColumn get fileKey => blob()();

  /// The real filename, which lives here rather than on the filesystem.
  TextColumn get originalName => text()();

  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get thumbnailId => text().nullable()();

  /// On-device voice transcription, if it is ever built. The column exists now
  /// so the model does not have to change later — DATA-MODEL.md put it here
  /// deliberately.
  TextColumn get transcript => text().nullable()();

  /// The shape of a voice note, as one byte per sample. Schema v2.
  ///
  /// WHY IT IS STORED RATHER THAN COMPUTED
  ///
  /// A waveform drawn from the audio has to decode the audio, and decoding a
  /// ten-minute AAC file to draw a 60-pixel-wide picture is absurd — it would
  /// happen on every scroll, for every note on the day, on the isolate that
  /// draws the screen. `PLAN.md` §8.1 is explicit: computed **once at record
  /// time**, from the amplitude samples the recorder is already reporting for
  /// the live waveform, and never recomputed.
  ///
  /// One byte per sample, 0–255, downsampled to at most 96 samples. That is
  /// 96 bytes for a note of any length — a rounding error next to the audio —
  /// and 96 bars is more than a phone-width waveform can show anyway.
  ///
  /// Null for every voice note recorded before this column existed, and for
  /// audio files imported from elsewhere. Those draw a flat placeholder rather
  /// than a lie, which is the honest answer to "we do not know the shape".
  BlobColumn get waveform => blob().nullable()();

  /// What this file weighed before Lamplight re-encoded it. Schema v4.
  ///
  /// **ISSUE 12 — "how do I know that the thing is getting compressed?"**
  ///
  /// A fair question, and the honest answer was that he could not know. Photos
  /// and videos have been re-encoded at import since round five, and the only
  /// evidence was a smaller number he had nothing to compare against.
  ///
  /// So the original size is kept. It is one integer per attachment and it
  /// makes the saving *showable*: "2.1 MB, was 14.8 MB" on the file itself, and
  /// a line at the moment of import saying what was saved.
  ///
  /// Null for everything imported before this column existed, and null for
  /// anything that was not re-encoded at all — a PDF, a text file, a GIF. Null
  /// means "no claim", and the app then says nothing rather than implying a
  /// saving of zero. See `humanSaving`.
  IntColumn get originalSize => integer().nullable()();

  /// Where you had got to in this document. Schema v5.
  ///
  /// **ROUND EIGHT, ISSUE 1B** — *"What it misses? Page numbers, it doesn't
  /// remembers what was the last page when I closed that PDF."*
  ///
  /// Zero-based, and null for everything that has never been opened since this
  /// column existed. Null means *start at the beginning*, which is the right
  /// answer for a document nobody has read rather than a guess at one.
  ///
  /// **In the database, and not in settings, and that is a privacy decision.**
  /// The vault's database is encrypted; `settings.json` is not. "Attachment
  /// 9f3e was left on page 212" is a fact about a person's reading, and a
  /// six-hundred-page document left on page 212 says something a
  /// three-page one does not. It is small, and small facts about somebody's
  /// papers are exactly the kind this app has decided not to leave lying about.
  IntColumn get lastPage => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The last ~20 versions of each entry. Cheap insurance.
///
/// For an app whose promise is *a record of your life*, "I accidentally deleted
/// a paragraph" being unrecoverable is not acceptable.
class Revisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryId => text()();
  TextColumn get body => text()();
  IntColumn get savedAt => integer()();
}

/// A one-line summary or marker attached to the day itself rather than to any
/// entry. Created lazily, only if used — DATA-MODEL.md is clear that days are
/// otherwise never rows.
class DayNotes extends Table {
  TextColumn get dayKey => text()();
  TextColumn get body => text().nullable()();
  TextColumn get marker => text().nullable()();

  @override
  Set<Column> get primaryKey => {dayKey};
}

@DriftDatabase(
  tables: [Entries, Folders, EntryFolders, Attachments, Revisions, DayNotes],
)
class VaultDatabase extends _$VaultDatabase {
  VaultDatabase(super.e);

  /// **4 as of 24 August 2026.** v2 added `attachments.waveform` for the voice
  /// note redesign; v3 added `entries.group_id` so photos chosen together can
  /// be drawn as one album; v4 added `attachments.original_size` so the app can
  /// show what compression actually saved (ISSUE 12). All three are nullable
  /// columns on existing tables, which is the only kind of migration this
  /// project intends ever to run.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createSearchIndex();
          await _createIndexes();
        },

        // ── The most dangerous eight lines in the project ──────────────────
        //
        // **An app update must never cost a user their notes.** Not one entry,
        // not once. Someone who has kept a journal here for three years and
        // takes an update from the Play Store must open it to find everything
        // exactly where it was, and any other outcome is the end of the
        // relationship — for them and for everyone they tell.
        //
        // drift's *default* `onUpgrade` throws. Left alone, the first release
        // that bumps [schemaVersion] would fail to open every existing vault on
        // earth, and it would do it after the update had already installed. The
        // absence of this handler was a loaded gun with the safety off, and it
        // was found by someone asking the right question rather than by anything
        // going wrong — which is the only cheap way to find this class of bug.
        //
        // THE RULES FOR WHOEVER ADDS THE NEXT MIGRATION
        //
        //  1. **Only ever add.** New tables, new nullable columns, new indexes.
        //     Never drop a column, never rename one, never change a type. A
        //     column nobody uses costs a few bytes; a dropped column costs
        //     somebody their life's record and cannot be undone.
        //  2. **One `if` per version step, in order, no `else`.** A vault three
        //     versions behind has to walk through every step, so they run one
        //     after another rather than jumping to the newest.
        //  3. **Never touch user rows.** A migration changes the shape of the
        //     database, not what is in it.
        //  4. **Add a test to `migration_test.dart` before the code.** It opens
        //     a vault at the old version, migrates it, and proves the entries
        //     are still there and still readable.
        //  5. **The schema version is a one-way ratchet.** An older build
        //     opening a newer vault is refused below, because the alternative is
        //     an old binary quietly writing rows the new schema cannot read.
        onUpgrade: (m, from, to) async {
          // Foreign keys must be off while the shape changes, or a legal
          // intermediate state can trip a constraint that is about to stop
          // applying. Turned back on in beforeOpen, every time, regardless.
          await customStatement('PRAGMA foreign_keys = OFF');

          // ── v1 → v2: the voice-note waveform ─────────────────────────────
          //
          // A nullable blob added to an existing table, which is the safest
          // migration SQLite has: `ALTER TABLE … ADD COLUMN` rewrites no rows
          // and cannot fail part-way. Every existing voice note gets NULL and
          // draws a flat placeholder, which is honest — we genuinely do not
          // know the shape of a recording made before we started measuring.
          //
          // Deliberately not backfilled. Backfilling would mean decoding every
          // recording in the vault at unlock, on battery, to draw pictures
          // nobody has asked to see yet.
          if (from < 2) {
            await m.addColumn(attachments, attachments.waveform);
          }

          // ── v2 → v3: photo albums ────────────────────────────────────────
          //
          // Same shape, same safety. Everything that already exists gets NULL
          // and keeps being drawn as its own block, which is exactly what it
          // was. Only imports made after this can be grouped.
          if (from < 3) {
            await m.addColumn(entries, entries.groupId);
          }

          // ── v3 → v4: what it weighed before ─────────────────────────────
          //
          // ISSUE 12. Same shape, same safety: a nullable integer, no rows
          // rewritten. Everything already in the vault gets NULL, which the UI
          // reads as "no claim" and says nothing about — rather than as a
          // saving of zero, which would be a number the app cannot back up.
          //
          // Deliberately not backfilled, for the same reason the waveform is
          // not: the original files are gone, so there is nothing to measure.
          if (from < 4) {
            await m.addColumn(attachments, attachments.originalSize);
          }

          // ── v4 → v5: where you had got to in a document ─────────────
          //
          // ROUND EIGHT, ISSUE 1B. A nullable integer, which is the same shape
          // as the two above and the safest migration SQLite has: no rows are
          // rewritten and it cannot fail part-way.
          //
          // Everything already in the vault gets NULL, and null means *open at
          // the beginning* — which is the truth about a document nobody has
          // read yet, rather than a guess at where they might have stopped.
          if (from < 5) {
            await m.addColumn(attachments, attachments.lastPage);
          }

          // The `if (from < n)` form rather than `from == n - 1` is rule 2: a
          // vault last opened two releases ago has to walk every step.

          await customStatement('PRAGMA foreign_keys = ON');
        },

        beforeOpen: (details) async {
          // Foreign keys are OFF by default in SQLite, which surprises people.
          // Without this, deleting a folder would leave orphaned join rows.
          await customStatement('PRAGMA foreign_keys = ON');

          // A vault written by a NEWER build than this one.
          //
          // Happens when someone installs an update, writes something, then
          // rolls back — or restores a backup made by a newer version onto an
          // older install. drift will happily open it and the app would then
          // write rows against a schema it does not understand, quietly
          // corrupting a database that was fine a moment ago.
          //
          // Refusing is the kind thing to do. The message says what to do next,
          // and nothing has been damaged by the time it is shown.
          if (details.versionBefore != null &&
              details.versionBefore! > details.versionNow) {
            throw VaultTooNew(details.versionBefore!, details.versionNow);
          }
        },
      );

  /// FTS5, built now and used later.
  ///
  /// Phase 3 is where search gets a UI, but the index has to exist from schema
  /// version 1 — retrofitting it later means a migration that rebuilds the
  /// index over every entry the user has ever written, on their phone, on
  /// battery. Free to add now, expensive to add in year two.
  Future<void> _createSearchIndex() async {
    await customStatement('''
      CREATE VIRTUAL TABLE entry_search USING fts5(
        body,
        content='entries',
        content_rowid='rowid'
      )
    ''');
    // Triggers keep the index honest without any application code having to
    // remember. A search index maintained by hand is a search index that
    // silently goes stale.
    await customStatement('''
      CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
        INSERT INTO entry_search(rowid, body) VALUES (new.rowid, new.body);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER entries_ad AFTER DELETE ON entries BEGIN
        INSERT INTO entry_search(entry_search, rowid, body)
        VALUES ('delete', old.rowid, old.body);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER entries_au AFTER UPDATE ON entries BEGIN
        INSERT INTO entry_search(entry_search, rowid, body)
        VALUES ('delete', old.rowid, old.body);
        INSERT INTO entry_search(rowid, body) VALUES (new.rowid, new.body);
      END
    ''');
  }

  /// The queries DATA-MODEL.md says the app is made of.
  Future<void> _createIndexes() async {
    // The day view. The single most common query in the app.
    await customStatement('CREATE INDEX idx_entries_day ON entries(day_key)');
    // "On this day, last year" — matching on the month-day suffix.
    await customStatement('CREATE INDEX idx_entries_created ON entries(created_at)');
    // Trash sweeps, and excluding deleted entries from every other query.
    await customStatement('CREATE INDEX idx_entries_deleted ON entries(deleted_at)');
    // Walking the folder tree.
    await customStatement('CREATE INDEX idx_folders_parent ON folders(parent_id)');
    // "Everything about Kavya, chronologically."
    await customStatement('CREATE INDEX idx_entry_folders_folder ON entry_folders(folder_id)');
    await customStatement('CREATE INDEX idx_revisions_entry ON revisions(entry_id, saved_at)');
  }
}

/// This vault was written by a newer version of Lamplight than this one.
///
/// Thrown rather than opened. An older binary writing into a newer schema does
/// not fail loudly — it succeeds, and leaves a database that the newer version
/// can no longer make sense of. The user still has everything at the moment
/// this is thrown, which is the entire point of throwing it.
class VaultTooNew implements Exception, PlainlySaid, Localisable {
  const VaultTooNew(this.vaultVersion, this.appVersion);

  final int vaultVersion;
  final int appVersion;

  /// The English sentence. See `BackupProblem` for why an exception thrown
  /// from `core/` carries both this and [describeIn].
  static const _english =
      'This vault was made by a newer version of Lamplight. Update the app to '
      'open it — your notes are safe and nothing has been changed.';

  @override
  String get plainMessage => _english;

  @override
  String describeIn(L l) => l.vaultDatabaseNewerVersion;

  @override
  String toString() => _english;
}

/// Opens the encrypted database at [path] with a raw 256-bit [key].
///
/// The key is passed as `x'...'` hex so SQLCipher uses it **directly** rather
/// than running its own PBKDF2 over it as though it were a passphrase. That
/// matters: the key already comes from Argon2id via the key hierarchy, and
/// letting SQLCipher stretch it again would be slower and would add a second,
/// weaker KDF to the chain for no benefit.
///
/// [key] must be [KeyPurpose.database] derived from the DEK — never the DEK
/// itself. `SECURITY-ARCHITECTURE.md` §3 step 7: if one subsystem is broken it
/// must not hand over the master key.
/// Returns a Future because opening is **verified**, not merely started.
///
/// drift opens the underlying database lazily — it does no work until the first
/// query. Left alone, that means a wrong key is not discovered at unlock but at
/// whatever query happens to run next, surfacing as an incomprehensible error
/// far from its cause. The unlock flow needs a definitive yes or no, so this
/// runs a probe query before returning. Found by a test that asserted a wrong
/// key must fail at open and caught it silently succeeding.
/// Everything that must happen on a freshly opened connection.
///
/// Its own function rather than an inline closure, because it now runs **inside
/// the worker isolate**. A body that reads clearly at the call site is not the
/// same thing as a body that is safe to send somewhere else, and everything
/// this touches is either passed in or made here.
void _prepare(CommonDatabase db, Uint8List key) {
  // The hex is built HERE, in the isolate that will use it.
  //
  // -- WHY THAT IS A SECURITY IMPROVEMENT AND NOT A DETAIL ------------------
  //
  // This used to run on the UI isolate, before the database existed. A Dart
  // String is immutable: once that hex existed there was no way to overwrite
  // it, and it sat in the heap until a garbage collector happened to reclaim
  // it -- for the whole life of an unlocked session, long after the bytes it
  // came from had been disposed.
  //
  // Built here, it lives only in the worker isolate, which `Vault.lock()`
  // destroys entirely by closing the database. So locking now takes the
  // database's copy of the key with it, rather than leaving an unreachable
  // string on the main heap and hoping.
  final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // Order matters. The key must be set before any other statement, or
  // SQLite tries to read the header as plaintext and fails.
  db.execute('PRAGMA key = "x\'$hex\'"');

  // WAL: a power loss mid-write cannot corrupt the database.
  // SECURITY-ARCHITECTURE.md §5 requires it, and §7's autosave design
  // leans on it — worst case the user loses 400ms of typing.
  db.execute('PRAGMA journal_mode = WAL');

  // Wait rather than failing instantly if another connection holds a
  // lock. Autosave fires on a debounce and can collide with a read.
  db.execute('PRAGMA busy_timeout = 5000');

  // Prove the key was right, here, at open time. Without this the failure
  // surfaces later as an incomprehensible error in whatever query ran
  // first. SQLCipher throws on a wrong key.
  db.execute('SELECT count(*) FROM sqlite_master');
}

/// Runs the database in this isolate instead of a worker. **Tests only.**
///
/// -- WHY THIS EXISTS, AND WHY IT IS NOT A SETTING -------------------------
///
/// `testWidgets` runs its body inside a fake-async zone. A worker isolate
/// delivers its answers on the real event loop, and no amount of pumping or
/// `runAsync` makes a worker-backed *stream* arrive somewhere the fake clock
/// can see it -- measured: a two-second real-time window still produced
/// nothing, so this is structural rather than slow.
///
/// So widget tests that read the vault run the database in-process. That is a
/// limitation of the test harness, not of the app, and the honest way to
/// handle it is one obvious flag rather than quietly making the production
/// path the untested one.
///
/// **The default is the production path.** Nothing in `lib/` ever sets this,
/// and `background_database_test.dart` exercises the worker for real, outside
/// the widget harness, so the shipped behaviour is covered.
bool debugUseInProcessDatabase = false;

Future<VaultDatabase> openVaultDatabase({
  required String path,
  required Uint8List key,
  bool? background,
}) async {
  if (key.length != 32) {
    throw ArgumentError('database key must be 32 bytes, got ${key.length}');
  }

  // Our own copy. [key] belongs to the caller, which wipes it as soon as this
  // returns; this copy is what crosses into the worker and dies with it.
  final keyForWorker = Uint8List.fromList(key);
  final file = File(path);

  // -- THE DATABASE DOES NOT RUN ON THE THREAD THAT DRAWS THE SCREEN --------
  //
  // Every stutter in this app traced back to it doing so. SQLCipher decrypts
  // a page to answer ANY query, so `watchDay`, `summariesBetween`, `search`
  // and every attachment-row miss did real cryptographic work on the isolate
  // that was trying to paint a frame. PLAN.md 9.7 put this first on its own
  // list and said, in bold, that nothing else would make as much difference.
  //
  // `createInBackground` spawns a worker, runs sqlite3 there, and -- drift's
  // own words -- is "stopped when closed". That last part is what makes it
  // safe here rather than merely faster: `Vault.lock()` closes the database,
  // which ends the isolate, which takes its copy of the key with it.
  //
  // `background: false` exists for one reason. A `flutter test` that opens
  // dozens of vaults would otherwise spawn dozens of isolates, and a test
  // that fails inside a worker reports it from somewhere unhelpful. The app
  // never passes it, and `test/db/background_isolate_test.dart` covers the
  // real path so the default is not the untested one.
  final onWorker = background ?? !debugUseInProcessDatabase;
  final executor = onWorker
      ? NativeDatabase.createInBackground(
          file,
          setup: (db) => _prepare(db, keyForWorker),
        )
      : NativeDatabase(
          file,
          setup: (db) => _prepare(db, keyForWorker),
        );

  final db = VaultDatabase(executor);

  // Force the lazy open to happen now, so a wrong key throws here rather than
  // at some unrelated query later. If it fails, close the half-open handle
  // before rethrowing — leaking file handles on every failed unlock attempt
  // would matter, since rate limiting means there will be many.
  try {
    await db.customSelect('SELECT count(*) FROM sqlite_master').get();
  } catch (e, stack) {
    await db.close().catchError((_) {});

    // -- THE WORKER MUST BE INVISIBLE TO CALLERS ---------------------------
    //
    // drift wraps anything thrown inside the worker isolate in a
    // `DriftRemoteException`. Left alone, that quietly breaks every typed
    // failure this file defines: a caller that says `on VaultTooNew` stops
    // matching, and the person opening a vault from a newer build gets a
    // generic error instead of the sentence written for them.
    //
    // Nothing in the app catches VaultTooNew by type *today*, which is
    // exactly why this is worth doing now -- the trap is that it would work
    // until somebody wrote the catch, and then fail in a way that looks like
    // the exception is never thrown at all.
    //
    // Found by `migration_test.dart` on the first run after the move, which
    // is the whole argument for that test existing.
    // A LOOP, not an `if`. drift wraps at both the server and the client
    // layer, so a failure raised inside a migration arrives double-wrapped
    // and unwrapping once still hands the caller a DriftRemoteException.
    // Found the same way as the wrapping itself: migration_test.
    var cause = e;
    var causeStack = stack;
    while (cause is DriftRemoteException) {
      causeStack = cause.remoteStackTrace ?? causeStack;
      cause = cause.remoteCause;
    }
    if (!identical(cause, e)) {
      Error.throwWithStackTrace(cause, causeStack);
    }
    rethrow;
  }
  return db;
}

/// A UUID v4 from the OS CSPRNG.
///
/// No `uuid` package: it is twelve lines, and `TECH-STACK.md` counts every
/// avoided dependency as a security property. [randomBytes] must be
/// `VaultCrypto.randomBytes` — never `Random()`.
String uuidV4(Uint8List Function(int) randomBytes) {
  final b = randomBytes(16);
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant 1
  String hex(int start, int end) =>
      b.sublist(start, end).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
