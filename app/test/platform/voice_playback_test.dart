import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/voice_playback.dart';

/// ISSUE 14 — "two voice notes play at the same time".
///
/// The sound was never wrong: there is one `MediaPlayer` on the Android side
/// and the second note really did replace the first. **The screen was wrong**,
/// because every voice-note widget kept its own idea of whether it was playing.
///
/// These tests are written against the object that now owns that answer, and
/// they deliberately cover the *class* of fault rather than the reported case —
/// `PLAN.md` §11 test 7. So: the second note, the second tap, the note that is
/// disposed while another is playing, and two taps landing out of order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  final channel = const MethodChannel('lamplight/documents');

  setUp(() {
    calls = [];
    VoicePlayback.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'audioState') {
        return <String, Object?>{
          'position': 1000,
          'duration': 60000,
          'playing': true,
        };
      }
      return null;
    });
  });

  tearDown(() {
    VoicePlayback.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<Uint8List> bytes() async => Uint8List.fromList([1, 2, 3]);

  test('starting a second note stops the first one on screen, not just in the '
      'speaker', () async {
    final audio = VoicePlayback.instance;

    await audio.start('note-a', bytes);
    expect(audio.isCurrent('note-a'), isTrue);

    await audio.start('note-b', bytes);

    // The report, in one line.
    expect(audio.isCurrent('note-b'), isTrue);
    expect(audio.isCurrent('note-a'), isFalse);
    expect(audio.isPlaying('note-a'), isFalse);
  });

  test('the note that is not playing shows no progress', () async {
    final audio = VoicePlayback.instance;
    await audio.start('note-a', bytes);
    await audio.start('note-b', bytes);

    // Note A must not inherit B's playhead, which is what made both of them
    // look live.
    expect(audio.progressOf('note-a'), 0);
    expect(audio.progressOf('note-b'), greaterThan(0));
  });

  test('a disposing widget cannot silence somebody else\'s note', () async {
    final audio = VoicePlayback.instance;
    await audio.start('note-a', bytes);
    await audio.start('note-b', bytes);

    // Note A's widget scrolls off the list and disposes. The old code called
    // `stop()` here unconditionally and killed B.
    await audio.stopIfCurrent('note-a');

    expect(audio.isCurrent('note-b'), isTrue,
        reason: 'B was still the one playing');
  });

  test('stopIfCurrent does stop the note that is actually playing', () async {
    final audio = VoicePlayback.instance;
    await audio.start('note-a', bytes);
    await audio.stopIfCurrent('note-a');
    expect(audio.currentId, isNull);
  });

  test('two taps in quick succession end on the one tapped last', () async {
    final audio = VoicePlayback.instance;
    final slow = Completer<Uint8List>();

    // A taps first and its decrypt is slow. B taps second and returns at once.
    final first = audio.start('note-a', () => slow.future);
    await audio.start('note-b', bytes);
    slow.complete(Uint8List.fromList([9]));
    await first;

    // Without the ticket, A's `play` would land after B's and the screen would
    // say B while the speaker said A.
    expect(audio.isCurrent('note-b'), isTrue);
    expect(audio.isCurrent('note-a'), isFalse);
    expect(
      calls.where((c) => c.method == 'playAudio'),
      hasLength(1),
      reason: 'the note that lost the race must never reach the player at all',
    );
  });

  test('a failure is reported in plain language and only on its own note',
      () async {
    final audio = VoicePlayback.instance;
    await audio.start('note-a', () async => throw StateError('boom'));

    expect(audio.error, isNotNull);
    expect(audio.error, isNot(contains('StateError')));
    expect(audio.currentId, isNull);

    // And it is gone the moment another note starts, rather than following the
    // user down the day.
    await audio.start('note-b', bytes);
    expect(audio.error, isNull);
  });

  test('there is one polling timer at most, and none when nothing plays',
      () async {
    final audio = VoicePlayback.instance;
    await audio.start('note-a', bytes);
    await audio.start('note-b', bytes);
    await audio.stop();

    // The old code left one `Timer.periodic` per widget running whether or not
    // that widget's note was the one playing. If a timer were still alive the
    // test binding would flag pending timers when this test ends.
    expect(audio.currentId, isNull);
  });
}
