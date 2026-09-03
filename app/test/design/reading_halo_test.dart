import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/components.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **ROUND FIFTEEN, ISSUE 9 — writing that sits on a chart.**
///
/// > *"VISIBLITY help needed! Text — I don't want you to change the backside —
/// > think of something which would look good! Ideate this"*, with the light
/// > page circled and *"can you understand"* beside it. On the dark one:
/// > *"manageable in dark mode!!!"*
///
/// The diagnosis matters as much as the fix, because the obvious reading of
/// that screenshot is "the text is too pale" and it is wrong — the numbers say
/// the page he photographed already clears AA with room to spare. What is
/// saturated is not contrast but **frequency**: the chart draws strokes about
/// as wide as the stems of the type, in the same colour, and the eye cannot
/// separate them.
///
/// So the first group here is the diagnosis, kept as arithmetic so nobody
/// re-opens it by adjusting a colour. The rest is the fix.
void main() {
  double luminance(Color c) => c.computeLuminance();
  double contrast(Color a, Color b) {
    final l1 = luminance(a), l2 = luminance(b);
    final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// [over] at [alpha], composited onto [under]. Source-over.
  Color composite(Color over, double alpha, Color under) => Color.fromARGB(
        255,
        ((over.r * alpha + under.r * (1 - alpha)) * 255).round(),
        ((over.g * alpha + under.g * (1 - alpha)) * 255).round(),
        ((over.b * alpha + under.b * (1 - alpha)) * 255).round(),
      );

  /// The strongest mark the light chart makes: a constellation line, drawn in
  /// the page's own ink at 34%. See `star_map.dart` — on paper the lines carry
  /// the picture, which is why they are that strong and why they are not being
  /// turned down.
  const chartAlpha = 0.34;

  group('the diagnosis, so nobody fixes the wrong thing', () {
    test('the page he photographed already cleared AA', () {
      const c = LamplightColors.light;
      final worst = composite(c.inkPrimary, chartAlpha, c.canvas);
      expect(contrast(c.inkPrimary, worst), greaterThan(4.5),
          reason: 'body copy over the darkest thing the chart draws. If the '
              'problem were contrast this number would be the problem, and it '
              'is not — it is the strokes being the same width as the stems');
    });
  });

  group('the halo puts the page back round every glyph', () {
    for (final entry in {
      'dark': LamplightColors.dark,
      'light': LamplightColors.light,
    }.entries) {
      final c = entry.value;

      test('${entry.key}: the chart is all but gone where a letter is', () {
        final halo = pageHalo(c.canvas);
        // Two stops, composited in the order Flutter paints them: the widest
        // and faintest first, the tight one over it, both under the glyph.
        final line = composite(c.inkPrimary, chartAlpha, c.canvas);
        var ground = line;
        for (final stop in halo.reversed) {
          ground = composite(c.canvas, stop.color.a, ground);
        }
        expect(contrast(ground, c.canvas), lessThan(1.05),
            reason: 'at full strength the halo leaves the page as the page. '
                'This is what happens under and immediately beside a stem; '
                'the blur fades it out over the next few points, which is the '
                'whole point — the sky is untouched everywhere else');
      });

      test('${entry.key}: and it is made of the page, not of a colour', () {
        for (final stop in pageHalo(c.canvas)) {
          expect(Color(stop.color.toARGB32()).withValues(alpha: 1.0), c.canvas,
              reason: 'a halo in any other colour is a glow, and a glow is a '
                  'shadow with better manners. DESIGN-SYSTEM.md bans those');
          expect(stop.offset, Offset.zero,
              reason: 'no offset, no direction — it is a knockout, not depth');
        }
      });
    }
  });

  group('who gets it', () {
    ThemeData themed(PageSurface surface) => lamplightTheme(
          LamplightColors.light,
          surface: surface,
        );

    test('a page that draws marks at the scale of type', () {
      expect(PageSurface.starMap.marksThePage, isTrue);
      expect(themed(PageSurface.starMap).textTheme.bodyLarge!.shadows,
          isNotEmpty);
    });

    test('and nothing else, because it is not free', () {
      for (final s in [
        PageSurface.plain,
        PageSurface.paper,
        PageSurface.lamplit,
      ]) {
        expect(s.marksThePage, isFalse, reason: s.id);
        expect(themed(s).textTheme.bodyLarge!.shadows, anyOf(isNull, isEmpty),
            reason: '${s.id} — two extra rasterisations per glyph for an '
                'effect nobody could see is a cost with no benefit');
      }
    });

    test('every style on the page, not only the body', () {
      final t = themed(PageSurface.starMap).textTheme;
      for (final style in [
        t.displaySmall,
        t.titleLarge,
        t.bodyLarge,
        t.labelMedium,
        t.labelSmall,
      ]) {
        expect(style!.shadows, isNotEmpty,
            reason: 'the timestamps and the weekday are the smallest text on '
                'the page and suffer most from a line crossing them');
      }
    });

    testWidgets('but not a label on a filled pill', (tester) async {
      // The one place in the app where the ground is not the page. The label
      // is drawn in `canvas` on the accent, so a canvas-coloured halo would be
      // the same colour as the letters and the word would just look fatter.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: lamplightTheme(LamplightColors.light,
            surface: PageSurface.starMap),
        home: Scaffold(
          body: LampButton(label: 'Create backup file', onPressed: () {}),
        ),
      ));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style!.textStyle!
          .resolve(<WidgetState>{})!;
      expect(style.shadows, isEmpty,
          reason: 'a button is its own surface and does not need the page to '
              'help it be read');
    });
  });
}
