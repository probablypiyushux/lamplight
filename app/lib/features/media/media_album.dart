import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/media/encrypted_image.dart';
import '../../core/storage/attachment_importer.dart' show humanDuration;
import '../../core/storage/attachment_store.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'photo_viewer.dart';

/// Everything captured in one go, drawn as one thing. **ISSUE 7.**
///
/// ── WHY ONE BLOCK AND NOT FIFTEEN ────────────────────────────────────────
///
/// Reported first as: *"I don't need 15 different blocks if I upload multiple
/// photos — I need one block, and that too with grouped photos."*
///
/// Correct, and the reason is not tidiness. Six photographs taken in one minute
/// are **one event**. Fifteen stacked full-width blocks turn a single moment
/// into fifteen scroll-heights of the day, so the rest of that day — the words,
/// the voice note, everything that gives the photographs their meaning — is
/// pushed off screen by the photographs. The album is not a space saving. It is
/// what stops one import from eating the day it belongs to.
///
/// ── WHAT ROUND FOUR CHANGED, AND WHY ─────────────────────────────────────
///
/// He looked at the first version and wrote *"it looks IDK normal"*, then the
/// rule underneath it: **make your app feel like the familiar app that most
/// users use.** Asked again, plainly: *"make it perfect — like how the album
/// grid is presented in WhatsApp or Telegram or Signal or Snapchat, and make
/// multiple uploads support both images and video in the album."*
///
/// Two things follow, and the second is the one that was actually broken.
///
/// **1. The layout is chosen from the pictures, not from the count.** The old
/// version had one arrangement per count — two side by side, always; four in a
/// square, always. That is what made it look not-quite-right: two landscape
/// photographs side by side become a pair of letterbox slivers, and two
/// portraits stacked become a column taller than the screen. Every one of the
/// four apps he named solves this the same way, and it is the whole of the
/// difference between a grid and a *mosaic* — **the orientation of the
/// contents decides the arrangement.** See [_Shape].
///
/// **2. A video belongs in the album.** It did not. `_group` in the day view
/// required every entry in a run to be a photo, so a single multi-select that
/// contained one clip came apart into an album *plus* a stray grey video row
/// underneath it — which is exactly what his ISSUE 7 screenshot shows, and it
/// is also half of ISSUE 8. Photos and videos share the grid now, a video tile
/// carries the play badge and its duration the way it does everywhere else, and
/// tapping one opens the player rather than the photo pager.
///
/// Documents and voice notes are still their own blocks, deliberately. That is
/// what WhatsApp does too: a PDF is a PDF, and putting it in a picture grid
/// would mean drawing a grey rectangle where a picture should be.
///
/// ── WHY NEVER MORE THAN FOUR TILES ───────────────────────────────────────
///
/// A 3×3 of thumbnails on a 390dp phone gives each photograph about 120 points,
/// which is too small to recognise a face in — and recognising the face is the
/// entire reason the picture is there. Four large tiles and a `+N` beats nine
/// small ones, which is the conclusion all four of those apps reached as well.
class MediaAlbum extends StatelessWidget {
  const MediaAlbum({
    super.key,
    required this.entries,
    required this.attachments,
    required this.store,
    required this.onMenu,
    this.onCaption,
    this.onSaveEntry,
    this.onTrashEntry,
    this.onOpenEntryWith,
  });

  /// In the order they were captured. Photos and videos, mixed.
  final List<Entry> entries;

  /// Keyed by attachment id. An entry whose row has not loaded yet is drawn as
  /// a placeholder tile rather than being left out — otherwise the album
  /// reshuffles itself as the rows arrive, which looks like a fault.
  final Map<String, Attachment> attachments;

  final AttachmentStore store;
  final VoidCallback onMenu;

