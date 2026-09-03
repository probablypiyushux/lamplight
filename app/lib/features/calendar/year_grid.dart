import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';

import '../../design/tokens.dart';

/// A whole year, seven rows deep. `PLAN.md` §9.4, `DESIGN-SYSTEM.md`'s ramp.
///
/// ── WHAT IT IS FOR, WHICH IS NOT NAVIGATION ─────────────────────────────────
///
/// `PLAN.md` §3 argues that the honest way to make somebody keep a private
/// journal for years is not a streak or a notification — it is **their own
/// material, given back to them**. "On this day" does that one day at a time.
/// This does it for a whole year at once: the shape of a year you actually
/// lived, where the busy weeks were, where the quiet months were.
///
/// You can tap it to travel, and that is useful. It is not the point. The point
/// is the two seconds before you tap anything.
///
/// ── GAPS ARE NEUTRAL. THIS IS A RULE, NOT A COLOUR CHOICE ───────────────────
///
/// `PLAN.md` §10 forbids "red gaps in the year grid" in the same breath as
/// streaks and shame counts, and `ETHICAL-DESIGN.md` §1 is the reason. A grid
/// that marks the days you did not write turns a record into a report card,
/// and the second test in §11 — *does it make someone glad they came back, or
/// anxious about not having* — has exactly one answer for a wall of red.
///
/// So the empty level is a **neutral**, taken from the ramp's first entry,
/// which `tokens.dart` sets to a grey rather than to the palest amber for this
/// reason. Nothing on this screen counts what did not happen.
///
/// ── WHY THE CELLS ARE SMALL, AND WHAT CARRIES THE ACCESSIBILITY ─────────────
///
/// 53 columns across a phone is a cell of about six points. That is well under
/// any touch-target floor, and there is no arrangement of a year-at-a-glance
/// that is not — the moment the cells are 48 points the year no longer fits on
/// the screen and the feature has stopped existing.
///
/// This is the "essential" case in WCAG 2.5.8 rather than a corner cut, and it
/// is only defensible because **an equivalent path already exists one tap
/// away**: the month grid in the same sheet has full-size targets and reaches
/// every day of every year from 1900 to 2100. The year grid is an overview
/// with a shortcut on it. Nothing here is the only way to do anything.
///
/// Every cell still carries its own label, so a screen reader reads "24 August
/// 2026, three entries" rather than announcing a decorative rectangle. That is
/// 371 semantics nodes, which is a number worth knowing and is comfortably
/// inside what Flutter handles on one static screen.
class YearGrid extends StatelessWidget {
  const YearGrid({
    super.key,
    required this.year,
    required this.counts,
    required this.today,
    required this.onPick,
    this.viewing,
  });

  final int year;

  /// Entries per `YYYY-MM-DD`. A missing key means nothing happened, which is
  /// not the same as zero and must not be drawn as level one of the ramp.
  final Map<String, int> counts;

  final DateTime today;

  /// The day the user came from, ringed so they can find themselves.
  final DateTime? viewing;

  final ValueChanged<DateTime> onPick;

  /// Which step of the ramp a day sits on.
  ///
  /// The thresholds are deliberately coarse at the top. The difference between
  /// eleven entries and forty is not something anybody needs to read off a
  /// six-point square, and stretching the ramp to cover it would flatten the
  /// difference between one entry and three — which is the distinction that
  /// actually tells you what kind of week you were having.
  static int levelFor(int count) {
    if (count <= 0) return 0;
    if (count == 1) return 1;
    if (count <= 3) return 2;
    if (count <= 6) return 3;
    if (count <= 10) return 4;
    return 5;
  }

  /// The Monday-based column a date falls in, 0–52.
  ///
  /// Weeks run Monday to Sunday to match the month grid, which uses the same
  /// order. Two calendars in one sheet disagreeing about where a week starts
  /// would be a small madness.
  static int columnFor(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    // How far into its week 1 January sits. `weekday` is 1 for Monday.
    final lead = jan1.weekday - 1;
    final dayOfYear = date.difference(jan1).inDays;
    return (dayOfYear + lead) ~/ 7;
  }

  static int rowFor(DateTime date) => date.weekday - 1;

  /// How many columns this year actually needs — 53 in most years, 54 when a
  /// leap year starts late enough in the week to push into one more column.
  static int columnsIn(int year) => columnFor(DateTime(year, 12, 31)) + 1;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;

