import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/components.dart';
import 'package:lamplight/design/paper.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/capture/capture_bar.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/day/day_screen.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND EIGHT — the three notes he wrote around the capture bar.**
///
/// He drew a ring round the whole bottom bar and wrote *"Give this section
/// little transparency — The Background"*, *"A little glassmorphism can be used
/// here"*, and *"Can look cool and also stay in our app's aesthetics"*.
///
/// The bar got more transparent, and the argument for why that is safe rests on
/// a fact about the layout rather than on taste: **nothing passes behind it.**
/// This file is that fact, written down as something that fails if it stops
/// being true.
void main() {
  // ── Built in setUpAll, not inside the test ─────────────────────────────
  //
  // A `testWidgets` body runs in a fake-async zone: `SodiumSumoInit.init`
  // loads a native library and `vault.create` runs Argon2 over real files, and
  // neither of those ever completes in there. Doing it inline hangs the test
  // for the full ten-minute timeout with no useful message, which is exactly
  // what it did the first time this was written.
  late Vault vault;
  late AppSettings settings;
  late Directory tmp;

  setUpAll(() async {
    final sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_glass');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    settings = await AppSettings.load(File('${tmp.path}/settings.json'));
  });

  tearDownAll(() async {
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Relative luminance, per WCAG 2.x.
  double luminance(Color c) => c.computeLuminance();

  double contrast(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// What [over] at [alpha] actually looks like once it is composited onto
  /// [under]. Source-over, the only blend a translucent panel does.
  Color composite(Color over, double alpha, Color under) => Color.fromARGB(
        255,
        ((over.r * alpha + under.r * (1 - alpha)) * 255).round(),
        ((over.g * alpha + under.g * (1 - alpha)) * 255).round(),
        ((over.b * alpha + under.b * (1 - alpha)) * 255).round(),
      );

  // ── The bar's own numbers, read from the bar ──────────────────────────
  //
  // These used to be copies, with a comment saying to change them in step. A
  // test holding its own copy of the value it is checking is a test that goes
  // on passing while measuring something the app no longer does — so it reads
  // the real constants now and the drift is not possible.
  const topAlpha = LampGlass.defaultTopAlpha;
  const bottomAlpha = LampGlass.defaultBottomAlpha;

  // ══ ROUND FIFTEEN, ISSUE 6 — WHAT ACTUALLY MAKES IT SEE-THROUGH ═════════
  //
  // > *"WHEREVER YOU HAVE USED GLASSMORPHISM - PLEASE MAKE THE GLASS A LIL
  // > TRANSCLUCENT - I NEED IT TO BE A LIL SEE THROUGH A LIL!"*, and in red
  // > round the capture bar: *"give me glass like feel"*.
  //
  // Third time of asking, and the first two attempts moved the alpha, which is
  // the knob that could not do it. These tests state the two facts that
  // together decide whether a pane looks see-through, so that the next person
  // to be asked for "more glass" turns the right one.
  group('why the alpha alone could never do it', () {
    test('surface and canvas are the same colour, so mixing them shows nothing',
        () {
      for (final c in [LamplightColors.dark, LamplightColors.light]) {
        expect(contrast(c.surface, c.canvas), lessThan(1.2),
            reason: 'this is not a complaint about the palette — one step '
                "apart is exactly right for a surface. It is the reason "
                'lowering the glass alpha cannot make the bar look more '
                'see-through: both sides of the mix are the same colour, so '
                'the composite lands in the same place at 0.9 and at 0.1');
      }
    });

  });

  group('the blur is small enough to leave the page recognisable', () {
    // A Gaussian of standard deviation sigma multiplies a feature of
    // wavelength L by exp(-2 pi^2 sigma^2 / L^2). That is the whole of ISSUE 6
    // in one equation, so it is the thing pinned here rather than the number:
    // somebody raising the blur has to argue with the page rather than with a
    // magic constant.
    double survives(double sigma, double wavelength) =>
        math.exp(-2 * math.pi * math.pi * sigma * sigma /
            (wavelength * wavelength));

    const glass = LampGlass(child: SizedBox.shrink());

    test('a rule gap keeps more than half its contrast', () {
      // 40 points is roughly the gap between ruled lines and the width of a
      // major fold. At the old sigma of 18 this was 1.84% — erased.
      expect(survives(glass.blur, 40), greaterThan(0.5),
          reason: 'the page has to be visible through the glass, or it is not '
              'glass, it is a slightly different grey');
    });

    test('the lamp comes through almost untouched', () {
      expect(survives(glass.blur, 160), greaterThan(0.9));
    });

    test('but a star is still smoothed away, so it is frosted not clear', () {
      // The thing that keeps this glass rather than a window. A star is a
      // point; a point has no wavelength to survive.
      expect(survives(glass.blur, 4), lessThan(0.01));
      expect(survives(glass.blur, 12), lessThan(0.05));
    });

    test('the old blur failed every one of those', () {
      expect(survives(18, 40), lessThan(0.05),
          reason: 'kept as the counter-example, so the number that was wrong '
              'stays measurable rather than becoming folklore');
      expect(survives(18, 24), lessThan(0.001));
    });
  });

  group('the labels on the glass still clear AA through it', () {
    for (final entry in {
      'dark': LamplightColors.dark,
      'light': LamplightColors.light,
    }.entries) {
      final c = entry.value;

      test('${entry.key}: the caption under each glyph', () {
        // The thinnest ink on the bar, over the most transparent part of it.
        final through = composite(c.surface, bottomAlpha, c.canvas);
        expect(contrast(c.inkMuted, through), greaterThanOrEqualTo(4.5),
            reason: 'the bar carries words — Voice, Photo, File — and a word '
                'you cannot read is worse than no word');
      });

      test('${entry.key}: the glyphs themselves', () {
        final through = composite(c.surface, topAlpha, c.canvas);
        expect(contrast(c.inkSecondary, through), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: transparency barely moves the background at all', () {
        // Why the above passes with room to spare, stated as the reason rather
        // than as a lucky result: `surface` and `canvas` are one step apart, so
        // letting the canvas through changes the composite by a hair. This is
        // what would stop being true if somebody made `canvas` and `surface`
        // far apart, and it would take the contrast with it.
        final through = composite(c.surface, bottomAlpha, c.canvas);
        expect(contrast(c.surface, through), lessThan(1.2),
            reason: 'the glass is see-through, not a different colour');
      });
    }
  });

  testWidgets('nothing is laid out behind the capture bar', (tester) async {
    // ── The fact the whole change rests on ────────────────────────────────
    //
    // The bar is a sibling of the day's PageView in a Column, not a layer over
    // it, so a `BackdropFilter` inside it can only ever sample the page. If
    // somebody moves the bar into a Stack over the stream — which is the
    // obvious thing to do if you ever want the day to scroll under it — then
    // writing really would show through 52% glass, and the old 88/78 numbers
    // were right after all. This test is where that gets noticed.
    tester.view.physicalSize = const Size(686, 1143);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: Column(
          children: [
            const Expanded(child: ColoredBox(color: Color(0xFF123456))),
            CaptureBar(onVoice: () {}, onPhoto: () {}, onFile: () {}),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(CaptureBar));
    final above = tester.getRect(find.byType(ColoredBox).first);
    expect(above.bottom, lessThanOrEqualTo(bar.top + 0.5),
        reason: 'the stream must stop where the bar starts');
  });

  testWidgets('and the real day screen keeps it that way', (tester) async {
    // The same assertion against the screen itself rather than against a
    // reconstruction of it. This is the one that would actually catch somebody
    // moving the bar into a `Stack` so the day can scroll under it.
    tester.view.physicalSize = const Size(686, 1143);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: DayScreen(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      ),
    ));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    final bar = tester.getRect(find.byType(CaptureBar));
    final stream = tester.getRect(find.byType(PageView));
    expect(stream.bottom, lessThanOrEqualTo(bar.top + 0.5),
        reason: 'the day stops where the bar starts — which is why 52% glass '
            'is safe here and would not be if the two overlapped');

    // Unmounted unconditionally, including after a failure: a DayScreen left
    // mounted keeps a live database stream open, and `vault.lock()` in
    // tearDownAll then waits for it for ever.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('and the page really is behind the bar, not just the canvas',
      (tester) async {
    // The other half of ISSUE 6, as a layout fact. What a person sees through
    // the pane is the **page** — stars, lamp, folds, ruling — because
    // PaperGround is full-bleed and the capture bar is drawn inside it. If
    // somebody ever moves the bar outside that subtree the blur has nothing
    // left to sample and the glass goes back to being a grey rectangle, at any
    // alpha. That is a different layer from the day *stream*, which must still
    // stop at the bar; the two tests above and below are not the same claim.
    tester.view.physicalSize = const Size(686, 1143);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.dark),
      home: DayScreen(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      ),
    ));
    await tester.pump();

    expect(
      find.ancestor(
        of: find.byType(CaptureBar),
        matching: find.byType(PaperGround),
      ),
      findsWidgets,
      reason: 'the bar is inside the page, so the BackdropFilter has the page '
          'to sample. Move it out and there is nothing to see through.',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('the glass turns itself off when the platform asks',
      (tester) async {
    // Unchanged by this round, and restated because the transparency went up:
    // under reduced transparency or high contrast there is no blur at all and
    // the bar is fully opaque. `ACCESSIBILITY.md` treats those as instructions
    // rather than hints, and the more see-through the default gets the more
    // that matters.
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: Scaffold(
          body: CaptureBar(onVoice: () {}, onPhoto: () {}, onFile: () {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing,
        reason: 'no effect at all, rather than a weaker one');

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: CaptureBar(onVoice: () {}, onPhoto: () {}, onFile: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget,
        reason: 'and it is there by default');
  });
}
