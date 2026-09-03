import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **ISSUE 15, and the one thing about it that could be catastrophic.**
///
/// Android has two speech recognisers and they are one word apart in the
/// source:
///
///   * `SpeechRecognizer.createSpeechRecognizer()` — the ordinary one, which on
///     most phones **sends the audio to Google's servers**;
///   * `SpeechRecognizer.createOnDeviceSpeechRecognizer()` — added in Android
///     13 precisely so an app can *demand* on-device recognition.
///
/// Lamplight having no INTERNET permission would not save it. The recogniser
/// runs in another process with its own permissions, and would upload
/// somebody's diary on our behalf without any manifest of ours changing. The
/// app's central promise would become false silently, and — this is the part
/// that makes it worth a test rather than a comment — **there would be no
/// symptom.** Transcripts would keep appearing. Everything would look right.
///
/// `Honest Review/WHAT-LAMPLIGHT-LACKS.md` set the condition for building this
/// at all: *"do not build this until the no-network test passes on a real phone
/// in aeroplane mode … if it fails, the answer is not to ship it with a
/// warning — the answer is not to ship it."*
///
/// That test still belongs on a phone and it is in the release checklist. This
/// is the half that can be checked here, and it is the half that would actually
/// regress: not "does this phone behave", which is fixed, but **"is the code
/// still asking for the on-device one"**, which is one careless edit away at
/// any time.
///
/// ── WHY IT READS THE SOURCE ────────────────────────────────────────────────
///
/// Because the mistake would be made in Kotlin, and a Dart test cannot call it.
/// Reading the file is crude and it is the only thing here that can fail on the
/// day somebody "fixes" transcription on an older phone by adding a fallback —
/// which is exactly the shape the mistake would take, and it would look like a
/// kindness while it was being written.
void main() {
  final kotlin = File(
    'android/app/src/main/kotlin/com/probablypiyush/lamplight/Transcribe.kt',
  );

  group('the recording never leaves the phone', () {
    /// The file with its comments removed.
    ///
    /// The comments in `Transcribe.kt` quote the dangerous name on purpose and
    /// at length, because a warning belongs where somebody about to make the
    /// mistake would be reading. So they are stripped before anything is
    /// asserted — otherwise the explanation of the rule would fail the test
    /// that enforces it.
    late String code;

    setUpAll(() {
      expect(kotlin.existsSync(), isTrue,
          reason: 'Transcribe.kt has moved; this test needs its new path');
      code = kotlin
          .readAsLinesSync()
          .where((line) {
            final t = line.trimLeft();
            return !t.startsWith('*') &&
                !t.startsWith('//') &&
                !t.startsWith('/*');
          })
          .join('\n');
    });

    test('it asks for the on-device recogniser', () {
      expect(code, contains('createOnDeviceSpeechRecognizer'),
          reason: 'the guarantee is which constructor is called');
    });

    test('and never for the ordinary one, anywhere, on any path', () {
      // `createOnDeviceSpeechRecognizer` contains `SpeechRecognizer` but not
      // `createSpeechRecognizer`, so this is an exact test rather than a
      // near-miss.
      expect(code, isNot(contains('createSpeechRecognizer')),
          reason: 'THIS IS THE ONE THAT MATTERS. Somewhere in Transcribe.kt is '
              'a call to the recogniser that uploads audio. There is no '
              'circumstance in which Lamplight may use it — not as a fallback '
              'for an old phone, not behind a setting, not "just for '
              'languages". If on-device recognition is unavailable, the '
              'feature is not offered. See the note at the top of that file.');
    });

    test('it also says it prefers offline, which is belt and braces', () {
      // A *preference*, which is exactly the sort of thing that gets ignored on
      // the day it matters — so it is welcome and it is not the guarantee.
      expect(code, contains('EXTRA_PREFER_OFFLINE'));
    });

    test('the availability gate is on the on-device check', () {
      expect(code, contains('isOnDeviceRecognitionAvailable'),
          reason: 'without this the feature would be offered on phones that '
              'have the API and no service behind it, and fail at the moment '
              'somebody first tried to use it');
    });
  });

  group('the default, and the one thing it must still be true of', () {
    // == THIS TEST USED TO ASSERT THE OPPOSITE ==============================
    //
    // It required `?? false`, on the argument that transcribing hands decrypted
    // audio to another process and ETHICAL-DESIGN.md forbids a default that
    // gives away more than was asked for. That argument was and is correct.
    //
    // **He overruled it on 28 August 2026** -- *"Make the option turned on!
    // phone's own model for voice transcription from default!"* -- and the
    // counter-argument is real: a voice note nobody can search is a voice note
    // nobody finds again, so the feature that makes speaking as good as writing
    // was off for everybody who never opened Settings.
    //
    // The default is his to set. **What is not negotiable is the sentence
    // underneath it**, and that is what this group tests now: the audio must
    // still never leave the phone. A default that is on makes the on-device
    // guarantee matter more, not less -- every other test in this file is what
    // holds that line, and none of them has been relaxed.
    test('it is on, deliberately, and the reasoning survives beside it', () {
      final settings =
          File('lib/core/settings/app_settings.dart').readAsStringSync();
      expect(
        settings,
        contains("_data['transcribeVoice'] as bool? ?? true"),
        reason: 'his decision, 28 August 2026 -- see the note above',
      );
      // The overruled argument has to stay next to the value that overruled it,
      // or the next session flips this back as an obvious oversight.
      expect(
        settings,
        contains('ETHICAL-DESIGN.md'),
        reason: 'the trade this default makes has to be written where somebody '
            'changing it will read it, not only in a commit message',
      );
    });

    test('and there is exactly one engine, which is the on-device one', () {
      final settings =
          File('lib/core/settings/app_settings.dart').readAsStringSync();
      expect(
        settings,
        isNot(contains('useSystemRecogniser')),
        reason: 'Whisper was removed, so the switch that chose between the two '
            'engines has nothing to choose between. A control with one option '
            'is furniture.',
      );
    });
  });
}
