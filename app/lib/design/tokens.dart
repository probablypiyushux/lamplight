
import 'package:flutter/material.dart';

import 'accents.dart';
import 'typefaces.dart';

export 'accents.dart';
export 'typefaces.dart';

/// The Lamplight design tokens, from `08-design/DESIGN-SYSTEM.md`.
///
/// **Every value here was computed and verified, not eyeballed.** The contrast
/// ratios in the comments come from `08-design/CONTRAST-REPORT.md`, calculated
/// with the WCAG 2.1 relative-luminance formula. Do not adjust a colour without
/// recomputing them — a "slightly nicer" grey that drops below 4.5:1 excludes
/// people, and it does so invisibly.
///
/// **Rule: if a widget contains a hex code, it is a bug.** `CLAUDE.md` rule 8.
/// Reference these by role — `context.ink.secondary`, not `Color(0xFFA5A29A)` —
/// so light and dark are one swap and a future palette change is one file
/// rather than four hundred edits.
///
/// THE IDEA BEHIND THE PALETTE
///
/// Warm near-black, warm paper-white, one amber accent. Not blue. Blue is the
/// default of every productivity app and reads *corporate* — a tool for getting
/// things done. This is a private room at the end of the day. Amber on warm
/// neutrals reads as lamp, paper, evening, and it feels like an object rather
/// than software.
///
/// A single-accent palette has a free accessibility property: with no competing
/// hues there are no colour pairs to confuse, so it is **inherently
/// colour-blind safe** in every form. Meaning is carried by lightness and
/// position, which every eye reads the same way. That is a benefit of restraint,
/// not a happy accident.
@immutable
class LamplightColors extends ThemeExtension<LamplightColors> {
  const LamplightColors({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.borderHair,
    required this.borderStrong,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.accent,
    required this.danger,
    required this.good,
    required this.gridRamp,
  });

  /// App background. Warm near-black, never `#000`.
  final Color canvas;

  /// Sheets and panels.
  final Color surface;

  /// Menus and pressed states.
  final Color raised;

  /// Dividers. **Decorative only** — below 3:1 by design. Nothing may depend on
  /// seeing these. Any boundary that carries meaning uses [accent] or ink, both
  /// of which clear 3:1. That is the correct reading of WCAG 1.4.11 rather than
  /// a loophole, and `CONTRAST-REPORT.md` says so explicitly.
  final Color borderHair;

  /// Input outlines.
  final Color borderStrong;

  /// Body text. Warm off-white in dark mode, never `#FFF` — pure white on
  /// near-black causes halation, where text appears to glow and blur. That is
  /// particularly hard on people with astigmatism. Maximum contrast is not
  /// optimum contrast.
  final Color inkPrimary;

  /// Timestamps and meta.
  final Color inkSecondary;

  /// Placeholders and disabled states.
  final Color inkMuted;

  /// Amber. **Used for at most three things:** the recording state, the current
  /// day, the active selection. If everything is accented, nothing is.
  final Color accent;

  /// Destructive actions only. Never decorative.
  final Color danger;

  /// Confirmations.
  final Color good;

  /// The year grid: empty plus five levels, light to dark, one hue.
  ///
  /// The empty state is a **neutral**, not the lightest amber, so "nothing
  /// happened" reads as absence rather than as a small amount. Every adjacent
  /// pair is separated by at least 1.25× in luminance, so the steps stay
  /// distinguishable in greyscale, in sunlight, and to a monochromatic viewer.
  final List<Color> gridRamp;

  /// Dark mode. The default — `DESIGN-SYSTEM.md` says so.
  static const dark = LamplightColors(
    canvas: Color(0xFF0F0F0E),
    surface: Color(0xFF171714),
    raised: Color(0xFF1F1F1B),
    borderHair: Color(0xFF2B2B26),
    borderStrong: Color(0xFF403F38),
    inkPrimary: Color(0xFFF2F0EA), // 16.83:1 AAA
    inkSecondary: Color(0xFFA5A29A), // 7.52:1 AAA
    inkMuted: Color(0xFF8C897F), // 5.48:1 AA
    accent: Color(0xFFE9A94B), // 9.35:1 AAA
    danger: Color(0xFFF0736E), // 6.74:1 AA
    good: Color(0xFF6FBF73), // 8.56:1 AAA
    gridRamp: [
      Color(0xFF1E1E1A), // empty
      Color(0xFF4A3517),
      Color(0xFF7A5620),
      Color(0xFFA8762A),
      Color(0xFFD19A3C),
      Color(0xFFF2C071),
    ],
  );

