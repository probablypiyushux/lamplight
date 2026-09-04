import 'dart:async';
import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/progress/writing_session.dart';
import '../../core/db/database.dart';
import 'day_pages.dart';
import 'day_header.dart';
import 'day_line.dart';
import '../../core/db/day_note_repository.dart';
import '../../core/db/entry_repository.dart';
import '../../core/db/folder_repository.dart';
import '../../core/plain_words.dart';
import '../../core/platform/capture.dart';
import '../../core/platform/document_store.dart';
import '../../core/platform/hand_off.dart';
import '../../core/platform/sharing.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../design/announce.dart';
import '../../design/components.dart';
import '../../design/paper.dart';
import '../../design/tokens.dart';
import '../backup/backup_screen.dart';
import '../backup/silent_backup.dart';
import '../calendar/calendar_sheet.dart';
import '../capture/attachment_blocks.dart';
import '../capture/capture_bar.dart';
import '../capture/import_queue.dart';
import '../capture/size_sheet.dart';
import 'day_composer.dart';
import 'day_stream.dart';
import 'entry_block.dart';
import 'revisions_sheet.dart';
import '../capture/import_strip.dart';
import '../capture/transcription_queue.dart';
import '../capture/recording_sheet.dart';
import '../folders/folder_picker.dart';
import '../folders/folders_screen.dart';
import '../media/document_viewer.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

