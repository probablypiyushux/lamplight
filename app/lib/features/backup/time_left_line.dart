import 'package:flutter/material.dart';

import '../../core/progress/time_remaining.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// One quiet line under a progress bar: how much longer this has to run.
///
/// > *"On the place where the loading happens before uploading use - Time
/// > Remaining on long jobs"*
///
/// Shared by the backup, the restore, the readable copy and the journal
/// import, so that the five long jobs in the app say this the same way. The
/// arithmetic and the honesty rules are in [TimeRemaining]; this is only the
/// sentence.
///
/// **It renders nothing at all when there is no honest estimate**, which is
/// the first two seconds of every job and the whole of every short one. That
/// is deliberate and is why it is a `SizedBox.shrink` rather than a placeholder
/// or a dash: a row that appears, says "calculating…", and is replaced two
/// seconds later is a row that moved the layout twice to tell you nothing.
///
/// Because it can appear after the bar has been on screen for a moment, it
/// reserves no height and simply fades in. `Semantics(liveRegion:)` is left to
/// the caller, which already announces the percentage — two live regions
/// arguing over one progress bar makes a screen reader unusable.
class TimeLeftLine extends StatelessWidget {
  const TimeLeftLine({super.key, required this.estimate});

  final TimeRemaining estimate;

  @override
  Widget build(BuildContext context) {
    final remaining = estimate.remaining;
    if (remaining == null) return const SizedBox.shrink();

    final rounded = TimeRemaining.humanise(remaining);
    final l = L.of(context);
    final text = rounded.inSeconds < 60
        ? l.etaSeconds(rounded.inSeconds)
        : l.etaMinutes(rounded.inMinutes);

    return Padding(
      padding: const EdgeInsets.only(top: Space.x2),
      child: AnimatedOpacity(
        opacity: 1,
        duration: Motion.duration(context),
        child: Text(
          text,
          // A muted label, not body copy. This is an aside about the machine,
          // not something the user has to read.
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: context.lamplight.inkMuted),
          // Never announced separately — the caller's Semantics already says
          // the percentage, and this changing every second would talk over it.
          semanticsLabel: '',
        ),
      ),
    );
  }
}