  /// Light mode — **a separately chosen palette, not an inversion.**
  ///
  /// Flipping a dark palette produces muddy, low-contrast results. Every value
  /// below was picked against the light surface and re-verified. Note the
  /// accent is a deeper amber: the dark-mode amber fails on white.
  static const light = LamplightColors(
    canvas: Color(0xFFFAF9F5), // warm paper, not clinical white
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFF3F1EB),
    borderHair: Color(0xFFE6E3DA),
    borderStrong: Color(0xFFC4C0B2),
    inkPrimary: Color(0xFF1A1916), // 16.69:1 AAA
    inkSecondary: Color(0xFF5B5950), // 6.67:1 AA
    inkMuted: Color(0xFF6C6A60), // 5.15:1 AA
    accent: Color(0xFF9A6212), // 4.83:1 AA
    danger: Color(0xFFB8332C), // 5.62:1 AA
    good: Color(0xFF2C7531), // 5.39:1 AA
    gridRamp: [
      Color(0xFFEFEDE6), // empty
      Color(0xFFEFCC92),
      Color(0xFFE3B267),
      Color(0xFFCE9032),
      Color(0xFFA16F26),
      Color(0xFF5F4010),
    ],
  );

  @override
  LamplightColors copyWith({
    Color? canvas,
    Color? surface,
    Color? raised,
    Color? borderHair,
    Color? borderStrong,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkMuted,
    Color? accent,
    Color? danger,
    Color? good,
    List<Color>? gridRamp,
  }) =>
      LamplightColors(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        raised: raised ?? this.raised,
        borderHair: borderHair ?? this.borderHair,
        borderStrong: borderStrong ?? this.borderStrong,
        inkPrimary: inkPrimary ?? this.inkPrimary,
        inkSecondary: inkSecondary ?? this.inkSecondary,
        inkMuted: inkMuted ?? this.inkMuted,
        accent: accent ?? this.accent,
        danger: danger ?? this.danger,
        good: good ?? this.good,
        gridRamp: gridRamp ?? this.gridRamp,
      );

  @override
  LamplightColors lerp(LamplightColors? other, double t) {
    if (other == null) return this;
    return LamplightColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      borderHair: Color.lerp(borderHair, other.borderHair, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      good: Color.lerp(good, other.good, t)!,
      gridRamp: [
        for (var i = 0; i < gridRamp.length; i++)
          Color.lerp(gridRamp[i], other.gridRamp[i], t)!,
      ],
    );
  }

  /// The dark palette with [accent] swapped in, ramp and all.
  ///
  /// Only three values move: the accent itself, and the year grid's ramp. The
  /// neutrals do not, and that is on purpose — the warm near-black *is* the
  /// app, and re-tinting the whole page per accent would produce six different
  /// products rather than one product with a choice in it.
  static LamplightColors darkFor(LampAccent accent) =>
      dark.copyWith(accent: accent.dark, gridRamp: accent.darkRamp);

  static LamplightColors lightFor(LampAccent accent) =>
      light.copyWith(accent: accent.light, gridRamp: accent.lightRamp);
}

/// Space — an 8pt grid.
///
/// **Space is the design.** `03-product/DESIGN-LANGUAGE.md`: minimal is not
/// "fewer pixels", it is "nothing on screen that isn't the user's own content".
abstract final class Space {
  static const double x1 = 4; // icon to label
  static const double x2 = 8; // inside a control
  static const double x3 = 12; // tight stacks
  static const double x4 = 16; // default gap
  static const double x5 = 20; // between entries
  /// **Screen margin. 24, not 16.** Sixteen is the framework default, and
  /// defaults look like defaults. The extra eight points is most of the
  /// difference between "an app" and "a considered object".
  static const double x6 = 24;
  static const double x8 = 32; // above a date heading
  static const double x10 = 40; // major section breaks
}

