import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/media/encrypted_image.dart';
import 'package:lamplight/core/media/picture_region.dart';
import 'package:lamplight/features/media/zoom_tile.dart';

/// **Round six's ISSUE 1 — "PDF ZOOM CRASH!" — and round nine's ISSUE
/// IMPORTANT, "when I zoom photos sometimes the app closes."**
///
/// Two crashes, six weeks apart, in two different viewers, with one cause. The
/// second half of this file is the photograph side; the arithmetic it checks is
/// the same arithmetic, which is why the two used to be one file called
/// `pdf_tile` and are now one file called `zoom_tile`.
///
/// The crash was arithmetic, not a race and not a device quirk: zooming asked
/// Android for the whole page again at twice, then four times the width, and an
/// A4 page at 4096 across is a 95 MB bitmap that is copied twice more before it
/// reaches the screen. It crashed *because* he zoomed.
///
/// These tests are the shape of the fix, written as a property rather than as a
/// number: **the work asked for while zoomed is never more than the work
/// already being done unzoomed.** If a later change reintroduces "render the
/// page bigger" in any form, the third test below fails.
void main() {
  // A typical phone: a page laid out 360 logical pixels across at 3x, so the
  // base bitmap is 1080 device pixels wide.
  const child = Size(360, 509); // A4 proportions
  const baseWidth = 1080;

  /// The view transform for zooming by [scale] about the centre of the page.
  Matrix4 zoom(double scale) {
    final cx = child.width / 2;
    final cy = child.height / 2;
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }

  group('what the renderer is asked for', () {
    test('unzoomed, the tile is the whole page', () {
      final tile =
          ZoomTile.of(child: child, view: Matrix4.identity(), baseWidth: baseWidth)!;

      expect(tile.region.left, closeTo(0, 0.001));
      expect(tile.region.top, closeTo(0, 0.001));
      expect(tile.region.right, closeTo(1, 0.001));
      expect(tile.region.bottom, closeTo(1, 0.001));
      expect(tile.width, baseWidth);
    });

    test('zoomed to 4x, it asks for a quarter of the page', () {
      final tile = ZoomTile.of(child: child, view: zoom(4), baseWidth: baseWidth)!;

      expect(tile.region.width, closeTo(0.25, 0.01),
          reason: 'four times the magnification is a quarter of the paper');
      expect(tile.region.height, closeTo(0.25, 0.01));
      // Centred, so it should be the middle quarter.
      expect(tile.region.center.dx, closeTo(0.5, 0.01));
      expect(tile.region.center.dy, closeTo(0.5, 0.01));
    });

    test(
        'THE POINT OF ALL THIS: the bitmap never grows, however far in you go',
        () {
      // The unzoomed page is the budget. Nothing may exceed it.
      final base =
          ZoomTile.of(child: child, view: Matrix4.identity(), baseWidth: baseWidth)!;
      final budget = base.width * (base.width * child.height / child.width);

      for (final scale in [1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 16.0, 64.0]) {
        final tile =
            ZoomTile.of(child: child, view: zoom(scale), baseWidth: baseWidth)!;

        expect(tile.width, lessThanOrEqualTo(baseWidth),
            reason: 'at ${scale}x the tile is still no wider than the screen');

        // And in total pixels, which is what actually gets allocated.
        final aspect = tile.rect.height / tile.rect.width;
        final pixels = tile.width * (tile.width * aspect);
        expect(pixels, lessThanOrEqualTo(budget * 1.02),
            reason: 'at ${scale}x the tile is still no larger than the '
                'unzoomed page — this is the assertion that stands between '
                'the reader and the crash he reported');
      }
    });

    test('it gets sharper even though it does not get bigger', () {
      // The real resolution of the text: device pixels per unit of page.
      double sharpness(double scale) {
        final tile =
            ZoomTile.of(child: child, view: zoom(scale), baseWidth: baseWidth)!;
        return tile.width / tile.region.width;
      }

      // Doubling the zoom doubles the pixels spent on what is on screen, which
      // is precisely what "it is now legible" means.
      expect(sharpness(4), closeTo(sharpness(2) * 2, sharpness(2) * 0.05));
      expect(sharpness(8), closeTo(sharpness(4) * 2, sharpness(4) * 0.05));
    });
  });

  group('the edges', () {
    test('panned hard into a corner, the tile stays on the paper', () {
      // Zoom in, then shove the view well past the top-left corner.
      final view = zoom(4)..translateByDouble(500, 500, 0, 1);
      final tile = ZoomTile.of(child: child, view: view, baseWidth: baseWidth);
      if (tile == null) return; // entirely off the page is a legitimate answer

      expect(tile.region.left, greaterThanOrEqualTo(0));
      expect(tile.region.top, greaterThanOrEqualTo(0));
      expect(tile.region.right, lessThanOrEqualTo(1));
      expect(tile.region.bottom, lessThanOrEqualTo(1));
      expect(tile.rect.left, greaterThanOrEqualTo(0));
      expect(tile.rect.right, lessThanOrEqualTo(child.width));
    });

    test('a singular transform is declined rather than thrown', () {
      final flat = Matrix4.identity()..scaleByDouble(0, 0, 0, 1);
      expect(ZoomTile.of(child: child, view: flat, baseWidth: baseWidth), isNull);
    });

    test('a page with no size is declined', () {
      expect(
        ZoomTile.of(
            child: Size.zero, view: Matrix4.identity(), baseWidth: baseWidth),
        isNull,
      );
    });

    test('the hard ceiling is respected on an enormous screen', () {
      // A 16k display, hypothetically. The per-side cap still holds, because a
      // GPU texture has one and a bitmap wider than it simply fails to appear.
      final tile = ZoomTile.of(
        child: child,
        view: Matrix4.identity(),
        baseWidth: 20000,
        maxWidth: 4096,
      )!;
      expect(tile.width, lessThanOrEqualTo(4096));
    });
  });

  test('the rectangle and the region describe the same thing', () {
    for (final scale in [1.0, 2.0, 5.0]) {
      final tile =
          ZoomTile.of(child: child, view: zoom(scale), baseWidth: baseWidth)!;
      expect(tile.region.left * child.width, closeTo(tile.rect.left, 0.001));
      expect(tile.region.top * child.height, closeTo(tile.rect.top, 0.001));
      expect(tile.region.width * child.width, closeTo(tile.rect.width, 0.001));
      // If these two ever disagree, the sharp patch lands somewhere other than
      // the part of the page it was rendered from, which looks like the page
      // has torn.
      expect(math.max(tile.region.right, 0) * child.width,
          closeTo(tile.rect.right, 0.001));
    }
  });

  // ══ THE PHOTOGRAPH SIDE — ISSUE IMPORTANT, ROUND NINE ══════════════════════
  //
  // *"When I zoom photos sometimes the app closes."* Then, before the first fix
  // was finished: *"nah I want you to make it possible to view tall screenshots
  // too!"*
  //
  // Both are requirements and the naive fix satisfies only one of them. These
  // tests hold both at once:
  //
  //   * **safe** — the decode never exceeds a budget, whatever the picture is;
  //   * **readable** — and zooming in still gets real pixels, not a magnified
  //     blur, however tall the picture is.
  //
  // A test is the only place these can be checked together, because the case
  // that breaks them is a picture too big to keep in a repository.
  group('a photograph, and the tall screenshot that crashed it', () {
    // His phone, in device pixels.
    const screen = Size(1260, 2800);
    const budget = 7 * 1000 * 1000; // ~2× the screen, as the viewer computes it

    ({int width, int height}) decoded(Size source, {int? maxWidth}) {
      final size = targetSizeFor(
        intrinsicWidth: source.width.round(),
        intrinsicHeight: source.height.round(),
        maxWidth: maxWidth,
        maxPixels: budget,
      );
      return (width: size.width!, height: size.height!);
    }

    test('the base decode is bounded whatever shape the picture is', () {
      const pictures = <String, Size>{
        'an ordinary photograph': Size(4032, 3024),
        'the same one, portrait': Size(3024, 4032),
        'a phone screenshot': Size(1260, 2800),
        // The one that killed it. A screenshot of a whole web page.
        'a very tall screenshot': Size(1080, 21600),
        // And the other direction, because nothing should assume portrait.
        'a panorama': Size(23000, 2200),
        'something absurd': Size(60000, 60000),
      };

      pictures.forEach((what, source) {
        final out = decoded(source, maxWidth: screen.width.round());
        final bytes = out.width * out.height * 4;
        expect(out.width * out.height, lessThanOrEqualTo(budget),
            reason: '$what decoded to ${out.width}×${out.height}');
        // 28 MB is the budget in bytes. Three pages of the pager live at once,
        // so this number is the one that has to be multiplied by three and
        // still be survivable.
        expect(bytes, lessThanOrEqualTo(28 * 1000 * 1000), reason: what);
        // And it is still the same picture — a decode that quietly changed the
        // shape would letterbox wrongly and put the sharp patch out of
        // register. Checked as a *ratio of ratios*: a 23,000-wide panorama
        // comes down to 120 pixels tall, and at 120 pixels one pixel of
        // rounding is half a percent of the whole, which an absolute tolerance
        // would report as a bug and is not one.
        expect((out.width / out.height) / (source.width / source.height),
            closeTo(1, 0.01),
            reason: what);
      });
    });

    test('a small picture is never enlarged', () {
      final out = decoded(const Size(400, 300), maxWidth: 4000);
      expect(out.width, 400);
      expect(out.height, 300);
    });

    test('the sharp patch never asks for more than a screenful', () {
      // The picture is letterboxed into the screen; the viewer's child is the
      // whole box, which is the case ZoomTile was written for.
      const box = Size(420, 933); // logical, at 3x → 1260 device pixels
      const baseDevicePixels = 1260;

      Matrix4 zoomBox(double scale) {
        final cx = box.width / 2;
        final cy = box.height / 2;
        return Matrix4.identity()
          ..translateByDouble(cx, cy, 0, 1)
          ..scaleByDouble(scale, scale, scale, 1)
          ..translateByDouble(-cx, -cy, 0, 1);
      }

      for (final scale in [1.0, 2.0, 4.0, 8.0, 20.0]) {
        final tile = ZoomTile.of(
          child: box,
          view: zoomBox(scale),
          baseWidth: baseDevicePixels,
        )!;
        expect(tile.width, lessThanOrEqualTo(baseDevicePixels),
            reason: 'at ${scale}x the patch wanted ${tile.width} pixels, and '
                'the screen only has $baseDevicePixels');
      }
    });

    test('a tall screenshot gets real pixels when you zoom into it', () {
      // This is the half a smaller decode cannot give, and the half he asked
      // for. The picture is 21,600 pixels tall. Zoomed to 4x, the screen shows
      // about a 260-pixel-tall slice of the original — and asks for it at
      // subsampling 1, which is every pixel it has.
      const box = Size(420, 933);
      const sourceHeight = 21600.0;
      const sourceWidth = 1080.0;

      // Letterboxed: the picture is much taller than the box, so it is fitted
      // by height and is very narrow.
      final scale = math.min(box.width / sourceWidth, box.height / sourceHeight);
      final drawnWidth = sourceWidth * scale;

      final tile = ZoomTile.of(
        child: box,
        view: Matrix4.identity()
          ..translateByDouble(box.width / 2, box.height / 2, 0, 1)
          ..scaleByDouble(4, 4, 4, 1)
          ..translateByDouble(-box.width / 2, -box.height / 2, 0, 1),
        baseWidth: 1260,
      )!;

      final visible = tile.rect.intersect(
        Rect.fromLTWH((box.width - drawnWidth) / 2, 0, drawnWidth, box.height),
      );
      final target =
          (visible.width / tile.rect.width * tile.width).round().clamp(64, 4096);
      final regionWidthInSource = visible.width / drawnWidth * sourceWidth;

      final sample = PictureRegion.sampleFor(
        sourceWidth: regionWidthInSource.round(),
        targetWidth: target,
      );

      // Every pixel. Not a resample, not a guess — the actual bytes off the
      // file, which is what makes the text in a screenshot readable.
      expect(sample, 1,
          reason: 'a 4x zoom into a tall screenshot should read the file at '
              'full resolution, not subsample it');
    });

    test('subsampling halves, and stops one step before going soft', () {
      // 4000 source pixels into a 1000-pixel target: 2 would give 2000 (more
      // than needed, fine) and 4 would give exactly 1000. Exactly is allowed.
      expect(
          PictureRegion.sampleFor(sourceWidth: 4000, targetWidth: 1000), 4);
      // 3999 into 1000: 4 would give 999, which is under. So 2.
      expect(
          PictureRegion.sampleFor(sourceWidth: 3999, targetWidth: 1000), 2);
      // Never enlarges, and never returns 0.
      expect(PictureRegion.sampleFor(sourceWidth: 500, targetWidth: 1000), 1);
      expect(PictureRegion.sampleFor(sourceWidth: 500, targetWidth: 0), 1);
    });
  });
}
