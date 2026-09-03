import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A night sky, drawn, that turns with the clock. **ROUND EIGHT, ISSUE 7C.**
///
/// ══ THE REQUEST, WHICH HE MADE TWICE IN ONE DOCUMENT ═══════════════════════
///
/// *"THE MOST IMPORTANT FEATURE! I NEED THIS AT ANY WAY POSSIBLE! A STAR MAP —
/// ORIGINAL ONE WHICH CHANGES EVERYTIME — BUT WHICH IS SUBTLE AND LOOKS LIKE A
/// STAR MAP NOT JUST DOTS! I NEED THIS TO WORK AT ALL TIMES! A REAL STAR MAP!
/// IT SHOULD LOOK LIKE SOMEONE IS STAR GAZING! AND I DON'T NEED YOU TO ADD ANY
/// PHOTO OR SOMETHING? MAKE A STAR MAP! TAKE YOUR KNOWLEDGE FROM THIS WEBSITE —
/// stellarium-web.org."*
///
/// And in red across the middle of the screenshot: **"STAR MAP AS A
/// BACKGROUND"**. Nothing else in eight rounds has been asked for twice inside
/// one document.
///
/// Then, while this was being built: *"I need to see different star maps every
/// different time! Can you make it time synced? One which changes a lil every
/// hour in a day? Or every two hours in a day? Or do you have a better idea?"*
///
/// ══ THE ANSWER TO THAT QUESTION, BECAUSE IT CHANGED THE DESIGN ═════════════
///
/// The first build generated a **new random sky on every launch**. That is the
/// obvious reading of "changes every time" and it is the wrong one, for a
/// reason worth writing down: a sky that is different every time is not a sky,
/// it is a screensaver. Nothing is ever recognised, nothing is ever *his*, and
/// after a week it is wallpaper you have stopped seeing.
///
/// **So there is one sky, and it turns.** The same stars, in the same places,
/// for ever — and the page is a window onto them that rotates about a celestial
/// pole at **15.04 degrees an hour**, which is the rate the real sky turns.
/// That answers every part of what he asked and is also simply true:
///
///   * **It changes every time.** Open it at three and again at five and the
///     sky has moved thirty degrees. Open it tomorrow morning and it is
///     somewhere else entirely.
///   * **It changes "a lil" every hour**, continuously, rather than jumping to
///     an unrelated arrangement.
///   * **It is time synced** in the strict sense: the angle is a function of
///     the clock, so the sky at nine tonight is the sky at nine tonight
///     wherever you look at it from, and closing the app and reopening it does
///     not lose your place.
///   * **It comes back.** Twenty-four hours later it is nearly where it was —
///     *nearly*, because the rate is the **sidereal** 360.9856° per day, not
///     360°. The real sky returns about four minutes early every day, which
///     adds up to one extra whole turn a year. So the same clock time tomorrow
///     is one degree along, and the same clock time in six months is the
///     opposite face of the sky. That is not a flourish; it is the actual
///     phenomenon, and it costs one number.
///
/// The last of those is what makes it worth having in a journal. A page written
/// at midnight in August has the August midnight sky behind it, and the page
/// written at midnight next August will have it again.
///
/// ══ "NOT JUST DOTS" IS THE REST OF THE BRIEF ═══════════════════════════════
///
/// A field of white specks is what everybody builds and it does not read as a
/// sky — it reads as noise, or as dust on the screen. Five things separate a
/// sky from a scatter, and all five are here because leaving any one out puts
/// it back to dots:
///
///   1. **Magnitude.** Real stars are overwhelmingly faint. Brightness here is
///      `random^2.6`, so most are barely there and a handful are not — and size
///      and brightness move together, which is what the eye reads as distance
///      rather than as a bigger circle.
///   2. **Colour.** Stars are not white. They run from the blue-white of hot O
///      and B types to the amber of cool K and M, and a few per cent of
///      saturation is the difference between a sky and a pepper pot. Most sit
///      near white, which is also true.
///   3. **Structure.** The Milky Way is a band, brighter along its spine and
///      crossed by dust lanes that are *darker than the sky around them*, with
///      the stars crowding into it. It is the most recognisable thing in a real
///      sky and it costs four gradients.
///   4. **Figures.** Joined-up asterisms are what make it a **map** rather than
///      a photograph, and he named them. Each figure's stars are chained to
///      their nearest unused neighbour, which is how an eye actually links one
///      — a random polygon crosses itself and reads as a scribble.
///   5. **The grid.** Stellarium's is the giveaway that you are looking at a
///      chart of the sky rather than out of a window, and here it is the
///      cheapest possible proof that the rotation is real: the meridians
///      **radiate from the pole** and the parallels are **circles around it**,
///      so the whole wheel turns together. Drawn at four per cent, because this
///      is a page somebody writes on.
///
/// ══ THE LIGHT SKY IS A DIFFERENT OBJECT, NOT THE SAME ONE INVERTED ════════
///
/// **ROUND NINE, ISSUE 1.** *"And light time star map is just not so good! It's
/// just some black dots … rn the star map in light mode looks like a chocolate
/// which has dots. Not so good!"*
///
/// He is right, and rendering it and looking rather than reasoning about it
/// made the reason obvious: **a star is light, and on a pale page you cannot
/// draw light.** Every technique above works by adding brightness to a dark
/// ground. Run the same code on cream and each one inverts into something with
/// the opposite meaning — a bright star becomes a *big dark blot*, the halo
/// that made it glow becomes a smudge around it, and the Milky Way, which is a
/// glow, becomes a stain. Which is precisely "a chocolate which has dots".
///
/// The way out is not to tune the numbers. It is to accept that the light page
/// is a **different object with a different history**: not a photograph of the
/// night, but an **engraved star chart printed on paper** — the kind bound into
/// the back of a Victorian atlas. That object has its own conventions, and they
/// are the exact inverse of the ones above in every case where it matters:
///
///   * **magnitude is shown by size, not by brightness**, and the brightest
///     stars are drawn as a ring with a clear centre rather than as the
///     biggest, blackest dot — which is how an engraver got around ink having
///     only one value;
///   * **the constellation lines carry the picture**, so they are far stronger
///     here than on the night page, where the stars can carry it themselves;
///   * **the graticule is part of the drawing** rather than a faint hint of
///     one, because a chart without its grid is not a chart;
///   * and **the Milky Way is stippled**, not washed — a printed chart cannot
///     glow, so it shows the galaxy as a denser field of marks.
///
/// So `dark` does not choose between two palettes here. It chooses between two
/// **ways of drawing**, and that is why the branches look uneven: they are not
/// two versions of one picture.
///
/// ══ NO ASSET, AT ANY SIZE ══════════════════════════════════════════════════
///
/// *"I don't need you to add any photo or something."* Nor could we: a
/// photograph is a fixed resolution stretched over every density of screen, a
/// decode, and a megabyte in an APK whose whole claim is that you can check
/// what is inside it. Everything below is arithmetic, drawn at the size of the
/// page it is on — 46 points in the Appearance preview, or a whole tablet, same
/// code.
class StarMap {
  const StarMap._();

