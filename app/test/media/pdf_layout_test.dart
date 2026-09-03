import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/pdf_render.dart';
import 'package:lamplight/features/media/pdf_layout.dart';

/// **ROUND FIFTEEN, ISSUE 8 — the arithmetic under four of his complaints.**
///
/// > *"IMAGINE HAVING A PDF SIZE – 50MB not an issue yes – scroll to 50th page
/// > and see that doesn't even show me! Imagine a pdf is 40MB and has 10 pages
/// > – shows only first two pages other pages? When zoomed glitches – When
/// > scroll down Fastly down to the end it behaves jerky and when scrolled up
/// > Fastly – feels jerky!"*
///
/// Two of those — the jerk and the page that is not where the number says —
/// come from the same thing, and it is measurable rather than a matter of
/// feel: **the viewer did not know how tall a page was until it had drawn
/// it.** Every page was laid out as A4 and then took its real shape when its
/// bitmap arrived, moving everything below it and the scroll offset with it.
/// The page number was `scrollFraction x (pages - 1)`, which is exactly right
/// when every page is identical and wrong the rest of the time.
///
/// These tests are the fix stated as numbers. The two that matter most are
/// *"a document of mixed pages does not move as it renders"* and *"the page
/// number is the page you are looking at"*.
void main() {
  /// A document where every page is a different shape — a scan, a photograph,
  /// a wide table. The uniform case is the easy one and it is not the one that
  /// was broken.
  PdfLayout mixed({double width = 600}) => PdfLayout(
        pages: 5,
        width: width,
        // A4, square, landscape, tall, A4 again.
        shapeOf: (i) => const [1.414, 1.0, 0.7, 2.2, 1.414][i],
        padding: 16,
        gap: 16,
      );

  group('where the pages are', () {
    test('the first begins below the padding', () {
      expect(mixed().offsetOf(0), 16);
    });

    test('each one begins where the last one ended, plus the gap', () {
      final l = mixed();
      expect(l.offsetOf(1), 16 + 600 * 1.414 + 16);
      expect(l.offsetOf(2), l.offsetOf(1) + 600 * 1.0 + 16);
      expect(l.offsetOf(3), l.offsetOf(2) + 600 * 0.7 + 16);
    });

    test('the whole list is as long as its pages, and no longer', () {
      final l = mixed();
      final pages = 600 * (1.414 + 1.0 + 0.7 + 2.2 + 1.414);
      expect(l.extent, closeTo(pages + 4 * 16 + 2 * 16, 0.001));
    });

    test('a wider column makes a taller list, in proportion', () {
      // Which is why the layout is rebuilt when the column changes — a rotation
      // or a split-screen resize is not a redraw, it is a different document
      // shape. **ISSUE 12** meets ISSUE 8 here.
      expect(mixed(width: 1200).extent - 5 * 16 - 16,
          closeTo((mixed(width: 600).extent - 5 * 16 - 16) * 2, 0.001));
    });
  });

  group('which page you are on', () {
    test('is the page whose top you have most recently passed', () {
      final l = mixed();
      expect(l.pageAt(0), 0);
      expect(l.pageAt(l.offsetOf(1) - 5), 0, reason: 'still on the first');
      expect(l.pageAt(l.offsetOf(1)), 1);
      expect(l.pageAt(l.offsetOf(3) + 100), 3);
      expect(l.pageAt(l.extent * 2), 4, reason: 'past the end is the last page');
    });

    test('and it round-trips with going there, which it did not before', () {
      // This is the assertion behind "scroll to 50th page and it doesn't even
      // show me". The old code computed the offset from a fraction of the
      // total and read the page back the same way, so on a document of mixed
      // pages the two disagreed with each other.
      final l = PdfLayout(
        pages: 60,
        width: 686,
        shapeOf: (i) => i.isEven ? 1.414 : 0.75,
      );
      for (final page in [0, 1, 7, 49, 50, 59]) {
        expect(l.pageAt(l.offsetOf(page)), page, reason: 'page $page');
      }
    });

    test('the old estimate lands on the wrong page, measurably', () {
      // Kept as a measured counter-example, so the thing that was wrong stays
      // a number rather than becoming folklore.
      final l = PdfLayout(
        pages: 60,
        width: 686,
        shapeOf: (i) => i < 30 ? 3.0 : 0.4,
      );
      final offset = l.offsetOf(50);
      final estimated = (offset / l.extent * (l.pages - 1)).round();
      expect(l.pageAt(offset), 50);
      expect((estimated - 50).abs(), greaterThan(3),
          reason: 'the fraction of the way down a document is not the fraction '
              'of the way through its pages unless every page is the same');
    });
  });

  group('documents that would otherwise divide by something', () {
    test('one page', () {
      final l = PdfLayout(pages: 1, width: 600, shapeOf: (_) => 1.414);
      expect(l.pageAt(0), 0);
      expect(l.pageAt(99999), 0);
      expect(l.offsetOf(0), 16);
    });

    test('no pages at all', () {
      final l = PdfLayout(pages: 0, width: 600, shapeOf: (_) => 1.414);
      expect(l.pageAt(0), 0);
      expect(l.offsetOf(0), greaterThanOrEqualTo(0));
      expect(l.extent.isFinite, isTrue);
    });

    test('a page whose shape could not be measured falls back to A4', () {
      // `MemoryPdf.measure` leaves a page it cannot open at 1.414, and a
      // platform that does not measure at all returns an empty list. Neither
      // may produce a NaN height, which would take the whole list with it.
      for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
        final l = PdfLayout(pages: 2, width: 600, shapeOf: (_) => bad);
        expect(l.extent.isFinite, isTrue, reason: '$bad');
        expect(l.extent, greaterThan(600), reason: '$bad');
      }
    });
  });

  group('what the platform said the document was', () {
    test('a shape it measured is the shape it gives back', () {
      const open = OpenPdf(pages: 3, shapes: [1.5, 1.0, 0.8]);
      expect(open.shapeOf(1), 1.0);
    });

    test('a page past what it measured is A4, not a crash', () {
      // Very long documents are measured up to a cap; past it the viewer does
      // exactly what it always did.
      const open = OpenPdf(pages: 9000, shapes: [1.5]);
      expect(open.shapeOf(8000), 1.414);
      expect(open.shapeOf(-1), 1.414);
    });

    test('a platform that measures nothing still lays out', () {
      const open = OpenPdf(pages: 4, shapes: []);
      final l = PdfLayout(pages: 4, width: 600, shapeOf: open.shapeOf);
      expect(l.extent, greaterThan(0));
      expect(l.pageAt(l.offsetOf(2)), 2);
    });
  });
}
