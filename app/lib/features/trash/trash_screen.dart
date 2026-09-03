import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../core/media/encrypted_image.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/storage/attachment_store.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// The trash. Thirty days, then gone.
///
/// WHY THIS SCREEN HAS TO EXIST
///
/// `DATA-MODEL.md` gave entries a `deletedAt` column and described a 30-day
/// hold, and `ETHICAL-DESIGN.md` requires destructive actions to be reversible.
/// Without a screen, "reversible" was a column in a database that no user could
/// reach — the entry was gone as far as anyone could tell, and the promise was
/// technically kept and practically broken.
///
/// The undo on the day view catches the mis-tap you notice immediately. This
/// catches the one you notice on Thursday.
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key, required this.vault});

  final Vault vault;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
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
  late final EntryRepository _repo = EntryRepository(
    widget.vault.database,
    attachments: widget.vault.attachments,
  );
  late final AttachmentImporter _importer = AttachmentImporter(widget.vault);
  late final Stream<List<Entry>> _trash = _repo.watchTrash();

  @override
  Widget build(BuildContext context) {
    // ── `attachments:` was missing, and it was a real leak of space ────────
    //
    // `EntryRepository.purge` deletes an attachment's blob through
    // `_attachments?.delete(...)`, and this screen built the repository without
    // a store — so the null-aware call did nothing. Emptying the trash by hand,
    // and the thirty-day purge when it ran from here, deleted the rows and left
    // every encrypted blob on disk for good.
    //
    // Not a confidentiality problem: the blob is encrypted with a file key that
    // was just deleted with its row, so it is unreadable by anybody including
    // us. It is a *size* problem, and it compounds — the files never go, and
    // ISSUE 4 is him telling us a single minute of video is a hundred
    // megabytes.
    final repo = _repo;
    final importer = _importer;
    return LampPage(
      title: L.of(context).settingsTrash,
      subtitle: L.of(context).trashNote,
      child: StreamBuilder<List<Entry>>(
        stream: _trash,
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (entries.isEmpty) return const _TrashEmpty();
          return ListView(
            padding: const EdgeInsets.only(bottom: Space.x10),
            children: [
              LampGroup(
                children: [
                  for (final e in entries)
                    _TrashRow(entry: e, repo: repo, importer: importer),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x6),
                child: TextButton(
                  onPressed: () => _confirmEmpty(context, repo, entries),
                  child: Text(
                    L.of(context).trashEmpty,
                    style: TextStyle(color: context.lamplight.danger),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    EntryRepository repo,
    List<Entry> entries,
  ) async {
    final c = context.lamplight;
    // A dialog, not a sheet, and not an undo. This is the one action in the
    // app that genuinely cannot be taken back, so it gets the one interruption
    // pattern reserved for exactly that.
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L.of(context).trashConfirm),
        content: Text(
          L.of(context).trashConfirmBody(entries.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(L.of(context).trashKeep, style: TextStyle(color: c.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(L.of(context).trashDeleteForGood, style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final e in entries) {
      await repo.purge(e.id);
    }
  }
}

/// One deleted thing, drawn as the thing it is. **ISSUE 11.**
///
/// It used to be one `Text` showing `entry.body`, falling back to the words
/// "Empty entry" when there were none. Every photograph, video, GIF, recording
/// and document has no body, so the trash was a list of identical grey rows
/// saying "Empty entry" — he screenshotted it and wrote *"it's shown whenever
/// photos, videos, GIFs, documents"*, and then what he wanted instead:
/// *"I want the photos, videos, GIFs, documents to be visible."*
///
/// The point is not decoration. A trash you cannot read is a trash you cannot
/// use — `ETHICAL-DESIGN.md` requires destructive actions to be reversible, and
/// an undo you cannot aim is reversible only in the sense that the database
/// row still exists. Restoring the right thing required remembering the order
/// you deleted things in.
///
/// So: a thumbnail for anything with a picture, a glyph for anything without,
/// and a name for all of it. Videos use their poster frame, which already
/// exists as a second encrypted attachment (ISSUE 8) and costs nothing new.
class _TrashRow extends StatefulWidget {
  const _TrashRow({
    required this.entry,
    required this.repo,
    required this.importer,
  });

  final Entry entry;
  final EntryRepository repo;
  final AttachmentImporter importer;

  @override
  State<_TrashRow> createState() => _TrashRowState();
}

class _TrashRowState extends State<_TrashRow> {
  Attachment? _attachment;

  /// A video's poster frame. Null for everything else.
  Attachment? _poster;

  Entry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Through the importer's cache, which is the same one the day view uses, so
  /// a trash full of photographs costs cached lookups rather than a query per
  /// row per rebuild.
  Future<void> _load() async {
    final id = entry.attachmentId;
    if (id == null) return;
    final row = await widget.importer.attachmentById(id);
    if (!mounted || row == null) return;
    setState(() => _attachment = row);

    final posterId = row.thumbnailId;
    if (posterId == null) return;
    final poster = await widget.importer.attachmentById(posterId);
    if (mounted && poster != null) setState(() => _poster = poster);
  }

  /// What to call this thing when there are no words to show.
  ///
  /// A GIF is called a GIF rather than a photo, because he listed it
  /// separately and because to anybody who saved one it is a different object.
  String _kindIn(L l) {
    final a = _attachment;
    final mime = (a?.mimeType ?? '').toLowerCase();
    final name = (a?.originalName ?? '').toLowerCase();
    if (mime == 'image/gif' || name.endsWith('.gif')) return 'GIF';
    return switch (entry.type) {
      'photo' => l.kindPhoto,
      'video' => l.kindVideo,
      'voice' => l.kindRecording,
      'file' =>
        a?.originalName.isNotEmpty == true ? a!.originalName : l.kindFile,
      _ => l.trashEmptyEntry,
    };
  }

  IconData get _glyph => switch (entry.type) {
        'voice' => Icons.mic_none_outlined,
        'video' => Icons.videocam_outlined,
        'photo' => Icons.photo_outlined,
        'file' => Icons.description_outlined,
        _ => Icons.notes_outlined,
      };

  /// The picture to draw, if there is one: the photo itself, or a video's
  /// poster frame. Null for a recording, a document, or words.
  Attachment? get _picture {
    if (entry.type == 'video') return _poster;
    if (entry.type == 'photo') return _attachment;
    // A file that happens to be an image — a PNG picked through the file
    // picker rather than the photo picker — is still worth showing.
    final mime = (_attachment?.mimeType ?? '').toLowerCase();
    if (mime.startsWith('image/')) return _attachment;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(entry.deletedAt ?? 0);
    final daysLeft = 30 - DateTime.now().difference(deletedAt).inDays;
    final body = (entry.body ?? '').trim();
    final hasAttachment = entry.attachmentId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x5, Space.x4, Space.x3, Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAttachment) ...[
                _TrashThumbnail(
                  picture: _picture,
                  glyph: _glyph,
                  store: widget.importer.vault.attachments,
                ),
                const SizedBox(width: Space.x4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Words win when there are any — a photograph with a
                      // caption is best identified by its caption. The kind is
                      // the fallback, and "Empty entry" survives only for an
                      // entry that genuinely is one.
                      body.isNotEmpty ? body : _kindIn(L.of(context)),
                      style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // When there are words AND an attachment, say what the
                    // attachment was too, so a caption does not hide a photo.
                    if (body.isNotEmpty && hasAttachment) ...[
                      const SizedBox(height: Space.x1),
                      Text(
                        _kindIn(L.of(context)),
                        style: t.labelMedium?.copyWith(color: c.inkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          Row(
            children: [
              Expanded(
                child: Text(
                  // The day it was written, then how long is left. Both matter:
                  // one tells you which entry this is, the other tells you how
                  // long you have to decide.
                  '${entry.dayKey} · '
                  '${daysLeft <= 0 ? L.of(context).trashGoneToday : L.of(context).trashDaysLeft(daysLeft)}',
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await widget.repo.restore(entry.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                content: Text(L.of(context).trashPutBackOn(entry.dayKey))),
                  );
                },
                child: Text(L.of(context).trashPutBack,
                style: TextStyle(color: c.accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small square: the picture if there is one, its glyph if not.
///
/// 56 points, which is the row's own rhythm rather than a new number, and
/// decoded at exactly that size times the device ratio — decoding a twelve
/// megapixel photograph to draw it at 56 points is the mistake
/// `EncryptedImage.maxWidth` exists to prevent.
class _TrashThumbnail extends StatelessWidget {
  const _TrashThumbnail({
    required this.picture,
    required this.glyph,
    required this.store,
  });

  final Attachment? picture;
  final IconData glyph;
  final AttachmentStore store;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final image = picture;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: SizedBox(
        width: _size,
        height: _size,
        child: image == null
            ? ColoredBox(
                color: c.raised,
                child: Icon(glyph, size: 22, color: c.inkMuted),
              )
            : Image(
                image: EncryptedImage(
                  image,
                  store: store,
                  maxWidth:
                      (_size * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // A thumbnail that failed to decrypt must not take the row with
                // it. The glyph is the honest fallback.
                errorBuilder: (context, _, _) => ColoredBox(
                  color: c.raised,
                  child: Icon(glyph, size: 22, color: c.inkMuted),
                ),
              ),
      ),
    );
  }
}

class _TrashEmpty extends StatelessWidget {
  const _TrashEmpty();

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x6),
      child: Text(
        L.of(context).trashNothingHere,
        style: t.bodyLarge?.copyWith(color: c.inkMuted),
      ),
    );
  }
}