  /// Opens the editor on one entry, so an album can be given **one** caption.
  ///
  /// ── `PLAN.md` §9.7, AND `Honest Review`'S SMALL LIST ────────────────────
  ///
  /// > *"A caption per album, not per photo. Words currently attach to
  /// > whichever entry in the batch they were typed against, and the album
  /// > joins them with newlines. Fine, and not what anybody means."*
  ///
  /// Exactly right, and the cause is that an album has no identity of its own to
  /// hang words on — it is fifteen entries sharing a `groupId`, drawn as one
  /// block. Editing "the album" meant picking one of the fifteen at random and
  /// editing that, and the next caption went somewhere else.
  ///
  /// **Not fixed with a schema change**, which is what a real album row would
  /// be. [captionEntry] names one member as the one that holds the words, by a
  /// rule that is stable for the life of the album, and the sheet always sends
  /// captions there. One place, no migration, and nothing already written is
  /// moved or lost.
  final void Function(Entry)? onCaption;

  /// **ISSUE D.** What the viewer's three-dot menu does, given the *entry* the
  /// picture on screen belongs to.
  ///
  /// The album is the only place that knows the mapping, because it is the only
  /// place holding both the entries and their attachment rows — which is why
  /// the resolution happens here and the day screen is handed an [Entry] it
  /// already knows what to do with.
  final void Function(Entry)? onSaveEntry;
  final void Function(Entry)? onTrashEntry;

  /// **ISSUE 4, 13.** Lend the picture or clip on screen to another app.
  final void Function(Entry)? onOpenEntryWith;

  /// The seam between tiles.
  ///
  /// Three points, which is what the reference apps use and is not an arbitrary
  /// small number: at one point the seam disappears against a dark photograph
  /// and two pictures read as one; at six it reads as a table of contents.
  static const double _gap = 3;

  /// Which attachment a tile should actually draw.
  ///
  /// A named rule rather than an expression at the call site, because it is
  /// the kind of one-liner that gets "simplified" back into
  /// `isVideo ? thumbnailId : id` by somebody who has not noticed that
  /// photographs have thumbnails now. `thumbnail_preference_test.dart` is what
  /// stops that.
  ///
  ///  * A thumbnail if there is one — a 40 KB decrypt instead of a 4 MB one.
  ///  * Otherwise the original, for anything imported before thumbnails.
  ///  * Otherwise nothing, for a video with no poster: the file itself is not
  ///    a picture and handing it to an image decoder draws a broken tile.
  static String? pictureIdFor(Attachment attachment, {required bool isVideo}) =>
      attachment.thumbnailId ?? (isVideo ? null : attachment.id);

  // ───────────────────────────────────────────────────────────────────────
  //  Opening
  // ───────────────────────────────────────────────────────────────────────

  /// Everything in the album, in order, with the index of [tapped] among it.
  ///
  /// ── ISSUE 15 — WHAT THIS USED TO DO, AND WHY IT WAS WRONG ─────────────
  ///
  /// This was `_photosAround`, and it skipped videos:
  ///
  /// > *"The pager holds photographs only. A video in the middle of a
  /// > swipe-through would have to either autoplay — which nobody wants at full
  /// > volume in a quiet room — or sit there as a still, which is worse than
  /// > not being in the pager at all."*
  ///
  /// He reported the consequence precisely: *"when I slide it open V and I
  /// can't slide to P. When I open P it shows me 1 of 5"* — in an album of six.
  /// The clip was not merely unreachable, it had been removed from the count,
  /// so the app was telling him his album was smaller than it was.
  ///
  /// The argument above is half right and reaches the wrong conclusion. Nobody
  /// wants autoplay; that much stands. But "sit there as a still" is not worse
  /// than being absent — **a still with a play button on it is what every
  /// gallery on the phone shows**, and it is what this album's own tiles have
  /// always shown. The pager was the only place in the app that pretended
  /// videos were not there.
  ///
  /// So the pager holds the album. All of it, in capture order, counted
  /// honestly.
  (List<ViewerItem>, int) _itemsAround(int tapped) {
    final items = <ViewerItem>[];
    var at = 0;
    for (var i = 0; i < entries.length; i++) {
      final row = attachments[entries[i].attachmentId];
      if (row == null) continue;
      if (i <= tapped) at = items.length;
      final video = entries[i].type == 'video';
      items.add(ViewerItem(
        attachment: row,
        isVideo: video,
        // A video's still is a *different* attachment, reached through
        // `thumbnailId` — see MediaInfo.kt. `_load` in AlbumBlock has already
        // fetched them into this same map for the tiles.
        poster: video && row.thumbnailId != null
            ? attachments[row.thumbnailId!]
            : null,
      ));
    }
    return (items, at);
  }

