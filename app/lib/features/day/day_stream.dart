import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../core/db/folder_repository.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/vault/vault.dart';
import '../../design/tokens.dart';
import '../capture/attachment_blocks.dart';
import '../capture/transcription_queue.dart';
import 'empty_day.dart';
import 'entry_block.dart';
import 'folder_ribbon.dart';
import 'on_this_day.dart';

/// The day itself: the list of what is on it, and how it arrives.
///
/// ══ WHY THIS IS ITS OWN FILE. `Honest Review` ITEM 8 ═══════════════════════
///
/// > *"`day_screen.dart` is 2,147 lines and growing … not tidiness. **Every bug
/// > in this round that took more than one attempt was in a file over a
/// > thousand lines.**"*
///
/// This was the largest single thing in that file — the stream, the pull that
/// reveals search, and the rise a new block arrives with — and it is the part
/// that has the least to do with the rest of it. It reads entries and draws
/// them. It does not know about page controllers, capture handlers, the import
/// queue, the recording sheet, or where the caret is; everything it needs
/// arrives as a parameter, which is why the seam is here and not somewhere
/// tidier-looking.
///
/// **Nothing changed on the way out.** Every note below was written where it
/// stands, about a bug that was found where it stands.

class DayStream extends StatefulWidget {
  const DayStream({
    super.key,
    required this.repository,
    required this.importer,
    required this.vault,
    required this.date,
    required this.isToday,
    required this.draftEntryId,
    required this.editor,
    required this.composer,
    required this.onStartWriting,
    required this.onEdit,
    required this.onMenu,
    required this.onOpen,
    required this.onSaveCopy,
    required this.onOpenWith,
    required this.onTrash,
    required this.onFinishEditing,
    required this.onDeleteEditing,
    required this.onGoToDate,
    required this.transcripts,
    required this.settings,
    required this.onPullToSearch,
    required this.onOpenFolder,
  });

  /// Opens a folder by name, from the ribbon under a filed entry.
  /// **`PLAN.md` §9.1** — see `folder_ribbon.dart` for why the ribbon exists
  /// and why the swipe §7.0-E asks for does not.
  final void Function(String name) onOpenFolder;

  /// Pulling the day down past its top opens search. **`UX-FLOWS.md` flow 4.**
  final VoidCallback onPullToSearch;

  final EntryRepository repository;
  final AttachmentImporter importer;
  final Vault vault;
  final DateTime date;
  final bool isToday;
  final String? draftEntryId;
  final OpenEditor? editor;

  /// The writing surface, drawn as the last thing on this page. **ISSUE 9+14.**
  ///
  /// Null on every page except the one on screen, and null while an existing
  /// entry is being edited in place — two carets on one day would be two
  /// places the same words could go.
  final Widget? composer;

  /// Puts the caret on the page. Reached from the empty day's sheet and from
  /// the blank space below the last block.
  final VoidCallback onStartWriting;

  final void Function(Entry) onEdit;
  final void Function(Entry) onMenu;

  /// Open the attachment in place. Documents only — photos, videos and voice
  /// notes each own their own tap already.
  final void Function(Entry) onOpen;

  /// Write a copy somewhere the user chooses. Reaches the video player's
  /// refusal panel — ISSUE 10, and the viewer's three-dot "Save photo" —
  /// ISSUE D. They are the same act, so they are the same callback rather than
  /// two that could drift.
  final void Function(Entry) onSaveCopy;

  /// **ISSUE 4, 13.** Lend an attachment to another app.
  final void Function(Entry) onOpenWith;

  /// What is being written down, and why nothing is. **Round ten.**
  ///
  /// Reaches the one row under a voice note — see `_TranscriptRow`. Passed all
  /// the way down rather than looked up, because there is exactly one queue and
  /// it belongs to this screen's lifetime.
  final TranscriptionQueue transcripts;
  final AppSettings settings;

  /// **ISSUE D.** Send this block to the trash, from inside the viewer.
  final void Function(Entry) onTrash;

  final VoidCallback onFinishEditing;
  final Future<void> Function(String id) onDeleteEditing;
  final void Function(DateTime) onGoToDate;

  @override
  State<DayStream> createState() => DayStreamState();
}

