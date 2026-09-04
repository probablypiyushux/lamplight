import 'package:drift/drift.dart';

import 'database.dart';
import 'vault_changed.dart';

/// Threads that accumulate across years of days.
///
/// ── WHAT A FOLDER IS HERE, AND WHAT IT IS NOT ────────────────────────────
///
/// `00-vision/WHAT-WE-ARE-BUILDING.md` says the point of this app is
/// "recording things about a particular phase or particular person". Folders
/// are that, and the join table has been sitting in the schema since day one
/// waiting for them.
///
/// **A folder is a link, never a move.** Adding an entry to *Kavya* does not
/// take it off 4 March; it is on 4 March forever and it is also in Kavya. That
/// is the single idea the whole model rests on, and it is why there is a join
/// table rather than a `folder_id` column on the entry. Get it wrong and the
/// app becomes a file manager, where filing something means it is no longer
/// where it happened — which is the thing every note app does and the reason
/// none of them work as a record of a life.
///
/// The one-time sentence in the picker teaches exactly this: *"Still on 4
/// March. Also in Kavya."*
///
/// ── FOLDER NAMES ARE CONTENT ─────────────────────────────────────────────
///
/// `THREAT-MODEL.md` ranks them High and it is right: `Dr Mehta — therapy`
/// gives away more than most of the entries inside it. They live in the
/// encrypted database like everything else and there is no index, no export
/// and no place they are written in the clear.
class FolderRepository {
  FolderRepository(this._db);

  final VaultDatabase _db;

  /// Every folder, ordered the way the user arranged them, then by name.
  Stream<List<Folder>> watchAll() {
    return (_db.select(_db.folders)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<List<Folder>> all() {
    return (_db.select(_db.folders)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// How many live entries each folder holds.
  ///
  /// One query for the whole list. A folder screen asking per folder is N
  /// round trips through SQLCipher before the first frame.
  Future<Map<String, int>> counts() async {
    final rows = await _db.customSelect(
      'SELECT ef.folder_id AS fid, COUNT(*) AS n '
      'FROM entry_folders ef '
      'JOIN entries e ON e.id = ef.entry_id '
      'WHERE e.deleted_at IS NULL '
      'GROUP BY ef.folder_id',
      readsFrom: {_db.entryFolders, _db.entries},
    ).get();
    return {for (final r in rows) r.read<String>('fid'): r.read<int>('n')};
  }

  /// Everything in one folder, newest day first.
  ///
  /// Chronological rather than by when it was filed, because the folder is a
  /// story and a story has an order. Filing something six months later should
  /// put it where it happened, not at the top.
  Stream<List<Entry>> watchContents(String folderId) {
    final query = _db.select(_db.entries).join([
      innerJoin(_db.entryFolders,
          _db.entryFolders.entryId.equalsExp(_db.entries.id)),
    ])
      ..where(_db.entryFolders.folderId.equals(folderId))
      ..where(_db.entries.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(_db.entries.createdAt)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(_db.entries)).toList());
  }

  /// Which folders every entry on one day is in, live, by entry id.
  ///
  /// ── WHY THE DAY NEEDS THIS AND DID NOT HAVE IT ────────────────────────────
  ///
  /// `PLAN.md` §9.1 calls folders *"the thing the app is for"*, and until now
  /// filing something was **invisible the moment the sheet closed**. The entry
  /// looked exactly as it had before. The only way to find out whether an entry
  /// was in *Kavya* was to open the menu and open the picker and look at the
  /// ticks — which is to say, the app asked you to remember what you had told
  /// it, which is the one thing this app exists not to do.
  ///
  /// One query for the whole day rather than one per entry. A day of forty
  /// photographs asking forty questions is forty round trips into SQLCipher
  /// before the first frame.
  ///
  /// Entries that are not filed anywhere are simply absent from the map, so a
  /// missing key means "not filed" and no caller has to tell that apart from an
  /// empty list.
  Stream<Map<String, List<String>>> watchNamesForDay(String dayKey) {
    return _db
        .customSelect(
          'SELECT ef.entry_id AS entry_id, f.name AS name '
          'FROM entry_folders ef '
          'JOIN folders f ON f.id = ef.folder_id '
          'JOIN entries e ON e.id = ef.entry_id '
          'WHERE e.day_key = ?1 AND e.deleted_at IS NULL '
          'ORDER BY f.sort_order, f.name',
          variables: [Variable<String>(dayKey)],
          readsFrom: {_db.entryFolders, _db.folders, _db.entries},
        )
        .watch()
        .map((rows) {
      final out = <String, List<String>>{};
      for (final r in rows) {
        (out[r.read<String>('entry_id')] ??= []).add(r.read<String>('name'));
      }
      return out;
    });
  }

  /// Which folders one entry is in.
  Future<Set<String>> foldersFor(String entryId) async {
    final rows = await (_db.select(_db.entryFolders)
          ..where((t) => t.entryId.equals(entryId)))
        .get();
    return rows.map((r) => r.folderId).toSet();
  }

  Future<Folder> create({
    required String id,
    required String name,
    String? parentId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = FoldersCompanion.insert(
      id: id,
      name: name.trim(),
      parentId: Value(parentId),
      createdAt: now,
    );
    await _db.into(_db.folders).insert(row);
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
    return (_db.select(_db.folders)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.folders)..where((t) => t.id.equals(id)))
        .write(FoldersCompanion(name: Value(name.trim())));
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }

  /// Removes the folder and every link into it.
  ///
  /// **No entry is deleted.** That is the whole point of a link: deleting the
  /// shelf does not burn the books. The confirmation says so in those words,
  /// because "delete folder" reads as "delete what is in it" to anybody who
  /// has used a computer.
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.entryFolders)..where((t) => t.folderId.equals(id)))
          .go();
      await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
    });
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }

  Future<void> add(String entryId, String folderId) async {
    await _db.into(_db.entryFolders).insertOnConflictUpdate(
          EntryFoldersCompanion.insert(
            entryId: entryId,
            folderId: folderId,
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }

  Future<void> remove(String entryId, String folderId) async {
    await (_db.delete(_db.entryFolders)
          ..where((t) => t.entryId.equals(entryId))
          ..where((t) => t.folderId.equals(folderId)))
        .go();
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }

  /// Sets exactly which folders an entry belongs to, in one transaction.
  ///
  /// The picker collects every tick and applies them on close rather than
  /// writing per tap — so a person who ticks four boxes and changes their mind
  /// about two has produced one change, not six, and the undo story is simple.
  Future<void> setMembership(String entryId, Set<String> folderIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await (_db.delete(_db.entryFolders)..where((t) => t.entryId.equals(entryId)))
          .go();
      for (final id in folderIds) {
        await _db.into(_db.entryFolders).insert(
              EntryFoldersCompanion.insert(
                entryId: entryId,
                folderId: id,
                addedAt: now,
              ),
            );
      }
    });
    // The vault changed, so a backup is owed. See `vault_changed.dart`.
    VaultChanged.mark();
  }
}
