import 'dart:async';

import 'package:flutter/services.dart';

import 'document_store.dart';

/// Recording a voice note without ever writing plaintext audio to disk.
///
/// HOW IT WORKS, AND WHY IT IS NOT JUST "RECORD TO A FILE THEN ENCRYPT IT"
///
/// `04-technical/TECH-STACK.md` calls streaming-encrypted recording "a hard
/// requirement, verify it early", and it is right to. Every other import path
/// in this app produces a plaintext temp file that exists for a fraction of a
/// second before it is encrypted and scrubbed. A recording is different in
/// kind: it exists for as long as someone is talking. A four-minute confession
/// sitting unencrypted in app storage — while the phone might be picked up, the
/// battery might die, or the app might be killed and never get to the scrubbing
/// — is exactly the failure `CLAUDE.md` rule 2 exists to prevent.
///
/// So Android's `MediaRecorder` is given the write end of a **pipe** instead of
/// a file. The Kotlin side reads the read end and pushes buffers over an event
/// channel; this class turns those into a Dart stream; `AttachmentStore.write`
/// consumes that stream and encrypts it chunk by chunk with libsodium's
/// secretstream. **The audio is ciphertext by the time it reaches a filesystem,
/// and there is no moment at which it is not.**
///
/// One consequence worth knowing: the output format is **AAC in an ADTS
/// stream**, not the usual `.m4a`. An MPEG-4 container writes its index at the
/// end and seeks backwards to patch the header, which a pipe cannot do —
/// `MediaRecorder` fails outright. ADTS is self-framing and streams happily.
/// It is a slightly less common container and that is the price of the
/// requirement above.
class VoiceRecorder {
  static const MethodChannel _control = MethodChannel('lamplight/documents');
  static const EventChannel _audio = EventChannel('lamplight/audio');

  /// Whether the microphone has been granted.
  static Future<bool> hasPermission() async {
    try {
      return await _control.invokeMethod<bool>('hasMicPermission') ?? false;
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    }
  }

  /// Asks for the microphone. Returns whether it was granted.
  ///
  /// Asked here — the first time someone taps record — and not at first launch.
  /// `UX-FLOWS.md` flow 1: "no permissions requested up front. Ask for the
  /// microphone the first time they tap record." Just-in-time requests get
  /// dramatically higher acceptance and are far less alarming, because the
  /// reason is on screen at the moment of asking.
  static Future<bool> requestPermission() async {
    try {
      return await _control.invokeMethod<bool>('requestMicPermission') ?? false;
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    }
  }

  /// Starts recording and returns the stream of encoded audio.
  ///
  /// The stream is the *only* copy of the recording. Nothing on the Kotlin side
  /// buffers it to disk, so whoever consumes this stream has to consume all of
  /// it — hand it straight to `AttachmentStore.write`.
  static Future<Stream<Uint8List>> start() async {
    try {
      await _control.invokeMethod<void>('startRecording');
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The recorder would not start.');
    }
    return _audio
        .receiveBroadcastStream()
        .map((event) => event as Uint8List);
  }

  /// Stops, and returns how long it ran for in milliseconds.
  ///
  /// Closing the write end of the pipe ends the stream, so the encryption
  /// finishes on its own a moment later. **Stop is save** — `UX-FLOWS.md` flow
  /// 2 is explicit that there is no separate save step, because a recording you
  /// have to remember to save is a recording you will one day lose.
  static Future<int> stop() async {
    try {
      return await _control.invokeMethod<int>('stopRecording') ?? 0;
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The recording could not be saved.');
    }
  }

  /// Throws the recording away without keeping it.
  static Future<void> cancel() async {
    try {
      await _control.invokeMethod<void>('cancelRecording');
    } catch (_) {
      // Cancelling is best-effort by definition. There is nothing useful to
      // tell the user, and nothing was written.
    }
  }

  /// Holds the microphone but stops encoding. **ROUND EIGHT, ISSUE 5A.**
  ///
  /// *"There is no voice pause button while recording!"*
  ///
  /// **Returns whether it actually paused**, and the caller has to believe the
  /// answer rather than believing itself. Some devices refuse, and a screen
  /// showing a paused button over a microphone that is still listening is the
  /// single worst thing this feature could do — it would be the app lying about
  /// a recording, in a journal whose whole claim is that it does not.
  static Future<bool> pause() async {
    try {
      return await _control.invokeMethod<bool>('pauseRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Picks it back up. **ISSUE 5A.** Returns whether it resumed.
  static Future<bool> resume() async {
    try {
      return await _control.invokeMethod<bool>('resumeRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether the platform still has a recorder open. **ISSUE 5B.**
  ///
  /// Asked so the app can tell the difference between "you are recording" and
  /// "something left the microphone on", which used to be indistinguishable
  /// from the Dart side and is the state his phone got stuck in.
  static Future<bool> isRecording() async {
    try {
      return await _control.invokeMethod<bool>('isRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks the phone not to fall asleep. **ROUND EIGHT, ISSUE 5B.**
  ///
  /// *"IDK in first place when recording is taking place why is the app
  /// sleeping? Why?"* — because nothing had told it not to.
  ///
  /// This is `FLAG_KEEP_SCREEN_ON`, a **window flag rather than a permission**.
  /// It does not appear in the manifest, it cannot outlive the window, and it
  /// is the same mechanism a video player uses. It costs the threat model
  /// nothing and `WAKE_LOCK` — which is a real permission, listed in the store
  /// — is deliberately not what this is.
  ///
  /// Held only while a recording is on screen. Whoever turns it on owns turning
  /// it off, including on the failure path: a flag that outlives its reason is
  /// a phone that never sleeps again.
  static Future<void> keepAwake(bool on) async {
    try {
      await _control.invokeMethod<void>('keepScreenOn', {'on': on});
    } catch (_) {
      // A phone that will not take the call still records; it just dims. That
      // is a worse experience and not a broken one, and there is nothing
      // useful to say about it.
    }
  }

  /// The current input level, 0..1, for the waveform.
  static Future<double> amplitude() async {
    try {
      final v = await _control.invokeMethod<double>('recordingAmplitude');
      return (v ?? 0).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }
}
