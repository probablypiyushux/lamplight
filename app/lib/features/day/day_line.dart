import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/day_note_repository.dart';
import '../../core/db/entry_repository.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// The one line that names a day. **`PLAN.md` §7.0-E, first item.**
///
/// ── WHERE IT SITS, AND WHY IT IS NOT IN THE STREAM ────────────────────────
///
/// Directly under the date, above everything that happened. It belongs to the
/// **header**, not to the list, and the distinction is the whole design:
///
///   * a line in the stream would have a position among the entries, and the
///     first thing a reader would ask is *what time was this*. It has no time;
///   * a line in the header is a **subtitle to the date**, which is exactly
///     what it is — "Tuesday, 26 August" then "Ammi's birthday" — and it is in
///     the one place on the screen that is already about the day as a whole.
///
/// ── WHY IT IS NOT ALWAYS OFFERED ──────────────────────────────────────────
///
/// A note that exists is always shown. The *invitation* to write one appears
/// only once the day has something on it, and that rule is deliberate:
///
///   * an empty day already carries one invitation — `EmptyDay`'s sheet, which
///     says *"Anything you want to keep?"*. Two invitations on a blank page is
///     the app asking twice and answering neither;
///   * a day cannot honestly be summed up before anything has happened on it.
///     Offering the field first would be asking somebody to title a chapter
///     they have not written.
///
/// `test/widget/day_line_test.dart` holds that rule, because it is the kind of
/// thing a later tidy-up would "simplify" into always-on without noticing that
/// the empty day then has two prompts.
///
/// ── WHY THE FIELD IS INLINE AND NOT A SHEET ───────────────────────────────
///
/// `PLAN.md` §7.0-E's complaint about filing is *"long-press → sheet → tick →
/// Done is four steps for the app's central idea"*, and the same arithmetic
/// applies here. A sheet for one short line is three taps and a screen
/// transition to type six words. Tapping the line turns it into a field where
/// it stands, and tapping away saves it.
///
/// **Two carets on one page is the thing to be careful about**, and this is not
/// that. The concern written in `day_screen.dart` is about two places *the same
/// words* could go — the composer and the in-place entry editor, which both
/// write an entry body. This writes somewhere else entirely, is labelled, is
/// visually distinct, and is above the fold rather than in the stream. It also
/// hands focus over rather than sharing it: opening this closes the composer,
/// which is `onFocused`'s only job.
class DayLine extends StatefulWidget {
  const DayLine({
    super.key,
    required this.notes,
    required this.entries,
    required this.dayKey,
    required this.editable,
    this.onFocused,
  });

  final DayNoteRepository notes;

  /// Only for [EntryRepository.watchHasEntries] — whether the day has anything
  /// on it decides whether the invitation is offered. See the class comment.
  final EntryRepository entries;

  /// The `YYYY-MM-DD` this line belongs to.
  final String dayKey;

  /// False on a page that is not the one on screen, and while the vault is
  /// locking. A note still shows; it simply cannot be tapped into.
  final bool editable;

  /// Called the moment this takes the caret, so the composer can give it up.
  final VoidCallback? onFocused;

  @override
  State<DayLine> createState() => _DayLineState();
}

class _DayLineState extends State<DayLine> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// What is in the database right now, so the field can be seeded when it
  /// opens and the label can be drawn when it is closed.
  String? _saved;

  bool _editing = false;

  /// Whether the day has anything on it. Starts false, so a day that is empty
  /// never flashes an invitation on its way to being empty.
  bool _hasEntries = false;

  StreamSubscription<String?>? _sub;
  StreamSubscription<bool>? _entrySub;

  @override
  void initState() {
    super.initState();
    _listen();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DayLine old) {
    super.didUpdateWidget(old);
    // The header is one widget for every page — see `day_header.dart` — so the
    // day underneath it changes without this being rebuilt from scratch. The
    // subscription has to follow, and any half-typed line belongs to the day it
    // was typed on rather than travelling to the next one.
    if (old.dayKey != widget.dayKey) {
      if (_editing) unawaited(_save());
      _editing = false;
      _listen();
    }
    if (!widget.editable && _editing) {
      unawaited(_save());
      _editing = false;
    }
  }

  void _listen() {
    _sub?.cancel();
    _entrySub?.cancel();
    _saved = null;
    _hasEntries = false;
    _sub = widget.notes.watch(widget.dayKey).listen((body) {
      if (!mounted) return;
      setState(() {
        _saved = body;
        // Never overwrite what is being typed. The stream fires on our own
        // write, and re-seeding the controller from it would move the caret to
        // the start mid-sentence.
        if (!_editing) _controller.text = body ?? '';
      });
    });
    _entrySub =
        widget.entries.watchHasEntries(widget.dayKey).listen((any) {
      if (!mounted) return;
      setState(() => _hasEntries = any);
    });
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _editing) {
      setState(() => _editing = false);
      unawaited(_save());
    }
  }

  Future<void> _save() async {
    final text = _controller.text;
    // The day this was typed on, captured now: `didUpdateWidget` saves before
    // it switches, but the await below outlives the frame either way and
    // `widget.dayKey` would by then be the day that was swiped to.
    final key = widget.dayKey;
    if (text.trim() == (_saved ?? '')) return;
    await widget.notes.setBody(key, text);
  }

  void _open() {
    setState(() => _editing = true);
    _controller.text = _saved ?? '';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    widget.onFocused?.call();
    // After the frame, so the field exists to receive it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _entrySub?.cancel();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final note = _saved;

    // Nothing written, nothing on the day, or a page that cannot be typed on:
    // the row is not there at all. Not an empty box — the header is short and
    // every point of it is spoken for.
    if (!_editing && note == null && (!_hasEntries || !widget.editable)) {
      return const SizedBox.shrink();
    }

    if (_editing) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.x1, bottom: Space.x1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Rule(colour: c.accent),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                // One line, and the keyboard's return key says so. Enter
                // commits rather than starting a second line, because there is
                // no second line to start.
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _focus.unfocus(),
                // The cap is enforced where the finger is, so nobody types past
                // it and watches their words disappear on save.
                inputFormatters: [
                  LengthLimitingTextInputFormatter(DayNoteRepository.maxLength),
                ],
                style: t.bodyMedium?.copyWith(color: c.inkPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: L.of(context).dayLineHint,
                  hintStyle: t.bodyMedium?.copyWith(color: c.inkMuted),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final invitation = note == null;

    return Padding(
      padding: const EdgeInsets.only(top: Space.x1, bottom: Space.x1),
      child: Semantics(
        button: widget.editable,
        label: invitation
            ? L.of(context).dayLineSemantic
            : L.of(context).dayLineChange(note),
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.editable ? _open : null,
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.x1),
            child: Row(
              children: [
                _Rule(
                  colour: invitation
                      ? c.accent.withValues(alpha: 0.25)
                      : c.accent.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: Text(
                    // The invitation is a question, never an instruction, and
                    // never a reproach. `ETHICAL-DESIGN.md`: nothing in this
                    // app may imply the user owes it something.
                    invitation ? L.of(context).dayLineAsk : note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(
                      color: invitation ? c.inkMuted : c.inkSecondary,
                      // A named day is set in the writing face, because the
                      // words are the user's own rather than the app's.
                      fontStyle: invitation ? FontStyle.italic : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The two-point accent rule every block in this app hangs off, so the day's
/// own line reads as part of the same object rather than as a banner above it.
class _Rule extends StatelessWidget {
  const _Rule({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 14,
      margin: const EdgeInsets.only(right: Space.x3),
      color: colour,
    );
  }
}
