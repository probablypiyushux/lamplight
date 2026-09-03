import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';

/// **ISSUE 12 — "how do I know that the thing is getting compressed?"**
///
/// A fair question, and the honest answer was that he could not know: photos
/// and videos have been re-encoded at import since round five, and the only
/// evidence was a smaller number with nothing to compare it against.
///
/// The answer is `attachments.original_size` (schema v4) and this function,
/// which turns the pair into a sentence. Everything below is about **not
/// overclaiming** — the app should say nothing rather than say something it
/// cannot back up, which is the same rule the 0:00 in ISSUE 2 broke.
void main() {
  group('when there is something to say', () {
    test('a video that halved says so, in megabytes and per cent', () {
      final text = humanSaving(
        originalSize: 104 * 1024 * 1024,
        storedSize: 26 * 1024 * 1024,
      );
      expect(text, isNotNull);
      expect(text, contains('78'));
      expect(text, contains('75%'),
          reason: 'both the absolute saving and the proportion — one of them '
              'is meaningless without the other');
    });

    test('a photograph that shrank a lot says so too', () {
      expect(
        humanSaving(originalSize: 8 * 1024 * 1024, storedSize: 900 * 1024),
        isNotNull,
      );
    });
  });

  group('when there is nothing to say, it says nothing', () {
    test('an unknown original makes no claim at all', () {
      // Everything imported before schema v4. The files are gone, so there is
      // nothing to measure, and inventing a zero would be a lie.
      expect(humanSaving(originalSize: null, storedSize: 1024 * 1024), isNull);
    });

    test('a file stored exactly as it arrived makes no claim', () {
      // A PDF, a text file, a GIF. Nothing was re-encoded.
      final size = 4 * 1024 * 1024;
      expect(humanSaving(originalSize: size, storedSize: size), isNull);
    });

    test('a file that grew is not announced as a saving', () {
      // Re-encoding occasionally makes a small image slightly larger.
      // "Saved -2%" would be absurd.
      expect(
        humanSaving(originalSize: 500 * 1024, storedSize: 520 * 1024),
        isNull,
      );
    });

    test('a saving too small to care about is left unsaid', () {
      // True, uninteresting, and a line of text on screen costs more attention
      // than the fact is worth.
      expect(
        humanSaving(originalSize: 1000 * 1024, storedSize: 960 * 1024),
        isNull,
      );
    });

    test('the boundary is a tenth of a megabyte', () {
      expect(
        humanSaving(originalSize: 2000 * 1024, storedSize: 2000 * 1024 - 99 * 1024),
        isNull,
      );
      expect(
        humanSaving(originalSize: 2000 * 1024, storedSize: 2000 * 1024 - 101 * 1024),
        isNotNull,
      );
    });
  });

  test('a saving of everything does not divide by zero or read oddly', () {
    final text = humanSaving(originalSize: 5 * 1024 * 1024, storedSize: 0);
    expect(text, contains('100%'));
  });
}