  /// The seed the one sky is built from.
  ///
  /// **A constant, deliberately.** It could be per install, and then everybody
  /// would have their own sky and nobody would have *the* sky. The point of not
  /// re-rolling it is that after a fortnight the shape near the pole is
  /// familiar, and something you recognise is the opposite of wallpaper. If he
  /// ever wants his own, this becomes one value in settings and nothing else
  /// changes.
  static const int catalogue = 0x5A17ED;

  /// How often the page asks the clock again.
  ///
  /// One minute is a quarter of a degree of turn — well below the threshold of
  /// noticing a step, and 60 repaints an hour of a picture the raster cache
  /// already holds as a texture. Fast enough that leaving the app open and
  /// looking at it is rewarded; slow enough that it costs nothing.
  ///
  /// ── WHY IT HALVED, 2 SEPTEMBER 2026 ──────────────────────────────────
  ///
  /// It was two minutes, chosen when the only thing this number had to serve
  /// was the *rotation*, where it is generous. It has a second job now: **it
  /// is the clock the shooting star is scheduled against.** Five ticks to a
  /// period, one minute to a tick, so "once every five minutes" is exact
  /// rather than approximate — see [shootingStarPeriod].
  ///
  /// It briefly had a third job and no longer does, which is worth recording
  /// because the reasoning was sound and the conclusion was superseded within
  /// hours. When the star was a *static mark* it was only ever drawn on a
  /// repaint, so it was **sampled** at this rate — and any appearance shorter
  /// than one tick could fall between two samples and never be drawn at all.
  /// That is why the schedule is counted in ticks rather than in clock time,
  /// and it is still why.
  ///
  /// The star is a real animation now, on its own layer with its own
  /// controller, so it is no longer sampled by anything: once a tick starts
  /// it, all 3.4 seconds of it play. The tick decides *when* it falls, not
  /// whether it is seen.
  ///
  /// The rotation is not harmed by being sampled twice as often; it is made
  /// smoother. What it costs is thirty more repaints an hour of one cached
  /// layer, on the one surface that is a sky.
  static const Duration tick = Duration(minutes: 1);

  /// The sidereal day: **360.9856 degrees per solar day**, not 360.
  ///
  /// The extra 0.9856 is why the stars rise four minutes earlier each night and
  /// why the sky makes 366.25 turns in a 365.25-day year. Deleting it would
  /// make the sky identical at the same clock time every day, which is exactly
  /// the thing he did not want.
  static const double _degreesPerDay = 360.9856;

  /// Midnight UTC at the start of 2000 — the epoch the turn is measured from.
  ///
  /// Any fixed instant would do; this one is conventional and keeps the number
  /// of days small enough that a `double` loses nothing that matters.
  static final DateTime _epoch = DateTime.utc(2000, 1, 1);

  /// How far the sky has turned, in radians, at [at].
  ///
  /// **Quantised to [tick].** Not for looks — the value goes into
  /// `shouldRepaint`, and an angle taken from the raw clock is different on
  /// every single rebuild, so the sky would be redrawn on every keystroke while
  /// somebody is typing. Rounding to the tick means the picture is rebuilt when
  /// the sky has actually moved and at no other time.
  static double turn([DateTime? at]) {
    final now = (at ?? DateTime.now()).toUtc();
    final steps =
        (now.difference(_epoch).inMilliseconds / tick.inMilliseconds).floor();
    final days = steps * tick.inMilliseconds / Duration.millisecondsPerDay;
    return days * _degreesPerDay * math.pi / 180;
  }

  /// Paints a whole sky into [size], over a page already filled with [base].
  ///
  /// [ink] is the colour a star is drawn in — near-white on a night page, the
  /// page's own ink on a light one, where the result is an engraved celestial
  /// chart rather than a photograph. [glow] is the warm accent, used for the
  /// horizon and for the light of the galactic plane.
  static void paint(
    Canvas canvas,
    Size size, {
    required double turn,
    required bool dark,
    required Color base,
    required Color ink,
    required Color glow,
    /// The size the sky is **laid out for**, which is not always the size being
    /// painted.
    ///
    /// ══ ROUND NINE, ISSUE 1 — "ZOOMED VIEW / WHY?" ═══════════════════════
    ///
    /// Two screenshots side by side, an arrow between them labelled *"Start
    /// Typing"*, and a circle round the second one: **why?**
    ///
    /// Opening the keyboard shrinks the page's box. Every measurement in
    /// `_Sky` was taken from that box — the pole at `-height * 0.34`, the
    /// annulus the field is scattered on, the offset of the Milky Way — so a
    /// shorter box meant a **completely different sky**, generated on the spot
    /// and cached under a new key. Nothing zoomed; the whole thing was rebuilt
    /// at a different scale, which is what a zoom looks like.
    ///
    /// A sky is not a property of the space left over after a keyboard. So the
    /// day view passes the size of the **window**, which does not change when
    /// the keyboard opens, and the box simply shows less of it — the way a
    /// window shows less of the sky when you lower the blind.
    ///
    /// Left null by the Appearance preview tiles, which genuinely do want a
    /// small sky of their own rather than a crop of a big one — see the note
    /// on `scale` in `_Sky`.
    Size? field,
  }) {
    if (size.shortestSide < 6) return;
    final sky = _Sky.of(field ?? size);

    _paintWash(canvas, size, dark: dark, glow: glow, ink: ink);

    // ── Everything that belongs to the sky is drawn in the sky's own frame ──
    //
    // Origin at the celestial pole, rotated by the hour angle. Two lines, and
    // the Milky Way, the grid and every figure turn together as one object —
    // which is the difference between a sky that rotates and a set of things
    // that happen to be moving.
    canvas.save();
    canvas.translate(sky.pole.dx, sky.pole.dy);
    canvas.rotate(turn);
    _paintMilkyWay(canvas, sky, dark: dark, base: base, ink: ink, glow: glow);
    _paintGrid(canvas, sky, ink: ink, dark: dark);
    // ISSUE 1's list. In the sky's own frame, because both of these turn with
    // it: the ecliptic is a great circle among the stars, and the planets sit
    // on it.
    _paintEcliptic(canvas, sky, ink: ink, dark: dark, glow: glow);
    canvas.restore();

    // The stars are placed by hand rather than by the transform, so that the
    // eleven-twelfths of the catalogue which is off the page this hour costs
    // two multiplications each instead of a draw call each.
    _paintField(canvas, size, sky, turn: turn, dark: dark, ink: ink);
    _paintFigures(canvas, size, sky, turn: turn, dark: dark, ink: ink);
    _paintPlanets(canvas, size, sky,
        turn: turn, dark: dark, ink: ink, glow: glow);

    // ── The rest of ISSUE 1's list ────────────────────────────────────────
    //
    // *"Follow the star map rule — stars + constellations + planets + the
    // horizon and zenith + the ecliptic line + the grid lines + the milky
    // way."*
    //
    // Horizon and zenith come **last and outside the rotation**, and that is
    // the point of them rather than an implementation detail. Everything above
    // turns; these two do not, because they are not in the sky — they are facts
    // about where you are standing. A horizon that rotated with the stars would
    // be the one thing on the page that made no sense.
    _paintHorizon(canvas, size, dark: dark, glow: glow, ink: ink);
    _paintZenith(canvas, size, dark: dark, ink: ink);
  }

