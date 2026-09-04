import 'package:flutter/material.dart';
import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/attachment_importer.dart';
import '../../design/linked_text.dart';
import '../../design/tokens.dart';
import '../../core/media/encrypted_image.dart';
import '../media/media_album.dart';
import '../media/video_viewer.dart';
import 'transcription_queue.dart';
import 'voice_note.dart';

/// How a photo, a voice note, a video and a document appear in the day.
///
/// THE RULE ALL FOUR OBEY
///
/// **Nothing is ever decrypted to a file.** A photo is decrypted into memory
/// and decoded straight into a texture; a voice note and a video are decrypted
/// into memory and handed to a platform player reading from a byte array; a
/// document is not opened at all — it is described, and exporting a copy is an
/// explicit act that writes to a place the user chose, outside the vault.
///
/// The obvious implementation of each of these is a temp file and a path. Each
/// one is one line shorter and each one puts the user's material back on disk
/// in the clear. `CLAUDE.md` rule 2 has no exception for "briefly, for display".
///
/// ── WHY THE METADATA IS NOT FETCHED IN `build` ANY MORE ──────────────────
///
/// It used to be `FutureBuilder(future: importer.attachmentFor(entry), …)`,
/// which starts a database query **on every rebuild** — and a rebuild happens
/// on every keystroke in the composer, because the day is one widget. Twenty
/// attachments and a fast typist was a few hundred SQLCipher round trips a
/// second, every one of them decrypting a page, all on the isolate drawing the
/// screen.
///
/// The row is now cached the first time it is read and served synchronously
/// afterwards ([AttachmentImporter.cachedAttachment]), so a rebuild costs a map
/// lookup. The future is only reached on a genuine first sight.
class AttachmentBlock extends StatefulWidget {
  const AttachmentBlock({
    super.key,
    required this.entry,
    required this.importer,
    required this.onTap,
    this.onSaveCopy,
    required this.onLongPress,
    this.onSaveEntry,
    this.onTrashEntry,
    this.onOpenEntryWith,
    this.onCaption,
    this.transcripts,
    this.settings,
    this.bare = false,
  });

  final Entry entry;
  final AttachmentImporter importer;
  final VoidCallback onTap;

  /// Offered where the app has to refuse — a clip this phone cannot decode, or
  /// one too large to hold in memory. ISSUE 10: a refusal with nothing to do
  /// about it is the same defect as silence, one politeness removed.
  final VoidCallback? onSaveCopy;
  final VoidCallback onLongPress;

  /// **ISSUE D**, straight through to the viewer's three-dot menu.
  final void Function(Entry)? onSaveEntry;
  final void Function(Entry)? onTrashEntry;

  /// **ISSUE 4, 13.** Lend this attachment to another app for as long as
  /// somebody is looking at it.
  final void Function(Entry)? onOpenEntryWith;

  /// Opens the editor on the entry that carries an album's caption.
  /// **`PLAN.md` §9.7** — see `MediaAlbum.onCaption`.
  final void Function(Entry)? onCaption;

  /// What is being written down, and why nothing is. **Round ten.**
  ///
  /// Straight through to the voice player's one row — see `_TranscriptRow`.
  /// Absent inside the editor, where the block is drawn `bare` and a status
  /// line under a note you are editing would be noise.
  final TranscriptionQueue? transcripts;
  final AppSettings? settings;

  /// Just the content — no timestamp, no accent rule, no tap handling.
  ///
  /// Used inside the editor, where the block's own chrome would be drawn twice
  /// and where tapping the photograph should not open a menu on top of the
  /// keyboard you are typing into.
  final bool bare;

  @override
  State<AttachmentBlock> createState() => _AttachmentBlockState();
}

class _AttachmentBlockState extends State<AttachmentBlock> {
  Attachment? _attachment;

  @override
  void initState() {
    super.initState();
    // Synchronous on every sight after the first, which is what stops a scroll
    // costing a query per photograph.
    _attachment =
        AttachmentImporter.cachedAttachment(widget.entry.attachmentId);
    if (_attachment == null) _fetch();
  }

