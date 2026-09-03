import 'dart:math' as math;

/// Where every page of a document sits in the list. **ROUND FIFTEEN, ISSUE 8.**
///
/// > *"IMAGINE HAVING A PDF SIZE – 50MB not an issue yes – scroll to 50th page
/// > and see that doesn't even show me! ... When scroll down Fastly down to the
/// > end it behaves jerky and when scrolled up Fastly – feels jerky!"*
///
/// ── BOTH OF THOSE ARE ONE ABSENCE ────────────────────────────────────────
///
/// The viewer did not know how tall a page was until it had drawn it. So every
/// page was laid out as A4, and each one took its real shape the moment its
/// bitmap arrived — which moves everything below it, which moves the scroll
/// offset under the finger. That is what "jerky" is, and it cannot be smoothed
/// away, because the list genuinely is changing length while you are holding
/// it.
///
/// The same absence made the page number an estimate:
/// `scrollFraction x (pages - 1)`, which is exactly right when every page is
/// identical and wrong the rest of the time. The "open where you left it" jump
/// used the same arithmetic backwards, so it landed near the page rather than
/// on it — and the badge said a number that was not the page you were reading.
///
/// `MemoryPdf` measures every page's media box when the document opens. That is
/// a page-dictionary read with no rasterising in it — tens of milliseconds for
/// a whole book — and with the shapes in hand this class can say where each
/// page begins before a single one has been drawn.
///
/// ── WHY IT IS ITS OWN CLASS ──────────────────────────────────────────────
///
/// Same reason as `ZoomTile`: the arithmetic is the part that can be wrong, and
/// a `State` cannot be tested without a phone, a PDF and a finger.
/// `test/media/pdf_layout_test.dart` is the whole of it.
class PdfLayout {
  PdfLayout({
    required this.pages,
    required this.width,
    required double Function(int page) shapeOf,
    this.padding = 16,
    this.gap = 16,
  }) : _tops = List<double>.filled(math.max(pages, 0) + 1, 0) {
    var y = padding;
    for (var i = 0; i < pages; i++) {
      _tops[i] = y;
      // A shape that is not a positive number is A4, which is what the viewer
      // assumed for everything before this existed. A document whose shapes
      // could not be measured therefore behaves exactly as it used to rather
      // than not at all.
      final shape = shapeOf(i);
      y += width * (shape.isFinite && shape > 0 ? shape : 1.414) + gap;
    }
    _tops[pages] = y - gap + padding;
  }

  /// How many pages the document has.
  final int pages;

  /// The width of the column the pages are laid out in, in logical points.
  final double width;

  /// The list's own padding above the first page and below the last.
  final double padding;

  /// The space between one page and the next.
  final double gap;

  final List<double> _tops;

  /// The offset of the top of page [i] from the top of the list.
  double offsetOf(int i) => _tops[i.clamp(0, math.max(pages - 1, 0))];

  /// How long the whole list is.
  double get extent => _tops[math.max(pages, 0)];

  /// The page whose top has most recently passed [offset].
  ///
  /// Binary search rather than a walk: a four-hundred-page document is scrolled
  /// with a finger, and this runs on every scroll notification.
  int pageAt(double offset) {
    if (pages <= 1) return 0;
    var lo = 0, hi = pages - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      // The `+ 1` is slack for the fractional offsets a fling produces: landing
      // half a point above a page's top should already read as that page.
      if (_tops[mid] <= offset + 1) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
