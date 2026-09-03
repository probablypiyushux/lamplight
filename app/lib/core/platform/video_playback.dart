
import 'package:flutter/services.dart';

import 'document_store.dart';

/// Playing a video that never becomes a file.
///
/// The same shape as [EncryptedAudioPlayer] and for the same reason: the
/// plaintext exists only in RAM and must not reach a disk. Android reads it
/// through a `MediaDataSource` and renders onto a `SurfaceTexture` that Flutter
/// owns, so the frames arrive **inside** the widget tree rather than in a
/// native view floating over it — which matters, because a native view over a
/// Flutter app cannot be clipped, animated, or covered by a sheet.
///
/// ── THE LIMIT, SAID OUT LOUD ─────────────────────────────────────────────
///
/// The whole video is decrypted into memory before the first frame. That is
/// what buys seeking: an MP4 keeps its index at the end of the file, so a
/// player that cannot go backwards can only ever play straight through, and a
/// video you cannot scrub is barely a video. The cost is that a very large
/// clip will not open, and [maxPlayableBytes] is where the line is drawn. Above
/// it the app says so and offers to save a copy out, rather than trying and
/// being killed by Android's memory manager halfway through.
abstract final class EncryptedVideoPlayer {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// 320 MB of plaintext.
  ///
  /// Roughly ten minutes of 1080p phone video, and comfortably inside what a
  /// mid-range Android device will let one app hold. Chosen against the real
  /// constraint — Android's per-app heap limit, which on a 4 GB phone is often
  /// 512 MB total — rather than against a round number.
  static const int maxPlayableBytes = 320 * 1024 * 1024;

  static void Function()? _onFinished;
  static void Function(String message)? _onFailed;
  static bool _listening = false;

  /// Loads [bytes] and waits for the first frame.
  ///
  /// Returns the texture to draw and what the video turned out to be.
  static Future<VideoHandle> open(Uint8List bytes, {bool loop = false}) async {
    _ensureListening();
    try {
      final m = await _channel.invokeMapMethod<String, Object?>(
        'openVideo',
        {'bytes': bytes, 'loop': loop},
      );
      if (m == null) throw const DocumentStoreError('That video could not be opened.');
      return VideoHandle(
        textureId: (m['textureId'] as int?) ?? -1,
        width: (m['width'] as int?) ?? 0,
        height: (m['height'] as int?) ?? 0,
        duration: Duration(milliseconds: (m['duration'] as int?) ?? 0),
      );
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'That video could not be played.');
    }
  }

  static Future<void> play() => _quiet('playVideo');

  static Future<void> pause() => _quiet('pauseVideo');

  static Future<void> close() => _quiet('closeVideo');

  static Future<void> seek(int milliseconds) async {
    try {
      await _channel.invokeMethod<void>('seekVideo', {'ms': milliseconds});
    } catch (_) {}
  }

  static Future<void> setSpeed(double rate) async {
    try {
      await _channel.invokeMethod<void>('setVideoSpeed', {'rate': rate});
    } catch (_) {}
  }

  static Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod<void>('setVideoVolume', {'volume': volume});
    } catch (_) {}
  }

  /// Position, length and whether it is running, in one hop. Polled by the
  /// scrubber several times a second, so it is deliberately one call.
  static Future<VideoState> state() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('videoState');
      if (m == null) return VideoState.none;
      return VideoState(
        position: Duration(milliseconds: (m['position'] as int?) ?? 0),
        duration:
            Duration(milliseconds: ((m['duration'] as int?) ?? 0).clamp(0, 1 << 30)),
        playing: (m['playing'] as bool?) ?? false,
      );
    } catch (_) {
      return VideoState.none;
    }
  }

  static void onFinished(void Function() callback) {
    _ensureListening();
    _onFinished = callback;
  }

  static void onFailed(void Function(String message) callback) {
    _ensureListening();
    _onFailed = callback;
  }

  static void clearCallbacks() {
    _onFinished = null;
    _onFailed = null;
  }

  static Future<void> _quiet(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (_) {}
  }

  /// One handler for the whole channel, shared with the audio player.
  ///
  /// Registering a second `setMethodCallHandler` on the same channel silently
  /// replaces the first, so audio's `audioFinished` and video's `videoFinished`
  /// have to be dispatched from the same place. Learned the annoying way.
  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    PlatformChannelRouter.register('videoFinished', (_) => _onFinished?.call());
    PlatformChannelRouter.register(
        'videoFailed', (arg) => _onFailed?.call(arg as String? ?? 'Playback stopped.'));
  }
}

/// The one method-call handler for `lamplight/documents`.
///
/// Both players and anything else that needs a callback from Android register
/// here. Without it, whichever of them called `setMethodCallHandler` last would
/// win and the other's callbacks would vanish — a bug that only shows up when
/// somebody plays a voice note and then a video in the same session, which is
/// to say, in front of a user and never in a test.
abstract final class PlatformChannelRouter {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');
  static final Map<String, void Function(Object? argument)> _handlers = {};
  static bool _installed = false;

  static void register(String method, void Function(Object? argument) handler) {
    _handlers[method] = handler;
    if (_installed) return;
    _installed = true;
    _channel.setMethodCallHandler((call) async {
      _handlers[call.method]?.call(call.arguments);
      return null;
    });
  }
}

class VideoHandle {
  const VideoHandle({
    required this.textureId,
    required this.width,
    required this.height,
    required this.duration,
  });

  final int textureId;
  final int width;
  final int height;
  final Duration duration;

  /// 16:9 if the player could not say, which is the least wrong guess and
  /// stops the first frame arriving into a zero-height box.
  double get aspectRatio =>
      (width > 0 && height > 0) ? width / height : 16 / 9;
}

class VideoState {
  const VideoState({
    required this.position,
    required this.duration,
    required this.playing,
  });

  static const none = VideoState(
    position: Duration.zero,
    duration: Duration.zero,
    playing: false,
  );

  final Duration position;
  final Duration duration;
  final bool playing;

  double get fraction => duration.inMilliseconds <= 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}
