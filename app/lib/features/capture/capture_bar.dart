import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../design/components.dart';
import '../../design/tokens.dart';

/// The capture bar: **🎙 voice · 📷 photo · 📎 file**.
///
/// `UX-FLOWS.md` flow 2 specifies it "always visible at thumb height", with
/// four targets each at least 48×48. That is the whole navigation model for
/// capture — no plus button that opens a menu that opens a sheet, no "what
/// would you like to add?". Always there, one tap each.
///
/// ── WHY THERE ARE THREE NOW AND NOT FOUR. ISSUE 9 + 14 ───────────────────
///
/// **This is a deliberate deviation from `UX-FLOWS.md` flow 2, which says
/// four.** `CLAUDE.md` requires that to be said out loud rather than done
/// quietly, so: the pencil is gone, and the doc is being changed to match
/// rather than the other way round.
///
/// The pencil's only job was to focus the composer, and the composer was a
/// field pinned above this bar. Round five moved the caret onto the page —
/// *"typing doesn't feel like writing on any kind of notes app"* — and writing
/// now starts the way it starts in every notes app on the phone: by tapping the
/// page. A button whose entire function is "put the cursor in the thing you can
/// already see and tap" is the kind of control that makes an interface feel
/// like a form.
///
/// The other three stay, because voice, photo and file genuinely cannot be
/// started by tapping the page. They are the things that need a button.
///
/// WHY THE ICONS ARE NOT EMOJI
///
/// The specification writes them as ✎ 🎙 📷 📎 because that is the clearest way
/// to write them in a document. In the app they are Material glyphs, because
/// the workspace bans emoji as UI icons and it is right to: an emoji is a font
/// that changes with the OS version, renders in someone else's colour palette,
/// and is announced by a screen reader as "pencil" in whatever language the
/// font vendor chose. Every one of these carries a real tooltip and a real
/// semantic label instead.
class CaptureBar extends StatelessWidget {
  const CaptureBar({
    super.key,
    required this.onVoice,
    required this.onPhoto,
    required this.onFile,
  });

  final VoidCallback onVoice;
  final VoidCallback onPhoto;
  final VoidCallback onFile;

  // ── ISSUE 13 — there is no way to switch these off any more ──────────────
  //
  // This used to take `busy` and `progress`. `busy` greyed out all three
  // buttons for the whole of an import, which is his complaint verbatim:
  // *"when one file is uploading I can't upload another — not even record
  // voice, take photo, use gallery to upload or choose other file!"*
  //
  // The parameter is **gone** rather than passed `false`, and that is the
  // point: a flag that exists is a flag somebody sets. The queue absorbs a
  // second pick — see `ImportQueue`, which is still strictly sequential
  // underneath for the rule-2 reason written there — so there is no longer any
  // state in which disabling these would be correct.
  //
  // The little progress line that used to sit along the top went with it.
  // `ImportStrip`, directly above this, says which file and how far, which is
  // more than two pixels of accent could and is where he asked for it.