/// **The layout grid. ISSUE 1, ISSUE 2b, and the tablet instruction.**
///
/// ── WHAT WENT WRONG WITHOUT IT ────────────────────────────────────────────
///
/// Piyush photographed five screens and drew a red line down the right-hand
/// side of each: setting values, the search and gear icons, the ‹ › month
/// arrows, the footer. Nothing lined up with anything.
///
/// It was **one cause, not five**. There was no declared grid, so every
/// component picked its own inset from the [Space] scale and they came out at
/// 44, 40, 32, 24 and 20 points from the edge. Patching the five screens he
/// photographed would have left the sixth wrong, and the seventh would have
/// been written wrong tomorrow.
///
/// There was also a live layout bug underneath. A settings row put the value in
/// a `Flexible(flex: 2)`, which is a *loose* fit: short values like `21:00`
/// shrink-wrapped and gave their unused share back as slack, and a `Row` puts
/// slack at the end — so the chevron after a short value floated eighty points
/// left of the chevron after a long one. `textAlign: TextAlign.end` inside a
/// shrink-wrapped box does nothing at all. The value column is `Expanded` now,
/// which is the tight fit, so the split is deterministic and the right edge is
/// the same on every row whatever the value says.
///
/// ── THE TABLET ANSWER, AND WHY IT CHANGED ON 23 AUGUST 2026 ───────────────
///
/// **This section used to argue for a centred 560-point column. It is kept, as
/// an argument that was coherent and still lost, because the next person to
/// look at a 1142-point-wide settings row will have the same idea again.**
///
/// The instruction it was built on was *"responsive at core — make the app feel
/// the same on tablet and on mobile. I don't need any extra change in both"*
/// (22 Aug), and the mechanism chosen for it was to stop the content column
/// growing past [maxContent] and let the extra width become margin. The
/// reasoning was that this holds proportions across a 320dp phone and a 685dp
/// tablet, that a stretched row is a label at the far left and a value at the
/// far right with a desert between them, and that body text past 45–75
/// characters is harder to read. Every one of those sentences is still true.
///
/// It was wrong anyway, for two reasons he found by using it.
///
/// **One: it was never applied consistently, and that was worse than either
/// choice.** He photographed eight screens on one device and marked each
/// *"Full"* or *"Has space"* — Folders, the account card, Appearance and Backup
/// ran edge to edge; Fonts and licences, Trash, Locking and security and the
/// day sat in the centred column. Same app, same width, two different margins,
/// because some screens were wrapped in [LampColumnWidth] and some were not.
/// His summary was *"spacing issue on different parts on different places on
/// the same app"*, and no amount of being right about reading measure survives
/// an app that cannot decide.
///
/// **Two: in landscape the cap is not a margin, it is a hole.** He drew it —
/// a third of blank, a third of content marked *"very small"*, a third of
/// blank, with *"very much negative space"* down both sides — and named
/// WhatsApp, Instagram, Telegram and Google's own apps as the comparison.
/// Settings in landscape showed the account card full-width above rows at
/// *"1/3rd"*, and he wrote *"why???"* between them.
///
/// **His decision, verbatim:** *"If you make everything full → everything has a
/// consistent space on the side → everything blends consistently → looks
/// perfection."*
///
/// So the rule is now: **content fills the width, and [gutter] is the only side
/// margin.** One number, every screen, every orientation, both devices.
///
/// Note what did *not* change: the 22 August instruction is still obeyed. It
/// asked for one layout rather than a separate tablet build — *"I don't need
/// any extra change in both"* — and one full-width layout satisfies that
/// exactly as well as one capped layout did. The 560 cap was our mechanism, not
/// his request, and it is the mechanism that is gone.
///
/// [maxForm] survives, and is the one deliberate exception. A passcode field is
/// not content — it is one box and one button that want to be near the middle
/// of the screen and near a thumb — and he has never once complained about the
/// lock screen. See the note there.
abstract final class Layout {
  /// The screen margin, and the rule every full-width edge sits on.
  ///
  /// 24, matching [Space.x6], which `DESIGN-SYSTEM.md` chose over the
  /// framework's 16 — see the note there.
  static const double gutter = Space.x6;

  /// The inset from a grouped sheet's edge to the content inside it.
  static const double rowInset = Space.x4;

  /// The accent rule beside an entry, and the gap after it.
  ///
  /// **ISSUE 9/10 — "why are they in middle".** Every block in the day stream
  /// draws a two-point accent rule down its left side with [Space.x3] after it,
  /// and those fourteen points were being taken out of the *content*. So an
  /// entry's words — and a voice note's play button, which is what he circled —
  /// started fourteen points further right than the composer directly beneath
  /// them and than the date directly above them.
  ///
  /// Three rules on one page, none of them declared anywhere, which is exactly
  /// the fault the whole of [Layout] was written to end.
  ///
  /// The rule belongs in the margin, the way a margin mark does on paper. The
  /// stream is inset by [gutter] minus this, so the rule hangs outside and the
  /// content lands on [gutter] with everything else.
  static const double rail = 2 + Space.x3;

  /// **The one vertical rule.** Row text, group labels, group footers and every
  /// trailing control line up here, on both sides of the screen.
  ///
  /// It is the sheet's edge plus the row's own inset, which is what makes a
  /// section heading sit over the first word of the row beneath it rather than
  /// eight points to its left.
  static const double contentGutter = gutter + rowInset;

  /// Where a row of icon buttons is padded to.
  ///
  /// **An optical correction, not a different margin.** An [IconButton] centres
  /// a 24-point glyph inside a 48-point tap target, so padding its *box* to the
  /// gutter would leave the glyph twelve points inside the rule and read as
  /// misaligned — which is precisely what the search and gear icons were doing.
  /// Pulling the box out by half the difference puts the glyph on the rule and
  /// leaves the tap target its full size.
  static const double iconInset = gutter - (kMinTouchTarget - 24) / 2;

  /// The reading measure, in points. **No longer a cap on the layout.**
  ///
  /// 560 is a little over the 65-character measure at the body size. Until 23
  /// August every content column was clamped to it and centred, which is the
  /// decision reversed in the note above — content fills the width now.
  ///
  /// The number is kept, and kept public, for one reason: it is the width past
  /// which a line of running prose is genuinely harder to read, and that fact
  /// did not stop being true because the layout changed. Anything that is a
  /// *paragraph* rather than a *row* may still want it. Nothing in the app
  /// uses it as a clamp today, and adding one back needs a better argument
  /// than "it looks wide", because that argument has been made and lost.
  static const double maxContent = 560;

  /// The smallest a row's trailing column is ever drawn, so a one-word value
  /// and a switch occupy the same visual column.
  static const double trailingMin = 56;

