import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// What an entry used to say. **`PLAN.md` §9.6.**
///
/// ══ THE ROWS WERE WRITTEN AND UNREACHABLE ══════════════════════════════════
///
/// > *"Revision history UI — the rows are written and unreachable."*
///
/// `Revisions` has been in the schema since version 1 and
/// `EntryRepository.updateBody` has been filling it in ever since. The vault
/// has been paying to store every earlier version of every entry, in the
/// backup, in the export, for months — and giving none of it back. That is the
/// worst shape a feature can be in: all of the cost and none of the value.
///
/// ── WHY IT READS AND DOES NOT RESTORE ──────────────────────────────────────
///
/// There is no *"put it back"* button, and that is a decision rather than a
/// missing half.
///
/// Restoring would have to write the current text as a new revision before
/// overwriting it — otherwise the button destroys the thing it is meant to
/// protect against destroying — and then the list contains both the version you
/// came from and the one you went to, twice, and a journal has quietly become
/// something with a history you can get lost in.
///
/// What somebody actually wants here is to **read what they wrote before**, and
/// usually to copy a sentence out of it. So the text is selectable and that is
/// the whole interface. If a real need for restoring turns up, this comment is
/// where to start, and the first thing to settle is the double-write above.
///
/// ── AND WHY IT IS NOT ON EVERY ENTRY ───────────────────────────────────────
///
/// The row only appears when there is something to show. An entry written once
/// and never touched has no revisions, and offering *"Earlier versions"* on it
/// would be a menu item that opens an empty sheet — which is the same defect as
/// silence, one politeness removed.
Future<void> showRevisions({
  required BuildContext context,
  required EntryRepository repository,
  required Entry entry,
}) async {
  final revisions = await repository.revisionsFor(entry.id);
  if (!context.mounted || revisions.isEmpty) return;

  await showLampSheet<void>(
    context: context,
    title: L.of(context).entryEarlierVersions(revisions.length),
    builder: (sheet) {
      final c = sheet.lamplight;
      final t = Theme.of(sheet).textTheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.x6, Space.x4, Space.x6, Space.x2),
            child: Text(
              L.of(context).revisionsNote,
              style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.5),
            ),
          ),
          for (final revision in revisions) ...[
            Divider(height: 1, color: c.borderHair),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x4, Space.x6, Space.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_when(context, revision.savedAt),
                      style: t.labelSmall?.copyWith(color: c.inkMuted)),
                  const SizedBox(height: Space.x2),
                  SelectableText(
                    revision.body,
                    style: t.bodyMedium
                        ?.copyWith(color: c.inkSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// `4 March, 09:12`.
///
/// The day as well as the time, because an entry edited over a week has
/// revisions on different days and the time alone would put them in an order
/// nobody could read. No year: these are all recent by construction — a
/// revision belongs to an entry somebody is looking at now.
String _when(BuildContext context, int millis) {
  final at = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
  // The clock came from `padLeft(2, '0')`, which is 24-hour for everybody.
  // `LampDates.time` asks intl, so a reader whose language uses a 12-hour
  // clock gets one.
  return '${LampDates.dayAndMonth(context, at)}, '
      '${LampDates.time(context, at)}';
}
