import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// The four lines above the model. **28 August 2026.**
///
/// ══ WHAT WENT WRONG, AND WHY IT LOOKED LIKE THE MODEL'S FAULT ═════════════
///
/// > *"Is there any model better than Whisper? Cause that can't even
/// > understand mono lingual!"*
///
/// It could. What it was being handed could not be understood by anything.
///
/// A voice note is recorded at 44.1 kHz. Both transcription paths dropped it to
/// the 16 kHz that Whisper and Android's recogniser both want by **nearest
/// neighbour** — picking the closest source sample and discarding the rest —
/// and both carried a comment defending that, on the grounds that a speech
/// model re-filters everything it is given anyway.
///
/// **That is true of filtering and false of sampling**, and the distinction is
/// the whole of the bug. Decimating without a low-pass first does not remove
/// the energy above 8 kHz; it **folds it back down** into the speech band,
/// mirrored about 8 kHz, where it is thereafter indistinguishable from real
/// speech. A 10 kHz sibilant arrives as a 6 kHz tone. No front end downstream
/// can undo that, because by the time the model sees it, the aliased energy
/// *is* the signal.
///
/// And the band it lands in is where the consonants are — `s`, `sh`, `f`, `th`,
/// and the aspirated and retroflex consonants that carry most of the
/// distinctions in Hindi. Vowels survive; consonants smear. The transcript
/// comes back words-shaped and wrong, which reads as a bad model rather than as
/// four bad lines above the model.
///
/// ── WHAT THIS FILE CAN AND CANNOT DO ──────────────────────────────────────
///
/// The resampler is Kotlin, so the Dart suite cannot execute it. Two things are
/// still worth holding, and this project already does both elsewhere — the
/// on-device recogniser has a test that reads `Transcribe.kt` and fails if
/// anybody adds a fallback.
///
///  1. **The nearest-neighbour resamplers do not come back.** They are four
///     lines that look like a simplification and are a defect.
///  2. **The arithmetic is right.** The Dart mirror below is the same kernel,
///     and it is checked against the thing that actually matters: a tone above
///     the destination's Nyquist frequency must come out *quiet*, not come out
///     somewhere else.
void main() {
  group('the resamplers that must not come back', () {
    // ── ONE PATH NOW, AND IT IS STILL THE ONE THAT MATTERED ──────────────
    //
    // There were two: `Whisper.kt` and `Transcribe.kt`, and both decimated
    // 44.1 kHz to 16 kHz by nearest neighbour with no low-pass. Whisper was
    // removed on 28 August 2026, so only Android's path remains — and it is
    // the surviving one, so the assertion below matters more rather than less.
    //
    // The bug was never about which engine ran. With no low-pass, everything
    // above 8 kHz folds back into the speech band, where nothing downstream
    // can tell it from speech — and that band carries the consonants,
    // including the aspirated and retroflex ones that separate most of Hindi.
    final sources = [
      'android/app/src/main/kotlin/com/probablypiyush/lamplight/Transcribe.kt',
    ];

    test('neither path picks the nearest source sample any more', () {
      for (final path in sources) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path has moved');
        final code = file
            .readAsLinesSync()
            .where((l) {
              final t = l.trimLeft();
              // The prose in both files names the old approach on purpose.
              return !t.startsWith('*') &&
                  !t.startsWith('//') &&
                  !t.startsWith('/*');
            })
            .join('\n');

        expect(code, isNot(contains('coerceIn(0, frames - 1)')),
            reason: '$path is decimating by index again. That is aliasing, '
                'and it is what made Whisper look like it could not '
                'understand a single language. Read Resample.kt.');
      }
    });

    test('both go through the one shared resampler', () {
      for (final path in sources) {
        expect(File(path).readAsStringSync(), contains('Resample.'),
            reason: '$path must not grow a second copy of this — two copies '
                'is how one of them gets fixed and the other does not');
      }
    });

    test('the shared resampler is band-limited, not an interpolator', () {
      final code = File(
              'android/app/src/main/kotlin/com/probablypiyush/lamplight/Resample.kt')
          .readAsStringSync();
      // A linear interpolator is smooth and still aliases. The cutoff tied to
      // the *ratio* is the part that makes it an anti-aliasing filter.
      expect(code, contains('sinc'));
      expect(code, contains('blackman'));
      expect(code, contains('min(1.0, ratio)'),
          reason: 'the cutoff has to follow the rate change, or the kernel is '
              'a smoother rather than a low-pass');
    });
  });

  group('the arithmetic, mirrored', () {
    // The same kernel as `Resample.kt`, in Dart, so the property can actually
    // be measured. If this and the Kotlin ever disagree, the Kotlin is the one
    // that ships and this is the one that is wrong.
    const halfTaps = 12;

    double sinc(double x) {
      if (x == 0) return 1;
      final px = math.pi * x;
      return math.sin(px) / px;
    }

    double blackman(double x) {
      if (x <= -1 || x >= 1) return 0;
      final a = math.pi * (x + 1);
      return 0.42 - 0.5 * math.cos(a) + 0.08 * math.cos(2 * a);
    }

    List<double> resample(List<double> input, int from, int to) {
      final ratio = to / from;
      final outFrames = math.max(1, (input.length * ratio).floor());
      final cutoff = math.min(1.0, ratio);
      final halfWidth = halfTaps / cutoff;
      final out = List<double>.filled(outFrames, 0);

      for (var i = 0; i < outFrames; i++) {
        final centre = i / ratio;
        final first = (centre - halfWidth).ceil();
        final last = (centre + halfWidth).floor();
        var sum = 0.0;
        var norm = 0.0;
        for (var j = first; j <= last; j++) {
          if (j < 0 || j >= input.length) continue;
          final t = centre - j;
          final k = blackman(t / halfWidth) * sinc(cutoff * t);
          sum += k * input[j];
          norm += k;
        }
        out[i] = norm > 1e-9 ? sum / norm : 0;
      }
      return out;
    }

    /// Root-mean-square level, which is what "how loud is what came out" means.
    double rms(List<double> xs) {
      if (xs.isEmpty) return 0;
      var total = 0.0;
      for (final x in xs) {
        total += x * x;
      }
      return math.sqrt(total / xs.length);
    }

    List<double> tone(double hz, int rate, int seconds) => [
          for (var i = 0; i < rate * seconds; i++)
            math.sin(2 * math.pi * hz * i / rate),
        ];

    test('a tone inside the speech band comes through at full level', () {
      // 1 kHz — comfortably below the destination's 8 kHz Nyquist, and the
      // control for everything below.
      final out = resample(tone(1000, 44100, 1), 44100, 16000);
      // Edges excluded: the window runs off the end of the recording there,
      // which is a real effect and not the one under test.
      final body = out.sublist(400, out.length - 400);
      expect(rms(body), closeTo(0.707, 0.02),
          reason: 'an unfiltered sine has an RMS of 1/sqrt(2)');
    });

    test('a tone above the destination Nyquist is removed, not moved', () {
      // ══ THE WHOLE BUG, IN ONE ASSERTION ═══════════════════════════════
      //
      // 12 kHz sampled at 44.1 kHz, resampled to 16 kHz. Nyquist at the
      // destination is 8 kHz, so this tone cannot be represented — and the
      // question is what happens to it. Correct: it goes away. Nearest
      // neighbour: it reappears at |16000 − 12000| = 4 kHz, at nearly full
      // strength, in the middle of the speech band, sounding exactly like
      // something that was said.
      final out = resample(tone(12000, 44100, 1), 44100, 16000);
      final body = out.sublist(400, out.length - 400);

      expect(rms(body), lessThan(0.05),
          reason: 'this is the aliasing check. If it fails, energy above the '
              'destination Nyquist is being folded into the speech band, '
              'which is what made the transcripts wrong.');
    });

    test('nearest neighbour fails that same check, which is the point', () {
      // Kept as the counter-example, so the number above is a measurement
      // rather than a hopeful threshold.
      final input = tone(12000, 44100, 1);
      final ratio = 16000 / 44100;
      final outFrames = (input.length * ratio).floor();
      final naive = [
        for (var i = 0; i < outFrames; i++)
          input[math.min((i / ratio).round(), input.length - 1)],
      ];
      final body = naive.sublist(400, naive.length - 400);

      expect(rms(body), greaterThan(0.5),
          reason: 'the old code passed this tone through almost untouched, at '
              'the wrong frequency — measured at '
              '${rms(body).toStringAsFixed(3)} against the correct '
              'resampler\'s near-zero');
    });

    test('the level is not quietly changed', () {
      // A constant in, the same constant out. The kernel is normalised by its
      // own sum for exactly this: a resampler with a DC gain of 0.98 would
      // make every recording slightly quieter every time it was processed.
      final out = resample(List<double>.filled(44100, 0.5), 44100, 16000);
      for (final v in out) {
        expect(v, closeTo(0.5, 1e-6));
      }
    });

    test('a rate that needs no change is left alone', () {
      final input = tone(1000, 16000, 1);
      final out = resample(input, 16000, 16000);
      final body = out.sublist(200, out.length - 200);
      expect(rms(body), closeTo(0.707, 0.01));
    });
  });
}
