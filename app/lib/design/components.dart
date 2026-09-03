import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// The parts every screen after the day view is built from.
///
/// WHY THIS FILE EXISTS
///
/// `ANNOYANCES.md` is precise about what was wrong with the first pass: "the
/// tokens, spacing and contrast are not the problem — the screens are the
/// minimum arrangement of correct tokens rather than a designed thing." The
/// cure for that is not more colours. It is a small set of real components with
/// their states worked out once, so that a settings row on one screen and a
/// settings row on another are the *same object* rather than two similar
/// arrangements that drift apart.
///
/// THE PRIMITIVE
///
/// The app is made of **sheets of paper on a dark table**. `bg.canvas` is the
/// table; every group of controls is a sheet in `bg.surface` with a 12px
/// corner; nothing floats, nothing casts a shadow, and depth comes only from
/// the surface step. That is the same idea as the entry block on the day view —
/// content sitting *on* something — and it is why there are no cards with
/// borders and no elevation anywhere in this file.

/// A screen with a large title and a back arrow.
///
/// The title is set at the same size as the date on the day view, because it is
/// the same thing: the name of what you are looking at. Keeping one heading
/// size across the app is most of what makes it feel like one app.
class LampPage extends StatelessWidget {
  const LampPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── The header sits on the grid, optically ─────────────────
            //
            // ISSUE 1: the back arrow and the actions were padded to
            // `Space.x2` — eight points — while the title below them sat at
            // twenty-four, so the arrow hung outside the letter it should have
            // been above and the gear icon hung outside the right-hand rule.
            //
            // `Layout.iconInset` is the gutter pulled in by half the difference
            // between a 48-point tap target and the 24-point glyph inside it,
            // so the *glyph* lands on the rule and the target keeps its size.
            // See the note in tokens.dart.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Layout.iconInset, vertical: Space.x2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: c.inkPrimary,
                    tooltip: L.of(context).searchBack,
                  ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            // ── The heading takes at most half the screen ──────────────────
            //
            // On a 320dp phone at 200% text, "Deleted entries stay here for 30
            // days, then go for good." wraps to ten lines. Add a 76px title and
            // a back button and the heading alone is taller than the window, so
            // the Column below it overflowed off the bottom of the screen and
            // the actual content had nowhere to go.
            //
            // Capping it and letting it scroll inside that cap means the
            // heading can be as long as it needs to be at any text size, and
            // there is always a screen's worth of room left for the thing the
            // user came here for. Found by the responsive suite at 320x640 and
            // in landscape, neither of which is a size anyone would have
            // thought to try by hand.
            //
            // The cap comes from the window, not from a LayoutBuilder. A Column
            // hands its non-flexed children an *unbounded* main axis, so a
            // LayoutBuilder here reports infinity and `infinity * 0.5` is still
            // infinity — the first version of this fix did exactly that and
            // capped nothing at all.
            Builder(
              builder: (context) => ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42),
                child: SingleChildScrollView(
                  // The title lives in the same column as the content below it,
                  // so it is on the gutter on a phone and centred with
                  // everything else on a tablet rather than stranded at the far
                  // left of a very wide screen.
                  child: LampColumnWidth(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          Layout.gutter, Space.x1, Layout.gutter, Space.x5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.displaySmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: Space.x2),
                            Text(subtitle!,
                                style: t.bodyLarge
                                    ?.copyWith(color: c.inkSecondary)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// A sheet of related rows, with an optional label above it.
///
/// The label is set in the meta style — small, letter-spaced, muted — because
/// it is a signpost rather than content. It is deliberately *outside* the
/// sheet: a heading inside the box would compete with the rows for the same
/// visual job.
class LampGroup extends StatelessWidget {
  const LampGroup({super.key, this.label, required this.children, this.footer});

  final String? label;
  final List<Widget> children;

  /// One quiet sentence under the group, for the thing the user would
  /// otherwise have to guess. Not help text for its own sake.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    // ── One rule, obeyed by the label, the sheet and the footer ────────
    //
    // ISSUE 1. These three sat at 32, 24 and 32 points from the left and 24, 24
    // and 32 from the right — three different edges inside one group.
    // `Layout.contentGutter` is the sheet's own margin plus a row's inset,
    // which is where the *text inside a row* starts, so a section heading now
    // sits directly over the first word beneath it and the footer sentence
    // lines up under both.
    //
    // The width cap lives here rather than at each screen because every
    // settings-shaped screen in the app is a stack of these. One wrapper, and a
    // tablet gets the phone's proportions everywhere at once instead of on the
    // four screens somebody remembered to change. See `Layout.maxContent`.
    return LampColumnWidth(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.x8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (label != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  Layout.contentGutter, 0, Layout.contentGutter, Space.x3),
              child: Text(label!.toUpperCase(),
                  style: t.labelSmall?.copyWith(color: c.inkMuted)),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Layout.gutter),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            // Clip so a pressed row's ripple stops at the rounded corner
            // instead of squaring it off.
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    // Inset to where the text starts, so the divider separates
                    // the rows rather than cutting the sheet in half.
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: Layout.rowInset),
                      child: Divider(height: 1, thickness: 1, color: c.borderHair),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                  Layout.contentGutter, Space.x3, Layout.contentGutter, 0),
              child: Text(footer!,
                  style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row inside a [LampGroup].
///
/// Minimum height is the touch-target floor, not a fixed height — set the OS
/// text size to 200% and this row grows instead of clipping its own label.
/// `ACCESSIBILITY.md` asks for exactly that and it is the single most common
/// place apps break.
class LampTile extends StatelessWidget {
  const LampTile({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;

  /// The current setting, shown at the right in secondary ink.
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Destructive. Uses `danger` for the label and the icon — and is still not
  /// the only signal, because the word itself says what it does.
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final ink = !enabled
        ? c.inkMuted
        : danger
            ? c.danger
            : c.inkPrimary;

    return Semantics(
      button: onTap != null,
      enabled: enabled,
      // Read as one thing — "Auto-lock, after one minute" — rather than as two
      // unrelated labels that a screen-reader user has to stitch together.
      label: value == null ? title : '$title, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: c.raised,
        highlightColor: c.raised,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Layout.rowInset, vertical: Space.x3),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: enabled ? ink : c.inkMuted),
                  const SizedBox(width: Space.x4),
                ],
                // ── Why both of these take a flex share ──────────────────────────
                //
                // The obvious build is `Expanded(title)` with a plain `Text`
                // for the value on the right. A plain `Text` in a `Row` is not
                // flexible: it demands its full natural width, the `Expanded`
                // gets whatever is left, and if the value is long the title is
                // squeezed to nothing and the row overflows off the right edge.
                //
                // A 200% text-size test caught that, which is the whole
                // argument for having one. `ACCESSIBILITY.md` requires every
                // screen to work at 200% without clipping, and this row appears
                // eight times on the settings screen — so getting it wrong here
                // got it wrong everywhere at once.
                //
                // 3:2 rather than 1:1 because the label is the thing you are
                // looking for and the value is the thing you are checking.
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: t.bodyLarge?.copyWith(color: ink)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: t.labelMedium?.copyWith(color: c.inkMuted)),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: Space.x4),
                  // ── `Expanded`, not `Flexible`. ISSUE 1 lived here. ────────
                  //
                  // `Flexible` is a *loose* fit: a child may take less than its
                  // share, and a short value like `21:00` did — it shrink-
                  // wrapped to forty points instead of its hundred-and-twenty
                  // point share and handed the rest back as slack. A `Row` puts
                  // slack at the **end**, so the chevron after `21:00` sat
                  // eighty points left of the chevron after `Skip for 60
                  // seconds`, and `textAlign: TextAlign.end` inside a
                  // shrink-wrapped box did nothing whatsoever.
                  //
                  // That is the single cause behind "nothing lines up on the
                  // right-hand side". `Expanded` is the tight fit: the column is
                  // always its full share, the text is set against the right
                  // edge of it, and every row in the app ends on the same rule
                  // whatever its value happens to say.
                  Expanded(
                    flex: 2,
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: Space.x3),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: Space.x2),
                  Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row that turns something on or off.
class LampSwitchTile extends StatelessWidget {
  const LampSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      toggled: value,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        splashColor: c.raised,
        highlightColor: c.raised,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Layout.rowInset, vertical: Space.x3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: t.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: t.labelMedium?.copyWith(color: c.inkMuted)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Space.x4),
                // excludeSemantics above means the switch is not announced
                // twice; the row carries the whole control.
                ExcludeSemantics(
                  child: Switch(value: value, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One option in a set of them.
///
/// **The tick is not the only signal.** The selected row also carries its label
/// in primary ink against unselected rows in secondary, so the choice is
/// readable without seeing the accent — which is what `DESIGN-SYSTEM.md` means
/// by never encoding meaning in colour alone.
class LampChoiceTile<T> extends StatelessWidget {
  const LampChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final selected = value == groupValue;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: title,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(value),
        splashColor: c.raised,
        highlightColor: c.raised,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Layout.rowInset, vertical: Space.x3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: t.bodyLarge?.copyWith(
                          color: selected ? c.inkPrimary : c.inkSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: t.labelMedium?.copyWith(color: c.inkMuted)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Space.x4),
                Icon(
                  selected ? Icons.check : null,
                  size: 20,
                  color: c.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one filled button in the app, in the accent.
class LampButton extends StatelessWidget {
  const LampButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final fill = danger ? c.danger : c.accent;
    // A floor, not a fixed height. 48dp is the touch-target minimum; at 200%
    // text the label alone is taller than that, and a fixed height would clip
    // the word inside the button rather than growing to hold it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTouchTarget),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          // The canvas colour on the accent, not white. Both palettes were
          // verified this way round in CONTRAST-REPORT.md.
          foregroundColor: c.canvas,
          disabledBackgroundColor: c.raised,
          disabledForegroundColor: c.inkMuted,
          // A pill. See Radii.full — it is the cheapest signal in the whole
          // system that this interface was designed recently.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          // ── No halo on a filled pill. **ISSUE 9.** ──────────────────
          //
          // The star map puts a wash of the page's own colour round every
          // glyph in the text theme, which is invisible everywhere the ground
          // *is* the page colour — and this is the one place it is not. The
          // label here is drawn in `canvas` on the accent, so a canvas-coloured
          // halo would be the same colour as the letters and the word would
          // simply look fatter. A button is its own surface; it does not need
          // the page's help to be read.
          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                shadows: const <Shadow>[],
              ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// The app is working, and this is how it says so.
///
/// WHY THIS EXISTS AS A SHARED THING
///
/// Reported as "it seems to stuck" and "I can't tell if it's my phone lagging",
/// and both were fair. Several places in this app stop for a noticeable time —
/// unlocking runs Argon2id over 256 MiB, which is a deliberate quarter of a
/// second or more; decrypting a photo; writing a backup — and in every one of
/// them the screen simply held still. **A still screen and a broken screen look
/// identical**, so the user is left to guess, and after a second or two
/// everybody guesses broken.
///
/// The fix is not a spinner bolted onto each one. It is one shape, used
/// everywhere, that the eye learns to read as "this is going, wait" — so that
/// the second time someone sees it they already know what it means.
///
/// It is the lamp's own light, breathing. On brand, and it costs one animation
/// controller rather than Material's rotating ring, which belongs to a
/// different design language than this app's.
///
/// **Honest about what it does not know.** This is indeterminate on purpose:
/// Argon2id cannot report progress, and a fake bar creeping to 90% and stopping
/// is a lie that makes waiting worse. Where real progress exists — backup,
/// restore — those screens show a real bar instead.
class LampBusy extends StatefulWidget {
  const LampBusy({super.key, this.label, this.size = 44});

  /// One short line under it. Say what is happening, not "Please wait".
  final String? label;
  final double size;

  @override
  State<LampBusy> createState() => _LampBusyState();
}

class _LampBusyState extends State<LampBusy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // A resting heart rate. Deliberately human rather than fast — a quick pulse
    // reads as urgency, and nothing here is urgent.
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    // Reduced motion gets a still, clearly-lit mark rather than a pulsing one.
    // It still reads as "on"; it just does not move. ACCESSIBILITY.md.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        // No `reverse`. A heartbeat is not symmetrical, and playing one
        // backwards is precisely the throb this replaced.
        _c.repeat();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// A heartbeat, not a fade.
  ///
  /// **This is the difference between "the app is thinking" and "the app is
  /// alive".** The first version breathed in and out on a sine, and a slow
  /// symmetric fade is indistinguishable from a rendering glitch — reported,
  /// fairly, as "the unlocking animation is just stuck".
  ///
  /// A heart does not fade. It goes *thump-thump*, pause. Two sharp rises close
  /// together and then a rest, and the rest is the part that makes it read as a
  /// pulse rather than a throb: the eye needs the gap to know it saw two beats.
  ///
  /// The numbers below are one cardiac cycle normalised to 0..1 — systole at
  /// 0.00, the second, smaller beat at 0.22, and the rest of the cycle quiet.
  double _beat(double t) {
    double pulse(double centre, double width, double height) {
      final d = (t - centre).abs();
      if (d > width) return 0;
      // A raised cosine: rises and falls smoothly, reaches zero at the edges,
      // and has none of a sine's lazy shoulders.
      return height * 0.5 * (1 + math.cos(math.pi * d / width));
    }

    // The big beat, then the smaller one on its heels.
    return (pulse(0.00, 0.16, 1.0) + pulse(0.22, 0.12, 0.55)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'Working',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _beat(_c.value);
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        c.accent.withValues(alpha: 0.12 + 0.62 * v),
                        c.accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      // The core swells with the beat too, so the pulse is
                      // carried by size as well as brightness — visible on a
                      // sunlit screen where a change in alpha alone is not.
                      width: widget.size * (0.22 + 0.10 * v),
                      height: widget.size * (0.22 + 0.10 * v),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent.withValues(alpha: 0.55 + 0.45 * v),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.label != null) ...[
            const SizedBox(height: Space.x3),
            Text(
              widget.label!,
              style: t.labelMedium?.copyWith(color: c.inkSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A quiet notice on a page. Never a modal, never a badge.
///
/// Used for the backup reminder in `UX-FLOWS.md` flow 5, which is explicit that
/// the wording may escalate but the intrusiveness may not. It is dismissible,
/// it does not cover anything, and it never appears twice in a row.
class LampBanner extends StatelessWidget {
  const LampBanner({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(Space.x6, 0, Space.x6, Space.x4),
      padding: const EdgeInsetsDirectional.fromSTEB(Space.x4, Space.x3, Space.x2, Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        // A hairline is decorative here; the words carry the meaning.
        border: Border.all(color: c.borderHair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: t.bodyLarge?.copyWith(color: c.inkSecondary)),
                const SizedBox(height: Space.x1),
                // A text button, not a filled one. This is an offer, not a
                // demand — ETHICAL-DESIGN.md, and the difference is the whole
                // point of the banner.
                InkWell(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.x2),
                    child: Text(actionLabel,
                        style: t.bodyLarge?.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
            color: c.inkMuted,
            tooltip: L.of(context).actionDismiss,
          ),
        ],
      ),
    );
  }
}

/// The passcode field, in the one shape it has everywhere it appears — the lock
/// screen, the backup confirmation, and the passcode change.
///
/// ══ THE REVEAL BUTTON, ROUND FIVE ISSUE 5 ════════════════════════════════
///
/// *"See, the passcode is shown like that. I was wishing to have a way by which
/// someone can see what is the passcode if he/she wanna check — after typing."*
///
/// He screenshotted the lock screen with a row of dots in the field and circled
/// it. It is the oldest usability complaint there is about password fields, and
/// it has an equally old answer: an eye on the right-hand end.
///
/// ── The security question, since this is a passcode field ─────────────────
///
/// `THREAT-MODEL.md` ranks *"the person who picks up the unlocked phone"* as
/// the most likely adversary by a wide margin, and a passcode drawn in plain
/// text is readable by anyone standing behind the person typing it. That is a
/// real cost and it is why this is **off by default, every single time**.
///
/// What makes it acceptable is that nothing is revealed without a deliberate
/// tap, by the person who already knows the passcode, at a moment they chose.
/// The alternative — no way to check — does not remove the risk so much as
/// move it: somebody who cannot see what they typed types it wrong, and
/// `attempt_limiter.dart` starts counting failures towards a cooldown on a
/// person who knows their own passcode perfectly well. Every serious app that
/// asks for a secret on a phone keyboard offers this, and they are right to.
///
/// **It resets to hidden whenever the field is left.** The state lives in this
/// widget rather than in a setting, so it cannot be left permanently on and
/// forgotten about — walking away and coming back gives dots again.
///
/// One thing worth being honest about: with *Settings → Allow screenshots* on,
/// `FLAG_SECURE` is cleared, so a screen recording running at that moment could
/// capture a revealed passcode. That is the documented cost of that switch
/// rather than of this button, and it is the same trade Signal makes under
/// "Screen security".
class LampPasscodeField extends StatefulWidget {
  const LampPasscodeField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<LampPasscodeField> createState() => _LampPasscodeFieldState();
}

class _LampPasscodeFieldState extends State<LampPasscodeField> {
  /// Hidden until asked, and hidden again next time this field is built.
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final controller = widget.controller;
    return TextField(
      controller: controller,
      obscureText: !_revealed,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      // Never the OS suggestion strip, never autocorrect, never a keyboard that
      // learns the passcode. `visiblePassword` is the type that opts out of all
      // three on Android.
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      onSubmitted: widget.onSubmitted,
      style: t.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: c.inkMuted),
        filled: true,
        fillColor: c.surface,
        // ISSUE 5. `ValueListenableBuilder` on the controller so the eye is
        // absent until there is something to reveal — an eye over an empty
        // field is a control that does nothing, which is the defect this whole
        // round is largely about.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: widget.enabled
                  ? () => setState(() => _revealed = !_revealed)
                  : null,
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              color: c.inkMuted,
              // Says what the tap will do, not what the state is. A screen
              // reader announcing "hidden" leaves the user to guess whether
              // that is a description or a button.
              tooltip: _revealed ? 'Hide passcode' : 'Show passcode',
            );
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.x4, vertical: Space.x4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.borderHair),
        ),
      ),
    );
  }
}

/// A bar the page shows through. **ISSUE G — "bring glass effect (just a
/// little)".**
///
/// ── WHAT IT IS FOR, WHICH IS NOT DECORATION ──────────────────────────────
///
/// He asked for *"paper effect, glass effect (just a little), skeuomorphism"*,
/// carefully, and named what it must not cost: accessibility, usability,
/// responsiveness, functionality, speed, aesthetics, trust, familiarity, core.
/// That list is the specification, not a caveat on it.
///
/// The reason glass earns a place here is that ISSUE 1 has just put a **ruled
/// page** behind the day. An opaque bar sitting on a ruled page cuts the lines
/// dead at its edge and reads as a separate panel bolted over the top; the same
/// bar with the page faintly visible through it reads as *resting on* the page.
/// Glass is what makes the paper continue underneath, which is the whole point
/// of having put paper there.
///
/// ══ ROUND EIGHT — HE ASKED FOR MORE OF IT, AND HE CAN HAVE IT ════════
///
/// He circled the whole capture bar and wrote three things around it: *"Give
/// this section little transparency — The Background"*, *"A little
/// glassmorphism can be used here"*, and *"Can look cool and also stay in our
/// app's aesthetics"*.
///
/// **An 18-sigma blur and a surface running 66% to 52% down its face**, up from
/// 12-sigma at 88/78. The comment that used to be here argued against exactly
/// this, and gave a reason: at a phone control centre's strength *"writing
/// shows through the bar it sits behind"*. That reason was true when it was
/// written and it is not true now, and it is worth being precise about why
/// rather than simply turning the number up.
///
/// **Nothing passes behind this bar.** It is a sibling of the day's `PageView`
/// in a `Column`, not a layer over it — the stream is laid out *above* it and
/// stops dead at its top edge. So the only thing a `BackdropFilter` here can
/// sample is `PaperGround`: the page's own tone, the lamp, a ruling, and since
/// ISSUE 7C the sky. There is no writing behind it to show through, and there
/// never was; the risk that number was defending against belongs to a layout
/// this screen does not have.
///
/// The contrast arithmetic is in `test/design/glass_test.dart`, because "it
/// looks fine" is not something to leave unstated about a bar with labels on
/// it. The composite of a 52%-opaque surface over the canvas is within a point
/// or two of the surface itself, so `inkMuted` keeps its 5.48:1 and nothing on
/// the bar moves. **If a future change ever does put content behind this bar,
/// that test is what fails, and the number goes back up.**
///
/// ── THE SPEED CLAUSE, WHICH IS THE ONE THAT BITES ────────────────────────
///
/// `BackdropFilter` is the most expensive widget in Flutter: it forces a
/// saveLayer and re-blurs its backdrop **every frame it is on screen**, and
/// this app is judged on a Redmi Pad. Three things keep it honest:
///
///   * **Only two of these exist**, and both are short bars a few dozen points
///     tall. The cost is proportional to blurred area, and this is a few per
///     cent of the screen rather than all of it.
///   * **`ClipRect` is not optional.** Without a clip the filter samples the
///     entire layer tree beneath it rather than the strip it occupies, which
///     is the difference between a cheap effect and a dropped frame.
///   * **It turns itself off** when the platform asks for reduced transparency
///     or reduced motion, falling back to the opaque bar that was there before.
///     `ACCESSIBILITY.md` treats those as instructions rather than hints, and
///     somebody who has asked their phone for less of this has asked us too.
class LampGlass extends StatelessWidget {
  const LampGlass({
    super.key,
    required this.child,
    this.border,
    this.radius = BorderRadius.zero,
    this.topAlpha = defaultTopAlpha,
    this.bottomAlpha = defaultBottomAlpha,
    this.blur = 7,
  });

  /// ══ HOW SOLID THE PANE IS, AND WHY THESE TWO NUMBERS ARE NAMED ═══════════
  ///
  /// They used to be literals in the constructor's default arguments, and
  /// `test/design/glass_test.dart` kept **its own copies** of them with a
  /// comment saying that if they change here they must be changed there too.
  /// That is a drift waiting to happen, and it is a bad kind: the test would go
  /// on passing while measuring numbers the app had stopped using. Named here,
  /// imported there, so the contrast arithmetic is done against the glass that
  /// actually ships.
  ///
  /// **Lowered from 0.66/0.52 on 28 August 2026**, at his request — *"needs to
  /// be little translucent not so opaque"*. Round eight had already asked for
  /// *"a little transparency"* and got a pane you could not really see through.
  ///
  /// ══ ROUND FIFTEEN, ISSUE 6 — THE KNOB WAS NEVER CONNECTED TO ANYTHING ══
  ///
  /// > *"WHEREVER YOU HAVE USED GLASSMORPHISM - PLEASE MAKE THE GLASS A LIL
  /// > TRANSCLUCENT - I NEED IT TO BE A LIL SEE THROUGH A LIL!"*, and in red
  /// > round the capture bar: *"give me glass like feel"*.
  ///
  /// He asked for this in round eight, again on 28 August, and again now.
  /// Three times is not somebody being fussy — it is the change not having
  /// happened, and the note that used to sit here is why.
  ///
  /// It read: *"`surface` and `canvas` are one step apart, so letting more
  /// canvas through moves the composited colour by a hair."* Every word of
  /// that is true. **It is 1.07:1** — they are the same colour for any
  /// practical purpose. Which means lowering this alpha cannot make the bar
  /// look more see-through, whatever it is lowered to: both sides of the mix
  /// are the same near-black. An accurate description of why the change would
  /// have no effect was written down twice and read both times as a reassurance
  /// that the change was safe.
  ///
  /// The thing a person can actually see through this pane is not the canvas
  /// colour. It is the **page** — the stars, the constellation lines, the
  /// lamp, the grain, the ruling. `PaperGround` is full-bleed and does run
  /// underneath the bar, so all of it is genuinely back there. It was being
  /// erased by [blur], and that is where this round's fix is.
  ///
  /// These come down as well, because now that there is something behind the
  /// glass the alpha decides how much of it survives. `glass_test.dart` holds
  /// the arithmetic proving the labels still clear AA — it rejected a
  /// hand-picked pair once already, so do not adjust these by eye.
  static const double defaultTopAlpha = 0.30;
  static const double defaultBottomAlpha = 0.16;

  final Widget child;

  /// The hairline that separates the bar from the page, if it has one.
  final BorderSide? border;

  /// Rounded, for a panel that floats. Square for a bar welded to an edge.
  ///
  /// **ROUND NINE, ISSUES 10 AND 25 — one glass, in two places.**
  ///
  /// > *"Make this section a little glass like feeling"* — round the capture
  /// > bar. And: *"This part GLASSMORPHISM — make it better, keep our app's
  /// > aesthetics and core value in our head"* — round the video player's
  /// > controls.
  ///
  /// Two requests, one week apart, about two panels that were being built
  /// separately and were already drifting: the bar had a lit top edge and the
  /// video panel had a flat fill and a hairline round it. Two pieces of glass
  /// in one app that are not the same glass is worse than one piece of it that
  /// is slightly wrong, so there is one now, and this is the parameter that
  /// lets it be both shapes.
  final BorderRadius radius;

  /// How solid the pane is at its top and at its foot.
  ///
  /// A pane is not one flat alpha. The default pair is the capture bar's, and
  /// `test/design/glass_test.dart` holds the arithmetic proving the words on it
  /// still clear AA at the thinner end — it rejected a hand-picked pair once
  /// already, so do not adjust these by eye.
  final double topAlpha;
  final double bottomAlpha;

  /// How far the backdrop is blurred.
  ///
  /// **The trap, and it is the reason this has a knob at all:** `BackdropFilter`
  /// costs by blurred *area*, not by sigma — so a bigger number is nearly free
  /// and a bigger rectangle is not. Blur the smallest thing that works, and
  /// never put one inside a scrolling list.
  ///
  /// ══ SEVEN, NOT EIGHTEEN. ROUND FIFTEEN, ISSUE 6 ═══════════════════
  ///
  /// **This number was the whole of "the glass is not see-through".**
  ///
  /// A Gaussian blur of standard deviation sigma multiplies a feature of
  /// wavelength L by `exp(-2 pi^2 sigma^2 / L^2)`. Put the page's own scales
  /// through that:
  ///
  ///     feature              sigma 18     sigma 7
  ///     a star (4pt)            0.00%       0.00%
  ///     fine grain (12pt)       0.00%       0.12%
  ///     a fold (24pt)           0.00%      18.65%
  ///     a rule gap (40pt)       1.84%      54.63%
  ///     the lamp (160pt)       77.89%      96.29%
  ///
  /// At eighteen, **everything smaller than the bar itself was gone.** What
  /// was left was the page's average colour, which is `canvas`, which is
  /// within 1.07:1 of the colour the pane is tinted with — so the bar
  /// composited to a flat rectangle a shade off the page, which is what an
  /// opaque bar looks like. That is why two rounds of lowering [defaultTopAlpha]
  /// changed nothing anybody could see.
  ///
  /// At seven the fine detail still goes — a star is a point and a point still
  /// smooths away, which is what keeps this frosted rather than a window — and
  /// the structures somebody recognises as *the page* survive: the
  /// constellation lines, the lamp's pool of light, the folds, the ruling.
  ///
  /// It is also cheaper. `test/design/glass_test.dart` pins the attenuation
  /// rather than the number, so raising it back has to argue with the page.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final media = MediaQuery.of(context);

    // Somebody who has turned this off at the OS gets the solid bar. Not a
    // degraded version of the effect — no effect.
    final plain = media.disableAnimations || media.highContrast;

    // ── ISSUE 8 — glass that reads as glass ──────────────────────────────
    //
    // *"Where is skeuomorphism? Glassmorphism?"* The blur was already here; the
    // thing that was missing is the part that makes a blurred panel read as a
    // *pane* rather than as a smudge. Real glass catches light along its top
    // edge, and a very slight gradient down its face.
    //
    // Both are a fraction of a per cent, and neither is a shadow —
    // `DESIGN-SYSTEM.md` bans those, and that ban is a large part of why this
    // app does not look like every other one. Depth here is a surface step and
    // an edge, which is how a pane of glass is actually lit.
    final face = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      // Top edge more solid than the bottom: light falls on a pane from above,
      // and the foot of the bar is where the page has most to say for itself.
      colors: [
        c.surface.withValues(alpha: topAlpha),
        c.surface.withValues(alpha: bottomAlpha),
      ],
    );

    final rounded = radius != BorderRadius.zero;

    // ── The lit rim, on a panel that floats. ISSUE 25 ──────────────────────
    //
    // *"Make it better."* What was missing is what makes a blurred rectangle
    // read as a **pane** rather than as a smudge: real glass catches light
    // along its edge, brightest where it faces the lamp and fading round to
    // where it does not.
    //
    // A `Border.all` cannot do that — it is one colour the whole way round, and
    // one colour the whole way round is an outline, which is exactly what round
    // eight removed from this panel for making it read as a box.
    //
    // So the rim is a **gradient**: the panel is drawn twice, the outer one
    // filled top-to-bottom from a bright ink to almost nothing, and the inner
    // one inset by a single pixel with the glass face on it. What shows in that
    // one pixel is a rim that is lit at the top and gone by the bottom. It is a
    // trick and it is the cheapest correct one — no shader, no second layer,
    // and it clips with the same radius as everything else.
    final Widget body = rounded
        ? Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: plain
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.inkPrimary.withValues(alpha: 0.20),
                        c.inkPrimary.withValues(alpha: 0.02),
                      ],
                      stops: const [0.0, 0.55],
                    ),
              color: plain ? c.surface : null,
            ),
            padding: plain ? EdgeInsets.zero : const EdgeInsets.all(1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: plain ? null : face,
                color: plain ? c.surface : null,
              ),
              child: child,
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              border: border == null ? null : Border(top: border!),
              gradient: plain ? null : face,
              color: plain ? c.surface : null,
            ),
            child: plain
                ? child
                : Stack(
                    children: [
                      child,
                      // The light along the top edge. One logical pixel, drawn
                      // over the hairline so the two read as one lit edge
                      // rather than as two lines. A bar welded to the bottom of
                      // the screen has only one edge that can catch anything;
                      // the rim treatment above would put a line down the
                      // screen's own sides.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          // Raised again with the transparency, **ISSUE 6**.
                          // A lit edge is what tells the eye where a pane of
                          // glass starts, and the more you can see through
                          // something the more it needs one. At 16% at the
                          // foot this is now most of what says where the bar
                          // begins.
                          color: c.inkPrimary.withValues(alpha: 0.14),
                        ),
                      ),
                    ],
                  ),
          );

    if (plain) return body;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        // Seven, not eighteen. Eighteen erased 98% of everything on the page
        // at the scale a person can see, which is why the bar read as opaque
        // however transparent it was made. **ISSUE 6** — the arithmetic is
        // on [blur].
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: body,
      ),
    );
  }
}

