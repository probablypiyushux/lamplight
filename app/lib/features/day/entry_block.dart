import 'dart:async';
import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../design/linked_text.dart';
import '../../design/tokens.dart';

/// One entry on a day, and the editor it turns into when you tap it.
///
/// ══ WHY THIS IS ITS OWN FILE. `Honest Review` ITEM 8 ═══════════════════════
///
/// > *"`day_screen.dart` is 2,147 lines and growing … not tidiness. **Every bug
/// > in this round that took more than one attempt was in a file over a
/// > thousand lines.**"*
///
/// It was 2,477 by 28 August, and the round that wrote that sentence proved it
/// twice over: the composer filing keystrokes under the wrong day, and the
/// entry menu's **Done** landing a third of the way across the screen, were both
/// in there, and both took more than one attempt to see.
///
/// Nothing here changed on the way out. These three classes were the last
/// quarter of that file, they are used by nothing else, and they have no
/// business knowing about page controllers, capture handlers or the import
/// queue — which is the whole argument for the seam being exactly here.

class OpenEditor {
  OpenEditor(this.entryId, String initial, this._repo)
      : controller = TextEditingController(text: initial);

  final String entryId;
  final TextEditingController controller;
  final EntryRepository _repo;
  Timer? debounce;

  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), flushNow);
  }

  /// Write immediately, and **say when it has landed**.
  ///
  /// Called on the way out of the app, where waiting 400 ms means waiting past
  /// the point where the keys still exist.
  ///
  /// ── WHY THIS RETURNS A FUTURE, AND USED NOT TO ────────────────────────────
  ///
  /// It was `void`, and it ended in `unawaited(...)`, which reads as "fire and
  /// forget, the write will land". Since 25 August the database has been on a
  /// **worker isolate**, so that write is a round trip rather than a local
  /// call — and the caller is `didChangeAppLifecycleState` on `inactive`, with
  /// `hidden` following within a frame or two, and `hidden` is where the vault
  /// locks and destroys the keys.
  ///
  /// That is round nine's ISSUE 5 exactly — *"I am recording the voice, someone
  /// enters my room, I close the app, voice doesn't get saved"* — in the entry
  /// editor instead of the recording sheet. The recording was fixed by handing
  /// the lock something to wait for; this had nothing to hand it, because it
  /// discarded the only thing that knew when the write was done.
  Future<void> flushNow() async {
    debounce?.cancel();
    final text = controller.text.trim();
    if (text.isEmpty) return;
    await _repo.updateBody(entryId, text);
  }

  void dispose() {
    debounce?.cancel();
    controller.dispose();
  }
}

