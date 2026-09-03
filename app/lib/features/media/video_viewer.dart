import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import 'dart:typed_data';


import 'package:flutter/material.dart';

import '../../core/db/database.dart' show Attachment;
import '../../core/platform/document_store.dart';
import '../../core/platform/video_playback.dart';
import '../../core/storage/attachment_importer.dart' show humanDuration, humanSize;
import '../../core/storage/attachment_store.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'viewer_menu.dart';
import 'photo_viewer.dart' show LampBusyDot;

/// Watching a video that is never written to disk in the clear.
///
/// `PLAN.md` §9.5 asked for this and was specific about what must **not** be
/// built: decrypt to a temp file and point the platform player at it. That is
/// four lines and it puts somebody's video on their filesystem, unencrypted,
/// for as long as they watch it and for however long the delete takes to
/// happen afterwards. `CLAUDE.md` rule 2 has no "briefly" clause.
///
/// So the bytes go to Android as bytes, and Android reads them through a
/// `MediaDataSource` — the same mechanism the voice player has used since
/// August. The frames land on a `SurfaceTexture` that Flutter owns, so this is
/// a real widget: it can be pushed, popped, animated and covered like anything
/// else.
///
/// WHAT THE SCREEN ACTUALLY DOES
///
/// Play, pause, scrub, skip ten seconds either way, and speed. Tap to hide the
/// controls. That is a video player; anything less is a preview, and the
/// difference is whether you can reach the thing you wanted to see.
class VideoViewer extends StatefulWidget {
  const VideoViewer({
    super.key,
    required this.attachment,
    required this.store,
    this.onSaveCopy,
    this.onSave,
    this.onTrash,
    this.onOpenWith,
  });

  final Attachment attachment;
  final AttachmentStore store;

  /// Offered on the refusal panel. Nullable so a caller that genuinely has no
  /// export path — a test, a preview — simply does not show the button, rather
  /// than showing one that does nothing.
  /// The button on the *refusal* screen — a clip this phone cannot decode.
  /// Not the menu. See [onSave].
  final VoidCallback? onSaveCopy;

  /// **ISSUE D**, the three-dot menu: save this clip, or send it to the trash.
  /// Null means the caller cannot offer it and the row is hidden.
  final void Function(Attachment)? onSave;
  final void Function(Attachment)? onTrash;