  /// Which entry an attachment row belongs to. **ISSUE D.**
  ///
  /// The viewer hands back the attachment the user was actually looking at,
  /// which in a four-photo album is not necessarily the one they tapped. This
  /// walks back to its entry so the action lands on the right block.
  ///
  /// Returns null if the row is not in this album at all, which cannot happen
  /// through the viewer but is cheap to be honest about — acting on the wrong
  /// entry is worse than doing nothing.
  Entry? _entryFor(Attachment shown) {
    for (final e in entries) {
      if (e.attachmentId == shown.id) return e;
    }
    return null;
  }

  /// Which member of the album holds its caption.
  ///
  /// The first that already has words, so nothing anybody has written is
  /// orphaned by this rule arriving; the first entry otherwise, so a fresh
  /// album has a settled answer before anybody types. Stable for the life of
  /// the album either way, which is the only property that matters — a rule
  /// that moved would put the second caption somewhere the first was not.
  Entry get captionEntry {
    for (final e in entries) {
      if ((e.body ?? '').trim().isNotEmpty) return e;
    }
    return entries.first;
  }

  void Function(Attachment)? _wrap(void Function(Entry)? action) {
    if (action == null) return null;
    return (shown) {
      final entry = _entryFor(shown);
      if (entry != null) action(entry);
    };
  }

