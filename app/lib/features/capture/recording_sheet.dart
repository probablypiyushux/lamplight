import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/platform/voice_recorder.dart';
import '../../core/plain_words.dart';
import '../../core/storage/attachment_importer.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// Recording a voice note.
///
/// `UX-FLOWS.md` flow 2: "one tap starts recording. Live waveform, elapsed
/// time, one big stop button. Encrypted chunks written continuously. Haptic on
/// start and stop. **No 'save' step — stop *is* save.**"
///
/// WHAT THE FIRST VERSION GOT WRONG, AND WHY IT MATTERED
///
/// The clock sat at 00:00 and the bars barely moved, so there was no way to
/// tell whether the microphone was hearing anything — and a recording screen
/// that cannot prove it is recording is worse than no recording screen, because
/// you find out afterwards. Two causes, both mine:
///
///   1. The clock was redrawn by a 120 ms timer whose callback first `await`ed
///      a platform channel for the amplitude. Every tick of the clock was
///      therefore waiting on a round trip to Kotlin, and if that call was slow
///      or failed the clock simply stopped. **The time and the level are now
///      completely separate**: the clock is driven by a `Ticker` at frame rate
///      and touches no channel at all, and the level is polled independently
///      into a `ValueNotifier` so a slow reading can never freeze the time.
///
///   2. `setState` on every reading rebuilt the whole sheet several times a
///      second, which is what made it feel like the phone was struggling. Only
///      the two things that change now rebuild — the digits and the bars —
///      through `ValueListenableBuilder`.
///
/// WHAT IS HAPPENING WHILE THIS SHEET IS OPEN
///
/// The audio never becomes a file. `VoiceRecorder.start` returns a stream of
/// encoded buffers coming straight off a pipe from Android's MediaRecorder, and
/// that stream is handed to `AttachmentImporter.importStream`, which encrypts
/// it as it arrives. By the time anything touches the filesystem it is
/// ciphertext, and there is no window in which it is not.
///
/// ══ ROUND EIGHT, ISSUE 5 — THE TWO THINGS THAT WERE WRONG ════════════
///
/// **5A. There was no pause.** *"There is no voice pause button while
/// recording!"* Now there is, and it is honest about itself: the clock stops,
/// the level reads zero rather than drawing a live waveform over a microphone
/// that is not listening, and the saved length counts only the parts that were
/// recorded. If the phone refuses to pause — some do — the button says so and
/// the recording carries on, because a screen showing a paused button over an
/// open microphone would be the app lying about a recording.
///
/// **5B. Leaving the app left the microphone on, for ever.** In his words:
///
/// > *"When the voice is being recorded, and if the app sleeps — voice
/// > recording doesn't stops — app gets closed — when I open it up back and
/// > when I try to record the voice it doesn't works! — cause the microphone
/// > was on! But no voice record file was saved or being saved! … IDK in first
/// > place when recording is taking place why is the app sleeping? Why? And if
/// > the phone sleeps which it shouldn't or just the app gets closed by any
/// > issues — atleast stop recording save the file till it has been recorded!"*
///
/// Three separate faults, and he found all three from the outside:
///
///   1. **Nothing kept the screen awake.** Answered with
///      `FLAG_KEEP_SCREEN_ON` — a window flag, not a permission, so nothing
///      appears in the manifest or in a store listing. Held while this sheet is
///      open and released by its `dispose`, including the dispose that happens
///      because something failed.
///   2. **Leaving the app did not stop the recording.** It does now: going to
///      the background **stops and saves**, which is exactly the sentence he
///      wrote. You come back and the note is on the day, as long as it got.
///   3. **A recorder left running poisoned every later attempt.** `start()` on
///      the Kotlin side threw *"Already recording"* if one was still alive, so a
///      single missed cleanup finished voice notes for the lifetime of the
///      process. It releases the stale one and starts instead, and this sheet
///      can no longer be disposed without the microphone being put down — see
///      `_rescue`, which runs on the paths nobody plans for.
Future<bool> showRecordingSheet({
  required BuildContext context,
  required AttachmentImporter importer,
  required String dayKey,
}) async {
  final granted = await VoiceRecorder.hasPermission() ||
      await VoiceRecorder.requestPermission();

  if (!granted) {
    if (!context.mounted) return false;
    // Refused, and that is allowed. No nagging, no second dialog, no
    // "Lamplight needs this to work" — ETHICAL-DESIGN.md. Just what happened
    // and where to change it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          L.of(context).recordingNoMic,
        ),
        duration: Duration(seconds: 6),
      ),
    );
    return false;
  }

  if (!context.mounted) return false;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    // Not dismissible by tapping outside, and not draggable away. A recording
    // in progress must not be endable by a stray thumb — the two ways out are
    // Stop, which keeps it, and Discard, which does not.
    isDismissible: false,
    enableDrag: false,
    builder: (context) => _RecordingSheet(importer: importer, dayKey: dayKey),
  );
  return saved ?? false;
}

