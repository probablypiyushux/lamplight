import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/features/day/day_pages.dart';

/// The day↔page arithmetic, over four centuries.
///
/// Written because of a report that picking January 1628 in the calendar showed
/// the month but did not travel there. That could have been two very different
/// things — arithmetic that produces an unreachable page, or a user who had not
/// yet tapped a day — and guessing between them from a description is how you
/// fix the wrong one. This settles the arithmetic half.
void main() {
  // A Wednesday, deliberately mid-month and mid-year so nothing lines up
  // conveniently.
  final today = DateTime(2026, 8, 19);
  final pages = DayPages(today);

  test('today is the origin', () {
    expect(pages.pageFor(today), DayPages.origin);
    expect(pages.dateFor(DayPages.origin), today);
  });

  test('yesterday and tomorrow are one page either side', () {
    expect(pages.pageFor(DateTime(2026, 8, 18)), DayPages.origin - 1);
    expect(pages.pageFor(DateTime(2026, 8, 20)), DayPages.origin + 1);
    expect(pages.dateFor(DayPages.origin - 1), DateTime(2026, 8, 18));
  });

  group('every date the calendar can now reach is reachable', () {
    // The year picker runs 400 years back and 200 forward. Every one of those
    // has to land on a page a PageView can actually show — a non-negative
    // index — or the picker is offering a year the day view cannot display.
    for (final year in [1628, 1700, 1900, 1999, 2000, 2026, 2100, 2226]) {
      test('$year round-trips and lands on a real page', () {
        for (final date in [
          DateTime(year, 1, 1),
          DateTime(year, 1, 15),
          DateTime(year, 6, 30),
          DateTime(year, 12, 31),
        ]) {
          final page = pages.pageFor(date);
          expect(page, greaterThanOrEqualTo(0),
              reason: '$date computes page $page, which a PageView cannot '
                  'show — the calendar would offer a date the day view '
                  'cannot open');
          expect(pages.dateFor(page), date,
              reason: '$date did not survive the round trip');
        }
      });
    }
  });

  test('a leap day is a real day and not an off-by-one', () {
    final leap = DateTime(2024, 2, 29);
    expect(pages.dateFor(pages.pageFor(leap)), leap);
    // And the day after it is exactly one page later.
    expect(
      pages.pageFor(DateTime(2024, 3, 1)) - pages.pageFor(leap),
      1,
    );
  });

  test('consecutive pages are always consecutive days, across a year', () {
    // Walks a whole year one page at a time and insists the date advances by
    // exactly one calendar day each time. This is the check that would have
    // caught the daylight-saving bug that `Duration(days: 1)` causes — on the
    // day the clocks change, adding 24 hours does not advance the date.
    var page = pages.pageFor(DateTime(2026, 1, 1));
    var previous = pages.dateFor(page);
    for (var i = 0; i < 365; i++) {
      page += 1;
      final next = pages.dateFor(page);
      final gap = DateTime.utc(next.year, next.month, next.day)
          .difference(DateTime.utc(previous.year, previous.month, previous.day))
          .inDays;
      expect(gap, 1, reason: 'page $page went from $previous to $next');
      previous = next;
    }
  });

  test('the origin leaves room for the whole range the picker offers', () {
    // 400 years back is the deepest the year grid goes. If the origin is ever
    // lowered, this fails before anyone discovers it by travelling there.
    final deepest = pages.pageFor(DateTime(today.year - 400, 1, 1));
    expect(deepest, greaterThan(0),
        reason: 'the day view cannot reach the oldest year the calendar offers');
  });
}
