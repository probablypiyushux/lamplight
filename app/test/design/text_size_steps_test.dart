import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';

/// **ROUND FIFTEEN, ISSUE 3 — the size slider stops on fives.**
///
/// He read the whole sequence off the screen and typed it out:
///
/// > *"WHEN THE FONT SIZES ARE INCREASED - IT INCREASES LIKE - 75 - 80 - 86 -
/// > 91 - 96 - 102 - 107 - 112 - 118 - 123 - 128 - 133 - 139 - 144 - 149 - 155
/// > – 160!! WHY SO WORSE? WHY NOT SIMPLY? 5?"*
///
/// The cause was arithmetic, not taste. Round nine moved the floor from 0.80 to
/// 0.75 and left `divisions: 16` alone, so seventeen stops were spread over a
/// range of 0.85 and each became 0.053125 — which rounds to a percentage that
/// wanders.
///
/// **This test exists because the same mistake is one edit away from coming
/// back.** Anybody who changes [AppSettings.minTextScale] or
/// [AppSettings.maxTextScale] and leaves the step alone gets told here rather
/// than three rounds later in a document.
void main() {
  group('the stops he asked for', () {
    test('are exactly 75, 80, 85 … 160', () {
      final stops = <int>[
        for (var i = 0; i <= AppSettings.textScaleDivisions; i++)
          (AppSettings.snapTextScale(
                    AppSettings.minTextScale +
                        i *
                            (AppSettings.maxTextScale -
                                    AppSettings.minTextScale) /
                            AppSettings.textScaleDivisions,
                  ) *
                  100)
              .round(),
      ];

      expect(stops, [
        75, 80, 85, 90, 95, 100, 105, 110, 115, 120,
        125, 130, 135, 140, 145, 150, 155, 160,
      ]);
    });

    test('and none of the numbers he complained about survives', () {
      final stops = <int>[
        for (var i = 0; i <= AppSettings.textScaleDivisions; i++)
          (AppSettings.snapTextScale(
                    AppSettings.minTextScale +
                        i *
                            (AppSettings.maxTextScale -
                                    AppSettings.minTextScale) /
                            AppSettings.textScaleDivisions,
                  ) *
                  100)
              .round(),
      ];
      for (final wrong in [86, 91, 96, 102, 107, 112, 118, 123, 128, 133, 139]) {
        expect(stops, isNot(contains(wrong)),
            reason: '$wrong% is one of the stops he wrote out as wrong');
      }
    });

    test('the division count is derived, so moving an end cannot break it', () {
      expect(
        AppSettings.textScaleDivisions,
        ((AppSettings.maxTextScale - AppSettings.minTextScale) /
                AppSettings.textScaleStep)
            .round(),
      );
      // The range has to be a whole number of steps or the top of the slider
      // would not be reachable. 0.85 / 0.05 = 17, exactly.
      expect(
        AppSettings.minTextScale +
            AppSettings.textScaleDivisions * AppSettings.textScaleStep,
        closeTo(AppSettings.maxTextScale, 1e-9),
      );
    });
  });

  group('snapping', () {
    test('pulls a value written by an older build onto the grid', () {
      // What the previous 16-division slider actually stored at stop 2.
      expect(AppSettings.snapTextScale(0.853125), 0.85);
      expect(AppSettings.snapTextScale(1.0203125), 1.0);
    });

    test('leaves a value that is already on a five alone', () {
      for (final v in [0.75, 0.9, 1.0, 1.25, 1.6]) {
        expect(AppSettings.snapTextScale(v), v);
      }
    });

    test('returns a number a percentage label can show exactly', () {
      // 0.75 + 2 * 0.05 is 0.8500000000000001 in binary floating point, and a
      // Slider will not sit on a division it cannot match. Rounding is not
      // cosmetic here.
      for (var i = 0; i <= AppSettings.textScaleDivisions; i++) {
        final v = AppSettings.snapTextScale(
            AppSettings.minTextScale + i * AppSettings.textScaleStep);
        expect((v * 100) - (v * 100).roundToDouble(), closeTo(0, 1e-9),
            reason: '$v is not a whole percentage');
      }
    });

    test('the default is on the grid', () {
      expect(AppSettings.snapTextScale(AppSettings.defaultTextScale),
          AppSettings.defaultTextScale);
    });
  });
}