  /// [maxContent] plus a gutter each side. **Unused, and deliberately kept.**
  ///
  /// This was the outer width of a page whose children applied their own
  /// margins. Nothing wraps itself in it any more — see the note above — but
  /// the relationship it expresses is still the one to use if a measure cap
  /// ever comes back, so it stays rather than being reinvented slightly
  /// differently by whoever needs it next.
  static const double maxColumn = maxContent + gutter * 2;

  /// The widest a *form* is drawn: the lock screen, onboarding, a passcode.
  ///
  /// Narrower than [maxContent] on purpose, and it is not an arbitrary second
  /// number. A column of prose wants a 65-character measure; a stack of one
  /// field and one button wants to be **near the middle of the screen and near
  /// your thumb**, and a 560-wide passcode field on a tablet reads as a web
  /// page. Every phone in the responsive suite is narrower than this, so on a
  /// phone it is not doing anything.
  static const double maxForm = 420;

  /// The side margin at [width]. **Always [gutter], at every width.**
  ///
  /// It used to centre a [maxContent]-wide column, growing the margin once the
  /// screen was wider than the column. That is the behaviour he drew as two
  /// blank thirds; see the note at the top of this file.
  ///
  /// It still takes [width] and is still called everywhere it was, rather than
  /// every call site being replaced with a bare constant. That is on purpose:
  /// there is exactly one function that decides the side margin, so if it ever
  /// needs to vary again — by orientation, by hinge, by anything — it varies in
  /// one place and every screen follows. Deleting it would scatter the decision
  /// back across the app, which is the state this whole file exists to end.
  static double marginFor(double width) => gutter;

  /// The horizontal padding a full-width screen uses at [width].
  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: marginFor(width));
}

/// Lets its child have the full width. **ISSUE 6.**
///
/// This used to clamp to [Layout.maxContent] and centre, and it was the single
/// mechanism behind "the same on tablet and on mobile". It is now a
/// pass-through, and the long note at the top of this file says why.
///
/// **It is a pass-through rather than deleted, and that is the point.** Nine
/// call sites wrap their content in this. Deleting it would mean editing all
/// nine and would leave the app with *no* single place where "how wide is
/// content" is decided — which is the exact condition that produced eight
/// screens with two different margins and got this written down as an issue.
/// One widget, one answer, and if the answer ever changes again it changes
/// here and every screen follows on the same day.
///
/// The old implementation is worth keeping in view: it was an `Align` with
/// `heightFactor: 1` around a `ConstrainedBox`, and the height factor was
/// load-bearing rather than tidiness — almost every caller is inside a scroll
/// view where the vertical constraint is unbounded, and an `Align` without one
/// tries to fill that and throws. Anyone restoring a cap here needs that line
/// back with it.
class LampColumnWidth extends StatelessWidget {
  const LampColumnWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Corner radii. Four values, each with a job.
/// Corner radii.
///
/// **Raised from the original 6/12/20 on 19 August 2026**, and the reason is
/// worth writing down because it is a deviation from `DESIGN-SYSTEM.md`'s
/// table rather than an implementation of it.
///
/// The brief was for the app to hold its own against Google's own — Keep,
/// Calendar, Files. Looking at what actually separates those from a competent
/// amateur build, it is almost never colour and almost always two things:
/// **corner radius and breathing room**. Material 3 moved to 12 for the small
/// case and 16–28 for containers, and the difference between a 12px sheet and a
/// 20px one is most of the difference between "an app" and "a current app".
/// The old values were drawn from a 2019 vocabulary.
///
/// The ratios are kept — each value still has exactly one job, and there are
/// still four of them, which is the rule that actually matters. Anything more
/// than four radii is a system with no opinion.
abstract final class Radii {
  /// Chips, inputs, small controls, the focus ring.
  static const double sm = 10;

  /// Grouped rows, banners, entry containers.
  static const double md = 18;

  /// Sheets and modals — the largest thing that is still a rectangle.
  static const double lg = 28;

  /// Buttons and the record button.
  ///
  /// **Pill-shaped, which is the single most legible signal that an interface
  /// was designed this decade.** It is also the one Material 3 borrowed from
  /// iOS rather than the other way round, and it costs nothing: a filled button
  /// at full radius reads as a button at any size, in any language, at 200%
  /// text.
  static const double full = 999;
}

/// Motion.
///
/// **Motion only to explain a spatial relationship** — a sheet rising, a day
/// sliding sideways. Never decoration. Nothing blocks input: if the user can
/// type during a transition, they can type.
abstract final class Motion {
  static const Duration standard = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOut;

  /// Honours `prefers-reduced-motion`. One flag, and for people with vestibular
  /// disorders it is the difference between nausea and no nausea.
  /// `08-design/ACCESSIBILITY.md` requires it.
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : standard;
}

/// Minimum touch target, from `08-design/ACCESSIBILITY.md`.
///
/// 48×48dp for anything tappable, always. The *visual* size may be smaller; the
/// hit area may not.
const double kMinTouchTarget = 48;

/// The two faces, and why neither of them is a bundled font file.
///
/// `DESIGN-SYSTEM.md` offers "the platform's own — SF on iOS, Roboto on Android
/// — or Inter" for the interface, and separately offers a serif for the user's
/// own writing. Both are taken here, and both resolve to fonts that are already
/// on the device.
///
/// **Nothing is bundled.** A font file is two things this project treats as
/// costs: about 300 KB of APK for each weight, and a licence to carry and
/// honour. The platform faces are already there, already hinted for the screen
/// in the reader's hand, and already the size the user picked in Settings.
/// Using them is also what makes the app feel like part of the phone rather
/// than a website wearing an app's clothes.
abstract final class Typefaces {
  /// The interface. `null` means "whatever this platform's own is" — Roboto on
  /// Android, SF on iOS. Deliberately not Inter as a display face: the
  /// workspace bans that, and the platform face is the better answer anyway.
  static const String? ui = null;

