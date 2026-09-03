import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

import '../core/security/passcode_rules.dart';
import 'tokens.dart';

/// What a passcode needs, said while it is being typed.
///
/// ── WHY THIS IS NOT A COLOURED BAR ───────────────────────────────────────
///
/// The universal answer here is a five-segment meter that goes red-amber-green,
/// and it is bad in three specific ways:
///
///  1. **It implies a measurement nobody has made.** "60% strong" is not a
///     property of a password. It is a number a heuristic made up, and users
///     correctly learn to game it — `Password1!` scores green everywhere and is
///     in every cracking dictionary.
///  2. **It relies on colour alone**, which `DESIGN-SYSTEM.md` bans outright,
///     and green-vs-red is the exact pair the commonest colour blindness
///     cannot separate.
///  3. **It tells you the score and not the fix.** Somebody looking at an amber
///     bar knows they have failed and does not know what to do about it, which
///     is the definition of a bad error message.
///
/// So this says the requirement, ticks it when it is met, and names the
/// strength in **words**. The tick is the signal; the accent is emphasis on the
/// tick. Turn the screen greyscale and nothing is lost.
///
/// It never blocks on anything except length and the short list of guessable
/// choices — see `PasscodeRules` for why composition rules make passwords
/// worse rather than better.
class PasscodeMeter extends StatelessWidget {
  const PasscodeMeter({
    super.key,
    required this.passcode,
    this.confirm,
  });

  final String passcode;

  /// The second field, if there is one. `null` while it does not apply.
  final String? confirm;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    // Nothing typed yet: the requirement, stated once, quietly. Not an error —
    // an empty field somebody has not reached yet has not failed at anything.
    if (passcode.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.x3),
        child: Text(
          L.of(context).passcodeRuleWords,
          style: t.labelMedium?.copyWith(color: c.inkMuted),
        ),
      );
    }

    final problems = PasscodeRules.problems(passcode, L.of(context));
    final strength = PasscodeRules.strengthOf(passcode);
    final mismatch =
        confirm != null && confirm!.isNotEmpty && confirm != passcode;

    return Padding(
      padding: const EdgeInsets.only(top: Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The one hard requirement, as a checklist row.
          _Check(
            met: passcode.length >= PasscodeRules.minimumLength,
            label: L.of(context).passcodeAtLeastShort(
                PasscodeRules.minimumLength),
          ),
          if (problems.isNotEmpty)
            for (final p in problems.skip(
                passcode.length < PasscodeRules.minimumLength ? 1 : 0))
              Padding(
                padding: const EdgeInsets.only(top: Space.x1),
                child: _Check(met: false, label: p),
              ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: Space.x1),
              child: _Check(met: false, label: L.of(context).passcodeNoMatch),
            ),
          if (problems.isEmpty) ...[
            const SizedBox(height: Space.x2),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Text(
                    strength.label,
                    style: t.labelMedium?.copyWith(
                      color: strength.rank >= PasscodeStrength.good.rank
                          ? c.good
                          : c.inkSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: Space.x2),
                  if (strength.rank < PasscodeStrength.strong.rank)
                    Expanded(
                      child: Text(
                        // Advice, not a refusal. Everything from here up is
                        // already acceptable; this only says what would make
                        // it better, and it says how rather than that.
                        L.of(context).passcodeRuleStronger,
                        style: t.labelSmall?.copyWith(color: c.inkMuted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '${met ? L.of(context).checkDone : L.of(context).checkNotYet}: $label',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 16,
            color: met ? c.good : c.inkMuted,
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(
              label,
              style: t.labelMedium?.copyWith(
                color: met ? c.inkSecondary : c.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
