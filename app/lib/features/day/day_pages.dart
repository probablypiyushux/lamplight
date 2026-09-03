/// The arithmetic that maps a day onto a page of the day view, and back.
///
/// Pulled out of the widget so it can be tested. It looks trivial and it is
/// not: it has to survive daylight saving, leap years, and a calendar picker
/// that can now send you four centuries away — and every one of those has
/// already produced a bug here.
class DayPages {
  const DayPages(this.today);

  /// Today, at midnight, as the day view was built.
  final DateTime today;

  /// Which page today sits on.
  ///
  /// **Large on purpose.** It used to be 10,000 — about 27 years — which was
  /// fine while the calendar could only reach a few years back. Once the year
  /// picker became unbounded it could ask for 1750, and that computes a
  /// *negative* page, which a `PageView` cannot show: the picker would have
  /// offered a year the day view could not display. 200,000 is about 547 years
  /// either side, and it costs nothing because pages are built lazily.
  static const int origin = 200000;

  /// **Not `today.add(Duration(days: n))`.**
  ///
  /// A `Duration` is an exact number of hours, and two days a year are not 24
  /// hours long. Adding 24 hours to the day a clock goes forward lands at 01:00
  /// the following day; on the day it goes back, at 23:00 the same day. A swipe
  /// would silently skip a day or refuse to move. Building the date from its
  /// parts lets Dart normalise the overflow using the calendar rather than the
  /// clock, which is what "one day later" actually means.
  DateTime dateFor(int page) =>
      DateTime(today.year, today.month, today.day + (page - origin));

  /// The inverse, by the same rule: count calendar days, not elapsed hours.
  ///
  /// Both sides are converted to UTC first so the subtraction cannot land on a
  /// daylight-saving boundary and come back 23 or 25 hours short.
  int pageFor(DateTime date) {
    final from = DateTime.utc(today.year, today.month, today.day);
    final to = DateTime.utc(date.year, date.month, date.day);
    return origin + to.difference(from).inDays;
  }
}
