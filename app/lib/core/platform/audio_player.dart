
import 'package:flutter/services.dart';

import 'document_store.dart';
import 'video_playback.dart' show PlatformChannelRouter;

/// Playing a voice note that never becomes a file — with real controls.
///
/// WHY THIS IS NOT `just_audio` OR `audioplayers`
///
/// Not mainly the dependency, though `CLAUDE.md` rule 4 would want a
/// justification. It is that **every audio package in the ecosystem takes a
/// file path or a URL**, and this app has neither: it has a few hundred
/// kilobytes of plaintext AAC that exists only in RAM and must not touch a
/// disk. Using one would mean writing the decrypted note out, playing it, and
/// hoping to delete it afterwards — putting the user's voice back on disk in
/// the clear, which is the thing the whole recording path was built to avoid.
///
/// Android has an answer: `MediaDataSource`, which lets a player read from
/// wherever you like — here, a byte array.
///
/// WHY THERE IS SO MUCH MORE HERE THAN PLAY AND STOP
///
/// Because play and stop is not a player. A ten-minute voice note with no way
/// to seek means that hearing what you said in the ninth minute costs you nine
/// minutes, every time. That is not a missing nicety; it makes long recordings
/// pointless, which makes the record button pointless for anything but a
/// sentence. Seeking, skipping and speed are the feature, not decoration on it.
abstract final class EncryptedAudioPlayer {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  static void Function()? _onFinished;
  static bool _listening = false;

  /// Loads [bytes] and starts playing. Replaces anything already playing.
  static Future<void> play(Uint8List bytes) async {
    _ensureListening();
    try {
      await _channel.invokeMethod<void>('playAudio', {'bytes': bytes});
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(
          e.message ?? 'That recording could not be played.');
    }
  }

  static Future<void> pause() => _quiet('pauseAudio');

  static Future<void> resume() => _quiet('resumeAudio');

  static Future<void> stop() => _quiet('stopAudio');

  /// Jump to a point, in milliseconds from the start.
  static Future<void> seek(int milliseconds) async {
    try {
      await _channel.invokeMethod<void>('seekAudio', {'ms': milliseconds});
    } catch (_) {}
  }

  /// 0.5 to 2.0. Pitch is preserved, so 1.5x is listenable rather than comic.
  static Future<void> setSpeed(double rate) async {
    try {
      await _channel.invokeMethod<void>('setAudioSpeed', {'rate': rate});
    } catch (_) {}
  }

  /// Where playback has got to, how long it is, and whether it is running.
  ///
  /// One call returning three things rather than three calls: a scrubber
  /// redrawing several times a second should cost one hop across the channel.
  static Future<AudioState> state() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('audioState');
      if (m == null) return AudioState.none;
      return AudioState(
        position: Duration(milliseconds: (m['position'] as int?) ?? 0),
        duration: Duration(
            milliseconds: ((m['duration'] as int?) ?? 0).clamp(0, 1 << 30)),
        playing: (m['playing'] as bool?) ?? false,
      );
    } catch (_) {
      return AudioState.none;
    }
  }

  /// Called when playback reaches the end on its own.
  static void onFinished(void Function() callback) {
    _ensureListening();
    _onFinished = callback;
  }

  static Future<void> _quiet(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (_) {
      // Stopping something that has already stopped is not a failure.
    }
  }

  /// Shared with the video player. Registering a second handler on the same
  /// channel replaces the first, so both go through one router — see
  /// [PlatformChannelRouter].
  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    PlatformChannelRouter.register('audioFinished', (_) => _onFinished?.call());
  }
}

class AudioState {
  const AudioState({
    required this.position,
    required this.duration,
    required this.playing,
  });

  static const none = AudioState(
    position: Duration.zero,
    duration: Duration.zero,
    playing: false,
  );

  final Duration position;
  final Duration duration;
  final bool playing;

  /// 0..1, and 0 rather than NaN before the duration is known.
  double get fraction => duration.inMilliseconds <= 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}