class _RecordingSheet extends StatefulWidget {
  const _RecordingSheet({required this.importer, required this.dayKey});

  final AttachmentImporter importer;
  final String dayKey;

  @override
  State<_RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<_RecordingSheet>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Drives the clock and the bars' motion. **Touches no platform channel**, so
  /// nothing on the other side of the engine can stop time moving on screen.
  late final Ticker _ticker = createTicker(_onFrame);

  /// Elapsed time, published on its own so only the digits rebuild.
  final _elapsed = ValueNotifier<Duration>(Duration.zero);

  /// The rolling level history the waveform draws.
  final _levels = ValueNotifier<List<double>>(List.filled(40, 0));

  /// **Every** level, kept from the first sample to the last.
  ///
  /// [_levels] is a forty-sample window because that is what fits on screen.
  /// The saved waveform has to be the shape of the *whole* recording, so it
  /// needs the whole history — and this is the only moment it is free. Fourteen
  /// samples a second on a ten-minute note is about eight thousand doubles,
  /// which is nothing, and it is thrown away the instant it has been reduced
  /// to the ninety-six bytes that get stored.
  final List<double> _history = <double>[];

  Timer? _amplitude;
  Stopwatch? _clock;
  Future<String>? _import;
  StreamSubscription<void>? _bytes;

  /// Held rather than read through `widget`, because [_rescue] runs after this
  /// state is gone and still has to finish writing the recording. **ISSUE 5B.**
  late final AttachmentImporter _importer = widget.importer;

  /// Whether the recording has been dealt with — stopped, discarded, or
  /// rescued. The single thing [dispose] checks before putting the microphone
  /// down itself. **ISSUE 5B.**
  bool _settled = false;

  /// Paused, and believed only because the platform said so. **ISSUE 5A.**
  bool _paused = false;

  /// Whether any audio has actually arrived from the recorder.
  ///
  /// The honest signal. The clock running proves only that Dart is alive; this
  /// proves the microphone is producing something, and it is what the "Listening"
  /// line reports.
  final _hearing = ValueNotifier<bool>(false);

