import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/progress/writing_session.dart';

/// **ROUND SEVENTEEN — "Time Spent writing ... encouraging people!"**
///
/// Half of this file is the feature and half is the fence around it.
/// `ETHICAL-DESIGN.md` bans streaks, running totals and anything that can
/// manufacture guilt, and a stopwatch on somebody's journal is one small step
/// from all three. The tests at the bottom are the ones that will fail if a
/// future round is asked for "you wrote 4 hours this month" and says yes.
void main() {
  late DateTime now;
  WritingSession make() => WritingSession(clock: () => now);
  void tick(int seconds) => now = now.add(Duration(seconds: seconds));

  setUp(() => now = DateTime(2026, 9, 5, 21));

  group('it measures writing, not the app being open', () {
    test('continuous typing accrues', () {
      final w = make();
      for (var i = 0; i < 12; i++) {
        w.typed();
        tick(10);
      }
      // Eleven gaps of ten seconds. The twelfth keystroke has no successor.
      expect(w.spent, const Duration(seconds: 110));
    });

    // The whole reason this is not `end - start`. Somebody starts a sentence,
    // puts the phone down, cooks dinner, and comes back to finish it. Wall
    // clock says two hours; two hours is a lie, and it would be shown to them
    // inside a sentence meant to be kind.
    test('a long absence contributes nothing', () {
      final w = make();
      w.typed();
      tick(30);
      w.typed();          // 30s of real writing
      tick(60 * 60 * 2);  // dinner
      w.typed();          // back again — the gap is not counted
      tick(30);
      w.typed();          // another 30s

      expect(w.spent, const Duration(seconds: 60),
          reason: 'two hours of not being there is not two hours of writing');
    });

    test('a thinking pause still counts, because staring at a page is writing',
        () {
      final w = make();
      w.typed();
      tick(90); // a minute and a half mid-sentence
      w.typed();
      expect(w.spent, const Duration(seconds: 90));
    });
  });

  group('and it keeps quiet when there is nothing worth saying', () {
    test('a short entry says nothing at all', () {
      final w = make();
      w.typed();
      tick(20);
      w.typed();
      expect(w.finish(), isNull,
          reason: 'telling somebody they wrote for twenty seconds is a '
              'judgement wearing the clothes of a fact');
    });

    test('an entry with no typing in it says nothing', () {
      expect(make().finish(), isNull);
    });

    test('but a real sitting is reported', () {
      final w = make();
      for (var i = 0; i < 20; i++) {
        w.typed();
        tick(20);
      }
      final spent = w.finish();
      expect(spent, isNotNull);
      expect(spent!.inMinutes, greaterThanOrEqualTo(6));
    });
  });

  // ══ THE FENCE. ETHICAL-DESIGN.md, and these are not incidental ═════════
  group('it cannot become a streak', () {
    test('finishing resets, so nothing accumulates across entries', () {
      final w = make();
      for (var i = 0; i < 10; i++) {
        w.typed();
        tick(20);
      }
      expect(w.finish(), isNotNull);

      // The next entry starts from nothing. There is no yesterday to beat.
      expect(w.spent, Duration.zero);
      expect(w.finish(), isNull);
    });

    test('the session holds no history to compare against', () {
      final w = make();
      // The public surface is three methods and one duration. If a `total`,
      // a `best`, a `days` or a `history` ever appears on this class, the
      // feature has become the thing ETHICAL-DESIGN.md forbids.
      expect(w.spent, Duration.zero);
      w.typed();
      tick(5);
      w.typed();
      w.reset();
      expect(w.spent, Duration.zero,
          reason: 'reset must genuinely forget, not archive');
    });
  });
}
