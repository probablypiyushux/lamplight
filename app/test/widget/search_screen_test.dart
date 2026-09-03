import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/search/search_screen.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND FIFTEEN, ISSUE 7 — the screen he photographed was empty.**
///
/// > *"UI ISSUE NOT SO MUCH BUT FEW!"*, and on the search screen, in red:
/// > *"use the full space dude"*, *"see how close and ugly it looks"*,
/// > *"But why the fuck like this"*.
///
/// He sent a screenshot of a search screen that is a field, five chips, a
/// hairline, and then **nothing at all** — a black rectangle filling four
/// fifths of the display. That is not a design opinion about whitespace. The
/// screen is supposed to show four worked examples there, and they were not
/// being drawn.
///
/// ── AND THE REASON NOBODY NOTICED FOR SIX DAYS ──────────────────────────
///
/// **There was no test for this screen.** Not one, in a suite of 1,246. Search
/// is the feature `search_screen.dart`'s own header calls the difference
/// between a journal and a write-only medium, and the only thing that had ever
/// exercised it was somebody opening it by hand.
///
/// This file is that gap closed. The first test is the screenshot.
void main() {
  late Vault vault;
  late Directory tmp;

  // Real crypto and real files, so this cannot be done inside a `testWidgets`
  // body — see `app_boots_test.dart` and `glass_test.dart` for the full story.
  // A `testWidgets` body runs in a fake-async zone where an await on anything
  // real never completes, and the run stops rather than failing.
  setUpAll(() async {
    final sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_search');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
  });

  tearDownAll(() async {
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(686, 1143);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.dark),
      home: SearchScreen(vault: vault, onOpenDay: (_) {}),
    ));
    // Pumped by hand rather than settled: PaperGround always has a frame
    // scheduled on this app, so pumpAndSettle can never return. See CLAUDE.md.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('an empty search box shows the examples, not a black rectangle',
      (tester) async {
    await open(tester);
    expect(tester.takeException(), isNull,
        reason: 'a ListView nested straight inside another ListView is given '
            'unbounded height, which throws here and draws nothing at all in '
            'a release build. That is the screenshot he sent.');

    final l = await L.delegate.load(const Locale('en'));
    for (final example in [
      l.searchDateExample,
      l.searchWordsExample,
      l.searchFileExample,
      l.searchFolderExample,
    ]) {
      expect(find.text(example), findsOneWidget,
          reason: 'showing that a date works is the whole point of the '
              'feature and is otherwise invisible');
    }
  });

  testWidgets('and they are laid out down the page, not squeezed into nothing',
      (tester) async {
    await open(tester);
    final l = await L.delegate.load(const Locale('en'));

    final first = tester.getRect(find.text(l.searchDateExample));
    final last = tester.getRect(find.text(l.searchFolderExample));

    expect(first.height, greaterThan(0));
    expect(last.top, greaterThan(first.top),
        reason: 'four examples, in order, each below the last');
    // "use the full space dude" — the examples should reach a good way down
    // the screen rather than huddling under the hairline.
    expect(last.bottom, greaterThan(300),
        reason: 'the screenshot had 900 points of nothing below the chips');
  });

  testWidgets('the chips are all there and none of them is the odd one out',
      (tester) async {
    await open(tester);
    final l = await L.delegate.load(const Locale('en'));
    for (final label in [
      l.searchKindWords,
      l.searchKindVoice,
      l.searchKindPhotos,
      l.searchKindVideo,
      l.searchKindFiles,
    ]) {
      // `findsWidgets`, not `findsOneWidget`: "Words" is deliberately both a
      // chip and one of the worked examples below, and those are the same
      // idea said twice on purpose rather than a duplicate.
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('typing something that matches nothing says so', (tester) async {
    await open(tester);
    await tester.enterText(
        find.byType(TextField), 'a word nobody has ever written here');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
