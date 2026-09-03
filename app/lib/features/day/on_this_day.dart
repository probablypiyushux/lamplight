import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../design/tokens.dart';

/// "Three years ago today."
///
/// ── THE ONE ENGAGEMENT FEATURE THIS APP IS ALLOWED ───────────────────────
///
/// `PLAN.md` §3 spends a page arguing that the honest way to make somebody
/// open a private journal for years is not a streak, a badge, a red dot or a
/// notification. Every one of those works by making *not* opening the app
/// uncomfortable, and every one of them is banned by `ETHICAL-DESIGN.md` §1.
///
/// The thing that actually works, and is not manipulation, is **their own
/// forgotten writing**. The strongest emotional response anybody has to their
/// own records is to material they had forgotten making. Nothing else in this
/// app can produce that feeling, and it is produced entirely from content the
/// user made, which is what makes it honest rather than a mechanism.
///
/// ── THE FOUR RULES IT OBEYS ──────────────────────────────────────────────
///
///  1. **It waits; it never summons.** No notification, ever. It is here when
///     you open the app and it is not anywhere else.
///  2. **Silence on a day with no history.** No "nothing from last year",
///     which would be an app pointing at a gap in somebody's life. Absence is
///     absence.
///  3. **One entry, one line.** Not a carousel, not "your memories". A single
///     quiet card that you either tap or scroll past.
///  4. **It never counts anything.** No "you have written 47 times in August".
///     The moment it starts measuring, it is scoring the user.
class OnThisDayCard extends StatelessWidget {
  const OnThisDayCard({
    super.key,
    required this.history,
    required this.repository,
    required this.onOpen,
  });

  /// Resolved once by the day that owns it, not per rebuild.
  final Future<List<Entry>> history;
  final EntryRepository repository;
  final void Function(DateTime day) onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Entry>>(
      future: history,
      builder: (context, snap) {
        final entries = snap.data;
        // Rule 2: nothing at all rather than an empty state. Also nothing
        // while the query is in flight, so the card never flashes in and
        // pushes the day down after it has been read.
        if (entries == null || entries.isEmpty) return const SizedBox.shrink();
        return _Card(entry: entries.first, onOpen: onOpen);
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.entry, required this.onOpen});

  final Entry entry;
  final void Function(DateTime day) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    final parts = entry.dayKey.split('-');
    final day = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final years = DateTime.now().year - day.year;
    final when = years == 1
        ? L.of(context).onThisDayOneYear
        : L.of(context).onThisDayYears('$years');
    final body = (entry.body ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: Space.x5),
      child: Semantics(
        button: true,
        label: L.of(context).onThisDaySemantic(when, body),
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onOpen(day),
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              // A hairline rather than a fill in the accent. This card is a
              // door, not an announcement, and an accent-filled panel at the
              // top of every day would be shouting once a week for years.
              border: Border.all(color: c.borderHair),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 15, color: c.accent),
                    const SizedBox(width: Space.x2),
                    Flexible(
                      child: Text(
                        when.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.x3),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: writingStyle(context)
                      .copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