/// The one sheet. **`PLAN.md` §9.7, and `Honest Review`'s small list.**
///
/// > *"Four hand-rolled bottom sheets with four slightly different paddings."*
///
/// Ten of them by the time anybody counted, and the drift was exactly the kind
/// nobody notices in one place and everybody feels across ten: some set their
/// own background and some did not, so a sheet was `surface` on one screen and
/// Material's default on the next; some were `isScrollControlled` and the rest
/// would clip their own last row at 200% text; the top padding ranged from
/// `Space.x4` to `Space.x6` depending on which one had been copied.
///
/// **None of that is a bug and all of it is the same fault**: a component that
/// existed as a habit rather than as a thing. This is the thing.
///
/// ── WHAT IT SETTLES, AND WHY EACH ONE MATTERS ──────────────────────────────
///
///   * **`surface`, always.** A sheet is one step above the page. Letting
///     Material choose meant it sometimes was not.
///   * **`isScrollControlled`, always.** Without it a sheet is capped at half
///     the screen and a long one silently loses its bottom row — which at 200%
///     text is most of them, and the row it loses is the one people came for,
///     because the destructive action is always last.
///   * **`SafeArea` and a scroll view, always**, for the same reason.
///   * **One title, one divider, one set of paddings.**
///
/// It deliberately does **not** take a list of options and build them. The
/// sheets in this app hold genuinely different things — a choice, a form, a
/// picker with a live query behind it — and a component that tried to own all of
/// that would be a worse `showModalBottomSheet`. It owns the frame; the caller
/// owns what is in it.
Future<T?> showLampSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,

  /// Whether tapping away or dragging down closes it.
  ///
  /// True everywhere except the one place it must not be: the sheet that says
  /// what a passcode change did and did not do — see `ChangePasscodeScreen` —
  /// because that is a moment somebody will not come back to.
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.lamplight.surface,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    builder: (sheet) {
      final c = sheet.lamplight;
      final t = Theme.of(sheet).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      Space.x6, Space.x5, Space.x6, Space.x4),
                  child: Text(title, style: t.titleLarge),
                ),
                Divider(height: 1, color: c.borderHair),
              ] else
                const SizedBox(height: Space.x5),
              builder(sheet),
              const SizedBox(height: Space.x4),
            ],
          ),
        ),
      );
    },
  );
}

