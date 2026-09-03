import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';

import '../../core/db/database.dart';
import '../../core/db/folder_repository.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../capture/attachment_blocks.dart';
import 'folder_picker.dart';

/// The folders, and what is in them.
///
/// ── WHY THIS IS THE FEATURE THE APP IS FOR ───────────────────────────────
///
/// `00-vision/WHAT-WE-ARE-BUILDING.md` describes the point as "recording
/// things about a particular phase or particular person", and until now the
/// app had no way to express either. Days are how you *write*; folders are how
/// you *read back*. Search finds the entry you remember. Folders hold the ones
/// you have forgotten, which is the far larger set and the whole reason a
/// journal beats a chat with yourself.
///
/// ── AN ENTRY IS LINKED, NEVER MOVED ──────────────────────────────────────
///
/// Nothing here takes anything off its day. That is stated in the picker, it is
/// stated again when a folder is deleted, and it is enforced by the schema —
/// there is a join table and there is no `folder_id` on the entry, so "moving"
/// is not a thing the model can express.
class FoldersScreen extends StatefulWidget {
  const FoldersScreen({
    super.key,
    required this.vault,
    required this.onOpenDay,
  });

  final Vault vault;
  final void Function(DateTime day) onOpenDay;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  late final FolderRepository _repo = FolderRepository(widget.vault.database);

