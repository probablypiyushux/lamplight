import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:lamplight/core/settings/video_quality.dart';

/// **ROUND FIFTEEN, ISSUE 10 — "it does prompts but never resizes".**
///
/// > *"Video Size – when uploaded it does prompts but never resizes – I want
/// > those features to work!"*
///
/// Two faults, and only the second is a bug in the usual sense.
///
/// ── ONE: THE CAP WAS ON THE WRONG EDGE ──────────────────────────────────
///
/// `Transcode.kt` capped `maxOf(width, height)` at 1080. **"1080p" is the
/// short edge** — 1080p is 1920x1080 — so an ordinary phone recording came out
/// **1080x606**, a third of the pixels, from a setting whose own note promises
/// the quality is not compromised. On the 4K clips the feature was written for
/// it did the right thing by accident, because 4K's long edge is 3840: correct
/// direction, wrong destination.
///
/// The arithmetic is in Kotlin and a Dart test cannot call it, so this reads
/// the source — the same crude method `transcription_stays_on_the_phone_test`
/// uses, and for the same reason: the mistake would be made over there and it
/// would look reasonable while it was being written.
///
/// ── TWO: EVERY WAY OF DECLINING WAS THE SAME SILENCE ────────────────────
///
/// The transcoder has a dozen ways to give up — too small to bother, already
/// at a sane bitrate, an audio codec MP4 cannot carry, no free hardware
/// encoder, a ten-bit HDR source an AVC encoder will not take — and all of
/// them returned the same null. The app asked a question, he answered it, and
/// then nothing happened and nothing was said. The second group here is that
/// answer travelling back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final kotlin = File(
    'android/app/src/main/kotlin/com/probablypiyush/lamplight/Transcode.kt',
  );

  group('the resolution cap', () {
    test('is measured on the short edge', () {
      final source = kotlin.readAsStringSync();
      expect(source, contains('val shortest = minOf(width, height)'),
          reason: '`maxOf` here turns every 1920x1080 recording into 1080x606');
      expect(source, isNot(contains('val longest = maxOf(width, height)')),
          reason: 'the line that caused it');
    });

    // The same arithmetic, written out, so the *behaviour* is pinned and not
    // only the spelling. If somebody rewrites those two lines in Kotlin, this
    // table is the statement of what they have to keep true.
    (int, int) capped(int width, int height, int cap) {
      final shortest = width < height ? width : height;
      final scale = shortest > cap ? cap / shortest : 1.0;
      return (((width * scale).toInt() ~/ 2) * 2,
          ((height * scale).toInt() ~/ 2) * 2);
    }

    test('leaves an ordinary 1080p recording alone at Balanced', () {
      expect(capped(1920, 1080, 1080), (1920, 1080),
          reason: 'this is the case he was looking at. It used to come out '
              '1080x606 and the only honest word for that is damage');
      expect(capped(1080, 1920, 1080), (1080, 1920), reason: 'portrait');
    });

    test('brings 4K down to a true 1080p', () {
      expect(capped(3840, 2160, 1080), (1920, 1080));
      expect(capped(2160, 3840, 1080), (1080, 1920));
    });

    test('Smaller is 720, on the short edge too', () {
      expect(capped(1920, 1080, 720), (1280, 720));
      expect(capped(3840, 2160, 720), (1280, 720));
    });

    test('never scales anything up', () {
      expect(capped(640, 480, 1080), (640, 480));
      expect(capped(1280, 720, 1080), (1280, 720));
    });

    test('every result is even, which H.264 requires', () {
      for (final (w, h) in [(1920, 1080), (3840, 2160), (1440, 1079), (999, 555)]) {
        for (final cap in [720, 1080]) {
          final (ow, oh) = capped(w, h, cap);
          expect(ow.isEven, isTrue, reason: '$w x $h at $cap');
          expect(oh.isEven, isTrue, reason: '$w x $h at $cap');
        }
      }
    });
  });

  group('the pump cannot spin for ever', () {
    test('there is a wall clock on it', () {
      // A decoder that produces no frames leaves `sawDecodeEnd` false for ever,
      // so `signalEndOfInputStream` is never called and the encoder has no
      // reason to finish. That is not only a hang: `ImportQueue` is strictly
      // sequential because every waiting file sits in the cache as plaintext
      // until its turn ends, so a transcode that never returns keeps the rest
      // of the batch in the clear on disk for as long as the app is alive.
      final source = kotlin.readAsStringSync();
      expect(source, contains('DEADLINE_MS'));
      expect(source, contains('System.currentTimeMillis() > giveUpAt'));
    });
  });

  group('what came back, and why', () {
    const channel = MethodChannel('lamplight/documents');
    TestDefaultBinaryMessenger messenger() =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    Future<Compressed> ask(Object? reply, {VideoQuality? quality}) async {
      messenger().setMockMethodCallHandler(channel, (_) async => reply);
      addTearDown(() => messenger().setMockMethodCallHandler(channel, null));
      final file = CapturedFile(
        file: File('${Directory.systemTemp.path}/nothing-real.mp4'),
        name: 'clip.mp4',
        mimeType: 'video/mp4',
      );
      return Capture.compressVideo(file,
          quality: quality ?? VideoQuality.balanced);
    }

    test('"keep the original" never reaches the platform at all', () async {
      var called = false;
      messenger().setMockMethodCallHandler(channel, (_) async {
        called = true;
        return null;
      });
      addTearDown(() => messenger().setMockMethodCallHandler(channel, null));
      final result = await ask(null, quality: VideoQuality.original);
      expect(called, isFalse,
          reason: 'a file the user asked us not to touch must not be able to '
              'be touched by a bug in a transcoder that never runs');
      expect(result.outcome, CompressionOutcome.notAsked);
    });

    test('too small to bother is said, not swallowed', () async {
      final result =
          await ask(<String, Object?>{'path': null, 'reason': 'alreadySmall'});
      expect(result.outcome, CompressionOutcome.alreadySmall);
    });

    test("this phone's codecs refusing is a different sentence", () async {
      final result =
          await ask(<String, Object?>{'path': null, 'reason': 'cannot'});
      expect(result.outcome, CompressionOutcome.couldNot);
    });

    test('a platform with no such method is not a lost video', () async {
      messenger().setMockMethodCallHandler(channel, null);
      final file = CapturedFile(
        file: File('${Directory.systemTemp.path}/nothing-real.mp4'),
        name: 'clip.mp4',
        mimeType: 'video/mp4',
      );
      final result = await Capture.compressVideo(file);
      expect(result.file, same(file),
          reason: 'the original is always a valid answer, and losing a clip to '
              'a compression bug is a memory somebody does not get back');
      expect(result.outcome, CompressionOutcome.couldNot);
    });
  });
}
