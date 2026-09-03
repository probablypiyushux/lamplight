import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/paper.dart';

/// **ROUND EIGHT, ISSUE 7B — "isometric and traingles are half done and worst!"**
///
/// He was right, and "half done" was the literal truth rather than a figure of
/// speech. Both of the patterns he named have a family of lines leaning **down**
/// to the right, and neither of them drew all of it: the run of lines was
/// computed with a range that only works for a family leaning **up**, so about
/// the bottom-left third of the page had one diagonal and not the other.
///
/// ── WHY THIS IS A UNIT TEST AND NOT A WIDGET TEST ────────────────────────
///
/// A `CustomPainter` is the one part of a Flutter app that `pumpWidget` cannot
/// really see. It draws into a canvas and returns nothing, so "is the pattern
/// on the whole page" is not a question the widget tester can answer, and a
/// golden file would answer it only for the one screen size it was captured at
/// — which is exactly the wrong shape of test for a bug that depends on the
/// page's proportions.
///
/// A family of parallel lines is completely described by its angle and the list
/// of places it crosses `y = 0`. That list is a pure function of the page size,
/// and this file checks the property that matters directly: **from anywhere on
/// the page, there is a line of every family within half a gap.** No sampling
/// resolution to argue about, no screenshot to re-record, and it holds at every
/// size rather than at one.
void main() {
  /// The perpendicular distance from [p] to the line that crosses `y = 0` at
  /// [crossing] and runs at [degrees].
  ///
  /// `(dx, dy)` is a unit vector, so the cross product of it with the offset
  /// from a point on the line *is* the perpendicular distance.
  double distance(Offset p, double crossing, double degrees) {
    final r = degrees * math.pi / 180;
    return ((p.dx - crossing) * math.sin(r) - p.dy * math.cos(r)).abs();
  }

  /// The worst-covered point on the page: how far you can stand from the
  /// nearest line of this family.
  double worstGap(Size page, double gap, double degrees) {
    final lines = PagePattern.crossings(page, gap, degrees);
    expect(lines, isNotEmpty, reason: 'a family with no lines in it');
    var worst = 0.0;
    // A 40 × 40 lattice over the whole sheet, corners included. The bug being
    // guarded against was regional — a third of the page, always the same
    // third — so any sampling dense enough to land in that third finds it, and
    // 1600 points across a phone screen is one every twenty points or so.
    for (var i = 0; i <= 40; i++) {
      for (var j = 0; j <= 40; j++) {
        final p = Offset(page.width * i / 40, page.height * j / 40);
        var nearest = double.infinity;
        for (final line in lines) {
          final d = distance(p, line, degrees);
          if (d < nearest) nearest = d;
        }
        if (nearest > worst) worst = nearest;
      }
    }
    return worst;
  }

  // The four angles the two broken patterns are made of. Isometric is vertical
  // plus ±30; triangle is horizontal plus ±60. The vertical and horizontal
  // families are drawn directly by the painter and were never in question —
  // which is itself the clue, because Lines and Dot grid have no diagonals and
  // were the two patterns he did not complain about.
  const angles = <double>[30, -30, 60, -60];

  // Portrait and landscape, phone and tablet, plus a couple of extremes. The
  // old range depended on the page being taller than it was wide in one
  // particular way, so the shapes are the point.
  const pages = <Size>[
    Size(360, 800), // a small phone
    Size(412, 915), // a large phone
    Size(686, 1143), // the Redmi Pad he judges the app on. PLAN.md §0.
    Size(1024, 768), // wide
    Size(200, 2000), // a column
    Size(2000, 200), // a strip
  ];

  group('every family covers the whole page', () {
    for (final page in pages) {
      for (final degrees in angles) {
        test('${page.width.toInt()}×${page.height.toInt()} at '
            '${degrees.toInt()}°', () {
          const gap = 33.0; // roughly one line of writing at the default size
          final worst = worstGap(page, gap, degrees);

          // Half a gap is the best any family of parallel lines can do: stand
          // exactly between two of them and that is how far away they both are.
          // A tenth of a point of slack for the arithmetic.
          expect(worst, lessThanOrEqualTo(gap / 2 + 0.1),
              reason: 'somewhere on this page is $worst points from the '
                  'nearest ${degrees.toInt()}° line — that is the '
                  'empty region he called "half done"');
        });
      }
    }
  });

  test('the descending families are the ones that were broken', () {
    // The regression, stated as the number it actually was, so that the fix
    // cannot be undone by somebody restoring the "simpler" range.
    //
    // Old code: `for (x = -height/|sin| - step; x < width + step; x += step)`.
    // For a family leaning down to the right, the lines covering the bottom
    // left of the page cross y = 0 far to the *right* of the sheet, and that
    // loop stops at the right-hand edge.
    const page = Size(686, 1000);
    const gap = 33.0;

    for (final degrees in <double>[-30, -60]) {
      final lines = PagePattern.crossings(page, gap, degrees);
      final oldStop = page.width + gap / math.sin(degrees * math.pi / 180).abs();
      expect(lines.last, greaterThan(oldStop),
          reason: 'the lines that cover the bottom-left corner are beyond '
              'where the old loop gave up');
    }

    // And the ascending families, which always worked, still start far enough
    // to the left.
    for (final degrees in <double>[30, 60]) {
      expect(PagePattern.crossings(page, gap, degrees).first,
          lessThan(-page.height / 2));
    }
  });

  test('a family is spaced by the perpendicular gap, not the top-edge gap', () {
    // The property that stops a 30-degree family looking twice as crowded as a
    // 60-degree one. It held before this round and is asserted here because the
    // fix rewrote the loop that produces it.
    const page = Size(686, 1143);
    const gap = 33.0;
    for (final degrees in angles) {
      final lines = PagePattern.crossings(page, gap, degrees);
      final apart = (lines[1] - lines[0]) *
          math.sin(degrees * math.pi / 180).abs();
      expect(apart, closeTo(gap, 0.001),
          reason: 'at ${degrees.toInt()}° the lines are $apart apart');
    }
  });

  test('the pattern does not slide sideways when the page is resized', () {
    // The crossings are snapped to whole multiples of the step, so growing the
    // page adds lines at the ends rather than shifting every line already
    // drawn. Without it, rotating the phone or opening the keyboard would slide
    // the whole grid under the writing.
    const gap = 33.0;
    for (final degrees in angles) {
      final small = PagePattern.crossings(const Size(360, 800), gap, degrees);
      final large = PagePattern.crossings(const Size(360, 900), gap, degrees);
      for (final line in small) {
        expect(large.any((l) => (l - line).abs() < 0.001), isTrue,
            reason: 'line at $line vanished when the page grew');
      }
    }
  });

  test('a horizontal family is refused rather than divided by zero', () {
    // Every caller draws its horizontals directly, and asking this for them
    // would be an infinite run of lines an infinitesimal distance apart.
    expect(PagePattern.crossings(const Size(360, 800), 33, 0), isEmpty);
    expect(PagePattern.crossings(const Size(360, 800), 33, 180), isEmpty);
    expect(PagePattern.crossings(const Size(360, 800), 0, 30), isEmpty);
  });

  // ══ ROUND NINE, ISSUE 26 — "ISOMETRIC HAS FALLEN DOWN HERE" ═══════════════
  //
  // *"Look closely how isometric has fallen down here! Why does it does not
  // work on different screen sizes."* And beside the other pattern in the same
  // screenshot: *"Triangle have the same, look into it."*
  //
  // Round eight fixed **which** lines are drawn, and the tests above check
  // that and still pass. What it did not touch is **how far** each line is
  // drawn, which was `width + height` — a length that is sufficient only when
  // `height / |sin θ| ≤ width + height`, which is a fact about the page's
  // proportions. He said "different screen sizes" and he was reading it right
  // off the glass.
  //
  // These check the segment rather than the list. The property is the one a
  // person can see: **the drawn line reaches the bottom of the page**, at every
  // angle the app uses, on every shape of screen it runs on.
  group('ISSUE 26 — a line is drawn far enough to cross the whole page', () {
    /// The two devices he judges the app on, in logical pixels, plus the
    /// extremes either side of them.
    const pages = <String, Size>{
      'Redmi Pad': Size(685.7, 1142.9),
      'Vivo V2318': Size(412, 915),
      'a short wide window': Size(900, 400),
      'a very tall phone': Size(360, 1400),
      'nearly square': Size(700, 720),
    };

    /// Every angle any ruling uses. 30 is isometric's, 60 is triangle's.
    const angles = <double>[30, -30, 60, -60];

    test('the reach covers the page from y = 0, at every angle and shape', () {
      pages.forEach((what, page) {
        for (final degrees in angles) {
          final reach = PagePattern.reach(page, degrees);
          final radians = degrees * math.pi / 180;
          final dy = math.sin(radians);

          // A line drawn from -reach to +reach through (x, 0) covers this
          // range of y. It must contain the whole page.
          final lowestY = -(reach * dy).abs();
          final highestY = (reach * dy).abs();
          expect(lowestY, lessThanOrEqualTo(0), reason: '$what at $degrees');
          expect(highestY, greaterThanOrEqualTo(page.height),
              reason: '$what at $degrees° stopped '
                  '${(page.height - highestY).toStringAsFixed(0)} points short '
                  'of the bottom — this is what "fallen down here" looks like');
        }
      });
    });

    test('the old bound really was too short, on the page he photographed', () {
      // Guards the diagnosis, not just the fix. If somebody later decides
      // `width + height` was fine after all, this says what it costs.
      const page = Size(685.7, 1142.9);
      final old = page.width + page.height;
      final needed = page.height / math.sin(30 * math.pi / 180).abs();
      expect(old, lessThan(needed),
          reason: 'if this ever passes, the bug could not have happened and '
              'the explanation in paper.dart is wrong');
      expect(PagePattern.reach(page, 30), greaterThanOrEqualTo(needed));
    });

    test('every line of a family reaches the bottom, not just the middle one',
        () {
      // The failure was at the **bottom-left**, which is where the lines whose
      // crossing sits far off the right-hand edge end up. Those are the ones a
      // bound measured from the middle of the page would miss.
      const page = Size(685.7, 1142.9);
      const gap = 33.0;
      for (final degrees in angles) {
        final radians = degrees * math.pi / 180;
        final dx = math.cos(radians);
        final dy = math.sin(radians);
        final reach = PagePattern.reach(page, degrees);

        for (final x in PagePattern.crossings(page, gap, degrees)) {
          final from = Offset(x - dx * reach, -dy * reach);
          final to = Offset(x + dx * reach, dy * reach);
          // The segment's own y-range has to span the page whatever x is,
          // because y does not depend on x at all — which is the insight that
          // makes the bound exact.
          expect(math.min(from.dy, to.dy), lessThanOrEqualTo(0.0));
          expect(math.max(from.dy, to.dy), greaterThanOrEqualTo(page.height));
        }
      }
    });
  });
}
