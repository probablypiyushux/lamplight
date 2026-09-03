import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/voice_recorder.dart';

/// **ROUND EIGHT, ISSUE 5 — pause, and the microphone that would not let go.**
///
/// > *"When the voice is being recorded, and if the app sleeps — voice recording
/// > doesn't stops — app gets closed — when I open it up back and when I try to
/// > record the voice it doesn't works! — cause the microphone was on! But no
/// > voice record file was saved or being saved!"*
///
/// The half of this that lives in Kotlin — `MediaRecorder.pause`, the window
/// flag, releasing a stale recorder instead of throwing — cannot be reached from
/// a Dart test, and the reasoning for each is written where it happens. What is
/// testable here is the contract this side keeps with that side, and one
/// decision in it that is not obvious enough to leave unguarded: **the platform
/// is believed about whether it paused.**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lamplight/documents');
  late List<MethodCall> calls;
  late Map<String, Object?> answers;

  setUp(() {
    calls = [];
    answers = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (answers.containsKey(call.method)) {
        final answer = answers[call.method];
        if (answer is PlatformException) throw answer;
        return answer;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('pause — ISSUE 5A', () {
    test('a phone that pauses is reported as having paused', () async {
      answers['pauseRecording'] = true;
      expect(await VoiceRecorder.pause(), isTrue);
      expect(calls.single.method, 'pauseRecording');
    });

    test('a phone that refuses is reported as having refused', () async {
      // ── The decision this file exists to protect ──────────────────────
      //
      // `MediaRecorder.pause` is not honoured by every device. The tempting
      // shape here is `Future<void> pause()` — call it, assume it worked, set
      // the button to "paused". That would draw a paused button over a
      // microphone that is still listening, which is the app lying about a
      // recording, in a journal whose entire claim is that it does not lie
      // about recordings. So it returns a bool and the sheet believes it.
      answers['pauseRecording'] = false;
      expect(await VoiceRecorder.pause(), isFalse);
    });

    test('a phone that throws is also a refusal, not a crash', () async {
      answers['pauseRecording'] =
          PlatformException(code: 'recorder', message: 'no');
      expect(await VoiceRecorder.pause(), isFalse,
          reason: 'the recording carries on; only the button was refused');
    });

    test('resume answers the same way', () async {
      answers['resumeRecording'] = true;
      expect(await VoiceRecorder.resume(), isTrue);
      answers['resumeRecording'] = false;
      expect(await VoiceRecorder.resume(), isFalse);
    });

    test('a build with no platform at all refuses rather than throwing',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await VoiceRecorder.pause(), isFalse);
      expect(await VoiceRecorder.resume(), isFalse);
      expect(await VoiceRecorder.isRecording(), isFalse);
    });
  });

  group('the screen stays awake — ISSUE 5B', () {
    test('asking for it sends the flag on', () async {
      await VoiceRecorder.keepAwake(true);
      expect(calls.single.method, 'keepScreenOn');
      expect(calls.single.arguments, {'on': true});
    });

    test('and letting it go sends the flag off', () async {
      await VoiceRecorder.keepAwake(false);
      expect(calls.single.arguments, {'on': false});
    });

    test('a phone that will not take the call still records', () async {
      // It dims. That is a worse experience and not a broken one, and there is
      // nothing useful to say to the user about it — so nothing is said, and
      // nothing is thrown into the middle of starting a recording.
      answers['keepScreenOn'] = PlatformException(code: 'nope');
      await expectLater(VoiceRecorder.keepAwake(true), completes);
    });
  });

  group('asking whether the microphone is still held — ISSUE 5B', () {
    test('yes', () async {
      answers['isRecording'] = true;
      expect(await VoiceRecorder.isRecording(), isTrue);
    });

    test('no', () async {
      answers['isRecording'] = false;
      expect(await VoiceRecorder.isRecording(), isFalse);
    });
  });

  group('stop and cancel are unchanged by any of this', () {
    test('stop returns the length the platform reports', () async {
      answers['stopRecording'] = 4321;
      expect(await VoiceRecorder.stop(), 4321);
    });

    test('cancel never throws, because there is nothing to tell', () async {
      answers['cancelRecording'] =
          PlatformException(code: 'recorder', message: 'already gone');
      await expectLater(VoiceRecorder.cancel(), completes);
    });
  });
}
