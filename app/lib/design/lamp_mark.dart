import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// The Lamplight mark: a hanging shade, and the light falling out of it.
///
/// WHY IT IS DRAWN IN CODE AND NOT DROPPED IN AS A PNG
///
/// The same geometry has to be the lock-screen mark, the launcher icon at five
/// densities, the adaptive icon's foreground layer, and the monochrome layer
/// Android tints for themed icons. Drawn once here, all six come from one
/// source and cannot drift apart. `tool/generate_icon_test.dart` paints this
/// painter into PNG files; nothing is traced by hand and there is no binary in
/// the repository whose origin nobody remembers.
///
/// WHY THIS SHAPE
///
/// `ANNOYANCES.md`: "an actual lamplight, in the manner of iOS app icons." The
/// literal answer — a detailed Victorian street lamp — dies at 48 px, which is
/// the size that matters most because it is the size on the home screen. So the
/// mark is built from the two things that make a lamp legible at any size: a
/// solid shade, and a cone of warm light under it. Everything else is left out.
///
/// It is also the palette's own argument, drawn. `DESIGN-SYSTEM.md` says amber
/// on warm neutrals "reads as lamp, paper, evening" — this is that sentence as
/// a picture, and the accent is doing the one job it is allowed to do.
class LampMarkPainter extends CustomPainter {
  const LampMarkPainter({
    required this.shade,
    required this.glow,
    this.backdrop,
    this.cornerRadiusFraction = 0,
    this.contentScale = 1.0,
    this.monochrome = false,
    this.progress = 1.0,
  });

  /// How far through "switching the lamp on" the mark is, 0 to 1.
  ///
  /// 1 is the finished mark and is what everything except the opening
  /// animation uses. Below 1 the light is coming up: the shade arrives first,
  /// then the bulb, then the cone falls. The geometry never moves — only the
  /// light does — because a mark that slides around is an animation, and a lamp
  /// that brightens is the object doing the one thing it is for.
  final double progress;

  /// The lampshade and the cord. The bright, solid part of the mark.
  final Color shade;

  /// The light. The only large area of amber anywhere in the app, which is
  /// deliberate — it is the one place the accent is the subject.
  final Color glow;

  /// Two stops, top to bottom, for the plate behind the mark. Null leaves the
  /// background transparent, which is what the lock screen and the adaptive
  /// foreground layer both want.
  final List<Color>? backdrop;

  /// Corner rounding of that plate, as a fraction of the shortest side.
  final double cornerRadiusFraction;

  /// Shrinks the mark inside its box without shrinking the plate.
  ///
  /// Android's adaptive icons are 108 units square and crop to the middle 72 —
  /// anything outside that can be masked away by whichever shape the launcher
  /// has decided on this year. 0.667 keeps the whole mark inside the circle.
  final double contentScale;

  /// Flatten everything to one colour, for Android's themed icons — the system
  /// tints the monochrome layer to the user's wallpaper palette, so any colour
  /// we put in it is thrown away and any translucency turns to mud.
  final bool monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = Offset.zero & size;

