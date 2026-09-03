import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/features/capture/voice_note.dart';

/// **ISSUE 2, second half — the 0:00.**
///
/// *"And also WTF is this 0:00 — obviously that audio is not 0:00 cause that
/// plays! Why is this bug even placed here?"*
///
/// A missing duration was stored as null, turned into `Duration.zero`, and
/// printed as `0:00`: the app stating as a fact something it had never measured
/// and that was plainly false the moment you pressed play. The import path is
/// fixed at the source, but every note already in the vault still has the hole,
/// and a hole must not be printed as a number.
void main() {
  test('a length that is not known does not pretend to be zero', () {
    expect(voiceClock(Duration.zero), '--:--');
    expect(voiceClock(const Duration(milliseconds: -1)), '--:--');
  });

  test('a length that is known reads as a clock', () {
    expect(voiceClock(const Duration(seconds: 41)), '0:41');
    expect(voiceClock(const Duration(minutes: 2, seconds: 5)), '2:05');
    expect(voiceClock(const Duration(minutes: 63, seconds: 9)), '63:09');
  });

  test('seconds are always two digits, so the row does not twitch', () {
    for (var s = 0; s < 60; s++) {
      final text = voiceClock(Duration(seconds: 60 + s));
      expect(text.split(':').last.length, 2, reason: 'at $s seconds');
    }
  });

  test('one millisecond of audio is still audio, and reads as 0:00', () {
    // The boundary is deliberate: zero means "not measured", and anything
    // actually measured — however short — is a real length and reads as one.
    expect(voiceClock(const Duration(milliseconds: 1)), '0:00');
  });
}