    return LayoutBuilder(
      builder: (context, box) {
        final columns = columnsIn(year);
        // The gutter carries three weekday initials. Three rather than seven
        // because seven at this size is a column of noise, and Monday,
        // Wednesday and Friday are enough to orient by.
        const gutter = 14.0;
        const gap = 1.0;
        final cell =
            ((box.maxWidth - gutter) / columns - gap).clamp(3.0, 12.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthLabels(
              year: year,
              columns: columns,
              cell: cell,
              gap: gap,
              gutter: gutter,
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gutter,
                  child: Column(
                    children: [
                      for (var row = 0; row < 7; row++)
                        SizedBox(
                          height: cell + gap,
                          child: row.isOdd
                              ? Text(
                                  const ['', 'T', '', 'T', '', 'S', ''][row],
                                  style: TextStyle(
                                    fontSize: 8,
                                    height: 1,
                                    color: c.inkMuted,
                                  ),
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (var row = 0; row < 7; row++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: gap),
                          child: Row(
                            children: [
                              for (var col = 0; col < columns; col++)
                                _Cell(
                                  date: _dateAt(year, col, row),
                                  counts: counts,
                                  today: today,
                                  viewing: viewing,
                                  size: cell,
                                  gap: gap,
                                  onPick: onPick,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            _Legend(cell: cell),
          ],
        );
      },
    );
  }

  /// The date in a column and row, or null where the grid runs past the year.
  ///
  /// Nulls are real and are drawn as nothing at all — the first few cells of
  /// column zero and the last few of the final column. Filling them with the
  /// neighbouring year's days would put somebody's December in the same shape
  /// as their January.
  static DateTime? _dateAt(int year, int col, int row) {
    final jan1 = DateTime(year, 1, 1);
    final lead = jan1.weekday - 1;
    final dayOfYear = col * 7 + row - lead;
    if (dayOfYear < 0) return null;
    final date = jan1.add(Duration(days: dayOfYear));
    if (date.year != year) return null;
    return date;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.date,
    required this.counts,
    required this.today,
    required this.viewing,
    required this.size,
    required this.gap,
    required this.onPick,
  });

  final DateTime? date;
  final Map<String, int> counts;
  final DateTime today;
  final DateTime? viewing;
  final double size;
  final double gap;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final d = date;

    if (d == null) {
      return SizedBox(width: size + gap, height: size);
    }

    final key = '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final count = counts[key] ?? 0;
    final level = YearGrid.levelFor(count);

    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    final isViewing = viewing != null &&
        d.year == viewing!.year &&
        d.month == viewing!.month &&
        d.day == viewing!.day;

    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: Semantics(
        button: true,
        // Read as a sentence, because a screen reader user gets this one cell
        // and no surrounding shape to infer from.
        label: '${_spoken(context, d)}, '
            '${L.of(context).entriesCount(count)}'
            '${isToday ? ', ${L.of(context).dayToday.toLowerCase()}' : ''}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onPick(d),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c.gridRamp[level],
              borderRadius: BorderRadius.circular(1),
              // Today and the day you came from are rings rather than fills,
              // so they read as position rather than as a busy day.
              border: isToday || isViewing
                  ? Border.all(
                      color: isToday ? c.accent : c.inkSecondary,
                      width: 1,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// The date a screen reader says for one cell.
  ///
  /// Takes a context now: the month names came from a `static const` English
  /// list, and there were eight such lists in the app. `l10n/dates.dart` is the
  /// one place, and it needs to know the locale.
  static String _spoken(BuildContext context, DateTime d) =>
      LampDates.dayMonthYear(context, d);
}

/// Month names along the top, each over the column its first day falls in.
class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.year,
    required this.columns,
    required this.cell,
    required this.gap,
    required this.gutter,
  });

  final int year;
  final int columns;
  final double cell;
  final double gap;
  final double gutter;

  static const _short = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;

    return SizedBox(
      height: 10,
      child: Row(
        children: [
          SizedBox(width: gutter),
          Expanded(
            child: Stack(
              children: [
                for (var m = 1; m <= 12; m++)
                  Positioned(
                    left: YearGrid.columnFor(DateTime(year, m, 1)) *
                        (cell + gap),
                    top: 0,
                    child: Text(
                      // Single letters. Three-letter names at this column width
                      // overlap in February and collide every time, and a label
                      // that sits over the wrong month is worse than a letter.
                      _short[m - 1],
                      style: TextStyle(
                        fontSize: 8,
                        height: 1,
                        color: c.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Less → more, so the ramp is readable without being explained.
class _Legend extends StatelessWidget {
  const _Legend({required this.cell});

  final double cell;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final size = cell.clamp(6.0, 10.0);

    return Semantics(
      // One node, not seven. The swatches are a key to the grid above, and a
      // screen reader reading six unnamed colours would be noise.
      label: L.of(context).calendarDensityNote,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(L.of(context).calendarLess,
              style: TextStyle(fontSize: 10, color: c.inkMuted, height: 1)),
          const SizedBox(width: 4),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: c.gridRamp[i],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          const SizedBox(width: 2),
          Text(L.of(context).calendarMore,
              style: TextStyle(fontSize: 10, color: c.inkMuted, height: 1)),
        ],
      ),
    );
  }
}