class DayStreamState extends State<DayStream> {
  // ══ GETTING TO THE END OF A LONG DAY. `PLAN.md` §7.0-E ═══════════════
  //
  // *"Jump to the first or last entry of a long day — small, and the only
  // navigation complaint left."*
  //
  // A day with forty photographs on it is several screens tall and the two
  // places somebody actually wants are its ends: the **start**, to read the
  // day from the beginning, and the **end**, where the composer is and where
  // anything new goes. Everything in between is what scrolling is for.
  //
  // ── WHY ONE BUTTON AND NOT TWO ──────────────────────────────────
  //
  // Two arrows in a corner is a scrollbar drawn badly. One control that points
  // at the end you are **not** at is unambiguous at every moment: near the top
  // it offers the end, near the end it offers the top, and it never asks the
  // user to work out which of two similar glyphs they want. It is the gesture
  // every messaging app already teaches, borrowed rather than invented.
  final ScrollController _scroll = ScrollController();

  /// What the button should look like, and **nothing else in this widget
  /// listens to it.**
  ///
  /// ══ WHY THIS IS A NOTIFIER AND NOT TWO FIELDS AND A `setState` ══════════
  ///
  /// This is round ten's *"the app hangs as hell"* bug waiting to be written a
  /// second time, and the first draft of this control had it.
  ///
  /// A scroll notification arrives on **every frame of every scroll**. Calling
  /// `setState` from there rebuilds `DayStreamState` — which means the
  /// `StreamBuilder`, the album grouping, the `ListView.builder` and every
  /// `itemBuilder` Flutter decides to re-run — sixty times a second, for the
  /// whole length of a flick, to move one arrow. On a day of photographs that
  /// is the heaviest subtree in the app being rebuilt during the one
  /// interaction that most needs to stay at sixty frames.
  ///
  /// A `ValueNotifier` read by a `ValueListenableBuilder` **around the button
  /// alone** rebuilds forty-eight points of arrow and nothing else. And the
  /// value is a pair of *booleans* rather than the raw offset, so a scroll
  /// that does not cross either threshold notifies nobody at all: the common
  /// case — dragging through the middle of a long day — is zero rebuilds
  /// rather than one per frame.
  final ValueNotifier<({bool visible, bool toTop})> _jumpState =
      ValueNotifier((visible: false, toTop: false));

  /// Long enough that scrolling to an end is a chore rather than a flick.
  ///
  /// **A full screen of travel** — which is to say the day is more than twice
  /// the height of the window. A day that merely spills past the fold does not
  /// get the control, because there the button is furniture: it would cover
  /// part of somebody's last sentence to save a gesture that costs nothing.
  ///
  /// Stated in screens rather than in points on purpose. The unit that matters
  /// is *how many flicks away the end is*, and that is the same number on a
  /// tall tablet and a short phone; a fixed pixel threshold would put the
  /// button on ordinary days on a small screen and hide it on long ones on a
  /// large screen, which is exactly backwards.
  static const double _longDay = 1.0;

  /// Within this of an end counts as being at it, so the arrow turns over
  /// before the scroll physics have quite finished settling.
  static const double _atEnd = 24;

  bool _onScroll(ScrollNotification n) {
    // Only the list's own scrolls. The pager is a horizontal `Scrollable` and
    // its notifications travel up through here too; acting on them would make
    // the button flicker on every day change.
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification && n is! ScrollMetricsNotification) {
      return false;
    }

    final m = n.metrics;
    final next = (
      visible: m.maxScrollExtent > m.viewportDimension * _longDay,
      toTop: m.pixels >= m.maxScrollExtent - _atEnd,
    );
    if (next == _jumpState.value) return false;

