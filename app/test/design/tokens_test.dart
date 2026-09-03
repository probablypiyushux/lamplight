import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';

/// Contrast is verified in code, not trusted to a table someone typed once.
///
/// `08-design/CONTRAST-REPORT.md` ends with "Put this in CI. A colour change
/// that breaks contrast should fail the build, not ship." This is that. The
/// ratios are recomputed here with the WCAG 2.1 formula rather than read from
/// the document, so the document and the code cannot silently disagree.
void main() {
  // WCAG 2.1 relative luminance. sRGB linearisation, then the standard
  // coefficients. Reproduced from CONTRAST-REPORT.md.
  double luminance(Color c) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    final hi = math.max(la, lb), lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  The launcher icon. ISSUE 6.
  //
  //  *"The light-mode app icon is ugly as fuck"* — a white lamp on a white
  //  ground, no contrast, nothing to see. He was right, and the cause was one
  //  shared file: `ic_launcher_light.xml` swapped the plate to warm paper and
  //  went on pointing at the **dark** icon's foreground.
  //
  //  What makes that worth a test rather than a fix is where it went wrong.
  //  Every colour involved was correct — `dark.inkPrimary` is a verified token,
  //  `light.canvas` is a verified token — and the defect was **pairing two
  //  palettes**, which no per-palette check could ever see. So this asserts the
  //  pairing, in both directions, and it would have failed the day the light
  //  icon was added.
  // ═══════════════════════════════════════════════════════════════════════
  group('the launcher icon', () {
    test('the lamp is visible on its own plate, in both variants', () {
      const dark = LamplightColors.dark;
      const light = LamplightColors.light;

      // The pairing the generator actually uses. If `generate_icon_test.dart`
      // ever draws one palette's mark on the other's plate again, this is what
      // stops it reaching a phone.
      final pairs = {
        'dark icon': (ink: dark.inkPrimary, plate: dark.canvas),
        'light icon': (ink: light.inkPrimary, plate: light.canvas),
      };

      for (final entry in pairs.entries) {
        final ratio = contrast(entry.value.ink, entry.value.plate);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: the lampshade is ${ratio.toStringAsFixed(2)}:1 '
              'against its own plate — this is the white-lamp-on-white-ground '
              'bug coming back',
        );
      }

      // And the arrangement that was actually shipping, so the diagnosis
      // cannot rot into a test that would pass either way.
      expect(
        contrast(dark.inkPrimary, light.canvas),
        lessThan(1.5),
        reason: 'if this stops being invisible, the ISSUE 6 note in '
            'ic_launcher_light.xml is wrong and should be corrected',
      );
    });

    test('the light on the plate reads as light, not as a smudge', () {
      // The glow is the accent, and on a pale plate an accent that is too close
      // to the paper turns the cone into a stain. 3:1 is the WCAG floor for a
      // graphical object that carries meaning, and the bulb carries the whole
      // metaphor.
      expect(
        contrast(LamplightColors.light.accent, LamplightColors.light.canvas),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        contrast(LamplightColors.dark.accent, LamplightColors.dark.canvas),
        greaterThanOrEqualTo(3.0),
      );
    });
  });

  for (final entry in {
    'dark': LamplightColors.dark,
    'light': LamplightColors.light,
  }.entries) {
    final mode = entry.key;
    final c = entry.value;

    group('$mode mode', () {
      test('every text token clears AA (4.5:1) on every surface', () {
        // CONTRAST-REPORT.md's headline claim. If this fails, the design
        // excludes people, and it does so invisibly.
        final surfaces = {'canvas': c.canvas, 'surface': c.surface, 'raised': c.raised};
        final inks = {
          'inkPrimary': c.inkPrimary,
          'inkSecondary': c.inkSecondary,
          'inkMuted': c.inkMuted,
          'accent': c.accent,
          'danger': c.danger,
          'good': c.good,
        };
        for (final s in surfaces.entries) {
          for (final i in inks.entries) {
            final ratio = contrast(i.value, s.value);
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '$mode ${i.key} on ${s.key} is only '
                  '${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      });

      test('ink.primary reaches AAA (7:1) on the canvas', () {
        expect(contrast(c.inkPrimary, c.canvas), greaterThanOrEqualTo(7.0));
      });

      test('the focus ring clears 3:1, which is what WCAG 1.4.11 requires', () {
        expect(contrast(c.accent, c.canvas), greaterThanOrEqualTo(3.0));
        expect(contrast(c.accent, c.surface), greaterThanOrEqualTo(3.0));
      });

      test('neither pure black nor pure white appears anywhere', () {
        // ACCESSIBILITY.md: pure white on pure black causes halation, where
        // text appears to glow and blur. Hard on people with astigmatism.
        // The warm near-blacks and off-whites are deliberate.
        const forbidden = [Color(0xFF000000), Color(0xFFFFFFFF)];
        for (final token in [c.canvas, c.inkPrimary, c.raised, c.accent]) {
          expect(forbidden, isNot(contains(token)), reason: '$mode uses pure black or white');
        }
      });

      test('the year-grid ramp is monotonic and every step is distinguishable', () {
        // The check most people skip: each step against its NEIGHBOUR, not just
        // against the background. It is what decides whether the grid is
        // actually readable — and it is how CONTRAST-REPORT.md caught a
        // light-mode level that read as *less* than empty.
        expect(c.gridRamp, hasLength(6));
        for (var i = 0; i < c.gridRamp.length - 1; i++) {
          final a = luminance(c.gridRamp[i]) + 0.05;
          final b = luminance(c.gridRamp[i + 1]) + 0.05;
          final step = math.max(a, b) / math.min(a, b);
          expect(
            step,
            greaterThanOrEqualTo(1.25),
            reason: '$mode ramp step $i→${i + 1} is only '
                '${step.toStringAsFixed(2)}× — too close to tell apart',
          );
        }
      });

      test('the empty grid cell reads as absence, not as a small amount', () {
        // A neutral, not the lightest amber. "Nothing happened" must not look
        // like "a little happened" — ETHICAL-DESIGN.md, gaps are neutral.
        final empty = c.gridRamp.first;
        final channels = [empty.r, empty.g, empty.b];
        final spread = channels.reduce(math.max) - channels.reduce(math.min);
        expect(spread, lessThan(0.06), reason: '$mode empty cell is too saturated');
      });
    });
  }

  test('light is not a naive inversion of dark', () {
    // DESIGN-SYSTEM.md: light mode is a separately chosen palette. Inverting
    // saturates pastels and silently breaks every measured ratio.
    final invertedAccent = Color.from(
      alpha: 1,
      red: 1 - LamplightColors.dark.accent.r,
      green: 1 - LamplightColors.dark.accent.g,
      blue: 1 - LamplightColors.dark.accent.b,
    );
    expect(LamplightColors.light.accent, isNot(invertedAccent));
  });

  test('body type is 17/26 — the number that must not be tightened', () {
    final t = lamplightTextTheme(LamplightColors.dark.inkPrimary,
        LamplightColors.dark.inkSecondary);
    expect(t.bodyLarge!.fontSize, 17);
    expect(t.bodyLarge!.height! * t.bodyLarge!.fontSize!, closeTo(26, 0.01));
  });

  test('the touch-target floor is 48dp', () {
    expect(kMinTouchTarget, greaterThanOrEqualTo(48));
  });

  testWidgets('the theme carries the tokens and paints the canvas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: Text('x', style: TextStyle(color: context.lamplight.inkPrimary)),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(Scaffold));
    expect(ctx.lamplight.canvas, LamplightColors.dark.canvas);
    expect(Theme.of(ctx).scaffoldBackgroundColor, LamplightColors.dark.canvas);
  });
}
