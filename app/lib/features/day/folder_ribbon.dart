import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Where an entry is filed, said on the entry itself. **`PLAN.md` §9.1.**
///
/// ══ WHY THIS EXISTS, AND WHY IT IS NOT A SWIPE ═════════════════════════════
///
/// `PLAN.md` §7.0-E asks for *"swipe an entry to file it"*, with the reason:
/// *"long-press → sheet → tick → Done is four steps for the app's central
/// idea."* The complaint is right. **The gesture it proposes cannot exist in
/// this app**, and it is worth writing down why here rather than discovering it
/// again in six months.
///
/// The day view is a horizontal `PageView` — swiping sideways is how you change
/// day, and `day_screen.dart` deliberately moved the pager *down* so that it
/// contains the day's content and nothing else. A `Dismissible` on an entry
/// installs a `HorizontalDragGestureRecognizer` deeper in the tree than the
/// pager's, and in a Flutter gesture arena the deeper recogniser is swept
/// first: it would win **every** horizontal drag that starts on an entry
/// block. Entry blocks are most of the screen. Swiping between days would stop
/// working over most of the day.
///
/// That is not a trade worth making — it breaks the app's primary navigation to
/// speed up a secondary action — and it is the fourth time gesture arenas have
/// cost this project something, after the photo viewer, the PDF reader and the
/// pencil. `test/widget/filing_test.dart` fails if a horizontal drag recogniser
/// is ever added inside the day's stream, so the next person to try this reads
/// the reason before they read the bug.
///
/// **What was actually wrong is fixed instead**, and in two halves:
///
///   * the picker writes the moment a folder is ticked, so there is no **Done**
///     to forget and no state to lose by walking away;
///   * filing is **visible**. This is that half. Before it, putting an entry in
///     *Kavya* changed nothing you could see — the only way to find out where
///     something was filed was to open the menu, open the picker and read the
///     ticks, which is the app asking you to remember what you told it.
///
/// ── WHY CHIPS AND NOT A LINE OF TEXT ──────────────────────────────────────
///
/// Because they are the way back. Each one opens its folder, so the ribbon is
/// both the answer to *where is this* and the door to *what else is in there* —
/// which is the whole reason folders exist. A sentence would only answer the
/// first.
class FolderRibbon extends StatelessWidget {
  const FolderRibbon({
    super.key,
    required this.names,
    required this.onOpen,
  });

  /// The folders this entry is in, in the order the user arranged them.
  final List<String> names;

  /// Opens one folder by name.
  final void Function(String name) onOpen;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Padding(
      // Hard against the block above it — this belongs to that entry, and a
      // gap would make it read as a row of its own.
      padding: const EdgeInsets.only(
          left: Layout.rail, top: Space.x1, bottom: Space.x2),
      child: Wrap(
        // Wraps rather than scrolls. An entry in six folders is rare and a
        // horizontal scroller inside a vertical list is a gesture conflict
        // waiting to happen — which is the subject of this whole file.
        spacing: Space.x2,
        runSpacing: Space.x1,
        children: [
          for (final name in names)
            Semantics(
              button: true,
              label: L.of(context).folderAlsoIn(name),
              excludeSemantics: true,
              child: Material(
                color: c.raised,
                borderRadius: BorderRadius.circular(Radii.full),
                child: InkWell(
                  onTap: () => onOpen(name),
                  borderRadius: BorderRadius.circular(Radii.full),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.x3, vertical: Space.x1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 12, color: c.inkMuted),
                        const SizedBox(width: Space.x1),
                        Text(
                          name,
                          style: t.labelSmall?.copyWith(color: c.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