/// The day view — the home screen. `03-product/DATA-MODEL.md` and UX-FLOWS §2.
///
/// **A vertical stream of blocks in the order you added them, like a chat with
/// yourself.** Not a form. A form asks you to fill it in; a stream just
/// accumulates, and the friction of a form is exactly what makes journalling
/// apps die after nine days.
///
/// Today is already the screen. No home screen, no dashboard, no "what would
/// you like to do?". Yesterday is one swipe right, and any day in your life is
/// two taps away through the date at the top.
///
/// ── WHAT MOVED, AND WHY IT MATTERS MORE THAN IT SOUNDS ────────────────────
///
/// The whole screen used to live **inside** the `PageView`, one complete copy
/// per day. Swiping therefore slid the header, the composer and the capture bar
/// across as well, and they were rebuilt from scratch on the other side.
/// Reported exactly right: *"when I swipe my days, the down menu also gets
/// swiped — it feels like the down menu is new in all the day, but it isn't."*
///
/// That is not a cosmetic complaint, it is a correct reading of what the screen
/// was saying. Motion means *this thing moved*. Sliding a control that has not
/// changed tells the user it has, and after a few swipes they stop trusting the
/// interface to tell them where they are.
///
/// So now the `PageView` contains **only the day's own content**. The date, the
/// composer and the capture bar are outside it, fixed, and they belong to the
/// app rather than to any one day. Three consequences, all good:
///
///   * swiping moves the material and nothing else, which is what swiping means;
///   * the composer no longer scrolls away at the bottom of a long day;
///   * one composer exists instead of one per page, so switching days cannot
///     lose what is half-typed — it is flushed to the day it was typed on.
class DayScreen extends StatefulWidget {
  const DayScreen({
    super.key,
    required this.vault,
    required this.settings,
    required this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;

  /// Told whenever this screen writes, so an automatic backup knows there is
  /// something new to back up. Without it, every lifecycle event would rewrite
  /// an identical vault — battery and storage spent protecting nothing that was
  /// not already protected.
  final SilentBackup silentBackup;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> with WidgetsBindingObserver {
  static const int _todayPage = DayPages.origin;

  late final PageController _pages = PageController(initialPage: _todayPage);
  late final DateTime _today = _startOfDay(DateTime.now());
  late final DayPages _map = DayPages(_today);

  /// Which day is on screen. Drives the header, the composer's target day and
  /// every capture action.
  late DateTime _date = _today;
  int _page = _todayPage;

  /// Which way the last day change went, so the header slides with it.
  bool _goingForward = true;

  late final EntryRepository _repo = EntryRepository(
    widget.vault.database,
    attachments: widget.vault.attachments,
  );

  /// The one line that names a day. **`PLAN.md` §7.0-E, first item.**
  late final DayNoteRepository _dayNotes =
      DayNoteRepository(widget.vault.database);

  /// How much is in the vault, for the backup banner and nothing else.
  ///
  /// ── WHY THE BANNER NEEDS THIS AT ALL ──────────────────────────────────
  ///
  /// The never-backed-up reminder used to be a **calendar** — silence for
  /// fourteen days — and on 28 August a three-day-old vault was destroyed
  /// inside that silence. `AppSettings.backupReminderDueFor` now asks how much
  /// there is to lose instead, and this is where the answer comes from.
  ///
  /// Read **once**, when the screen is built, and again after a write that
  /// might have crossed the line. Not watched: a banner does not need to be
  /// right within a frame, it needs to be right today, and a live `COUNT(*)`
  /// re-running on every keystroke is the kind of thing round ten spent a day
  /// removing.
  ({int entries, int days}) _vaultSize = (entries: 0, days: 0);

  Future<void> _measureVault() async {
    if (!widget.vault.isUnlocked) return;
    final stats = await _repo.stats();
    if (!mounted) return;
    // Only when it changes the answer, so this never causes a rebuild that
    // draws the same thing.
    if (stats.entries != _vaultSize.entries || stats.days != _vaultSize.days) {
      setState(() => _vaultSize = stats);
    }
  }
  // ISSUE 2A. The only place in the app that imports a video, so the only
  // place that needs to know what he chose about compressing one.
  late final AttachmentImporter _importer = AttachmentImporter(
    widget.vault,
    videoQuality: () => widget.settings.videoQuality,
    // ISSUE 6. The same, for a photograph — used by every path that does not
    // go through the sheet: a share from another app, the camera, the journal
    // importer.
    photoQuality: () => widget.settings.photoQuality,
  );

  /// Everything waiting to be added to the vault. **ISSUES 12, 13, 14.**
  ///
  /// Owned here rather than app-wide because importing needs an unlocked vault
  /// and this screen exists exactly as long as one does — locking pops the
  /// route, which disposes this, which scrubs whatever is still waiting.
  late final ImportQueue _queue =
      ImportQueue(importer: _importer, vault: widget.vault);

  /// Voice notes waiting to be written down. **ISSUE 15.**
  ///
  /// Owned beside the import queue and for the same reason: both need an
  /// unlocked vault, and this screen exists exactly as long as one does.
  late final TranscriptionQueue _transcripts = TranscriptionQueue(
    importer: _importer,
    vault: widget.vault,
    settings: widget.settings,
  );

  // ── The composer ───────────────────────────────────────────────────────────
  final _composer = TextEditingController();

  /// How long this entry has actually been worked on. Reported once
  /// when it is saved and then forgotten — see [WritingSession] for
  /// why it is deliberately not a total, a streak or a target.
  final _writing = WritingSession();
  final _composerFocus = FocusNode();
  String? _draftEntryId;
  Timer? _debounce;
  bool _saving = false;

  /// What the composer's own controls need to know, and nothing else.
  ///
  /// The composer's listener used to call `setState`, which rebuilt the entire
  /// day on every keystroke — the header, the banner, the stream and every
  /// block in it, six or eight times a second at a comfortable typing speed.
  /// You felt it as the keyboard lagging behind your thumbs. Only the twenty
  /// pixels that actually change now rebuild.
  final _composerState = ValueNotifier<ComposerState>(
      const ComposerState(hasText: false, saving: false, hasDraft: false));

  /// The entry currently open for editing, if any. Null almost always.
  OpenEditor? _editor;

  String get _dayKey => EntryRepository.dayKeyFor(_date);

  bool get _isToday => _page == _todayPage;

  @override
  void initState() {
    super.initState();
    unawaited(_measureVault());
    WidgetsBinding.instance.addObserver(this);
    _composer.addListener(_onTyped);
    _queue.addListener(_onQueueChanged);
    // ISSUE 15. Whatever is still without a transcript, worked through
    // quietly. Started here rather than on a timer: this screen appearing is
    // exactly the moment the vault is open and nothing else is happening.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _transcripts.catchUp().ignore());
    // ISSUE 13. Anything shared into Lamplight before the vault was open is
    // waiting on the platform side; this screen only exists once it is open.
    WidgetsBinding.instance.addPostFrameCallback((_) => _collectShared());
  }

  /// Takes whatever another app handed us and puts it on today. **ISSUE 13.**
  ///
  /// *"Any app, any file → shared → Lamplight → saved as a note, according to
  /// whatever the file is, on that day, that time."*
  ///
  /// **Onto today, and not onto whichever day happens to be on screen.** He
  /// wrote *"on that day, that time"*, and the day a thing was shared is today
  /// — somebody who has swiped back to March to read something, and then
  /// shares a photograph in from their gallery, has not said anything about
  /// March. The screen moves to today so what happened is visible; a note
  /// arriving on a page nobody is looking at is the same as it not arriving.
  ///
  /// Files and words are handled by the paths that already exist —
  /// `_capture` and `_repo.createText` — rather than by anything new. A shared
  /// photograph is encrypted and its temp file scrubbed by exactly the code
  /// that does it for the camera.
  Future<void> _collectShared() async {
    if (!mounted || !widget.vault.isUnlocked) return;
    if (!await Sharing.hasPending()) return;
    final shared = await Sharing.take();
    if (!mounted || shared.isEmpty) return;

    if (!_isToday) _pages.jumpToPage(_todayPage);

    final words = shared.text;
    if (words != null && words.isNotEmpty) {
      await _repo.createText(
        id: widget.vault.newId(),
        dayKey: EntryRepository.dayKeyFor(_today),
        body: words,
      );
      widget.silentBackup.markDirty();
    }

    if (shared.files.isNotEmpty) {
      // Through the ordinary import, which handles the group id for a
      // multi-share, the progress bar, the failure wording and the scrub.
      await _capture(() async => shared.files);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_sharedMessage(context, shared)),
        duration: const Duration(seconds: 3),
      ));
  }

  String _sharedMessage(BuildContext context, SharedContent shared) {
    final l = L.of(context);
    final n = shared.files.length;
    final hasWords = shared.text != null && shared.text!.isNotEmpty;
    if (n == 0) return l.daySavedToToday;
    if (n == 1) return hasWords ? l.daySavedToToday : l.dayAddedToToday;
    return l.dayAddedThings(n);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queue.removeListener(_onQueueChanged);
    _queue.dispose();
    _transcripts.dispose();
    _debounce?.cancel();
    // `adopt: false`, and it is not a detail. The ordinary autosave calls
    // `setState` to hand the newly created row's id to the list as the live
    // draft — and calling `setState` from inside `dispose` trips
    // `_lifecycleState != _ElementLifecycle.defunct`. There is nothing to hand
    // it to here: the list is being torn down with everything else.
    //
    // The reachable version of that is worth writing down, because it is not
    // theoretical: type a word, do not pause long enough for the 400 ms
    // debounce, and let the vault lock. Locking pops every route, which
    // disposes this screen, which flushes — and the app throws on the way out
    // of a perfectly ordinary lock. Found by ISSUE 4's test, which is the first
    // one to type and leave without waiting.
    unawaited(_write(
      dayKey: _dayKey,
      text: _composer.text.trim(),
      draftId: _draftEntryId,
      adopt: false,
    ));
    _editor?.dispose();
    _composer.dispose();
    _composerFocus.dispose();
    _composerState.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// ── The half-typed sentence, on the way out ─────────────────────────────
  ///
  /// `SECURITY-ARCHITECTURE.md` §7 wants an immediate flush on backgrounding,
  /// screen-off and an incoming call, and it was only ever happening on the
  /// 400 ms debounce and on dispose. The debounce usually won the race with
  /// the lock, and "usually" is not a word that belongs anywhere near somebody
  /// losing a sentence.
  ///
  /// `inactive` rather than `paused`: it is the first lifecycle event of going
  /// away and it arrives while the vault is still open, so the write can
  /// actually complete. By `paused` the keys are gone.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _debounce?.cancel();
      // ══ THE LAST SENTENCE. `PLAN.md` §7.0-E, "write-ahead the composer" ══
      //
      // This was two bare calls — `unawaited(_flush())` and
      // `_editor?.flushNow()` — and it was **round nine's ISSUE 5 in the
      // composer**, which nobody had noticed because losing the tail of a
      // sentence looks like never having typed it.
      //
      // The sequence, on every single exit:
      //
      //   1. `inactive` arrives. The flush starts. Since 25 August the
      //      database is on a **worker isolate**, so this is a round trip and
      //      not a local call — it has not finished when this method returns.
      //   2. `hidden` arrives, within a frame or two. `app.dart` calls
      //      `vault.onBackgrounded()`, which locks.
      //   3. Locking closes the database and destroys the keys. Whatever the
      //      flush had not yet written is gone.
      //
      // So the exposure was not the 400 ms of debounce that
      // `SECURITY-ARCHITECTURE.md` §7 prices — the debounce is cancelled right
      // above. It was **everything typed since the last autosave**, lost on the
      // way out, every time the timing went the wrong way.
      //
      // `whileSettling` is the mechanism round nine built for exactly this and
      // it is used here for exactly the reason it exists: a write the user has
      // already committed to, bounded by `_settleLimit`, with the lock
      // happening anyway if it overruns. It is **not** the trade `PLAN.md`
      // refuses for backups — read the note on `Vault.whileSettling` before
      // widening this to anything larger than one row.
      //
      // The counter is incremented synchronously by `whileSettling` before its
      // first `await`, so by the time `hidden` reaches `app.dart` the lock
      // already knows there is something to wait for.
      unawaited(widget.vault.whileSettling(() async {
        await _flush();
        await _editor?.flushNow();
      }));
    }
    // ISSUE 13. A share into an app that was already running arrives through
    // `onNewIntent` rather than `onCreate`, and brings the app forward. This
    // is the moment to notice it — checked rather than assumed, because
    // `resumed` fires every time the user comes back from anything.
    if (state == AppLifecycleState.resumed) {
      unawaited(_collectShared());
    }
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _goToDate(DateTime date) {
    // Jump rather than animate. Sliding through four hundred days would be
    // motion that means nothing, which the design system bans, and it would
    // build every page on the way.
    _pages.jumpToPage(_map.pageFor(date));
  }

  void _goBy(int delta) => _pages.animateToPage(
        _page + delta,
        duration: Motion.duration(context),
        curve: Motion.curve,
      );

  /// The day changed under the composer.
  ///
  /// ══ ROUND NINE, ISSUE 4 — "IT WRITES ONLY ON TODAY" ═══════════════════════
  ///
  /// *"Static boxes — opens keyboard but when I write they don't write — it
  /// feels like a way to open keyboard! It writes only on TODAY! And in other
  /// pages it doesn't write just opens the keyboard!"*
  ///
  /// This method used to `await _flush()` **before** moving, and every word of
  /// his report follows from that one `await`.
  ///
  /// The `PageView` has already moved by the time this is called — the user is
  /// looking at the new day. But `_page` and `_date` do not move until after
  /// the flush, and the flush is a database write. So for as long as that write
  /// takes, the screen shows one day and the state believes another, and three
  /// things are wrong at once:
  ///
  ///   * `composer: page == _page` is false for the page on screen, so the
  ///     visible day **has no composer**;
  ///   * `EmptyDay(onTap: composer == null ? null : …)` is therefore inert, so
  ///     the static box he taps does nothing at all;
  ///   * and the composer that still exists — offscreen, on the day he just
  ///     left — still holds the caret, because nothing moved focus. The
  ///     keyboard is up. Whatever he types goes into it, and `_flush` files it
  ///     under `_date`, **which is still the old day**.
  ///
  /// Which is, exactly and literally, "it writes only on today".
  ///
  /// It is a race, so it never reproduced on a laptop where the write finishes
  /// in under a frame — and it got *worse* on 25 August, when the database
  /// moved to a background isolate and every write grew a round trip. A fix
  /// for slowness made a correctness bug visible, which is the kind of thing
  /// that only ever shows up on somebody's actual phone.
  ///
  /// **So the move happens first, synchronously, and the words follow.** The
  /// new day is live in the same frame the user sees it: composer attached,
  /// static box wired, caret in the right place. What was in the composer is
  /// captured before any of that and written afterwards, to the day it was
  /// typed on, by [_write] — which is why that takes its day key as an argument
  /// instead of reading `_date` at the moment it happens to run.
  Future<void> _onPageChanged(int page) async {
    _debounce?.cancel();

    // Captured before the move, because after it they belong to another day.
    final leavingKey = _dayKey;
    final leavingDraft = _draftEntryId;
    final leavingText = _composer.text.trim();

    if (!mounted) return;
    setState(() {
      _goingForward = page > _page;
      _page = page;
      _date = _map.dateFor(page);
      _draftEntryId = null;
      _composer.clear();
      _editor?.dispose();
      _editor = null;
    });
    _publishComposerState();

    // `adopt: false` — a row created here belongs to the day being left, and
    // the composer has already moved on. Adopting its id as the live draft
    // would tie the new day's composer to yesterday's row, which is the same
    // class of bug in the other direction.
    await _write(
      dayKey: leavingKey,
      text: leavingText,
      draftId: leavingDraft,
      adopt: false,
    );
  }

  // ── Autosave ───────────────────────────────────────────────────────────────

  void _onTyped() {
    widget.vault.touch(); // typing is activity; do not idle-lock mid-sentence
    _writing.typed();
    _publishComposerState();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _flush);
  }

