import 'dart:ui' show Rect, Size;

import 'package:flutter/material.dart' show Matrix4, MatrixUtils, Offset;

/// What to ask the renderer for, given where the reader is looking.
///
/// **Round six's ISSUE 1 — "PDF ZOOM CRASH!" — and round nine's ISSUE
/// IMPORTANT, which turned out to be the same sentence about a different
/// rectangle.**
///
/// This is the arithmetic that keeps anything zoomable inside a fixed memory
/// budget, pulled out of the widget so it can be checked without a phone. The
/// property it exists to guarantee is one sentence long:
///
/// > However far in the reader zooms, the bitmap asked for is never bigger
/// > than the one the unzoomed page already uses.
///
/// The old PDF code did the opposite — it asked for the whole page at 2x, then
/// 4x, which is how a 95 MB bitmap and a dead process happen. See `MemoryPdf.kt`
/// for that story in full.
///
/// ── WHY IT IS NOT CALLED `PdfTile` ANY MORE ─────────────────────────────────
///
/// Because photographs have the same problem and it took a crash to notice.
/// *"When I zoom photos sometimes the app closes."* A decoded photograph is
/// four bytes a pixel, a long screenshot is tens of thousands of pixels tall,
/// and the viewer was decoding the whole thing at twice the screen's width.
///
/// The tempting fix is to decode it smaller, and it is wrong: he answered it
/// before it was finished — *"nah I want you to make it possible to view tall
/// screenshots too!"* A picture you cannot read when you zoom in is not a
/// picture that has been made safe, it is a picture that has been taken away.
///
/// The right answer was already in this file, written for PDFs six weeks
/// earlier and never noticed to be general. **Bound the memory by the screen,
/// not by the document.** A screen is a fixed number of pixels; ask for what is
/// on it and nothing else, and the size of the thing you are looking into stops
/// mattering entirely.
///
/// One piece of arithmetic, one test — `zoom_tile_test.dart` covers both
/// callers, because a bug in it would be a crash in both.
class ZoomTile {
  const ZoomTile({
    required this.rect,
    required this.region,
    required this.width,
  });

  /// Where the tile goes, in the page widget's own coordinates.
  final Rect rect;

  /// The same rectangle expressed against the page, 0..1 on both axes. This is
  /// what crosses the method channel, because the renderer thinks in pages and
  /// knows nothing about widgets.
  final Rect region;

  /// How many device pixels across to draw it.
  final int width;

  /// The tile for a page of laid-out size [child], currently transformed by
  /// [view], first rasterised at [baseWidth] device pixels across.
  ///
  /// Returns null when there is nothing sensible to ask for — a degenerate
  /// size, a singular transform, or a viewport that has been panned entirely
  /// off the paper.
  static ZoomTile? of({
    required Size child,
    required Matrix4 view,
    required int baseWidth,
    int maxWidth = 4096,
  }) {
    if (child.width <= 0 || child.height <= 0 || baseWidth <= 0) return null;

    final Matrix4 inverse;
    try {
      inverse = Matrix4.inverted(view);
    } catch (_) {
      return null;
    }

    // What the viewport is looking at, trimmed to the paper — at the edge of a
    // zoom the viewport sees past the page, and there is nothing there to draw.
    final seen = MatrixUtils.transformRect(inverse, Offset.zero & child);
    final rect = Rect.fromLTRB(
      seen.left.clamp(0.0, child.width),
      seen.top.clamp(0.0, child.height),
      seen.right.clamp(0.0, child.width),
      seen.bottom.clamp(0.0, child.height),
    );
    if (rect.width < 1 || rect.height < 1) return null;

    // The ratio between the page's laid-out width and the width it was first
    // rasterised at *is* the device pixel ratio, so it does not need asking for
    // separately — and cannot drift from the value the base render used.
    final dpr = baseWidth / child.width;
    final scale = view.getMaxScaleOnAxis();

    // The device pixels this rectangle actually occupies on the glass. Because
    // `rect` is clipped to the viewport, `rect.width * scale` can never exceed
    // the viewport's own width, so this can never exceed `baseWidth` — which is
    // the whole guarantee, in one line.
    final width = (rect.width * scale * dpr).round().clamp(64, maxWidth);

    return ZoomTile(
      rect: rect,
      region: Rect.fromLTRB(
        rect.left / child.width,
        rect.top / child.height,
        rect.right / child.width,
        rect.bottom / child.height,
      ),
      width: width,
    );
  }
}