  /// The user's own writing, when the serif setting is on.
  ///
  /// `serif` is a generic family name that Android resolves to Noto Serif and
  /// iOS resolves to New York / Times. Every platform ships one, so this is a
  /// real serif at zero bytes. The fallbacks below name the usual concrete
  /// files in case a manufacturer's font config has been stripped down.
  static const String serif = 'serif';

  static const List<String> serifFallback = <String>[
    'Noto Serif',
    'Source Serif Pro',
    'Georgia',
    'Times New Roman',
  ];
}

/// The style the user's own words are set in — entries, and the composer.
///
/// **Only the user's own words, and the headings.** Labels, buttons,
/// timestamps and errors stay in the interface face at every setting. Setting
/// a delete confirmation in a blackletter is not expression, it is a
/// legibility bug. See the long note in `typefaces.dart`.
TextStyle writingStyle(BuildContext context, {WritingFace? face}) {
  final resolved = face ?? LampTypography.of(context).face;
  final base = Theme.of(context).textTheme.bodyLarge!;
  // The face's own metric corrections are already folded into `apply`, so a
  // paragraph of Caveat and a paragraph of IBM Plex occupy about the same room
  // and read at about the same size.
  return resolved.apply(base);
}

/// The chosen face, carried down the tree so any widget can ask for it without
/// being handed the settings object.
///
/// An [InheritedWidget] rather than a field on the theme extension because the
/// face has to reach `writingStyle`, which is called from inside build methods
/// that have a context and nothing else.
class LampTypography extends InheritedWidget {
  const LampTypography({
    super.key,
    required this.face,
    required super.child,
  });

  final WritingFace face;

  static LampTypography of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LampTypography>() ??
      const LampTypography(face: WritingFace.system, child: SizedBox.shrink());