  // ══ THE ECLIPTIC ══════════════════════════════════════════════════════════
  //
  // The path the sun takes through the stars over a year, and therefore the
  // line the planets are always found near — which is why it earns a place on a
  // chart rather than being decoration. Dashed, because that is how every
  // printed planisphere draws it and because a solid line at this weight would
  // compete with the grid.
  //
  // Tilted 23.4° from the celestial equator, which is the tilt of the Earth.
  // Getting that number right costs nothing and it is the difference between a
  // chart and a drawing of one.
  static void _paintEcliptic(
    Canvas canvas,
    _Sky sky, {
    required Color ink,
    required bool dark,
    required Color glow,
  }) {
    final radius = sky.outer * 0.52;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, 0.9 * sky.scale)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      // Warmer than the grid, because it is the sun's road. Barely — this is a
      // chart, not a diagram with a key.
      ..color = Color.lerp(ink, glow, dark ? 0.5 : 0.35)!
          .withValues(alpha: dark ? 0.10 : 0.11);

    canvas.save();
    canvas.translate(sky.eclipticCentre.dx, sky.eclipticCentre.dy);
    canvas.rotate(sky.eclipticTilt);
    // The 23.4° tilt, seen from the pole, is a flattening.
    canvas.scale(1, math.cos(23.4 * math.pi / 180));

