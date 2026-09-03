import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';
import 'package:flutter/services.dart';

import '../../design/components.dart';
import '../../design/tokens.dart';

/// Getting to a date, directly.
///
/// ── THE PROBLEM THIS EXISTS TO SOLVE ─────────────────────────────────────
///
/// Reported as: *"imagine I want to go to 16 March 2006 through the calendar
/// view — I am unable to. And have you seen how bad that design is? When
/// someone wants to go to a particular date it's the worst-feeling part."*
///
/// All of it fair. The old path was: tap the month name, get a grid of years,
/// scroll it, tap 2006, get a grid of months, tap March, land on the month
/// grid, then tap 16. **Five interactions across three different screens**, in
/// a sheet that changed shape twice on the way, for something a person had
/// already decided before they opened it. Somebody who knows the date they want
/// is not browsing. They are *going somewhere*, and browsing controls are the
/// wrong tool for going somewhere.
///
/// ── WHY THREE WHEELS ─────────────────────────────────────────────────────
///
/// Because a date is three numbers, and a wheel is the one control that makes
/// a long ordered list of numbers reachable in a flick. It is what every phone
/// on earth uses for exactly this, on the alarm clock and the date field, so
/// there is nothing to learn — and 2006 is two flicks of the year wheel rather
/// than a scroll, a tap, a screen change and a hunt.
///
/// The grid stays. It is genuinely better for *browsing* — for "sometime around
/// last March" — and this sits above it rather than replacing it. Two tools,
/// each doing the thing it is good at, which is what the old design got wrong
/// by making one control do both jobs badly.
///
/// ── THE DATE IS ALWAYS LEGAL ─────────────────────────────────────────────
///
/// The day wheel shrinks and grows with the month, so 31 February cannot be
/// selected at all. Landing on a day the user did not choose — which is what
/// clamping silently would do — is worse than not offering it.
class DateWheel extends StatefulWidget {
  const DateWheel({
    super.key,
    required this.initial,
    required this.earliest,
    required this.onPicked,
  });

  final DateTime initial;

  /// The oldest day the vault has anything on, if it has anything.
  ///
  /// **It no longer bounds the wheel — see [_DateWheelState.firstYear].** It is
  /// a shortcut now: one tap to the beginning of the journal, which is the
  /// other date besides today that anybody actually jumps to.
  final DateTime? earliest;

  final ValueChanged<DateTime> onPicked;

  @override
  State<DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<DateWheel> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;

  // Clamped, because the wheel cannot show a year it does not have a row for
  // and an out-of-range initial value would otherwise open the wheel scrolled
  // to nowhere. Nothing in the app can produce one today; this is the guard
  // that keeps that true.
  late int _year = widget.initial.year.clamp(firstYear, lastYear);

  /// **ISSUE 2a: the calendar could not reach a real date.**
  ///
  /// The range used to be computed — today minus ten years through today plus
  /// one — which in August 2026 meant **1900 was unreachable and so was 2016**.
  /// An eight-year window, in a journal built to hold a life. Somebody born in
  /// 1998 could not record the day they were born, and the entry in `PLAN.md`
  /// that recorded the date picker as "fixed" had been written by somebody who
  /// never widened the range. That is §11 test 7 failing in the plainest
  /// possible way: the reported case was fixed and the class was left open.
  ///
  /// 1900 to 2100, as instructed. Two hundred and one rows, which is what
  /// every phone's own date picker offers and for the same reason: the wheel
  /// is lazy, so the count costs nothing to draw, and the two dates anybody
  /// travels to in one movement — today, and the first thing in the journal —
  /// are one tap each underneath. A wheel is for the year you have in mind; a
  /// shortcut is for the year you would otherwise have to hunt for.
  static const int firstYear = 1900;
  static const int lastYear = 2100;

  late final FixedExtentScrollController _dayWheel =
      FixedExtentScrollController(initialItem: _day - 1);
  late final FixedExtentScrollController _monthWheel =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _yearWheel =
      FixedExtentScrollController(initialItem: _year - firstYear);

