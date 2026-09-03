import 'package:drift/drift.dart' show Value;

import '../db/database.dart';
import '../vault/vault.dart';

/// What one sweep found and put right.
class SweepResult {
  const SweepResult({required this.strayFiles, required this.strayRows});

  /// Blobs on disk that no row in the database points at.
  final int strayFiles;

  /// Rows in the database whose blob is not on disk.
  final int strayRows;

  bool get isEmpty => strayFiles == 0 && strayRows == 0;

  @override
  String toString() => 'SweepResult(files: $strayFiles, rows: $strayRows)';
}

/// Files with no row, and rows with no file. **`PLAN.md` §7.2.**
///
/// ══ WHY THIS HAS TO EXIST ══════════════════════════════════════════════════
///
/// Storing an attachment is two writes that cannot be one: the blob goes to the
/// filesystem, and the row goes into the encrypted database. There is no
/// transaction spanning both, and there cannot be — SQLite can roll back its
/// own table and it cannot roll back a file.
///
/// So there is a window, and a phone is exactly the machine that lands in it.
/// Being killed for memory while importing a fifty-megabyte video, running out
/// of space between the two writes, a battery dying mid-import — each leaves
/// one half without the other:
///
///   * **A blob with no row** is dead weight. Nothing can ever read it, because
///     its key lived in the row that never landed. It is not a *leak* — it is
///     encrypted under a key that no longer exists anywhere in the universe —
///     but it is space, and on the video sizes he has complained about twice it
///     is a lot of space, held for ever, invisibly.
///
///   * **A row with no blob** is worse, because it is visible. The day view
///     draws a block for it, the block tries to decrypt a file that is not
///     there, and the user gets a broken thing in their own journal with no way
///     to make it go away. `EntryRepository.purge` deleting a row whose blob was
///     already gone was one half of the same bug.
///
/// `AttachmentStore.listIds` has existed since the first schema, with a comment
/// saying it is "used to find orphans". Nothing used it. This is the thing that
/// was supposed to.
///
/// ══ WHAT IT DELIBERATELY WILL NOT DO ═══════════════════════════════════════
///
/// **It never deletes a row that has a file, and it never deletes a file that
/// has a row.** That sounds obvious and it is the entire safety property, so it
/// is written here and asserted in `orphan_sweep_test.dart` rather than left as
/// something the reader has to convince themselves of by reading the loops.
///
/// **A row with no blob is emptied, not removed.** The attachment row goes,
/// because it describes a file that does not exist; the *entry* stays, with its
/// `attachmentId` cleared, because the entry may carry a caption somebody wrote
/// and a day they wrote it on — and losing those to tidy up after a crash would
/// be the app destroying the only part that survived. What is left reads as a
/// note whose picture is gone, which is true.
///
/// **It runs once per unlock, and never during one.** Listing a directory and
/// reading one column is cheap, but it is I/O on the frame budget of the moment
/// the vault opens — which is the moment the app most needs to feel instant. It
/// is called after the first frame, and everything it does is a `Future`.
abstract final class OrphanSweep {
  /// Looks for both kinds of orphan and puts them right.
  ///
  /// Safe to call as often as you like. On a healthy vault it is one directory
  /// listing, one column read, and no writes at all.
  static Future<SweepResult> run(Vault vault) async {
    if (!vault.isUnlocked) return const SweepResult(strayFiles: 0, strayRows: 0);

    final db = vault.database;
    final store = vault.attachments;

    // Both sides, read before anything is written. A sweep that deleted as it
    // walked could act on a half-read picture of the world, and the half it had
    // not read yet is somebody's photograph.
    final onDisk = store.listIds().toSet();
    final rows = await db.select(db.attachments).get();
    final known = <String>{for (final row in rows) row.id};

    // ── Blobs nothing points at ────────────────────────────────────────────
    var strayFiles = 0;
    for (final id in onDisk) {
      if (known.contains(id)) continue;
      try {
        // The same overwrite-then-unlink every other deletion uses. A blob
        // whose key is gone is already unreadable; this is defence in depth and
        // costs nothing on a file nobody wanted.
        await store.delete(id);
        strayFiles++;
      } catch (_) {
        // A file another process holds open, a permission that changed. Leaving
        // it is the correct outcome — it will be found again next time, and a
        // sweep that throws is a sweep that stops the app unlocking.
      }
    }

    // ── Rows whose file never landed ───────────────────────────────────────
    var strayRows = 0;
    for (final row in rows) {
      if (onDisk.contains(row.id)) continue;
      try {
        // The entry keeps its words and its day; only the pointer to a file
        // that does not exist goes. See the note above.
        await (db.update(db.entries)
              ..where((e) => e.attachmentId.equals(row.id)))
            .write(const EntriesCompanion(attachmentId: Value(null)));
        // And anything that pointed at it as a thumbnail, which is the poster
        // frame of a video and the small copy of a photograph. Left behind,
        // these are the grey box all over again.
        await (db.update(db.attachments)
              ..where((a) => a.thumbnailId.equals(row.id)))
            .write(const AttachmentsCompanion(thumbnailId: Value(null)));
        await (db.delete(db.attachments)..where((a) => a.id.equals(row.id)))
            .go();
        strayRows++;
      } catch (_) {
        // Same reasoning as above.
      }
    }

    return SweepResult(strayFiles: strayFiles, strayRows: strayRows);
  }
}