    // Sixty dashes: short enough to read as a dashed line, few enough that this
    // is sixty draw calls twice an hour.
    const dashes = 60;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        i * 2 * math.pi / dashes,
        (2 * math.pi / dashes) * 0.55,
        false,
        paint,
      );
    }
    canvas.restore();
  }

  // ══ THE PLANETS ═══════════════════════════════════════════════════════════
  //
  // Five, on the ecliptic, each moving at its own pace.
  //
  // ── HOW HONEST THIS IS, SAID PLAINLY ──────────────────────────────────────
  //
  // They are **not** where the real planets are tonight. Real positions need
  // elliptical orbits, a solver and a table, and this file is a page background
  // rather than an observing aid. The app refuses to overclaim about its
  // cryptography and the same rule applies to its wallpaper.
  //
  // What *is* true: there are five, they sit on the ecliptic where planets
  // actually are, they are brighter and steadier than the stars around them,
  // they are the right colours, and they **move against the stars** at
  // plausibly different rates — so the one near the top in March is somewhere
  // else by June. That is the part a person can see.
  //
  // **A planet does not twinkle**, and that is real rather than a shortcut: a
  // planet is a disc rather than a point, so the atmosphere cannot make it
  // flicker the way it does a star. It is the traditional way of telling one
  // from the other by eye, and here it is free — they are simply drawn without
  // the twinkle the field has, so the steadiest lights on the page are the
  // right ones.
  static void _paintPlanets(
    Canvas canvas,
    Size size,
    _Sky sky, {
    required double turn,
    required bool dark,
    required Color ink,
    required Color glow,
  }) {
    final cos = math.cos(turn);
    final sin = math.sin(turn);
    final radius = sky.outer * 0.52;
    final squash = math.cos(23.4 * math.pi / 180);
    final t = sky.eclipticTilt;

    for (var i = 0; i < _planetDays.length; i++) {
      // Where it has crept to along the ecliptic. `turn` is the clock in
      // radians of sky, and one turn is a day, so dividing by a planet's year
      // in days gives it its own pace.
      final along = sky.planetPhase[i] + turn / _planetDays[i];

      // On the tilted circle, in the sky's frame…
      final flat =
          Offset(math.cos(along) * radius, math.sin(along) * radius * squash);
      final tilted = Offset(
        flat.dx * math.cos(t) - flat.dy * math.sin(t),
        flat.dx * math.sin(t) + flat.dy * math.cos(t),
      );
      final inSky = sky.eclipticCentre + tilted;

      // …and then turned with the sky, like everything else on it.
      final at = Offset(
        sky.pole.dx + inSky.dx * cos - inSky.dy * sin,
        sky.pole.dy + inSky.dx * sin + inSky.dy * cos,
      );
      if (at.dx < -20 ||
          at.dy < -20 ||
          at.dx > size.width + 20 ||
          at.dy > size.height + 20) {
        continue;
      }

      final colour =
          dark ? _planetColours[i] : Color.lerp(ink, _planetColours[i], 0.32)!;
      final r = (1.05 + 0.5 * _planetBrightness[i]) * sky.scale;

      canvas.drawCircle(
        at,
        r,
        Paint()
          ..isAntiAlias = true
          ..color = colour.withValues(alpha: dark ? 0.92 : 0.60),
      );
      // A wider, softer halo than a star of the same size gets, which is what
      // makes them the brightest things on the page without being the biggest.
      canvas.drawCircle(
        at,
        r * 4.2,
        Paint()
          ..shader = ui.Gradient.radial(at, r * 4.2, [
            colour.withValues(
                alpha: (dark ? 0.20 : 0.10) * _planetBrightness[i]),
            colour.withValues(alpha: 0.0),
          ]),
      );
    }
  }

  /// Each planet's year, in days. Real figures, so Jupiter crawls and Mercury
  /// hurries — the relative pace is the part that can be seen over months.
  static const List<double> _planetDays = [88, 225, 687, 4333, 10759];

  /// Their colours to the naked eye, which is most of how they are told apart.
  static const List<Color> _planetColours = [
    Color(0xFFE8E2D2), // Mercury, pale
    Color(0xFFFFF3D6), // Venus, white-gold and the brightest of them
    Color(0xFFFFB495), // Mars, orange
    Color(0xFFFFE9C0), // Jupiter, cream
    Color(0xFFF2DFA8), // Saturn, straw
  ];

  static const List<double> _planetBrightness = [0.45, 1.0, 0.62, 0.90, 0.55];

  // ══ THE HORIZON AND THE ZENITH ════════════════════════════════════════════
  //
  // The last two things on his list, and the two that do not turn.
  //
  // A planisphere has both: a horizon ring, beyond which is ground rather than
  // sky, and a zenith mark for the point directly overhead. On a phone held
  // upright the bottom of the screen is the horizon and the top is where the
  // sky is deepest — so the horizon is a warm lift along the bottom edge, real
  // sky glow from a real town, which is what anybody actually sees, and the
  // zenith is a small cross a third of the way down.
  //
  // Both are quieter than everything else on the page, because a background
  // that announces its own annotations is not a background.
  static void _paintHorizon(
    Canvas canvas,
    Size size, {
    required bool dark,
    required Color glow,
    required Color ink,
  }) {
    final band = size.height * 0.22;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - band, size.width, band),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height),
          Offset(0, size.height - band),
          [
            glow.withValues(alpha: dark ? 0.055 : 0.030),
            glow.withValues(alpha: 0.0),
          ],
        ),
    );
    // The line itself: where the sky stops. One hairline, barely there.
    canvas.drawLine(
      Offset(0, size.height - band * 0.30),
      Offset(size.width, size.height - band * 0.30),
      Paint()
        ..strokeWidth = 0.7
        ..isAntiAlias = true
        ..color = ink.withValues(alpha: dark ? 0.045 : 0.050),
    );
  }

  static void _paintZenith(
    Canvas canvas,
    Size size, {
    required bool dark,
    required Color ink,
  }) {
    // A third of the way down rather than at the very top, where the header
    // sits — the mark should be over sky, not over the date.
    final at = Offset(size.width * 0.5, size.height * 0.30);
    final arm = math.max(4.0, size.shortestSide * 0.016);
    final paint = Paint()
      ..strokeWidth = 0.8
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: dark ? 0.075 : 0.085);
    canvas.drawLine(at.translate(-arm, 0), at.translate(arm, 0), paint);
    canvas.drawLine(at.translate(0, -arm), at.translate(0, arm), paint);
  }

  /// How many [tick]s there are between one shooting star and the next.
  ///
  /// Five, and the tick is a minute, so: **one every five minutes, on the page
  /// for one of them.**
  static const int ticksPerShootingStar = 5;

  /// How big to draw things, for a sky of [size].
  ///
  /// Everything in a sky is measured off the short edge so that the 46-point
  /// Appearance tile is a *small sky* rather than a magnified crop of a large
  /// one. The shooting star is drawn on its own layer now — see
  /// `paper.dart` — so it needs this from outside.
  static double scaleFor(Size size) =>
      (size.shortestSide / 560).clamp(0.20, 1.35);

  /// The period a shooting star belongs to at [turn], or null when there is
  /// none on the page.
  ///
  /// **Public, and a function rather than four lines inside the painter**, for
  /// exactly the reason `videoBoxRatio` is: the interesting property is not
  /// the drawing, it is the *schedule*, and a schedule buried in a painter can
  /// only be checked by looking at pixels. `star_map_test.dart` walks a day of
  /// ticks through this and counts them.
  ///
  /// It is also the thing most likely to be "tidied" back into continuous time
  /// by somebody who has not read why it is written in ticks — at which point
  /// the star silently stops appearing, because the window would be narrower
  /// than the sampling interval. That failure is invisible: nothing throws,
  /// nothing looks wrong, there is simply never a shooting star again. Hence a
  /// named function with a test on it rather than a clever expression.
  static int? shootingStarPeriod(double turn) {
    // One turn is a day, so this counts ticks and keeps counting across days.
    //
    // The count runs about 0.27% fast, because a turn is a *sidereal* day and
    // this divides it as though it were a solar one. Left alone on purpose:
    // `turn` is the single number the whole sky is a function of, and taking a
    // second reading of the clock here to correct a drift of one skipped star
    // every six hours would cost that property to buy nothing anybody can see.
    final ticks = (turn /
            (2 * math.pi) *
            Duration.millisecondsPerDay /
            tick.inMilliseconds)
        .round();
    final period = ticks ~/ ticksPerShootingStar;

    // Its own hash, so consecutive periods are unrelated.
    final rng = math.Random(period * 2654435761 ^ catalogue);
    // Which of the five ticks in this period it falls on. Drawn from the
    // tick grid rather than from continuous time — see the note on [tick] for
    // why, and for why that reasoning outlived the static version of this.
    if (ticks % ticksPerShootingStar != rng.nextInt(ticksPerShootingStar)) {
      return null;
    }
    return period;
  }

  // ══ THE SHOOTING STAR ═════════════════════════════════════════════════════
  //
  // > *"And that shooting star is an animation right? like shooting star? make
  // > the animation look real and enough long that people can wish!"*
  //
  // 2 September 2026, and the honest answer to his question was **no**. It was
  // a static line, drawn on the page for one minute and then gone — which is a
  // reasonable approximation of *having seen* a meteor and is not a shooting
  // star. He asked the right question about it.
  //
  // ── WHY IT WAS STATIC, AND WHAT CHANGED TO ALLOW THIS ────────────────────
  //
  // The sky is expensive: a few thousand catalogue stars, a fresh radial shader
  // for every bright one, the figures, the planets, the milky way. It is drawn
  // into a cached layer and repainted only when the sky has actually turned,
  // which is the whole reason `PaperGround` splits the painting from its child
  // — the note at the top of that build method is the history.
  //
  // So an animated star could not live in that painter: sixty frames a second
  // of *that* is the "app hangs as hell" bug being deliberately reintroduced.
  //
  // It lives on its own layer above the sky instead, in its own
  // `RepaintBoundary`, and that layer is nearly empty — one line, one glow.
  // Animating it costs a few hundred microseconds a frame and does not touch
  // the sky at all. Three and a half seconds of that, once every five minutes,
  // is not a budget anybody will notice.
  //
  // ── HOW LONG, AND WHY NOT LONGER ─────────────────────────────────────────
  //
  // A real meteor lasts well under a second. *"Enough long that people can
  // wish"* is not a physics constraint, it is the request, and it wins — but
  // there is a limit past which it stops reading as a falling star and starts
  // reading as something being animated across the screen, and that limit is
  // somewhere around four seconds. 3.4 is long enough to notice it, point at
  // it and say something; short enough that it still falls.

  /// Draws the streak at [progress] through its fall, 0 to 1.
  ///
  /// [period] seeds where it starts and which way it goes, so consecutive ones
  /// are unrelated and the same one is always the same. Nothing is drawn
  /// outside 0..1, so a controller sitting at rest costs one comparison.
  static void paintShootingStar(
    Canvas canvas,
    Size size, {
    required int period,
    required double progress,
    required bool dark,
    required Color ink,
  }) {
    if (progress <= 0 || progress >= 1) return;

    final rng = math.Random(period * 0x9E3779B1 ^ catalogue);
    final scale = scaleFor(size);

    // ── The path, and why it is fitted to the page rather than guessed ────
    //
    // The static version could be careless about this: a mark 16-30% of the
    // short edge long, starting anywhere, mostly landed on the page and a
    // corner case that ran off it was one frame nobody saw twice.
    //
    // A travelled path cannot be careless. It is two to three times longer,
    // and a fall that leaves the page early is **worse than no fall at all** —
    // the star appears, exits after half a second, and what a person sees is a
    // flicker in the corner rather than something to look at. Which is the
    // opposite of *"enough long that people can wish"*.
    //
    // So the direction is chosen first, the start is put on the side the star
    // is coming from, and the length is then whatever fits with a margin. The
    // whole streak is on the page for the whole fall, by construction.
    final sideways = rng.nextBool() ? 1.0 : -1.0;
    final steep = 0.30 + rng.nextDouble() * 0.55;
    // Normalised, so `reach` is a real distance rather than a distance times
    // an unnoticed factor of 1.04 to 1.31.
    final slope = Offset(sideways, steep);
    final direction = slope / slope.distance;

    // Upper third, and on the far side from where it is heading.
    final from = Offset(
      sideways > 0
          ? size.width * (0.05 + rng.nextDouble() * 0.28)
          : size.width * (0.67 + rng.nextDouble() * 0.28),
      size.height * (0.05 + rng.nextDouble() * 0.26),
    );

    // How far it could go before leaving the page, on each axis.
    final roomAcross =
        (direction.dx > 0 ? size.width - from.dx : from.dx) /
            direction.dx.abs();
    final roomDown = (size.height - from.dy) / direction.dy;
    // 0.9 so it burns out just inside the edge rather than exactly on it,
    // which reads as ending rather than as leaving.
    final reach = math.min(
      size.shortestSide * (0.45 + rng.nextDouble() * 0.30),
      math.min(roomAcross, roomDown) * 0.9,
    );

    // ── The motion ─────────────────────────────────────────────────────────
    //
    // Slightly eased out. A meteor does not accelerate — it is already at
    // speed and burning out — so the head slows a little towards the end
    // rather than stopping dead, which is what a linear travel looks like.
    final travelled = 1 - math.pow(1 - progress, 1.6).toDouble();

    // The tail is the piece of the path still glowing behind the head. It
    // opens up over the first fifth of the fall and closes again at the end,
    // so the star draws itself out and then is drawn in after itself rather
    // than being a fixed dash sliding across the sky.
    final opening = math.min(1.0, progress / 0.18);
    final closing = progress < 0.72 ? 1.0 : (1 - progress) / 0.28;
    final tailSpan = 0.34 * opening * closing;

    final headAt = math.min(1.0, travelled);
    final tailAt = math.max(0.0, travelled - tailSpan);
    if (headAt - tailAt < 0.004) return;

    final head = from + direction * (reach * headAt);
    final tail = from + direction * (reach * tailAt);

    // In quickly, out gently: a meteor appears at full brightness and fades.
    final strength = (progress < 0.06 ? progress / 0.06 : closing).clamp(0.0, 1.0);
    final peak = (dark ? 0.85 : 0.55) * strength;

    // The trail. Brightest at the head and gone at the tail, which is the
    // shape of a meteor — a plain line reads as a scratch on the screen.
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeWidth = math.max(1.0, 1.5 * scale)
        ..shader = ui.Gradient.linear(head, tail, [
          ink.withValues(alpha: peak),
          ink.withValues(alpha: 0.0),
        ]),
    );

    // The head itself, which is the part that makes it read as something
    // burning rather than as a line being drawn. Small, and only ever a glow —
    // a hard dot at the end of a soft trail looks like a cursor.
    final glow = math.max(1.6, 2.4 * scale);
    canvas.drawCircle(
      head,
      glow,
      Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.radial(head, glow, [
          ink.withValues(alpha: peak),
          ink.withValues(alpha: 0.0),
        ]),
    );
  }


  // ── The sky is not one colour ─────────────────────────────────────────────
  //
  // Even on the darkest night the sky is lighter towards the horizon than
  // overhead, and warmer with it, because there is more air in the way and some
  // of it is lit. Two gradients, both barely there. They do not rotate: down is
  // still down.
  static void _paintWash(
    Canvas canvas,
    Size size, {
    required bool dark,
    required Color glow,
    required Color ink,
  }) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            ink.withValues(alpha: dark ? 0.022 : 0.014),
            ink.withValues(alpha: 0.0),
          ],
          const [0.0, 0.55],
        ),
    );

    // The warm lift at the bottom edge — the light of somewhere you are not.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 1.10),
          size.height * 0.60,
          [
            glow.withValues(alpha: dark ? 0.060 : 0.032),
            glow.withValues(alpha: 0.0),
          ],
          const [0.0, 1.0],
          TileMode.clamp,
          Matrix4.diagonal3Values(1.7, 1.0, 1.0).storage,
        ),
    );
  }

  /// The band, its clouds, and the dust lanes. Drawn in the sky's frame.
  static void _paintMilkyWay(
    Canvas canvas,
    _Sky sky, {
    required bool dark,
    required Color base,
    required Color ink,
    required Color glow,
  }) {
    final reach = sky.outer;
    final width = sky.outer * 0.5;

    // ── ISSUE 1. The printed page does not glow ──────────────────────────
    //
    // Every gradient below adds light, which is what a galaxy does. On cream
    // paper adding light does nothing at all until it turns into adding *dark*,
    // and then the Milky Way is a brown stain across the page — half of "a
    // chocolate which has dots".
    //
    // A printed chart has the same problem and a four-hundred-year-old answer:
    // **stipple**. More marks where there is more light. So on the light page
    // the band is not drawn here at all — it is drawn by the star field, which
    // already crowds into it (see `_density`), and the crowding is the galaxy.
    // Nothing is lost, because that crowding was always the strongest signal in
    // the picture; what goes is the wash that was fighting it.
    //
    // A bare `return`, with no `restore`: the save this sits inside belongs to
    // `paint`, which owns the sky's rotation and restores it itself. Popping it
    // from in here would take the grid and the ecliptic out of the sky's frame
    // and draw them on the page instead — the kind of mistake that looks like a
    // rendering bug and is really a bookkeeping one.
    if (!dark) return;

    canvas.save();
    // The band is a great circle, so in this flat model it is a straight strip
    // that misses the pole by an offset — which is why it sweeps across the
    // page rather than pivoting on the spot.
    canvas.translate(
      math.cos(sky.bandAngle + math.pi / 2) * sky.bandOffset,
      math.sin(sky.bandAngle + math.pi / 2) * sky.bandOffset,
    );
    canvas.rotate(sky.bandAngle);

    final veil = Color.lerp(ink, glow, dark ? 0.45 : 0.30)!;
    final cloudColour = Color.lerp(ink, glow, dark ? 0.35 : 0.25)!;

    // Four overlapping veils of different widths, so the band has a bright
    // spine and a soft, uneven edge instead of one symmetrical smear. The
    // colour is the warm accent rather than white: the galactic plane is the
    // light of very old stars, and it is not blue.
    for (var i = 0; i < 4; i++) {
      final half = width * sky.veilWidth[i];
      final across = width * sky.veilAcross[i];
      final alpha = (dark ? 0.062 : 0.042) * (1 - i * 0.16);
      final top = across - half;
      final bottom = across + half;
      canvas.drawRect(
        Rect.fromLTRB(-reach, top, reach, bottom),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top),
            Offset(0, bottom),
            [
              veil.withValues(alpha: 0.0),
              veil.withValues(alpha: alpha),
              veil.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // Clouds along the spine. Without them the band is a ruler; with them it
    // has somewhere to be brighter, which is what you actually see.
    for (var i = 0; i < 6; i++) {
      final at = Offset(
        sky.cloudAlong[i] * reach,
        sky.cloudAcross[i] * width,
      );
      final radius = width * sky.cloudSize[i];
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            at,
            radius,
            [
              cloudColour.withValues(alpha: dark ? 0.048 : 0.030),
              cloudColour.withValues(alpha: 0.0),
            ],
          ),
      );
    }

    // ── The dust lanes, which are the part everybody forgets ──────────────
    //
    // The dark rift down the middle of the Milky Way is not an absence of
    // stars, it is dust in front of them, and it is *darker than the sky around
    // it*. Painting it in the page's own base colour subtracts the veil back
    // out along a narrow line, which leaves the band looking split rather than
    // airbrushed.
    for (var i = 0; i < 3; i++) {
      final half = width * sky.laneWidth[i];
      final across = width * sky.laneAcross[i];
      final top = across - half;
      final bottom = across + half;
      canvas.drawRect(
        Rect.fromLTRB(-reach, top, reach, bottom),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, top),
            Offset(0, bottom),
            [
              base.withValues(alpha: 0.0),
              base.withValues(alpha: dark ? 0.60 : 0.45),
              base.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    canvas.restore();
  }

  /// The equatorial grid, at the very edge of being there.
  ///
  /// Meridians radiate from the pole and parallels are circles around it, which
  /// is what an equatorial grid actually is — and, drawn that way, it is also
  /// the thing that makes the rotation legible. Without it the sky turning
  /// could be mistaken for the stars drifting.
  static void _paintGrid(
    Canvas canvas,
    _Sky sky, {
    required Color ink,
    required bool dark,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..isAntiAlias = true
      // ISSUE 1. A chart without its graticule is not a chart. On the night
      // page the grid is a whisper because a real sky has no lines in it; on
      // the printed one it is part of the drawing.
      ..color = ink.withValues(alpha: dark ? 0.042 : 0.115);

    // Twelve meridians is one every two hours of right ascension, which is the
    // convention and happens to be the number that reads as a wheel rather than
    // as a starburst.
    const meridians = 12;
    for (var i = 0; i < meridians; i++) {
      final a = i * 2 * math.pi / meridians;
      canvas.drawLine(
        Offset(math.cos(a) * sky.inner * 0.35, math.sin(a) * sky.inner * 0.35),
        Offset(math.cos(a) * sky.outer, math.sin(a) * sky.outer),
        paint,
      );
    }

    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(Offset.zero, sky.outer * i / 6, paint);
    }
  }

  /// Every star that is not part of a figure.
  static void _paintField(
    Canvas canvas,
    Size size,
    _Sky sky, {
    required double turn,
    required bool dark,
    required Color ink,
  }) {
    // A star's halo can reach a few points beyond its centre, so the cull is
    // generous enough that nothing pops in at the edge of the page.
    const margin = 24.0;
    final cos = math.cos(turn);
    final sin = math.sin(turn);

    for (var i = 0; i < sky.count; i++) {
      // Rotating the polar position by hand rather than through the canvas, so
      // the eleven-twelfths of the catalogue that is off the page this hour
      // costs two multiplications rather than a draw call.
      final x = sky.starX[i];
      final y = sky.starY[i];
      final at = Offset(
        sky.pole.dx + x * cos - y * sin,
        sky.pole.dy + x * sin + y * cos,
      );
      if (at.dx < -margin ||
          at.dy < -margin ||
          at.dx > size.width + margin ||
          at.dy > size.height + margin) {
        continue;
      }
      _star(
        canvas,
        at,
        magnitude: sky.starMagnitude[i],
        temperature: sky.starTemperature[i],
        scale: sky.scale,
        dark: dark,
        ink: ink,
        twinkle: _twinkle(sky, i, turn),
      );
    }
  }

  // ══ ROUND NINE, ISSUE 1 — "MAKE IT LIKE TWINKLE, NOT ALL STARS" ══════════
  //
  // *"Star map more happening? Make it like twinkle — not all stars — just
  // some."*
  //
  // Both halves of that are the design, and the second half is the harder one.
  // A sky where everything twinkles is a Christmas tree; what makes a real one
  // feel alive is that **three or four things are doing it and the rest are
  // steady**, so the eye keeps being caught by something it was not looking at.
  //
  // ── WHY IT IS A FUNCTION OF THE CLOCK AND NOT AN ANIMATION ───────────────
  //
  // The page repaints every two minutes — `tick` — and that is a deliberate,
  // load-bearing number: a sky animating at 60fps behind somebody's writing
  // would cost battery all day to be admired for ten seconds, and this app has
  // "feels so slow" in the same document.
  //
  // So the brightness is a **function of the same clock the rotation is**. Each
  // star gets its own period and phase, and two minutes later it is somewhere
  // else in its cycle. You do not catch one changing. You look up after a
  // while and the sky is not quite as you left it, which is exactly what
  // actually happens when you look at stars, and it costs nothing.
  //
  // ── WHICH ONES ───────────────────────────────────────────────────────────
  //
  // Real twinkling is atmosphere, so it is strongest **near the horizon** and
  // almost absent overhead — and it is easier to see on a bright star than a
  // faint one. `_Sky` marks roughly one star in nine as a twinkler when it
  // builds the catalogue, which keeps the count honest at any page size.
  static double _twinkle(_Sky sky, int i, double turn) {
    final depth = sky.starTwinkle[i];
    if (depth <= 0) return 1;
    // The turn is already the clock, in radians of sky. Multiplying it by the
    // star's own rate gives each one a period of its own — between about
    // fifteen and fifty minutes of real time, so no two are ever in step and
    // the pattern never repeats in a way anybody could notice.
    final phase = turn * sky.starRate[i] + sky.starPhase[i];
    return 1 - depth * (0.5 - 0.5 * math.cos(phase));
  }

  /// The asterisms — the part that makes this a map.
  static void _paintFigures(
    Canvas canvas,
    Size size,
    _Sky sky, {
    required double turn,
    required bool dark,
    required Color ink,
  }) {
    final cos = math.cos(turn);
    final sin = math.sin(turn);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, 0.95 * sky.scale)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      // ISSUE 1. Far stronger on a light page, and that is the engraved-chart
      // argument in one number: on a night sky the stars carry the picture and
      // the lines are a hint, but on paper the stars are small dark marks and
      // the **lines are the picture**. At 0.14 they were a hint of a hint, and
      // what was left was a scatter of dots.
      ..color = ink.withValues(alpha: dark ? 0.125 : 0.34);

    final page = Rect.fromLTWH(0, 0, size.width, size.height).inflate(60);

    for (final figure in sky.figures) {
      final points = <Offset>[
        for (final p in figure.points)
          Offset(
            sky.pole.dx + p.dx * cos - p.dy * sin,
            sky.pole.dy + p.dx * sin + p.dy * cos,
          ),
      ];
      // One rectangle test for the whole figure. A constellation half off the
      // page still draws its visible half, which is what you want — the sky
      // does not stop at the bezel.
      if (!points.any(page.contains)) continue;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, line);

      // After the lines, so a line never crosses the face of a star.
      for (var i = 0; i < points.length; i++) {
        _star(
          canvas,
          points[i],
          magnitude: figure.magnitudes[i],
          temperature: figure.temperatures[i],
          scale: sky.scale,
          dark: dark,
          ink: ink,
        );
      }
    }
  }

  /// One star.
  static void _star(
    Canvas canvas,
    Offset at, {
    required double magnitude,
    required double temperature,
    required double scale,
    required bool dark,
    required Color ink,
    /// 1 is steady; below that the star is part way through a twinkle.
    /// **ISSUE 1.**
    double twinkle = 1,
  }) {
    // The size barely moves and the brightness does most of the work, which is
    // what the eye actually sees — a twinkling star does not visibly change
    // size, it changes how much light it is throwing.
    final radius = (0.38 + 1.75 * magnitude) * scale * (0.94 + 0.06 * twinkle);

    // ── Spectral colour ────────────────────────────────────────────────────
    //
    // Hot stars are blue-white, cool ones amber, and most of what you can see
    // is close to white.
    final tint = temperature < 0.5
        ? Color.lerp(const Color(0xFFB8CEFF), ink, temperature * 2)!
        : Color.lerp(ink, const Color(0xFFFFCE9B), (temperature - 0.5) * 2)!;
    // On a light page the stars are ink on paper — an engraved chart — so the
    // spectral tint would be a smudge. It is kept at a quarter strength,
    // because dropping it makes the light sky look printed rather than drawn.
    final colour = dark ? tint : Color.lerp(ink, tint, 0.25)!;

    // ── The engraved star. ISSUE 1 ───────────────────────────────────────
    //
    // On a light page a bright star drawn the dark way is a big black blot, and
    // a page of them is the "chocolate which has dots" he photographed. An
    // engraver had the same problem — ink has one value — and solved it the way
    // this does: **the bright ones are rings.** Size carries the magnitude, and
    // the open centre is what stops the brightest stars being the heaviest
    // marks on the paper.
    //
    // The threshold is deliberately above the halo's, so on a light page the
    // few stars that would have glowed are exactly the few that are drawn open,
    // and everything else is a plain small dot.
    if (!dark && magnitude > 0.70) {
      final ring = radius * 1.9;
      canvas.drawCircle(
        at,
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, radius * 0.55)
          ..isAntiAlias = true
          ..color = colour.withValues(alpha: (0.30 + 0.42 * magnitude) * twinkle),
      );
      // A small solid centre, so it reads as a star rather than as a hole.
      canvas.drawCircle(
        at,
        radius * 0.45,
        Paint()
          ..isAntiAlias = true
          ..color = colour.withValues(alpha: 0.55 * twinkle),
      );
      return;
    }

    final alpha =
        (dark ? 0.16 + 0.74 * magnitude : 0.20 + 0.62 * magnitude) * twinkle;
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..isAntiAlias = true
        ..color = colour.withValues(alpha: alpha),
    );

    // ── The halo, on the ones bright enough to earn it ────────────────────
    //
    // A bright star does not look like a bigger dot, it looks like a dot with
    // light around it — that is the eye's own optics, and leaving it out is
    // most of why a drawn sky looks flat. Only above 0.62, so it stays a
    // property of the few rather than a glow over everything.
    // ISSUE 1. **Night only.** A halo is light spreading, and light spreading
    // on cream paper is a grease mark. The light page draws its bright stars as
    // rings instead, above.
    if (dark && magnitude > 0.70) {
      // The halo takes the twinkle harder than the disc does, which is what
      // makes it read as a flicker rather than as a dot fading.
      final spread = radius * (2.6 + 2.2 * magnitude) * twinkle;
      canvas.drawCircle(
        at,
        spread,
        Paint()
          ..shader = ui.Gradient.radial(
            at,
            spread,
            [
              colour.withValues(alpha: (dark ? 0.13 : 0.085) * magnitude),
              colour.withValues(alpha: 0.0),
            ],
          ),
      );
    }
  }
}