/// One entry in the stream.
///
/// **No card, no shadow, no border box.** A 2px accent-tinted left rule, a
/// timestamp in secondary ink, content in primary. Content should look like it
/// is sitting on the page, not inside a container.
class EntryBlock extends StatelessWidget {
  const EntryBlock({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final at = DateTime.fromMillisecondsSinceEpoch(entry.createdAt).toLocal();
    final time = LampDates.time(context, at);
    // A minute's grace, because autosave updates `updatedAt` a few times while
    // the entry is first being written and none of that is an edit.
    final edited = entry.updatedAt - entry.createdAt > 60 * 1000;
    final marked = entry.marker != null;

    return Semantics(
      button: true,
      label: (edited
              ? L.of(context).entrySemanticEdited(time)
              : L.of(context).entrySemantic(time)) +
          // Said out loud, because the rail is the only other channel and a
          // screen reader user has no access to it at all.
          (marked ? ' ${L.of(context).entryMattered}.' : ''),
      // ── The words themselves, and why they need saying here ──────────
      //
      // `excludeSemantics` below is deliberate and stays: without it the
      // rail, the star and the time are announced as three more nodes
      // before the entry, and the time is already in the label. But it
      // drops **everything** underneath, and what is underneath is
      // `LinkedText(entry.body)` -- the thing the person wrote.
      //
      // Found on hardware, 3 September 2026, by reading the accessibility
      // tree of a real day: every entry reported `Entry at 12:21. Tap to
      // edit.` and nothing else. Somebody using TalkBack could hear a list
      // of the times they had written at and not one word of their own
      // journal, which is the single thing this app is for.
      //
      // `value` rather than appending to `label`: it is the slot Flutter
      // and TalkBack both mean by "the content of this thing", and it
      // needs no new translated string -- an English sentence bolted onto
      // ten localised labels would have been its own defect.
      value: entry.body ?? '',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.only(
              top: Space.x5, bottom: Space.x1, right: Space.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── The rail, and the mark on it ────────────────────────
              //
              // A marked entry gets a solid rail rather than a faded one, and
              // a filled dot at its head. Two channels, not one: DESIGN-
              // SYSTEM.md does not allow a state to be carried by colour
              // alone, and a rail at 45% against a rail at 100% is precisely
              // the kind of difference that disappears in sunlight.
              //
              // A rail rather than a badge beside the time, because the mark
              // belongs to the whole entry and a badge would read as being
              // about the timestamp.
              Container(
                width: marked ? 3 : 2,
                height: 20,
                margin: const EdgeInsets.only(top: 4, right: Space.x3),
                color: c.accent.withValues(alpha: marked ? 1.0 : 0.45),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (marked) ...[
                          Icon(Icons.star_rounded,
                              size: 12, color: c.accent),
                          const SizedBox(width: 4),
                        ],
                        Text(
                            edited
                                ? L.of(context).entryEditedAt(time)
                                : time,
                            style: t.labelMedium),
                      ],
                    ),
                    const SizedBox(height: Space.x1),
                    // Measure capped so long lines stay readable — this app is
                    // for reading, and long lines are physically harder to
                    // read.
                    //
                    // **ISSUE 6b — removed anyway, and this is the honest
                    // reason.** The measure argument is sound and it is exactly
                    // the argument he overruled: *"if you make everything full,
                    // everything blends consistently"*. Leaving this one clamp
                    // in place while the header, the composer, the capture bar
                    // and every other screen went full-width would have
                    // recreated the defect he reported — a paragraph stopping
                    // short of a rule that everything around it sits on — only
                    // in a subtler place. One rule, no exceptions, is the whole
                    // point of the change.
                    // **ISSUE 11.** A web address somebody wrote is drawn
                    // as one and opens when tapped. `LinkedText` falls back to
                    // a plain `Text` when there is nothing to link, which is
                    // almost every entry — see the note there for why that
                    // matters beyond the saving.
                    LinkedText(entry.body ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An entry open for editing, in place.
///
/// In place rather than on its own screen because this is a stream, not a
/// document store — the surrounding day is the context for what you are
/// changing. The accent rule turns solid to say which block is live.
class EntryEditor extends StatelessWidget {
  const EntryEditor({
    super.key,
    required this.controller,
    required this.onDone,
    required this.onDelete,
    this.attachment,
  });

  final TextEditingController controller;
  final VoidCallback onDone;
  final VoidCallback onDelete;

  /// The photograph, recording or file this block also holds, shown above the
  /// words while they are edited. Null for a plain text entry.
  final Widget? attachment;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Padding(
      padding: const EdgeInsets.only(top: Space.x5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 20,
            margin: const EdgeInsets.only(top: 4, right: Space.x3),
            color: c.accent,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachment != null) ...[
                  attachment!,
                  const SizedBox(height: Space.x3),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  // Same reason as the composer: the keyboard may help, but it
                  // may not remember.
                  enableIMEPersonalizedLearning: false,
                  style: writingStyle(context),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                // ══ ROUND NINE, ISSUE 3 — "WHY IS THIS IN MIDDLE? WHY?" ══
                //
                // A circle round the **Done** button on the editing row, and
                // that question, twice.
                //
                // It is `Flexible` beside a `Spacer` — the exact shape
                // `test/widget/alignment_test.dart` was written about in round
                // six, still here in a row nobody had measured. Both buttons
                // and the `Spacer` are flex 1, so the free space is split
                // three ways and Done lands a third of the way in from the
                // right. Never at the edge, never quite centred: adrift, which
                // is what he was looking at.
                //
                // The comment that used to be here said `Flexible` was needed
                // so the row "does not stop fitting when the text doubles",
                // and that worry is real — at 200% these two words are wide.
                // But `Flexible` is a **loose** fit, which is precisely what
                // makes the position depend on the text. It was the bug, not
                // the protection.
                //
                // Two `Expanded` halves, each with its own alignment. A tight
                // fit, so the buttons are pinned to the two ends at every text
                // size, and each has half the row to wrap inside if it needs
                // it. One left rule and one right rule, which is the fix
                // `alignment_test` already documents.
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onDelete,
                          child: Text(L.of(context).actionDelete,
                              style: TextStyle(color: c.danger)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onDone,
                          child: Text(L.of(context).actionDone,
                              style: TextStyle(
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
