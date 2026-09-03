import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **"ALSO ONE MORE ISSUE — WHEN SLIDING BETWEEN DAYS ALSO FEELS JERKY IN
/// DAY!"** 2 September 2026.
///
/// ── THE COMMENT WAS RIGHT AND THE CODE UNDER IT WAS NOT ─────────────────────
///
/// `DayStreamState._seen` carries this note, and has since the animation was
/// added:
///
/// > *A row that was here before must not re-animate when its neighbour
/// > changes; **only genuinely new material rises in**.*
///
/// That is the correct rule. What the code implemented was a different one:
/// *only material **this widget** has not seen rises in*. On the day you are
/// already standing on those two sentences describe the same behaviour, which
/// is why this survived eleven rounds and why nobody reviewing the diff would
/// have caught it.
///
/// They come apart the moment you swipe. Every day in the `PageView` builds its
/// own `DayStreamState`, so `_seen` starts **empty for every day you arrive
/// at** — and every entry on that day is therefore "new". Swipe to a day with
/// eleven blocks on it and all eleven fade and translate in at once, on top of
/// the page slide that is already running. Two years of notes are not new
/// material; they were there before you arrived.
///
/// ── WHY THIS IS A SOURCE TEST AND NOT A WIDGET TEST ─────────────────────────
///
/// The same reason `groups_place_themselves_test.dart` is. Nothing about the
/// broken version is detectable from behaviour a test can cheaply stage: it
/// needs a vault, a database on a worker isolate, a `PageView` with a real
/// fling and a frame-by-frame reading of opacity across the arrival — and every
/// one of those is a place for the test to be flaky about something other than
/// the property.
///
/// What is cheap and exact is the **rule**: the first delivery a day makes
/// seeds `_seen` in silence. So this pins that, and it is verified to fail when
/// the seeding block is deleted.
void main() {
  test('the first batch a day delivers is seeded, not animated', () {
    final source =
        File('lib/features/day/day_stream.dart').readAsStringSync();

    expect(
      source.contains('bool _arrived = false;'),
      isTrue,
      reason: 'The flag that tells "this day is loading" apart from "something '
          'happened on this day" is gone. Without it every entry on every day '
          'you swipe to animates in at once — see the note on `_arrived`.',
    );

    // The seeding itself: on the first non-waiting delivery, every id present
    // goes into `_seen` without going through `Rising`.
    final seeds = RegExp(
      r'if\s*\(\s*!waiting\s*&&\s*!_arrived\s*\)\s*\{'
      r'[^}]*_arrived\s*=\s*true;'
      r'[^}]*_seen\.add',
      dotAll: true,
    );

    expect(
      seeds.hasMatch(source),
      isTrue,
      reason: 'The arrival seeding is missing or has been rewritten. A day must '
          'put its first batch into `_seen` before anything is built from it, '
          'or arriving at the day and material appearing on it become the same '
          'event again.',
    );
  });

  test('and new material still rises in', () {
    final source =
        File('lib/features/day/day_stream.dart').readAsStringSync();

    // The seeding must not have been "simplified" into switching the animation
    // off altogether, which would fix the jerk by deleting the feature.
    expect(
      RegExp(r'animate:\s*_seen\.add\(').allMatches(source).length,
      greaterThanOrEqualTo(2),
      reason: 'Both `Rising` call sites — the album and the single entry — '
          'should still animate genuinely new material. Turning the animation '
          'off is not the fix; knowing what is new is.',
    );
  });
}