/// One figure: its stars in sky coordinates, already in the order the eye
/// links them.
class _Figure {
  const _Figure(this.points, this.magnitudes, this.temperatures);

  final List<Offset> points;
  final List<double> magnitudes;
  final List<double> temperatures;
}

/// The catalogue: every star and figure, in coordinates relative to the pole,
/// built once for a given page size and reused at every turn of the clock.
///
/// ── WHY THIS IS CACHED AND NOT REGENERATED ───────────────────────────────
///
/// The page is a window onto an annulus of sky about eleven times its own area
/// — everything that will pass across it in twenty-four hours — so the
/// catalogue is thousands of stars where the page shows hundreds. Building that
/// is cheap once and wasteful every two minutes, and it also has to be
/// *identical* every time or the sky would twinkle its way through the night
/// rather than turning.
class _Sky {
  _Sky._(this.size) {
    final rng = math.Random(StarMap.catalogue);

    // Everything is measured off the short edge, so the 46-point Appearance
    // tile is a small sky rather than a magnified crop of a large one.
    scale = (size.shortestSide / 560).clamp(0.20, 1.35);

    // ── Where the pole sits ────────────────────────────────────────────────
    //
    // Off the top-left corner, which is where the celestial pole is for most of
    // the northern hemisphere and which keeps the visible sky in the part of
    // the wheel where the arcs are long and shallow. Far enough out that no
    // star ever pivots visibly on the spot — a pole *on* the page would draw
    // the eye to the one point that is not moving.
    pole = Offset(-size.width * 0.26, -size.height * 0.34);

    // The annulus that crosses the page over a full turn: from the nearest
    // point of the page to the furthest corner.
    inner = _distanceToRect(pole, size);
    outer = math.max(
      math.max((pole - Offset.zero).distance,
          (pole - Offset(size.width, 0)).distance),
      math.max((pole - Offset(0, size.height)).distance,
          (pole - Offset(size.width, size.height)).distance),
    );

    // ── The ecliptic, and the planets on it. ISSUE 1 ──────────────────────
    //
    // The sun's path is a great circle, so from the pole it is a circle whose
    // centre is offset — the offset being the 23.4 degrees between the two
    // poles. Everything here is drawn from the same seeded generator as the
    // rest of the catalogue, so the ecliptic sits in the same place in the same
    // sky for ever, which is the whole argument for the constant seed.
    eclipticTilt = rng.nextDouble() * 2 * math.pi;
    final lean = outer * math.sin(23.4 * math.pi / 180) * 0.52;
    eclipticCentre = Offset(
      math.cos(eclipticTilt) * lean,
      math.sin(eclipticTilt) * lean,
    );
    for (var i = 0; i < 5; i++) {
      planetPhase.add(rng.nextDouble() * 2 * math.pi);
    }

    // The Milky Way, as a strip offset from the pole.
    bandAngle = rng.nextDouble() * math.pi;
    bandOffset = outer * (0.18 + rng.nextDouble() * 0.34);
    for (var i = 0; i < 4; i++) {
      veilWidth.add(0.09 + rng.nextDouble() * 0.17);
      veilAcross.add((rng.nextDouble() - 0.5) * 0.22);
    }
    for (var i = 0; i < 6; i++) {
      cloudAlong.add((rng.nextDouble() - 0.5) * 1.7);
      cloudAcross.add((rng.nextDouble() - 0.5) * 0.4);
      cloudSize.add(0.16 + rng.nextDouble() * 0.26);
    }
    for (var i = 0; i < 3; i++) {
      laneWidth.add(0.020 + rng.nextDouble() * 0.055);
      laneAcross.add((rng.nextDouble() - 0.5) * 0.26);
    }

    // ── The field ──────────────────────────────────────────────────────────
    //
    // Sized off the area of the annulus rather than of the page, so that the
    // number of stars *on screen* is the same at every hour and on every
    // device. A count off the page instead would empty the sky out as the
    // window swept into the wider part of the wheel.
    final annulus = math.pi * (outer * outer - inner * inner);
    final wanted = (annulus / 1350).round().clamp(12, 20000);

    for (var i = 0; i < wanted; i++) {
      // Uniform over area, not over radius — `sqrt` is the whole difference
      // between an even sky and a bullseye crowded at the middle.
      final r = math.sqrt(
              inner * inner + rng.nextDouble() * (outer * outer - inner * inner));
      final a = rng.nextDouble() * 2 * math.pi;
      final at = Offset(math.cos(a) * r, math.sin(a) * r);

      // The field crowds into the Milky Way. Never below 40%, so the rest of
      // the sky is a sky rather than a blank margin beside a stripe.
      if (rng.nextDouble() > 0.52 + 0.48 * _density(at)) continue;

      starX.add(at.dx);
      starY.add(at.dy);
      // `^2.6` is what makes this a sky. A uniform magnitude gives an even
      // field of medium dots, which is exactly the "just dots" he complained
      // about; this leaves most of the population near invisible and a few
      // carrying the whole image.
      starMagnitude.add(math.pow(rng.nextDouble(), 2.6) as double);
      // Two draws averaged, so the strongly-coloured stars are the minority
      // they should be.
      starTemperature.add((rng.nextDouble() + rng.nextDouble()) / 2);

      // ── Which stars twinkle. ISSUE 1 ────────────────────────────────────
      //
      // *"Not all stars — just some."*
      //
      // Roughly one in nine, and the choice is not arbitrary. Twinkling is the
      // atmosphere, so it is strongest **low in the sky** and almost absent
      // overhead: a star far from the pole here is a star near the horizon on
      // this projection, so `r / outer` is a good enough stand-in for how much
      // air is in the way. And it is only visible at all on a star bright
      // enough to see change, so faint ones are left steady.
      //
      // The result is that the twinklers cluster towards the edges of the page
      // and the middle of the sky is calm, which is what a real sky does.
      final low = (r / outer).clamp(0.0, 1.0);
      final bright = starMagnitude.last;
      final twinkles = bright > 0.45 && rng.nextDouble() < 0.10 + 0.16 * low;
      starTwinkle.add(twinkles ? 0.28 + 0.34 * low : 0.0);
      // Its own period and its own starting point, so no two are in step. The
      // rate multiplies the sky's own turn, which at the sidereal rate works
      // out at roughly a quarter-hour to an hour per cycle.
      starRate.add(140 + rng.nextDouble() * 320);
      starPhase.add(rng.nextDouble() * 2 * math.pi);
    }
    count = starX.length;

    _buildFigures(rng);
  }