    // Outside the frame. A `ScrollMetricsNotification` is dispatched *during*
    // layout, and a notifier read by a `ValueListenableBuilder` marks that
    // builder dirty — "markNeedsBuild() called during build", on a day that
    // happens to change height while it is being drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpState.value = next;
    });
    return false;
  }

  void _jump() {
    if (!_scroll.hasClients) return;
    final to = _jumpState.value.toTop ? 0.0 : _scroll.position.maxScrollExtent;
    unawaited(HapticFeedback.selectionClick());
    // Animated rather than jumped. A list that teleports gives no sense of how
    // far it went, and on a day of forty photographs that distance is the one
    // piece of information the movement carries.
    _scroll.animateTo(
      to,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _jumpState.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ══ PULLING THE DAY DOWN. `UX-FLOWS.md` FLOW 4 ═══════════════════════════
  //
  // How far past the top the finger has dragged, and whether this drag has
  // already been spent. Both reset when the gesture ends, so one long pull
  // opens search once and a scroll that merely bumps the top opens nothing.
  double _pulled = 0;
  bool _pullSpent = false;

  /// Far enough to be a decision rather than a bounce.
  ///
  /// Ninety points is about a thumb's travel and is comfortably past the
  /// distance a flick to the top of a list overshoots by. Too small and the app
  /// leaves the day every time somebody scrolls up briskly, which would be a
  /// far worse bug than not having the gesture at all.
  static const double _pullThreshold = 90;

  bool _onPull(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _pulled = 0;
      _pullSpent = false;
    } else if (notification is OverscrollNotification) {
      // Negative overscroll is past the *top*. Pulling up from the bottom of a
      // long day is a different gesture and means nothing here.
      if (notification.overscroll < 0) _pulled -= notification.overscroll;
      if (!_pullSpent && _pulled > _pullThreshold) {
        _pullSpent = true;
        // A tap you can feel, at the moment it becomes inevitable rather than
        // when the finger lifts — so the pull has an end you can sense without
        // watching for it. `DESIGN-SYSTEM.md`: haptics carry more weight than
        // animation here.
        unawaited(HapticFeedback.mediumImpact());
        widget.onPullToSearch();
      }
    } else if (notification is ScrollEndNotification) {
      _pulled = 0;
      _pullSpent = false;
    }
    // Never absorbed. Everything above this — the pager, the scrollbar — is
    // entitled to hear its own scrolls.
    return false;
  }

  late final Stream<List<Entry>> _stream =
      widget.repository.watchDay(EntryRepository.dayKeyFor(widget.date));

  /// Which folders each entry on this day is in. **`PLAN.md` §9.1.**
  ///
  /// A second watched query rather than a join onto the day, deliberately: the
  /// day's own query is the hottest in the app and returns whole rows including
  /// bodies, and folding a one-to-many join into it would multiply those rows
  /// by the number of folders each entry is in. This returns two short strings
  /// per membership and re-runs only when a membership changes — so filing
  /// something does not re-read the day's writing.
  /// Whether this vault has ever held anything. **`Honest Review`, the small
  /// ones: "a real empty state for a brand-new vault".**
  ///
  /// Only consulted on today and only when the day is empty, so on every
  /// ordinary day this stream emits once and is never looked at.
  late final Stream<bool> _brandNew = widget.repository.watchIsBrandNew();

  late final Stream<Map<String, List<String>>> _folders =
      FolderRepository(widget.repository.db)
          .watchNamesForDay(EntryRepository.dayKeyFor(widget.date));

  /// Held so the resurfacing card is queried once per day rather than on every
  /// rebuild of the list.
  late final Future<List<Entry>> _history =
      widget.repository.onThisDay(widget.date);

  /// Which entry ids have already been on screen. A row that was here before
  /// must not re-animate when its neighbour changes; only genuinely new
  /// material rises in.
  final Set<String> _seen = <String>{};

  /// Whether this day has ever had its contents delivered.
  ///
  /// ══ "SLIDING BETWEEN DAYS FEELS JERKY." 2 SEPTEMBER 2026 ═══════════════
  ///
  /// It did, and this flag is the fix. The comment on [_seen] above states the
  /// rule correctly — *only genuinely new material rises in* — and the code
  /// under it did not implement that rule. It implemented *only material this
  /// **widget** has not seen rises in*, which is a different sentence, and the
  /// difference is invisible on the day you are already standing on.
  ///
  /// Every day in the `PageView` gets its own `DayStreamState`, so [_seen]
  /// starts empty for each one. Swipe to 14 March 2024 and every entry on it
  /// is, as far as this set is concerned, brand new — so **the whole day
  /// animates in at once**, eleven blocks fading and translating together, on
  /// top of the slide that is already in progress. Two years of notes are not
  /// new material. They were there before you arrived.
  ///
  /// So the first delivery a day ever makes is treated as **the day loading**
  /// rather than as things happening on it: [_seen] is seeded from it in
  /// silence, and everything after that animates normally. Writing an entry
  /// still rises in, because by then this is true and the new id is not in the
  /// set — which is the behaviour the animation was added for and the only one
  /// anybody asked for.
  bool _arrived = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<String>>>(
      stream: _folders,
      // The day draws with no ribbons until the memberships arrive, which is
      // one frame and is the honest intermediate state: an entry with no chips
      // under it looks exactly like an entry that is not filed, and it is about
      // to turn out to be one or the other.
      builder: (context, folderSnap) =>
          _buildDay(context, folderSnap.data ?? const {}),
    );
  }

  Widget _buildDay(BuildContext context, Map<String, List<String>> folders) {
    return StreamBuilder<List<Entry>>(
      stream: _stream,
      builder: (context, snap) {
        // The draft is deliberately not in the list. The day is a live query
        // and autosave writes a real row, so without this filter the sentence
        // being typed is drawn as a finished entry immediately above the
        // composer that still holds it.
        final entries = (snap.data ?? const <Entry>[])
            .where((e) => e.id != widget.draftEntryId)
            .toList();
        final waiting = snap.connectionState == ConnectionState.waiting;

        // ── Arriving at a day is not material appearing on it ─────────────
        //
        // See `_arrived`. Seeding here rather than at either `Rising` call
        // site because both of them key off an id drawn from `entries` — the
        // album uses `run.first.id`, which is one of these — so one loop
        // covers both, and a third call site added later is covered without
        // anybody having to notice this exists.
        if (!waiting && !_arrived) {
          _arrived = true;
          for (final e in entries) {
            _seen.add(e.id);
          }
        }

        final runs = groupIntoAlbums(entries);

        // Puts the folder ribbon under a block, or returns it untouched.
        //
        // Outside `Rising` rather than inside it, and that is deliberate: a
        // brand-new entry is not filed anywhere yet, so there would be nothing
        // to animate in with it — and when one is filed later the chips should
        // appear where the entry already is, rather than making a settled block
        // slide a second time.
        Widget filed(String entryId, Widget block) {
          final names = folders[entryId];
          if (names == null || names.isEmpty) return block;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block,
              FolderRibbon(names: names, onOpen: widget.onOpenFolder),
            ],
          );
        }

        // ── Lazy, and this is the last of "the app hangs" ─────────────────
        //
        // It was a plain `ListView(children: [...])`, which builds **every**
        // child immediately, on the frame the day opens. On a day with twenty
        // photographs that is twenty `AttachmentBlock`s constructed at once,
        // each starting its own decrypt — for eighteen pictures that are below
        // the fold and that nobody has scrolled to yet.
        //
        // `ListView.builder` builds only what is on screen plus a screenful
        // either side. The same day now starts three decrypts instead of
        // twenty, and the rest happen as they are scrolled towards. It is the
        // single largest remaining difference on a photo-heavy day and it is
        // one word of API.
        //
        // The header rows — the resurfacing card, the empty-day line — are
        // folded into the same index space rather than being a second list, so
        // there is still exactly one scroll view and one scroll position.
        final leading = <Widget>[
          if (widget.isToday)
            OnThisDayCard(
              history: _history,
              repository: widget.repository,
              onOpen: widget.onGoToDate,
            ),
          // ISSUE 3. This used to be one line of muted text floating in the
          // middle of a near-black rectangle, indistinguishable from a screen
          // that had failed to load. It is a sheet of paper now. See
          // `EmptyDay` for the argument, which is mostly `PLAN.md` §8.3 and
          // §3's endowed-progress note.
          if (entries.isEmpty && !waiting)
            // ── The first minute, and every other empty day ──────────────
            //
            // The `StreamBuilder` is *inside* the empty branch on purpose: a
            // day with anything on it never subscribes, so the extra query
            // costs nothing on the days that are not empty — which is most of
            // them, in a journal anybody is actually keeping.
            StreamBuilder<bool>(
              stream: _brandNew,
              builder: (context, snap) => EmptyDay(
                date: widget.date,
                isToday: widget.isToday,
                // False until the answer arrives, so an established vault
                // never flashes a welcome at somebody who has been here for
                // three years. The wrong direction of this default is a
                // greeting; the right direction is one frame of the ordinary
                // sheet.
                isFirstEver: snap.data ?? false,
                // ISSUE 9 — "I want this to work". The sheet is the invitation
                // to write, so tapping it is how writing starts. It was inert.
                onTap: widget.composer == null ? null : widget.onStartWriting,
              ),
            ),
        ];

        // ── ISSUE 7 — the page itself accepts a tap ────────────────────
        //
        // "This box even after touching here don't open write tab."
        //
        // `_startWriting`'s own comment has said since round five that it is
        // "called by the empty day's sheet and by a tap on the page's blank
        // space". The first half was true. The second half was not written:
        // nothing below the last block handled a tap at all, so the majority of
        // an empty day — the part that most obviously looks like a page you
        // could write on — was inert.
        //
        // `translucent`, so this never takes a tap away from anything. Entry
        // blocks, the sheet, the composer and every control keep their own
        // recognisers and win the arena by being deeper in the tree; this only
        // hears the taps that nothing else wanted. And it is only armed when
        // there is a composer to focus, so a page that is not the current one
        // stays inert rather than silently doing nothing.
        final stream = ListView.builder(
          controller: _scroll,
          // ── The scroll physics that make a pull possible ───────────────
          //
          // A day with two lines in it is shorter than the screen, and the
          // default physics refuse to overscroll a list that does not fill its
          // viewport — so on exactly the days somebody is most likely to reach
          // for search, there would have been nothing to pull. `AlwaysScrollable`
          // gives every day the same gesture.
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          // ── ISSUE 9/10 — one left rule for the whole page ──────────────
          //
          // "Why are they in middle." He drew it around a voice note, and the
          // voice note was not the only thing doing it — every block in the
          // stream was.
          //
          // Each block draws a two-point accent rule with twelve points after
          // it, and those fourteen points came out of the content's width. So
          // an entry's words, and a voice note's play button, began fourteen
          // points to the right of the composer immediately below and the date
          // immediately above. Three left rules on one page.
          //
          // The stream is pulled left by exactly the rule's width, so the rule
          // hangs in the margin where a margin mark belongs and the content
          // lands on `Layout.gutter` with everything else. The rows that carry
          // no rule — the resurfacing card, the empty-day sheet, the composer —
          // are given it back individually below, so they stay on the same rule
          // rather than sliding into the margin.
          padding: const EdgeInsets.fromLTRB(
              Layout.gutter - Layout.rail, 0, Layout.gutter, Space.x6),
          // A screenful either side, no more. The default is 250 logical
          // pixels, which on a day of full-width photographs is most of a
          // second photograph being decrypted before it is anywhere near
          // visible.
          // Renamed and re-typed by the framework after 3.41: it is a
          // `ScrollCacheExtent` now rather than a bare double, which is an
          // improvement — the old API could not tell "400 pixels" from "400
          // times the viewport" and the new one has to be told which you mean.
          // Pixels here, deliberately: the cost being managed is *decrypting a
          // photograph*, and that cost is the same on a tall screen as on a
          // short one.
          scrollCacheExtent: const ScrollCacheExtent.pixels(400),
          itemCount: leading.length + runs.length + 1,
          itemBuilder: (context, index) {
            // Everything without an accent rule of its own gets the rule's
            // width back, so it sits on `Layout.gutter` like the blocks that
            // do. See the padding above.
            if (index < leading.length) {
              return Padding(
                padding: const EdgeInsets.only(left: Layout.rail),
                child: leading[index],
              );
            }
            final i = index - leading.length;
            // The last slot is the writing surface — ISSUE 9 + 14. On a page
            // that is not the current one it is the old trailing spacer.
            if (i >= runs.length) {
              final composer = widget.composer;
              return composer == null
                  ? const SizedBox(height: Space.x6)
                  : Padding(
                      padding: const EdgeInsets.only(left: Layout.rail),
                      child: composer,
                    );
            }
            final run = runs[i];

            if (run.length > 1) {
              // Photos chosen together, drawn as one album.
              // The ribbon reads the folders of the member the entry menu
              // files — `onMenu` below passes the same `run.first`, so what
              // is shown and what was ticked cannot disagree.
              return filed(
                run.first.id,
                Rising(
                  key: ValueKey('album:${run.first.groupId}'),
                  animate: _seen.add(run.first.id) && !waiting,
                  child: AlbumBlock(
                    entries: run,
                    importer: widget.importer,
                    onMenu: () => widget.onMenu(run.first),
                    // `PLAN.md` §9.7 — one caption for the album rather than
                    // words attached to whichever picture they were typed
                    // against. The album picks which of its members holds them;
                    // this is the ordinary entry editor, opened on that one.
                    onCaption: widget.onEdit,
                    // ISSUE 4, 13.
                    onOpenEntryWith: widget.onOpenWith,
                    // ISSUE D. The album resolves which photograph the viewer
                    // was actually showing back to its entry before calling
                    // either of these — in a four-photo album that is not
                    // necessarily the one that was tapped.
                    onSaveEntry: widget.onSaveCopy,
                    onTrashEntry: widget.onTrash,
                  ),
                ),
              );
            }

            final e = run.first;
            if (widget.editor?.entryId == e.id) {
              return EntryEditor(
                controller: widget.editor!.controller,
                // ── The photo must not vanish while you type ────────────
                //
                // Editing used to replace the whole block with a bare text
                // field, so a photograph disappeared the moment you tapped to
                // fix a typo. Nothing was ever lost, but you had no way to
                // know that while it was gone, and being unsure whether an
                // app has just eaten your photograph is its own kind of harm.
                attachment: e.attachmentId == null
                    ? null
                    : AttachmentBlock(
                        entry: e,
                        importer: widget.importer,
                        onTap: () {},
                        onLongPress: () {},
                        bare: true,
                      ),
                onDone: widget.onFinishEditing,
                onDelete: () => widget.onDeleteEditing(e.id),
              );
            }

            return filed(
              e.id,
              Rising(
                key: ValueKey(e.id),
                // A new block rises and fades in. One that was already here
                // does not, because a list that re-animates itself every time
                // anything changes is exhausting to look at.
                animate: _seen.add(e.id) && !waiting,
                child: e.attachmentId != null
                    ? AttachmentBlock(
                        entry: e,
                        importer: widget.importer,
                        // ── ISSUE 4: a tap opens the thing ─────────────────
                        //
                        // It used to open the entry menu, which offered "save a
                        // copy" and nothing else — so a PDF in your own journal
                        // could not be read in your own journal. A photo, a
                        // video and a voice note all open on a tap; a document
                        // was the one kind that did not, and there was no reason
                        // for it beyond nobody having built the viewer.
                        //
                        // The menu is what a long press is for, which is where
                        // it already was on every other kind.
                        onTap: () => widget.onOpen(e),
                        onLongPress: () => widget.onMenu(e),
                        // ISSUE 10: reaches the video player's refusal panel, so
                        // "save a copy" is something you can do rather than
                        // something you are told about.
                        onSaveCopy: () => widget.onSaveCopy(e),
                        // ISSUE D — the viewer's three-dot menu.
                        onSaveEntry: widget.onSaveCopy,
                        onTrashEntry: widget.onTrash,
                        // ISSUE 4, 13 — and "Open with…" in that same menu.
                        onOpenEntryWith: widget.onOpenWith,
                        // `PLAN.md` §9.7. A lone photograph is drawn as an album
                        // of one, so it reaches the same sheet and the same
                        // editor.
                        onCaption: widget.onEdit,
                        // Round ten. The row that says where this recording's
                        // words are — or why there are none yet.
                        transcripts: widget.transcripts,
                        settings: widget.settings,
                      )
                    : EntryBlock(
                        entry: e,
                        onTap: () => widget.onEdit(e),
                        onLongPress: () => widget.onMenu(e),
                      ),
              ),
            );
          },
        );

        // ── Pull the day down to search. `UX-FLOWS.md` flow 4 ────────────
        //
        // Specified in the flows and never built — `Honest Review` lists it
        // among the small things, and it is the one gesture people arrive
        // already knowing, because every mail and message app on the phone has
        // it.
        //
        // **An overscroll rather than a `RefreshIndicator`.** A refresh spinner
        // would be a lie twice over: there is nothing to reload — the day is a
        // live query — and the thing at the end of the pull is a different
        // screen, not this one with new contents. So it watches the overscroll
        // and opens search once it is unmistakably deliberate.
        final pullable = NotificationListener<ScrollNotification>(
          onNotification: _onPull,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: stream,
          ),
        );

        // Only when there is somewhere for the caret to go.
        if (widget.composer == null) return pullable;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onStartWriting,
          child: Stack(
            children: [
              pullable,
              // ── The way to the end of a long day. `PLAN.md` §7.0-E ─────
              //
              // Drawn over the stream rather than beside it, because it must
              // not take a strip of width away from the writing on the
              // overwhelming majority of days where it does not exist. It is
              // only ever built on the page that has the composer — which is
              // to say the page on screen — so a swipe does not drag three
              // copies of it across the window.
              Positioned(
                right: Layout.gutter,
                bottom: Space.x5,
                child: ValueListenableBuilder<({bool visible, bool toTop})>(
                  valueListenable: _jumpState,
                  builder: (context, state, _) => _JumpButton(
                    visible: state.visible,
                    toTop: state.toTop,
                    onTap: _jump,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A short rise and a fade. Never a pop.
///
/// `PLAN.md` §8.5: "new entries animate in — a short rise and fade, never a
/// pop". Twelve points and 260 ms, which is far enough to read as arriving and
/// short enough that the second one is not a wait.
class Rising extends StatefulWidget {
  const Rising({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<Rising> createState() => RisingState();
}

class RisingState extends State<Rising> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Reduced motion gets the end state immediately. It still appears; it
        // just does not travel. ACCESSIBILITY.md.
        if (MediaQuery.disableAnimationsOf(context)) {
          _c.value = 1;
        } else {
          _c.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isCompleted) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// The writing surface. **On the page, since ISSUE 9 + 14.**
///
/// ── WHAT WAS WRONG, IN HIS WORDS ─────────────────────────────────────────
///
/// *"Typing doesn't feel like writing on any kind of notes app."*
///
/// It felt like a chat app, because it was shaped like one: a bordered field
/// with a hairline above it, pinned over the capture bar, with a hint reading
/// "Write…" inside a box. You typed into a strip at the bottom of the screen
/// and the words appeared somewhere else afterwards. Every decision in it was
/// defensible on its own and together they were WhatsApp's composer.
///
/// What a notes app does instead is put the caret **where the words will be**.
/// So this is now the last thing in the day's own scroll view, sitting directly
/// after the last block, and it has lost everything that made it look like an
/// input:
///
///   * **No border and no hairline.** Content sits *on* the page, which is what
///     `DESIGN-SYSTEM.md` already says about everything else in this app; the
///     composer was the one thing that had a box around it.
///   * **The writing face, at writing size.** It is the same
///     [writingStyle] a saved block is drawn in, so a sentence does not change
///     appearance at the moment it stops being a draft. That is the single
///     biggest part of it feeling like paper.
///   * **The hint is a sentence, not a label.** "Write…" is a field's
///     placeholder. It reads as an instruction now.
///
/// ── WHAT DELIBERATELY DID NOT CHANGE ─────────────────────────────────────
///
/// **Enter still makes a new line**, which is what he asked for, and it always
/// did — `maxLines: null` with a multiline keyboard type. **Autosave still runs
/// on every keystroke**, and on backgrounding, on a page change and on dispose.
/// There was never a save button to remove; what looked like one was the draft
/// being drawn twice, which is fixed in `_flush`.
///
/// **The blocks are still blocks.** Each stretch of writing stays its own
/// timestamped entry, so the timeline, album grouping, per-block delete, the
/// trash and search all work exactly as they did. A day is not one long note.

/// The one control that gets you to the end of a long day you are not at.
///
/// Fades rather than appears, because it arrives while the user is already
/// moving and something that pops into a moving picture reads as a glitch. It
/// keeps its place in the tree at zero opacity so the fade has something to
/// fade, and `IgnorePointer` means an invisible button cannot be pressed by
/// accident — an invisible tap target in the corner of the writing surface
/// would be a miserable thing to have to report.
class _JumpButton extends StatelessWidget {
  const _JumpButton({
    required this.visible,
    required this.toTop,
    required this.onTap,
  });

  final bool visible;

  /// True when the finger is already at the end, so what is on offer is the
  /// start. See `DayStreamState`: one control, pointing at the end you are not
  /// at, rather than two arrows that ask to be told apart.
  final bool toTop;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final label = toTop
        ? L.of(context).dayStartOfDay
        : L.of(context).dayEndOfDay;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.duration(context),
        curve: Motion.curve,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Tooltip(
            message: label,
            child: Material(
              // `raised` rather than `surface`: it sits on top of entries that
              // are themselves drawn on `surface`, and a control the same
              // colour as the thing behind it is a shape rather than a button.
              color: c.raised,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: kMinTouchTarget,
                  height: kMinTouchTarget,
                  child: AnimatedRotation(
                    // The arrow turns over rather than being swapped. Two
                    // glyphs cross-fading inside a circle reads as a flicker;
                    // one arrow turning reads as the same arrow changing its
                    // mind, which is what has actually happened.
                    turns: toTop ? 0.5 : 0,
                    duration: Motion.duration(context),
                    curve: Motion.curve,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: c.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