/// An error the user has to be able to act on.
///
/// Icon plus colour plus words — three channels. `ACCESSIBILITY.md` requires
/// that an error says what happened, why, and what to do next, and that it
/// never relies on the colour red to be noticed.
class LampError extends StatelessWidget {
  const LampError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: c.danger),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(message,
                style: t.bodyLarge?.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  }
}

/// Something was refused, and the screen says so by moving.
///
/// **A wrong passcode must not look like a slow one.** Both used to put a line
/// of text on the screen, and a person who has just typed a long passphrase
/// cannot tell "still thinking" from "no" without reading — which is the moment
/// they are least inclined to read.
///
/// So a refusal is a *shake*: the same motion a head makes, the same motion
/// every lock in every film makes, and one that carries no meaning except "not
/// that". It is over in 400ms, it never blocks input, and it is accompanied by
/// a heavier haptic than any success in the app — because being told no in the
/// dark, one-handed, should not require looking.
///
/// Under `prefers-reduced-motion` the shake does not happen; the message and
/// the haptic still do. Nobody loses the information, only the movement.
class LampShake extends StatefulWidget {
  const LampShake({super.key, required this.trigger, required this.child});

  /// Bump this to shake. A counter rather than a bool, so two refusals in a row
  /// shake twice — with a flag the second one would be a no-op and the screen
  /// would sit there having apparently accepted a passcode it did not.
  final int trigger;

  final Widget child;

  @override
  State<LampShake> createState() => _LampShakeState();
}

class _LampShakeState extends State<LampShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(LampShake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) {
      HapticFeedback.heavyImpact();
      if (!MediaQuery.disableAnimationsOf(context)) {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        if (!_c.isAnimating) return child!;
        // Three diminishing swings. A damped sine rather than a constant one:
        // a shake that ends at full amplitude looks like a dropped frame.
        final decay = 1 - _c.value;
        final offset = math.sin(_c.value * math.pi * 6) * 11 * decay;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

