import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// A day with nothing on it yet. **ISSUE 3.**
///
/// ── THE REPORT ────────────────────────────────────────────────────────────
///
/// *"The empty day is a void, not a surface."* In both palettes. He granted
/// that it was "aesthetic, simplicity" and said plainly that aesthetic is not
/// enough: every messaging app puts **something** behind the conversation, and
/// this put nothing behind anything.
///
/// He was right, and the old build was one line of muted text floating in the
/// middle of a near-black rectangle. There was no way to tell it from a screen
/// that had failed to load.
///
/// ── WHY THIS IS A PAGE AND NOT A WALLPAPER ────────────────────────────────
///
/// WhatsApp's wallpaper works because a bubble needs something to sit *on*.
/// Lamplight's entries deliberately sit **on the page** rather than in bubbles,
/// so a busy wallpaper would fight the type — `PLAN.md` §8.3 argues this out
/// and settles on a surface rather than a picture.
///
/// So an empty day is drawn as what it actually is: **a sheet of paper with the
/// date already written at the top and the first line waiting.** Ruled, in the
/// hairline that is decorative everywhere else in this app, so the eye reads
/// *somewhere to write* rather than *nothing here*.
///
/// ── THE PSYCHOLOGY, AND WHY IT IS THE HONEST KIND ─────────────────────────
///
/// `PLAN.md` §3 names two mechanisms and both are used here, deliberately:
///
///   * **Endowed progress** — people finish a card that already has two stamps
///     on it far more often than an empty one. The page is not blank when you
///     arrive; the date is already on it. Somebody else has started it for you.
///   * **The Zeigarnik effect** — an unfinished thing occupies the mind. A
///     ruled line with nothing on it is an unfinished thing.
///
/// Neither of them manufactures guilt, which is the line `ETHICAL-DESIGN.md`
/// draws. There is no count, no streak, no "you haven't written today". The
/// page simply looks like a page, and a page that looks like a page invites
/// writing the way a blank void does not. It passes §11 test 2: **glad, not
/// anxious.**
///
/// ── PAST DAYS ARE DIFFERENT, ON PURPOSE ───────────────────────────────────
///
/// A day in the past that is empty is not an invitation, it is a fact. It gets
/// the same sheet — so the app looks like itself everywhere — with a quieter
/// sentence and no ruling, because there is nothing to start.
///
/// ══ ROUND FIVE, ISSUE 9 — WHAT CHANGED AND WHY ═══════════════════════════
///
/// *"Static boxes which does nothing. I want them to be wired up to be able to
/// write."* And, with no softening: *"Also the static boxes ideas are worst.
/// Redesign, make them better."*
///
/// Both halves were fair, and the first is the serious one. This sheet is drawn
/// to look like somewhere to write — that is the whole argument above, endowed
/// progress and all — and then it did not accept writing. An interface that
/// invites a tap and ignores it is worse than one that never invited it,
/// because the user concludes the app is broken rather than that they aimed
/// wrong. **It is the composer's target now**: tapping it puts the caret on the
/// page, which is what it always looked like it would do.
///
/// The redesign, item by item:
///
///   * **The second date is gone.** He circled both and wrote *"why two date on
///     one page"* and *"why another date?"*. The header already says the date,
///     in the largest type on the screen, six millimetres above this. Repeating
///     it was the endowed-progress stamp, and the idea does not survive the
///     header being right there — it read as a duplicate, not as a head start.
///   * **The ruled lines are gone.** Three hairlines said "this is where
///     writing goes" when writing went somewhere else entirely. Now that the
///     caret genuinely lands here, drawing fake lines under a real one is
///     saying it twice.
///   * **The sentence carries it.** On today it is an invitation and it is
///     tappable; on any other day it is a plain statement of fact, with no tap,
///     because there is nothing to start on a day that is over.
///
/// ══ THE FIRST MINUTE. `Honest Review`: "a real empty state for a brand-new
/// vault" ═══════════════════════════════════════════════════════════════════
///
/// There is a third case and it was being drawn as the first. Somebody who has
/// just made a vault — who has chosen a passcode, written down twelve words,
/// and arrived — was shown *"Anything you want to keep?"* and nothing else. It
/// is a perfectly good sentence for a quiet Tuesday in the third year. It is
/// the wrong sentence for the first minute anybody has ever spent in this app,
/// because it answers a question they have not asked yet and does not answer
/// the one they have: **what is this, and where do I put things.**
///
/// So a vault with nothing in it anywhere gets a page rather than a line —
/// still the same sheet, still no card and no shadow, but with room on it.
/// Three things, and deliberately not four:
///
///   1. **What this is**, in one sentence that is about them rather than about
///      the app.
///   2. **Where things go** — the three ways in, named in the order of the
///      capture bar they point at, so the row of buttons at the bottom of the
///      screen stops being three unlabelled glyphs.
///   3. **One promise**, and only one: it stays on this phone. The onboarding
///      has already made the longer argument and repeating it here would be
///      the app selling itself to somebody who has already bought it.
///
/// **What it is not**: a tour, a checklist, a "3 of 5", or anything with a
/// dismiss button. `ETHICAL-DESIGN.md` rules out manufactured progress and
/// `PLAN.md` §3 rules out anything that turns writing into a task. This page
/// disappears the moment the first thing is written and can never come back —
/// `watchIsBrandNew` counts deleted entries as having been written, so even
/// somebody who writes a line and throws it away is never shown the welcome a
/// second time.
class EmptyDay extends StatelessWidget {
  const EmptyDay({
    super.key,
    required this.date,
    required this.isToday,
    this.onTap,
    this.isFirstEver = false,
  });

