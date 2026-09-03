import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/db/database.dart' show Attachment;
import '../../core/media/encrypted_image.dart';
import '../../core/media/picture_region.dart';
import '../../core/plain_words.dart';
import '../../core/storage/attachment_store.dart';
import '../../design/tokens.dart';
import 'video_viewer.dart';
import 'zoom_tile.dart';
import 'viewer_menu.dart';

/// One thing in an album, whatever kind of thing it is. **ISSUE 15.**
///
/// The pager used to hold a `List<Attachment>` and the album filtered videos
/// out of it before handing it over. This exists so it does not have to: a
/// video is an item like any other, and it carries the poster frame it is drawn
/// as — a *different* attachment row, reached through `thumbnailId`, which no
/// entry points at.
class ViewerItem {
  const ViewerItem({
    required this.attachment,
    required this.isVideo,
    this.poster,
  });

  /// The thing itself — the picture, or the clip.
  final Attachment attachment;

  final bool isVideo;

  /// The still that stands in for a clip until it is played. Null for a
  /// photograph, and null for a video imported before poster frames existed.
  final Attachment? poster;

  /// What is actually drawn on this page.
  Attachment? get picture => isVideo ? poster : attachment;
}

/// The tag that makes a photograph fly rather than cut.
///
/// ══ PLAN.md §8.5, AND `Honest Review`'S SMALL LIST ═════════════════════════
///
/// > *"Photo → viewer cuts rather than flies. The `Hero` was lost in a refactor
/// > and there is no `Hero` anywhere in `lib/` today."*
///
/// True until now — `grep -r Hero lib/` returned nothing at all.
///
/// It matters more here than it would in a gallery app, and the reason is in
/// `PLAN.md` §8.5's own words: *motion that says the app is alive*. A tap that
/// cuts to a full-screen picture is two unrelated images; a tap that flies tells
/// you **that** picture became **this** one, which is the difference between
/// navigating and opening. It is also the one place in this app where a
/// transition carries information rather than decoration, which is what
/// `DESIGN-SYSTEM.md` allows motion for.
///
/// ── WHY THE TAG IS THE ATTACHMENT ID AND NOT THE ENTRY'S ──────────────────
///
/// The viewer is a pager: it opens on the tile you tapped and you can swipe
/// away from it. Only **one** page can own the flight, and it has to be the one
/// that was tapped — Flutter throws if two `Hero`s share a tag in one subtree,
/// and a pager whose neighbours are built ahead of time has three live at once.
///
/// Keying on the attachment id makes the pair unique by construction: exactly
/// one tile draws that attachment and exactly one page does. Swiping to another
/// page simply means the flight home starts from a tile that is not on screen,
/// which Flutter handles by fading — the correct behaviour, and the one every
/// gallery has.
String heroTagFor(String attachmentId) => 'photo:$attachmentId';

