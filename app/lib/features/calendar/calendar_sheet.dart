import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';

import '../../core/db/database.dart' show Attachment;
import '../../core/db/entry_repository.dart';
import '../../core/media/encrypted_image.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/storage/attachment_store.dart';
import '../../design/tokens.dart';
import 'date_wheel.dart';
import 'year_grid.dart';

/// Jump to any day. `UX-FLOWS.md` §2: "Tap the date → month calendar."
///
/// `ANNOYANCES.md`: "No way to jump to a date. Swiping back a year means ~365
/// swipes." Two taps now, and the year row makes it one.
///
/// WHY THE DAY NUMBER DOES NOT SIT ON A COLOURED CELL
///
/// The obvious build of this screen is a heatmap: fill each cell with the year
/// grid's ramp and print the date on top. It was measured before it was drawn,
/// and it fails. Against light-mode level 4 (`#A16F26`) the best either ink can
/// manage is **4.14:1** — under the 4.5:1 floor — so on that one shade the
/// numbers would be legally and actually hard to read, in the mode people use
/// outdoors. There is no ink that fixes it; the shade itself is the problem,
/// and the shade is correct for the year grid it was designed for.
///
/// So the number always sits on the sheet's own surface, where it is at worst
/// 15:1, and the density is carried underneath it as a bar. That buys something
/// beyond compliance: the bar varies in **width as well as colour**, so the
/// difference between a quiet day and a full one survives greyscale, sunlight
/// and every form of colour blindness — which is what `DESIGN-SYSTEM.md` means
/// when it says colour is never the only channel.
///
/// The ratios above are computed in `test/design/calendar_contrast_test.dart`,
/// not remembered. Change a ramp value and that test tells you.
Future<DateTime?> showCalendarSheet({
  required BuildContext context,
  required EntryRepository repository,
  required AttachmentImporter importer,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CalendarSheet(
      repository: repository,
      importer: importer,
      initialDate: initialDate,
    ),
  );
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.repository,
    required this.importer,
    required this.initialDate,
  });

  final EntryRepository repository;
  final AttachmentImporter importer;
  final DateTime initialDate;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  /// Months are a `PageView`, so you swipe through them.
  ///
  /// **This is the fix for "August to January makes you tired".** With chevrons
  /// alone that is seven separate taps, each with a rebuild in between, and it
  /// feels like work — which is the opposite of what a journal wants from the
  /// gesture that moves through your own past.
  ///
  /// Swiping is how every calendar people already use behaves, so there is
  /// nothing to learn. The chevrons stay because `ACCESSIBILITY.md` does not
  /// allow a gesture to be the only way to do something, and the month name is
  /// still a button, because a swipe is fine for one month and no good at all
  /// for four years.
  static const int _originPage = 6000;

  late final DateTime _origin =
      DateTime(widget.initialDate.year, widget.initialDate.month);
  late final PageController _months =
      PageController(initialPage: _originPage);

  late DateTime _month = _origin;

  /// Whether the wheels are up instead of the grid.
  ///
  /// Two modes rather than one control trying to be both. Browsing and going
  /// somewhere specific are different intentions and they want different
  /// tools — see the long note on [DateWheel] for what happened when one
  /// control had to serve both.
  _Mode _mode = _Mode.browsing;

  /// Reading `_jumping` everywhere kept the diff small when the third mode
  /// arrived, and it is still the only question most of the header asks.
  bool get _jumping => _mode == _Mode.jumping;

  /// The year the grid is showing. Only meaningful in [_Mode.year].
  late int _year = widget.initialDate.year;

  // ══ THE YEAR GRID SLIDES TOO. ISSUE 8 ═════════════════════════════════════
  //
  // > *"When I slide between months it's smooth as butter, my fingers feel
  // > heavenly — but in year grid I can't slide years."*
  //
  // The month view was a `PageView` and the year view was a widget rebuilt
  // under a new key. Nothing was wrong with it except that it was a different
  // kind of thing in the same sheet, one screen apart, and the difference is
  // exactly the sort a finger notices and a diff does not.
  //
  // **Bounded rather than infinite, which the months are not.** Months run in
  // both directions from wherever you opened the sheet, so they need an origin
  // and an arbitrary page number to count from. Years are 1900 to 2100 — that
  // is `DateWheel`'s range and this has to agree with it — so the page *is* the
  // year, offset by 1900, and there is no arithmetic to get wrong. It also
  // means the `PageView` refuses to slide past either end on its own, rather
  // than being clamped after the fact by a `setState` that has to undo a
  // gesture the user already saw happen.
  static const int _firstYear = 1900;
  static const int _lastYear = 2100;

  late final PageController _years =
      PageController(initialPage: _pageForYear(widget.initialDate.year));

  static int _pageForYear(int year) =>
      year.clamp(_firstYear, _lastYear) - _firstYear;



  /// The day the user came from, so the wheels open where they already are.
  late final DateTime _viewing = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
    widget.initialDate.day,
  );

  /// The oldest day the vault has anything on. Bounds the year wheel, so it is
  /// a short list of plausible years rather than four centuries of empty.
  DateTime? _earliest;

  @override
  void initState() {
    super.initState();
    widget.repository.earliestDayKey().then((key) {
      if (!mounted || key == null) return;
      final parts = key.split('-');
      if (parts.length != 3) return;
      setState(() {
        _earliest = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      });
    });
  }

  @override
  void dispose() {
    _months.dispose();
    _years.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_origin.year, _origin.month + (page - _originPage));

  int _pageForMonth(DateTime m) =>
      _originPage +
      (m.year - _origin.year) * 12 +
      (m.month - _origin.month);

  void _goToMonth(DateTime m, {bool animate = false}) {
    final page = _pageForMonth(m);
    // Animate only for a step of one. Sliding through forty months would be
    // motion that means nothing, and it would build every month on the way.
    if (animate && (page - _pageForMonth(_month)).abs() == 1) {
      _months.animateToPage(
        page,
        duration: Motion.duration(context),
        curve: Motion.curve,
      );
    } else {
      _months.jumpToPage(page);
    }
    setState(() => _month = m);
  }

  /// Monday first. `DATA-MODEL.md` puts the week's start with the local
  /// convention, and `DateTime.weekday` is already 1 = Monday.

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Room for six weeks, whatever the text size.
  ///
  /// Six because that is the worst case — a 31-day month starting on a Sunday
  /// spans six rows — and every month gets the same height so the sheet does
  /// not resize under your thumb as you swipe. Scaled with the OS text setting,
  /// because at 200% a cell is a good deal taller than 48dp and a fixed number
  /// here would clip the last week of the month.
  double _gridHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(17) / 17;
    return 6 * math.max(kMinTouchTarget, 34 + 22 * scale);
  }

  /// One year, with the same movement a swipe would have made. **ISSUE 8.**
  ///
  /// > *"When I use the arrows it jerks like hell! I feel like I have done
  /// > something to piss off my phone."*
  ///
  /// This half of it was literal: the year arrows called `setState` and the
  /// grid was replaced under a new key, so a whole year of squares vanished and
  /// a different one appeared in the same frame. There was no motion to be
  /// smooth or otherwise — that *is* a jerk, and it is what the word describes.
  ///
  /// Now it is the same `animateToPage` the month arrows use, on the same
  /// duration, which means the arrow and the swipe produce the identical
  /// movement. `Motion.duration` respects the phone's reduce-motion setting, so
  /// somebody who has asked for no animation still gets the instant version.
  void _shiftYear(int delta) {
    final page = (_pageForYear(_year) + delta)
        .clamp(0, _lastYear - _firstYear);
    if (page == _pageForYear(_year)) return;
    _years.animateToPage(
      page,
      duration: Motion.duration(context),
      curve: Motion.curve,
    );
  }

  /// Room for the year grid, whatever the text size.
  ///
  /// Seven rows of squares at most 12 points each, the month labels above them,
  /// the legend below, and the one-line summary under that. Generous rather
  /// than exact: the grid is `mainAxisSize.min` inside this, so spare room is
  /// simply not used, whereas a pixel too few would clip the legend on the one
  /// phone nobody tested.
  double _yearHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(17) / 17;
    return 7 * 13 + 3 * 22 * scale + 40;
  }

  void _shiftMonth(int delta) => _goToMonth(
        DateTime(_month.year, _month.month + delta),
        animate: true,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final isThisMonth =
        _month.year == _today.year && _month.month == _today.month;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            //
            // The month name is no longer a doorway into a year grid. It is
            // just the month you are looking at; getting somewhere specific is
            // the button beside it, which opens the wheels. Two jobs, two
            // controls — see the long note on `DateWheel` for why one control
            // doing both was the thing that made this screen hard to use.
            Padding(
              // On the grid's optical rule, like every other row of icon
              // buttons in the app. ISSUE 1.
              padding: const EdgeInsets.fromLTRB(Layout.iconInset, Space.x4,
                  Layout.iconInset, Space.x2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _jumping
                        ? null
                        : () => _mode == _Mode.year
                            ? _shiftYear(-1)
                            : _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                    color: c.inkSecondary,
                    tooltip: _mode == _Mode.year
                        ? L.of(context).calendarPreviousYear
                        : L.of(context).calendarPreviousMonth,
                  ),
                  Expanded(
                    child: Text(
                      switch (_mode) {
                        _Mode.jumping => L.of(context).calendarGoToDate,
                        _Mode.year => '$_year',
                        _Mode.browsing =>
                          LampDates.monthAndYear(context, _month),
                      },
                      style: t.titleLarge,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _jumping
                        ? null
                        : () => _mode == _Mode.year
                            ? _shiftYear(1)
                            : _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                    color: c.inkSecondary,
                    tooltip: _mode == _Mode.year
                        ? L.of(context).calendarNextYear
                        : L.of(context).calendarNextMonth,
                  ),
                  // ── The year, and why it is a mode rather than a doorway ──
                  //
                  // The note above says the month name is no longer a doorway
                  // into a year grid, and that still holds: the thing that was
                  // removed was a year grid you had to pass *through* to reach
                  // a day, which made going somewhere specific five steps.
                  //
                  // This is the opposite. It is an overview you opt into and
                  // leave, it is on no path to anywhere, and the wheels beside
                  // it are still how you go to a date. Nothing has to travel
                  // through it. See `year_grid.dart` for what it is for.
                  IconButton(
                    onPressed: _jumping
                        ? null
                        : () => setState(() => _mode = _mode == _Mode.year
                            ? _Mode.browsing
                            : _Mode.year),
                    icon: Icon(_mode == _Mode.year
                        ? Icons.calendar_view_month
                        : Icons.grid_on),
                    color: _mode == _Mode.year ? c.accent : c.inkSecondary,
                    tooltip: _mode == _Mode.year
                        ? L.of(context).calendarBackToMonth
                        : L.of(context).calendarWholeYear,
                  ),
                  IconButton(
                    onPressed: () => setState(() =>
                        _mode = _jumping ? _Mode.browsing : _Mode.jumping),
                    icon: Icon(_jumping ? Icons.close : Icons.edit_calendar),
                    color: _jumping ? c.inkSecondary : c.accent,
                    tooltip: _jumping
                  ? L.of(context).calendarBackToBrowsing
                  : L.of(context).calendarGoToDate,
                  ),
                ],
              ),
            ),

            if (_mode == _Mode.year)
              // A fixed height for the same reason the month grid has one: a
              // `PageView` needs a bounded one, and years differ by a week
              // column, so letting them size themselves would make the sheet
              // breathe as you slid through them.
              SizedBox(
                height: _yearHeight(context),
                child: PageView.builder(
                  controller: _years,
                  itemCount: _lastYear - _firstYear + 1,
                  onPageChanged: (page) =>
                      setState(() => _year = _firstYear + page),
                  itemBuilder: (context, page) => _YearBody(
                    key: ValueKey(_firstYear + page),
                    repository: widget.repository,
                    year: _firstYear + page,
                    today: _today,
                    viewing: _viewing,
                    onPick: (date) => Navigator.of(context).pop(date),
                  ),
                ),
              )
            else if (_jumping)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.x2),
                child: DateWheel(
                  initial: _viewing,
                  earliest: _earliest,
                  onPicked: (date) => Navigator.of(context).pop(date),
                ),
              )
            else ...[
              // ── ISSUE 2b: the weekday letters and the dates are ONE grid ──
              //
              // "The month grid is crooked", with a sketch. It was, and the
              // reason was structural rather than a wrong number: the weekday
              // row laid out seven `Expanded` cells inside its own 16-point
              // padding, while the date grid computed its *own* margin from a
              // LayoutBuilder so that seven 48-point touch targets would fit.
              // Two independent geometries, so M never sat over the Mondays.
              //
              // `_GridMetrics` is worked out once, here, from the sheet's own
              // width, and both rows are handed the same numbers. Neither can
              // drift from the other because neither computes anything.
              LayoutBuilder(
                builder: (context, box) {
                  final metrics = _GridMetrics.forWidth(box.maxWidth);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WeekdayRow(
                          initials: LampDates.weekdayInitials(context),
                          metrics: metrics),
                      // A fixed height rather than Flexible, because a PageView
                      // needs a bounded one and because months are 4, 5 or 6
                      // weeks long — left to size themselves, the whole sheet
                      // would jump up and down as you swiped through the year.
                      SizedBox(
                        height: _gridHeight(context),
                        child: PageView.builder(
                          controller: _months,
                          onPageChanged: (page) =>
                              setState(() => _month = _monthForPage(page)),
                          itemBuilder: (context, page) => _MonthGrid(
                            key: ValueKey(page),
                            repository: widget.repository,
                            importer: widget.importer,
                            month: _monthForPage(page),
                            today: _today,
                            metrics: metrics,
                            viewing: DateTime(widget.initialDate.year,
                                widget.initialDate.month,
                                widget.initialDate.day),
                            onPick: (date) => Navigator.of(context).pop(date),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Always a way back to today, from any distance. Someone who has
              // travelled to 2019 should not have to count months home.
              TextButton(
                onPressed: isThisMonth
                    ? () => Navigator.of(context).pop(_today)
                    : () => _goToMonth(DateTime(_today.year, _today.month)),
                child: Text(
                  isThisMonth
                      ? L.of(context).calendarGoToToday
                      : L.of(context).calendarBackToThisMonth,
                  style: TextStyle(color: c.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The seven-column grid, computed once and shared. **ISSUE 2b.**
///
/// There is exactly one place in the app that decides where a calendar column
/// starts, and it is here. Anything that draws in that grid — the weekday
/// letters, the dates, and anything added later — is handed these numbers
/// rather than working out its own, which is the only arrangement in which two
/// rows cannot come out crooked.
class _GridMetrics {
  const _GridMetrics({required this.margin, required this.cell});

  /// The margin either side of the seven columns.
  final double margin;

  /// The width of one column.
  final double cell;

  static _GridMetrics forWidth(double width) {
    // `ACCESSIBILITY.md` asks for 48dp touch targets, and seven of them plus
    // the screen margin does not fit across a narrow phone. The margin gives
    // way first, because it is the thing that costs nothing — the target size
    // is the thing that costs someone with a tremor their tap.
    //
    // **ISSUE 6b — the grid fills the width now.** It used to clamp `usable` to
    // `Layout.maxContent` so the margin grew instead of the cells, keeping a
    // calendar cell the same size in the hand on a tablet as on a phone. That
    // is the decision reversed at the top of `tokens.dart`, and the calendar
    // has to follow it or it becomes the ninth screen with its own margin —
    // which is the actual complaint.
    //
    // The floor stays and is the part that matters: seven 48dp targets plus a
    // little air is what a month needs, and on a narrow phone the margin gives
    // way before the target does, because the margin costs nothing and the
    // target costs somebody with a tremor their tap.
    final wanted = 7 * kMinTouchTarget;
    final margin = math.max(Space.x2, (width - wanted) / 2);
    return _GridMetrics(margin: margin, cell: (width - margin * 2) / 7);
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.initials, required this.metrics});

  final _GridMetrics metrics;

  final List<String> initials;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return ExcludeSemantics(
      // Decorative to a screen reader: every cell below already announces its
      // own full date, so reading seven letters first is noise.
      child: Padding(
        // The grid's own margin, not a padding of its own. This is the whole
        // of ISSUE 2b: the letters and the dates are measured from the same
        // edge and cut into the same seven columns.
        padding: EdgeInsets.symmetric(
            horizontal: metrics.margin, vertical: Space.x2),
        child: Row(
          children: [
            for (final d in initials)
              SizedBox(
                width: metrics.cell,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(color: c.inkMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One month of squares. **The arrows used to jerk because of this class.**
///
/// ══ ISSUE 8 — "IT JERKS LIKE HELL" ════════════════════════════════════════
///
/// > *"When I use the arrows it jerks like hell! I feel like I have done
/// > something to piss off my phone."*
///
/// This was a `StatelessWidget` whose `build` handed `_MonthData.load(...)`
/// straight to a `FutureBuilder`'s `future:` — which means **a new database
/// query was started every time it rebuilt**, and a `FutureBuilder` handed a
/// new future throws away the snapshot it was showing and goes back to having
/// no data.
///
/// A rebuild happens on every `setState` in the sheet, and there is one on
/// every arrow tap and every page change. A `PageView` keeps three children
/// alive. So one tap of a chevron started **three** queries, and while they
/// were in flight all three months were drawn with no entry marks and no
/// photograph thumbnails — which then popped back in when the results landed.
/// Squares emptying and refilling under your thumb is precisely what "jerks"
/// describes, and it was invisible on a laptop because the answer came back
/// inside the same frame.
///
/// **It got worse on 25 August**, when the database moved off the UI isolate
/// and every query grew a round trip. That is the second time this round a fix
/// for slowness has made a correctness bug visible, and it is the same lesson:
/// work started during a build is a bug that hides behind a fast machine.
///
/// The load happens once per month now, in `initState` and on the one
/// `didUpdateWidget` that can change which month this is. Everything else —
/// including the parent rebuilding for its own reasons — redraws what is
/// already there.
class _MonthGrid extends StatefulWidget {
  const _MonthGrid({
    super.key,
    required this.repository,
    required this.importer,
    required this.month,
    required this.today,
    required this.viewing,
    required this.metrics,
    required this.onPick,
  });

  final EntryRepository repository;
  final AttachmentImporter importer;
  final DateTime month;
  final DateTime today;
  final DateTime viewing;

  /// The one grid. Handed down rather than computed — see [_GridMetrics].
  final _GridMetrics metrics;

  final ValueChanged<DateTime> onPick;

  @override
  State<_MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<_MonthGrid> {
  _MonthData _data = _MonthData.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_MonthGrid old) {
    super.didUpdateWidget(old);
    // The only thing that can make the answer different. Comparing the month
    // rather than reloading on every update is the entire point of the class
    // being stateful.
    if (old.month.year != widget.month.year ||
        old.month.month != widget.month.month) {
      _load();
    }
  }

  Future<void> _load() async {
    final month = widget.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final data = await _MonthData.load(
      widget.repository,
      EntryRepository.dayKeyFor(DateTime(month.year, month.month, 1)),
      EntryRepository.dayKeyFor(
          DateTime(month.year, month.month, daysInMonth)),
    );
    // Two guards, and both are needed. `mounted` because the sheet can be
    // closed while a query is in flight; the month check because a fast
    // swipe can start a second load before the first returns, and the older
    // answer arriving last would paint the wrong month's marks.
    if (!mounted ||
        widget.month.year != month.year ||
        widget.month.month != month.month) {
      return;
    }
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1, so the number of blanks before the 1st is weekday - 1.
    final leading = first.weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Builder(
      builder: (context) {
        final data = _data;
        final cell = widget.metrics.cell;
        return Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: widget.metrics.margin),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var row = 0; row < rows; row++)
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            SizedBox(
                              width: cell,
                              child: () {
                                final index = row * 7 + col;
                                final day = index - leading + 1;
                                if (day < 1 || day > daysInMonth) {
                                  return SizedBox(height: cell);
                                }
                                final date =
                                    DateTime(month.year, month.month, day);
                                final summary =
                                    data.days[EntryRepository.dayKeyFor(date)];
                                return _DayCell(
                                  date: date,
                                  size: cell,
                                  summary: summary,
                                  thumbnail: summary?.photoAttachmentId == null
                                      ? null
                                      : data
                                          .photos[summary!.photoAttachmentId],
                                  store: widget.importer.vault.attachments,
                                  isToday: date == widget.today,
                                  isViewing: date == widget.viewing,
                                  onTap: () => widget.onPick(date),
                                );
                              }(),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Everything one month's grid needs, in two queries rather than sixty.
///
/// A cell that loaded its own summary and its own thumbnail would be 31 × 2
/// database round trips per month, all of them starting on the frame the sheet
/// opens. Grouping them means a month costs one aggregate and one `IN (…)`.
class _MonthData {
  const _MonthData({required this.days, required this.photos});

  static const empty = _MonthData(days: {}, photos: {});

  final Map<String, DaySummary> days;
  final Map<String, Attachment> photos;

  static Future<_MonthData> load(
      EntryRepository repository, String from, String to) async {
    final days = await repository.summariesBetween(from, to);
    final ids = days.values
        .map((d) => d.photoAttachmentId)
        .whereType<String>()
        .toSet();
    final rows = await repository.attachmentsByIds(ids);

    // ── The small copy, where there is one ────────────────────────────────
    //
    // Thirty-one cells, each about 48 points, each previously decrypting a
    // whole photograph to fill one. `maxWidth: 128` below caps the *decode*
    // and the decrypt happens before it, so the cap never helped: opening a
    // month of holiday photographs meant pushing thirty-one multi-megabyte
    // files through libsodium before the sheet could settle.
    //
    // `photos` stays keyed by the id the summary names, and holds the
    // thumbnail row instead where one exists, so `_DayCell` is unchanged and
    // a photograph imported before thumbnails existed still draws.
    final thumbIds =
        rows.map((a) => a.thumbnailId).whereType<String>().toSet();
    final thumbs = thumbIds.isEmpty
        ? const <Attachment>[]
        : await repository.attachmentsByIds(thumbIds);
    final byId = {for (final a in thumbs) a.id: a};

    return _MonthData(
      days: days,
      photos: {
        for (final a in rows)
          a.id: (a.thumbnailId == null ? null : byId[a.thumbnailId!]) ?? a,
      },
    );
  }
}

/// One day, and it looks like itself.
///
/// ── WHY THE CELLS USED TO BE INTERCHANGEABLE ─────────────────────────────
///
/// Every day was a number and a density bar, so August looked exactly like
/// March and the only way to find anything was to already know the date.
/// `PLAN.md` §8.4 asked for three changes, and all three are here:
///
///   * **A photo day shows its photo**, dimmed, behind the number. This is the
///     highest-value change on the screen by a distance: a month with pictures
///     in it becomes navigable by memory rather than by arithmetic. You do not
///     read the grid, you recognise it.
///   * **Kind marks.** Up to three small shapes under the number — a *line*
///     for writing, a *dot* for voice, a *square* for a picture. Shapes, not
///     colours, so the information survives every form of colour blindness and
///     a sunlit screen.
///   * **Weekends recede.** Slightly muted, so the week's rhythm is visible
///     without anything being drawn to say so.
///
/// Today keeps its ring, unchanged, because it was already right.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.size,
    required this.summary,
    required this.thumbnail,
    required this.store,
    required this.isToday,
    required this.isViewing,
    required this.onTap,
  });

  final DateTime date;
  final double size;
  final DaySummary? summary;
  final Attachment? thumbnail;
  final AttachmentStore store;
  final bool isToday;
  final bool isViewing;
  final VoidCallback onTap;

  int get count => summary?.count ?? 0;

  /// Entry count → a step on the ramp.
  ///
  /// Six buckets for an unbounded number, weighted towards the low end because
  /// that is where journalling actually lives: the difference between one entry
  /// and three is a real difference in a day, and the difference between eleven
  /// and fourteen is not.
  static int levelFor(int n) {
    if (n <= 0) return 0;
    if (n == 1) return 1;
    if (n == 2) return 2;
    if (n <= 4) return 3;
    if (n <= 7) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final level = levelFor(count);
    final has = level > 0;
    final s = summary;
    final weekend = date.weekday >= DateTime.saturday;
    // `PLAN.md` §8.4. One flag on the whole day — `summariesBetween` takes
    // `MAX(e.marker)`, so a day is marked when anything on it is.
    final marked = (s?.marker ?? '').isNotEmpty;
    final photo = thumbnail;

    return Semantics(
      button: true,
      selected: isViewing,
      // The whole sentence, the way DESIGN-SYSTEM.md writes it: "16 March
      // 2006, 3 entries, a photo and a voice note". A screen-reader user gets
      // more than a sighted one here, not less — the shapes are a summary of
      // this sentence, and the sentence is the original.
      label: '${LampDates.dayMonthYear(context, date)}, '
          '${s == null ? L.of(context).calendarNothingOnDay : s.describeIn(L.of(context))}'
          // The third channel, and the one that matters most: a screen-reader
          // user gets the whole sentence rather than a colour they cannot see
          // and a weight they cannot hear.
          '${marked ? ', marked' : ''}'
          '${isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        // A minimum, not a fixed height. At 200% text the day number alone is
        // taller than a 48dp cell, and a fixed height would clip it — the one
        // person guaranteed to be reading at 200% is the one who cannot read it
        // clipped. The grid scrolls, so a taller row costs nothing.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size),
          child: Container(
            margin: const EdgeInsets.all(2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // The day you came from, so the sheet says where you are.
              color: isViewing ? c.raised : null,
              borderRadius: BorderRadius.circular(Radii.sm),
              // Today is a ring, not a fill — a fill would compete with the
              // selection, and there can only be one loudest thing.
              border: isToday ? Border.all(color: c.accent, width: 1.5) : null,
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // ── The photograph, if the day has one ──────────────────
                //
                // Heavily dimmed and behind everything. It is a *hint* of
                // what happened, not a picture: the number on top has to stay
                // at full contrast, and a bright thumbnail would eat it.
                // 0.30 is the most it can carry and still leave the digit
                // comfortably past 4.5:1 on both palettes.
                if (photo != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.30,
                      child: Image(
                        image: EncryptedImage(
                          photo,
                          store: store,
                          // A calendar cell is about 48 points. Decoding more
                          // than 128 real pixels for it is work nobody can see
                          // — and there are thirty-one of them on screen.
                          maxWidth: 128,
                        ),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        // A cell that cannot load its picture is just a cell.
                        // Never an error glyph: the day is still perfectly
                        // usable and a broken-image icon in a calendar reads
                        // as "something is wrong with your journal".
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── A day that mattered. `PLAN.md` §8.4 ──────────────
                    //
                    // > *Mood/marker, if built, tints the number itself.*
                    //
                    // It is built, and it is **one flag** rather than the mood
                    // scale §9.3 originally described — `marker` means *"this
                    // one mattered"* and `marker_test.dart` fails if anybody
                    // makes it a set. So there is one thing to show, not five
                    // shades, and a tint is enough.
                    //
                    // **Two channels, not one.** The accent carries it and so
                    // does the weight, because `DESIGN-SYSTEM.md` does not
                    // allow colour to be the only signal — the kind marks under
                    // the number already obey that with shape, and a marker
                    // that was hue alone would be the one thing on this grid a
                    // colour-blind reader could not see.
                    //
                    // Not a fill and not a ring: the fill is where-you-came-from
                    // and the ring is today, and there can only be one loudest
                    // thing.
                    Text(
                      '${date.day}',
                      style: t.bodyLarge?.copyWith(
                        color: marked
                            ? c.accent
                            : (has
                                ? c.inkPrimary
                                : (weekend
                                    ? c.inkMuted.withValues(alpha: 0.65)
                                    : c.inkMuted)),
                        fontWeight: isToday || marked
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 5,
                      width: size * 0.62,
                      child: s == null
                          ? null
                          : _KindMarks(summary: s, level: level),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to three shapes saying what kind of day it was.
///
/// **Shape, not colour.** A line is writing, a dot is a voice note, a square
/// is a picture. Somebody with no colour vision reads this grid exactly as
/// well as anybody else, which is the rule `DESIGN-SYSTEM.md` states and this
/// is the cheapest possible way to obey it.
///
/// The line's *width* also carries how much was written, which is the old
/// density bar folded into the same mark rather than added beside it.
class _KindMarks extends StatelessWidget {
  const _KindMarks({required this.summary, required this.level});

  final DaySummary summary;
  final int level;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final colour = c.gridRamp[level.clamp(1, c.gridRamp.length - 1)];
    final marks = <Widget>[
      if (summary.hasText)
        // A line. Longer for a fuller day.
        Container(
          width: 5.0 + 2.0 * level,
          height: 2.5,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      if (summary.hasVoice)
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
      if (summary.hasPhoto || summary.hasVideo)
        Container(width: 4, height: 4, color: colour),
      if (summary.hasFile && !summary.hasPhoto && !summary.hasVideo)
        Transform.rotate(
          angle: 0.785, // 45°, so a file reads as a diamond
          child: Container(width: 3.4, height: 3.4, color: colour),
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < marks.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          marks[i],
        ],
      ],
    );
  }
}


/// What the sheet is showing.
///
/// Three modes rather than three screens. Browsing a month, going to a date,
/// and looking at a year are different intentions with different controls —
/// but they are all "where in my own past am I", and pushing a route for each
/// would put a back stack between a person and their own calendar.
enum _Mode { browsing, jumping, year }

/// The year grid, plus the one query that feeds it.
///
/// Its own widget so the counts load when the year is shown and reload when it
/// changes, rather than the sheet holding a cache it has to remember to
/// invalidate. Keyed on the year, so switching years rebuilds rather than
/// showing the previous year's shape under a new heading — which would be a
/// quiet lie for as long as the query took.
class _YearBody extends StatefulWidget {
  const _YearBody({
    super.key,
    required this.repository,
    required this.year,
    required this.today,
    required this.viewing,
    required this.onPick,
  });

  final EntryRepository repository;
  final int year;
  final DateTime today;
  final DateTime viewing;
  final ValueChanged<DateTime> onPick;

  @override
  State<_YearBody> createState() => _YearBodyState();
}

class _YearBodyState extends State<_YearBody> {
  Map<String, int>? _counts;

  @override
  void initState() {
    super.initState();
    // One query for 365 days. `countsBetween` groups in SQL, so this is a
    // single round trip rather than the twelve the month grid would make.
    widget.repository
        .countsBetween('${widget.year}-01-01', '${widget.year}-12-31')
        .then((counts) {
      if (mounted) setState(() => _counts = counts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final counts = _counts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x5, Space.x2, Space.x5, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The grid is drawn even before the counts arrive, in the empty
          // colour. The shape appearing under a grid that is already there
          // reads as loading; a spinner replaced by a grid reads as a jump.
          YearGrid(
            year: widget.year,
            counts: counts ?? const {},
            today: widget.today,
            viewing: widget.viewing,
            onPick: widget.onPick,
          ),
          const SizedBox(height: Space.x3),
          if (counts != null)
            Text(
              _summary(context, counts),
              style: t.labelMedium?.copyWith(color: c.inkSecondary),
            ),
          const SizedBox(height: Space.x2),
        ],
      ),
    );
  }

  /// What the year held, in one line.
  ///
  /// Days *with* something and entries written — never days missed, never a
  /// percentage, never a comparison with last year. PLAN.md §10 rules out
  /// every count that shames, and "you wrote on 84 days" and "you missed 281"
  /// are the same number wearing different clothes.
  String _summary(BuildContext context, Map<String, int> counts) {
    final l = L.of(context);
    if (counts.isEmpty) return l.calendarNothingThisYear;
    final days = counts.length;
    final entries = counts.values.fold<int>(0, (a, b) => a + b);
    return l.calendarYearSummary(
        l.countEntries(entries), l.countDays(days));
  }
}