  void _publishComposerState() {
    _composerState.value = ComposerState(
      hasText: _composer.text.trim().isNotEmpty,
      saving: _saving,
      hasDraft: _draftEntryId != null,
    );
  }

  /// The ordinary autosave: whatever the composer holds, for the day on screen.
  Future<void> _flush() => _write(
        dayKey: _dayKey,
        text: _composer.text.trim(),
        draftId: _draftEntryId,
        adopt: true,
      );

  /// Writes [text] to [dayKey], as a new row or as an edit of [draftId].
  ///
  /// **[adopt] is the whole reason this takes arguments rather than reading the
  /// screen's state.** True for the ordinary autosave, where a newly created
  /// row becomes the live draft the composer keeps updating. False when
  /// flushing a day that has just been swiped away from — see [_onPageChanged],
  /// and **ISSUE 4**, which was this method reading `_date` at the moment it
  /// happened to run rather than at the moment the words were typed.
  Future<void> _write({
    required String dayKey,
    required String text,
    required String? draftId,
    required bool adopt,
  }) async {
    if (!widget.vault.isUnlocked) return;

    if (text.isEmpty) {
      if (draftId != null) {
        await _repo.discardDraft(draftId);
        // Through setState for the same reason as the insert below: the list
        // is given this id and has to be told when it changes. Only when this
        // is still the live draft — clearing it otherwise would blank a
        // composer that has already moved to another day.
        if (adopt) {
          if (mounted) {
            setState(() => _draftEntryId = null);
          } else {
            _draftEntryId = null;
          }
          _publishComposerState();
        }
      }
      return;
    }

    if (adopt) {
      _saving = true;
      _publishComposerState();
    }
    try {
      if (draftId == null) {
        final id = widget.vault.newId();
        // ══ ROUND FIVE, ISSUE 14 — THE DUPLICATE ═══════════════════════════
        //
        // *"Duplicates while I write. Why this double kind of thing. It's a
        // shit. I need it to get fixed and improved."* He is right, and the
        // interesting part is that the defence against this was already here
        // and already correct — the id is set **before** the await, exactly as
        // the old comment below explains, and `_DayList` filters
        // `e.id != widget.draftEntryId` for exactly this reason.
        //
        // What was missing is that neither of those does any good unless the
        // widget holding the list is told. `_draftEntryId` was a plain field
        // assignment, and the only thing called afterwards was
        // `_publishComposerState`, which pushes into a `ValueNotifier` that
        // rebuilds the "Saved / New block" row and nothing else. So the
        // sequence was: insert the row, the day's live query fires, `_DayList`
        // rebuilds — still holding the **previous** `draftEntryId`, which is
        // null, because its parent never rebuilt — and the filter compares
        // every id against null and keeps them all. The draft is drawn as a
        // finished entry directly above the composer that still holds it.
        //
        // It cleared itself on the next unrelated rebuild, which is why this
        // looked intermittent and why it survived a round: a defect that
        // vanishes when you look away.
        //
        // `setState`, therefore. It is one word and it is the whole fix, and
        // the mechanism it repairs is the one the original author documented.
        //
        // Set before the await, not after. The list is a live query: the insert
        // makes the row appear immediately, and if the screen does not yet know
        // that row is the draft it renders it as a finished entry directly above
        // the composer still holding the same words. You watch yourself type
        // the sentence twice.
        if (adopt) {
          if (mounted) {
            setState(() => _draftEntryId = id);
          } else {
            _draftEntryId = id;
          }
        }
        await _repo.createText(id: id, dayKey: dayKey, body: text);
      } else {
        await _repo.updateBody(draftId, text);
      }
      widget.silentBackup.markDirty();
    } finally {
      if (adopt) {
        _saving = false;
        if (mounted) _publishComposerState();
      }
    }
  }