  @override
  void dispose() {
    _dayWheel.dispose();
    _monthWheel.dispose();
    _yearWheel.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  DateTime get _todayDate {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Spin all three wheels to [date] rather than jumping the value under them.
  ///
  /// Animated on purpose. A wheel that changed its number without moving would
  /// read as a glitch; watching it travel is what tells you the shortcut did
  /// the same thing your thumb would have done, only faster.
  void _goTo(DateTime date) {
    final year = date.year.clamp(firstYear, lastYear);
    setState(() {
      _year = year;
      _month = date.month;
      _day = date.day.clamp(1, DateTime(year, date.month + 1, 0).day);
    });
    const motion = Duration(milliseconds: 260);
    _yearWheel.animateToItem(_year - firstYear,
        duration: motion, curve: Curves.easeOut);
    _monthWheel.animateToItem(_month - 1,
        duration: motion, curve: Curves.easeOut);
    _dayWheel.animateToItem(_day - 1,
        duration: motion, curve: Curves.easeOut);
  }

  void _settle() {
    // February shortened under a day that no longer exists. Pull the wheel
    // back rather than letting the value be illegal — and animate it, so the
    // user sees why the number changed instead of finding a different date
    // than the one they left.
    if (_day > _daysInMonth) {
      _day = _daysInMonth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayWheel.hasClients) {
          _dayWheel.animateToItem(
            _day - 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final chosen = DateTime(_year, _month, _day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // What is actually selected, at heading size, above the wheels. A
        // wheel picker without this reads as three unrelated dials — the
        // sentence is what turns them into one date.
        Padding(
          padding: const EdgeInsets.only(bottom: Space.x2),
          child: Text(
            LampDates.dayMonthYear(context, DateTime(_year, _month, _day)),
            style: t.displaySmall,
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(
          height: 168,
          child: Stack(
            children: [
              // The selection band, drawn once behind all three wheels so it
              // reads as one row across the whole control rather than three
              // separate highlights.
              Center(
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: Space.x4),
                  decoration: BoxDecoration(
                    color: c.raised,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Wheel(
                      controller: _dayWheel,
                      count: _daysInMonth,
                      label: (i) => '${i + 1}',
                      semantic: (i) => 'Day ${i + 1}',
                      onChanged: (i) {
                        _day = i + 1;
                        _settle();
                      },
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Wheel(
                      controller: _monthWheel,
                      count: 12,
                      label: (i) => LampDates.monthName(context, i + 1),
                      semantic: (i) => LampDates.monthName(context, i + 1),
                      onChanged: (i) {
                        _month = i + 1;
                        _settle();
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _Wheel(
                      controller: _yearWheel,
                      count: lastYear - firstYear + 1,
                      label: (i) => '${firstYear + i}',
                      semantic: (i) =>
                          L.of(context).wheelYear('${firstYear + i}'),
                      onChanged: (i) {
                        _year = firstYear + i;
                        _settle();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── The two years nobody should have to scroll to ────────────────
        //
        // Two hundred years is the right *range* and it is not by itself a way
        // of getting anywhere. These are: today, always; and the first day the
        // journal has anything on, when there is one and it is not already
        // where the wheels are pointing. Between them they cover almost every
        // real journey, and the wheel covers the rest.
        Padding(
          padding: const EdgeInsets.only(top: Space.x2),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.x2,
            children: [
              _Shortcut(
                label: L.of(context).calendarToday,
                onTap: () => _goTo(_todayDate)),
              // ── ISSUE 8. "First entry, 2026" made no sense ──────────────
              //
              // > *"What does it means? The user's first entry is 2026? If
              // > user's first entry is on 2027 then will the option change? Or
              // > what can be a better option instead of that option?"*
              //
              // Three questions and the third one is the answer to the other
              // two. Yes, the year changed — it was read from the vault, so it
              // was already whatever his oldest day happened to be. That was
              // never the problem. **The problem is that the chip named a year
              // instead of saying what tapping it does**, so the only way to
              // find out was to tap it and see where you ended up, and a year
              // on its own beside a button marked "Today" reads like a piece of
              // information rather than a place to go.
              //
              // So it says where it goes, and the date it names is the whole
              // date rather than the year — which is also more useful, because
              // "your first entry" is a day you may not remember and would
              // quite like to be told.
              //
              // **And it is gone when there is nothing to go back to.** The old
              // condition hid it when the wheels were already pointing at that
              // year, which is a different question and the wrong one: it meant
              // somebody on their first day of using the app was offered a
              // shortcut to today, labelled as something else.
              if (widget.earliest != null && widget.earliest != _todayDate)
                _Shortcut(
                  label: L.of(context).calendarFirstEntry,
                  note: '${widget.earliest!.day} '
                      '${LampDates.monthName(context, widget.earliest!.month)} '
                      '${widget.earliest!.year}',
                  onTap: () => _goTo(widget.earliest!),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
              Layout.gutter, Space.x4, Layout.gutter, Space.x2),
          child: LampButton(
            label: L.of(context).calendarGoToThisDay,
            onPressed: () => widget.onPicked(chosen),
          ),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.semantic,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final String Function(int) semantic;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 42,
      // A gentle curve rather than a drum. `diameterRatio` this high keeps the
      // rows nearly flat, so the numbers stay legible at the edges instead of
      // being squashed into an ellipse — which is where wheel pickers usually
      // fail an accessibility check.
      diameterRatio: 2.6,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 0.45,
      onSelectedItemChanged: (i) {
        onChanged(i);
        // The click a physical wheel makes. Cheap, and it is most of why a
        // wheel feels like a wheel rather than like a list.
        HapticFeedback.selectionClick();
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, i) => Semantics(
          label: semantic(i),
          excludeSemantics: true,
          child: Center(
            child: Text(
              label(i),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleLarge?.copyWith(
                color: c.inkPrimary,
                // Tabular figures, or the day and year columns jitter sideways
                // as they spin past.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two year shortcuts under the wheels.
///
/// A chip rather than a button, because it is a place to go rather than a thing
/// to confirm — and the one filled button on this sheet is already the confirm.
class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.label, this.note, required this.onTap});

  final String label;

  /// The date this goes to, under the label. **ISSUE 8.**
  ///
  /// The label says what tapping does and this says where it lands. Two lines
  /// rather than one long one, because "Your first entry, 3 March 2026" on a
  /// chip beside "Today" is a sentence where the other one is a word.
  final String? note;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      // Read as one thing. A screen reader announcing "Your first entry" and
      // then "3 March 2026" as two separate labels leaves the listener to
      // work out that they belong together.
      label: note == null ? label : '$label, $note',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          // The tap target is the floor even though the chip draws smaller —
          // ACCESSIBILITY.md is about the hit area, not the paint.
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: t.labelMedium?.copyWith(color: c.accent),
              ),
              if (note != null)
                Text(
                  note!,
                  style: t.labelSmall?.copyWith(color: c.inkMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