  @override
  bool updateShouldNotify(LampTypography old) => old.face != face;
}

/// Type scale.
///
/// **All sizes scale with the OS text-size setting, to 200%, without clipping
/// or overlap.** Never a hardcoded pixel font size, never a fixed-height text
/// container. These are the base values Flutter then scales.
///
/// The 26/17 body ratio is the single most important number in the design
/// system. It is what makes long text feel readable rather than cramped.
/// Do not let anyone tighten it.
/// ══ THE HALO THAT LETS WRITING SIT ON A CHART. ROUND FIFTEEN, ISSUE 9 ═════
///
/// > *"VISIBLITY help needed! Text — I don't want you to change the backside —
/// > think of something which would look good! Ideate this"*, with the light
/// > page circled and *"can you understand"* beside it, and, on the dark one,
/// > *"manageable in dark mode!!!"*
///
/// ── WHAT IS ACTUALLY WRONG, BECAUSE IT IS NOT CONTRAST ───────────────────
///
/// The obvious diagnosis is that the text is too pale, and it is wrong. Body
/// copy on the light page is `inkPrimary`, #1A1916, and the worst thing behind
/// it is a constellation line at 34% ink — which composites to about #AEAEAB.
/// That pair is **7.8:1**, comfortably past AA. By the numbers the page he
/// photographed is fine, which is exactly why three rounds of adjusting
/// colours would not have fixed it.
///
/// The problem is *spatial*, and it is the same shape of problem as ISSUE 6's
/// blur. The chart draws strokes 0.6–1 point wide. Body type at 17pt has stems
/// of about the same width. Two families of marks at the same scale, the same
/// colour and the same weight, crossing each other — the eye cannot tell which
/// strokes belong to the letters. Contrast is not the channel that is
/// saturated; *frequency* is. Dark mode escapes it because a star adds light
/// and the text is light, so the marks and the glyphs sit at opposite ends of
/// the range rather than on top of each other.
///
/// ── AND HE RULED OUT THE OBVIOUS FIX ─────────────────────────────────────
///
/// *"I don't want you to change the background."* So: no plate under the text
/// column, no lightening of the sky, no turning the chart down. The sky stays
/// exactly as it is.
///
/// ── SO THE LETTERS CARRY THEIR OWN QUIET ─────────────────────────────────
///
/// This is the cartographer's answer and it is a hundred years older than the
/// screen: a **halo**. Every label on every printed map that crosses a
/// coastline has one. The glyph is drawn over a soft wash of the page's own
/// colour, so within two or three points of every stem the chart is not there,
/// and everywhere else it is completely untouched.
///
/// Three things make it the right answer here rather than a trick:
///
///   * **It is not a shadow.** `DESIGN-SYSTEM.md` bans those and the ban
///     stands — it is about faking depth, and a drop shadow has an offset, a
///     direction and a darker colour. This has no offset, no direction, and it
///     is the page's colour. It is a knockout, not a lift.
///   * **It is invisible where it is not needed — on a page-coloured ground.**
///     On Settings, on the lock screen, on Plain, on Paper, this changes not
///     one pixel.
///
///     **That sentence used to end "which is why it can be applied to a whole
///     text theme without auditing every screen", and that was wrong.** It is
///     only true while the ground under the words *is* the page. The moment
///     text sits on a ground of its own — a photograph, an accent bubble, a
///     glass panel — the halo is no longer the colour behind it, and a wash of
///     cream around white type on a dark thumbnail is not a knockout, it is a
///     glow. He photographed exactly that twice: the duration on a video poster
///     and the value bubble on the text-size slider.
///
///     So the rule is stated properly now: **the halo belongs to text whose
///     ground is [LamplightColors.canvas]. Anything that paints its own ground
///     must take it off again** — see [stripPageHalo] and [OffThePage], which
///     is what the ground-painting components in `components.dart` now do for
///     themselves, so that no future island has to remember.
///   * **It costs nothing to say honestly.** The app is not claiming the sky
///     is dimmer than it is. The sky is exactly as drawn; the words are simply
///     nearer.
///
/// Two stops rather than one. A single blurred copy peaks below full alpha at
/// the glyph edge, so a line running straight into a stem is only half erased
/// where it matters most; a tight stop under a wide one gives a solid couple of
/// points and a fade after it.
List<Shadow> pageHalo(Color canvas) => [
      Shadow(color: canvas.withValues(alpha: 0.92), blurRadius: 2.5),
      Shadow(color: canvas.withValues(alpha: 0.78), blurRadius: 6),
    ];

/// The halo, taken off again, for text that is **not** on the page.
///
/// The counterpart to [pageHalo] and the other half of the rule stated there.
/// Returns [theme] unchanged when there was no halo on it — every surface
/// except Star Map — so this is free to call and safe to wrap anything in.
///
/// `const <Shadow>[]` rather than `null`: `TextStyle.copyWith` treats a null
/// argument as "leave what is there", which would silently do nothing at all
/// and is exactly the sort of no-op that looks like a fix in a diff.
TextTheme stripPageHalo(TextTheme theme) {
  final marker = theme.bodyLarge?.shadows;
  if (marker == null || marker.isEmpty) return theme;
  TextStyle? bare(TextStyle? from) => from?.copyWith(shadows: const <Shadow>[]);
  return theme.copyWith(
    displaySmall: bare(theme.displaySmall),
    titleLarge: bare(theme.titleLarge),
    bodyLarge: bare(theme.bodyLarge),
    labelMedium: bare(theme.labelMedium),
    labelSmall: bare(theme.labelSmall),
  );
}

/// Wraps a subtree that paints its own ground, so the page halo stops there.
///
/// Use it around anything with a background of its own: a filled button, a
/// card, a chip, a glass panel, the scrim over a photograph. On any surface but
/// Star Map it is a no-op and returns [child] untouched, so it costs a
/// `Theme.of` and nothing else.
class OffThePage extends StatelessWidget {
  const OffThePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stripped = stripPageHalo(theme.textTheme);
    if (identical(stripped, theme.textTheme)) return child;
    return Theme(data: theme.copyWith(textTheme: stripped), child: child);
  }
}

TextTheme lamplightTextTheme(
  Color ink,
  Color inkSecondary, {
  /// The chosen face, applied to the two display sizes and to body copy —
  /// the places that are the user's own words or the title of them. Never to
  /// [TextTheme.labelMedium] or [TextTheme.labelSmall], which are the
  /// timestamps and meta labels and stay in the platform's face for good.
  WritingFace face = WritingFace.system,

  /// The reader's language. Two things about type depend on it and nothing
  /// else can supply them — see `scriptFallbackFor` and `lineHeightScaleFor`.
  Locale? locale,

  /// A wash of the page's own colour round every glyph, for a page that draws
  /// marks at the scale of type. Null on every other page. **ISSUE 9** — see
  /// [pageHalo].
  List<Shadow>? halo,
}) {
  final base = _lamplightTextThemeBase(ink, inkSecondary);
  final leading = lineHeightScaleFor(locale);
  final order = scriptFallbackFor(locale);

  /// The face, then the script's own leading, then the script's own font
  /// ordering. In that sequence: the face decides the family, and the last two
  /// adjust how that family is set for the script actually being read.
  TextStyle style(TextStyle from) {
    final applied = face.apply(from);
    return applied.copyWith(
      height: applied.height == null ? null : applied.height! * leading,
      // Overridden rather than appended: `WritingFace.apply` already put
      // `kScriptFallback` on the end in its fixed order, and a second copy
      // after this one would put the fixed order back in front of nothing.
      //
      // Keyed on `face.family`, matching `apply`'s own rule rather than on the
      // resolved `fontFamily` — which is inherited from the base theme and so
      // is never null. `WritingFace.system` deliberately carries no fallback
      // list at all: it means "whatever the rest of the phone uses", and the
      // platform's own resolution is better at that than any list here.
      fontFamilyFallback:
          face.family == null ? null : [...face.fallback, ...order],
    );
  }

  // The halo goes on **every** style, not only the body. The date, the
  // weekday, the timestamps and the meta labels all sit on the same page and
  // the smallest of them suffer most — a 12pt label crossed by a constellation
  // line is the least readable thing on the screen. **ISSUE 9.**
  TextStyle haloed(TextStyle from) =>
      halo == null ? from : from.copyWith(shadows: halo);

  return base.copyWith(
    displaySmall: haloed(style(base.displaySmall!)),
    titleLarge: haloed(style(base.titleLarge!)),
    bodyLarge: haloed(style(base.bodyLarge!)),
    labelMedium: haloed(base.labelMedium!),
    labelSmall: haloed(base.labelSmall!),
  );
}

