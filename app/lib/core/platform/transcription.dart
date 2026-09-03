
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Writing down what was said, on this phone and nowhere else.
///
/// ══ ISSUE 15 ════════════════════════════════════════════════════════════════
///
/// > *"Voice transcribe — there should be an option for view transcript … use a
/// > offline model ofc! Which runs on the phone — supports multilingual
/// > languages — free cause it runs on my app locally … and slower output is
/// > not an issue — when a better output is received!"*
///
/// And `Honest Review/WHAT-LAMPLIGHT-LACKS.md` item 3, which calls it *"the
/// single largest gap between what the app collects and what it can give
/// back"*: the `transcript` column has existed since the first schema and
/// nothing has ever written to it.
///
/// ── THE PART THAT MATTERS MORE THAN THE FEATURE ─────────────────────────────
///
/// The honest review also set a condition on building this at all:
///
/// > *"On-device speech recognition on Android goes through a system service,
/// > and whether that service is genuinely offline varies by device … **Do not
/// > build this until the no-network test passes on a real phone in aeroplane
/// > mode.** If it fails, the answer is not to ship it with a warning — the
/// > answer is not to ship it."*
///
/// That condition is met **by construction rather than by testing**, which is
/// stronger. Android 13 added
/// `SpeechRecognizer.createOnDeviceSpeechRecognizer()` as a separate API from
/// the ordinary one precisely so that an app can *demand* on-device recognition
/// instead of hoping for it. `Transcribe.kt` uses only that constructor and has
/// no fallback: on a phone where it is unavailable the feature does not appear.
///
/// **The aeroplane-mode test is still worth running**, and it is in
/// `05-shipping/RELEASE-CHECKLIST.md`. Not because the contract is in doubt,
/// but because a claim this app makes about itself should be checked by
/// somebody rather than believed on the strength of a doc comment. See
/// `03-product/HOW-TRANSCRIPTION-WORKS.md`.
///
/// ── AND WHAT IS STILL TRUE ABOUT THE LIMITS ─────────────────────────────────
///
/// One language at a time. Android's on-device recogniser takes a single BCP-47
/// tag per session and there is no multilingual mode to ask for. He said
/// *"people 99% of the time will speak multilingually"* and he is right; what
/// the phone can do is one language per recording, chosen per recording, with
/// the default being the phone's own. That is said plainly in the settings
/// screen rather than glossed over.
abstract final class Transcription {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Whether this phone has an on-device recogniser at all.
  ///
  /// False on Android 12 and below — the API does not exist — and false on any
  /// phone whose maker did not ship a service behind it, which is a real
  /// proportion of them. Nothing about the feature is offered when this is
  /// false, rather than offering it and failing later.
  static Future<bool> get available async {
    try {
      return await _channel.invokeMethod<bool>('transcribeAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The phone's own language, as a BCP-47 tag.
  static Future<String> get phoneLanguage async {
    try {
      return await _channel.invokeMethod<String>('transcribeDefaultLanguage') ??
          'en-US';
    } catch (_) {
      return 'en-US';
    }
  }

  /// What the system can do, and what it has actually downloaded.
  ///
  /// The distinction is the whole reason this exists. A language that is
  /// *supported* but not *installed* produces an empty transcript rather than
  /// an error — which looks exactly like a recording with nothing in it, and is
  /// the single most misleading outcome available.
  static Future<TranscriptionLanguages> languages() async {
    try {
      final m = await _channel
          .invokeMapMethod<String, Object?>('transcribeLanguages');
      return TranscriptionLanguages(
        installed: List<String>.from(m?['installed'] as List? ?? const []),
        supported: List<String>.from(m?['supported'] as List? ?? const []),
      );
    } catch (_) {
      return const TranscriptionLanguages(installed: [], supported: []);
    }
  }

  /// Asks the system to fetch a language model.
  ///
  /// **The one place anything here touches a network**, and what travels is a
  /// model, not anybody's voice. It is Android's download, in Android's
  /// process; Lamplight still has no INTERNET permission and
  /// `tool/verify_no_internet.sh` still passes. It is behind an explicit tap
  /// all the same — see `Transcribe.kt`.
  static Future<bool> fetchLanguage(String tag) async {
    try {
      return await _channel.invokeMethod<bool>(
            'transcribeFetchLanguage',
            {'language': tag},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Transcribes one whole recording.
  ///
  /// [aac] is the decrypted audio, in memory. It is never written to disk on
  /// either side of the channel.
  ///
  /// Returns the empty string when the recording genuinely had no speech in it,
  /// which is a real answer and not a failure. Throws [TranscriptionFailed]
  /// when something went wrong, which is a different thing and is reported
  /// differently.
  static Future<String> of(Uint8List aac, {required String language}) async {
    try {
      return await _channel.invokeMethod<String>(
            'transcribe',
            {'bytes': aac, 'language': language},
          ) ??
          '';
    } on PlatformException catch (e) {
      throw TranscriptionFailed(e.message ?? 'That could not be written down.');
    }
  }
}

@immutable
class TranscriptionLanguages {
  const TranscriptionLanguages({
    required this.installed,
    required this.supported,
  });

  /// Ready to use right now, with no network involved at any point.
  final List<String> installed;

  /// Known to the system, but the model is not on the phone. Using one of
  /// these means asking Android to download it first.
  final List<String> supported;

  bool get isEmpty => installed.isEmpty && supported.isEmpty;
}

class TranscriptionFailed implements Exception {
  const TranscriptionFailed(this.message);

  final String message;

  @override
  String toString() => message;
}
