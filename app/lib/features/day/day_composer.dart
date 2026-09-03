import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../design/tokens.dart';

/// Where a new entry is typed, and the three controls around it.
///
/// ══ WHY THIS IS ITS OWN FILE. `Honest Review` ITEM 8 ═══════════════════════
///
/// > *"`day_screen.dart` is 2,147 lines and growing … **every bug in this round
/// > that took more than one attempt was in a file over a thousand lines.**"*
///
/// The composer is the part of the day with the tightest performance budget —
/// it is rebuilt on keystrokes — and it was buried in the middle of two
/// thousand lines that are rebuilt on almost nothing. Keeping the two apart is
/// most of what stops the next person "simplifying" [ComposerState] away.
///
/// **Read the note on [ComposerState] before touching it.** Its value equality
/// is the reason typing does not rebuild the day, and it looks like
/// boilerplate that could be deleted.

/// One day's material. **This is the only part that swipes.**
class DayComposer extends StatelessWidget {
  const DayComposer({
    super.key,
    required this.controller,
    required this.focus,
    required this.state,
    required this.isToday,
    required this.onNewBlock,
    required this.onInserted,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueNotifier<ComposerState> state;

  /// **ISSUE 4.** The invitation said *"Write about today…"* on every page,
  /// including 26 December 2077. Found while reproducing the day-swap race:
  /// the header had moved to yesterday and the page was still asking about
  /// today, which is a small lie and exactly the sort that makes somebody
  /// mistrust where their words are going — which is what he was reporting.
  final bool isToday;

  final VoidCallback onNewBlock;

  /// A GIF or a sticker committed by the keyboard. **ISSUE 4 addon.**
  final void Function(KeyboardInsertedContent) onInserted;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Semantics(
      label: L.of(context).composerSemantic,
      child: Padding(
        // No border, no hairline, no fill. It is the page.
        padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              // Grows with what you type, up to about six lines, then scrolls
              // inside itself. `PLAN.md` §8.5 asks for a composer that grows
              // rather than jumping line to line — `maxLines: null` inside a
              // bounded box is exactly that, and it costs nothing.
              // Six lines was right for a bar at the bottom of the screen.
              // On the page there is no reason to stop — the day scrolls, so a
              // long entry simply grows down it, which is the whole point.
              constraints: const BoxConstraints(maxHeight: 5000),
              child: TextField(
                controller: controller,
                focusNode: focus,
                style: writingStyle(context),
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                // ── The keyboard must not learn what you write here ────────
                //
                // Without this, every private word typed into this journal goes
                // into the keyboard's personal dictionary. Gboard then suggests
                // those words in other apps — and syncs the dictionary to
                // Google if the user has backup on. The note never leaves the
                // vault and the *words* leave anyway, through a door the
                // encryption does not cover.
                //
                // Deliberately NOT `enableSuggestions: false` — that would also
                // kill autocorrect, and an app for writing that fights you
                // while you write is one you stop using. This keeps the help
                // and drops the memory.
                enableIMEPersonalizedLearning: false,
                // ── The keyboard's GIF button. ISSUE 4 addon. ──────────────
                //
                // Without this the GIF key on Gboard, Samsung Keyboard and the
                // rest simply does nothing in Lamplight: Android's
                // `commitContent` needs the field to advertise which MIME types
                // it accepts, and a field that advertises none is a field the
                // keyboard quietly refuses to insert into. Another control that
                // does nothing when tapped, which is the defect this whole
                // round is about.
                //
                // **The privacy question, answered before it is asked**, since
                // it will otherwise be raised as one: *the keyboard fetches the
                // GIF, not us.* Gboard downloads it in its own process, under
                // its own permissions, and hands Lamplight the bytes through
                // the input connection. Lamplight still opens no socket and
                // still declares no INTERNET permission, and
                // `tool/verify_no_internet.sh` still passes against the release
                // APK. Nothing here changes what the app can reach.
                //
                // The list is deliberately narrow — three picture types, no
                // video, no audio, no arbitrary files. A field that accepts
                // anything a keyboard cares to send is a hole; this accepts the
                // three things a keyboard actually sends.
                contentInsertionConfiguration: ContentInsertionConfiguration(
                  allowedMimeTypes: const [
                    'image/gif',
                    'image/png',
                    'image/webp',
                  ],
                  onContentInserted: onInserted,
                ),
                decoration: InputDecoration(
                  // A sentence rather than a field's placeholder. ISSUE 9: the
                  // box that said "Anything you want to keep?" was inert, and
                  // this is where that invitation belongs now — on the thing
                  // that actually accepts the writing.
                  hintText: isToday
                      ? L.of(context).composerHintToday
                      : L.of(context).composerHintPast,
                  hintStyle: writingStyle(context).copyWith(color: c.inkMuted),
                  // No box. Content sits ON the page, not inside a container.
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: Space.x2),
                  isDense: true,
                ),
              ),
            ),
            // The only part of the screen that rebuilds while you type.
            ValueListenableBuilder<ComposerState>(
              valueListenable: state,
              builder: (context, s, _) {
                if (!s.hasText && !s.hasDraft) return const SizedBox(height: 4);
                // ROUND FIVE, ISSUE 14 — "New block" sits on the right now.
                //
                // *"In middle why? It should be in right side."* He drew it
                // with "Saved" circled on the left and "New block" circled
                // adrift near the centre, and the cause was not a missing
                // alignment — there is a `TextAlign.end` on that label already,
                // which is exactly the fix that looks right and does nothing.
                //
                // It was the two flex factors. `Expanded` is `Flexible` with
                // `fit: tight`, and a bare `Flexible` also defaults to
                // `flex: 1`, so the row was handing half its width to the label
                // and half to the button's box. The button then centred itself
                // inside its half, which put it three-quarters of the way
                // across — near the middle, pinned to nothing, moving as the
                // word "Saving…" got longer or shorter. The `TextAlign.end`
                // could not help because the `Text` is already shrink-wrapped
                // inside the button; there was no slack for it to align within.
                //
                // One `Expanded` and a button that hugs its content is all it
                // needs. The label takes everything left over, so the button is
                // against the right rule and stays there.
                return Row(
                  children: [
                    // Honest, quiet state. Never a spinner that blocks typing.
                    Expanded(
                      child: Text(
                        s.saving ? 'Saving…' : 'Saved',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: s.hasText ? onNewBlock : null,
                      child: Text(L.of(context).composerNewBlock,
                          style: TextStyle(color: c.inkSecondary)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// What the composer's own controls depend on.
class ComposerState {
  const ComposerState({
    required this.hasText,
    required this.saving,
    required this.hasDraft,
  });

  final bool hasText;
  final bool saving;
  final bool hasDraft;

  // Value equality, so a keystroke that changes nothing visible — the second
  // letter of a word, and every one after it — does not rebuild even the small
  // part. ValueNotifier only notifies when the value differs.
  @override
  bool operator ==(Object other) =>
      other is ComposerState &&
      other.hasText == hasText &&
      other.saving == saving &&
      other.hasDraft == hasDraft;

  @override
  int get hashCode => Object.hash(hasText, saving, hasDraft);
}