  /// **ISSUE 4, 13.** Hand this clip to another app. Lamplight plays video
  /// competently and is not going to out-play a video player, which is his
  /// argument for this existing at all.
  final void Function(Attachment)? onOpenWith;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> with WidgetsBindingObserver {
  VideoHandle? _handle;
  VideoState _state = VideoState.none;
  Timer? _ticker;
  String? _error;
  bool _chrome = true;
  double _speed = 1.0;

  /// True while the user is dragging the scrubber, so the poll does not fight
  /// the thumb for where it should be.
  bool _scrubbing = false;
  double _scrubTo = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    EncryptedVideoPlayer.clearCallbacks();
    // Releasing frees both the decoded bytes and the texture. Leaving either
    // behind would keep somebody's video in memory after they walked away
    // from it, which is exactly the thing this whole class is careful about.
    unawaited(EncryptedVideoPlayer.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Belt and braces. Android's own onPause already stops playback the
    // instant the window goes — see MainActivity — and this catches the case
    // where the platform side is not there at all.
    if (state != AppLifecycleState.resumed) {
      unawaited(EncryptedVideoPlayer.pause());
    }
  }

  Future<void> _load() async {
    try {
      if (widget.attachment.byteSize > EncryptedVideoPlayer.maxPlayableBytes) {
        // Working as designed, and the message says so rather than sounding
        // like a fault. The whole clip has to be held in memory to be played
        // without ever touching disk — see MemoryVideoPlayer — so this is a
        // real limit with a real reason, and PLAN.md §9.5 records the streaming
        // reader that would remove it.
        // ROUND EIGHT, ISSUE 10. It used to say the clip was "more than
        // Lamplight can hold in memory at once", which is the implementation
        // model exactly — a person watching a video does not have a memory
        // budget and cannot act on one.
        //
        // What survives is the half that is a **promise** rather than a
        // mechanism: the app will not write the clip out in the clear to get
        // around its own limit. Rule 3 of §7.0-C-i — a promise stays, a
        // mechanism goes.
        setState(() => _error = L
            .of(context)
            .videoTooBig(humanSize(widget.attachment.byteSize)));
        return;
      }

      final Uint8List bytes = await widget.store
          .readAllBytesOffThread(widget.attachment.id, widget.attachment.fileKey);
      if (!mounted) return;

      EncryptedVideoPlayer.onFinished(() {
        if (mounted) setState(() {});
      });
      EncryptedVideoPlayer.onFailed((message) {
        if (mounted) setState(() => _error = message);
      });

      final handle = await EncryptedVideoPlayer.open(bytes);
      if (!mounted) {
        await EncryptedVideoPlayer.close();
        return;
      }
      setState(() => _handle = handle);
      await EncryptedVideoPlayer.play();
      // 8 Hz. Fast enough that the scrubber tracks the thumb, slow enough that
      // polling is not itself the reason the frame budget is tight.
      _ticker = Timer.periodic(const Duration(milliseconds: 125), (_) async {
        final s = await EncryptedVideoPlayer.state();
        if (mounted && !_scrubbing) setState(() => _state = s);
      });
    } catch (e) {
      // Never an exception's own toString in front of a person. PLAN.md §11
      // test 6 — and this line was the last one in the app still doing it.
      if (mounted) {
        setState(() => _error = readableVideoFailure(L.of(context), e));
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_state.playing) {
      await EncryptedVideoPlayer.pause();
    } else {
      await EncryptedVideoPlayer.play();
    }
    final s = await EncryptedVideoPlayer.state();
    if (mounted) setState(() => _state = s);
  }

  Future<void> _skip(int seconds) async {
    final target = _state.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _state.duration ? _state.duration : target);
    await EncryptedVideoPlayer.seek(clamped.inMilliseconds);
  }

  Future<void> _cycleSpeed() async {
    const rates = [1.0, 1.25, 1.5, 2.0, 0.75];
    final next = rates[(rates.indexOf(_speed) + 1) % rates.length];
    await EncryptedVideoPlayer.setSpeed(next);
    if (mounted) setState(() => _speed = next);
  }

  /// ISSUE D — the three-dot sheet.
  Future<void> _menu() async {
    final shown = widget.attachment;
    final save = widget.onSave;
    final trash = widget.onTrash;
    final openWith = widget.onOpenWith;
    await showViewerMenu(
      context: context,
      kind: viewerKindFor(shown, video: true),
      onOpenWith:
          openWith == null ? null : () => openWith(shown),
      onSave: save == null ? null : () => save(shown),
      onTrash: trash == null
          ? null
          : () {
              // Leave first: a full-screen clip of something now in the trash
              // is a lie the user would have to dismiss themselves. Leaving
              // also stops the player, which matters more here than for a
              // photograph — audio continuing after a delete is alarming.
              Navigator.of(context).maybePop();
              trash(shown);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _chrome = !_chrome),
                child: Center(child: _stage(context)),
              ),
            ),

            // ══ ROUND EIGHT, ISSUE 2B — THE SCRIM ════════════════════
            //
            // *"Video player aesthetics lacks! I want you to keep it up! Make
            // it better!"*
            //
            // This is the single largest part of the answer, and it is not
            // decoration — it is what every video player on earth has and this
            // one did not. Two soft gradients, one under the top row and one
            // under the controls, dark at the edge and gone by the middle.
            //
            // It does two jobs at once and the second is the important one:
            //
            //   * A back arrow and a play button sat directly on the film,
            //     which means they were legible over a night scene and
            //     invisible over a snowfield. The scrim makes the ground under
            //     the chrome **known** rather than whatever frame happens to be
            //     showing.
            //   * And because the ground is known, the panel on top of it can
            //     afford to be glass. Without a scrim, making that panel
            //     see-through would put grey text on a white film. See
            //     `_controls`.
            //
            // Painted under the chrome and faded with it, so a video with the
            // controls hidden is the whole frame and nothing else.
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: Motion.duration(context),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.0),
                        // 0.78, and the number was measured rather than
                        // chosen. `video_controls_test.dart` solves for the
                        // scrim that keeps the panel's quietest label above
                        // 4.5:1 over a completely white frame; 0.62 came out
                        // at 4.28 and this is what clears it.
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.22, 0.62, 1.0],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _chrome ? 1 : 0,
              duration: Motion.duration(context),
              child: IgnorePointer(
                ignoring: !_chrome,
                child: Padding(
                  padding: const EdgeInsets.all(Space.x2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          color: c.inkPrimary,
                          tooltip: L.of(context).searchBack,
                        ),
                        const Spacer(),
                        // ISSUE D. Same sheet as the photo viewer's, from the
                        // same function, so the two cannot drift apart.
                        if (widget.onSave != null || widget.onTrash != null)
                          IconButton(
                            onPressed: _menu,
                            icon: const Icon(Icons.more_vert),
                            color: c.inkPrimary,
                            tooltip: L.of(context).viewerMore,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_handle != null && _error == null)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: _chrome ? 1 : 0,
                  duration: Motion.duration(context),
                  child: IgnorePointer(
                    ignoring: !_chrome,
                    child: _controls(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stage(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 32, color: c.inkMuted),
            const SizedBox(height: Space.x4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: t.bodyLarge?.copyWith(color: c.inkSecondary),
            ),
            // ── The sentence has to be actionable ──────────────────────────
            //
            // Both refusals above end with "save a copy", and until now there
            // was nowhere on this screen to do it — the user had to go back,
            // long-press the block and find the menu. Telling somebody what to
            // do and giving them no way to do it is the same defect as saying
            // nothing, one politeness removed.
            if (widget.onSaveCopy != null) ...[
              const SizedBox(height: Space.x8),
              LampButton(label: L.of(context).entrySaveCopy, onPressed: widget.onSaveCopy),
            ],
          ],
        ),
      );
    }

    final handle = _handle;
    if (handle == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LampBusyDot(size: 40),
          const SizedBox(height: Space.x4),
          Text(
            // Honest about what the wait is. A video has to be opened before
            // the first frame, and a person who knows that is waiting rather
            // than wondering.
            L.of(context).videoOpening,
            style: t.labelMedium?.copyWith(color: c.inkSecondary),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: handle.aspectRatio,
      child: Texture(textureId: handle.textureId),
    );
  }

  Widget _controls(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final total = _state.duration.inMilliseconds;
    final value = _scrubbing ? _scrubTo : _state.fraction;

    // ══ ISSUE 2B — GLASS, AND WHY IT IS SAFE HERE ══════════════════
    //
    // It was a slab at 94% opacity with a hairline round it: a grey box
    // parked on the film. His word was *"lacks"*, and this is most of what it
    // lacked.
    //
    // Glass, with the same reasoning as the capture bar in this round — and
    // the same care, because the situation is **not** the same. Nothing passes
    // behind the capture bar; here a whole film does. A transparent panel over
    // an arbitrary frame is grey text on whatever colour the video felt like.
    //
    // The scrim above is what makes this legal. It puts a known dark ground
    // under the whole bottom of the screen, so the backdrop this panel samples
    // is the scrim rather than the film — and 78% of `surface` over a scrim
    // that is already 62% black composites to within a couple of points of the
    // opaque panel it replaces. The contrast is held by the scrim, not hoped
    // for; `video_controls_test.dart` states that as a number.
    //
    // The hairline goes. A border round a floating panel is the thing that
    // made it read as a box rather than as part of the picture.
    //
    // ══ ROUND NINE, ISSUE 25 — "MAKE IT BETTER" ═════════════════════════════
    //
    // > *"This part GLASSMORPHISM — make it better, keep our app's aesthetics
    // > and core value in our head."*
    //
    // The blur was already here and it was hand-rolled: this panel had its own
    // `BackdropFilter`, its own flat alpha and no lit edge, while the capture
    // bar had a gradient face and a lit top and no rounding. **Two pieces of
    // glass in one app that are not the same glass**, drifting apart every time
    // either was touched, which is most of why this one read as a blurred
    // rectangle rather than as a pane.
    //
    // It is `LampGlass` now, in the same round the capture bar is, and the
    // improvement it brings is the lit rim — see the long note there for why a
    // `Border.all` cannot be one and what is done instead.
    //
    // **The alphas go up, not down.** 0.90 at the top and 0.84 at the foot, so
    // the *worst* point on this panel is exactly the flat value it replaces and
    // `video_controls_test.dart`'s number is still the number to check. A
    // control panel over an arbitrary film is the one place in this app where
    // more transparency is not automatically better; the scrim under it is what
    // makes any of this legal and it is doing enough work already.
    return LampGlass(
      radius: BorderRadius.circular(Radii.lg),
      topAlpha: 0.90,
      bottomAlpha: 0.84,
      // ── ISSUE 6 — ten, not twenty ──────────────────────────────────────
      //
      // > *"WHEREVER YOU HAVE USED GLASSMORPHISM ... I NEED IT TO BE A LIL
      // > SEE THROUGH A LIL!"*
      //
      // The **alphas do not move** and the paragraph above is why: this panel
      // sits over an arbitrary film and its legibility is the reason it is
      // nearly solid. What moves is the blur, for the same reason it moved on
      // the capture bar — at twenty, everything behind this panel smaller than
      // the panel itself was erased, so the sixteen per cent of film showing
      // through was showing through as a single averaged colour. At ten it is
      // recognisably the film. See LampGlass.blur for the arithmetic.
      blur: 10,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x4, Space.x2, Space.x4, Space.x3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            // ISSUE 2B. Thinner track, smaller thumb, no halo, and the
            // inactive half drawn in ink rather than in `raised` — a panel
            // that is now see-through cannot use a *surface* colour for a line
            // on it, because there is no surface behind it any more.
            data: SliderThemeData(
              trackHeight: 2.5,
              activeTrackColor: c.accent,
              inactiveTrackColor: c.inkPrimary.withValues(alpha: 0.22),
              thumbColor: c.accent,
              overlayColor: c.accent.withValues(alpha: 0.14),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              // A real label, so a screen reader says "four minutes twelve"
              // rather than "point three eight".
              label: humanDuration(
                  (value * total).round().clamp(0, 1 << 30)),
              onChanged: total <= 0
                  ? null
                  : (v) => setState(() {
                        _scrubbing = true;
                        _scrubTo = v;
                      }),
              onChangeEnd: total <= 0
                  ? null
                  : (v) async {
                      await EncryptedVideoPlayer.seek((v * total).round());
                      if (mounted) setState(() => _scrubbing = false);
                    },
            ),
          ),
          Row(
            children: [
              Text(
                humanDuration(
                    (value * total).round().clamp(0, 1 << 30)),
                // Tabular figures: without them the digits change width as
                // they tick and the whole row jitters once a second.
                style: t.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              _RoundControl(
                icon: Icons.replay_10,
                label: L.of(context).videoBackTen,
                onTap: () => _skip(-10),
              ),
              const SizedBox(width: Space.x2),
              _RoundControl(
                icon: _state.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: _state.playing ? 'Pause' : 'Play',
                onTap: _togglePlay,
                filled: true,
              ),
              const SizedBox(width: Space.x2),
              _RoundControl(
                icon: Icons.forward_10,
                label: L.of(context).videoForwardTen,
                onTap: () => _skip(10),
              ),
              const Spacer(),
              // ISSUE 2B. How much is left, which the panel never said.
              //
              // Every player shows both ends and this one showed only where
              // you are — so "how long is this clip" and "how much is left"
              // both had to be worked out from a slider. A minus sign in front,
              // which is the convention for remaining rather than total, and
              // the same tabular figures so it does not jitter either.
              Text(
                '-${humanDuration(((1 - value.clamp(0.0, 1.0)) * total).round().clamp(0, 1 << 30))}',
                style: t.labelMedium?.copyWith(
                  // `inkSecondary`, not `inkMuted`. The quietest ink in the
                  // palette is for a label on a known surface, and this one is
                  // on glass over arbitrary film — it failed AA on both
                  // palettes when it was muted, which the test found before
                  // anybody had to look at it.
                  color: c.inkSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: Space.x3),
              // Speed carries its own value as text, so it is never colour or
              // an icon alone that says what it is set to.
              TextButton(
                onPressed: _cycleSpeed,
                style: TextButton.styleFrom(
                  minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  '${_speed == _speed.roundToDouble() ? _speed.toStringAsFixed(0) : _speed}×',
                  style: t.labelMedium?.copyWith(
                    color: _speed == 1.0 ? c.inkSecondary : c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? c.accent : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: filled ? 28 : 24,
              color: filled ? c.canvas : c.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}


/// An exception turned into something a person can act on.
///
/// **ISSUE 10, and PLAN.md §11 test 6.** Every branch below names a thing that
/// happened and, where there is one, a thing to do about it. None of them
/// contains a type name, a code or the word "error".
///
/// The honest position on formats, which Piyush is owed: the platform decoder
/// covers everything a phone camera or a messaging app produces — H.264, H.265,
/// VP8/9, AV1, in MP4, MOV and WebM. Genuinely exotic containers would need
/// FFmpeg, a very large dependency that could read the entire vault, and that
/// trade is not worth making. **So the answer is: cover everything the phone
/// can decode natively, and when it cannot, say so out loud.** A silent failure
/// is the thing he is actually complaining about, in every one of the fifteen.
String readableVideoFailure(L l, Object error) {
  final message = switch (error) {
    DocumentStoreUnavailable() => l.videoNotAvailableHere,
    DocumentStoreError(:final message) => message,
    _ => null,
  };
  if (message != null && message.isNotEmpty) return message;

  final raw = '$error';
  // A message the platform already wrote in plain language passes through; a
  // Dart exception's toString does not.
  if (raw.contains('cannot play') ||
      raw.contains('could not be played') ||
      raw.contains('too large')) {
    return raw.replaceFirst(RegExp(r'^[A-Za-z_]+(Exception|Error)?: '), '');
  }
  return l.videoCouldNotOpen;
}
