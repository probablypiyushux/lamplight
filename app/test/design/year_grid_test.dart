import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/calendar/year_grid.dart';

/// The year grid. `PLAN.md` §9.4 — specified, verified, and until now, never
/// built.
///
/// ── WHAT IS ACTUALLY AT RISK HERE ───────────────────────────────────────────
///
/// Calendar arithmetic fails quietly. An off-by-one in the column maths does
/// not crash and does not look wrong — it draws a perfectly plausible year
/// with every day in the wrong place, and the person looking at it has no way
/// to tell. So the geometry is pinned against dates whose weekday is a matter
/// of record.
///
/// The other risk is not a bug at all. `PLAN.md` §10 forbids red gaps, and
/// `ETHICAL-DESIGN.md` §1 is why: a grid that marks the days you did not write
/// turns a record into a report card. That is a property somebody could
/// "improve" away in a year's time without knowing it was load-bearing, so it
/// is a test rather than a comment.
void main() {
  group('where a day lands', () {
    test('the first of January sits in column zero', () {
      for (final year in [2024, 2025, 2026, 2027]) {
        expect(YearGrid.columnFor(DateTime(year, 1, 1)), 0,
            reason: '1 January $year should open the grid');
      }
    });

    test('rows are weekdays, Monday at the top', () {
      // Monday to match the month grid in the same sheet. Two calendars
      // disagreeing about where a week starts would be a small madness.
      expect(YearGrid.rowFor(DateTime(2026, 8, 24)), 0); // a Monday
      expect(YearGrid.rowFor(DateTime(2026, 8, 30)), 6); // the Sunday after
    });

    test('a week is one column, and the next Monday is the next one', () {
      final monday = DateTime(2026, 8, 24);
      final sunday = DateTime(2026, 8, 30);
      final nextMonday = DateTime(2026, 8, 31);

      expect(YearGrid.columnFor(sunday), YearGrid.columnFor(monday));
      expect(
        YearGrid.columnFor(nextMonday),
        YearGrid.columnFor(monday) + 1,
      );
    });

    test('every day of a leap year has a place, and no two share one', () {
      // 2024 is a leap year that starts on a Monday — the case most likely to
      // push a day off the end of the grid or collide two into one cell.
      final seen = <String>{};
      var day = DateTime(2024, 1, 1);
      while (day.year == 2024) {
        final at = '${YearGrid.columnFor(day)},${YearGrid.rowFor(day)}';
        expect(seen.add(at), isTrue,
            reason: '$day collides with another day at $at');
        expect(YearGrid.columnFor(day), lessThan(YearGrid.columnsIn(2024)));
        day = day.add(const Duration(days: 1));
      }
      expect(seen.length, 366);
    });

    test('a year that needs a 54th column gets one', () {
      // The grid must be sized from the year rather than assumed to be 53, or
      // the last few days of some years are simply not drawn.
      for (var year = 2000; year <= 2040; year++) {
        final last = DateTime(year, 12, 31);
        expect(YearGrid.columnsIn(year), greaterThan(YearGrid.columnFor(last)),
            reason: '31 December $year would fall outside the grid');
      }
    });
  });

  group('how much a day shows', () {
    test('nothing is level zero, and one entry is not', () {
      // The distinction the whole grid rests on. If "nothing happened" and
      // "one small note" drew the same, the shape of the year would be a lie.
      expect(YearGrid.levelFor(0), 0);
      expect(YearGrid.levelFor(1), 1);
    });

    test('more is never less', () {
      var previous = -1;
      for (var n = 0; n <= 40; n++) {
        final level = YearGrid.levelFor(n);
        expect(level, greaterThanOrEqualTo(previous));
        previous = level;
      }
    });

    test('stays inside the ramp', () {
      // Six colours. A seventh level would throw on the busiest day somebody
      // ever has, which is the worst possible day for it to happen.
      for (final n in [0, 1, 5, 50, 5000]) {
        expect(YearGrid.levelFor(n), inInclusiveRange(0, 5));
      }
    });
  });

  group('the rule that gaps are neutral', () {
    testWidgets('an empty day is not drawn in a warning colour', (tester) async {
      // PLAN.md §10 forbids red gaps in the year grid, in the same breath as
      // streaks and shame counts. This is that rule, made mechanical.
      for (final colours in [LamplightColors.dark, LamplightColors.light]) {
        final empty = colours.gridRamp.first;
        expect(empty, isNot(colours.danger));

        // Neutral means the three channels sit close together. A red gap would
        // show up as a wide spread whatever the exact value chosen.
        final spread = [empty.r, empty.g, empty.b];
        final range = spread.reduce((a, b) => a > b ? a : b) -
            spread.reduce((a, b) => a < b ? a : b);
        expect(range, lessThan(0.06),
            reason: 'the empty cell should read as absence, not as a colour');
      }
    });
  });

  group('on a screen', () {
    Widget host(Widget child) => MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: ThemeData(extensions: const [LamplightColors.dark]),
          home: Scaffold(body: SizedBox(width: 380, child: child)),
        );

    testWidgets('a whole year fits without overflowing', (tester) async {
      await tester.pumpWidget(host(YearGrid(
        year: 2026,
        counts: const {'2026-08-24': 3},
        today: DateTime(2026, 8, 24),
        onPick: (_) {},
      )));
      await tester.pumpAndSettle();

      // The point of the screen is seeing a year at once. A horizontal
      // overflow means it does not fit, and the feature has quietly stopped
      // being the thing it was for.
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a day travels to it', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(host(YearGrid(
        year: 2026,
        counts: const {},
        today: DateTime(2026, 8, 24),
        onPick: (d) => picked = d,
      )));
      await tester.pumpAndSettle();

      final cell = find.bySemanticsLabel(RegExp('24 August 2026'));
      expect(cell, findsOneWidget);
      await tester.tap(cell, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.day, 24);
      expect(picked!.month, 8);
    });

    testWidgets('every day is announced, with what is on it', (tester) async {
      await tester.pumpWidget(host(YearGrid(
        year: 2026,
        counts: const {'2026-03-01': 1, '2026-03-02': 4},
        today: DateTime(2026, 8, 24),
        onPick: (_) {},
      )));
      await tester.pumpAndSettle();

      // Singular and plural both, because "1 entries" is the kind of small
      // wrongness that makes an app feel unfinished.
      expect(find.bySemanticsLabel('1 March 2026, 1 entry'), findsOneWidget);
      expect(find.bySemanticsLabel('2 March 2026, 4 entries'), findsOneWidget);
      expect(find.bySemanticsLabel('3 March 2026, nothing'), findsOneWidget);
    });

    testWidgets('today is announced as today', (tester) async {
      await tester.pumpWidget(host(YearGrid(
        year: 2026,
        counts: const {},
        today: DateTime(2026, 8, 24),
        onPick: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('24 August 2026, nothing, today'),
        findsOneWidget,
      );
    });
  });
}
