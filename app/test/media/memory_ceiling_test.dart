import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/pdf_render.dart';

/// **ROUND FIFTEEN, ISSUE 4 — the app was not crashing, it was being killed.**
///
/// > *"LOOK INTO ANY CODE ISSUES - CS WHENEVER IDK WHEN OR HOW EVEN WHEN I AM
/// > WORKING THE APP IDK SUDDENLY CLOSES! LOOK FOR ANY ISSUES!"*
///
/// `adb shell dumpsys activity exit-info` settled it in one command.
/// **Twelve process exits recorded, exactly one an exception.** Every other one
/// is `reason=13 (OTHER KILLS BY SYSTEM)` — the low-memory killer — at up to
/// **876 MB RSS**, on a 6 GB tablet with 123 MB free. `dumpsys meminfo` on an
/// idle, backgrounded app showed **152 MB of GPU textures**.
/// `02-security/ON-DEVICE-EVIDENCE.md` §4 has the table.
///
/// ── WHY THIS FILE EXISTS AND WHAT IT HONESTLY CANNOT DO ──────────────────
///
/// **Nothing in this project measures memory.** 1,415 tests, a clean analyzer,
/// two release gates that read the built artefact — and not one of them would
/// notice a feature that allocates a full-screen bitmap and keeps it. A laptop
/// has plenty of memory, which is precisely the shape of every other expensive
/// thing here: *the thing being checked was not the thing being shipped.*
///
/// A Dart test cannot weigh a GPU texture. What it **can** do is hold the
/// project to its own arithmetic, which is where every one of these bugs
/// actually lived:
///
///   * ISSUE 1, round six: the PDF asked for the whole page at 4096 across —
///     a 95 MB bitmap, copied twice more on the way to the screen.
///   * ISSUE IMPORTANT, round nine: a long screenshot decoded to about 93 MB
///     because `maxWidth` bounded the width and said nothing about the height.
///   * Round fifteen: Crumpled held two 768 × 1536 RGBA sheets — 9 MB — from
///     the moment anybody chose the surface.
///
/// **Every one of those is a number somebody could have written down.** So this
/// file writes them down: the largest single allocation each path can make, and
/// the worst case with all of them alive at once. It is a ceiling, not a
/// measurement, and it is the difference between a regression that is caught
/// here and one that is caught by a stranger's phone closing.
///
/// **Run the real check on a device before a release.** Two commands, two
/// minutes, and they are in `RELEASE-CHECKLIST.md` now:
///
/// ```
/// adb shell dumpsys meminfo com.probablypiyush.lamplight
/// adb shell dumpsys activity exit-info com.probablypiyush.lamplight
/// ```
void main() {
  /// Bytes for an ARGB_8888 bitmap of [w] × [h]. Four bytes a pixel, whatever
  /// it compressed to on disk — which is the fact all three bugs above missed.
  int bytes(int w, int h) => w * h * 4;

  String mb(int b) => '${(b / 1024 / 1024).toStringAsFixed(1)} MB';

  group('the largest single thing each path can allocate', () {
    test('a PDF page, at the base width the viewer asks for', () {
      // `_PdfPages.build` clamps the request to 1400 device pixels across.
      // A very tall page — a receipt, a scanned scroll — is the worst shape,
      // so this is checked at 1:4 rather than at A4.
      const width = 1400;
      final worst = bytes(width, width * 4);
      expect(worst, lessThan(40 * 1024 * 1024),
          reason: 'one page is ${mb(worst)}. The list keeps a small number of '
              'these alive at once, so a ceiling here is a ceiling on the '
              'viewer');
    });

    test('a PDF zoom tile never grows with the magnification', () {
      // The whole of round six's ISSUE 1, as a property rather than a number:
      // zooming asks for a smaller *region* at the same width, so the bitmap
      // is the size of the screen at every magnification. `zoom_tile_test.dart`
      // proves the region arithmetic; this states what it is worth in bytes.
      const screen = 1400;
      final tile = bytes(screen, screen * 2);
      expect(tile, lessThan(20 * 1024 * 1024), reason: mb(tile));
    });

    test('the platform refuses anything past its own budget', () {
      // Enforced in Kotlin as well as asked for in Dart, because that is the
      // process that dies if the Dart side is wrong. Both a per-side cap — a
      // GPU texture has one — and a total-pixel cap, because two sides each
      // within their limit still multiply.
      final kotlin = File(
        'android/app/src/main/kotlin/com/probablypiyush/lamplight/MemoryPdf.kt',
      ).readAsStringSync();
      expect(kotlin, contains('MAX_DIMENSION = 4096'));
      expect(kotlin, contains('MAX_PIXELS = 8_000_000'));
      // 8 megapixels as ARGB_8888, briefly doubled while the pixels are copied
      // out. Comfortably more than any phone screen — a 1440 x 3200 display is
      // 4.6 MP — so it is a backstop rather than a working limit.
      expect(bytes(1, 8000000), lessThan(40 * 1024 * 1024));
    });

    test('a photograph is bounded on both sides, not only on width', () {
      // Round nine's ISSUE IMPORTANT. `maxWidth` alone let a 1080 x 22000
      // screenshot through at about 93 MB and Android killed the process.
      // `maxPixels` is the second cap and the smaller of the two wins.
      final source = File('lib/core/media/encrypted_image.dart')
          .readAsStringSync();
      expect(source, contains('maxPixels'),
          reason: 'a width cap says nothing about a long screenshot');
      expect(bytes(1080, 22000), greaterThan(90 * 1024 * 1024),
          reason: 'the counter-example, kept as a number: ${mb(bytes(1080, 22000))}');
    });
  });

  group('what can be alive at the same time', () {
    // Deliberately pessimistic. Every one of these is a real path, and the
    // point of adding them up is that no single one of them looks alarming.
    test('the worst honest case is still under a quarter of a gigabyte', () {
      final live = <String, int>{
        'three PDF pages in the list': 3 * bytes(1400, 1980),
        'one zoom tile over them': bytes(1400, 2800),
        'a photograph being viewed': bytes(2520, 3360),
        'the page ground': bytes(1200, 2000),
      };
      final total = live.values.fold<int>(0, (a, b) => a + b);
      for (final e in live.entries) {
        // ignore: avoid_print
        print('${e.key.padRight(32)} ${mb(e.value)}');
      }
      // ignore: avoid_print
      print('${'TOTAL'.padRight(32)} ${mb(total)}');

      expect(total, lessThan(250 * 1024 * 1024),
          reason: 'the device recorded 876 MB RSS before it was killed. This '
              'is a ceiling on the parts this project controls, and it is not '
              'a measurement — see the note at the top of this file');
    });

    test('and Crumpled is not in that list any more', () {
      // Two 768 x 1536 RGBA sheets, cached statically and uploaded as textures
      // the moment anybody chose the surface. 9 MB that nothing ever freed.
      // ISSUE 1 of round fifteen removed the feature; this is what it was
      // worth, kept as a number so the cost of putting it back is visible.
      final crumple = 2 * bytes(768, 1536);
      expect(crumple, 9 * 1024 * 1024,
          reason: 'exactly nine megabytes: 2 x 768 x 1536 x 4');

      final paper = File('lib/design/paper.dart').readAsStringSync();
      expect(paper.toLowerCase(), isNot(contains('crumple')),
          reason: 'and it is gone from the painter, not merely from the menu');
    });
  });

  group('the abandoned render, which is a memory fix as much as a speed one', () {
    test('a page nobody is looking at is dropped before it costs anything', () {
      // A fling used to build and dispose a page widget every few frames and
      // every one of them fired a render. Thirty queued renders is thirty
      // bitmaps decoded for pages that had already gone.
      expect(const PdfRenderAbandoned().toString(), contains('scrolled past'));
    });

    test('and the queue is one deep, which is what bounds the peak', () {
      final source = File('lib/core/platform/pdf_render.dart').readAsStringSync();
      expect(source, contains('static Future<void> _busy'));
      expect(source, contains('stillWanted'));
    });
  });
}
