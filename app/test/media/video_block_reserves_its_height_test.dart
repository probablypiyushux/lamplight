import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/features/capture/attachment_blocks.dart';

/// **"WHEN THERE ARE TWO OR MORE VIDEOS UPLOADED ON THE PAGE — THE PAGE
/// JERKS."** 31 August 2026.
///
/// ── WHAT WAS HAPPENING ──────────────────────────────────────────────────────
///
/// A video block draws its poster frame, and the poster is a *second*
/// attachment reached through `thumbnailId` — so it has to be fetched, and it
/// cannot be known during `build`. Until it arrived the block drew the old file
/// row, about **72 points** tall. The moment it landed, `setState` swapped in an
/// `AspectRatio`, which at a day column's width is **roughly 200 points for a
/// landscape clip and up to 600 for a portrait one**.
///
/// So every video on the day grew by between 130 and 530 points, each at its own
/// moment, after the page had been laid out and scrolled. With one video that
/// reads as a thumbnail appearing. With **two or more** it is two or more
/// independent shoves of everything below them — which is what "the page jerks"
/// describes, and why it took two to notice: the first usually finished before
/// the page was still.
///
/// ── WHY IT NEVER NEEDED TO ──────────────────────────────────────────────────
///
/// The ratio was being taken from the poster, and it was on the **video's own
/// row all along**. `width`, `height` and `thumbnailId` are written in one
/// `AttachmentsCompanion.insert`, from one `MediaFacts`. A clip that has a
/// poster worth waiting for has always had its shape available synchronously.
///
/// ── WHY THIS IS A TEST AND NOT A COMMENT ────────────────────────────────────
///
/// `videoBoxRatio` is four lines and reads like an accident. The obvious tidy —
/// *"the poster is right there, use its dimensions"* — restores the jerk
/// exactly, and would break nothing else, log nothing, and look neater. This is
/// the thing that fails.
void main() {
  Attachment video({
    String? thumbnailId = 'poster',
    int? width,
    int? height,
  }) =>
      Attachment(
        id: 'clip',
        fileKey: Uint8List(32),
        originalName: 'clip.mp4',
        mimeType: 'video/mp4',
        byteSize: 1,
        thumbnailId: thumbnailId,
        width: width,
        height: height,
      );

  group('the box is decided by the clip, not by its poster', () {
    test('a landscape clip reserves its own shape', () {
      expect(videoBoxRatio(video(width: 1920, height: 1080)),
          closeTo(16 / 9, 0.001));
    });

    test('a portrait clip reserves its own shape', () {
      // A phone held upright. `MediaInfo` has already applied the rotation, so
      // these are the numbers as displayed rather than as stored.
      expect(videoBoxRatio(video(width: 1080, height: 1920)),
          closeTo(0.6, 0.001),
          reason: 'clamped, so a very tall clip still leaves room for the day '
              'underneath it');
    });

    test('an extreme clip is clamped at both ends', () {
      expect(videoBoxRatio(video(width: 4000, height: 500)), 2.0);
      expect(videoBoxRatio(video(width: 500, height: 4000)), 0.6);
    });

    test('a clip with no dimensions falls back rather than waiting', () {
      // The vanishingly rare row that got a poster but no numbers. It must
      // still answer *something* synchronously: returning null here would send
      // it to the file row and then jump to a picture, which is the bug.
      expect(videoBoxRatio(video(width: null, height: null)),
          kVideoBoxFallbackRatio);
    });

    test('the fallback is what a phone actually records', () {
      // Not arbitrary. It is the value that makes the common landscape clip
      // shift by nothing at all, and it is the same one `_Placeholder` holds
      // open while the attachment row itself is still loading — so the
      // placeholder, the fallback and the real box all agree.
      expect(kVideoBoxFallbackRatio, closeTo(16 / 9, 0.001));
    });
  });

  group('a clip from before poster frames existed', () {
    test('is sent to the old file row, and is sent there on the first frame',
        () {
      // Null is the signal for "draw `_row`". Decided from `thumbnailId`, which
      // is on the row in hand, so this branch is taken on frame one and holds
      // for the life of the widget — it cannot move either.
      expect(videoBoxRatio(video(thumbnailId: null)), isNull);
    });

    test('and having dimensions does not change that', () {
      // A clip with no poster has no picture to draw, whatever its shape. It
      // gets the row.
      expect(videoBoxRatio(video(thumbnailId: null, width: 1920, height: 1080)),
          isNull);
    });
  });

  test('the answer does not depend on anything fetched later', () {
    // The property, stated directly: two calls with the same row give the same
    // number, and the row is all there is. Nothing here can consult a poster,
    // because nothing here is given one.
    final row = video(width: 1280, height: 720);
    expect(videoBoxRatio(row), videoBoxRatio(row));
  });
}