/// A photograph, full screen.
///
/// ── THE BUG THIS FIXES ───────────────────────────────────────────────────
///
/// Reported as *"photos open like in miniature"*, and it was exactly that. The
/// old viewer was:
///
/// ```dart
/// Center(child: InteractiveViewer(child: Image(..., fit: BoxFit.contain)))
/// ```
///
/// `BoxFit` only does anything when the widget has been **given** a size.
/// Inside a `Center` an `Image` is unconstrained, so it takes its intrinsic
/// size instead — and its intrinsic size is whatever the decoder produced. The
/// decoder had already been told, correctly, not to waste memory on pixels
/// nobody can see. So a photo that decoded to a modest bitmap was drawn at
/// exactly that many logical pixels, in the middle of a black screen, as a
/// postage stamp. `fit: BoxFit.contain` was in the code and doing nothing at
/// all.
///
/// The fix is `Positioned.fill`: give the image the whole screen and *then*
/// ask it to fit inside. One word of layout, and it is the difference between
/// a viewer and a thumbnail on a dark background.
///
/// ── AND IT PAGES NOW ─────────────────────────────────────────────────────
///
/// An album opens at the picture you tapped and swipes to its neighbours,
/// which is what every gallery does and what the old one-photo-per-route
/// version made impossible — you had to go back and tap the next one.
///
/// ══ ISSUE 15 — THE ALBUM IS ONE THING, NOT TWO ═══════════════════════════
///
/// *"In multiple uploads album grids — a video and photo can't come together.
/// \[V | P | P | P | P | P\] … when I slide it open V and I can't slide to P.
/// When I open P it shows me 1 of 5, and unable to slide to V. I want you to
/// repair this issue where I can't move into multiple uploads if their file
/// formats change!"*
///
/// He has described the old behaviour exactly, including the giveaway detail:
/// **"1 of 5" in an album of six**. The album filtered videos out before
/// building the pager, so the clip was not merely unreachable — it had been
/// removed from the count, and the app was quietly telling him his album was
/// smaller than it was.
///
/// The reasoning behind that filter is still in `MediaAlbum` and it was not
/// silly: a video in the middle of a swipe-through would have to autoplay,
/// which nobody wants at full volume in a quiet room, or sit there as a still.
/// The mistake was treating "sit there as a still" as the bad outcome. **A
/// still with a play button on it is exactly what every gallery on the phone
/// shows**, and it is what the album's own tiles already showed. The pager was
/// the only place in the app that pretended videos were not there.
///
/// So every item is a page, the count is the whole album, and a video page is
/// its poster frame with the play control over it. Pressing play opens the
/// video player that already exists, with all its controls, rather than a
/// second half-built one embedded in a pager.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.items,
    required this.store,
    this.initialIndex = 0,
    this.onSave,
    this.onTrash,
    this.onOpenWith,
  });

  /// Everything in the album, in the order it was captured — photographs and
  /// videos alike. **ISSUE 15.**
  final List<ViewerItem> items;

  final AttachmentStore store;
  final int initialIndex;

  /// **ISSUE D.** Save the picture currently on screen, and send the picture
  /// currently on screen to the trash.
  ///
  /// They take the [Attachment] rather than closing over one, because this is a
  /// pager: the thing being acted on is whichever page the user has swiped to,
  /// not the one they opened. Getting that wrong would delete the wrong
  /// photograph out of an album of four, silently, and it is the kind of defect
  /// that is only ever found by the person it happens to.
  ///
  /// Null means the caller cannot offer it — the menu then hides that row, and
  /// hides itself entirely if both are null.
  final void Function(Attachment)? onSave;
  final void Function(Attachment)? onTrash;

  /// **ISSUE 4, 13.** Hand this picture to another app for as long as somebody
  /// is looking at it. *"I want it on every file type/format"* — a photograph
  /// is a file type.
  final void Function(Attachment)? onOpenWith;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// How far the picture has been dragged towards being dismissed.
  double _dragged = 0;

  /// Controls hide on tap, the way a full-screen photo should.
  bool _chrome = true;

  /// True while any page is zoomed in, so the pager and the drag-to-close both
  /// get out of the way of panning.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Acts on the page currently shown, never on the one that was opened.
  Future<void> _menu() async {
    if (_index < 0 || _index >= widget.items.length) return;
    final item = widget.items[_index];
    final shown = item.attachment;
    final save = widget.onSave;
    final trash = widget.onTrash;
    final openWith = widget.onOpenWith;
    await showViewerMenu(
      context: context,
      // ISSUE 15. The sheet says "Save video" over a clip and "Save photo" over
      // a picture, in an album that now holds both.
      kind: viewerKindFor(shown, video: item.isVideo),
      onOpenWith: openWith == null ? null : () => openWith(shown),
      onSave: save == null ? null : () => save(shown),
      onTrash: trash == null
          ? null
          : () {
              // Out of the viewer first. Leaving a full-screen picture of
              // something that is now in the trash on the screen is a lie the
              // user has to dismiss themselves.
              Navigator.of(context).maybePop();
              trash(shown);
            },
    );
  }

  /// Plays the clip on this page. **ISSUE 15.**
  ///
  /// Pushes the video player that already exists rather than embedding a second
  /// one in the pager. Two players in one app drift apart, and the swipe
  /// gesture the pager owns and the scrub gesture a player owns would be
  /// fighting over the same finger.
  void _play(ViewerItem item) {
    if (!item.isVideo) return;
    final save = widget.onSave;
    final trash = widget.onTrash;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => VideoViewer(
        attachment: item.attachment,
        store: widget.store,
        onSave: save,
        onTrash: trash,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final many = widget.items.length > 1;
    // The ground fades as the picture is pulled away, so the gesture explains
    // itself before you commit to it.
    final fade = (1 - (_dragged.abs() / 340)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: c.canvas.withValues(alpha: fade),
      body: Stack(
        // ISSUE 9. Scaffold hands its body **loose** constraints, and a Stack
        // sizes itself to its non-positioned children. The chrome row below
        // used to be non-positioned, so this Stack collapsed to the height of
        // a back button — 98.3 logical pixels, confirmed on a Redmi Pad by
        // dumping the live render tree — and `Positioned.fill` then faithfully
        // filled *that*. `BoxFit.contain` did exactly as told and drew the
        // photograph into a 98-pixel strip at the top of a black screen.
        //
        // Two defences, because one was not enough last time: every child is
        // positioned, AND the stack is told to expand. Either alone fixes it;
        // together they survive somebody adding a plain child later.
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _dragged),
              child: PageView.builder(
                controller: _pages,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.items.length,
                itemBuilder: (context, i) => _Page(
                  item: widget.items[i],
                  store: widget.store,
                  isCurrent: i == _index,
                  onPlay: () => _play(widget.items[i]),
                  onChrome: () => setState(() => _chrome = !_chrome),
                  onZoom: (z) => setState(() => _zoomed = z),
                  onDrag: (dy) => setState(() => _dragged += dy),
                  onDragEnd: (velocity) {
                    if (_dragged.abs() > 140 || velocity.abs() > 700) {
                      Navigator.of(context).maybePop();
                    } else {
                      setState(() => _dragged = 0);
                    }
                  },
                ),
              ),
            ),
          ),

          // Back, and — for an album — where you are in it. Nothing else.
          // Everything this screen can do, it does with a gesture, and a row of
          // icons over somebody's photograph is furniture.
          //
          // `Positioned` is load-bearing, not tidiness: unpositioned, this row
          // is what the Stack measures itself against. See the note above.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _chrome ? 1 : 0,
              duration: Motion.duration(context),
              child: IgnorePointer(
                ignoring: !_chrome,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.x2),
                    child: Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back,
                          label: L.of(context).searchBack,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        // ── ISSUE 14 — "INTERCHANGING OF BUTTONS! IN VIEWERS"
                        //
                        // He drew the bar as it was, drew it again as he wanted
                        // it, and wrote "Interchange their position.
                        // Understood?" underneath. So: the counter, then the
                        // menu hard against the margin.
                        //
                        // Round five put them the other way round on the
                        // argument that the counter should be the rightmost
                        // thing and the menu should land under a thumb. That
                        // was wrong on its own terms. "5 of 7" is a *label* —
                        // it is not touchable, and putting the one thing you
                        // cannot press in the one place a right-handed thumb
                        // reaches most easily is backwards. Every gallery on
                        // the phone puts the menu in the trailing corner, which
                        // is test 5, familiarity, and it is also where his
                        // drawing puts it.
                        if (many)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.x3,
                              vertical: Space.x2,
                            ),
                            decoration: BoxDecoration(
                              color: c.canvas.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(Radii.full),
                            ),
                            child: Text(
                              '${_index + 1} of ${widget.items.length}',
                              style: t.labelMedium?.copyWith(
                                color: c.inkPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        if (many) const SizedBox(width: Space.x2),
                        if (widget.onSave != null || widget.onTrash != null)
                          _CircleButton(
                            icon: Icons.more_vert,
                            label: L.of(context).viewerMore,
                            onTap: _menu,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One photograph inside the pager.
class _Page extends StatefulWidget {
  const _Page({
    required this.item,
    required this.store,
    required this.onChrome,
    required this.onPlay,
    required this.onZoom,
    required this.onDrag,
    required this.onDragEnd,
    required this.isCurrent,
  });

  final ViewerItem item;
  final AttachmentStore store;

  /// Whether this is the page the pager is actually on. **`PLAN.md` §8.5.**
  ///
  /// Only the current page carries the `Hero`. A `PageView` builds its
  /// neighbours ahead of time, and three heroes sharing a tag in one subtree is
  /// an assertion failure rather than a wrong-looking animation.
  final bool isCurrent;

  /// Play this page's clip. **ISSUE 15.** Never called on a photograph.
  final VoidCallback onPlay;
  final VoidCallback onChrome;
  final ValueChanged<bool> onZoom;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTo;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final to = _zoomTo;
      if (to != null) _controller.value = to.value;
    });
    _controller.addListener(() {
      widget.onZoom(_isZoomed);
      _onView();
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _controller.dispose();
    _settle?.cancel();
    _detail?.dispose();
    _detail = null;
    _source = null;
    super.dispose();
  }

  bool get _isZoomed => _controller.value.getMaxScaleOnAxis() > 1.02;

  // ══ THE SHARP PATCH — ISSUE IMPORTANT, AND HIS CORRECTION TO IT ═══════════
  //
  // *"When I zoom photos sometimes the app closes."* …and then, mid-round:
  // *"nah I want you to make it possible to view tall screenshots too!"*
  //
  // The whole argument is on `core/media/picture_region.dart`. What happens
  // here is the last two steps of it:
  //
  //   * the picture underneath is decoded **whole, within a pixel budget**, so
  //     opening any photograph — a 4:3 snapshot or a screenshot of a whole web
  //     page — costs a fixed and small amount, and cannot kill the process;
  //   * and the moment somebody pinches in, the rectangle they are actually
  //     looking at is decoded again at full detail and laid over the top.
  //
  // The second decode is bounded by the screen, so it costs the same whatever
  // it is a rectangle *of*. That is the sentence that lets a very tall
  // screenshot be both safe and readable, which is what he asked for and which
  // one dial could never have given.
  //
  // The same shape as the PDF reader, deliberately, down to sharing
  // `ZoomTile`. It was already the right answer to this and nobody had noticed
  // it was general.

  /// The stored file, kept only while zoomed in.
  ///
  /// Compressed bytes, not pixels — a few megabytes for a photograph, and it
  /// buys not decrypting the file again on every pan. Dropped on the way back
  /// out, so a person who pinches once does not hold it for the session.
  Uint8List? _source;

  /// The picture's true size, from the database where it is known and from the
  /// file's own header where it is not.
  Size? _sourceSize;

  /// The sharp rectangle currently drawn over the base picture, and where.
  ui.Image? _detail;
  Rect? _detailRect;

  Size? _childSize;
  bool _working = false;
  bool _again = false;
  Timer? _settle;

  /// Called on every frame of a pinch or a pan.
  ///
  /// Debounced rather than acted on: decoding a region while the fingers are
  /// still moving would queue a decode per frame, and every one of them would
  /// be stale before it finished. Waiting for the gesture to settle costs a
  /// fifth of a second of softness at the end of a pinch and saves doing the
  /// work sixty times.
  void _onView() {
    if (!_isZoomed) {
      if (_detail != null || _source != null) _dropDetail();
      return;
    }
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 180), _renderDetail);
  }

  void _dropDetail() {
    _settle?.cancel();
    final old = _detail;
    setState(() {
      _detail = null;
      _detailRect = null;
      // Back at 1:1 there is nothing to be sharp about, and holding the file's
      // bytes for a picture nobody is looking into is the memory this whole
      // change exists to stop spending.
      _source = null;
      _sourceSize = null;
    });
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  Future<void> _renderDetail() async {
    final picture = widget.item.picture;
    final laidOut = _childSize;
    if (!mounted || picture == null || laidOut == null) return;
    if (!_isZoomed) return;
    if (_working) {
      _again = true;
      return;
    }
    _working = true;
    try {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final bytes = _source ??= await widget.store
          .readAllBytesOffThread(picture.id, picture.fileKey);
      if (!mounted || !_isZoomed) return;

      // The database usually knows, because the importer measured it. When it
      // does not — an old row, or a format the importer could not read — the
      // header is asked directly, which decodes nothing.
      final size = _sourceSize ??=
          (picture.width != null && picture.height != null
              ? Size(picture.width!.toDouble(), picture.height!.toDouble())
              : await PictureRegion.measure(bytes));
      if (!mounted || !_isZoomed) return;
      if (size.width < 1 || size.height < 1) return;

      // What is on the glass right now, in the box's own coordinates. The
      // child of the `InteractiveViewer` **is** the box, so this is the case
      // `ZoomTile` was written for and its guarantee applies unchanged: a
      // rectangle clipped to the viewport can never need more device pixels
      // than the viewport has.
      final tile = ZoomTile.of(
        child: laidOut,
        view: _controller.value,
        baseWidth: (laidOut.width * dpr).round(),
      );
      if (tile == null) return;

      // `BoxFit.contain` letterboxes the picture inside that box, so most of
      // what is visible at 1:1 is not picture at all. Only the overlap is
      // worth asking the decoder for — and at the edges of a pan, the overlap
      // is a good deal smaller than the screen.
      final drawn = _containedRect(laidOut, size);
      final visible = tile.rect.intersect(drawn);
      if (visible.width < 1 || visible.height < 1) return;

      // Device pixels for the overlap, in the same terms ZoomTile used for the
      // whole viewport. Bounded above by `tile.width`, which is bounded by the
      // viewport, which is the property this whole change turns on.
      final targetWidth =
          (visible.width / tile.rect.width * tile.width).round().clamp(64, 4096);

      final toSource = size.width / drawn.width;
      final image = await PictureRegion.decode(
        bytes: bytes,
        region: Rect.fromLTRB(
          (visible.left - drawn.left) * toSource,
          (visible.top - drawn.top) * toSource,
          (visible.right - drawn.left) * toSource,
          (visible.bottom - drawn.top) * toSource,
        ),
        targetWidth: targetWidth,
      );

      if (!mounted || !_isZoomed) {
        image.dispose();
        return;
      }
      final old = _detail;
      setState(() {
        _detail = image;
        _detailRect = visible;
      });
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    } catch (_) {
      // The base picture is already on screen and legible. A phone that cannot
      // region-decode this file simply keeps showing it, which is exactly what
      // it did before any of this was written — so there is nothing to tell
      // anybody about.
    } finally {
      _working = false;
      if (_again && mounted) {
        _again = false;
        _renderDetail();
      }
    }
  }

  /// How many pixels the picture underneath is allowed to decode to.
  ///
  /// Twice the screen's own pixel count. Two, rather than one, because the
  /// picture is letterboxed — a very tall picture in a portrait window uses a
  /// fraction of the screen's width, so a budget of exactly one screenful would
  /// make an ordinary photograph slightly softer than it needs to be for the
  /// sake of the rare one. Two is generous for the common case and still a hard
  /// ceiling for the pathological one:
  ///
  /// | | screen | budget | worst case decoded |
  /// |---|---|---|---|
  /// | Vivo V2318 | 1260 × 2800 | 7.0 MP | 28 MB |
  /// | Redmi Pad | 1200 × 2000 | 4.8 MP | 19 MB |
  ///
  /// Three pages of that alive at once is 84 MB at the very worst, against a
  /// previous worst case with no ceiling on it at all. And it is what the
  /// picture costs *whatever it is* — the number does not move when somebody
  /// imports a panorama.
  static int _basePixelBudget(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screen = size.width * dpr * size.height * dpr;
    // Floors so a test bench with a tiny surface still gets a sane number.
    return (screen * 2).round().clamp(2 * 1024 * 1024, 16 * 1024 * 1024);
  }

  /// Where a picture of [source] ends up inside [box] under `BoxFit.contain`.
  ///
  /// Pure, and public to the library so `zoom_tile_test.dart` can check the
  /// letterbox arithmetic without a picture. Getting this wrong does not crash
  /// anything — it draws the sharp patch a few pixels out of register, which is
  /// far harder to notice and far more annoying than a crash.
  static Rect _containedRect(Size box, Size source) {
    final scale = math.min(box.width / source.width, box.height / source.height);
    final width = source.width * scale;
    final height = source.height * scale;
    return Rect.fromLTWH(
      (box.width - width) / 2,
      (box.height - height) / 2,
      width,
      height,
    );
  }

  /// ══ ROUND EIGHT, ISSUE 4A — WHY THE PINCH FAILED NINE TIMES IN TEN ══
  ///
  /// *"So hard to view a photo dude! Double tap is better — when I try to
  /// pinch the screen it fails! After 10 failed tries I get once the pinch
  /// right!"*
  ///
  /// Ten tries and one success is not a flaky gesture, it is a **race with a
  /// rigged finish line**, and the numbers are the whole story.
  ///
  /// The page used to carry its own `VerticalDragGestureRecognizer` for
  /// pull-down-to-close, competing in the same gesture arena as the
  /// `ScaleGestureRecognizer` inside `InteractiveViewer`. Both declare victory
  /// by crossing a distance threshold, and **their thresholds are not the
  /// same**:
  ///
  ///   * a drag recogniser accepts at `kTouchSlop`, **18 logical pixels**, on
  ///     one finger;
  ///   * the scale recogniser accepts at `kPanSlop`, **36**, or once the span
  ///     between two fingers has changed by `kScaleSlop`, 18.
  ///
  /// Fingers do not land at the same millisecond. The first one down starts
  /// moving before the second arrives, and the moment its vertical travel
  /// passed eighteen pixels the drag had already won — before the scale
  /// recogniser had two fingers to measure a span between. The photograph did
  /// not zoom; it started sliding towards being dismissed. Measured here across
  /// a sweep of "how far did the first finger drift before the second landed":
  /// **at a drift of 20 and 30 pixels the pinch produced no zoom at all.**
  ///
  /// The guard that was already here — `_isZoomed ? null : …` — could not
  /// help. It disables the drag once you are **already** zoomed in, and a pinch
  /// is the thing you do when you are not.
  ///
  /// **So the competing recogniser is gone.** Dismissing is driven by
  /// `InteractiveViewer`'s own interaction callbacks instead, which means there
  /// is exactly one recogniser handling both the pinch and the pull, and no
  /// arena to lose. What that leaves is a set of thresholds that happen to be
  /// exactly right:
  ///
  ///   * **Pinch** — span changes by 18, scale accepts, nothing competes.
  ///   * **Pull down** — needs 36 rather than 18, so it is slightly firmer than
  ///     it was, which is the correct direction for a gesture that closes
  ///     something.
  ///   * **Swipe sideways** — the `PageView` still wins, because its horizontal
  ///     drag accepts at 18 and this only accepts at 36. Album swiping is
  ///     untouched, which is the thing round six fixed and this must not undo.
  ///
  /// `album_viewer_test.dart` sweeps the drift and asserts all three.
  ///
  /// How many fingers this gesture has had at any point. Latched to the
  /// maximum, so lifting one finger of a pinch does not turn the remaining one
  /// into a dismissal halfway through.
  int _fingers = 0;

  /// Whether the current one-finger gesture has committed to closing.
  bool _dismissing = false;

  /// Travel so far, for deciding whether it has declared itself vertical.
  Offset _travel = Offset.zero;

  /// Double tap zooms to the point you tapped, not to the middle. Zooming to
  /// the centre when somebody double-tapped a face in the corner is the most
  /// common small annoyance in photo viewers.
  void _doubleTap(TapDownDetails details) {
    final target = _isZoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(
              -details.localPosition.dx,
              -details.localPosition.dy,
              0,
              1,
            )
            ..scaleByDouble(2.5, 2.5, 1, 1));
    _zoomTo = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(CurvedAnimation(parent: _zoom, curve: Curves.easeOutCubic));
    _zoom.forward(from: 0);
  }

  /// A gesture began. **ISSUE 4A.**
  void _interactionStart(ScaleStartDetails details) {
    _fingers = details.pointerCount;
    _dismissing = false;
    _travel = Offset.zero;
  }

  /// The only place drag-to-dismiss lives now. **ISSUE 4A.**
  void _interactionUpdate(ScaleUpdateDetails details) {
    // Latched, not read fresh: a pinch whose second finger comes up early must
    // not become a pull-to-close for its last few pixels.
    if (details.pointerCount > _fingers) _fingers = details.pointerCount;

    if (_fingers > 1 || _isZoomed) {
      // Turned into a pinch, or the picture is zoomed and this is a pan. Put
      // back anything already given away.
      if (_dismissing) {
        _dismissing = false;
        widget.onDragEnd(0);
      }
      return;
    }

    if (!_dismissing) {
      _travel += details.focalPointDelta;
      // Committed only once it is clearly a downward or upward pull rather
      // than a sideways one — otherwise a diagonal album swipe would drag the
      // picture away as it went.
      if (_travel.dy.abs() < 8 || _travel.dy.abs() < _travel.dx.abs()) return;
      _dismissing = true;
    }
    widget.onDrag(details.focalPointDelta.dy);
  }

  /// **ISSUE 4A.**
  void _interactionEnd(ScaleEndDetails details) {
    if (_dismissing) widget.onDragEnd(details.velocity.pixelsPerSecond.dy);
    _dismissing = false;
    _fingers = 0;
    _travel = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onChrome,
      // Double-tap zoom is for photographs. A poster frame has no detail to
      // magnify, and zooming one would leave the play button floating over a
      // blown-up thumbnail.
      onDoubleTapDown: widget.item.isVideo ? null : _doubleTap,
      onDoubleTap: widget.item.isVideo ? null : () {},
      // ISSUE 4A. There is deliberately **no drag recogniser here any more**.
      // It was the thing beating the pinch to the arena. See `_fingers`.
      child: InteractiveViewer(
        transformationController: _controller,
        maxScale: 8,
        // ISSUE 4A. Dismissing rides the scale recogniser rather than
        // competing with it.
        onInteractionStart: _interactionStart,
        onInteractionUpdate: _interactionUpdate,
        onInteractionEnd: _interactionEnd,
        // Nothing to pan at 1:1, and leaving it on is what would let this
        // recogniser take a sideways drag away from the `PageView`.
        panEnabled: _isZoomed,
        // **The fix.** `Positioned.fill` gives the image the whole screen, and
        // only then does `BoxFit.contain` have anything to fit inside. Without
        // it the image draws at its intrinsic pixel size — see the class note
        // on PhotoViewer.
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(builder: (context, box) {
                // The one place that knows how big the picture's box is. The
                // sharp patch is positioned in these coordinates.
                _childSize = box.biggest;
                final picture = _picture(context);
                // ── The flight, on the page that was tapped ──────────────
                //
                // Only the current page. A `PageView` builds its neighbours
                // ahead of time, and three `Hero`s sharing a tag in one subtree
                // is an assertion failure rather than a wrong-looking
                // animation — see `heroTagFor`.
                if (!widget.isCurrent) return picture;
                return Hero(
                  tag: heroTagFor(widget.item.attachment.id),
                  // The tile is `cover` and this is `contain`, so the picture
                  // changes shape as it flies. Left to itself Flutter would
                  // interpolate the two `Image` widgets and the aspect would
                  // jump at the end; a plain box that fades is what makes the
                  // shape change read as the picture opening out.
                  flightShuttleBuilder:
                      (_, animation, direction, fromContext, toContext) =>
                          FadeTransition(
                    opacity: animation.drive(
                      Tween<double>(begin: 0.85, end: 1),
                    ),
                    child: toContext.widget,
                  ),
                  child: picture,
                );
              }),
            ),

            // ── The sharp patch ──────────────────────────────────────────
            //
            // Only ever present while zoomed in, only ever as big as the
            // screen, and drawn exactly over the part of the base picture it
            // was decoded from. `BoxFit.fill` rather than `contain`: the
            // rectangle it is going into is the rectangle it came out of, so
            // there is nothing left to fit.
            if (_detail != null && _detailRect != null)
              Positioned.fromRect(
                rect: _detailRect!,
                child: RawImage(image: _detail, fit: BoxFit.fill),
              ),

            // ── ISSUE 15 — the clip, on its own page in the album ────────
            //
            // A still with a play button on it, which is what every gallery on
            // the phone shows and what this album's own tiles already showed.
            // The pager was the only place in the app that pretended videos
            // were not there.
            //
            // Not positioned over a zoomed photograph, because a video page
            // cannot be zoomed — there is nothing to zoom into but a thumbnail.
            if (widget.item.isVideo)
              Positioned.fill(
                child: Center(
                  child: _CircleButton(
                    icon: Icons.play_arrow_rounded,
                    label: L.of(context).photoPlayVideo,
                    onTap: widget.onPlay,
                    large: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// What is drawn on this page: the photograph, or a clip's poster frame.
  Widget _picture(BuildContext context) {
    final picture = widget.item.picture;
    if (picture == null) {
      // A video imported before poster frames existed. A flat ground under the
      // play button is honest and is what the album tile does; decoding a frame
      // here would mean decrypting the whole clip to draw a still nobody asked
      // for.
      final c = context.lamplight;
      return ColoredBox(color: c.raised, child: const SizedBox.expand());
    }
    return Image(
      image: EncryptedImage(
        picture,
        store: widget.store,
        // Full screen, at the screen's real resolution, and **no headroom**.
        //
        // It used to ask for twice the screen's width, so that a pinch did not
        // immediately reveal a soft picture. That headroom is where ISSUE
        // IMPORTANT lived: doubling the width quadruples the pixels, a decoded
        // pixel is four bytes, the pager keeps three pages alive, and nothing
        // capped the *height* at all — so one long screenshot was hundreds of
        // megabytes and the process was killed mid-pinch.
        //
        // The headroom is not needed any more, because there is something
        // better in its place: pinching in now decodes the rectangle being
        // looked at, at full detail, from the file itself. See `_renderDetail`.
        // Sharper than the old 2× ever was, at a fraction of the memory, and it
        // does not care how tall the picture is.
        maxWidth: (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(720, 4096),
        // And the backstop, which is the part that cannot be defeated by an
        // aspect ratio nobody thought of. See `EncryptedImage.maxPixels`.
        maxPixels: _basePixelBudget(context),
      ),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, _) => _Unopenable(
          message: plainFailure(error,
              fallback: L.of(context).photoCouldNotOpen,
              andThen: L.of(context).photoMayBeDamaged,
          words: L.of(context))),
      frameBuilder: (context, child, frame, wasSync) {
        if (frame != null || wasSync) return child;
        return const Center(child: LampBusyDot(size: 34));
      },
    );
  }
}

/// A round button that stays legible on top of a photograph of anything.
///
/// A bare white glyph disappears against a snowfield and a bare dark one
/// disappears against a night sky. The scrim behind it is not decoration, it is
/// what makes the control reliably visible — the same reason every camera app
/// on earth has one.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.large = false,
  });

  /// The play control on a video page, which is the one case where this is the
  /// subject of the screen rather than chrome at its edge. **ISSUE 15.**
  final bool large;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            // The play control on a video page is the subject of the screen,
            // not chrome at its edge, so it is drawn at the size a gallery
            // draws one. Everything else stays at the tap-target floor.
            width: large ? 72 : kMinTouchTarget,
            height: large ? 72 : kMinTouchTarget,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.canvas.withValues(alpha: large ? 0.62 : 0.55),
            ),
            child: Icon(icon, color: c.inkPrimary, size: large ? 40 : 22),
          ),
        ),
      ),
    );
  }
}

class _Unopenable extends StatelessWidget {
  const _Unopenable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 32, color: c.inkMuted),
            const SizedBox(height: Space.x4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyLarge?.copyWith(color: c.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The smallest form of the busy indicator: one pulse, no words.
///
/// Used where a label would be noise because the surrounding screen has
/// already said what is happening.
class LampBusyDot extends StatefulWidget {
  const LampBusyDot({super.key, this.size = 28});

  final double size;

  @override
  State<LampBusyDot> createState() => _LampBusyDotState();
}

class _LampBusyDotState extends State<LampBusyDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.repeat();
      }
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = (0.5 - 0.5 * (_c.value * 2 - 1).abs()).clamp(0.0, 1.0);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Container(
              width: widget.size * (0.34 + 0.16 * v),
              height: widget.size * (0.34 + 0.16 * v),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.45 + 0.45 * v),
              ),
            ),
          ),
        );
      },
    );
  }
}
