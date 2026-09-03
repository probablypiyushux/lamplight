import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/star_map.dart';

/// **ROUND EIGHT, ISSUE 7C — the sky, and the clock it keeps.**
///
/// The look of a star map is not something a test can hold an opinion about;
/// `star_map_render_test.dart` writes PNGs for a person to look at instead. What
/// *is* testable is the half he asked about in his own words — *"can you make it
/// time synced? one which changes a lil every hour in a day?"* — because that is
/// arithmetic, and getting it wrong would be invisible until somebody noticed
/// months later that the sky was the same every night.
void main() {
  double degrees(double radians) => radians * 180 / math.pi;

  group('the sky turns with the clock', () {
    test('15.04 degrees an hour — the real rate, not 15', () {
      final at = DateTime.utc(2026, 8, 26, 20);
      final moved = degrees(StarMap.turn(at.add(const Duration(hours: 1))) -
          StarMap.turn(at));
      expect(moved, closeTo(360.9856 / 24, 0.01));
    });

    test('a whole turn in a day, plus the four minutes', () {
      final at = DateTime.utc(2026, 8, 26, 20);
      final moved = degrees(
          StarMap.turn(at.add(const Duration(days: 1))) - StarMap.turn(at));
      // Not 360. The extra degree is why the stars rise about four minutes
      // earlier every night, and why the same clock time six months from now
      // shows the opposite face of the sky. Deleting it would make every night
      // identical, which is the one thing he asked it not to be.
      expect(moved, closeTo(360.9856, 0.01));
      expect(moved, isNot(closeTo(360.0, 0.5)));
    });

    test('366 turns in a year, not 365', () {
      // The check that the sidereal rate is a real number rather than a
      // decorated one: a year of solar days contains one more rotation of the
      // sky than it does days.
      final start = DateTime.utc(2026, 1, 1);
      final turns = degrees(
              StarMap.turn(DateTime.utc(2027, 1, 1)) - StarMap.turn(start)) /
          360;
      expect(turns, closeTo(366.25, 0.3));
    });

    test('two hours apart is thirty degrees — "changes a lil every hour"', () {
      final at = DateTime.utc(2026, 8, 26, 9);
      final moved = degrees(StarMap.turn(at.add(const Duration(hours: 2))) -
          StarMap.turn(at));
      expect(moved, closeTo(30.08, 0.02));
    });
  });

  group('the angle is quantised, and that is not cosmetic', () {
    test('two readings inside one tick are the same number', () {
      // This is what stops the sky being redrawn on every keystroke. The value
      // goes into `shouldRepaint`, so an angle taken from the raw clock would
      // differ on every rebuild and repaint thousands of stars while somebody
      // is typing a sentence.
      //
      // Written in terms of `tick` rather than in seconds. It used to say 30
      // and 90, which was two readings inside a two-minute tick and one
      // reading outside a one-minute one — so halving the tick on 2 September
      // 2026 turned a test of quantisation into a test of the old constant.
      // Half a tick past a boundary is inside that tick at any tick length.
      final at = DateTime.utc(2026, 8, 26, 12, 0, 1);
      expect(StarMap.turn(at), StarMap.turn(at.add(StarMap.tick ~/ 4)));
      expect(StarMap.turn(at), StarMap.turn(at.add(StarMap.tick ~/ 2)));
    });

    test('and readings a tick apart are not', () {
      final at = DateTime.utc(2026, 8, 26, 12);
      expect(StarMap.turn(at), isNot(StarMap.turn(at.add(StarMap.tick))));
    });

    test('one tick is about a quarter of a degree', () {
      final at = DateTime.utc(2026, 8, 26, 12);
      final step = degrees(StarMap.turn(at.add(StarMap.tick)) - StarMap.turn(at));
      // Small enough that the movement reads as continuous rather than as a
      // jump, which is the whole difference between "turns" and "flickers".
      //
      // It was half a degree until 2 September 2026, when the tick halved to a
      // minute so that a five-minute shooting star could be sampled on a grid
      // it fits. Smaller is not a regression here — it is a smoother turn for
      // thirty more repaints an hour of one cached layer.
      expect(step, closeTo(0.25, 0.01));
    });

    test('the clock, not the launch — reopening does not lose your place', () {
      // The first build of this seeded a new random sky per launch. That is
      // the reading of "changes everytime" that makes a screensaver rather
      // than a sky, and this is the property that replaced it: the same
      // instant always gives the same sky, whoever asks and whenever.
      final at = DateTime.utc(2026, 8, 26, 21, 30);
      expect(StarMap.turn(at), StarMap.turn(at));
      expect(StarMap.turn(at), StarMap.turn(at.toLocal()));
    });
  });

  group('it draws, at every size it is asked to', () {
    Future<ui.Image> render(Size size, {double turn = 0, bool dark = true}) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const base = Color(0xFF0B0B0C);
      canvas.drawRect(Offset.zero & size, Paint()..color = base);
      StarMap.paint(
        canvas,
        size,
        turn: turn,
        dark: dark,
        base: base,
        ink: const Color(0xFFF2EDE4),
        glow: const Color(0xFFE0A458),
      );
      return recorder
          .endRecording()
          .toImage(math.max(1, size.width.round()),
              math.max(1, size.height.round()));
    }

    // "I NEED THIS TO WORK AT ALL TIMES." The 46-point tile is the Appearance
    // preview and the 1024 is a tablet in the widest layout; a painter that
    // divides by a page dimension somewhere would fall over on one of them.
    for (final size in const [
      Size(46, 32),
      Size(360, 800),
      Size(686, 1143),
      Size(1024, 768),
    ]) {
      test('${size.width.toInt()}×${size.height.toInt()}', () async {
        final image = await render(size);
        expect(image.width, size.width.round());
        image.dispose();
      });
    }

    test('a page too small to be a sky is left alone rather than crashing', () {
      // Reached during a layout transition, when a box is briefly zero-sized.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => StarMap.paint(
          canvas,
          Size.zero,
          turn: 0,
          dark: true,
          base: const Color(0xFF000000),
          ink: const Color(0xFFFFFFFF),
          glow: const Color(0xFFE0A458),
        ),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('the same instant twice gives the identical sky', () async {
      // The catalogue is cached and the seed is a constant, so a repaint is a
      // redraw of the same stars — not a reshuffle. Without this the sky would
      // twinkle its way through the night instead of turning, which is the
      // single most obvious way this could look wrong.
      final a = await render(const Size(360, 640), turn: 1.234);
      final b = await render(const Size(360, 640), turn: 1.234);
      final one = await a.toByteData(format: ui.ImageByteFormat.png);
      final two = await b.toByteData(format: ui.ImageByteFormat.png);
      expect(one!.buffer.asUint8List(), two!.buffer.asUint8List());
      a.dispose();
      b.dispose();
    });

    test('an hour later is a different sky', () async {
      final at = DateTime.utc(2026, 8, 26, 22);
      final a = await render(const Size(360, 640), turn: StarMap.turn(at));
      final b = await render(const Size(360, 640),
          turn: StarMap.turn(at.add(const Duration(hours: 1))));
      final one = await a.toByteData(format: ui.ImageByteFormat.png);
      final two = await b.toByteData(format: ui.ImageByteFormat.png);
      expect(one!.buffer.asUint8List(), isNot(two!.buffer.asUint8List()),
          reason: '"I need to see different star maps every different time"');
      a.dispose();
      b.dispose();
    });
  });
  // ══ THE SHOOTING STAR'S CADENCE ══════════════════════════════════════════
  //
  // > *"Remember one thing? our star map would have one shooting star — once a
  // > hour to make it rare. Okay make it once a 5 minutes! cause nobody is
  // > gonna keep the app open for one hour!"*
  //
  // 2 September 2026. The old rate was defensible reasoning about *rarity* laid
  // on top of arithmetic nobody had multiplied out: an hourly event on a screen
  // people look at for four minutes is not rare, it is one somebody sees a few
  // times a year by accident.
  //
  // These tests exist because the failure mode of getting this wrong is
  // **completely silent**. There is no exception, no wrong colour and no bad
  // layout — there is simply never a shooting star, and nobody can tell the
  // difference between "the schedule is broken" and "I have not been lucky
  // yet". That is precisely the shape of bug this project keeps finding on a
  // phone months later, so it gets pinned here instead.
  group('the shooting star comes round every five minutes', () {
    // Walk real ticks, the way the page actually samples the sky, rather than
    // asking the schedule about instants it will never be handed.
    List<bool> ticksAcross(Duration span) {
      final from = DateTime.utc(2026, 9, 2, 21);
      final out = <bool>[];
      for (var t = Duration.zero; t < span; t += StarMap.tick) {
        out.add(StarMap.shootingStarPeriod(StarMap.turn(from.add(t))) != null);
      }
      return out;
    }

    test('exactly one tick in five, across a whole day', () {
      final seen = ticksAcross(const Duration(days: 1));
      final count = seen.where((e) => e).length;
      // One in five, with a little room for the 0.27% sidereal drift that
      // `shootingStarPeriod` documents and deliberately does not correct.
      expect(count / seen.length, closeTo(1 / 5, 0.01),
          reason: 'one minute in five is the whole request');
    });

    test('and it is never more than a few minutes away', () {
      final seen = ticksAcross(const Duration(hours: 6));
      var gap = 0, worst = 0;
      for (final on in seen) {
        if (on) {
          gap = 0;
        } else {
          worst = math.max(worst, ++gap);
        }
      }
      // Two periods back to back is the worst the slot lottery can produce:
      // the first tick of one period and the last of the next.
      expect(worst, lessThanOrEqualTo(2 * StarMap.ticksPerShootingStar),
          reason: 'nobody keeps a journal open long enough to wait longer');
    });

    // ── The regression this file exists for ────────────────────────────────
    //
    // A session is minutes long. If somebody rewrites the schedule in
    // continuous time — which reads more naturally and is what was there
    // before — the window becomes narrower than the sampling interval and can
    // land wholly between two ticks. Everything still compiles, every other
    // test still passes, and the feature is gone.
    test('a ten-minute sitting always sees one', () {
      for (var start = 0; start < 60; start++) {
        final from = DateTime.utc(2026, 9, 2, 21, start);
        var sawOne = false;
        for (var t = Duration.zero;
            t < const Duration(minutes: 10);
            t += StarMap.tick) {
          if (StarMap.shootingStarPeriod(StarMap.turn(from.add(t))) != null) {
            sawOne = true;
            break;
          }
        }
        expect(sawOne, isTrue,
            reason: 'ten minutes with the app open and no shooting star, '
                'starting at minute $start');
      }
    });

    test('the same instant always gives the same answer', () {
      final at = DateTime.utc(2026, 9, 2, 21, 37);
      expect(StarMap.shootingStarPeriod(StarMap.turn(at)),
          StarMap.shootingStarPeriod(StarMap.turn(at)));
    });

    test('it is on the page for one tick, not several', () {
      // Consecutive runs of "on" would mean it lingers, which is the thing
      // that turns a rare event back into wallpaper.
      final seen = ticksAcross(const Duration(hours: 3));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i] && seen[i - 1], isFalse,
            reason: 'two ticks in a row at index $i — it is meant to be gone '
                'again before you look up');
      }
    });
  });
  // ══ IT IS AN ANIMATION NOW, AND THAT WAS A FAIR QUESTION ═════════════════
  //
  // > *"And that shooting star is an animation right? like shooting star? make
  // > the animation look real and enough long that people can wish!"*
  //
  // It was not. It was a static line drawn on the page for one minute — a fine
  // approximation of *having seen* a meteor and not a shooting star at all.
  //
  // What a test can hold an opinion about is not whether it looks real; that is
  // what `star_map_render_test.dart` writes PNGs for. It is that **the thing
  // moves**, that it is gone at both ends, and that the same fall is always the
  // same fall — because the failure mode of getting this wrong is a streak
  // frozen in the middle of the sky, which reads as a scratch on the screen and
  // is exactly what the static version looked like.
  group('the shooting star falls', () {
    Future<List<int>> frameAt(double progress, {int period = 7}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, 400, 700));
      StarMap.paintShootingStar(
        canvas,
        const Size(400, 700),
        period: period,
        progress: progress,
        dark: true,
        ink: const Color(0xFFF2F0EA),
      );
      final image = await recorder.endRecording().toImage(400, 700);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }

    bool anyInk(List<int> pixels) {
      for (var i = 3; i < pixels.length; i += 4) {
        if (pixels[i] != 0) return true;
      }
      return false;
    }

    test('nothing before it starts and nothing after it lands', () async {
      expect(anyInk(await frameAt(0)), isFalse,
          reason: 'A controller at rest must cost nothing and draw nothing.');
      expect(anyInk(await frameAt(1)), isFalse,
          reason: 'Left on the page at the end is the static version again.');
      expect(anyInk(await frameAt(-0.2)), isFalse);
      expect(anyInk(await frameAt(1.4)), isFalse);
    });

    test('and something in the middle of it', () async {
      expect(anyInk(await frameAt(0.5)), isTrue,
          reason: 'Halfway through the fall there is a meteor on the page.');
    });

    test('which is in a different place from one moment to the next', () async {
      final early = await frameAt(0.30);
      final later = await frameAt(0.62);
      expect(early, isNot(later),
          reason: 'This is the whole of "is it an animation": two frames of '
              'the same fall must not be the same picture. A streak that does '
              'not move is a scratch on the screen.');
    });

    test('and it is on the page for the whole fall, not just the start',
        () async {
      // The bug this caught while it was being written. A travelled path is
      // two to three times longer than the static mark it replaced, so a start
      // point and direction chosen independently will often run off the edge
      // within half a second — and a meteor that exits immediately is a
      // flicker in the corner, which is the opposite of the request.
      //
      // Twelve consecutive falls, four moments each. Every one must put
      // something on the page.
      for (var period = 1; period <= 12; period++) {
        for (final at in [0.15, 0.4, 0.6, 0.85]) {
          expect(anyInk(await frameAt(at, period: period)), isTrue,
              reason: 'period $period is off the page at $at of its fall');
        }
      }
    });

    test('the same fall is always the same fall', () async {
      expect(await frameAt(0.4, period: 12), await frameAt(0.4, period: 12));
    });

    test('and two different ones are not', () async {
      expect(await frameAt(0.4, period: 12), isNot(await frameAt(0.4, period: 13)),
          reason: 'Consecutive periods are seeded apart so one does not fall '
              'down the same track as the last.');
    });
  });
}