  String? _error;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ISSUE 5B. "Why is the app sleeping when recording is taking place?"
    // Because nothing had asked it not to.
    unawaited(VoiceRecorder.keepAwake(true));
    _begin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _amplitude?.cancel();
    _bytes?.cancel();
    // ISSUE 5B. Released here and not only on the paths that went to plan. The
    // sheet can be disposed by a route being torn down, by the activity being
    // rebuilt, or by an exception on the way in — and a screen-on flag that
    // outlives its reason is a phone that never sleeps again.
    unawaited(VoiceRecorder.keepAwake(false));
    // ── The last line of defence, and the whole of his bug ───────────
    //
    // If this sheet goes away without Stop or Discard having run, the platform
    // recorder is still holding the microphone. That is the state his phone got
    // into, and it used to be permanent: every later recording failed for the
    // lifetime of the process. Nothing may leave this method with a recorder
    // running, so the paths nobody planned for get the same treatment as the
    // ones that did — stop it, and keep what was recorded.
    if (!_settled) unawaited(_rescue());
    _elapsed.dispose();
    _levels.dispose();
    _hearing.dispose();
    super.dispose();
  }

  /// The app went away with a recording running. **ISSUE 5B.**
  ///
  /// *"Atleast stop recording save the file till it has been recorded!"* — so
  /// that is what happens, in those words. Not a pause the user has to remember
  /// to come back to, and not a silent discard: the note is stopped, saved, and
  /// on the day, as long as it got before he left.
  ///
  /// `paused` rather than `inactive`. `inactive` fires for the notification
  /// shade being pulled down and for a system dialog appearing, neither of which
  /// is leaving — ending a recording because somebody glanced at their
  /// notifications would be a worse bug than the one being fixed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ══ ISSUE 5, ROUND NINE — "VOICE DOESN'T GET SAVED" ═══════════════════
    //
    // *"I am recording the voice ↓ someone enters my room I close the app ↓
    // voice doesn't get saved! I want you to save the voice!"*
    //
    // Round eight made backgrounding stop and save, and this line is why it
    // never once worked. Android reports leaving as **three** states in a row:
    // `inactive`, then `hidden`, then `paused`. `app.dart` locks the vault on
    // `hidden`. This waited for `paused`. So the save always ran against a
    // vault whose database was closed and whose keys were gone — every time,
    // not sometimes, which is why he reported it as a feature that does not
    // exist rather than as a flaky one.
    //
    // `inactive` is the first of the three and it arrives while the app is
    // still fully up. It is also where the silent backup already starts, for
    // exactly this reason — see `app.dart`, which says so in as many words.
    //
    // Being early costs something honest: pulling down the notification shade
    // over a recording now ends it. That is the right way round. He has asked
    // twice for a recording that survives an interruption and never once for
    // one that survives being glanced away from, and a note that was saved
    // when it need not have been can be deleted in two taps.
    if (state == AppLifecycleState.resumed) return;
    if (_settled || _stopping || _error != null) return;
    unawaited(_stop());
  }

  /// Put the microphone down and keep whatever was recorded, from outside the
  /// widget's own lifetime. **ISSUE 5B.**
  ///
  /// Deliberately touches no `State` — no `setState`, no `context`, no
  /// `widget` — because by the time this runs there may be none. It uses the
  /// captured importer and the futures that were already in flight, and every
  /// failure is swallowed: this is the path where there is nobody left to tell.
  Future<void> _rescue() async {
    final pending = _import;
    try {
      // ISSUE 5, same reasoning as `_stop`. This is the path with nobody left
      // to tell, so it is the one that most needs the vault to still be there.
      await _importer.vault.whileSettling(() async {
        final reported = await VoiceRecorder.stop();
        if (pending == null) return;
        final entryId = await pending;
        final ms = reported > 0 ? reported : 0;
        // A recording with no measurable length is a tap on the button, not a
        // note. Keeping it would put an empty row on the day for no reason.
        if (ms < 700) {
          await _importer.discardEntry(entryId);
          return;
        }
        await _importer.setDuration(
          entryId,
          ms,
          waveform: summariseWaveform(_history),
        );
      });
    } catch (_) {
      // Best effort by definition. The one thing that mattered — the
      // microphone being released — is done by `VoiceRecorder.stop` above and
      // by the platform's own release on the way out.
    }
  }

  void _onFrame(Duration _) {
    final clock = _clock;
    if (clock == null) return;
    _elapsed.value = clock.elapsed;
  }

  Future<void> _begin() async {
    try {
      final stream = await VoiceRecorder.start();
      // A firm tap. DESIGN-SYSTEM.md: "Haptics carry more weight than animation
      // here" — you should be able to feel that it started without looking.
      unawaited(HapticFeedback.mediumImpact());

      _clock = Stopwatch()..start();
      _ticker.start();

      // Tapped so we can see that bytes really are arriving, then passed on
      // untouched. The importer consumes this and encrypts it as it goes.
      final watched = stream.map((chunk) {
        if (!_hearing.value) _hearing.value = true;
        return chunk;
      });

      _import = widget.importer.importStream(
        source: watched,
        dayKey: widget.dayKey,
        type: 'voice',
        // *"Every voice is saved as voice.aac"* — it was, and every one of
        // them collided with every other one in the Readable copy, coming out
        // as `Voice note (1)`, `(2)`, `(10)`, in no order anybody can read.
        // A recording has no file on disk to take a name from, so this is the
        // one place a name can be given. See `stampedName`.
        originalName: stampedName(
          kind: 'Voice',
          at: DateTime.now(),
          extension: '.aac',
        ),
        // ADTS rather than the usual m4a, because an MPEG-4 container has to
        // seek backwards to write its index and a pipe cannot seek. See
        // VoiceRecorder for the whole argument.
        mimeType: 'audio/aac',
      );

      // Separate from the clock, and deliberately so — see the note at the top
      // of this file. A slow or failed reading costs a flat bar, not the time.
      _amplitude = Timer.periodic(const Duration(milliseconds: 70), (_) async {
        // ISSUE 5A. A pause is not part of the note, so it is not part of the
        // shape of the note either. Sampling through it would draw a flat
        // stretch into the saved waveform proportional to how long somebody
        // stopped for, which is a picture of the wrong thing.
        if (_paused) return;
        final level = await VoiceRecorder.amplitude();
        if (!mounted) return;
        _history.add(level);
        final next = List<double>.of(_levels.value)
          ..removeAt(0)
          ..add(level);
        _levels.value = next;
      });

      setState(() {});
    } catch (e) {
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).recordingCouldNotStart,
          andThen: L.of(context).recordingCheckMicrophone,
          words: L.of(context)));
    }
  }

  /// Pause, or pick it back up. **ISSUE 5A.**
  Future<void> _togglePause() async {
    if (_paused) {
      final resumed = await VoiceRecorder.resume();
      if (!mounted) return;
      if (!resumed) return _sayPauseFailed(L.of(context).recordingStartAgain);
      setState(() => _paused = false);
      _clock?.start();
      _ticker.start();
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    final paused = await VoiceRecorder.pause();
    if (!mounted) return;
    // ISSUE 5A. The answer from the platform is believed over anything this
    // screen would like to be true. Drawing a paused button over a microphone
    // that is still listening would be the app lying about a recording, in a
    // journal whose entire claim is that it does not.
    if (!paused) return _sayPauseFailed('pause');
    setState(() => _paused = true);
    // Both clocks stop. `Stopwatch` already excludes the time it spent stopped,
    // and the Kotlin side banks its own elapsed the same way, so the two agree
    // about how long the note is without either having to tell the other.
    _clock?.stop();
    _ticker.stop();
    unawaited(HapticFeedback.selectionClick());
  }

  void _sayPauseFailed(String what) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        // No error code, no mention of the encoder. What happened, and what is
        // still true: the recording did not stop.
        content: Text(L.of(context).recordingCannot(what)),
        duration: const Duration(seconds: 4),
      ));
  }

  Future<void> _stop() async {
    if (_settled) return;
    _settled = true;
    setState(() => _stopping = true);
    _ticker.stop();
    _amplitude?.cancel();
    _clock?.stop();
    try {
      // ISSUE 5. Held open across the whole save, because the lock is very
      // likely already on its way — this method's commonest caller is the app
      // going into the background. Bounded and small; the argument is written
      // out in full on `Vault.whileSettling`.
      await _importer.vault.whileSettling(() async {
        final reported = await VoiceRecorder.stop();
        unawaited(HapticFeedback.mediumImpact());
        // Closing the write end of the pipe ends the stream, which lets the
        // encryption finish, which completes this future. The entry does not
        // exist until it does.
        final entryId = await _import!;
        final ms = reported > 0 ? reported : (_clock?.elapsedMilliseconds ?? 0);
        await widget.importer.setDuration(
          entryId,
          ms,
          waveform: summariseWaveform(_history),
        );
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // It did not save, so it is not settled — otherwise the guard at the top
      // would refuse the retry and `dispose` would skip the rescue, and the
      // recording would be lost by the code written to stop that happening.
      _settled = false;
      if (mounted) {
        setState(() {
          _error = plainFailure(e,
              fallback: L.of(context).recordingCouldNotSave,
              andThen: L.of(context).recordingStillHere,
          words: L.of(context));
          _stopping = false;
        });
      }
    }
  }

  Future<void> _discard() async {
    _settled = true;
    _ticker.stop();
    _amplitude?.cancel();
    _clock?.stop();
    await VoiceRecorder.cancel();
    // The import future may still complete with a partial recording. Let it,
    // then remove it — simpler and more reliable than trying to abort a stream
    // that is already being encrypted, and it cannot leave a half-written blob.
    try {
      final id = await _import;
      if (id != null) await widget.importer.discardEntry(id);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LampError(message: _error!),
              const SizedBox(height: Space.x5),
              LampButton(
                label: L.of(context).recordingClose,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(Space.x6, Space.x6, Space.x6, Space.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── The clock ───────────────────────────────────────────────
              // Its own listenable, so it redraws at frame rate while nothing
              // around it rebuilds at all.
              ValueListenableBuilder<Duration>(
                valueListenable: _elapsed,
                builder: (context, elapsed, _) => Semantics(
                  liveRegion: true,
                  label: L.of(context).recordingElapsed(elapsed.inSeconds),
                  excludeSemantics: true,
                  child: Text(
                    _format(elapsed),
                    style: t.displaySmall?.copyWith(
                      // Tabular figures, or the digits jitter sideways every
                      // time a 1 becomes a 7 and the whole thing looks unsteady.
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),

              // ── Is it actually hearing anything ─────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: _hearing,
                builder: (context, hearing, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ISSUE 5A. The dot is the one thing on this screen that
                    // keeps moving through silence, so it is also the thing
                    // that must stop when the microphone does. A breathing dot
                    // beside the word PAUSED would be the screen arguing with
                    // itself.
                    if (!_stopping && !_paused) _Pulse(active: hearing),
                    if (!_stopping && !_paused) const SizedBox(width: Space.x2),
                    Text(
                      _stopping
                          ? 'Saving…'
                          : _paused
                              ? 'PAUSED'
                              : hearing
                                  ? 'LISTENING'
                                  : 'STARTING…',
                      style: t.labelSmall?.copyWith(
                        color: _stopping || _paused
                            ? c.inkSecondary
                            : hearing
                                ? c.accent
                                : c.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.x6),

              // ── The waveform ────────────────────────────────────────────
              ValueListenableBuilder<List<double>>(
                valueListenable: _levels,
                builder: (context, levels, _) => _Waveform(
                  levels: levels,
                  // Held, not cleared: the shape of what has been recorded so
                  // far is still true while it is paused, and wiping it would
                  // look like the recording had been thrown away.
                  colour: _stopping || _paused ? c.inkMuted : c.accent,
                  idle: c.raised,
                ),
              ),
              const SizedBox(height: Space.x8),

              // ── ISSUE 5A — pause, beside stop but never instead of it ───
              //
              // Stop stays exactly where it was: dead centre, 88 points, the
              // only place in the app where amber fills a large area, which
              // `DESIGN-SYSTEM.md` reserves for this one control. Pause is
              // smaller, outlined rather than filled, and sits to its left.
              //
              // The empty `Expanded` on the right is doing real work. Without
              // it the row would centre *itself*, which would shove the stop
              // button off to the right by half the width of the pause button
              // — and the thing your thumb has learnt the position of would
              // have moved because a second control appeared next to it.
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        label: _paused
                            ? L.of(context).recordingCarryOnSemantic
                            : L.of(context).recordingPauseSemantic,
                        excludeSemantics: true,
                        child: Tooltip(
                          message: _paused
                              ? L.of(context).recordingCarryOn
                              : L.of(context).recordingPause,
                          child: InkWell(
                            onTap: _stopping ? null : _togglePause,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.raised,
                                border: Border.all(
                                  color: _stopping
                                      ? c.borderHair
                                      : c.accent.withValues(alpha: 0.55),
                                ),
                              ),
                              child: Icon(
                                _paused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 28,
                                color:
                                    _stopping ? c.inkMuted : c.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x5),
                  // The one big stop button.
                  Semantics(
                    button: true,
                    label: L.of(context).recordingStopKeep,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: _stopping ? null : _stop,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _stopping ? c.raised : c.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stop_rounded,
                          size: 40,
                          color: _stopping ? c.inkMuted : c.canvas,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x5),
                  // ── ISSUE 5, round nine — Discard belongs in the row ─────
                  //
                  // He drew it here. On the screenshot there is a box sketched
                  // to the right of the stop button with **Discard** written
                  // in it and *"A possible option"* above.
                  //
                  // He is right, and the reason is the note above about the
                  // empty `Expanded`: that slot was left blank purely so the
                  // stop button would stay dead centre when pause appeared
                  // beside it. It has been a hole in the layout ever since,
                  // and the thing that should have been in it was sitting two
                  // rows below, under a line of explanation, where a
                  // destructive action is easiest to hit by accident on the
                  // way to nothing in particular.
                  //
                  // Stop does not move. It is still 88 points, still centred,
                  // still the only large amber area in the app.
                  //
                  // ── ROUND FIFTEEN, ISSUE 7 — "make it look like one of
                  // them" ──────────────────────────────────────────────────
                  //
                  // > *"WTF is this Dude"*, with an arrow at this control,
                  // > *"use an icon"*, *"make it look like one of them"*, and
                  // > beside it *"matching"* and *"not like odd one out"*.
                  //
                  // He is right and it is not only a matter of taste. Two
                  // round controls and one word in a row is a row with no
                  // grammar: the eye reads the two circles as *the* controls
                  // and the word as a caption belonging to one of them. Round
                  // nine put Discard in this slot and stopped one step short
                  // of giving it the shape the slot already had.
                  //
                  // Same 60 points as pause, same `raised` disc, same ring —
                  // in `danger` rather than in the accent, because being one
                  // of a set is about form and this one still has to say what
                  // it does. The word has not been lost: it is the tooltip and
                  // the screen-reader label, and `ACCESSIBILITY.md` requires
                  // an icon-only control to carry both.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: L.of(context).recordingDiscard,
                        excludeSemantics: true,
                        child: Tooltip(
                          message: L.of(context).recordingDiscard,
                          child: InkWell(
                            onTap: _stopping ? null : _discard,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.raised,
                                border: Border.all(
                                  color: _stopping
                                      ? c.borderHair
                                      : c.danger.withValues(alpha: 0.55),
                                ),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 26,
                                color: _stopping ? c.inkMuted : c.danger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ── ISSUE 5 — the line he called a blunder ──────────────────
              //
              // *"This line is Blunder why? cause Pausing it is also stopping.
              // remove the line."*
              //
              // The line said *"Stopping saves it. There is no save button."*
              // It was written to reassure somebody who was looking for a save
              // button, and what it actually does is raise the question. Worse,
              // he read it while paused and it is wrong there — with a pause
              // button on screen, "stopping saves it" invites exactly the
              // reading he gave it.
              //
              // The paused half stays, because that one is a fact about the
              // microphone rather than an explanation of the interface.
              if (_paused) ...[
                const SizedBox(height: Space.x4),
                Text(
                  L.of(context).recordingPaused,
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    // Tenths, because at 1 Hz a clock looks stopped between ticks and that is
    // exactly the doubt this screen exists to remove.
    final tenths = (d.inMilliseconds ~/ 100) % 10;
    return '$m:${s.toString().padLeft(2, '0')}.$tenths';
  }
}

/// A slow breathing dot beside the word LISTENING.
///
/// Not decoration: it is the one thing on the screen that keeps moving even
/// through silence, so a quiet room does not look like a dead microphone.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active});

  final bool active;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colour = context.lamplight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (widget.active ? colour.accent : colour.inkMuted)
              .withValues(alpha: widget.active ? 0.4 + 0.6 * _c.value : 0.4),
        ),
      ),
    );
  }
}

/// The live waveform.
///
/// Drawn with a painter rather than forty `AnimatedContainer`s. The first
/// version built forty implicitly-animated widgets and rebuilt them several
/// times a second, which is most of why the screen felt like the phone was
/// struggling. One painter, one repaint, no widget churn.
class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.levels,
    required this.colour,
    required this.idle,
  });

  final List<double> levels;
  final Color colour;
  final Color idle;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformPainter(levels: levels, colour: colour, idle: idle),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.levels,
    required this.colour,
    required this.idle,
  });

  final List<double> levels;
  final Color colour;
  final Color idle;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final slot = size.width / levels.length;
    final width = math.min(4.0, slot * 0.55);
    final middle = size.height / 2;

    // ── ISSUE 5, round nine — "feels like something is missing here" ───────
    //
    // An arrow to the right-hand end of this meter, and that sentence.
    //
    // The window is forty samples and they arrive at the right, so for the
    // first three seconds of any recording most of it is a row of faint
    // full-stops with a little cluster of bars at one end. Each dot is the
    // two-pixel floor a silent sample is drawn at — which was itself a fix,
    // because zero-height bars read as broken. It solved one problem and left
    // a picture that looks like a sentence with the words missing.
    //
    // A continuous hairline through the middle is the difference between
    // "part of this is not drawn" and "this is a meter, and it is quiet
    // there". It is what a tape counter, an oscilloscope and every voice-memo
    // app in existence do, and it costs one line of paint.
    canvas.drawRect(
      Rect.fromLTRB(0, middle - 0.5, size.width, middle + 0.5),
      Paint()..color = idle,
    );

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      // A floor, so silence is a steady line rather than nothing at all —
      // nothing at all reads as broken.
      final half = math.max(2.0, level * size.height * 0.46);
      final x = slot * i + slot / 2;
      // Newest at the right, and older bars fade, so the eye sees the sound
      // travelling rather than a row of jumping sticks.
      final age = i / levels.length;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - width / 2, middle - half, x + width / 2, middle + half),
          Radius.circular(width / 2),
        ),
        Paint()
          ..color = level <= 0.02
              ? idle
              : colour.withValues(alpha: 0.35 + 0.65 * age),
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.levels != levels || old.colour != colour;
}

/// Reduces a whole recording's level history to the bytes that get stored.
///
/// WHY NINETY-SIX
///
/// A waveform on a phone is about 280 logical pixels wide with a 2 px bar and
/// a 1 px gap, which is roughly ninety bars. More samples than bars is detail
/// nobody can see, and fewer is a picture that looks stretched. Ninety-six is
/// the next round number up and it is 96 bytes — smaller than the row it sits
/// in.
///
/// **Peak, not mean.** Averaging a bucket of samples turns speech into a low
/// flat hedge, because most of any sentence is quiet. The peak of each bucket
/// is what makes a waveform look like the thing that was said — you can see
/// where the sentences were.
///
/// A recording shorter than 96 samples is stretched rather than padded, so a
/// four-second note still fills its own width instead of trailing off into
/// flat.
Uint8List summariseWaveform(List<double> history, {int samples = 96}) {
  if (history.isEmpty) return Uint8List(0);
  final out = Uint8List(samples);
  // Normalise against the loudest moment, so a quietly-recorded note is still
  // legible rather than being a flat line near zero. The floor stops a note of
  // pure silence being amplified into noise.
  var loudest = 0.0;
  for (final v in history) {
    if (v > loudest) loudest = v;
  }
  if (loudest < 0.02) return out;

  for (var i = 0; i < samples; i++) {
    final from = (i * history.length / samples).floor();
    final to = (((i + 1) * history.length) / samples).ceil().clamp(from + 1, history.length);
    var peak = 0.0;
    for (var j = from; j < to; j++) {
      if (history[j] > peak) peak = history[j];
    }
    out[i] = ((peak / loudest) * 255).round().clamp(0, 255);
  }
  return out;
}