  @override
  Widget build(BuildContext context) {
    // ISSUE 1 + G. Glass, so the ruled page carries on under the bar instead
    // of stopping dead at its edge. No shadow anywhere — DESIGN-SYSTEM.md:
    // depth comes from the surface step and from a lit edge.
    // ── ISSUE 10, asked twice ──────────────────────────────────────────────
    //
    // > *"Make this section a little glass like feeling"*, circled round this
    // > bar — and round eight had already made it glass.
    //
    // What it was still missing is the difference between a **pane** and a
    // slab: the bar was welded across the bottom of the screen with square
    // corners and a hairline over the top, which is a wall, not a piece of
    // glass lying on a page. Rounding the top two corners is the whole change
    // and it moves nothing — same height, same place, and the day still stops
    // exactly where the bar starts, which is the fact `glass_test.dart` guards
    // and the reason 52% transparency is safe here at all.
    //
    // The bottom stays square because it is the edge of the screen. The
    // hairline goes because the rounded form brings `LampGlass`'s lit rim with
    // it, and a hairline plus a rim is two lines where the eye wants one edge.
    //
    // **The alphas are not touched.** Round eight tuned them and
    // `test/design/glass_test.dart` holds the contrast arithmetic that rejected
    // a hand-picked pair once already. Wanting more glass is not a reason to
    // guess at numbers a test is checking.
    return LampGlass(
      radius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x4,
                vertical: Space.x2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CaptureButton(
                    icon: Icons.mic_none_outlined,
                    caption: 'Voice',
                    label: L.of(context).captureVoice,
                    onTap: onVoice,
                  ),
                  _CaptureButton(
                    icon: Icons.photo_camera_outlined,
                    caption: 'Photo',
                    label: L.of(context).capturePhoto,
                    onTap: onPhoto,
                  ),
                  _CaptureButton(
                    icon: Icons.attach_file_outlined,
                    caption: 'File',
                    label: L.of(context).captureFile,
                    onTap: onFile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One capture button, with a spring under it.
///
/// `PLAN.md` §8.5: "the capture bar's icons respond to press with a spring,
/// not a ripple". A ripple is Material's answer and it is the wrong one here —
/// it spreads *outward*, which reads as a surface being touched. These are
/// objects being pressed, and an object pressed gets smaller.
///
/// Eight per cent, down in 90 ms and back on a spring. Short enough that it
/// never delays the action it accompanies; distinct enough that the bottom of
/// the app stops feeling like a printed strip.
class _CaptureButton extends StatefulWidget {
  const _CaptureButton({
    required this.icon,
    required this.caption,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// One word under the glyph. **ISSUE 8 and the margin note on the bar.**
  ///
  /// *"No doubt these look best — I want you to improve experience of these."*
  ///
  /// The look was not the problem; three bare glyphs were. A tooltip only
  /// appears on a long press, so the only way to find out what the paperclip
  /// did was to press it and see — which for a control that opens a system
  /// picker means leaving the app to find out. A word under each is what every
  /// current app does with a bottom bar, and it is the single cheapest thing
  /// that turns "improve the experience" into something a person notices.
  final String caption;

  final String label;
  final VoidCallback? onTap;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final enabled = widget.onTap != null;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  HapticFeedback.selectionClick();
                  widget.onTap!.call();
                }
              : null,
          child: AnimatedScale(
            scale: _down && !reduced ? 0.86 : 1.0,
            duration: Duration(milliseconds: _down ? 90 : 260),
            // Overshoot on the way back up, none on the way down. A press is
            // firm; a release is elastic.
            curve: _down ? Curves.easeOut : Curves.elasticOut,
            child: SizedBox(
              // The floor from ACCESSIBILITY.md, as a hit area rather than as a
              // drawn box. The glyph inside is 24; the target around it is 48.
              width: kMinTouchTarget + 16,
              height: kMinTouchTarget + 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── ISSUE 8 — the key under the glyph ──────────────────
                  //
                  // *"Where is skeuomorphism? Glassmorphism? I know you made it
                  // paper feel styled — but I want you to keep our core
                  // aesthetics and also follow a little of modern trend!"*
                  //
                  // This is the smallest honest version of that: a key cap that
                  // appears under the finger. It is a *physical* cue rather
                  // than a Material ripple — the ripple spreads outward, which
                  // reads as a surface being touched, and these are objects
                  // being pressed.
                  //
                  // **No shadow**, because `DESIGN-SYSTEM.md` bans them and
                  // that ban is what keeps this app from looking like every
                  // other one. The depth comes from a surface step and a
                  // hairline catching the light along the top edge, which is
                  // how a real key is lit and costs no blur.
                  AnimatedContainer(
                    duration: Duration(milliseconds: _down ? 90 : 220),
                    curve: Curves.easeOut,
                    width: 38,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _down && !reduced
                          ? c.raised
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: _down && !reduced
                          ? Border(
                              top: BorderSide(
                                color: c.inkPrimary.withValues(alpha: 0.10),
                              ),
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: !enabled
                          ? c.inkMuted
                          : (_down ? c.accent : c.inkSecondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: !enabled
                              ? c.inkMuted
                              : (_down ? c.accent : c.inkMuted),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