  /// One picture out of an album. **`Honest Review`'s small list.**
  ///
  /// > *"Albums — you cannot remove or reorder one photo without deleting the
  /// > whole block."*
  ///
  /// Half true and the half that was true was the painful half. A long press
  /// anywhere on the mosaic opened the **entry** menu, and an album is one block
  /// on the day, so the only thing that menu could offer was all of it. Somebody
  /// with a good set of six and one bad frame had a choice between keeping the
  /// bad frame for ever and throwing away the other five.
  ///
  /// ── WHY REMOVAL IS EASY AND REORDERING IS NOT ─────────────────────────────
  ///
  /// Every picture in an album is already **its own entry**, sharing a
  /// `groupId`. So removing one is trashing one entry — reversible, thirty days
  /// in the trash, exactly like every other deletion in the app — and the album
  /// redraws with five.
  ///
  /// **Reordering is not done and is not a line of work away.** The album is
  /// drawn in capture order, which is `createdAt`, and there is no column that
  /// says where a picture sits in its own block. Adding one means a schema
  /// migration and a drag-and-drop mosaic, and it is worth far less than this
  /// was: nobody has ever asked to reorder, and he asked for the other twice.
  /// Said here rather than left as a half-kept promise.
  Future<void> _pick(BuildContext context, int index) async {
    final entry = entries[index];
    final attachment = attachments[entry.attachmentId];
    final video = (attachment?.mimeType ?? '').startsWith('video/');
    // Nothing this sheet could offer. Falls back to the whole-album menu rather
    // than doing nothing, which is what a long press did before.
    if (onTrashEntry == null && onSaveEntry == null && onOpenEntryWith == null) {
      onMenu();
      return;
    }

    final thing = video ? 'video' : 'photo';
    await showLampSheet<void>(
      context: context,
      // Names which one, because a mosaic of six and a sheet that says "this
      // photo" is a sentence about something the user has to remember they were
      // touching.
      title: entries.length > 1
          ? L.of(context)
              .albumThisOneOf(thing, '${index + 1}', '${entries.length}')
          : L.of(context).albumThisOne(thing),
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            if (onCaption != null)
              LampTile(
                // Named for the album rather than for this picture, because it
                // is the album's words — see `captionEntry`. Somebody who long
                // pressed the fourth tile is not expecting to caption only the
                // fourth.
                title: (captionEntry.body ?? '').trim().isEmpty
                    ? (entries.length > 1
                        ? L.of(context).albumCaptionThese
                        : L.of(context).albumCaptionThis)
                    : L.of(context).albumCaptionEdit,
                icon: Icons.notes_outlined,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onCaption!(captionEntry);
                },
              ),
            if (onOpenEntryWith != null)
              LampTile(
                title: L.of(context).docOpenWith,
                icon: Icons.open_in_new,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onOpenEntryWith!(entry);
                },
              ),
            if (onSaveEntry != null)
              LampTile(
                title: L.of(context).entrySaveCopy,
                icon: Icons.save_alt,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onSaveEntry!(entry);
                },
              ),
            if (onTrashEntry != null)
              LampTile(
                title: L.of(context).albumRemoveThis(thing),
                // The whole reason this is safe to offer on one tap. It is the
                // same reversible deletion as everywhere else in the app.
                subtitle: entries.length > 1
                    ? L.of(context)
                        .albumOthersStay('${entries.length - 1}')
                    : L.of(context).albumGoesToTrash,
                icon: Icons.delete_outline,
                danger: true,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onTrashEntry!(entry);
                },
              ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) {
    // ISSUE 15. One route for the whole album, whatever it is made of. A clip
    // opens on its own page showing its poster with the play control over it,
    // and playing pushes the video player from there — so the swipe is never
    // interrupted and the count is never a lie.
    final (items, at) = _itemsAround(index);
    if (items.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PhotoViewer(
        items: items,
        store: store,
        initialIndex: at,
        onSave: _wrap(onSaveEntry),
        onTrash: _wrap(onTrashEntry),
        onOpenWith: _wrap(onOpenEntryWith),
      ),
    ));
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Layout
  // ───────────────────────────────────────────────────────────────────────

  /// What one item's picture is shaped like.
  ///
  /// A video reports the shape of the *video*, not of its poster frame, because
  /// `MediaInfo` already corrected the recorded rotation and the poster is
  /// drawn `cover` inside whatever box it is given anyway.
  double _ratioOf(int index) {
    final a = attachments[entries[index].attachmentId];
    final w = a?.width;
    final h = a?.height;
    if (w != null && h != null && w > 0 && h > 0) {
      // Clamped: a panorama at 6:1 would be a two-centimetre strip and a long
      // screenshot at 1:2.2 would be the whole screen. The clamp is only ever
      // reached by things that are not really photographs.
      return (w / h).clamp(0.62, 1.9);
    }
    // 4:3 is the honest default for something imported before dimensions were
    // recorded, and it is what a phone camera produces more often than not.
    return 4 / 3;
  }

  bool _isWide(int index) => _ratioOf(index) > 1.15;

  @override
  Widget build(BuildContext context) {
    final shown = entries.length > 4 ? 4 : entries.length;
    final extra = entries.length - shown;

    return GestureDetector(
      onLongPress: onMenu,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        // ISSUE 6b: no cap. The mosaic is as wide as the block it sits in,
        // like everything else on the day. See `tokens.dart`.
        child: SizedBox(
          width: double.infinity,
          child: switch (shown) {
            1 => _one(context),
            2 => _two(context),
            3 => _three(context),
            _ => _four(context, extra),
          },
        ),
      ),
    );
  }

  /// One item keeps its own proportions, up to a cap.
  ///
  /// The cap matters: a portrait photograph at its true ratio is taller than
  /// the screen, and a day where one picture fills the viewport is a day you
  /// cannot read.
  Widget _one(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: AspectRatio(
          aspectRatio: _ratioOf(0),
          child: _tile(context, 0),
        ),
      );

  /// Two: side by side, unless both are landscape.
  ///
  /// **This is the mosaic rule in its simplest form.** Two landscape pictures
  /// side by side each get half the width at their own height, which makes two
  /// slivers; stacked, they each get the full width and look like themselves.
  /// Two portraits are the other way round. Telegram, WhatsApp and Signal all
  /// branch here and it is most of why their albums look composed.
  Widget _two(BuildContext context) {
    final bothWide = _isWide(0) && _isWide(1);
    if (bothWide) {
      // Stacked. The block's height is the two pictures' heights at full width,
      // averaged, so a 16:9 and a 4:3 do not force one another out of shape.
      final ratio = 2 / (1 / _ratioOf(0) + 1 / _ratioOf(1));
      return AspectRatio(
        aspectRatio: ratio.clamp(0.9, 2.2),
        child: Column(
          children: [
            Expanded(child: _tile(context, 0)),
            const SizedBox(height: _gap),
            Expanded(child: _tile(context, 1)),
          ],
        ),
      );
    }
    // Side by side. Each tile is half the width, so the pair is twice as wide
    // as the shorter of the two is tall.
    final ratio = _ratioOf(0) + _ratioOf(1);
    return AspectRatio(
      aspectRatio: ratio.clamp(1.0, 2.4),
      child: Row(
        children: [
          Expanded(child: _tile(context, 0)),
          const SizedBox(width: _gap),
          Expanded(child: _tile(context, 1)),
        ],
      ),
    );
  }

  /// Three: one big and two small, and which edge the big one takes depends on
  /// its shape.
  ///
  /// A landscape hero goes on top with two beneath it; a portrait hero goes
  /// down the left with two stacked beside it. Putting a wide picture in a tall
  /// slot is the single most common way this layout goes wrong.
  Widget _three(BuildContext context) {
    if (_isWide(0)) {
      return AspectRatio(
        aspectRatio: 1.05,
        child: Column(
          children: [
            Expanded(flex: 3, child: _tile(context, 0)),
            const SizedBox(height: _gap),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _tile(context, 1)),
                  const SizedBox(width: _gap),
                  Expanded(child: _tile(context, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Row(
        children: [
          Expanded(flex: 2, child: _tile(context, 0)),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _tile(context, 1)),
                const SizedBox(height: _gap),
                Expanded(child: _tile(context, 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Four or more: a square two-by-two, with `+N` on the last tile.
  ///
  /// The one arrangement that does *not* branch on orientation, and that is
  /// deliberate — at four or more the tiles are small enough that every picture
  /// is a crop anyway, and a square block is the shape the eye reads as "a set"
  /// rather than as "some pictures". All four reference apps do the same.
  Widget _four(BuildContext context, int extra) => AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, 0)),
                  const SizedBox(width: _gap),
                  Expanded(child: _tile(context, 1)),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, 2)),
                  const SizedBox(width: _gap),
                  Expanded(
                    child:
                        _tile(context, 3, badge: extra > 0 ? '+$extra' : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ───────────────────────────────────────────────────────────────────────
  //  One tile
  // ───────────────────────────────────────────────────────────────────────

  Widget _tile(BuildContext context, int index, {String? badge}) {
    final entry = entries[index];
    final attachment = attachments[entry.attachmentId];
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    if (attachment == null) {
      return ColoredBox(color: c.raised, child: const SizedBox.expand());
    }

    // ── Whatever small copy exists, in preference to the original ──────────
    //
    // A video draws its poster frame, which is a *different* attachment — see
    // MediaInfo.kt. One imported before poster frames existed has none, and
    // gets a plain dark tile with the play badge over it rather than a decode
    // on the day view's frame budget.
    //
    // Photographs now have a `thumbnailId` too, and it matters here more than
    // it does for video because there are so many more of them. Drawing the
    // original meant decrypting the whole four-megabyte file to fill a
    // two-centimetre square, once per tile, every time the day came back into
    // view. The provider's `maxWidth` never helped with that — it caps the
    // *decode*, and the decrypt happens first.
    //
    // `??` rather than a branch, so a photograph imported before thumbnails
    // existed still draws from its original. Nothing has to be migrated and
    // nothing regresses.
    final video = entry.type == 'video';
    final pictureId = MediaAlbum.pictureIdFor(attachment, isVideo: video);
    // ── ISSUE 3 — a missing thumbnail is slow, not blank ───────────
    //
    // The grey box was caused by a caller handing over a map without the
    // thumbnail row in it, and that caller is fixed. This is the second half:
    // **the tile no longer depends on the caller getting it right.** If the
    // small copy is not in the map, a photograph falls back to its original —
    // which is a big decrypt for a small square and is exactly what the
    // thumbnail exists to avoid, but it is a picture, and the alternative was
    // showing somebody a blank square where their photograph is.
    //
    // Not for video: a clip's own bytes are not an image, and handing them to
    // a decoder draws a broken tile rather than a slow one. A video with no
    // poster keeps the dark tile and the play badge, which is what every
    // gallery on the phone shows for the same case.
    final picture = (pictureId == null ? null : attachments[pictureId]) ??
        (video ? null : attachments[attachment.id]);

    final dpr = MediaQuery.devicePixelRatioOf(context);
    return GestureDetector(
      onTap: () => _open(context, index),
      // One picture rather than the whole block. See `_pick`, and note that the
      // album-level long press is what this replaces — it could only ever offer
      // to throw away all six.
      onLongPress: () => _pick(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.raised),
          if (picture != null)
            // ── The flight. `PLAN.md` §8.5 ───────────────────────────────
            //
            // *"Photo → viewer cuts rather than flies."* It did, and there was
            // no `Hero` anywhere in `lib/` at all. Keyed on the attachment id
            // rather than the entry's, so exactly one tile and exactly one
            // viewer page can ever claim the tag — see `heroTagFor`.
            //
            // On the **whole tile**, including the `+N` badge and a video's play
            // chrome, so the thing that leaves is the thing that was tapped.
            // Wrapping only the `Image` would fly the picture out from under its
            // own overlays and leave them behind for a frame.
            Hero(
              tag: heroTagFor(attachment.id),
              child: Image(
              image: EncryptedImage(
                picture,
                store: store,
                // A tile is at most half the column. Decoding more than that is
                // work nobody can see, times however many tiles are on screen.
                maxWidth: (300 * dpr).round().clamp(240, 1200),
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: Motion.duration(context),
                  curve: Motion.curve,
                  child: child,
                );
              },
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : ColoredBox(
                      color: c.raised,
                      child: const Center(child: LampBusyDot(size: 22)),
                    ),
              errorBuilder: (context, error, _) => ColoredBox(
                color: c.raised,
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 20, color: c.inkMuted),
                ),
              ),
            ),
            ),

          // ── The video's own chrome ───────────────────────────────────────
          //
          // Drawn only when this tile is not the `+N` one: two overlays on one
          // tile is a mess, and the count is the more useful of the two.
          if (video && badge == null) ...[
            const _BottomScrim(),
            Center(
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: c.accent, shape: BoxShape.circle),
                child:
                    Icon(Icons.play_arrow_rounded, size: 26, color: c.canvas),
              ),
            ),
            if (attachment.durationMs != null)
              Positioned(
                left: Space.x2,
                right: Space.x2,
                bottom: Space.x2,
                child: Text(
                  humanDuration(attachment.durationMs!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(
                    // Over a photograph rather than over the app's canvas, so
                    // this is one of the two places the palette's ink would be
                    // the wrong answer — the frame underneath can be any colour
                    // at all. Taken from the dark palette's own primary ink
                    // rather than written as a hex code, so rule 8 holds.
                    //
                    // The halo comes off for the same reason. **Round 19.**
                    color: LamplightColors.dark.inkPrimary,
                    fontWeight: FontWeight.w600,
                    shadows: const <Shadow>[],
                  ),
                ),
              ),
          ],

          if (badge != null)
            // The `+N` scrim. A flat dark wash rather than a corner chip,
            // because the number has to be legible over a photograph of
            // anything at all, and a chip small enough not to hide the picture
            // is too small to read at arm's length.
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.48),
              child: Center(
                child: Text(
                  badge,
                  style: t.titleLarge?.copyWith(
                    color: LamplightColors.dark.inkPrimary,
                    fontWeight: FontWeight.w600,
                    // Over a black scrim over a photograph. The page's halo
                    // has no business here either. **Round 19.**
                    shadows: const <Shadow>[],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A short gradient at the foot of a tile, so light text on a pale frame is
/// still readable. Bottom only: the picture is the point, and dimming all of it
/// would be dimming the thing you came to look at.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) => const Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0x99000000), Color(0x00000000)],
            ),
          ),
        ),
      );
}
