import 'package:flutter/material.dart';

import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../design/lamp_mark.dart';
import '../../design/tokens.dart';

/// The top of the day view: whose page this is, which day, and the way out.
///
/// ── TWO REAL BUGS LIVED HERE, AND THEY WERE BOTH MINE ────────────────────
///
/// **1. The date broke in the middle of a word.**
///
/// ```
///  30              1 Sept
///  Augus           ember
///  t
/// ```
///
/// Reported, fairly, as *"isn't this hectic? it seems so so so bad"*. It was.
/// The cause: the date sat in an `Expanded` in a `Row` alongside four 48dp
/// icon buttons. On a 390dp phone that leaves the date about 150 points, and
/// "1 September" at 32px needs closer to 200 — so Flutter did the only thing
/// it can when a single word is wider than its line, and broke the word.
///
/// The fix has two halves and needs both:
///
///   * **The date gets its own line.** Nothing competes with it for width. It
///     is the title of the page, and a title that shares a row with a toolbar
///     was the underlying mistake.
///   * **`softWrap: false` inside a scale-down `FittedBox`.** So even at 200%
///     text on a 320dp phone, where a full line is still not enough, the date
///     *shrinks* rather than breaking. A word never splits, at any size, on
///     any phone. That is a guarantee rather than a wide-enough guess.
///
/// Shrinking text is normally the wrong answer to an accessibility constraint
/// and it is the right one here: this is one short decorative-scale heading
/// whose content is repeated verbatim, unshrunk, in the screen-reader label
/// and in the row beneath it. Nobody loses information. What they gain is a
/// date that reads as a date.
///
/// **2. Nobody could find Settings.**
///
/// The app's mark was the way in. It looked good and it was invisible as a
/// control — *"idk it looks good but nobody can say how to reach setting? New
/// person would be confused"*, which is precisely right and is Norman's
/// affordance problem in one sentence. A logo is a badge; badges are not
/// buttons, and people have thirty years of training that says so.
///
/// So the mark went back to being a mark — it sits at the left, saying which
/// app this is and doing nothing — and Settings is a **gear**. Not a novel
/// choice and that is the entire point: the gear is the single most learned
/// symbol in software, and being recognisable beats being interesting for the
/// control that leads to everything a person cannot otherwise find.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.date,
    required this.isToday,
    this.goingForward = true,
    required this.greetingName,
    required this.onPickDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSearch,
    required this.onSettings,
    this.dayLine,
  });

  /// The one line that names this day — `day_line.dart`, `PLAN.md` §7.0-E.
  ///
  /// Passed in rather than built here, because it needs two repositories and
  /// this widget is deliberately presentational: everything above is a
  /// function of its arguments, which is why the header can be tested at
  /// fourteen window sizes without a vault. It draws itself as nothing at all
  /// on a day with no line and no reason to offer one, so on most days this
  /// row costs a `SizedBox.shrink`.
  final Widget? dayLine;

  final DateTime date;
  final bool isToday;

  /// Which way the day just moved, so the date can slide the same way.
  ///
  /// True when the last change went forwards in time. Null-safe default of
  /// true on first build, where there is nothing to animate from anyway.
  final bool goingForward;

  /// What to call them, if they said. Empty means they did not, and the
  /// greeting is simply left out — never "Hello, there".
  final String greetingName;

  final VoidCallback onPickDate;
  final VoidCallback onPrevious;

  /// Null on today, because there is no tomorrow to write on.
  final VoidCallback? onNext;

  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final showYear = date.year != DateTime.now().year;
    // The words and the order both come from `intl` now — see
    // `l10n/dates.dart` for why a translated month name glued to
    // '\${date.day} \$month' is still wrong in half these languages.

    return Padding(
      // ISSUE 1. Left was 24 and right was 8, so the date started on one rule
      // and the search, gear and ‹ › glyphs ended on another twelve points
      // outside it — which is why the chevrons read as floating in the middle
      // of nothing rather than as being pinned to an edge. `Layout.iconInset`
      // is the optical correction that puts a 24-point glyph inside a 48-point
      // tap target onto the same rule as the text. See tokens.dart.
      padding: const EdgeInsets.fromLTRB(
          Layout.gutter, Space.x2, Layout.iconInset, Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row one: the app, and the two ways out of the day ───────────
          SizedBox(
            height: kMinTouchTarget,
            child: Row(
              children: [
                // The mark. A mark, not a button — see the class comment.
                Semantics(
                  label: L.of(context).appName,
                  child: const ExcludeSemantics(child: LampMark(size: 24)),
                ),
                // ── ISSUE 9 / "why are they not on the right?" ──────────
                //
                // This was `Flexible(greeting)` followed by `Spacer()`, and
                // that pairing is the whole bug. Both are flex-1 children, so
                // the Row splits the free space evenly between them — but
                // `Flexible` is a *loose* fit, so the greeting takes only the
                // width of the word "Piyush" and hands the rest back. A Row
                // with leftover space and the default `MainAxisAlignment.start`
                // parks that leftover at the **end**, which is to say in a hole
                // between the gear and the right margin.
                //
                // Measured on a 360-point phone: the gear stopped 19.7 points
                // short of the rule, and the ‹ › chevrons in the third row —
                // where the label is shorter, so the hand-back is bigger —
                // stopped **50.4 points short**. Two different holes, from one
                // mistake, which is why it read as arbitrary rather than as
                // wrong: nothing was aligned to anything.
                //
                // One `Expanded` does the whole job. It is a tight fit, so it
                // consumes every point that is not an icon, and the icons have
                // nowhere to be but hard against the margin.
                Expanded(
                  child: greetingName.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: Space.x3),
                          child: Text(
                            // No exclamation mark, no "Welcome back". It is a
                            // name, said once, the way a room greets you by
                            // being yours.
                            greetingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelSmall?.copyWith(color: c.inkMuted),
                          ),
                        ),
                ),
                IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                  color: c.inkSecondary,
                  tooltip: L.of(context).daySearch,
                ),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                  color: c.inkSecondary,
                  tooltip: L.of(context).daySettings,
                ),
              ],
            ),
          ),

          // ── Row two: the date, on its own line, unbreakable ─────────────
          Semantics(
            button: true,
            label: '${LampDates.full(context, date)}'
                '${isToday ? ', ${L.of(context).dayToday.toLowerCase()}' : ''}'
                '. ${L.of(context).dayChooseDate}',
            excludeSemantics: true,
            // ══ ROUND EIGHT, ISSUE 8 — THE CHEVRON COMES BACK TO THE DATE ══
            //
            // *"Calendar alignment little smallest issue."* The drawing is the
            // whole report: a box round **26 August** at the far left, a box
            // round the ˅ at the far right, one arrow between them, and
            // *"I want them close"* — with **MAIN ISSUE** written underneath.
            //
            // It was an `Expanded`, which is `Flexible(fit: tight)`: the date
            // was forced to consume every point of the row that was not the
            // chevron, so the chevron had nowhere to be except hard against
            // the right margin — about 250 points away from the word it
            // belongs to on his tablet. Two controls that are one control.
            //
            // The irony is that `Expanded` is here *because* of round six,
            // where `Flexible` beside a `Spacer` left holes of 19.7 and 50.4
            // points in the rows above and below this one. That fix was right
            // for a **toolbar**, where the icons belong to the margin. It is
            // wrong for a **label and its own affordance**, which belong to
            // each other. Both rules are in this file now and they do not
            // conflict: pin to the margin what the margin owns, and keep
            // together what reads as one thing.
            //
            // So: a loose `Flexible`, a `MainAxisSize.min` row, and the whole
            // thing pushed to the left rule by an `Align`. The date takes the
            // width of the date, the chevron sits four points after the last
            // letter of it, and the tap target is now the size of the thing
            // it appears to be rather than a full-width invisible strip.
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, Space.x1, Space.x2, Space.x1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        // ── The date moves when the day does ──────────────
                        //
                        // The header is fixed now, which fixed the "the bottom
                        // menu gets swiped too" complaint and introduced a
                        // smaller one: swiping the day made the date *pop* to
                        // a new value, with no relationship to the direction
                        // of the gesture. A static label under a sliding page
                        // is exactly the kind of thing that makes an interface
                        // feel like a set of parts rather than one object.
                        //
                        // So it slides the way the page slid — forward in time
                        // enters from the right, backward from the left — and
                        // fades across. Sixteen points of travel, which is
                        // enough to read as motion and short enough that a
                        // fast swipe through a week does not become a queue of
                        // animations.
                        child: AnimatedSwitcher(
                          duration: Motion.duration(context),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          // ── ISSUE 8: the outgoing date does not vote ────
                          //
                          // Now that the chevron sits immediately after the
                          // last letter, the width of this box is a *position*
                          // rather than a detail — and the default layout puts
                          // both dates in an unpositioned `Stack`, which takes
                          // the width of the **wider** of the two. Swiping
                          // from "5 May" to "26 September" would therefore
                          // shove the chevron out for 260 ms and snap it back
                          // at the end of the animation: a twitch on every
                          // single day change, introduced by the fix for the
                          // complaint about where the chevron sits.
                          //
                          // `Positioned` children do not contribute to a
                          // `Stack`'s size, so the box is the width of the
                          // date **arriving** and the chevron goes straight to
                          // where it will stay. The date that is leaving keeps
                          // its own natural width and fades out in place, on
                          // the left, where it already was.
                          //
                          // Nothing overlaps: `easeOutCubic` has spent 87% of
                          // its travel by the halfway point, so by the time
                          // the incoming date is opaque enough to read, it is
                          // within about two points of home.
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.none,
                            children: [
                              for (final child in previous)
                                Positioned(
                                    left: 0, top: 0, bottom: 0, child: child),
                              ?current,
                            ],
                          ),
                          transitionBuilder: (child, animation) {
                            final entering =
                                animation.status != AnimationStatus.reverse;
                            final from = (goingForward ? 1.0 : -1.0) *
                                (entering ? 1 : -1);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0.12 * from, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: FittedBox(
                            // Keyed on the date, so the switcher knows a new
                            // day has arrived rather than the same one
                            // rebuilding.
                            key: ValueKey(date.toIso8601String()),
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              showYear
                                  ? LampDates.dayMonthYear(context, date)
                                  : LampDates.dayAndMonth(context, date),
                              // The two lines that make the broken-word bug
                              // impossible rather than unlikely.
                              maxLines: 1,
                              softWrap: false,
                              style: t.displaySmall,
                            ),
                          ),
                        ),
                      ),
                      // Four points, not eight. This is the gap between a word
                      // and its own punctuation, which is what the chevron now
                      // is — the join that makes them read as one control
                      // rather than as two things that happen to be near each
                      // other.
                      const SizedBox(width: Space.x1),
                      Icon(Icons.expand_more, size: 20, color: c.inkMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Row three: which day of the week, and how to move ───────────
          Row(
            children: [
              // `Expanded`, not `Flexible` + `Spacer` — see row one. This is
              // the row where the old pairing left the widest hole, because
              // "TODAY" is short and handed back the most.
              Expanded(
                child: Text(
                  isToday
                      ? L.of(context).dayToday
                      : LampDates.weekdayName(context, date).toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(
                    // Today is accent AND bolder AND labelled — three
                    // channels, never colour alone.
                    color: isToday ? c.accent : c.inkMuted,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              // Button equivalents for the swipe. `ACCESSIBILITY.md` forbids a
              // gesture being the only way to do anything, and someone with a
              // tremor cannot reliably swipe.
              _Chevron(
                icon: Icons.chevron_left,
                label: L.of(context).dayPrevious,
                onTap: onPrevious,
              ),
              _Chevron(
                icon: Icons.chevron_right,
                label: L.of(context).dayNext,
                onTap: onNext,
              ),
            ],
          ),

          // ── Row four: what this day was ─────────────────────────────────
          //
          // Below the navigation rather than above it, and that ordering is
          // the argument. Rows two and three are one cluster — the date, the
          // chevron that changes it, and the two arrows that step it — and
          // pushing a line of the user's own writing into the middle of that
          // would split a control across a sentence.
          //
          // So it sits at the bottom of the header, immediately above the
          // day's contents, which is where a title belongs relative to the
          // thing it titles. On the overwhelming majority of days it is a
          // `SizedBox.shrink` and this row does not exist.
          ?dayLine,
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            // 40 visually, 48 as a target — the icons sit close together and
            // two 48dp circles side by side read as a segmented control rather
            // than as two arrows.
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? c.inkMuted.withValues(alpha: 0.4) : c.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