    if (backdrop != null) {
      final radius = math.min(size.width, size.height) * cornerRadiusFraction;
      final rrect = RRect.fromRectAndRadius(plate, Radius.circular(radius));
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = ui.Gradient.linear(
            plate.topCenter,
            plate.bottomCenter,
            backdrop!,
          ),
      );
      // Clip so the glow cannot bleed past a rounded corner.
      canvas.save();
      canvas.clipRRect(rrect);
    } else {
      canvas.save();
    }

    // Everything below is expressed in a unit square and then scaled, so the
    // proportions are identical at 48 px and at 1024.
    final side = math.min(size.width, size.height) * contentScale;
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;
    canvas.translate(dx, dy);
    canvas.scale(side);

    _paintMark(canvas);

    canvas.restore();
  }

  /// The mark itself, inside a 1×1 box.
  /// Maps overall [progress] onto one stage's own 0..1.
  ///
  /// The stages overlap on purpose. A lamp does not finish glowing before it
  /// starts casting; three separate animations played end to end would read as
  /// a sequence of events, and this has to read as one thing switching on.
  double _stage(double from, double to) {
    if (progress >= to) return 1;
    if (progress <= from) return 0;
    return (progress - from) / (to - from);
  }

  void _paintMark(Canvas canvas) {
    final lightColour = monochrome ? shade : glow;

    // The lamp arrives first, then the light comes up inside it.
    final body = _stage(0.00, 0.42);
    final bulb = _stage(0.28, 0.72);
    final beam = _stage(0.46, 1.00);

    // ── The glow around the bulb ─────────────────────────────────────────────
    // Painted first so the shade sits on top of it and the light appears to
    // come out from underneath, which is the whole illusion.
    if (!monochrome && bulb > 0) {
      const centre = Offset(0.5, 0.48);
      canvas.drawCircle(
        centre,
        0.34,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            0.34,
            [
              lightColour.withValues(alpha: 0.55 * bulb),
              lightColour.withValues(alpha: 0.14 * bulb),
              lightColour.withValues(alpha: 0.0),
            ],
            [0.0, 0.45, 1.0],
          ),
      );
    }

    // ── The cone of light ────────────────────────────────────────────────────
    // Leaves the shade at its full width and widens as it falls. Faded to
    // nothing at the bottom rather than stopped, so it reads as light rather
    // than as a grey triangle someone forgot to finish.
    if (beam > 0) {
      // The beam falls rather than fading in. Its far edge travels from the
      // shade's mouth down to the floor, so the light appears to reach — which
      // is what light does, and is the difference between this and a triangle
      // whose opacity is being animated.
      final reach = 0.455 + (0.900 - 0.455) * beam;
      final spread = 0.305 + (0.100 - 0.305) * beam;
      final cone = Path()
        ..moveTo(0.305, 0.455)
        ..lineTo(0.695, 0.455)
        ..lineTo(1 - spread, reach)
        ..lineTo(spread, reach)
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0.5, 0.455),
            Offset(0.5, reach),
            monochrome
                ? [
                    lightColour.withValues(alpha: 0.55),
                    lightColour.withValues(alpha: 0.18),
                  ]
                : [
                    lightColour.withValues(alpha: 0.50 * beam),
                    lightColour.withValues(alpha: 0.0),
                  ],
          ),
      );
    }

    // ── There is no pool of light on the floor ───────────────────────────────
    //
    // Two versions of one were drawn and both were deleted. A solid ellipse
    // went brown and muddy — amber at any real opacity over a near-black plate
    // stops reading as light. A softened one read as a *shadow*, because the
    // eye compares it to the bright cone immediately above it and calls the
    // darker thing a shadow regardless of what the alpha says.
    //
    // Left out rather than fixed. The cone dissolving into nothing already says
    // the light falls away, and the design system's own rule applies to a mark
    // as much as to a screen: if it does not earn its place, it does not go in.

    // ── The cord ─────────────────────────────────────────────────────────────
    // It hangs. Without this the shade reads as a hat.
    //
    // During the opening it *drops* — the cord pays out from the top of the
    // frame and the shade comes down on the end of it. That is the one piece of
    // real movement in the mark, and it is what makes the lamp feel hung rather
    // than drawn.
    if (body > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0.4855, 0.105, 0.5145, 0.105 + (0.245 - 0.105) * body),
        Paint()..color = shade.withValues(alpha: shade.a * body),
      );
    }

    // ── The shade ────────────────────────────────────────────────────────────
    // A trapezoid, narrow at the top, with the corners rounded just enough to
    // stop the points looking sharp. Solid, so it is the anchor of the mark at
    // every size.
    final shadePath = Path()
      ..moveTo(0.408, 0.245)
      ..lineTo(0.592, 0.245)
      ..lineTo(0.700, 0.437)
      ..quadraticBezierTo(0.706, 0.455, 0.686, 0.455)
      ..lineTo(0.314, 0.455)
      ..quadraticBezierTo(0.294, 0.455, 0.300, 0.437)
      ..close();
    if (body > 0) {
      // Comes down with the cord, on the same 0..1, so shade and cord are one
      // object rather than two things that happen to appear together.
      canvas.save();
      canvas.translate(0, -(1 - body) * 0.14);
      canvas.drawPath(
        shadePath,
        Paint()..color = shade.withValues(alpha: shade.a * body),
      );
      canvas.restore();
    }

    // ── The bulb ─────────────────────────────────────────────────────────────
    // A sliver of pure light at the shade's mouth. The single brightest thing
    // in the mark, and the reason the eye lands in the middle.
    if (bulb > 0) {
      canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0.5, 0.4585), width: 0.30, height: 0.055),
        Paint()
          ..color = (monochrome ? shade : lightColour)
              .withValues(alpha: bulb),
      );
    }
  }

  @override
  bool shouldRepaint(LampMarkPainter old) =>
      old.shade != shade ||
      old.glow != glow ||
      old.backdrop != backdrop ||
      old.progress != progress ||
      old.contentScale != contentScale ||
      old.monochrome != monochrome ||
      old.cornerRadiusFraction != cornerRadiusFraction;
}

/// The mark, in the app.
///
/// Used on the lock screen and at the top of onboarding, where it is the only
/// thing on the screen that is not a word. Purely decorative to a screen
/// reader — the word "Lamplight" is right underneath it — so it is hidden
/// rather than announced as an unlabelled image.
class LampMark extends StatelessWidget {
  const LampMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: LampMarkPainter(shade: c.inkPrimary, glow: c.accent),
        ),
      ),
    );
  }
}
