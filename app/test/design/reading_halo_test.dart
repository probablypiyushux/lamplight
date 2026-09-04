import 'dart:io';

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
      // The label is drawn in `canvas` on the accent, so a canvas-coloured
      // halo would be the same colour as the letters and the word would just
      // look fatter.
      //
      // **This comment used to open "the one place in the app where the ground
      // is not the page", and that was not true.** It was true of the
      // *components*; it was never true of the app. Round 17 found four more —
      // a video poster, an album tile, a `+N` badge and a slider's value
      // bubble — and the group at the bottom of this file is the rule stated
      // so that the count stops mattering.
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

  // ══ ROUND NINETEEN — the halo on ground that is not the page ═══════════
  //
  // Two photographs, sent from a Play Store build: "85%" on the text-size
  // slider and "1:47 · 132.3 MB" on a video poster, both **glowing**.
  //
  // The cause is one sentence of reasoning in `tokens.dart` that was true of
  // what it described and false of what it was used for: *"page-coloured light
  // on a page-coloured ground is nothing at all — which is why it can be
  // applied to a whole text theme without auditing every screen."* The first
  // half is correct. The second does not follow, because a text theme reaches
  // text that is **not** on a page-coloured ground: white type on a dark
  // photograph, dark type on an accent bubble. There the halo is not invisible
  // and not a knockout. It is a wash of the wrong colour, which reads as a glow.
  //
  // So the rule, stated once: **the halo belongs to text whose ground is the
  // canvas. Anything that paints its own ground takes it off again.**
  group('round 19 — anything that paints its own ground takes the halo off', () {
    test('stripPageHalo clears every style the halo was put on', () {
      final haloed = lamplightTextTheme(
        LamplightColors.light.inkPrimary,
        LamplightColors.light.inkSecondary,
        halo: pageHalo(LamplightColors.light.canvas),
      );
      // Precondition: the fixture really is haloed, so a green test below
      // cannot be the fixture quietly having no shadows to begin with.
      expect(haloed.bodyLarge!.shadows, isNotEmpty);

      final bare = stripPageHalo(haloed);
      for (final style in <TextStyle?>[
        bare.displaySmall,
        bare.titleLarge,
        bare.bodyLarge,
        bare.labelMedium,
        bare.labelSmall,
      ]) {
        expect(style!.shadows, isEmpty);
      }
    });

    test('and is the identity on a theme that never had one', () {
      final plain = lamplightTextTheme(
        LamplightColors.light.inkPrimary,
        LamplightColors.light.inkSecondary,
      );
      // Same object back, not an equal copy: this runs inside every
      // `OffThePage` on every surface but Star Map, and it should cost nothing.
      expect(identical(stripPageHalo(plain), plain), isTrue);
    });

    testWidgets('OffThePage takes it off for everything beneath it',
        (tester) async {
      late TextStyle inside;
      late TextStyle outside;
      await tester.pumpWidget(MaterialApp(
        theme: lamplightTheme(LamplightColors.light,
            surface: PageSurface.starMap),
        home: Scaffold(
          body: Column(
            children: [
              Builder(builder: (context) {
                outside = Theme.of(context).textTheme.labelMedium!;
                return const SizedBox.shrink();
              }),
              OffThePage(
                child: Builder(builder: (context) {
                  inside = Theme.of(context).textTheme.labelMedium!;
                  return const SizedBox.shrink();
                }),
              ),
            ],
          ),
        ),
      ));
      await tester.pump();

      expect(outside.shadows, isNotEmpty,
          reason: 'the page itself still carries the halo — ISSUE 9 stands');
      expect(inside.shadows, isEmpty);
    });

    // ── The regression guard that does not need a screenshot ──────────────
    //
    // Both faults he photographed have the same fingerprint in the source: a
    // text style that overrides the ink **because the ground is a photograph**,
    // and then says nothing about the shadow. The ink was corrected at both
    // sites when they were written; the halo was not, at either.
    //
    // So: wherever the source reaches for the dark palette's ink to sit on a
    // frame of somebody's film, it must also put the shadow out. Reading the
    // source rather than pumping four widgets is deliberate — this is a rule
    // about a habit, and the habit is visible in the text.
    test('every label drawn over a photograph also puts the halo out', () {
      const overAPhotograph = <String>[
        'lib/features/capture/attachment_blocks.dart',
        'lib/features/media/media_album.dart',
      ];
      for (final path in overAPhotograph) {
        final source = File(path).readAsStringSync();
        // Each `copyWith` that reaches for the dark palette's primary ink is a
        // declaration that the ground underneath is not the page.
        final declarations =
            'color: LamplightColors.dark.inkPrimary'.allMatches(source).length;
        expect(declarations, greaterThan(0),
            reason: '$path no longer draws over a photograph — if that is '
                'deliberate, take it out of this list');

        // Every one of them must be inside a style that also silences the
        // shadow. Counted rather than parsed: the two must stay in step, and a
        // new label added without the shadow moves one count and not the other.
        final silenced = 'shadows: const <Shadow>[]'.allMatches(source).length;
        expect(silenced, greaterThanOrEqualTo(declarations),
            reason: '$path draws $declarations labels over a photograph but '
                'silences the page halo on only $silenced of them. A '
                'canvas-coloured wash round white type on somebody\'s film is '
                'the glow he photographed twice.');
      }
    });
  });
}
