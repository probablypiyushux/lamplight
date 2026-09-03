import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/media/pdf_layout.dart';

/// **"I OPEN THAT PDF AGAIN — IT NEVER LOADS."** 2 September 2026.
///
/// > *"Say me a way — i am in a pdf which size is 25 mb and has 165 pages! Last
/// > time i opened that — and stopped it on 145 page number! Now i open that
/// > pdf again — it never loads — to make it load — i need to go to page one
/// > and slowly go to 145 page!"*
///
/// Three separate faults, all of which had to be present for this symptom, and
/// each of which is invisible on a phone with a short document.
///
/// ── ONE. THE LIST DID NOT KNOW HOW LONG IT WAS ──────────────────────────────
///
/// `ListView.builder` with no item extent estimates `maxScrollExtent` from the
/// children it has built. On the first frame that is two or three pages.
/// `_goTo` clamped the restore target to that estimate, so a jump to page 145
/// was clamped to somewhere near page three — and `_restore` sets `_restored`
/// before jumping, so nothing ever tried again. Fixed with `itemExtentBuilder`,
/// which is exact from the first frame because every page's shape was measured
/// when the document opened.
///
/// ── TWO. THE LAYOUT WAS MEASURED AT THE WRONG WIDTH ─────────────────────────
///
/// `PdfLayout` was built with `min(box.maxWidth - gutter * 2, Layout.maxColumn)`
/// while the pages were drawn at `box.maxWidth - gutter * 2` — `LampColumnWidth`
/// is a pass-through since ISSUE 6b. Identical on a phone, different on a
/// tablet, and the error accumulates. **That is what the first group below
/// measures**, and the number it produces is the reason this is not a rounding
/// detail.
///
/// ── THREE. THE RENDER WAS DROPPED, NOT DELAYED ──────────────────────────────
///
/// Every page asks `stillWanted: (i - _current.value).abs() <= 3` before it may
/// render — a guard added in round fifteen so a fling could not queue thirty
/// dead renders. `_current` started at `0`, so on the way in to page 145 the
/// answer was false and the render was thrown away before it reached the
/// channel. That is the literal "never loads": the page was built, it asked,
/// and the guard said no. Scrolling up from page one worked because it walks
/// `_current` along with it. `_current` now starts at the page being restored.
void main() {
  // His document: 165 pages, and a scan is not perfectly uniform, so a mix of
  // ordinary page shapes rather than 165 identical ones.
  double shapeOf(int i) => switch (i % 4) {
        0 => 1.414, // A4 portrait
        1 => 1.294, // US Letter
        2 => 1.5, // a slightly taller scan
        _ => 1.414,
      };

  PdfLayout at(double width) => PdfLayout(
        pages: 165,
        width: width,
        shapeOf: shapeOf,
        padding: Space.x4,
        gap: Space.x4,
      );

  group('the width the layout is measured at is the width pages are drawn at',
      () {
    // The Redmi Pad this app is judged on: 686 points wide in portrait.
    const tablet = 686.0;
    final drawn = tablet - Layout.gutter * 2; // 638 — what a page really gets
    final capped =
        (tablet - Layout.gutter * 2).clamp(0.0, Layout.maxColumn); // 608 — what
    // the layout used to assume

    test('and on a tablet those were different numbers', () {
      expect(drawn, greaterThan(capped),
          reason: 'If these are equal the test is measuring nothing. '
              'LampColumnWidth is a pass-through, so a page fills the gutters.');
    });

    test('being 5% out is seven pages out by page 145', () {
      final truth = at(drawn);
      final believed = at(capped);

      // Where the old arithmetic would have sent somebody asking for page 145.
      final landedAt = truth.pageAt(believed.offsetOf(145));

      expect(landedAt, lessThan(140),
          reason: 'A five per cent error per page does not matter on page two '
              'and is several pages by page 145. This is why the badge '
              'disagreed with the page under it on a tablet and on no phone.');
      expect(145 - landedAt, greaterThanOrEqualTo(5),
          reason: 'Stated as a number so nobody reads this as rounding.');
    });

    test('and measured correctly, the page you ask for is the page you get', () {
      final l = at(drawn);
      for (final page in [0, 1, 42, 99, 144, 145, 164]) {
        expect(l.pageAt(l.offsetOf(page)), page,
            reason: 'asked for $page');
      }
    });
  });

  group('the list knows how long it is before it is built', () {
    test('the item extent matches the layout stride exactly', () {
      // `itemExtentBuilder` hands the list `column * shape + gap` per page.
      // If that ever disagrees with `PdfLayout`, offsets drift again — which
      // is the entire class of bug above, reintroduced.
      const width = 638.0;
      final l = at(width);

      for (var i = 1; i < 165; i++) {
        final stride = l.offsetOf(i) - l.offsetOf(i - 1);
        final itemExtent = width * shapeOf(i - 1) + Space.x4;
        expect(stride, closeTo(itemExtent, 0.001),
            reason: 'page ${i - 1} to $i: the list and the layout must agree '
                'about how tall a page is, or the jump lands somewhere else');
      }
    });

    test('page 145 of 165 is a long way down, which is the whole point', () {
      final l = at(638);
      // The number that used to be clamped away to almost nothing.
      expect(l.offsetOf(145), greaterThan(100000),
          reason: 'An estimated maxScrollExtent from three built pages is a '
              'few thousand points. Clamping this to that is how a jump to '
              'page 145 became a jump to page three.');
      expect(l.extent, greaterThan(l.offsetOf(164)));
    });
  });
}
