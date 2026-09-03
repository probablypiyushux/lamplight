import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/vault/vault.dart';
import '../../design/tokens.dart';

/// The few seconds' notice before the app locks itself. **ISSUE 21.**
///
/// ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
///
/// > *"APP AUTO CLOSES — WHILE I AM WATCHING AT IT CLOSES — A GOOD FEATURE BUT
/// > SAY ME HOW TO TAME IT!"*
///
/// Read that twice, because both halves are unusual. He is not asking for the
/// idle lock to go away — he calls it a good feature. He is asking to be told
/// how to live with it. And underneath that is the thing he did not have to
/// say: **he thought the app was crashing.** It is filed in the same document
/// as "app feels so slow", not under settings, because from where he was
/// sitting there is no difference between an app that locked itself and an app
/// that fell over. Both are: what you were reading is gone, and nobody said
/// why.
///
/// A lock that announces itself first is a different experience of identical
/// behaviour. It stops being something done *to* you, it becomes something you
/// can decline, and it names the setting at the one moment anybody would care
/// enough to go and change it.
///
/// ── WHAT IT DELIBERATELY DOES NOT DO ────────────────────────────────────────
///
/// It does not extend the timeout by a single millisecond. The lock happens at
/// the instant it always would have; this only makes the last twenty seconds of
/// it visible. `UX-FLOWS.md` flow 7 is not being renegotiated — and a warning
/// that quietly bought itself extra time would be renegotiating it in the one
/// way nobody would notice.
///
/// It does not block anything either. Tapping anywhere on the screen already
/// calls `touch()` — see the `Listener` in `app.dart` — so this cannot trap
/// somebody: any interaction at all dismisses it, and the button is a
/// convenience rather than the only way out.
class AboutToLock extends StatelessWidget {
  const AboutToLock({super.key, required this.vault, required this.child});

  final Vault vault;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: vault.aboutToLock,
            builder: (context, soon, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              // Grows out of the bottom edge rather than fading in over the
              // page. A fade at the bottom of a page of text reads as part of
              // the text arriving; a slide reads as something new.
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.bottomCenter,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: soon
                  ? _Notice(
                      key: const ValueKey('about-to-lock'),
                      seconds: vault.warningWindow.inSeconds,
                      onStay: vault.touch,
                    )
                  : const SizedBox.shrink(key: ValueKey('nothing')),
            ),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.seconds, required this.onStay});

  final int seconds;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Space.x4, Space.x2, Space.x4, Space.x4),
        child: Material(
          color: c.raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg),
            side: BorderSide(color: c.borderHair),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.x4, Space.x3, Space.x2, Space.x3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // Not a live countdown. A number ticking down is a
                        // pressure device, and `ETHICAL-DESIGN.md` is short
                        // with those — it would also mean a rebuild a second
                        // for a message that says the same thing throughout.
                        L.of(context).lockWarnSeconds(seconds),
                        style: t.bodyMedium?.copyWith(color: c.inkPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Where to change it, in the words the settings screen
                        // actually uses, so the sentence is a route and not a
                        // vague gesture at "settings somewhere".
                        L.of(context).lockWarnChange,
                        style: t.labelMedium?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onStay,
                  child: const Text("I'm still here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
