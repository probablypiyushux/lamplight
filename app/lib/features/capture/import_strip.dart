import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../design/tokens.dart';
import 'import_queue.dart';

/// What the app is doing with your files, while it is doing it.
///
/// **ISSUE 12**, and the sentence in **ISSUE 23** that says the same thing in
/// general terms: *"When a process is going on! Give me a visual instead of
/// shutting down!"* — followed, notably, by *"IK you gave the visuals in
/// photos, videos, documents IK good work there!"* He is not asking for a new
/// idea. He is asking for the one the viewers already have, in the one place it
/// was missing.
///
/// ── WHAT IT SAYS, AND WHY IT IS NOT A PERCENTAGE ────────────────────────────
///
/// A percentage would be a claim, and for the case he cares about most it would
/// be a false one. A video is re-encoded before a byte of it is encrypted, and
/// `compressVideo` reports nothing at all while it runs — so the bar would sit
/// at zero for the slow part and then sweep across in a second. That is worse
/// than no bar: it teaches you the number is meaningless.
///
/// So the line names the file and counts the batch — *"Adding IMG_0421.jpg · 2
/// of 5"* — which is true throughout, and the bar underneath is
/// **indeterminate until real bytes are moving**, and only then shows how far
/// they have got. `ETHICAL-DESIGN.md` bans fake progress; this is what obeying
/// that looks like when part of the work genuinely cannot be measured.
class ImportStrip extends StatelessWidget {
  const ImportStrip({super.key, required this.queue});

  final ImportQueue queue;

  @override
  Widget build(BuildContext context) {
    final progress = queue.progress;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: progress == null
          ? const SizedBox(width: double.infinity)
          : _Strip(progress: progress, waiting: queue.pending - 1),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.progress, required this.waiting});

  final ImportProgress progress;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    // "2 of 5" only when there is more than one, because "1 of 1" is noise
    // dressed up as information.
    final counted = progress.total > 1
        ? ' · ${L.of(context).importNthOf('${progress.done + 1}', '${progress.total}')}'
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.raised,
        border: Border(top: BorderSide(color: c.borderHair)),
      ),
      padding: const EdgeInsets.fromLTRB(
          Layout.gutter, Space.x3, Layout.gutter, Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // The filename, because it is the user's own word for the
                  // thing. Not the MIME type, not the size, not the id.
                  L.of(context).importStripCounted(progress.name, counted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(color: c.inkSecondary),
                ),
              ),
              if (waiting > 0) ...[
                const SizedBox(width: Space.x3),
                Text(
                  // ISSUE 13's other half made visible: adding more while this
                  // is running is allowed, so it has to be legible that they
                  // went somewhere.
                  L.of(context).importWaiting(waiting),
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.x2),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.full),
            child: LinearProgressIndicator(
              // Null is the honest answer while nothing measurable is
              // happening, and Flutter draws that as a sweep rather than as a
              // bar sitting at zero — which is the difference between "working"
              // and "stuck", and the whole of what he asked for.
              value: progress.fraction,
              minHeight: 3,
              backgroundColor: c.surface,
              valueColor: AlwaysStoppedAnimation<Color>(c.accent),
            ),
          ),
        ],
      ),
    );
  }
}