  @override
  void didUpdateWidget(AttachmentBlock old) {
    super.didUpdateWidget(old);
    if (old.entry.attachmentId != widget.entry.attachmentId) {
      _attachment =
          AttachmentImporter.cachedAttachment(widget.entry.attachmentId);
      _thumbnail = null;
      if (_attachment == null) {
        _fetch();
      } else {
        // ISSUE 3. The row was in the cache, so `_fetch` never runs — and the
        // thumbnail pass lives inside it. This is the path a scrolled-back-to
        // photograph takes, which is why the grey box came and went as you
        // moved up and down the day.
        _fetchThumbnail(_attachment!);
      }
    }
  }

  /// The small copy, when this block is a photograph that has one.
  ///
  /// **ROUND EIGHT, ISSUE 3 — and this field is the whole bug.**
  Attachment? _thumbnail;

  Future<void> _fetch() async {
    final row = await widget.importer.attachmentFor(widget.entry);
    if (mounted) setState(() => _attachment = row);
    if (row != null) await _fetchThumbnail(row);
  }

  /// ══ ROUND EIGHT, ISSUE 3 — THE GREY BOX ══════════════════════
  ///
  /// *"Some times it works sometimes it doesn't — photos clicked via mobile
  /// camera? They suffer **having** a thumbnail! It looks like a grey box!"*
  ///
  /// He diagnosed it in that sentence and I do not think he knew: the
  /// photographs that failed were the ones that **had** a thumbnail.
  ///
  /// A lone photograph is drawn as an album of one — one layout engine rather
  /// than two that have to be kept looking alike — and it was handed
  /// `{attachment.id: attachment}`, which is the original and nothing else.
  /// Round seven then taught `MediaAlbum.pictureIdFor` to prefer
  /// `thumbnailId`, and that call site was never told. So the tile asked the
  /// map for a thumbnail row that had never been put in it, got null, and drew
  /// its empty background: a grey box.
  ///
  /// The intermittency was the tell, and it was not random. A photograph only
  /// gets a thumbnail above `THUMB_WORTH_IT`; below it the file is its own
  /// thumbnail, `thumbnailId` is null, `pictureIdFor` falls back to the
  /// original, and the tile draws perfectly. **Small pictures worked and camera
  /// photographs did not**, every single time, which is exactly the population
  /// he described.
  ///
  /// The album block already does this pass for videos and has since ISSUE 8.
  /// This is the same pass, in the one place that was not an album.
  Future<void> _fetchThumbnail(Attachment row) async {
    final id = row.thumbnailId;
    if (id == null) return;
    final cached = AttachmentImporter.cachedAttachment(id);
    if (cached != null) {
      if (mounted) setState(() => _thumbnail = cached);
      return;
    }
    final loaded = await widget.importer.attachmentById(id);
    if (loaded != null && mounted) setState(() => _thumbnail = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final at = DateTime.fromMillisecondsSinceEpoch(widget.entry.createdAt).toLocal();
    final time = LampDates.time(context, at);
    final attachment = _attachment;
    // ISSUE 3. Both rows go to the album, so a photograph with a thumbnail has
    // one to draw. `?..` rather than a branch: a picture with no thumbnail
    // hands over a map of one, exactly as it always did.
    final rows = <String, Attachment>{
      ?attachment?.id: ?attachment,
      ?_thumbnail?.id: ?_thumbnail,
    };

    if (widget.bare) {
      return attachment == null
          ? _Placeholder(type: widget.entry.type)
          : _content(context, attachment, rows);
    }

    return Semantics(
      button: true,
      label: _semanticLabel(context, attachment, time),
      // The caption, for the same reason `entry_block.dart` carries one -- and
      // found in the same hour, because the first fix was scoped to entry
      // blocks and this is the sibling file.
      //
      // The comment forty lines down already says it: *"the words under a
      // photograph or a recording are the user's own writing as much as an
      // entry is"*. `excludeSemantics` was quietly disagreeing with it. A
      // person using TalkBack heard "Photo, 12:21" and never the sentence they
      // had written underneath.
      value: widget.entry.body ?? '',
      excludeSemantics: true,
      child: InkWell(
        // ── The bug this line is ────────────────────────────────────────
        //
        // There was no `onTap` here at all, so a document chip was
        // completely inert. Reported as "no document opens", and it was worse
        // than that: nothing happened, so there was no way to tell a broken
        // feature from a missing one.
        //
        // Round four found that fixing the tap had not fixed the report — it
        // opened the entry *menu*, which offered "save a copy" and nothing
        // about opening. It opens the document now. See `DocumentViewer`.
        //
        // Photos and videos put their own `GestureDetector` inside this and
        // win the tap, so they are unaffected.
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.only(
              top: Space.x5, bottom: Space.x1, right: Space.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: 20,
                margin: const EdgeInsets.only(top: 4, right: Space.x3),
                color: c.accent.withValues(alpha: 0.45),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time, style: t.labelMedium),
                    const SizedBox(height: Space.x2),
                    if (attachment == null)
                      _Placeholder(type: widget.entry.type)
                    else
                      _content(context, attachment, rows),
                    if ((widget.entry.body ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: Space.x2),
                      // ISSUE 11. The words under a photograph or a recording
                      // are the user's own writing as much as an entry is.
                      LinkedText(widget.entry.body!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    Attachment attachment,
    Map<String, Attachment> rows,
  ) =>
      switch (widget.entry.type) {
        // A lone photograph is an album of one, so there is one layout engine
        // rather than two that have to be kept looking alike.
        'photo' => MediaAlbum(
            entries: [widget.entry],
            // ISSUE 3. The original **and** its thumbnail. This was
            // `{attachment.id: attachment}`, and that missing second entry is
            // the entire grey-box bug — see `_fetchThumbnail`.
            attachments: rows,
            store: widget.importer.vault.attachments,
            onMenu: widget.onLongPress,
            onCaption: widget.onCaption,
            onSaveEntry: widget.onSaveEntry,
            onTrashEntry: widget.onTrashEntry,
            onOpenEntryWith: widget.onOpenEntryWith,
          ),
        'voice' => VoiceNotePlayer(
            attachment: attachment,
            importer: widget.importer,
            transcripts: widget.transcripts,
            settings: widget.settings,
          ),
        'video' => _Video(
            attachment: attachment,
            importer: widget.importer,
            onOpenEntryWith: widget.onOpenEntryWith,
            onSaveCopy: widget.onSaveCopy,
            entry: widget.entry,
            onSaveEntry: widget.onSaveEntry,
            onTrashEntry: widget.onTrashEntry,
          ),
        _ => _FileChip(attachment: attachment),
      };

  /// What a screen reader says about this block.
  ///
  /// Localised on 29 August 2026. These were English literals, which meant a
  /// blind reader got English in all ten languages — the one group of users for
  /// whom the label *is* the interface, and the only ones who could not work
  /// around it by looking at the picture.
  ///
  /// `humanDuration` here is the `4:07` clock form from `attachment_importer`,
  /// not the sentence form in `plain_words`. It is digits and a colon, so it
  /// carries across languages unchanged.
  String _semanticLabel(BuildContext context, Attachment? a, String time) {
    final l = L.of(context);
    if (a == null) return l.attachmentLoading(time);
    String length(Attachment a) => a.durationMs == null
        ? l.lengthUnknown
        : humanDuration(a.durationMs!);
    return switch (widget.entry.type) {
      'photo' => l.photoSemantic(time),
      'video' => l.videoSemantic(time, length(a)),
      'voice' => l.voiceSemantic(time, length(a)),
      _ => l.fileSemantic(time, a.originalName, humanSize(a.byteSize)),
    };
  }
}

/// While the metadata is being read for the very first time.
///
/// A shaped, shimmering block rather than a grey rectangle. The shape is the
/// promise — a wide box for a photo, a short bar for a voice note — so the
/// layout does not jump when the real thing arrives, which is the single most
/// irritating thing a loading list does.
class _Placeholder extends StatefulWidget {
  const _Placeholder({required this.type});

  final String type;

  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Under reduced motion it is a still block. The information — "something
      // is arriving here" — is carried by the shape, not by the shimmer.
      if (!MediaQuery.disableAnimationsOf(context)) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    // ── A PLACEHOLDER'S JOB IS TO BE THE RIGHT SIZE ───────────────────────
    //
    // 31 August 2026, and the second half of "the page jerks with two or more
    // videos". A video block is an `AspectRatio`, so at a day column's width a
    // landscape clip settles at about **202** points — and this reserved a flat
    // **180**, guaranteeing a 22-point shove the moment the real block arrived.
    // A placeholder that is not the size of the thing it stands in for is a
    // layout shift with a shimmer on it.
    //
    // 16:9 is not a guess here; it is what `_Video._reserve` falls back to and
    // what a phone records by default, so the common clip lands at exactly the
    // height this held open. A portrait clip still moves — nothing knows its
    // shape until its row is read — but it moves once, before the poster, and
    // the poster no longer moves it a second time. See `_VideoState._ratio`.
    final ratio = switch (widget.type) {
      'video' => kVideoBoxFallbackRatio,
      _ => null,
    };
    final height = switch (widget.type) {
      'photo' => 200.0,
      'voice' => 70.0,
      _ => 64.0,
    };
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // A slow sweep of slightly lighter surface across the block. Very
        // faint: this is a placeholder, not an event.
        final t = _c.value;
        final block = Container(
          height: ratio == null ? height : null,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t - 0.6, 0),
              end: Alignment(-1 + 2 * t + 0.6, 0),
              colors: [c.raised, c.surface, c.raised],
            ),
          ),
        );
        return ratio == null
            ? block
            : AspectRatio(aspectRatio: ratio, child: block);
      },
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_glyphFor(attachment.mimeType), size: 22, color: c.inkSecondary),
          const SizedBox(width: Space.x3),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.originalName,
                  style: t.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(humanSize(attachment.byteSize),
                    style: t.labelMedium?.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _glyphFor(String mime) {
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.startsWith('video/')) return Icons.movie_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.startsWith('text/')) return Icons.description_outlined;
    if (mime.contains('zip') || mime.contains('compressed')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

/// The shape a video block holds open, or null for a clip with no poster.
///
/// **Derived from the video's own row and never from the poster's**, which is
/// the whole of the fix for "the page jerks with two or more videos" — see
/// `_VideoState._ratio` for what was happening and why. `width` and `height`
/// are written on the video in the same `AttachmentsCompanion.insert` that
/// writes `thumbnailId`, from one `MediaFacts`, so a clip with a poster on the
/// way has always had its shape in hand synchronously.
///
/// Public, and a function rather than four lines inside a `State`, for the same
/// reason `MediaAlbum.pictureIdFor` is: it is short enough to read like an
/// accident, and tidying it back to *"use the poster's dimensions, they are
/// right there"* would restore the jerk without failing anything. Now it fails
/// `test/media/video_block_reserves_its_height_test.dart`.
double? videoBoxRatio(Attachment a) {
  // Null decided synchronously too, from the row in hand, so a clip imported
  // before poster frames existed picks the old file row on the first frame and
  // also never moves.
  if (a.thumbnailId == null) return null;
  final w = a.width;
  final h = a.height;
  // 16:9 for the vanishingly rare row that has a poster but no dimensions, and
  // the same ratio `_Placeholder` holds open, so the two agree. `BoxFit.cover`
  // crops rather than distorts, so a wrong guess costs a tight crop — whereas
  // taking the poster's ratio when it lands would cost the jerk this exists to
  // remove.
  if (w == null || h == null) return kVideoBoxFallbackRatio;
  // Clamped so a very tall or very wide clip still leaves room for the day
  // underneath it.
  return (w / h).clamp(0.6, 2.0).toDouble();
}

/// The shape assumed when a clip's own is not known.
///
/// What a phone records by default, and therefore the value that makes the
/// common case shift by nothing at all.
const double kVideoBoxFallbackRatio = 16 / 9;

/// A video, drawn as a video. **ISSUE 8.**
///
/// ── WHAT WAS WRONG ────────────────────────────────────────────────────────
///
/// *"A video arrives looking like a document."* It did: a grey row with a
/// filename, a size and a chevron, indistinguishable from a spreadsheet. The
/// only thing marking it as playable was a small amber square, and nothing on
/// it told you what was in the clip — so a day with three videos on it was
/// three identical grey rows and you had to open each one to find out which was
/// which.
///
/// Every other app on the phone shows the frame. This one does now: extracted
/// once at import (`MediaInfo.kt`), stored **encrypted** in the attachment
/// store beside the video, and drawn here as a still with a play badge over it
/// — so nothing is decoded on the day view's frame budget and nothing about the
/// clip is ever on disk in the clear.
///
/// A clip imported before this existed has no poster and falls back to the old
/// row, rather than decoding on scroll to catch up. An honest gap beats a
/// stutter, and the next import will have one.
class _Video extends StatefulWidget {
  const _Video({
    required this.attachment,
    required this.importer,
    required this.entry,
    this.onSaveCopy,
    this.onSaveEntry,
    this.onTrashEntry,
    this.onOpenEntryWith,
  });

  final Attachment attachment;
  final AttachmentImporter importer;

  /// The entry this clip belongs to. **ISSUE D** — needed so the viewer's
  /// three-dot menu can act on the block rather than only on the file.
  final Entry entry;
  final VoidCallback? onSaveCopy;
  final void Function(Entry)? onSaveEntry;
  final void Function(Entry)? onTrashEntry;

  /// **ISSUE 4, 13.** Lend this attachment to another app for as long as
  /// somebody is looking at it.
  final void Function(Entry)? onOpenEntryWith;

  @override
  State<_Video> createState() => _VideoState();
}

class _VideoState extends State<_Video> {
  Attachment? _poster;

  /// ══ "THE PAGE JERKS WITH TWO OR MORE VIDEOS." 31 August 2026 ═══════════
  ///
  /// It did, and this field is the whole fix.
  ///
  /// The poster row is fetched asynchronously — it is a second attachment
  /// reached through `thumbnailId`, so it cannot be known in `build`. Until it
  /// arrived this widget drew `_row`, a **72-point** file row; the moment it
  /// landed, `setState` swapped in an `AspectRatio`, which at a day column's
  /// width is **200 points for a landscape clip and up to 600 for a portrait
  /// one**. So every video on the day silently grew by between 130 and 530
  /// points, each at its own unpredictable moment, after the page had already
  /// been laid out and scrolled.
  ///
  /// With one video that reads as the thumbnail appearing. With **two or more**
  /// it is two or more independent shoves of everything below them, which is
  /// exactly what "the page jerks" describes — and the reason it needed two to
  /// show up is that the first one usually finishes before the page is still.
  ///
  /// **The ratio never needed the poster.** `width` and `height` are written on
  /// the *video's own* row, in the same `AttachmentsCompanion.insert` that
  /// writes `thumbnailId`, from the same `MediaFacts` — so a clip that has a
  /// poster to wait for has always had its shape on hand, synchronously, in
  /// `widget.attachment`. The box is reserved on the first frame and the
  /// picture is dropped into a hole already the right size.
  ///
  /// Latched in `initState` rather than recomputed in `build`, because "the
  /// height is decided once and does not move" is the property being fixed,
  /// and a value derived in `build` is one future edit away from moving again.
  late final double? _ratio = videoBoxRatio(widget.attachment);

  @override
  void initState() {
    super.initState();
    _loadPoster();
  }

  Future<void> _loadPoster() async {
    final id = widget.attachment.thumbnailId;
    if (id == null) return;
    // Through the same cache every other attachment row goes through, so a day
    // with six videos costs six cached lookups rather than six queries per
    // rebuild. See the long note on `AttachmentImporter.attachmentFor`.
    final row = await widget.importer.attachmentById(id);
    if (mounted && row != null) setState(() => _poster = row);
  }

  void _open() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoViewer(
            attachment: widget.attachment,
            store: widget.importer.vault.attachments,
            onSaveCopy: widget.onSaveCopy,
            // The entry is known here, so there is nothing to resolve — unlike
            // the album, where the clip on screen may not be the one tapped.
            onSave: widget.onSaveEntry == null
                ? null
                : (_) => widget.onSaveEntry!(widget.entry),
            onTrash: widget.onTrashEntry == null
                ? null
                : (_) => widget.onTrashEntry!(widget.entry),
            onOpenWith: widget.onOpenEntryWith == null
                ? null
                : (_) => widget.onOpenEntryWith!(widget.entry),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final poster = _poster;
    // The ratio the *video* was recorded at, not the thumbnail's, and clamped
    // so a very tall or very wide clip still leaves room for the day underneath
    // it. It comes from `MediaInfo`, which reads the rotation as well — a
    // phone held upright records a landscape stream plus "rotate 90", and
    // without that correction every portrait clip would be drawn on its side.
    //
    // Decided in `initState`. See `_ratio` for why that matters.
    final ratio = _ratio;

    // A clip imported before poster frames existed. Known on the first frame,
    // so this branch is taken for the whole life of the widget.
    if (ratio == null) {
      return GestureDetector(onTap: _open, child: _row(context));
    }

    return GestureDetector(
      onTap: _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.surface),
              // The one thing that waits. Everything around it — the box, the
              // badge, the caption — is drawn from the first frame, so the
              // arrival of the picture changes a colour and not a layout.
              if (poster != null)
                LayoutBuilder(
                  builder: (context, box) => Image(
                    image: EncryptedImage(
                      poster,
                      store: widget.importer.vault.attachments,
                      // The column's real pixel width. Never the full frame —
                      // see the note on EncryptedImage.maxWidth.
                      maxWidth:
                          (box.maxWidth * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              // A scrim under the caption, so light text on a pale frame is
              // still readable. Bottom only: the picture is the point, and
              // dimming all of it would be dimming the thing you came to see.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x99000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child:
                      Icon(Icons.play_arrow_rounded, size: 34, color: c.canvas),
                ),
              ),
              Positioned(
                left: Space.x3,
                right: Space.x3,
                bottom: Space.x3,
                child: Text(
                  [
                    if (widget.attachment.durationMs != null)
                      humanDuration(widget.attachment.durationMs!),
                    humanSize(widget.attachment.byteSize),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Over a photograph, not over the app's canvas, so this is
                  // the one place the palette's ink would be the wrong answer
                  // — the frame underneath can be any colour at all. Taken
                  // from the dark palette's own primary ink rather than
                  // written as a hex code, so rule 8 holds.
                  //
                  // **And the halo comes off for the same reason. Round 19.**
                  // He photographed "1:47 · 132.3 MB" glowing on a video
                  // poster. The ink was corrected here when this was written
                  // and the shadow was not, so on Star Map the label carried a
                  // cream wash from `pageHalo` round white letters on a dark
                  // frame. The ground under these words is a photograph; the
                  // scrim above is what makes them readable, not the page.
                  style: t.labelMedium?.copyWith(
                    color: LamplightColors.dark.inkPrimary,
                    shadows: const <Shadow>[],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The old row, kept for a clip imported before poster frames existed.
  Widget _row(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(Icons.play_arrow_rounded, size: 30, color: c.canvas),
          ),
          const SizedBox(width: Space.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.attachment.originalName,
                  style: t.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (widget.attachment.durationMs != null)
                      humanDuration(widget.attachment.durationMs!),
                    humanSize(widget.attachment.byteSize),
                  ].join(' · '),
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
        ],
      ),
    );
  }
}

/// Several photographs, captured together, drawn as one block.
///
/// The wrapper that gives an album the same chrome every other block has — the
/// accent rule, the timestamp, any words underneath — and resolves the
/// attachment rows for all of them before handing off to [MediaAlbum].
///
/// The rows are fetched **once for the whole run** rather than once per tile.
/// Six tiles each running their own query is six SQLCipher round trips on the
/// frame the day opens, and they all land on the isolate that is trying to
/// draw it.
class AlbumBlock extends StatefulWidget {
  const AlbumBlock({
    super.key,
    required this.entries,
    required this.importer,
    required this.onMenu,
    this.onCaption,
    this.onSaveEntry,
    this.onTrashEntry,
    this.onOpenEntryWith,
  });

  final List<Entry> entries;
  final AttachmentImporter importer;
  final VoidCallback onMenu;

  /// One caption for the whole album. **`PLAN.md` §9.7** — see
  /// `MediaAlbum.onCaption`.
  final void Function(Entry)? onCaption;

  /// **ISSUE D.** The album is where the viewer's menu actions come from, and
  /// where the picture on screen is resolved back to its entry.
  final void Function(Entry)? onSaveEntry;
  final void Function(Entry)? onTrashEntry;

  /// **ISSUE 4, 13.** Lend this attachment to another app for as long as
  /// somebody is looking at it.
  final void Function(Entry)? onOpenEntryWith;

  @override
  State<AlbumBlock> createState() => _AlbumBlockState();
}

class _AlbumBlockState extends State<AlbumBlock> {
  Map<String, Attachment> _rows = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AlbumBlock old) {
    super.didUpdateWidget(old);
    if (old.entries.length != widget.entries.length) _load();
  }

  Future<void> _load() async {
    // The cache answers most of this synchronously on every sight after the
    // first, so scrolling back past an album costs nothing.
    final found = <String, Attachment>{};
    final missing = <Entry>[];
    for (final e in widget.entries) {
      final hit = AttachmentImporter.cachedAttachment(e.attachmentId);
      if (hit != null) {
        found[hit.id] = hit;
      } else {
        missing.add(e);
      }
    }
    if (mounted && found.isNotEmpty) setState(() => _rows = found);
    for (final e in missing) {
      final row = await widget.importer.attachmentFor(e);
      if (row != null) found[row.id] = row;
    }

    // ── The poster frames, which no entry points at ──────────────────────
    //
    // A video's thumbnail is a second attachment reached through
    // `thumbnailId` (ISSUE 8), so it is not found by walking the entries.
    // Without this pass a video tile in a mixed album would draw as an empty
    // dark square with a play badge — technically correct and exactly the
    // "looks like a document" complaint in a smaller box.
    for (final row in List.of(found.values)) {
      final poster = row.thumbnailId;
      if (poster == null || found.containsKey(poster)) continue;
      final loaded = await widget.importer.attachmentById(poster);
      if (loaded != null) found[loaded.id] = loaded;
    }

    if (mounted) setState(() => _rows = Map.of(found));
  }

  /// "6 photos", "3 videos", or "4 photos and 2 videos".
  ///
  /// Said properly rather than as "6 items", because the two are not the same
  /// thing to a person looking for one of them — and because the old label
  /// said "photos" for a batch that contained a video, which was simply untrue.
  String get _what {
    final videos = widget.entries.where((e) => e.type == 'video').length;
    final photos = widget.entries.length - videos;
    String plural(int n, String one) => '$n $one${n == 1 ? '' : 's'}';
    if (videos == 0) return plural(photos, 'photo');
    if (photos == 0) return plural(videos, 'video');
    return '${plural(photos, 'photo')} and ${plural(videos, 'video')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final at =
        DateTime.fromMillisecondsSinceEpoch(widget.entries.first.createdAt)
            .toLocal();
    final time = LampDates.time(context, at);
    // Any words typed against any photo in the batch. There is normally one at
    // most, and showing them all would turn the caption into a list.
    final words = widget.entries
        .map((e) => (e.body ?? '').trim())
        .where((b) => b.isNotEmpty)
        .join('\n');

    return Semantics(
      button: true,
      label: L.of(context).attachmentSemantic(_what, time),
      // Every caption typed against any photograph in the batch -- `words` is
      // already assembled just above for the drawing, and there is no reason
      // the drawing should be the only place it reaches.
      value: words,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
            top: Space.x5, bottom: Space.x1, right: Space.x1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(top: 4, right: Space.x3),
              color: c.accent.withValues(alpha: 0.45),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(time, style: t.labelMedium),
                      const SizedBox(width: Space.x2),
                      Text(
                        _what,
                        style: t.labelSmall?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.x2),
                  MediaAlbum(
                    entries: widget.entries,
                    attachments: _rows,
                    store: widget.importer.vault.attachments,
                    onMenu: widget.onMenu,
                    onCaption: widget.onCaption,
                    onSaveEntry: widget.onSaveEntry,
                    onTrashEntry: widget.onTrashEntry,
                    onOpenEntryWith: widget.onOpenEntryWith,
                  ),
                  if (words.isNotEmpty) ...[
                    const SizedBox(height: Space.x2),
                    // ISSUE 11. The caption on an album is the user's own
                    // words too, so a link in one is a link.
                    LinkedText(words),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