  final Size size;
  late final double scale;
  late final Offset pole;
  late final double inner;
  late final double outer;

  /// Where the ecliptic's circle is centred, and which way it leans.
  /// **ISSUE 1.**
  late final Offset eclipticCentre;
  late final double eclipticTilt;

  /// Where each planet started. Its position now is this plus how far the
  /// clock has moved it — see `StarMap._paintPlanets`.
  final List<double> planetPhase = [];

  late final double bandAngle;
  late final double bandOffset;
  final List<double> veilWidth = [];
  final List<double> veilAcross = [];
  final List<double> cloudAlong = [];
  final List<double> cloudAcross = [];
  final List<double> cloudSize = [];
  final List<double> laneWidth = [];
  final List<double> laneAcross = [];

  final List<double> starX = [];
  final List<double> starY = [];
  final List<double> starMagnitude = [];
  final List<double> starTemperature = [];

  /// How deeply this star twinkles. **Zero for most of them.** ISSUE 1.
  final List<double> starTwinkle = [];

  /// Its own rate and starting point, so no two are ever in step.
  final List<double> starRate = [];
  final List<double> starPhase = [];
  late final int count;

  final List<_Figure> figures = [];

  /// How far into the Milky Way a point is: 0 well outside, 1 on the spine.
  /// A Gaussian falloff, because a hard edge would read as a stripe.
  double _density(Offset p) {
    final across = (p.dx * math.sin(bandAngle) - p.dy * math.cos(bandAngle)) -
        -bandOffset;
    final t = across / (outer * 0.24);
    return math.exp(-t * t);
  }

