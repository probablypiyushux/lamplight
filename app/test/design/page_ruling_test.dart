import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/paper.dart';
import 'package:lamplight/design/tokens.dart';

/// **ISSUE 6 — the background, and who chooses it.**
///
/// The typed line was "CHAT BACKGROUND — LINES?? SERIOUSLY! REMOVE THOSE LINES
/// BACKGROUND!". The handwriting on the same page was "You have added Lines.
/// Why don't you give the user choices in this too: Lines → already there ·
/// Isometric grid · triangle · dot grid", and "can be changed from Appearances".
///
/// Both halves are honoured by one arrangement: the ruling is a setting, and
/// its default is nothing. These tests pin the half that is easy to lose —
/// **the default** — because a later change that quietly makes lines the
/// default again would put the app straight back to the screen he photographed.
void main() {
  group('what a page looks like when nobody has chosen', () {
    test('nothing is printed on it', () {
      expect(PageRuling.fromId(null), PageRuling.none,
          reason: '"REMOVE THOSE LINES BACKGROUND!" — a fresh install, and his '
              'existing one, gets a clean page');
    });

    test('an unrecognised value falls back to nothing, not to lines', () {
      expect(PageRuling.fromId('squared'), PageRuling.none);
      expect(PageRuling.fromId(''), PageRuling.none);
    });

    test('PaperGround defaults to no ruling when it is not told', () {
      const ground = PaperGround(
        surface: PageSurface.paper,
        child: SizedBox.shrink(),
      );
      expect(ground.ruling, PageRuling.none);
    });
  });

  group('all four choices he listed exist and are distinct', () {
    test('lines, isometric, triangle and dot grid', () {
      expect(
        PageRuling.values.map((r) => r.id),
        containsAll(<String>['lines', 'isometric', 'triangle', 'dots']),
      );
    });

    test('every ruling round-trips through its id', () {
      for (final ruling in PageRuling.values) {
        expect(PageRuling.fromId(ruling.id), ruling);
      }
    });

    test('every ruling says what it is, for the line under the picker', () {
      for (final ruling in PageRuling.values) {
        expect(ruling.label, isNotEmpty);
        expect(ruling.note, isNotEmpty);
      }
    });
  });

  // ── ROUND FIFTEEN, ISSUE 1 — CRUMPLED IS GONE ───────────────────────
  //
  // > *"REMOVE CRUMPLED OPTION"*
  //
  // Three tests used to live here proving it existed. What matters now is the
  // opposite, and it is the half that could hurt somebody: **a vault whose
  // settings still say `"crumpled"` must open**. `fromId` returning null, or
  // throwing, or a `switch` in `design_names.dart` losing its exhaustiveness,
  // would all be a locked-out Appearance screen rather than a missing option.
  group('a page that was left on Crumpled', () {
    test('opens on Paper, which is the surface it was a variation of', () {
      expect(PageSurface.fromId('crumpled'), PageSurface.paper);
    });

    test('and Crumpled is not hiding under another name', () {
      expect(PageSurface.values.map((s) => s.id), isNot(contains('crumpled')));
      for (final s in PageSurface.values) {
        expect(s.label.toLowerCase(), isNot(contains('crumpl')), reason: s.id);
      }
    });

    test('every surface that is left still has a name and a note', () {
      for (final s in PageSurface.values) {
        expect(s.label, isNotEmpty);
        expect(s.note, isNotEmpty);
      }
      expect(PageSurface.values.length, 4,
          reason: 'plain, paper, lamplit, star map');
    });
  });

  group('every combination actually paints', () {
    // Cheap, and it catches the class of fault that only shows up on a real
    // page: a diagonal family whose step works out to zero and spins forever,
    // a star map laid out against a zero-width screen.
    for (final surface in PageSurface.values) {
      for (final ruling in PageRuling.values) {
        testWidgets('${surface.id} + ${ruling.id}', (tester) async {
          await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

            theme: lamplightTheme(LamplightColors.dark),
            home: Scaffold(
              body: PaperGround(
                surface: surface,
                ruling: ruling,
                child: const SizedBox.expand(),
              ),
            ),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('a page narrower than one glyph still paints', (tester) async {
    // A 40-point sliver is what a settings preview tile is, and the star map
    // has to lay a whole sky out inside it without dividing by anything.
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.light),
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 40,
            height: 24,
            child: PaperGround(
              surface: PageSurface.starMap,
              ruling: PageRuling.isometric,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
