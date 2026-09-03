import 'dart:async';
import '../../l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/database.dart';
import '../../core/settings/app_settings.dart';
import '../../core/platform/voice_playback.dart';
import '../../core/storage/attachment_importer.dart';
import '../../design/tokens.dart';
import 'transcription_queue.dart';

/// A voice note as **one object you can see the shape of**.
///
/// ── WHAT CHANGED, AND WHY IT IS NOT A COSMETIC CHANGE ────────────────────
///
/// The previous version was a row of controls: a play button, a Material
/// slider, two skip buttons, a speed chip and two timestamps, all visible at
/// once, on every note, whether or not anything was playing. Six controls for
/// a thing whose primary verb is "listen". `PLAN.md` §8.1 called it correctly —
/// a voice note should be a single object, not a control panel.
///
/// So the object is **the waveform**. It is the thing, it is the progress bar,
/// and it is the scrubber: the played part is in the accent, the rest in muted
/// ink, and you drag anywhere on it to move. One shape doing three jobs, which
/// is fewer things on screen and fewer things to learn.
///
/// The skip and speed controls are still there and still complete — they appear
/// **only on the note that is playing**. A control that is useless until you
/// press play does not need to be on screen before you press play, and on a day
/// with six recordings that is thirty controls that are not drawn.
///
/// ── THE WAVEFORM IS REAL ─────────────────────────────────────────────────
///
/// Not a decorative sine, not random bars. It is the actual amplitude of the
/// actual recording, measured while it was being made and stored as 96 bytes
/// on the attachment row — see `Attachments.waveform`. It is never computed on
/// scroll, because computing it would mean decoding the audio, and decoding
/// audio to draw a picture is how you make a list stutter.
///
/// A note recorded before that column existed, or an audio file imported from
/// elsewhere, has no waveform and gets an honest flat bar rather than a
/// plausible fake one.
/// A voice note's length, or an admission that it is not known.
///
/// Top level so that ISSUE 2's regression test can reach it without building a
/// vault, a database and a screen to ask one question of a label.
String voiceClock(Duration d) => d.inMilliseconds <= 0
    ? '--:--'
    : '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.attachment,
    required this.importer,
    this.transcripts,
    this.settings,
  });

  /// What is being written down, and why nothing is. **Round ten.**
  ///
  /// Optional because this player is also used inside the editor and inside the
  /// viewer, where there is no day screen above it to own a queue. Without it
  /// the row falls back to what it always did — the words if there are any, and
  /// nothing if there are not — which is a smaller answer rather than a wrong
  /// one.
  final TranscriptionQueue? transcripts;
  final AppSettings? settings;

  final Attachment attachment;
  final AttachmentImporter importer;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  static const List<double> _speeds = [1.0, 1.25, 1.5, 2.0, 0.75];

  /// **This widget owns almost nothing now. ISSUE 14.**
  ///
  /// It used to keep its own `_loaded`, its own `AudioState`, its own polling
  /// timer and its own copy of the completion callback — so six notes on a day
  /// meant six independent opinions about a single speaker, and starting the
  /// second note left the first one drawing a pause button over a moving
  /// playhead for a recording nobody could hear.
  ///
  /// Everything except the drag lives in [VoicePlayback] now. This widget asks
  /// it questions and rebuilds when it says something changed.
  VoicePlayback get _audio => VoicePlayback.instance;

  String get _id => widget.attachment.id;

  /// Where the finger is while a drag is in progress, 0..1.
  ///
  /// The one piece of genuinely local state, and it has to be local: it is
  /// where *this* finger is, and the player has no opinion about it. Held apart
  /// so the mark follows the thumb rather than snapping back to whatever the
  /// player last reported. The seek happens on release — seeking on every frame
  /// of a drag stutters on any real device.
  double? _dragging;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    // `stopIfCurrent`, never `stop`. A note scrolled off the list — or replaced
    // by the one the user just tapped — must not silence whatever is actually
    // playing. The old code called `stop()` unconditionally here, which is the
    // same defect as ISSUE 14 arriving from the other direction.
    _audio.stopIfCurrent(_id);
    super.dispose();
  }

  void _onAudio() {
    if (!mounted) return;
    _learnDurationIfNeeded();
    setState(() {});
  }

  /// The app finding out how long a note is by listening to it.
  ///
  /// For notes already in the vault from before audio imports were probed —
  /// the ones showing `--:--`. Playing one tells the media player exactly how
  /// long it is, and there is no reason to forget that again when the note
  /// scrolls off. Written once; [AttachmentImporter.learnDuration] refuses to
  /// overwrite a duration that is already known.
  bool _learned = false;

  void _learnDurationIfNeeded() {
    if (_learned || !_isCurrent) return;
    if ((widget.attachment.durationMs ?? 0) > 0) return;
    final measured = _audio.state.duration;
    if (measured.inMilliseconds <= 0) return;
    _learned = true;
    widget.importer
        .learnDuration(widget.attachment.id, measured.inMilliseconds)
        .ignore();
  }

  bool get _isCurrent => _audio.isCurrent(_id);
  bool get _isLoading => _audio.isLoading(_id);
  bool get _isPlaying => _audio.isPlaying(_id);

  Duration get _duration {
    if (_isCurrent && _audio.state.duration.inMilliseconds > 0) {
      return _audio.state.duration;
    }
    return Duration(milliseconds: widget.attachment.durationMs ?? 0);
  }

  double get _progress =>
      _dragging ?? _audio.progressOf(_id, fallbackDuration: _duration);

  /// Only *this* note's failure, never the one before it.
  String? get _error => _isCurrent || _isLoading ? _audio.error : null;

  Future<void> _start() =>
      _audio.start(_id, () => widget.importer.bytesOf(widget.attachment));

  Future<void> _toggle() async {
    if (!_isCurrent) return _start();
    if (_audio.state.playing) {
      await _audio.pause();
    } else {
      await _audio.resume();
    }
  }

  Future<void> _skip(Duration by) => _audio.skip(_id, by);

  Future<void> _seekFraction(double v) =>
      _audio.seekFraction(_id, v, fallbackDuration: _duration);

  Future<void> _cycleSpeed() async {
    final index = _speeds.indexOf(_audio.speed);
    await _audio.setSpeed(_speeds[(index < 0 ? 0 : index + 1) % _speeds.length]);
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final total = _duration;
    final position = _isCurrent ? _audio.state.position : Duration.zero;
    final shown = _dragging != null
        ? Duration(milliseconds: (_dragging! * total.inMilliseconds).round())
        : position;
    final speed = _audio.speed;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          Space.x3, Space.x3, Space.x4, Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundButton(
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: _isPlaying
                    ? L.of(context).voicePause
                    : L.of(context).voicePlay,
                filled: true,
                busy: _isLoading,
                onTap: _isLoading ? null : _toggle,
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: _Waveform(
                  samples: widget.attachment.waveform,
                  progress: _progress,
                  enabled: _isCurrent,
                  played: c.accent,
                  unplayed: c.inkMuted,
                  spokenPosition: _spoken(context, shown, total),
                  onSeekPreview: (v) => setState(() => _dragging = v),
                  onSeek: (v) async {
                    setState(() => _dragging = null);
                    if (_isCurrent) {
                      await _seekFraction(v);
                    } else {
                      // Tapping the wave of a note that is not playing means
                      // "play from here", which is what you would expect and
                      // what the old version made you do in two steps.
                      await _start();
                      if (mounted) await _seekFraction(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: Space.x3),
              Text(
                _isCurrent ? _clock(shown) : _clockOrUnknown(total),
                style: t.labelMedium?.copyWith(
                  color: c.inkSecondary,
                  // Tabular figures. Without them the digits change width as
                  // they count and the whole row twitches once a second.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // ── Only while it is playing ────────────────────────────────────
          //
          // Skip and speed are real controls and they are complete. They are
          // also meaningless before playback starts, and a day with six voice
          // notes should not be carrying eighteen dormant buttons.
          AnimatedSize(
            duration: Motion.duration(context),
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: !_isCurrent
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.x1),
                    child: Row(
                      children: [
                        _RoundButton(
                          icon: Icons.replay_10,
                          label: L.of(context).videoBackTen,
                          onTap: () => _skip(const Duration(seconds: -10)),
                        ),
                        _RoundButton(
                          icon: Icons.forward_30,
                          label: L.of(context).voiceForwardThirty,
                          onTap: () => _skip(const Duration(seconds: 30)),
                        ),
                        const Spacer(),
                        Semantics(
                          button: true,
                          label: L.of(context).voiceSpeed('$speed'),
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: _cycleSpeed,
                            borderRadius: BorderRadius.circular(Radii.full),
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: kMinTouchTarget,
                                minHeight: kMinTouchTarget - 8,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${speed == speed.roundToDouble() ? speed.toInt() : speed}×',
                                style: t.labelMedium?.copyWith(
                                  color: speed == 1.0
                                      ? c.inkSecondary
                                      : c.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // ══ ISSUE 15 — "THERE SHOULD BE AN OPTION FOR VIEW TRANSCRIPT" ══
          //
          // **An option**, and that word decided the shape. Not a wall of text
          // under every recording: a voice note is a voice note, and a day with
          // six of them would become six paragraphs of machine transcription
          // with the actual notes squeezed between. One quiet row, and the
          // words when you ask for them.
          //
          // ══ ROUND TEN — AND A ROW WHEN THERE IS NOT ONE YET ═════════════
          //
          // > *"It's been 15 minutes, I recorded a 5 sec voice note, it can't
          // > transcribe! Idk if it's transcribed or not!"* — with Instagram's
          // > **View transcription** row circled underneath.
          //
          // The old condition was `if (transcript is not empty)`, and its note
          // argued that silence was right for a recording nobody had asked to
          // be written down. That is defensible for one of the five states this
          // can be in and wrong for the other four, and from the outside all
          // five looked the same: nothing under the note.
          //
          // **Which is the same fault as ISSUE 16, made in the other
          // direction.** ISSUE 16 was about showing people machinery they
          // should not have to see; this is hiding something they are waiting
          // for. The rule that covers both is one rule: a person should never
          // have to guess whether the app is working.
          //
          // So the row is always there on a voice note, and it says which of
          // the five it is. See `_TranscriptRow`.
          _TranscriptRow(
            attachment: widget.attachment,
            importer: widget.importer,
            transcripts: widget.transcripts,
            settings: widget.settings,
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.x2),
              child: Text(_error!,
                  style: t.labelMedium?.copyWith(color: c.danger)),
            ),
        ],
      ),
    );
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  /// The length, or an admission that it is not known yet.
  ///
  /// ── "WTF is this 0:00 — obviously that audio is not 0:00 cause that
  ///    plays! Why is this bug even placed here?" ────────────────────────
  ///
  /// He is right twice. The cause was that imported audio was never probed for
  /// its duration — fixed at the source, in `MediaInfo.readAudio`, so files
  /// imported from now on arrive knowing how long they are.
  ///
  /// This is the second half, and it is the half that matters for the notes
  /// already in his vault. A missing duration is stored as null, and the old
  /// code turned null into `Duration.zero` and printed it as **0:00** — an app
  /// stating, as a fact, something it had never measured and that was plainly
  /// false the moment you pressed play.
  ///
  /// So an unknown length now looks unknown. Two dashes rather than a number:
  /// the same width as a time in tabular figures, so nothing shifts when the
  /// real duration arrives a moment after playback starts and replaces it.
  ///
  /// **This is the invisible-machinery rule applied to a label.** A control
  /// that does nothing when tapped and a number that is confidently wrong are
  /// the same defect — the app saying something it cannot back up.
  static String _clockOrUnknown(Duration d) => voiceClock(d);

  /// Read aloud for the position slider.
  ///
  /// Takes a context now: the "length not known" case is a sentence rather
  /// than a number, so it has to come from the ARB like every other sentence.
  static String _spoken(BuildContext context, Duration at, Duration total) {
    if (total.inMilliseconds <= 0) {
      return L.of(context).voiceLengthUnknown;
    }
    return L.of(context).voicePositionSpoken(
        humanDuration(at.inSeconds), humanDuration(total.inSeconds));
  }
}

/// The shape of the recording, which is also the scrubber.
///
/// A `Slider` was the old answer and it was the wrong shape: a slider is a
/// value being set, and this is a place in a thing being found. Dragging on the
/// picture of the sound is how every audio editor and every messaging app does
/// it, and it needs no legend.
///
/// **It is still a real control for a screen reader.** `Semantics` marks it as
/// a slider with increase and decrease actions, so it is operable without ever
/// seeing the bars — which a hand-drawn scrubber usually is not, and that is
/// normally the reason not to build one.
class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.samples,
    required this.progress,
    required this.enabled,
    required this.played,
    required this.unplayed,
    required this.spokenPosition,
    required this.onSeekPreview,
    required this.onSeek,
  });

  final Uint8List? samples;
  final double progress;
  final bool enabled;
  final Color played;
  final Color unplayed;
  final String spokenPosition;
  final ValueChanged<double> onSeekPreview;
  final Future<void> Function(double) onSeek;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: L.of(context).voicePosition,
      value: spokenPosition,
      onIncrease: () => onSeek((progress + 0.05).clamp(0.0, 1.0)),
      onDecrease: () => onSeek((progress - 0.05).clamp(0.0, 1.0)),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          double at(Offset local) =>
              (local.dx / box.maxWidth).clamp(0.0, 1.0);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onSeek(at(d.localPosition)),
            onHorizontalDragStart: (d) => onSeekPreview(at(d.localPosition)),
            onHorizontalDragUpdate: (d) => onSeekPreview(at(d.localPosition)),
            onHorizontalDragEnd: (_) => onSeek(progress),
            child: SizedBox(
              // 44 high, and deliberately a **fixed** number rather than one
              // scaled from the screen. The bars inside it are a fixed size
              // too, so a voice note is physically the same object on a phone
              // and on a tablet — which is Piyush's tablet instruction applied
              // to the one control he said not to change the feel of.
              // ACCESSIBILITY.md's floor is a target size, not a paint size:
              // the row is 44 so a drag that starts slightly above or below
              // the bars still catches.
              height: 44,
              child: CustomPaint(
                painter: _WavePainter(
                  samples: samples,
                  progress: progress,
                  played: played,
                  unplayed: unplayed,
                  showThumb: enabled,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The shape of a recording — **the convention, not an invention. ISSUE 12.**
///
/// ── THIS IS THE THIRD DRAWING. THAT IS THE POINT ──────────────────────────
///
/// Round two was hard-edged symmetric rectangles: reported as "ugly as shit",
/// and fairly — it read as a barcode. Round three replaced them with a filled
/// silhouette under a smooth spline, a genuinely nicer picture of a sound, and
/// **Piyush rejected that too**. His instruction was specific: make it look
/// like WhatsApp and Telegram.
///
/// So this one is not a fourth idea. `PLAN.md` §11 test 5 — the familiarity
/// test — says that where every messaging app has converged on one way of
/// drawing a thing, Lamplight draws it that way, and a departure has to be
/// argued for rather than assumed. **Two redesigns from taste is the argument
/// against a third.** Every deliberate choice below is a copy of what the
/// convention already does, and the reasons are recorded so that nobody
/// mistakes them for arbitrary numbers and "improves" them:
///
///  1. **Discrete rounded bars, not a contour.** A stadium — a rectangle with
///     fully rounded ends — at every sample. The rounding is the single detail
///     that separates this from round two's barcode, and it is the reason the
///     same data reads as *soft* rather than as a fence.
///
///  2. **A gap that never closes.** The bar pitch is fixed in logical pixels
///     rather than derived from the sample count, so a long recording draws
///     fewer bars rather than thinner ones. Bars that thin out to hairlines as
///     a note gets longer is the most common way this control is got wrong.
///
///  3. **A floor, so silence is a dot rather than a hole.** A pause in speech
///     still draws a small round mark on the centre line. A waveform that
///     vanishes where somebody stopped to think looks broken.
///
///  4. **Whole bars change colour, one at a time.** The played part is the
///     accent, the rest is muted ink, and the boundary lands on a bar edge
///     rather than cutting through one. Both apps do this, and it is why the
///     progress reads at a glance without a separate bar.
///
///  5. **A round thumb at the boundary, only while the note is the live one.**
///     WhatsApp's is the reference. It says "this is draggable" — which it is —
///     and it disappears with the playback state so a shelf of six notes is not
///     six dots.
///
/// The stored data is unchanged: 96 amplitude bytes measured at record time
/// (`Attachments.waveform`), never recomputed on scroll. A note with no
/// measurement gets an even, obviously-neutral row rather than a plausible
/// fake.
class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.samples,
    required this.progress,
    required this.played,
    required this.unplayed,
    required this.showThumb,
  });

  final Uint8List? samples;
  final double progress;
  final Color played;
  final Color unplayed;

  /// The dragging dot. Only on the note that is loaded.
  final bool showThumb;

  /// Bar width and the gap after it, in logical pixels.
  ///
  /// 3 and 2 is what the messaging apps use at this row height and it survives
  /// the whole range the responsive suite covers: at 320dp the wave is about
  /// 150dp wide and draws 30 bars, at a tablet's 685dp it draws about 100. The
  /// count changes; **the bars stay the same size**, which is what makes the
  /// control look identical on a phone and on a tablet. That is the tablet
  /// instruction in one number.
  static const double _barWidth = 3;
  static const double _barGap = 2;

  /// The smallest a bar is ever drawn: a circle of the bar's own width, so a
  /// silent moment is a dot on the line.
  static double get _minBar => _barWidth;

  /// The level at `t` (0..1) across the recording.
  ///
  /// Nearest-neighbour with a short average rather than the spline round three
  /// used. A spline exists to make a *continuous contour* smooth; there is no
  /// contour here, and interpolating between discrete bars only blurs the
  /// difference between a loud syllable and a quiet one — which is the entire
  /// information content of the picture.
  double _levelAt(double t, double span) {
    final data = samples;
    if (data == null || data.isEmpty) {
      // No measurement exists for this recording — an import, or a note made
      // before the waveform column existed. An even row is honest about that:
      // it says "a recording, length unknown" rather than inventing peaks that
      // were never there.
      return 0.34;
    }
    if (data.length == 1) return data.first / 255.0;

    // Average the samples this bar actually covers. With more bars than
    // samples this is one sample; with fewer it is a proper summary, so a long
    // recording is not represented by every 40th peak and nothing between.
    final from = (t * (data.length - 1)).floor().clamp(0, data.length - 1);
    final to = ((t + span) * (data.length - 1)).ceil().clamp(0, data.length - 1);
    var peak = 0;
    for (var i = from; i <= to; i++) {
      if (data[i] > peak) peak = data[i];
    }
    return peak / 255.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final mid = size.height / 2;
    final maxBar = size.height * 0.86;
    final pitch = _barWidth + _barGap;
    final count = ((size.width + _barGap) / pitch).floor();
    if (count <= 0) return;

    // Centre the row of bars in whatever width is left over, so the wave does
    // not drift left of its box on one screen and right on another.
    final used = count * pitch - _barGap;
    final originX = (size.width - used) / 2;

    final cut = progress.clamp(0.0, 1.0) * used;
    final playedPaint = Paint()..color = played;
    final unplayedPaint = Paint()..color = unplayed.withValues(alpha: 0.55);

    for (var i = 0; i < count; i++) {
      final t = i / count;
      final level = _levelAt(t, 1 / count);
      final height = (_minBar + level * (maxBar - _minBar)).clamp(_minBar, maxBar);
      final left = originX + i * pitch;
      final rect = Rect.fromLTWH(left, mid - height / 2, _barWidth, height);

      // A whole bar belongs to whichever side its centre falls on. Clipping a
      // bar in half is the one thing neither reference app does, and it reads
      // as a rendering fault rather than as progress.
      final isPlayed = (left - originX) + _barWidth / 2 <= cut;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(_barWidth / 2)),
        isPlayed ? playedPaint : unplayedPaint,
      );
    }

    // ── The thumb ────────────────────────────────────────────────────────
    //
    // WhatsApp's dot. It marks the position and advertises that the wave can
    // be dragged, which a bare colour boundary does not.
    if (showThumb) {
      final x = (originX + cut).clamp(originX, originX + used);
      canvas.drawCircle(Offset(x, mid), 5.5, Paint()..color = played);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress ||
      old.samples != samples ||
      old.showThumb != showThumb ||
      old.played != played ||
      old.unplayed != unplayed;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  /// The note is being decrypted. Shown as a ring around the button rather
  /// than by swapping the glyph for an hourglass — the button must not change
  /// what it looks like it does while you are aiming at it.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: busy ? L.of(context).voiceOpening : label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: filled ? 40 : kMinTouchTarget,
                  height: filled ? 40 : kMinTouchTarget,
                  alignment: Alignment.center,
                  decoration: filled
                      ? BoxDecoration(color: c.accent, shape: BoxShape.circle)
                      : null,
                  child: Icon(
                    icon,
                    size: filled ? 26 : 22,
                    color: onTap == null && !busy
                        ? c.inkMuted
                        : filled
                            ? c.canvas
                            : c.inkSecondary,
                  ),
                ),
                if (busy)
                  SizedBox(
                    width: kMinTouchTarget - 2,
                    height: kMinTouchTarget - 2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.accent,
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

/// The one row under a voice note that says where its words are.
///
/// ══ FIVE STATES THAT ALL LOOKED LIKE NOTHING ═══════════════════════════════
///
/// > *"It's been 15 minutes, I recorded a 5 sec voice note, it can't
/// > transcribe! Idk if it's transcribed or not!"*
///
/// He is not reporting a transcription bug. He is reporting that he **cannot
/// tell** — and he was right, because every one of these drew the same thing,
/// which was nothing:
///
///  1. **Off.** The setting is off, so nothing was ever going to happen. This
///     is the likeliest one and the worst, because it is the state a person is
///     in before they have ever seen the feature work, and the app's answer was
///     silence.
///  2. **Impossible here.** No system recogniser and no imported model.
///  3. **Waiting.** In the queue, behind other recordings.
///  4. **Working.** Being written down right now.
///  5. **Nothing in it.** Written down, and there was silence to write. The old
///     code drew nothing for this too, and its note argued that an empty box is
///     worse than no box — which is true, and is not an argument for making it
///     indistinguishable from four other states.
///
/// Only the last of the five, plus "here are the words", is an ending. Three of
/// them are things a person is waiting on, and one of them is a thing they can
/// fix in one tap. Every one now says which it is.
///
/// ── WHY THE "OFF" ROW TURNS IT ON, RATHER THAN SENDING YOU TO SETTINGS ─────
///
/// Because the answer to *"why has this not been written down"* is *"because
/// you have not asked for that"*, and the reply to that should be available
/// where the question is asked. Settings → Your notes → Write down what is said
/// is four taps and a screen away from the recording that prompted the thought.
///
/// It stays **off by default** and that is not being revisited here: on a phone
/// with no imported model the audio is handed to Android's recognition service,
/// which is on-device but is still somebody's diary crossing into another
/// process, and `ETHICAL-DESIGN.md` does not allow an app to make that decision
/// for a person. Asking here is the opposite of assuming here.
class _TranscriptRow extends StatefulWidget {
  const _TranscriptRow({
    required this.attachment,
    required this.importer,
    required this.transcripts,
    required this.settings,
  });

  final Attachment attachment;
  final AttachmentImporter importer;
  final TranscriptionQueue? transcripts;
  final AppSettings? settings;

  @override
  State<_TranscriptRow> createState() => _TranscriptRowState();
}

class _TranscriptRowState extends State<_TranscriptRow> {
  /// The row as this widget last saw it, which may be fresher than the one it
  /// was built with.
  ///
  /// ── WHY THIS HAS TO RE-READ ──────────────────────────────────────────────
  ///
  /// The day is a stream of **entries**, and a transcript is written to an
  /// **attachment**. Nothing about the entry changes when the words land, so
  /// the day never rebuilds, and without this the row would sit on "Writing
  /// this down…" for ever — which is a worse version of the bug it was built to
  /// fix, because it would be a promise rather than a silence.
  ///
  /// `setTranscript` evicts the attachment from the shared cache when it
  /// writes, so the re-read here is a query only when there is genuinely
  /// something new, and a map lookup otherwise.
  late Attachment _row = widget.attachment;

  TranscriptionQueue? get _queue => widget.transcripts;

  @override
  void initState() {
    super.initState();
    _queue?.addListener(_onQueue);
  }

  @override
  void didUpdateWidget(_TranscriptRow old) {
    super.didUpdateWidget(old);
    if (old.transcripts != widget.transcripts) {
      old.transcripts?.removeListener(_onQueue);
      widget.transcripts?.addListener(_onQueue);
    }
    if (old.attachment.id != widget.attachment.id ||
        old.attachment.transcript != widget.attachment.transcript) {
      _row = widget.attachment;
    }
  }

  @override
  void dispose() {
    _queue?.removeListener(_onQueue);
    super.dispose();
  }

  /// The queue moved on. If this recording is still without words, look again.
  Future<void> _onQueue() async {
    if (!mounted) {
      return;
    }
    if (_row.transcript != null) {
      setState(() {});
      return;
    }
    final fresh = await widget.importer.attachmentById(_row.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _row = fresh;
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachment = _row;
    final transcripts = widget.transcripts;
    final settings = widget.settings;
    final text = attachment.transcript;

    // The words, when there are words. Unchanged, and it is the ending
    // everything else is on the way to.
    if (text != null && text.isNotEmpty) return _Transcript(text: text);

    final queue = transcripts;
    final prefs = settings;
    // Used somewhere with no day screen above it — inside the editor, inside
    // the viewer. A smaller answer rather than a wrong one.
    if (queue == null || prefs == null) return const SizedBox.shrink();

    // ── IT DOES NOT SAY "NOTHING WAS SAID". ROUND TEN ────────────────────
    //
    // > *"If transcribe can't find anything! I don't want it to say — Nothing
    // > was said in this one! I don't want it to behave like that! If it can't
    // > provide me a transcript don't say nothing was said in this one!"*
    //
    // He is right, and the reason he is right is bigger than the wording. The
    // app cannot tell the difference between these two:
    //
    //   * a recording of a quiet room, which genuinely has nothing in it; and
    //   * a recording the engine could not make anything of — a language it
    //     was not expecting, a bad moment, a model that returned empty.
    //
    // It only sees an empty string. Asserting the first when it might be the
    // second is the app claiming to know something it does not, about somebody
    // else's recording of their own life. **Wrong, and unkind in a way that is
    // easy to miss:** being told there was nothing in a note you remember
    // making is being told your memory is wrong.
    //
    // So it says what is actually true — no words came back — and offers the
    // only thing that could change it. `''` is still *stored*, because the
    // queue needs a mark saying "this one has been through" or it would grind
    // the whole backlog again on every unlock. Tapping takes the mark off.
    if (text != null) {
      return _TranscriptAction(
        icon: Icons.refresh,
        label: L.of(context).voiceNoWords,
        onTap: () async {
          await widget.importer.forgetTranscript(attachment.id);
          if (!mounted) return;
          // Re-read rather than patched by hand: `Attachment.copyWith` cannot
          // set a nullable column back to null without drift's `Value`, and
          // reaching for the database's own wrapper here would put generated
          // types in a widget. The row was just evicted from the cache, so this
          // is one query and it is the truth rather than an assumption about it.
          final fresh = await widget.importer.attachmentById(_row.id);
          if (!mounted) return;
          setState(() {
            if (fresh != null) _row = fresh;
          });
          await queue.catchUp();
        },
      );
    }

    // Everything below can change while this is on screen, so it listens.
    return AnimatedBuilder(
      animation: queue,
      builder: (context, _) {
        if (!prefs.transcribeVoice) {
          return _TranscriptAction(
            icon: Icons.notes_outlined,
            label: L.of(context).voiceWriteThis,
            onTap: () async {
              prefs.transcribeVoice = true;
              await queue.catchUp();
            },
          );
        }
        // ── The ordinary state of a new install. ROUND TEN ─────────────
        //
        // *"Make the whisper the base."* Nothing is broken and nothing is being
        // waited for; there is one thing left to do, and it opens from here
        // rather than from four taps into Settings — because here is where
        // somebody notices they need it.
        // ── THERE IS NOTHING TO IMPORT ANY MORE ───────────────────────
        //
        // A row here used to offer *"Add a language model to write this
        // down"*, opening the Whisper importer, because a phone with no model
        // was the ordinary state of a new install. Whisper was removed on 28
        // August 2026 and `queue.needsModel` is a constant `false` now.
        //
        // The equivalent situation — the phone has not downloaded the acoustic
        // model for the chosen language — is `queue.missingLanguage` below,
        // and the phone fetches that itself.
        if (queue.engineAvailable == false) {
          return _TranscriptNote(
            icon: Icons.notes_outlined,
            label: L.of(context).voiceCannotWrite,
          );
        }
        // A language the recogniser has not downloaded. **This is the one
        // failure that used to be recorded as an answer** — Android returns an
        // empty string rather than an error, and an empty transcript is the
        // mark that stops the queue retrying, so one run of the backlog would
        // have marked every recording in the vault as silent, permanently.
        // See `TranscriptionQueue._one`.
        if (queue.missingLanguage != null) {
          return _TranscriptNote(
            icon: Icons.schedule_outlined,
            label: L.of(context).voiceLanguageMissing,
          );
        }
        final problem = queue.problem;
        if (problem != null) {
          return _TranscriptNote(
            icon: Icons.schedule_outlined,
            label: problem,
          );
        }
        if (queue.isWorkingOn(attachment.id)) {
          return _TranscriptNote(
            icon: Icons.more_horiz,
            label: L.of(context).voiceWriting,
          );
        }
        return _TranscriptNote(
          icon: Icons.schedule_outlined,
          // Honest about the order of things. This is the least urgent work in
          // the app by design — he asked for that, three times, in the words
          // "take your time" — and it only runs while the vault is open.
          label: L.of(context).voiceWaiting,
        );
      },
    );
  }
}

/// A quiet line under a voice note. Not a button; there is nothing to do.
class _TranscriptNote extends StatelessWidget {
  const _TranscriptNote({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.x2, vertical: Space.x2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c.inkMuted),
          const SizedBox(width: Space.x1),
          Flexible(
            child: Text(
              label,
              style: t.labelMedium?.copyWith(color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The same line, when tapping it does something.
class _TranscriptAction extends StatelessWidget {
  const _TranscriptAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: ConstrainedBox(
          // The floor, even though the line draws smaller. `ACCESSIBILITY.md`
          // is about the hit area, not the paint.
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.x2, vertical: Space.x2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: c.accent),
                const SizedBox(width: Space.x1),
                Flexible(
                  child: Text(
                    label,
                    style: t.labelMedium?.copyWith(color: c.accent),
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

/// What was said, when somebody asks to see it. **ISSUE 15.**
///
/// Collapsed by default and remembered per note only for as long as the block
/// is on screen — which is right, because wanting to read one transcript is not
/// a statement about wanting to read all of them.
///
/// ── WHY IT SAYS WHERE THE WORDS CAME FROM ───────────────────────────────────
///
/// The line under an open transcript reads *"Written down on this phone."* That
/// is not decoration and it is not the machinery ISSUE 16 bans — it is the
/// distinction between this app and every other app that has ever offered to
/// transcribe something. `PLAN.md` §7.0-C-i rule 3: a promise the user is owed
/// stays, a mechanism they are being made to operate goes. This is the first
/// kind.
class _Transcript extends StatefulWidget {
  const _Transcript({required this.text});

  final String text;

  @override
  State<_Transcript> createState() => _TranscriptState();
}

class _TranscriptState extends State<_Transcript> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: _open ? L.of(context).voiceHideTranscript : L.of(context).voiceShowTranscript,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.x2, vertical: Space.x2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _open ? Icons.expand_less : Icons.notes_outlined,
                    size: 15,
                    color: c.inkMuted,
                  ),
                  const SizedBox(width: Space.x1),
                  Text(
                    _open ? L.of(context).voiceHideTranscript : L.of(context).voiceTranscriptTitle,
                    style: t.labelMedium?.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.duration(context),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Space.x2, 0, Space.x2, Space.x2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        widget.text,
                        style: t.bodyMedium?.copyWith(
                          color: c.inkSecondary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: Space.x2),
                      Text(
                        L.of(context).voiceWritten,
                        style: t.labelSmall?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
