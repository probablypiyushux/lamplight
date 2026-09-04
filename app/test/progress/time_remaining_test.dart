import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/progress/time_remaining.dart';

/// **ROUND NINETEEN — "Time Remaining on long jobs".**
///
/// The arithmetic is trivial. What is being tested here is mostly the
/// *refusals*, because a remaining-time estimate earns its place by shutting
/// up when it does not know, and the classic version of this feature is the
/// one that says "27 minutes" for a job that takes nine seconds and is never
/// believed again.
void main() {
  /// A clock the test drives by hand, so nothing here has to sleep.
  late DateTime now;
  TimeRemaining make() => TimeRemaining(clock: () => now);
  void tick(int ms) => now = now.add(Duration(milliseconds: ms));

  setUp(() => now = DateTime(2026, 9, 5, 12));

  group('it refuses to guess', () {
    test('with nothing to go on', () {
      expect(make().remaining, isNull);
    });

    test('after a single sample, because one point has no rate', () {
      final eta = make();
      eta.update(0.5);
      tick(5000);
      expect(eta.remaining, isNull);
    });

    test('before enough of the job has actually happened', () {
      final eta = make();
      eta.update(0);
      tick(3000);
      // 1% done after three seconds. The arithmetic would happily say five
      // minutes; it has no business doing so on one per cent.
      eta.update(0.01);
      expect(eta.remaining, isNull);
    });

    test('before enough time has passed, however fast it looks', () {
      final eta = make();
      eta.update(0);
      tick(200);
      eta.update(0.5);
      expect(eta.remaining, isNull,
          reason: 'two hundred milliseconds is not evidence about a job');
    });

    test('when the job is nearly over anyway', () {
      final eta = make();
      eta.update(0);
      tick(2500);
      // Half the work in 2.5s: about 2.5s left. Not worth a countdown.
      eta.update(0.5);
      expect(eta.remaining, isNull);
    });

    test('and when it is finished', () {
      final eta = make();
      eta.update(0);
      tick(3000);
      eta.update(1);
      expect(eta.remaining, isNull);
    });
  });

  group('and when it does speak, it is roughly right', () {
    test('a steady job', () {
      final eta = make();
      eta.update(0);
      // 10% every two seconds — a twenty-second job.
      for (var i = 1; i <= 3; i++) {
        tick(2000);
        eta.update(i * 0.10);
      }
      // 70% left at 5%/s is about fourteen seconds.
      final left = eta.remaining;
      expect(left, isNotNull);
      expect(left!.inSeconds, inInclusiveRange(10, 20));
    });
  });

  group('the ratchet', () {
    test('a countdown does not creep upwards on jitter', () {
      final eta = make();
      eta.update(0);
      for (var i = 1; i <= 4; i++) {
        tick(1000);
        eta.update(i * 0.10);
      }
      final first = eta.remaining;
      expect(first, isNotNull);

      // A slow chunk — the sort a 40 MB video produces in the middle of a
      // backup. Enough to move the average, not enough to be a new reality.
      tick(1400);
      eta.update(0.45);
      final second = eta.remaining!;

      expect(second, lessThanOrEqualTo(first!),
          reason: 'an estimate that climbs while you watch is the single most '
              'irritating thing a progress screen can do');
    });

    test('but a real collapse in speed does get through', () {
      final eta = make();
      eta.update(0);
      // 5% a second: a twenty-second job, so the first estimate is well clear
      // of the "not worth saying" floor and there is something to compare to.
      for (var i = 1; i <= 4; i++) {
        tick(1000);
        eta.update(i * 0.05);
      }
      final fast = eta.remaining;
      expect(fast, isNotNull);

      // The phone throttles. Twenty seconds for one per cent.
      for (var i = 0; i < 6; i++) {
        tick(20000);
        eta.update(0.20 + (i + 1) * 0.01);
      }
      expect(eta.remaining!, greaterThan(fast!),
          reason: 'the ratchet must not hide a job that genuinely slowed down');
    });
  });

  group('humanise says it the way a person would', () {
    test('never finer than ten seconds', () {
      expect(TimeRemaining.humanise(const Duration(seconds: 3)).inSeconds, 10);
      expect(TimeRemaining.humanise(const Duration(seconds: 24)).inSeconds, 30);
    });

    test('minutes once it is minutes', () {
      expect(TimeRemaining.humanise(const Duration(seconds: 95)).inMinutes, 2);
      expect(TimeRemaining.humanise(const Duration(seconds: 61)).inMinutes, 1);
    });

    test('and gets coarser as it gets longer', () {
      // Nobody needs "23 minutes" to be distinguished from "24 minutes".
      expect(TimeRemaining.humanise(const Duration(minutes: 23)).inMinutes, 25);
    });
  });

  test('reset forgets everything', () {
    final eta = make();
    eta.update(0);
    tick(3000);
    eta.update(0.3);
    expect(eta.remaining, isNotNull);
    eta.reset();
    expect(eta.remaining, isNull);
  });

  test('rewound and repeated fractions do not produce infinities', () {
    final eta = make();
    eta.update(0.5);
    eta.update(0.5); // same instant, no time passed
    tick(1000);
    eta.update(0.2); // a rewind
    tick(3000);
    eta.update(0.2); // no progress at all
    final left = eta.remaining;
    expect(left == null || left.inSeconds.isFinite, isTrue);
  });
}
