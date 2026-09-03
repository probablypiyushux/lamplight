import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/day_header.dart';

/// **ISSUE 9 and 10 — the alignment he circled on three separate pages.**
///
/// *"Why are they not on the right?"* against the search and gear icons, and
/// again against the ‹ › day arrows. *"Alighnment issues"*, twice, with arrows.
///
/// ── WHAT IT ACTUALLY WAS ─────────────────────────────────────────────────
///
/// Each of those rows held a label in a `Flexible` followed by a `Spacer`.
/// Both are flex-1 children, so the Row divided the free space evenly between
/// them — but `Flexible` is a **loose** fit, so the label took only the width
/// of its own text and handed the remainder back. A Row with leftover space and
/// the default `MainAxisAlignment.start` parks that leftover at the *end*: a
/// hole between the last icon and the margin.
///
/// The hole's size depended on how short the label happened to be, which is why
/// it looked arbitrary rather than merely wrong. Measured on a 360-point phone
/// before the fix: the gear stopped **19.7 points** short of the rule, and the
/// chevrons — whose label, "TODAY", is shorter — stopped **50.4 points** short.
///
/// These tests state the intended geometry in points, so the next person to
/// reach for `Flexible` next to a `Spacer` finds out immediately.
void main() {
  Widget header({String name = 'Piyush', bool isToday = true}) => MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: DayHeader(
            date: DateTime(2026, 8, 24),
            isToday: isToday,
            greetingName: name,
            onPickDate: () {},
            onPrevious: () {},
            onNext: isToday ? null : () {},
            onSearch: () {},
            onSettings: () {},
          ),
        ),
      );

  /// Where a 48-point tap target's trailing edge belongs.
  ///
  /// `Layout.iconInset` is the optical correction that puts a 24-point glyph
  /// inside a 48-point target onto the same rule as the text: the *target* ends
  /// 12 points outside the gutter so that the *glyph* inside it ends exactly on
  /// the gutter.
  double targetRuleFor(double width) => width - Layout.iconInset;

  /// And where the glyph itself belongs — the rule the date starts on.
  double glyphRuleFor(double width) => width - Layout.gutter;

  /// The tap target around an icon.
  ///
  /// Measured rather than the `Icon` itself, because the two controls build
  /// differently and their `Icon` render boxes are not comparable: an
  /// `IconButton` leaves its icon at 24 points, while `_Chevron`'s plain
  /// `SizedBox` imposes tight 48-point constraints and stretches the icon's box
  /// to fill them. Both draw the same 24-point glyph in the same place; only
  /// one of them reports a 24-point rectangle for it. Comparing those two
  /// numbers directly is how a passing layout looks like a failing one.
  Finder targetOf(IconData icon) => find
      .ancestor(
        of: find.byIcon(icon),
        matching: find.byWidgetPredicate((w) =>
            w is IconButton || (w is SizedBox && w.width == kMinTouchTarget)),
      )
      .first;

  for (final width in <double>[320, 360, 412, 768, 1024]) {
    group('on a ${width.toInt()}-point screen', () {
      testWidgets('the search and gear icons end on the right rule',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(header());
        await tester.pumpAndSettle();

        final gear = tester.getRect(targetOf(Icons.settings_outlined));
        expect(gear.right, closeTo(targetRuleFor(width), 0.5),
            reason: 'the gear must end on the same rule as everything else — '
                'this is "why are they not on the right?"');
        // The glyph inside it lands on the text rule.
        expect(tester.getRect(find.byIcon(Icons.settings_outlined)).right,
            closeTo(glyphRuleFor(width), 0.5));

        // And the search sits immediately inboard of it, one tap target away.
        final search = tester.getRect(targetOf(Icons.search));
        expect(search.right, closeTo(gear.right - kMinTouchTarget, 0.5));
      });

      testWidgets('the day chevrons end on the SAME rule as the gear',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(header(isToday: false));
        await tester.pumpAndSettle();

        final gear = tester.getRect(targetOf(Icons.settings_outlined));
        final next = tester.getRect(targetOf(Icons.chevron_right));

        expect(next.right, closeTo(targetRuleFor(width), 0.5));
        // The half that made it read as arbitrary: the two rows disagreed with
        // each other by a different amount at every width.
        expect(next.right, closeTo(gear.right, 0.5),
            reason: 'both rows must land on one rule, not two');
      });

      testWidgets('the date starts on the left rule', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(header());
        await tester.pumpAndSettle();

        expect(tester.getRect(find.text('24 August')).left,
            closeTo(Layout.gutter, 0.5));
        expect(tester.getRect(find.text('TODAY')).left,
            closeTo(Layout.gutter, 0.5));
      });

      // ══ ROUND EIGHT, ISSUE 8 ══════════════════════════════════
      //
      // *"I want them close"*, with **MAIN ISSUE** underneath it and one arrow
      // drawn from the date at the far left to the chevron at the far right.
      //
      // This is the exact opposite of the assertion three tests above, and
      // that is the point: **the toolbar rows belong to the margin and this
      // row does not.** A row that is a label plus that label's own affordance
      // has to stay together; a row that is a title plus a toolbar must not.
      // Both rules now live in one file so that satisfying either of them
      // cannot quietly undo the other.
      testWidgets('the dropdown sits against the date, not the margin',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(header());
        await tester.pumpAndSettle();

        final date = tester.getRect(find.text('24 August'));
        final chevron = tester.getRect(find.byIcon(Icons.expand_more));

        // The whole of ISSUE 8, in one number, at every width.
        expect(chevron.left - date.right, closeTo(Space.x1, 1.0),
            reason: 'the chevron is the date\'s punctuation, not the room\'s '
                'furniture');

        // And it is a row, not a stack: the two are on the same line.
        expect(chevron.center.dy, closeTo(date.center.dy, 3.0));
      });
    });
  }

  testWidgets('a very long name does not push the icons off their rule',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(header(
        name: 'Bartholomew Fitzgerald-Wellington the Third and a bit more'));
    await tester.pumpAndSettle();

    final gear = tester.getRect(targetOf(Icons.settings_outlined));
    expect(gear.right, closeTo(360 - Layout.iconInset, 0.5),
        reason: 'the name ellipsises; the icons do not move');
  });

  testWidgets('no name at all leaves the icons exactly where they were',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(header(name: ''));
    await tester.pumpAndSettle();

    expect(tester.getRect(targetOf(Icons.settings_outlined)).right,
        closeTo(360 - Layout.iconInset, 0.5));
  });

  // ══ ROUND EIGHT, ISSUE 8 ════════════════════════════════════════
  //
  // The measurement that catches `Expanded` coming back, on the device he
  // actually reported it from.
  //
  // The gap test above passes either way on a narrow phone, because "24
  // August" at display size is about 300 points wide and a 320-point screen
  // has no slack to leave: the date fills the row and the chevron ends up at
  // the margin whichever widget holds it. It is on a wide screen that the two
  // layouts separate, which is precisely why he saw it on the tablet.
  testWidgets('on his tablet the chevron is 340 points in from the margin',
      (tester) async {
    // Redmi Pad, 1200×2000 at density 280 — 685.7 logical points. PLAN.md §0.
    tester.view.physicalSize = const Size(686, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(header());
    await tester.pumpAndSettle();

    final chevron = tester.getRect(find.byIcon(Icons.expand_more));
    final rightRule = 686 - Layout.gutter;

    // Where `Expanded` used to leave it: hard against the rule, about 343
    // points from the word it belongs to.
    expect(rightRule - chevron.right, greaterThan(300),
        reason: 'this is the number he drew the arrow across');
    expect(chevron.right, lessThan(360));
  });

  test('the rail is the two-point rule plus the gap after it', () {
    // The number the day stream is pulled left by, so that an entry's content
    // — and a voice note's play button — lands on the gutter rather than
    // fourteen points inside it. "Why are they in middle."
    expect(Layout.rail, 2 + Space.x3);
  });

  // ══ ROUND NINE, ISSUE 3 — THE SAME MISTAKE, TWICE MORE ═════════════════════
  //
  // *"ALIGHNMENT — FIX IT ASAP! 2 PLACES ON EDIT TAB! AND ON SETTINGS TAB!"*
  // With, on the screenshots: a circle round **Done** and *"why Is this In
  // middle? why?"*, and a red box round the settings colophon and *"why Is this
  // on the leftest side possible? Keep it in the middle."*
  //
  // Both are the fault this whole file exists about — **a loose fit takes only
  // what it needs, and then something else decides where that goes** — and both
  // survived the round that wrote the file. So they get tests here, next to the
  // original, rather than somewhere new: the point of a regression test is that
  // the next person looking at a layout complaint finds every previous one in
  // the same place.
  group('ISSUE 3 — a control ends up where the design put it', () {
    testWidgets('two buttons in a row sit at the two ends, at any text size',
        (tester) async {
      // The editing row's shape: Delete on the left, Done on the right. Built
      // here rather than driven through the day screen, because what is under
      // test is the shape itself — and because the shape is now used in a
      // second place and should stay correct in both.
      Widget row() => MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

            theme: lamplightTheme(LamplightColors.dark),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () {}, child: const Text('Delete')),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {}, child: const Text('Done')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

      tester.view.physicalSize = const Size(686, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(row());
      await tester.pumpAndSettle();

      final done = tester.getRect(find.text('Done'));
      final delete = tester.getRect(find.text('Delete'));
      const rightRule = 686 - Layout.gutter;

      // The old arrangement put Done about a third of the way in from the
      // right — 686 wide, so roughly x = 460. Anything under 600 is the bug.
      expect(done.right, greaterThan(600),
          reason: '"why Is this In middle? why?" — Done is adrift again');
      expect(rightRule - done.right, lessThan(40));
      expect(delete.left, lessThan(Layout.gutter + 40));
    });

    testWidgets('a centred block is centred on the screen, not on itself',
        (tester) async {
      // The colophon's situation: a `Column` with `crossAxisAlignment: start`
      // hands its children loose constraints, so a child that centres its own
      // contents still ends up hard against the left edge.
      Widget colophon({required bool tight}) => MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

            theme: lamplightTheme(LamplightColors.dark),
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: tight ? double.infinity : null,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('Made by'), Text('PROBABLYPIYUSH')],
                    ),
                  ),
                ],
              ),
            ),
          );

      tester.view.physicalSize = const Size(686, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // First the bug, so the test proves the difference rather than merely
      // that something is centred.
      await tester.pumpWidget(colophon(tight: false));
      await tester.pumpAndSettle();
      final adrift = tester.getRect(find.text('PROBABLYPIYUSH'));
      expect(adrift.center.dx, lessThan(686 / 2 - 40),
          reason: 'if this ever fails, the diagnosis in settings_screen.dart '
              'is wrong and the comment should go');

      await tester.pumpWidget(colophon(tight: true));
      await tester.pumpAndSettle();
      final centred = tester.getRect(find.text('PROBABLYPIYUSH'));
      expect(centred.center.dx, closeTo(686 / 2, 2),
          reason: '"keep it in the middle"');
    });
  });
}