  final DateTime date;
  final bool isToday;

  /// Nothing has ever been written in this vault, on any day.
  ///
  /// Only ever true on today — a brand-new vault swiped back to last March is
  /// a day in the past, and greeting somebody there would be greeting them in
  /// the wrong room.
  final bool isFirstEver;

  /// Puts the caret on the page. **ISSUE 9** — null on a day that is not the
  /// one on screen, and on past days, where there is nothing to invite.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    if (isFirstEver && isToday) return _FirstPage(onTap: onTap);

    final sheet = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: Space.x5, vertical: Space.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          // The accent rule an entry block has, so an empty day is recognisably
          // the same object as a day with something on it — one short of it
          // rather than a different screen.
          Container(
            width: 2,
            height: 20,
            margin: const EdgeInsets.only(right: Space.x3),
            color: c.accent.withValues(alpha: isToday ? 0.45 : 0.2),
          ),
          Expanded(
            child: Text(
              // A question, not pressure. `ETHICAL-DESIGN.md`: the empty first
              // day must not guilt anyone into writing. Set in the writing face
              // on today, because it is standing where their own sentence will
              // be a moment later and the two should not look different.
              isToday ? L.of(context).dayEmptyToday : L.of(context).dayEmptyPast,
              style: isToday
                  ? writingStyle(context).copyWith(color: c.inkMuted)
                  : t.bodyLarge?.copyWith(color: c.inkMuted),
            ),
          ),
          if (onTap != null)
            Icon(Icons.edit_outlined, size: 18, color: c.inkMuted),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: Space.x5),
      child: onTap == null
          ? sheet
          : Semantics(
              button: true,
              label: L.of(context).dayWriteSomething,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(Radii.md),
                child: sheet,
              ),
            ),
    );
  }
}

/// The first page of an empty book. **`Honest Review`, the small ones.**
///
/// Drawn once in the life of a vault. See `EmptyDay`'s comment for what it
/// deliberately is not.
class _FirstPage extends StatelessWidget {
  const _FirstPage({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: Space.x5),
      child: Semantics(
        button: onTap != null,
        label: L.of(context).firstPageSemantic,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.x6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // The same accent rule every block in this app hangs off,
                    // so the very first thing somebody sees is already the
                    // shape everything else will be.
                    Container(
                      width: 2,
                      height: 22,
                      margin: const EdgeInsets.only(right: Space.x3),
                      color: c.accent.withValues(alpha: 0.45),
                    ),
                    Expanded(
                      child: Text(
                        // About them, not about the app. Not "Welcome to
                        // Lamplight" — they know what they installed.
                        L.of(context).firstPageTitle,
                        style: writingStyle(context)
                            .copyWith(color: c.inkPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.x5),
                Text(
                  L.of(context).firstPageShelves,
                  style: t.bodyMedium?.copyWith(color: c.inkSecondary),
                ),
                const SizedBox(height: Space.x5),
                // The three ways in, in the order of the bar they point at, so
                // three unlabelled glyphs at the bottom of the screen get
                // names exactly once.
                _Way(
                  icon: Icons.edit_outlined,
                  text: L.of(context).firstPageWayWrite,
                ),
                _Way(
                  icon: Icons.mic_none_outlined,
                  text: L.of(context).firstPageWayVoice,
                ),
                _Way(
                  icon: Icons.add_photo_alternate_outlined,
                  text: L.of(context).firstPageWayAttach,
                ),
                const SizedBox(height: Space.x5),
                Divider(height: 1, color: c.borderHair),
                const SizedBox(height: Space.x4),
                Text(
                  // One promise, said once. The onboarding has already made
                  // the longer argument; repeating it here would be the app
                  // selling itself to somebody who has already bought it.
                  L.of(context).firstPagePromise,
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the three ways in.
class _Way extends StatelessWidget {
  const _Way({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aligned to the first line of text rather than centred, so a
          // sentence that wraps at 200% does not leave the icon floating in
          // the middle of two lines.
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: c.inkMuted),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              text,
              style: t.bodyMedium?.copyWith(color: c.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