  /// Put the caret on the page. **ISSUE 9, and then ROUND EIGHT ISSUE 6.**
  ///
  /// Called by the empty day's sheet — the pencil — and by a tap on the page's
  /// blank space. Writing is no longer a button on a bar; it is what tapping
  /// the page does, which is what every notes app on the phone does and what he
  /// meant by *"typing doesn't feel like writing on any kind of notes app"*.
  ///
  /// ══ ROUND EIGHT, ISSUE 6 — WHY THE PENCIL STOPPED WORKING ═══════════════
  ///
  /// *"The static boxes and their pencil? Those still don't work! … I want you
  /// to let the app work as it is! Don't change anything which changes how the
  /// type comes out! And keyboard opens — I want you to make that pencil icon
  /// work! Not change any dynamics!"* And the detail that names the bug:
  /// *"Sometimes what happens? If the pencil is working for one day — and I
  /// swipe to next day pencil stops working on that day."* On the screenshot,
  /// an arrow to the pencil: **"Doesn't works anymore."**
  ///
  /// Round six measured this control, found it wired up, and concluded it
  /// already worked. It did work — the first time. This is the whole of what
  /// was wrong, and it was three lines away from where anybody looked:
  ///
  /// **`if (_composerFocus.hasFocus) return;`**
  ///
  /// That guard reads as "already writing, nothing to do", and on Android it is
  /// false about half the time. Dismissing the keyboard with the system Back
  /// button **hides the keyboard without moving focus** — the field keeps the
  /// caret, `hasFocus` stays true, and the guard then swallows every subsequent
  /// tap on the pencil. From the outside the control is simply dead, and it
  /// stays dead until something else steals focus. That is exactly the shape he
  /// described: works, then stops, with no visible reason.
  ///
  /// The day swipe is the same fault reached by a different road.
  /// `_onPageChanged` clears the composer and rebuilds, and the composer is
  /// rebuilt into the **new page's** list — a different place in the tree, so
  /// the old `TextField` is disposed and this node is detached and reattached
  /// across a frame boundary. `FocusNode.requestFocus()` on a node whose
  /// `parent` is null returns silently without focusing anything. Tap the
  /// pencil in that window and nothing happens, for ever, because nothing tries
  /// again.
  ///
  /// So both roads are handled, and neither of them changes how typing behaves
  /// once the caret is there — which is the part he asked twice not to touch:
  ///
  ///   * **Detached** — wait one frame for the composer to be in the tree, then
  ///     ask again. One retry, not a loop: if it is still not there, the page
  ///     genuinely has no composer and doing nothing is correct.
  ///   * **Focused but no keyboard** — ask the platform for the keyboard
  ///     directly. `requestFocus` cannot help, because focus is exactly what is
  ///     not missing.
  void _startWriting() {
    // Detached: the composer is not in the tree this frame. Requesting focus
    // now is a silent no-op, which is what "doesn't work anymore" looked like.
    if (_composerFocus.parent == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showKeyboard();
      });
      return;
    }
    _showKeyboard();
  }

  /// The caret, and the keyboard that has to come with it. **ISSUE 6.**
  void _showKeyboard() {
    if (_composerFocus.parent == null) return;
    if (_composerFocus.hasFocus) {
      // The field never lost the caret — the keyboard was dismissed out from
      // under it with the Back button. There is no focus change to make, so
      // there is nothing `requestFocus` can do; the keyboard itself is what is
      // being asked for.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      return;
    }
    _composerFocus.requestFocus();
  }

  /// Finish the current block and start a new one.
  ///
  /// ══ OPTIMISTIC. `PLAN.md` §8.5, §7.0-E ═══════════════════════════════════
  ///
  /// > *"Optimistic writes — §8.5 calls it Telegram's whole feel in one idea.
  /// > Partly true already — the draft entry does appear — so **measure what
  /// > is actually missing** before building anything."*
  ///
  /// Measured, and one thing was: **this method used to `await _flush()`
  /// first.** Since 25 August the database is on a worker isolate, so that
  /// await is a round trip — and for its whole length the text field still held
  /// the finished sentence, the caret had not come back, and tapping the button
  /// again did nothing. On a laptop that is invisible. On a phone, mid-thought,
  /// it is the pause that makes an app feel like it is thinking about whether
  /// to let you continue.
  ///
  /// Nothing else needed building. The draft row **already exists** — autosave
  /// wrote it 400 ms ago — and it is invisible only because `draftEntryId`
  /// filters it out of the stream. Clearing that filter *is* the optimistic
  /// write: the block appears on the next frame, from data already in the
  /// database, with nothing to roll back if the trailing write fails.
  ///
  /// The one case that still waits is somebody typing a whole sentence and
  /// tapping **New block** inside 400 ms, before the first autosave. There the
  /// row genuinely does not exist yet and pretending otherwise would mean
  /// drawing an entry the vault does not have.
  ///
  /// `adopt: false` is the load-bearing argument: the row being written must
  /// **not** become the live draft, because the composer has already moved on
  /// to the next block. That is the same flag, for the same reason, as the day
  /// swipe — see `_write`.
  Future<void> _newBlock() async {
    _debounce?.cancel();

    // Snapshotted before anything is cleared. Everything below runs after the
    // composer has been emptied, so reading these later would write a blank.
    final text = _composer.text.trim();
    final draftId = _draftEntryId;
    final dayKey = _dayKey;

    _composer.clear();
    setState(() => _draftEntryId = null);
    _publishComposerState();
    _composerFocus.requestFocus();
    unawaited(HapticFeedback.selectionClick());

    await _write(dayKey: dayKey, text: text, draftId: draftId, adopt: false);

    // ── "You wrote for six minutes." Round nineteen. ───────────────────
    //
    // Said once, here, about the entry that was just finished — and then
    // forgotten, because nothing about it is stored. `WritingSession` is
    // where the boundary is argued: this is an observation about effort
    // already spent, which is why it can be encouraging without becoming a
    // target. It is shown *after* the writing, it has nothing to compare
    // itself to, and it says nothing at all below a minute.
    //
    // ETHICAL-DESIGN.md forbids the version of this feature that keeps a
    // running total. If somebody asks for one later, that document is the
    // argument and this comment is where it was already had.
    final spent = _writing.finish();
    if (spent != null && mounted) {
      // `announce`, never a hand-built bar. Round eighteen found a `Deleted.`
      // message that survived backgrounding, a re-lock and an unlock, because
      // a SnackBar's dismiss timer is armed inside the messenger's build and
      // nothing tries again if that rebuild does not land. See
      // `design/announce.dart`. `a_message_goes_away_test.dart` counts the
      // raw calls and refuses a twenty-sixth — it caught this line when it was
      // written the other way, which is the ratchet doing its job.
      announce(context, L.of(context).youWroteForMinutes(spent.inMinutes));
    }

    // The one write that reliably adds an entry rather than editing one, so it
    // is the cheapest place to notice that the vault has grown into something
    // worth protecting.
    unawaited(_measureVault());
  }

  // ── Editing an entry that already exists ───────────────────────────────────

  void _startEditing(Entry entry) {
    _debounce?.cancel();
    unawaited(_flush());

    _editor?.dispose();
    final editor = OpenEditor(entry.id, entry.body ?? '', _repo);
    editor.controller.addListener(() {
      widget.vault.touch();
      editor.schedule();
    });
    setState(() => _editor = editor);
  }

  Future<void> _finishEditing() async {
    final editor = _editor;
    if (editor == null) return;
    editor.debounce?.cancel();
    final text = editor.controller.text.trim();
    final id = editor.entryId;

    setState(() => _editor = null);
    editor.dispose();

    if (text.isEmpty) {
      // Emptied an entry that already existed. That is a delete, and it is
      // reversible like every other delete — ETHICAL-DESIGN.md.
      await _delete(id);
    } else {
      await _repo.updateBody(id, text);
      widget.silentBackup.markDirty();
    }
  }

  /// Marks or unmarks an entry, and says which happened.
  ///
  /// Announced rather than silent: the mark is a small dot on a rail and the
  /// menu has just closed over it, so without a word the tap looks like it did
  /// nothing — test 6, where a control that appears to do nothing is the same
  /// defect as a crash in better clothes.
  Future<void> _toggleMarker(Entry entry) async {
    final marking = entry.marker == null;
    await _repo.setMarker(
      entry.id,
      marking ? EntryRepository.markMattered : null,
    );
    widget.silentBackup.markDirty();
    if (!mounted) return;
    announce(
      context,
      marking ? L.of(context).entryMarked : L.of(context).entryMarkRemoved,
    );
  }

  /// Soft-deletes an entry and says so, with the undo that catches the mis-tap
  /// you notice straight away. The trash catches the one you notice on Thursday.
  ///
  /// The parameter is `words` rather than `announce` because `announce` is now
  /// the function that says them -- see `design/announce.dart` for why a bar in
  /// this app can no longer be left to dismiss itself.
  Future<void> _delete(String id, {String? words}) async {
    await _repo.softDelete(id);
    widget.silentBackup.markDirty();
    if (!mounted) return;
    announce(
      context,
      words ?? L.of(context).entryDeleted,
      action: SnackBarAction(
        label: L.of(context).actionUndo,
        onPressed: () => _repo.restore(id),
      ),
    );
  }

  /// Opens a folder from the ribbon under an entry. **`PLAN.md` §9.1.**
  ///
  /// By **name**, because that is what the ribbon has: the day's membership
  /// query returns names rather than ids, so that drawing a chip costs no
  /// second lookup. Resolving it back here is one indexed read on a table with
  /// as many rows as the user has folders.
  ///
  /// A folder that has been renamed or deleted between the day being drawn and
  /// the chip being tapped does nothing at all rather than opening an empty
  /// screen — the ribbon is a live query, so the chip is already on its way
  /// out.
  Future<void> _openFolderNamed(String name) async {
    final folders = await FolderRepository(widget.vault.database).all();
    final folder = folders.where((f) => f.name == name).firstOrNull;
    if (folder == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FolderContentsScreen(
          vault: widget.vault,
          folder: folder,
          onOpenDay: _goToDate,
          onChanged: widget.silentBackup.markDirty,
        ),
      ),
    );
  }

  /// The menu on an entry.
  ///
  /// A sheet rather than a context menu, because it has to be reachable
  /// without a long-press for anyone who cannot hold one.
  Future<void> _entryMenu(Entry entry) async {
    final hasAttachment = entry.attachmentId != null;
    final hasWords = (entry.body ?? '').trim().isNotEmpty;
    // `PLAN.md` §9.6. Asked before the sheet opens so the row can be absent
    // rather than opening an empty one — an entry written once and never
    // touched has no earlier versions, and offering to show them would be the
    // same defect as silence, one politeness removed.
    final earlier = hasWords ? await _repo.revisionsFor(entry.id) : const [];
    if (!mounted) return;
    final kind = switch (entry.type) {
      'photo' => 'photo',
      'voice' => 'recording',
      'video' => 'video',
      _ => 'file',
    };

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.lamplight.surface,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Space.x2),
            // ── "This one mattered" ──────────────────────────────────────
            //
            // The `marker` column has existed on two tables since the first
            // commit and nothing has ever written to it. FEATURE-RANKING.md
            // ranks it 16th and describes exactly what it is for: *"Not a mood
            // scale. Enables 'read back what mattered'."*
            //
            // One tap, no scale, no number. A scale would ask somebody to rate
            // their own day, which turns writing into scoring — and PLAN.md 10
            // rules out everything downstream of that. This asks nothing and
            // only answers a question the person already had: where was that
            // one. Search, with an empty box, is where they get it back.
            LampTile(
              title: entry.marker == null
                  ? L.of(context).entryMattered
                  : L.of(context).entryNoLongerMarked,
              subtitle: entry.marker == null
                  ? L.of(context).entryFindAgain
                  : null,
              icon: entry.marker == null
                  ? Icons.star_border_rounded
                  : Icons.star_rounded,
              onTap: () {
                Navigator.of(sheet).pop();
                _toggleMarker(entry);
              },
            ),
            LampTile(
              title: hasAttachment
                  ? (hasWords
                      ? L.of(context).entryEditWords
                      : L.of(context).entryAddNote)
                  : L.of(context).actionEdit,
              icon: Icons.edit_outlined,
              onTap: () {
                Navigator.of(sheet).pop();
                _startEditing(entry);
              },
            ),
            // ── PLAN.md §9.6 — "the rows are written and unreachable" ─────
            //
            // They had been since schema version 1: every edit writes the old
            // text to `revisions`, and the vault has been carrying all of it —
            // into the backup, into the export — and giving none of it back.
            // All of the cost and none of the value.
            if (earlier.isNotEmpty)
              LampTile(
                title: L.of(context).entryEarlierVersions(earlier.length),
                subtitle: L.of(context).entryRevisionsNote,
                icon: Icons.history,
                onTap: () {
                  Navigator.of(sheet).pop();
                  showRevisions(
                    context: context,
                    repository: _repo,
                    entry: entry,
                  );
                },
              ),
            LampTile(
              title: L.of(context).folderAddTo,
              subtitle: L.of(context).entryStaysOnDay,
              icon: Icons.folder_outlined,
              onTap: () {
                Navigator.of(sheet).pop();
                showFolderPicker(
                  context: context,
                  vault: widget.vault,
                  entryId: entry.id,
                  settings: widget.settings,
                  // `PLAN.md` §9.1's sentence names the actual day, because
                  // "Still on 4 March" is about the thing in front of the
                  // person and "an entry can be in several places" is not.
                  dayLabel: _dayInWords(context, entry.dayKey),
                  onChanged: widget.silentBackup.markDirty,
                );
              },
            ),
            if (hasAttachment) ...[
              LampTile(
                title: L.of(context).entrySaveCopy,
                subtitle: L.of(context).entrySaveCopyNote,
                icon: Icons.save_alt,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _exportAttachment(entry);
                },
              ),
              // ROUND FIVE, ISSUE C — "Remove" is gone as a word.
              //
              // *"Why do we have two different wording — Remove / Delete? Keep
              // the wording same."* He is right, and the wording was the least
              // of it: the two words also meant two different fates, one
              // recoverable and one not. See `removeAttachment` for that half.
              //
              // Both rows say **Delete** now and differ only in what they say
              // is being deleted, which is the actual difference between them.
              // A single verb, a different object — the way a menu should read.
              LampTile(
                title: L.of(context).entryDeleteKind(kind),
                subtitle: hasWords ? L.of(context).entryKeepsWords : null,
                icon: Icons.hide_image_outlined,
                danger: true,
                onTap: () {
                  Navigator.of(sheet).pop();
                  _removeAttachment(entry, kind);
                },
              ),
            ],
            LampTile(
              title: hasAttachment
                  ? L.of(context).entryDeleteBlock
                  : L.of(context).actionDelete,
              icon: Icons.delete_outline,
              danger: true,
              onTap: () {
                Navigator.of(sheet).pop();
                _delete(entry.id);
              },
            ),
            const SizedBox(height: Space.x4),
          ],
        ),
      ),
    );
  }

  Future<void> _removeAttachment(Entry entry, String kind) async {
    final hasWords = (entry.body ?? '').trim().isNotEmpty;
    final undoId = await _importer.removeAttachment(entry.id);
    widget.silentBackup.markDirty();
    if (!mounted) return;
    // ROUND FIVE, ISSUE C — there is an Undo here now, because there is
    // something to undo.
    //
    // The old comment on this snackbar said an Undo button was deliberately
    // withheld because "the blob is overwritten and unlinked, so there is
    // nothing left to put back", and that an undo that could not undo would be
    // worse than none. Both sentences were honest and the second is still true.
    // What changed is the premise: this no longer destroys anything, so the
    // reason for having no undo has gone with it.
    //
    // The id restored is not always `entry.id`. When there were words to keep,
    // the picture now lives on a new row, so `removeAttachment` returns the id
    // that is actually in the trash rather than leaving the caller to guess.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(hasWords
              ? L.of(context).entryKindInTrashWords(kind)
              : L.of(context).entryKindInTrash(kind)),
          action: undoId == null
              ? null
              : SnackBarAction(
                  label: L.of(context).actionUndo,
                  onPressed: () => _repo.restore(undoId),
                ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Writes a decrypted copy to a place the user picks.
  ///
  /// **The only path in the app that puts plaintext content anywhere the user
  /// can see it, and it is deliberate.** `CLAUDE.md` rule 2 is about what the
  /// app leaves lying around on its own; a person asking for their own
  /// photograph back is not a leak, it is the point of keeping it.
  /// Open a document in place. **ISSUE 4.**
  ///
  /// Photos, videos and voice notes each own their own tap inside
  /// [AttachmentBlock] and never reach this. What does reach it is everything
  /// that used to be inert: a PDF, a text file, a picture that arrived through
  /// the file picker rather than the photo picker, and the formats Lamplight
  /// cannot draw — which now get a screen that says so rather than a menu that
  /// does not mention it.
  Future<void> _openAttachment(Entry entry) async {
    final attachment = await _importer.attachmentFor(entry);
    if (!mounted) return;
    // No attachment row yet — the metadata is still being read. The menu is the
    // right fallback, because it is what the long press would have given and
    // doing nothing is the one option that is never acceptable.
    if (attachment == null) return _entryMenu(entry);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentViewer(
          entry: entry,
          attachment: attachment,
          importer: _importer,
          onSaveCopy: () => _exportAttachment(entry),
          // ISSUE 13 — offered even for the kinds Lamplight can already show.
          onOpenWith: () => _openAttachmentElsewhere(entry),
        ),
      ),
    );
  }

  /// A GIF or sticker committed by the keyboard. **ISSUE 4 addon.**
  ///
  /// It arrives as bytes in memory rather than as a file, which is the shape
  /// [AttachmentImporter.importStream] already takes — the same door a voice
  /// recording comes through. So nothing new touches the disk on this path
  /// either, and there is no temp file to scrub because there was never one.
  ///
  /// `hasData` is false when the keyboard handed over a URI it expected us to
  /// resolve ourselves. Lamplight will not: resolving it means reading through
  /// a content provider we know nothing about, and the honest answer is to say
  /// so rather than to appear to have accepted something and silently drop it.
  Future<void> _insertFromKeyboard(KeyboardInsertedContent content) async {
    final data = content.data;
    if (!content.hasData || data == null || data.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.of(context).shareCouldNotAdd),
      ));
      return;
    }

    try {
      final extension = content.mimeType.split('/').last;
      await _importer.importStream(
        source: Stream.value(data),
        dayKey: _dayKey,
        type: 'photo',
        // A name it can be exported under later. The real name, if it had
        // one, is in a URI we deliberately do not resolve — so this is the
        // same case as a voice note, and had the same bug: every sticker and
        // every GIF anybody ever pasted arrived called `keyboard.gif`.
        originalName: stampedName(
          kind: 'Picture',
          at: DateTime.now(),
          extension: '.$extension',
        ),
        mimeType: content.mimeType,
      );
      widget.silentBackup.markDirty();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableFailure(context, e))));
    }
  }

  /// Lends this attachment to another app. **ISSUE 4, 13.**
  ///
  /// *"Give me an option to open the file anywhere else. Why? We can't provide
  /// anybody the best in file viewing."* And, crucially: *"a way the user
  /// doesn't download the file but is able to view this in another app."*
  ///
  /// The plaintext exists for as long as somebody is reading it and is
  /// overwritten and deleted the moment Lamplight is in front again — see
  /// `HandOff`, which also records the terms on which `CLAUDE.md` rule 2 was
  /// lifted for this one path.
  Future<void> _openAttachmentElsewhere(Entry entry) async {
    final attachment = await _importer.attachmentFor(entry);
    if (attachment == null) return;
    try {
      final opened = await HandOff.open(
        bytes: await _importer.bytesOf(attachment),
        name: attachment.originalName,
        mimeType: attachment.mimeType,
      );
      if (!mounted || opened) return;
      // Nothing on the phone claims the type. Said out loud, because a chooser
      // that never appears is indistinguishable from a button that does
      // nothing — which is the fault ISSUE 7 was about, in another place.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.of(context).openNothingCanOpen),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableFailure(context, e))));
    }
  }

  Future<void> _exportAttachment(Entry entry) async {
    final attachment = await _importer.attachmentFor(entry);
    if (attachment == null) return;

    final scratch = Directory('${widget.vault.root.path}/export-scratch');
    final file = File('${scratch.path}/${attachment.originalName}');
    try {
      await scratch.create(recursive: true);
      await file.writeAsBytes(await _importer.bytesOf(attachment), flush: true);
      final saved = await DocumentStore.export(
        source: file,
        suggestedName: attachment.originalName,
      );
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
                content: Text(L.of(context).entrySavedAs(saved))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableFailure(context, e))));
    } finally {
      // Overwrite, then delete. Same treatment as an import's temp file — it is
      // the user's content in the clear and it does not get to linger.
      if (await file.exists()) {
        await CapturedFile(
          file: file,
          name: attachment.originalName,
          mimeType: attachment.mimeType,
        ).scrub();
      }
      if (await scratch.exists()) {
        await scratch.delete(recursive: true).catchError((_) => scratch);
      }
    }
  }

  // ── Capture ────────────────────────────────────────────────────────────────

  /// Hands whatever the picker returned to the queue, and gets out of the way.
  ///
  /// ══ ISSUES 12, 13, 14 — WHY THIS IS FOUR LINES NOW ═══════════════════════
  ///
  /// It used to be the import loop itself: pick, then encrypt each file in
  /// turn, awaiting all of it here, with `_importing = true` across the whole
  /// thing. `_importing` greyed out all three capture buttons.
  ///
  /// So a one-gigabyte video was: the app goes dead for minutes, nothing says
  /// why, you cannot record a thought while you wait, and if you leave it is
  /// gone. Which is ISSUE 13 word for word — *"when one file is uploading I
  /// can't upload another — not even record voice, take photo, use gallery"* —
  /// and most of 12 and 14 as well.
  ///
  /// The loop lives in `ImportQueue` now. It is still strictly sequential, for
  /// the rule-2 reason written on that class: a file waits in the cache as
  /// plaintext until its turn is done. What changed is that waiting for it is
  /// no longer the screen's job, so nothing has to be disabled while it
  /// happens.
  Future<void> _capture(Future<List<CapturedFile>> Function() pick) async {
    _debounce?.cancel();
    await _flush();
    final dayKey = _dayKey;

    final List<CapturedFile> files;
    try {
      files = await pick();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableFailure(context, e))));
      return;
    }
    if (files.isEmpty) return; // They changed their mind. Not an error.

    // ── ISSUE 6 — "ask when uploading" ────────────────────────────────────
    //
    // Asked once for the whole pick, and only when there is something in it
    // that could be made smaller. A null answer is somebody dismissing the
    // sheet, which is them changing their mind about the import — so the files
    // are scrubbed rather than added, exactly as a cancelled pick would be.
    if (!mounted) return;
    final size = await askAboutSize(
      context: context,
      settings: widget.settings,
      files: files,
    );
    if (size == null) {
      for (final file in files) {
        await file.scrub();
      }
      return;
    }

    // Everything chosen in one go carries the same id, so the day view draws it
    // as one album rather than as fifteen stacked blocks. A single file gets no
    // id at all — an "album" of one is just a photograph. Decided per pick, so
    // that adding more while the first batch is still running makes a second
    // album rather than joining the first.
    _queue.add(
      files,
      dayKey: dayKey,
      groupId: files.length > 1 ? widget.vault.newId() : null,
      photoSize: size.photo,
      videoSize: size.video,
    );
  }

  /// The one sentence at the end of a batch. **ISSUE 12.**
  void _onQueueChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_queue.hasSummary) return;
    final summary = _queue.takeSummary();
    if (summary.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    if (summary.failure != null && summary.added == 0) {
      messenger.showSnackBar(
          SnackBar(content: Text(readableFailure(context, summary.failure!))));
      return;
    }

    // ── ISSUE 14 — said out loud rather than found later ─────────────────
    //
    // *"If I upload the file and then app gets closed the uploading stops."*
    // It does, and it cannot not — the whole argument is on `ImportQueue`.
    // What it must never do again is happen in silence. "The file never gets
    // there — idk what is it?" is a complaint about not being told at least as
    // much as about the loss.
    if (summary.abandoned > 0) {
      messenger.showSnackBar(SnackBar(
        // Whole sentences from the ARB, joined by a space. The English used to
        // be assembled from fragments — "Added 4. " plus a clause — which no
        // language can be translated into as a whole.
        content: Text(summary.added > 0
            ? '${L.of(context).importAdded(summary.added)} '
                '${L.of(context).importAbandoned(summary.abandoned)}'
            : '${L.of(context).importAbandoned(summary.abandoned)} '
                '${L.of(context).importNothingLeft}'),
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    // ── ISSUE 12, round six — the answer to "how do I know?" ─────────────
    //
    // Photos and videos have been re-encoded at import since round five, and
    // the only evidence was a number he had nothing to compare against. This
    // is the comparison, said once, at the moment it is true.
    //
    // **Only when there is something worth saying.** `humanSaving` returns null
    // below a tenth of a megabyte and null when nothing was saved, so a PDF or
    // a text file — stored exactly as they arrived — get no line, rather than a
    // claim of zero the app cannot stand behind.
    final saved = humanSaving(
      originalSize: summary.savedFrom == 0 ? null : summary.savedFrom,
      storedSize: summary.savedTo,
    );
    final counted = L.of(context).importAdded(summary.added);

    // ── ISSUE 10 — the end of a question that was asked ──────────────────
    //
    // > *"Video Size – when uploaded it does prompts but never resizes"*
    //
    // The resolution cap was on the wrong edge and that is fixed in
    // `Transcode.kt`. This is the other half: the transcoder has a dozen ways
    // to decline and every one of them used to be silence, so somebody who had
    // just been asked a question and answered it saw nothing happen and
    // nothing said. That is what makes a feature feel broken rather than
    // merely unlucky.
    //
    // Said **before** the saving line and instead of it, because when a clip
    // was kept whole there is no saving to report and this is the more useful
    // sentence. Nothing here names a codec: which one is missing is a fact
    // about the phone, it changes nothing anybody can do, and
    // `plain_language_test.dart` would fail the sentence that said it.
    final kept = switch (summary.videoKept) {
      CompressionOutcome.alreadySmall => L.of(context).importVideoAlreadySmall,
      CompressionOutcome.couldNot => L.of(context).importVideoCouldNotShrink,
      _ => null,
    };

    if (summary.failure != null) {
      messenger.showSnackBar(SnackBar(
          content: Text('$counted '
              '${L.of(context).importOneFailed(readableFailure(context, summary.failure!))}')));
    } else if (kept != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(saved != null ? '$counted · $saved · $kept' : '$counted · $kept'),
        duration: const Duration(seconds: 5),
      ));
    } else if (saved != null) {
      messenger.showSnackBar(SnackBar(content: Text('$counted · $saved')));
    } else if (summary.added > 1) {
      // Only worth saying for a batch. Confirming a single obvious action is
      // noise — the photograph is right there on the day.
      messenger
          .showSnackBar(SnackBar(
              content: Text(L.of(context).importAdded(summary.added))));
    }
  }

  Future<void> _captureOne(Future<CapturedFile?> Function() pick) =>
      _capture(() async {
        final one = await pick();
        return one == null ? <CapturedFile>[] : [one];
      });

  /// Camera or gallery.
  Future<void> _photo() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.lamplight.surface,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Space.x2),
            LampTile(
              title: L.of(context).capturePhotoTake,
              icon: Icons.photo_camera_outlined,
              onTap: () => Navigator.of(sheet).pop('camera'),
            ),
            LampTile(
              title: L.of(context).capturePhotoChoose,
              icon: Icons.photo_library_outlined,
              onTap: () => Navigator.of(sheet).pop('gallery'),
            ),
            const SizedBox(height: Space.x4),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == 'camera') {
      await _captureOne(Capture.takePhoto);
    } else {
      await _capture(Capture.pickPhotos);
    }
  }

  Future<void> _voice() async {
    _debounce?.cancel();
    await _flush();
    if (!mounted) return;
    final dayKey = _dayKey;
    try {
      final kept = await showRecordingSheet(
        context: context,
        importer: _importer,
        dayKey: dayKey,
      );
      if (kept) {
        widget.silentBackup.markDirty();
        // ISSUE 15. The note he just made is the one he is most likely to want
        // to find again, so it goes first rather than at the back of whatever
        // backlog exists.
        _transcripts.catchUp().ignore();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(readableFailure(context, e))));
    }
  }

  // ── Going elsewhere ────────────────────────────────────────────────────────

  Future<void> _openCalendar() async {
    _debounce?.cancel();
    await _flush();
    if (!mounted) return;
    final picked = await showCalendarSheet(
      context: context,
      repository: _repo,
      importer: _importer,
      initialDate: _date,
    );
    if (picked != null) _goToDate(picked);
  }

  /// `2026-03-04` as *4 March*. **`PLAN.md` §9.1.**
  ///
  /// No year, because the sentence it goes into is about a day the person is
  /// looking at right now — *"Still on 4 March"* — and a year in it would read
  /// as a record rather than as a reassurance.
  static String _dayInWords(BuildContext context, String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null ||
        month < 1 || month > 12 || day < 1 || day > 31) {
      return dayKey;
    }
    // The year is parsed and then not shown — `dayAndMonth` drops it, and
    // `DateTime` needs one to know which month this is. See the note above
    // for why the year has no place in this particular sentence.
    return LampDates.dayAndMonth(context, DateTime(year, month, day));
  }

  void _openSearch() {
    _debounce?.cancel();
    unawaited(_flush());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          vault: widget.vault,
          onOpenDay: (day) {
            Navigator.of(context).pop();
            _goToDate(day);
          },
        ),
      ),
    );
  }

  void _openSettings() {
    _debounce?.cancel();
    unawaited(_flush());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          vault: widget.vault,
          settings: widget.settings,
          silentBackup: widget.silentBackup,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final surface = widget.settings.pageSurface;
    // The two sentences transcription writes on its own, in the reader's
    // language. It runs on a background path with no context — see
    // `TranscriptionQueue.words`.
    _transcripts.words = L.of(context);

    return Scaffold(
      backgroundColor: c.canvas,
      // The composer sits above the keyboard rather than behind it. Chat
      // behaviour, and the only correct one when the writing surface is pinned.
      resizeToAvoidBottomInset: true,
      body: PaperGround(
        surface: surface,
        // ISSUE 6. Round five printed lines on every page without asking; this
        // is the page he actually chose, and out of the box it is blank.
        ruling: widget.settings.pageRuling,
        // The lamp now lives inside PaperGround itself, so every screen that
        // draws a page gets it rather than only this one — which is what makes
        // it a *surface* rather than an effect bolted onto the home screen.
        child: Builder(
          builder: (context) => SafeArea(
            bottom: false,
            // ── ISSUE 6b — the day fills the window ────────────────────────
            //
            // The whole day — header, stream, composer and capture bar — used
            // to be one column capped at `Layout.maxColumn` and centred in
            // whatever was left. That is what he drew on page 9: a third of
            // blank, a third of content marked "very small", a third of blank,
            // with "very much negative space" down both sides, against
            // WhatsApp, Instagram, Telegram and Google's apps in landscape.
            //
            // It fills the width now, with `Layout.gutter` down each side like
            // everything else. The reasoning that put the cap here is preserved
            // in full at the top of `tokens.dart` — it was a good argument and
            // it lost to how the app actually looks on his tablet.
            //
            // `PaperGround` stays full-bleed behind it, because the paper is
            // the table rather than the page.
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fixed. Does not swipe. ────────────────────────────────
                //
                // Capped at two fifths of the window, and it scrolls inside
                // that cap. The same arrangement `LampPage` uses for its
                // heading, and here for the same reason: at 200% text on a
                // short landscape window — 640 × 320, a phone on its side —
                // the header, the composer and the capture bar together came
                // to thirty points more than the screen, the `Expanded` in
                // between was squeezed to nothing and the Column overflowed
                // off the bottom.
                //
                // The header gives way rather than the day, because the day is
                // what the user came for and the header is how they got here.
                // Nothing changes at any ordinary size: on every phone and
                // tablet in the responsive suite the header is well under the
                // cap and this box does nothing at all.
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.42),
                  child: SingleChildScrollView(
                    child: DayHeader(
                      date: _date,
                      isToday: _isToday,
                      goingForward: _goingForward,
                      // ROUND FIVE, ISSUE 8 — every day, not just today.
                      //
                      // *"Today has name / Tomorrow has no name → WHY?"* and,
                      // on his checklist, *"Name → shown on Today Page, never
                      // shown on other day page"*. It was `_isToday ? name :
                      // ''`, which is a deliberate line somebody wrote on
                      // purpose, so it is worth saying why it was wrong rather
                      // than just deleting the condition.
                      //
                      // The idea was that a name is a greeting, and you greet
                      // somebody when they arrive rather than every time they
                      // turn a page. That reads well as a sentence and does not
                      // survive contact with the app, because these are not
                      // separate screens — they are one screen you swipe
                      // sideways, and the header is fixed while you do it. So
                      // the effect was not "a greeting on arrival", it was a
                      // row that silently changed shape under your thumb.
                      //
                      // Constant, therefore. The name is part of the header's
                      // furniture, like the lamp beside it, and furniture does
                      // not appear and disappear depending on the date.
                      greetingName: widget.settings.displayName,
                      onPickDate: _openCalendar,
                      onPrevious: () => _goBy(-1),
                      onNext: _isToday ? null : () => _goBy(1),
                      onSearch: _openSearch,
                      onSettings: _openSettings,
                      // The day's own line. Keyed on nothing — one instance
                      // that follows the day, so a half-typed line is saved by
                      // `didUpdateWidget` on the way past rather than thrown
                      // away with a rebuilt State.
                      dayLine: DayLine(
                        notes: _dayNotes,
                        entries: _repo,
                        dayKey: EntryRepository.dayKeyFor(_date),
                        // Not while an entry is being edited in place: that is
                        // the one moment when a second caret on the page really
                        // would be two places the same words could go.
                        editable: _editor == null,
                        // Taking the caret means giving it up somewhere else.
                        // Without this the composer keeps focus, the keyboard
                        // stays pointed at it, and the first thing typed into
                        // the day's line lands in the day's writing instead.
                        onFocused: _composerFocus.unfocus,
                      ),
                    ),
                  ),
                ),

                // ── ISSUE 20's other half ────────────────────────────────
                //
                // `backupOutOfDate` is set when the passcode changes, because
                // the file on disk then wants a passcode its owner has
                // deliberately stopped using — and nothing about the *vault*
                // changed, so neither the automatic backup nor the thirty-day
                // reminder would ever have noticed. It is a different sentence
                // from "it has been a while", so it gets one.
                if (_isToday &&
                    (widget.settings.backupReminderDueFor(
                          entries: _vaultSize.entries,
                          days: _vaultSize.days,
                        ) ||
                        widget.settings.backupOutOfDate))
                  LampBanner(
                    // ── SAY WHAT ACTUALLY HAPPENS ──────────────────────
                    //
                    // This used to read *"Your notes are only on this
                    // phone."* — true, and it lets somebody conclude that
                    // the risk is dropping the phone in a river. The risk
                    // that actually took a vault on 28 August was the app
                    // being removed, and `allowBackup="false"` means removal
                    // takes everything with it, immediately and with no
                    // recovery anywhere.
                    //
                    // Nobody is told that, and it is genuinely surprising:
                    // most apps on the phone would come back with their
                    // contents from a cloud account this one deliberately
                    // does not have. Saying so is not fear — it is the one
                    // fact somebody needs in order to decide whether to
                    // spend thirty seconds choosing a folder.
                    message: widget.settings.backupOutOfDate
                        ? L.of(context).backupOutOfDate
                        : widget.settings.lastBackupAt == null
                            ? L.of(context).backupNeverMade
                            : L.of(context).backupStale,
                    actionLabel: L.of(context).backupAction,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BackupScreen(
                          vault: widget.vault,
                          settings: widget.settings,
                        ),
                      ),
                    ),
                    onDismiss: () =>
                        setState(widget.settings.snoozeBackupReminder),
                  ),

                // ── The only thing that swipes ────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    onPageChanged: _onPageChanged,
                    // ── Why the neighbours are built before they are needed ─
                    //
                    // > *"you can also slide through pages and see how it
                    // > jerks! a little! i want you to make it smoother!"*
                    //
                    // A `PageView` builds lazily. Without this it keeps only
                    // the page you are on, so the day either side is
                    // constructed **during the gesture** -- its query runs, its
                    // blocks are laid out and its thumbnails are decoded while
                    // a finger is already moving. The first frames of every
                    // swipe were paying for a day that did not exist yet, which
                    // is exactly what a small, repeatable stutter at the start
                    // of a movement looks like.
                    //
                    // `allowImplicitScrolling` gives the viewport a cache
                    // extent of one page each way, so both neighbours are
                    // already built and the swipe only has to move them.
                    //
                    // **The memory is the thing to watch**, and it was
                    // measured rather than assumed: three days held instead of
                    // one. A day is a query and some text; the photographs in
                    // it are already bounded by `EncryptedImage`'s pixel budget,
                    // which is the cap that matters and is unchanged. See the
                    // note in `document_viewer.dart` for what happens when that
                    // cap is missing.
                    allowImplicitScrolling: true,
                    itemBuilder: (context, page) {
                      final date = _map.dateFor(page);
                      return DayStream(
                        key: ValueKey(page),
                        repository: _repo,
                        importer: _importer,
                        vault: widget.vault,
                        date: date,
                        isToday: page == _todayPage,
                        draftEntryId: page == _page ? _draftEntryId : null,
                        editor: page == _page ? _editor : null,
                        // ══ ISSUE 9 + 14 — THE CARET GOES ON THE PAGE ═════
                        //
                        // *"Typing doesn't feel like writing on any kind of
                        // notes app."* It did not, and the reason was where
                        // the writing happened rather than how: the composer
                        // was a bordered field pinned above the capture bar,
                        // which is a chat app's shape. You typed into a strip
                        // at the bottom of the screen and your words appeared
                        // somewhere else.
                        //
                        // It is the last thing on the page now, directly after
                        // the day's blocks, so the caret is where the words
                        // will actually live and they grow down the page as
                        // they are written.
                        //
                        // **Still exactly one composer.** This is passed only
                        // for the current page — the same `page == _page`
                        // guard the draft and the editor already use — so the
                        // controller, its text and its draft id remain single
                        // and shared, and switching days still flushes to the
                        // day the words were typed on. The header comment on
                        // this class explains why one composer mattered enough
                        // to restructure the screen for; that is preserved.
                        // What moved is where it is *drawn*, not what owns it.
                        composer: page == _page && _editor == null
                            ? DayComposer(
                                controller: _composer,
                                focus: _composerFocus,
                                state: _composerState,
                                isToday: page == _todayPage,
                                onNewBlock: _newBlock,
                                onInserted: _insertFromKeyboard,
                              )
                            : null,
                        onStartWriting: _startWriting,
                        onEdit: _startEditing,
                        onMenu: _entryMenu,
                        onOpen: _openAttachment,
                        onSaveCopy: _exportAttachment,
                        onOpenWith: _openAttachmentElsewhere,
                        transcripts: _transcripts,
                        settings: widget.settings,
                        onPullToSearch: _openSearch,
                        onOpenFolder: _openFolderNamed,
                        onTrash: (e) => _delete(e.id),
                        onFinishEditing: _finishEditing,
                        onDeleteEditing: (id) async {
                          final editor = _editor;
                          setState(() => _editor = null);
                          editor?.dispose();
                          await _delete(id);
                        },
                        onGoToDate: _goToDate,
                      );
                    },
                  ),
                ),

                // ── Fixed. Does not swipe. ────────────────────────────────
                //
                // The composer used to be here, above the bar. It is on the
                // page now — see the note where it is passed into DayStream.
                // ── ISSUES 12, 13, 23 — what the app is doing, while it
                // does it ────────────────────────────────────────────────
                //
                // Directly above the capture bar, so the answer to "what is
                // happening?" is next to the buttons that started it. It takes
                // no height at all when there is nothing to say.
                ImportStrip(queue: _queue),

                if (_editor == null)
                  CaptureBar(
                    onVoice: _voice,
                    onPhoto: _photo,
                    onFile: () => _capture(Capture.pickDocuments),
                  ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Exceptions turned into something a person can act on.
///
/// **The rule and the reasoning now live in `core/plain_words.dart`**, because
/// round nine's ISSUE 16 made it the whole app's rule rather than this screen's
/// habit, and because the version that lived here had a hole in it: it let
/// anything ending in a full stop through, and a retaining path two hundred
/// lines long can end in a full stop.
///
/// The name stays so the six call sites below read the same as they did.
String readableFailure(BuildContext context, Object e) => plainFailure(
      e,
      fallback: L.of(context).failureGeneric,
      andThen: L.of(context).failureNothingLost,
          words: L.of(context));