  // ── A STREAM MADE IN `build` IS A NEW SUBSCRIPTION EVERY REBUILD ────────
  //
  // `watch…()` returns a **new** stream each time it is called, and a
  // `StreamBuilder` handed a new stream unsubscribes from the old one, throws
  // away the data it was showing, and starts again with none. Built inside
  // `build`, that happened on every rebuild — a dialog opening above it, a
  // theme change, an ancestor animating — and every one was a fresh query
  // against an encrypted database on a worker isolate, with the loading
  // spinner flashing while it ran.
  //
  // Resolved once, and watched for as long as the screen is alive.
  late final Stream<List<Folder>> _folders = _repo.watchAll();
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final counts = await _repo.counts();
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _create() async {
    final name = await promptForFolderName(context);
    if (name == null || name.trim().isEmpty) return;
    await _repo.create(id: widget.vault.newId(), name: name);
    await _refreshCounts();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: L.of(context).settingsFolders,
      actions: [
        IconButton(
          onPressed: _create,
          icon: const Icon(Icons.create_new_folder_outlined),
          color: c.inkPrimary,
          tooltip: L.of(context).folderNew,
        ),
      ],
      child: StreamBuilder<List<Folder>>(
        stream: _folders,
        builder: (context, snap) {
          final folders = snap.data;
          if (folders == null) {
            return const Padding(
              padding: EdgeInsets.only(top: Space.x10),
              child: Center(child: LampBusy()),
            );
          }
          if (folders.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x4, Space.x6, Space.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Concrete, not abstract. "Organise your content" tells
                    // nobody anything; a person's name tells them exactly what
                    // this is for.
                    L.of(context).folderWhatItIs,
                    style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    L.of(context).folderNothingMoves,
                    style: t.labelMedium?.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: Space.x6),
                  LampButton(
              label: L.of(context).folderMakeFirst, onPressed: _create),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: Space.x10),
            children: [
              for (final f in folders)
                LampTile(
                  title: f.name,
                  subtitle: _describe(L.of(context), _counts[f.id] ?? 0),
                  icon: Icons.folder_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FolderContentsScreen(
                        vault: widget.vault,
                        folder: f,
                        onOpenDay: widget.onOpenDay,
                        onChanged: _refreshCounts,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _describe(L l, int n) =>
      n == 0 ? l.folderNothingInIt : l.countEntries(n);
}

/// One folder's contents, newest first.
class FolderContentsScreen extends StatefulWidget {
  const FolderContentsScreen({
    super.key,
    required this.vault,
    required this.folder,
    required this.onOpenDay,
    required this.onChanged,
  });

  final Vault vault;
  final Folder folder;
  final void Function(DateTime day) onOpenDay;
  final VoidCallback onChanged;

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  late final FolderRepository _repo = FolderRepository(widget.vault.database);

  // ── A STREAM MADE IN `build` IS A NEW SUBSCRIPTION EVERY REBUILD ────────
  //
  // `watch…()` returns a **new** stream each time it is called, and a
  // `StreamBuilder` handed a new stream unsubscribes from the old one, throws
  // away the data it was showing, and starts again with none. Built inside
  // `build`, that happened on every rebuild — a dialog opening above it, a
  // theme change, an ancestor animating — and every one was a fresh query
  // against an encrypted database on a worker isolate, with the loading
  // spinner flashing while it ran.
  //
  // Resolved once, and watched for as long as the screen is alive.
  late final Stream<List<Entry>> _contents =
      _repo.watchContents(widget.folder.id);
  late final AttachmentImporter _importer = AttachmentImporter(widget.vault);
  late String _name = widget.folder.name;

  Future<void> _rename() async {
    final name = await promptForFolderName(context, initial: _name);
    if (name == null || name.trim().isEmpty) return;
    await _repo.rename(widget.folder.id, name);
    widget.onChanged();
    if (mounted) setState(() => _name = name.trim());
  }

  Future<void> _delete() async {
    final c = context.lamplight;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(L.of(context).folderDeleteAsk(_name)),
        content: Text(
          // The sentence that stops this being frightening. Everybody reads
          // "delete folder" as "delete what is inside it", because in every
          // other app it is.
          L.of(context).folderDeleteNote,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(L.of(context).folderKeepIt,
                style: TextStyle(color: c.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(L.of(context).folderDeleteIt,
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.delete(widget.folder.id);
    widget.onChanged();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: _name,
      actions: [
        IconButton(
          onPressed: _rename,
          icon: const Icon(Icons.drive_file_rename_outline),
          color: c.inkPrimary,
          tooltip: L.of(context).folderRename,
        ),
        IconButton(
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
          color: c.inkPrimary,
          tooltip: L.of(context).folderDeleteThis,
        ),
      ],
      child: StreamBuilder<List<Entry>>(
        stream: _contents,
        builder: (context, snap) {
          final entries = snap.data;
          if (entries == null) {
            return const Padding(
              padding: EdgeInsets.only(top: Space.x10),
              child: Center(child: LampBusy()),
            );
          }
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.x6),
              child: Text(
                L.of(context).folderNoneInHere,
                style: t.bodyLarge?.copyWith(color: c.inkMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                Space.x6, 0, Space.x6, Space.x10),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final parts = e.dayKey.split('-');
              final day = DateTime(int.parse(parts[0]), int.parse(parts[1]),
                  int.parse(parts[2]));
              // The date heading repeats only when the day changes, so a
              // folder reads as a sequence of days rather than as a list of
              // rows that each restate the same date.
              final newDay = i == 0 || entries[i - 1].dayKey != e.dayKey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (newDay)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: Space.x6, bottom: Space.x1),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onOpenDay(day);
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: Space.x1),
                          child: Text(
                            _headline(context, day),
                            style: t.labelSmall?.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (e.attachmentId != null)
                    AttachmentBlock(
                      entry: e,
                      importer: _importer,
                      onTap: () {},
                      onLongPress: () => _remove(e),
                    )
                  else
                    InkWell(
                      onLongPress: () => _remove(e),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onOpenDay(day);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Space.x3),
                        child: Text(e.body ?? '',
                            style: writingStyle(context)),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _remove(Entry entry) async {
    await _repo.remove(entry.id, widget.folder.id);
    widget.onChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L.of(context).folderTakenOut(_name)),
        action: SnackBarAction(
          label: L.of(context).actionUndo,
          onPressed: () => _repo.add(entry.id, widget.folder.id),
        ),
      ),
    );
  }

  /// The day heading over a group of entries in a folder.
  ///
  /// Upper-cased in English and left alone by scripts that have no case, which
  /// is correct rather than a gap — `dayToday`'s note says the same thing.
  static String _headline(BuildContext context, DateTime d) =>
      LampDates.dayMonthYear(context, d).toUpperCase();
}
