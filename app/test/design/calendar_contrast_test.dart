import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/tokens.dart';

/// Why the calendar does not print day numbers on the density ramp.
///
/// The obvious design is a heatmap: fill each cell with the year grid's colour
/// and put the date on top. It was measured before it was drawn, and it fails —
/// so this file is the measurement, kept, so that nobody has to take the
/// decision on trust or re-derive it in a year.
///
/// `CONTRAST-REPORT.md` ends with "Put this in CI. A colour change that breaks
/// contrast should fail the build, not ship." A design *decision* that rests on
/// a measured number belongs in CI for the same reason: if someone later
/// lightens the ramp, the reason for the current design quietly evaporates and
/// nothing tells them.
void main() {
  // WCAG 2.1 relative luminance, the same as tokens_test.dart.
  double luminance(Color c) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// The best either available ink can do against a background.
  double bestInk(LamplightColors c, Color background) => math.max(
        contrast(c.inkPrimary, background),
        contrast(c.canvas, background),
      );

  group('the reason day numbers are not on the ramp', () {
    test('light mode level 4 cannot carry text at 4.5:1, with any ink', () {
      const c = LamplightColors.light;
      final best = bestInk(c, c.gridRamp[4]);

      expect(best, lessThan(4.5),
          reason:
              'If this ever passes, the ramp has changed and the calendar could '
              'legitimately be redrawn as a heatmap. Until then, printing a day '
              'number on this shade would fail AA in the mode people use '
              'outdoors — measured at ${best.toStringAsFixed(2)}:1.');
    });

    test('and it is not a near miss that a nudge would fix', () {
      const c = LamplightColors.light;
      // Both inks, not just the better one. Neither is close.
      expect(contrast(c.inkPrimary, c.gridRamp[4]), lessThan(4.5));
      expect(contrast(c.canvas, c.gridRamp[4]), lessThan(4.5));
    });
  });

  group('what the calendar actually draws instead', () {
    for (final entry in {
      'dark': LamplightColors.dark,
      'light': LamplightColors.light,
    }.entries) {
      final mode = entry.key;
      final c = entry.value;

      test('$mode: the day number clears AA on the sheet it sits on', () {
        // The number is always on `surface`, never on a ramp colour. That is
        // the whole trade, and this is the number it buys.
        expect(contrast(c.inkPrimary, c.surface), greaterThanOrEqualTo(4.5));
        // Days with nothing on them are muted, and still have to be readable.
        expect(contrast(c.inkMuted, c.surface), greaterThanOrEqualTo(4.5));
      });

      test('$mode: the ramp is only ever a mark, and steps are separable', () {
        // With the ramp demoted to a bar, its contrast job is no longer text —
        // but the steps still have to be tellable apart, including in
        // greyscale, which is what DESIGN-SYSTEM.md's 1.25x rule is for.
        for (var i = 1; i < c.gridRamp.length - 1; i++) {
          final a = luminance(c.gridRamp[i]) + 0.05;
          final b = luminance(c.gridRamp[i + 1]) + 0.05;
          expect(math.max(a, b) / math.min(a, b), greaterThanOrEqualTo(1.25),
              reason: '$mode ramp steps $i and ${i + 1} are too close together');
        }
      });

      test('$mode: the bar width carries the level as well as the colour', () {
        // Colour is never the only channel. The widths below are the ones in
        // calendar_sheet.dart; if they are ever flattened, a colour-blind or
        // greyscale reader loses the distinction entirely.
        double widthFor(int level) => 0.35 + 0.13 * level;
        for (var level = 1; level < 5; level++) {
          expect(widthFor(level + 1) - widthFor(level), greaterThan(0.1),
              reason: 'levels $level and ${level + 1} would look the same width');
        }
        expect(widthFor(5), lessThanOrEqualTo(1.0));
      });
    }
  });

  test('the selected and today markers do not rely on colour alone', () {
    // Today is a ring AND a bold number AND the word "today" in its label.
    // The selected day is a filled cell AND is announced as selected. Neither
    // is only an accent — which is what makes the calendar readable to someone
    // who cannot see the accent at all.
    for (final c in [LamplightColors.dark, LamplightColors.light]) {
      // The ring itself still has to be visible as a boundary that carries
      // meaning: 3:1 against the surface behind it, per WCAG 1.4.11.
      expect(contrast(c.accent, c.surface), greaterThanOrEqualTo(3.0));
      // And the selected fill has to be distinguishable from the sheet.
      expect(luminance(c.raised), isNot(closeTo(luminance(c.surface), 0.0001)));
    }
  });
}
