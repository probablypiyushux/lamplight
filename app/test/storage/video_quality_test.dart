import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/settings/video_quality.dart';

/// **ROUND EIGHT, ISSUE 2A — "do the user wants it compressed?"**
///
/// *"Give the user an option on how the video is compressed? How much it is
/// compressed? Do the user wants it compressed? If he wants then how?"*
///
/// Four question marks in two lines, and the first one that matters is the
/// third: until this existed, every video was re-encoded on the way in and the
/// original was scrubbed. **Irreversibly** — the original no longer exists to
/// go back to. That is a permanent decision about somebody's own recording,
/// taken on their behalf, without asking.
///
/// The tests that matter here are not about bitrates, which live in Kotlin and
/// are a matter of taste. They are about the two things that would be a real
/// failure: **the default must not move**, and **"keep the original" must
/// actually keep the original**.
void main() {
  group('the default does not move', () {
    test('a vault that has never heard of the setting is Balanced', () {
      // Changing the default would silently alter what happens to the next
      // video imported by somebody who never opens this setting — which is the
      // same fault as never having offered the choice, in the other direction.
      expect(AppSettings.inMemory().videoQuality, VideoQuality.balanced);
    });

    test('a settings file written before this existed is Balanced too', () {
      expect(
        AppSettings.inMemory({'autoLock': 60000, 'pageSurface': 'paper'})
            .videoQuality,
        VideoQuality.balanced,
      );
    });

    test('an unknown value falls back rather than failing', () {
      // A settings file edited by hand, or written by a newer build and opened
      // by an older one. Compressing as usual is the safe answer; refusing to
      // import is not.
      expect(
        AppSettings.inMemory({'videoQuality': 'ultra'}).videoQuality,
        VideoQuality.balanced,
      );
    });
  });

  group('the choice survives being written and read back', () {
    for (final quality in VideoQuality.values) {
      test(quality.id, () {
        final settings = AppSettings.inMemory();
        settings.videoQuality = quality;
        expect(settings.videoQuality, quality);
      });
    }
  });

  group('"keep the original" means it', () {
    test('only one option keeps the original', () {
      expect(
        VideoQuality.values.where((q) => q.keepsOriginal).toList(),
        [VideoQuality.original],
      );
    });

    test('the compressing options do not claim to keep it', () {
      expect(VideoQuality.balanced.keepsOriginal, isFalse);
      expect(VideoQuality.smaller.keepsOriginal, isFalse);
    });
  });

  group('every option says what it costs', () {
    // ETHICAL-DESIGN.md, applied to a settings sheet. A list of three options
    // where each note describes only the upside is not a choice, it is
    // marketing — and the one that makes the biggest files has to say so as
    // plainly as the one that makes the smallest.
    for (final quality in VideoQuality.values) {
      test('${quality.id} has a label and a note', () {
        expect(quality.label, isNotEmpty);
        expect(quality.note, isNotEmpty);
        expect(quality.note.length, greaterThan(20),
            reason: 'a note too short to carry a trade-off is not carrying one');
      });
    }

    test('the largest and the smallest both name their downside', () {
      expect(VideoQuality.original.note.toLowerCase(), contains('largest'));
      expect(VideoQuality.smaller.note.toLowerCase(), contains('notice'));
    });
  });

  test('the ids are stable, because they are written to disk', () {
    // Renaming one of these would silently reset every vault that had chosen
    // it back to the default, on the next launch, with no way to tell.
    expect(VideoQuality.values.map((q) => q.id).toList(),
        ['original', 'balanced', 'smaller']);
  });
}