TextTheme _lamplightTextThemeBase(Color ink, Color inkSecondary) => TextTheme(
      // Date heading — 32/38. The date is the title of the day.
      //
      // Negative tracking is the one thing added to the spec's numbers. Every
      // digital face is spaced for body copy, and at 32px that spacing reads
      // loose and unconsidered — the letters look like they are drifting apart.
      // Tightening large text and leaving small text alone is standard
      // typographic practice, not a deviation from the table.
      displaySmall: TextStyle(
        fontSize: 32,
        height: 38 / 32,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      // Section — 22/28.
      titleLarge: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      // Body — 17/26. The number that matters.
      bodyLarge: TextStyle(
        fontSize: 17,
        height: 26 / 17,
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      // Timestamp — 13/16.
      labelMedium: TextStyle(
        fontSize: 13,
        height: 16 / 13,
        fontWeight: FontWeight.w500,
        color: inkSecondary,
      ),
      // Meta / label — 12/16, letter-spaced.
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.06 * 12,
        fontWeight: FontWeight.w500,
        color: inkSecondary,
      ),
    );

/// Builds a [ThemeData] carrying the tokens.
///
/// **No shadows anywhere.** Depth comes from surface colour steps
/// (canvas → surface → raised). Shadows on a near-black background are
/// invisible, and on light they read as 2014.
/// Built themes, kept.
///
/// ══ WHY THIS IS WORTH CACHING AND ALMOST NOTHING ELSE IS ═══════════════════
///
/// > *"Make the whole app experience lag free!"*
///
/// `LamplightApp.build` constructs **two** of these every time it runs — the
/// light one and the dark one — and it runs on every vault notification and
/// every settings write. Two `ThemeData`s is not obviously expensive until you
/// look at what is inside one: `ColorScheme.fromSeed`, which runs Material 3's
/// tonal-palette algorithm in the HCT colour space, and a `TextTheme` with a
/// typeface applied across fifteen styles.
///
/// None of it depends on anything that changes between those rebuilds. There
/// are six accents, two brightnesses and fourteen faces, so the whole space is
/// small, bounded, and immutable once built — which is the exact shape of thing
/// that should be computed once.
///
/// **Bounded on purpose.** A cache with no lid is a leak with good manners; at
/// most a couple of dozen entries can ever exist here, and the assertion below
/// is what would catch somebody keying it on something unbounded later.
final Map<(int, String, String?, bool), ThemeData> _themes =
    <(int, String, String?, bool), ThemeData>{};

ThemeData lamplightTheme(
  LamplightColors c, {
  WritingFace face = WritingFace.system,
  /// The reader's language, which decides two things about type that nothing
  /// else can: which CJK family is preferred for a shared Han codepoint, and
  /// how much leading a script needs. See `scriptFallbackFor` and
  /// `lineHeightScaleFor` in `typefaces.dart`.
  Locale? locale,

  /// What the page is made of. It reaches the *type* for one reason only:
  /// a surface that draws marks at the scale of type needs the writing to
  /// carry a halo, or the two families of strokes interfere. **ISSUE 9** —
  /// see [pageHalo] and [PageSurface.marksThePage].
  PageSurface surface = PageSurface.paper,
}) {
  // The accent and the canvas between them settle every colour in the theme —
  // `LamplightColors` is a fixed palette per accent per brightness — and the
  // face settles the type. Nothing else in here varies.
  // The locale is part of the key: two locales produce genuinely different
  // text themes now, and caching one under the other's key would set Japanese
  // in the Simplified Chinese forms for the life of the process.
  // The surface is part of it for the same reason: on a star map the type
  // carries a halo and on paper it does not, so the two are different themes.
  final key = (
    c.accent.toARGB32() ^ (c.canvas.toARGB32() * 31),
    face.id,
    locale?.toLanguageTag(),
    surface.marksThePage,
  );
  final cached = _themes[key];
  if (cached != null) return cached;
  final built = _buildLamplightTheme(c, face, locale, surface);
  // 6 accents x 2 brightnesses x 14 faces is the whole space, and nobody visits
  // more than a handful of it. If this ever trips, the key has grown a
  // dimension that does not belong in it.
  assert(_themes.length < 200, 'the theme cache has grown a moving part');
  _themes[key] = built;
  return built;
}

ThemeData _buildLamplightTheme(
    LamplightColors c, WritingFace face, Locale? locale, PageSurface surface) {
  final text = lamplightTextTheme(
    c.inkPrimary,
    c.inkSecondary,
    face: face,
    locale: locale,
    // Page-coloured light on a page-coloured ground is nothing at all, so this
    // is invisible on every surface that does not need it — but it is still
    // two extra rasterisations per glyph, so it is not asked for. **ISSUE 9.**
    halo: surface.marksThePage ? pageHalo(c.canvas) : null,
  );
  final base = c.canvas.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: base,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: base,
    ).copyWith(
      surface: c.canvas,
      primary: c.accent,
      error: c.danger,
    ),
    textTheme: text,
    dividerTheme: DividerThemeData(color: c.borderHair, thickness: 1, space: 1),
    // One focus ring, everywhere, in the accent. CONTRAST-REPORT.md verifies it
    // clears 3:1 against every surface in both modes.
    focusColor: c.accent,
    splashFactory: InkRipple.splashFactory,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: c.inkPrimary,
      titleTextStyle: text.titleLarge,
    ),
    // Every surface that rises above the page is themed once, here, rather than
    // at each call site. Material's defaults would tint these with its own
    // seeded palette and quietly reintroduce the purple this design does not
    // have — `surfaceTintColor: transparent` is what turns that off.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surface,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      // A sheet that stops short of the top edge reads as a sheet. One that
      // fills the screen reads as a page that arrived from the wrong direction.
      constraints: const BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.borderHair),
      ),
      // A tooltip is a raised slab of its own. No page halo. **Round 19.**
      textStyle: text.bodyLarge?.copyWith(shadows: const <Shadow>[]),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.raised,
      // `raised`, not `canvas` — so a canvas-coloured halo is a visible wash
      // here rather than the nothing it is on the page. **Round 19.**
      contentTextStyle: text.bodyLarge
          ?.copyWith(color: c.inkPrimary, shadows: const <Shadow>[]),
      actionTextColor: c.accent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(color: c.borderHair),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkSecondary,
      textColor: c.inkPrimary,
      // 24 to match the screen margin, so a row's text lines up with the
      // heading above it instead of sitting eight points inside it.
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.x6),
      minVerticalPadding: Space.x3,
    ),
    // The one focus ring, and the one selected-state fill, both in the accent.
    // Material would otherwise pick its own from the seed.
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.borderStrong,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.canvas : c.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.raised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.borderStrong,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.raised,
      circularTrackColor: c.raised,
    ),
    // ── How every screen arrives ──────────────────────────────────────────
    //
    // Material's default on Android is `ZoomPageTransitionsBuilder`, which
    // scales the incoming screen up from 80% while fading it. It is fine, it is
    // everywhere, and it is the single most recognisable "this is a default
    // Flutter app" tell there is.
    //
    // This is a shared-axis slide: the outgoing screen moves a short way left
    // and dims, the incoming one comes in from the right. It reads as *going
    // somewhere*, which is what a push is, and it matches the day view's own
    // horizontal swipe between days — so the whole app moves along one axis
    // rather than each screen having its own idea.
    //
    // 260ms. Longer than the design system's 200 because a full-screen
    // transition has further to travel than a sheet, and short enough that
    // nobody taps twice thinking the first one missed.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: _LampPageTransitions(),
        TargetPlatform.iOS: _LampPageTransitions(),
      },
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.28),
      selectionHandleColor: c.accent,
    ),
  );
}