  void _buildFigures(math.Random rng) {
    final annulus = math.pi * (outer * outer - inner * inner);
    final wanted = (annulus / 420000).round().clamp(1, 30);

    for (var f = 0; f < wanted; f++) {
      final r = math.sqrt(
          inner * inner + rng.nextDouble() * (outer * outer - inner * inner));
      final a = rng.nextDouble() * 2 * math.pi;
      final centre = Offset(math.cos(a) * r, math.sin(a) * r);
      final reach = size.shortestSide * (0.11 + rng.nextDouble() * 0.13);
      final want = 4 + rng.nextInt(4);

      final stars = <Offset>[];
      var attempts = 0;
      while (stars.length < want && attempts < 70) {
        attempts++;
        final angle = rng.nextDouble() * 2 * math.pi;
        final radius = reach * (0.25 + rng.nextDouble() * 0.75);
        final p =
            centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        // No two stars of one figure closer than a third of its reach. Two
        // stars almost on top of each other with a line between them is the
        // detail that makes a generated constellation look generated.
        if (stars.any((q) => (q - p).distance < reach * 0.33)) continue;
        stars.add(p);
      }
      if (stars.length < 3) continue;

      // ── Chained to the nearest unused neighbour, not joined at random ────
      //
      // This is the difference between an asterism and a scribble. Given a
      // handful of points the eye links each to whatever is closest and not
      // already used — that is what "seeing a shape in the stars" is — while a
      // random polygon crosses itself and reads as a mistake. A greedy
      // nearest-neighbour path is the cheapest thing that produces the long
      // limbs and sharp corners real figures have.
      final remaining = List<Offset>.of(stars);
      final order = <Offset>[remaining.removeAt(0)];
      while (remaining.isNotEmpty) {
        var best = 0;
        var bestDistance = double.infinity;
        for (var i = 0; i < remaining.length; i++) {
          final d = (remaining[i] - order.last).distance;
          if (d < bestDistance) {
            bestDistance = d;
            best = i;
          }
        }
        order.add(remaining.removeAt(best));
      }

      figures.add(_Figure(
        order,
        // A figure is made of stars you can actually see. Drawn through faint
        // ones it is a set of lines with nothing on the corners.
        [for (var i = 0; i < order.length; i++) 0.40 + rng.nextDouble() * 0.38],
        [
          for (var i = 0; i < order.length; i++)
            (rng.nextDouble() + rng.nextDouble()) / 2
        ],
      ));
    }
  }

  /// The shortest distance from a point outside a rectangle at the origin to
  /// the rectangle itself.
  static double _distanceToRect(Offset p, Size size) {
    final dx = math.max(math.max(-p.dx, 0.0), p.dx - size.width);
    final dy = math.max(math.max(-p.dy, 0.0), p.dy - size.height);
    return math.sqrt(dx * dx + dy * dy);
  }

  // ── One catalogue per page size ────────────────────────────────────────
  //
  // Four, in practice: the day view, the Appearance preview tiles, and whatever
  // else is on screen. Small enough that an LRU would be more code than it
  // saves and large enough that opening Appearance does not evict the sky the
  // day view is using and rebuild it on the way back.
  static final Map<Size, _Sky> _cache = {};

  static _Sky of(Size size) {
    // Rounded, so a one-pixel change from a keyboard opening or a scrollbar
    // appearing does not rebuild thousands of stars.
    final key = Size(size.width.roundToDouble(), size.height.roundToDouble());
    final hit = _cache[key];
    if (hit != null) return hit;
    if (_cache.length >= 4) _cache.remove(_cache.keys.first);
    return _cache[key] = _Sky._(key);
  }
}