/// `context.lamplight` instead of `Theme.of(context).extension<…>()!`.
extension LamplightTheme on BuildContext {
  LamplightColors get lamplight =>
      Theme.of(this).extension<LamplightColors>() ?? LamplightColors.dark;
}

/// The one page transition this app uses.
///
/// Both directions of a shared axis: the new screen slides in from the right
/// while the old one moves a little to the left and dims. Going back reverses
/// exactly, so the two screens keep a consistent spatial relationship rather
/// than each appearing from nowhere.
///
/// The outgoing screen moves **less far than the incoming one** — a third of
/// the distance. That is the detail that makes it feel like depth rather than a
/// carousel: the thing you left is still there, just behind.
class _LampPageTransitions extends PageTransitionsBuilder {
  const _LampPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Honour the accessibility setting. `prefers-reduced-motion` gets a plain
    // cross-fade — the screen still changes, nothing slides. ACCESSIBILITY.md
    // requires it and for someone with a vestibular disorder it is the
    // difference between using the app and not.
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    const curve = Curves.easeOutCubic;
    final incoming = CurvedAnimation(parent: animation, curve: curve);
    final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: curve);

    return SlideTransition(
      // Where this screen goes when something is pushed on top of it.
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.28, 0),
      ).animate(outgoing),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.55).animate(outgoing),
        child: SlideTransition(
          // Where this screen comes from.
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(incoming),
          child: FadeTransition(opacity: incoming, child: child),
        ),
      ),
    );
  }
}
