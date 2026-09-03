import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'star_map.dart';
import 'tokens.dart';

/// The page as a surface rather than as an absence.
///
/// WHAT THIS IS AND WHY IT IS NOT AN IMAGE ASSET
///
/// A flat near-black fills the screen and says nothing. A very faint grain on
/// top of it says *paper*, and it is the single cheapest thing that separates
/// a designed object from a dark background. The catch is that the obvious
/// implementation — ship a 512px noise PNG and tile it — is wrong three ways:
/// it is an asset to carry, it is a fixed resolution stretched across every
/// density of screen, and it is a decoded bitmap living in memory for the life
/// of the app.
///
/// So the grain is **generated once at startup into a 96×96 texture** and
/// handed to the GPU as a repeating shader. One small allocation, tiled in
/// hardware, no asset, no decode, and it costs nothing per frame.
///
/// HOW FAINT IS FAINT
///
/// The noise is ±3% luminance at 3.5% opacity. You cannot see it if you look
/// for it; you can see its absence if you turn it off and look at the two side
/// by side. That is the correct amount. Anything you can point at is a texture,
/// and a texture behind somebody's writing is competing with it.
///
/// **It never sits over content.** The grain is painted behind everything, at
/// the very bottom of the stack, so no glyph is ever drawn on top of noise —
/// which would cost real contrast, and contrast is not ours to spend.
///
/// ══ ROUND FIVE, ISSUE 1 — THE RULED PAGE ═════════════════════════════════
///
/// *"Can you see the vagueness? Void. I know it's aesthetic, simplicity, worth
/// it — never enough. Need a background, like WhatsApp, Telegram, Instagram,
/// Signal or any other app."* He drew a ring round the empty middle of both the
/// dark and the light day and an arrow to the word **Void**.
///
/// **This is the second time he has asked**, and that is the deciding fact.
/// Round four answered it with the grain above, `PLAN.md` §8.3 argued at
/// length that Lamplight should have a *surface* rather than a *wallpaper* —
/// because WhatsApp's wallpaper works by giving a bubble something to sit on,
/// and Lamplight's entries deliberately sit on the page rather than in bubbles
/// — and every word of that is still true. It is also still not what he asked
/// for. `PLAN.md` §11 test 5 is familiarity, and §7.0 wrote down the
/// instruction in advance: *"if he asks again, build a real page motif rather
/// than re-arguing."* He asked again.
///
/// So there is a motif now, and it is **ruled lines** — the app is a journal,
/// and the one background a journal is allowed to have is the one a notebook
/// has. It is the answer that is a background without being a picture: it never
/// competes with the writing, because it is the thing writing sits on.
///
/// Three properties make it safe to have at all:
///
///   * **It is behind everything opaque.** Entry blocks are drawn on `surface`,
///     so the lines are visible in the *empty* parts of the page and vanish
///     under content — exactly like paper under a photograph.
///   * **It is under the grain.** Painted first, so the texture falls across
///     it, which is what stops it looking like a drawn grid and starts it
///     looking like a printed sheet.
///   * **The contrast is a fraction of a per cent.** `ACCESSIBILITY.md` is
///     about text contrast and this is nowhere near text, but the rule to obey
///     is simpler than that: if you can read a line *through* a letter, the
///     line is too strong.
///
/// **It follows the writing size**, not a fixed number of pixels. A ruled page
/// whose lines do not match the text sitting on them is the uncanny half of
/// skeuomorphism, and somebody at 160% text would get lines through the middle
/// of every row.
class PaperGround extends StatefulWidget {
  const PaperGround({
    super.key,
    required this.surface,
    required this.child,
    this.ruling = PageRuling.none,
    this.colour,
  });

  final PageSurface surface;

  /// What is printed on the page. **ISSUE 6.**
  ///
  /// Defaults to nothing, so a caller that has not been told about rulings
  /// draws a clean sheet rather than inheriting somebody else's lines.
  final PageRuling ruling;

  final Widget child;

  /// The base colour. Defaults to the theme's canvas, already time-shifted by
  /// whoever built the theme.
  final Color? colour;

  @override
  State<PaperGround> createState() => _PaperGroundState();
}

/// ══ ISSUE 7C — WHY A SURFACE NEEDED STATE ═════════════════════════════════
///
/// It was a `StatelessWidget` for eight rounds and had no business being
/// anything else — a page is a page. The star map is the one surface that is a
/// function of **when** as well as of what, and *"can you make it time synced?
/// one which changes a lil every hour in a day?"* is not something a stateless
/// widget can do: it would show the sky as it stood the moment the screen was
/// built and then hold it there until something unrelated caused a rebuild.
///
/// So there is a timer, and it is armed **only** on the star map. Every other
/// surface behaves exactly as it did, allocates nothing, and schedules nothing.
class _PaperGroundState extends State<PaperGround>
    with SingleTickerProviderStateMixin {
  Timer? _clock;
  double _turn = 0;

  /// ══ THE SHOOTING STAR IS AN ANIMATION NOW. 2 SEPTEMBER 2026 ═══════════
  ///
  /// > *"And that shooting star is an animation right? like shooting star?
  /// > make the animation look real and enough long that people can wish!"*
  ///
  /// The honest answer was **no**. It was a static line, on the page for one
  /// minute and then gone — a reasonable approximation of *having seen* a
  /// meteor, and not a shooting star. He asked exactly the right question.
  ///
  /// It could not have been animated where it was. The sky is drawn into a
  /// cached layer and repainted only when it has actually turned, for the
  /// reasons in the long note in `build` — sixty frames a second of a few
  /// thousand catalogue stars is the "app hangs as hell" bug, deliberately
  /// put back.
  ///
  /// So the star has its own layer above the sky and its own controller. That
  /// layer holds one line and one glow; animating it does not touch the sky,
  /// and the sky does not know it is happening.
  ///
  /// 3.4 seconds, which is not physics — a real meteor is well under one —
  /// but *"enough long that people can wish"* is the requirement and it wins.
  /// Past about four it stops reading as a falling star and starts reading as
  /// something being animated across a screen.
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  /// The period whose star is playing, or has played. Stops one tick's star
  /// being restarted by an unrelated rebuild.
  int? _played;

  @override
  void initState() {
    super.initState();
    _syncToTheSky();
  }

  @override
  void didUpdateWidget(PaperGround old) {
    super.didUpdateWidget(old);
    if (old.surface.isStarMap != widget.surface.isStarMap) _syncToTheSky();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _fall.dispose();
    super.dispose();
  }

  /// Starts or stops the clock, depending on whether this page is a sky.
  void _syncToTheSky() {
    _clock?.cancel();
    _clock = null;
    if (!widget.surface.isStarMap) return;
    _turn = StarMap.turn();
    // Two minutes is half a degree. The angle is quantised to the same step, so
    // a tick that finds the sky has not moved far enough costs one comparison
    // in `shouldRepaint` and no paint at all.
    _clock = Timer.periodic(StarMap.tick, (_) {
      if (!mounted) return;
      final now = StarMap.turn();
      if (now != _turn) setState(() => _turn = now);
      _maybeFall(now);
    });
    _maybeFall(_turn);
  }

  /// Starts a fall if this tick is the one that carries a shooting star.
  ///
  /// Checked on arming as well as on every tick, so opening the app during a
  /// star's own minute shows it rather than waiting up to five minutes for the
  /// next. `_played` makes that idempotent — a rebuild inside the same minute
  /// does not restart the fall halfway down.
  void _maybeFall(double turn) {
    final period = StarMap.shootingStarPeriod(turn);
    if (period == null || period == _played) return;
    _played = period;
    _fall.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final surface = widget.surface;
    final ruling = widget.ruling;
    final base = widget.colour ?? c.canvas;

    // ── Nothing to draw at all: a flat colour, and no painter ─────────────
    //
    // **ISSUE 6.** This used to read `if (!surface.hasGrain)`, from when the
    // ruling was a property of the surface. It is a separate choice now, and
    // that condition would have thrown away a ruling chosen on a Plain page —
    // the one combination somebody who dislikes texture but wants a rhythm to
    // write against would pick first. A control that silently does nothing on
    // one of its settings is the invisible-machinery fault again.
    if (!surface.hasGrain &&
        !surface.isStarMap &&
        ruling == PageRuling.none) {
      return ColoredBox(color: base, child: widget.child);
    }

    final dark = base.computeLuminance() < 0.5;
    // ISSUE 1. The rhythm of the rule is the rhythm of the writing, so the
    // lines land between rows rather than through them at any text size. Read
    // from the theme rather than assumed, which is what makes it hold at 200%.
    final writing = writingStyle(context);
    final line = (writing.fontSize ?? 16) * (writing.height ?? 1.5);

    // ══ THE PAGE IS A LAYER OF ITS OWN, AND THAT IS THE WHOLE FIX ══════════
    //
    // > *"The app hangs as hell! It feels like the app is loading NASA
    // > database and unable to work!"*
    //
    // He was closer than he knew. This was `CustomPaint(painter: …, child:
    // widget.child)` — the painter and the child sharing one layer.
    //
    // `shouldRepaint` does **not** protect that arrangement, and it is easy to
    // believe it does. It is only consulted when the widget is rebuilt with a
    // *new painter*. When the **child** repaints, the render object repaints,
    // and repainting a `RenderCustomPaint` means calling `painter.paint` again
    // — every time, unconditionally, however cheap `shouldRepaint` would have
    // been. Ten fields compared, and nothing ever asked.
    //
    // The child here is the whole day screen. It holds a text field, and a text
    // field holds a cursor, and a cursor blinks — so this painter ran **twice a
    // second while the page simply sat there**, and again on every keystroke,
    // every scroll and every frame of every animation.
    //
    // What it ran was: a full-screen radial gradient, the star map, the folds,
    // the ruling, and a full-screen `BlendMode.overlay` rect. The star map
    // alone walks a catalogue of several thousand stars and builds a fresh
    // radial shader for each bright one it draws. That is not a background;
    // that is a frame's entire budget, spent again on every blink of a cursor.
    //
    // Splitting them means the painting gets its own layer, which Flutter's
    // raster cache can keep as a texture and blit — so an idle page costs one
    // copy, and the sky is redrawn when the sky has actually turned. The child
    // paints into the parent layer above it and can repaint as often as it
    // likes without touching any of this.
    //
    // `isComplex: true, willChange: false` is the pair that asks for that
    // caching: expensive enough to be worth keeping, and not expected to change
    // next frame. Both are now true, and before the split neither could help.
    return Stack(
      // The stack is exactly as big as the child; the painting fills it. Any
      // other fit would either shrink the page to nothing or let it grow to
      // whatever the parent allowed.
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GrainPainter(
                // ISSUE 1. The whole screen, so that opening the keyboard shows less
                // of the same sky instead of generating a different one.
                field: surface.isStarMap ? MediaQuery.sizeOf(context) : null,
                base: base,
                rule: line,
                ruling: ruling,
                // ISSUE 7C. The whole sky travels as one number — how far it has
                // turned — so `shouldRepaint` compares it like any other field, and
                // the picture is rebuilt when the sky has moved and at no other time.
                // Null on every surface that is not a sky.
                turn: surface.isStarMap ? _turn : null,
                accent: c.accent,
                ink: c.inkPrimary,
                // ── Raised, because the old value worked too well ────────────────
                //
                // It was 0.040 / 0.026, tuned deliberately to sit below the threshold
                // of notice. It succeeded, and the result was reported as "there is no
                // difference between paper and plain" — which settles the argument. A
                // setting whose effect nobody can see is not a setting.
                //
                // Light pages still take less than dark ones: on near-black the noise
                // has to fight the display's own black crush to be there at all, and
                // on warm paper the same amount reads as dirt rather than as fibre.
                //
                // Zero on a Plain page. Since ISSUE 6 the painter also runs for a
                // plain page that has a ruling on it, and "Plain" has to keep meaning
                // *no grain* — otherwise choosing a dot grid would silently turn the
                // texture back on.
                opacity: !surface.hasGrain ? 0.0 : (dark ? 0.13 : 0.075),
                // The lamp, on the Lamplit surface. A warm wash from above the
                // top-left, which is where a reading lamp is. It is meant to be seen —
                // the whole complaint about the version this replaces was that it was
                // not.
                glow: surface.isLit ? c.accent : null,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
        ),

        // ── The shooting star, on a layer of its own ─────────────────────
        //
        // Above the sky and below the writing, which is where a meteor is:
        // behind nothing, in front of the stars, and not something you can
        // touch. `IgnorePointer` because a page you cannot tap is not a page.
        //
        // Its own `RepaintBoundary` is the entire reason this is affordable —
        // see `_fall`. The sky beneath it stays a cached texture for the whole
        // 3.4 seconds; what repaints is one line and one glow.
        //
        // `AnimatedBuilder` rather than `setState`, so a frame of the fall
        // rebuilds this subtree and nothing else on the page.
        if (surface.isStarMap)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _fall,
                  builder: (context, _) => CustomPaint(
                    painter: _FallingStarPainter(
                      period: _played ?? 0,
                      progress: _fall.value,
                      dark: dark,
                      ink: c.inkPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),

        widget.child,
      ],
    );
  }
}

/// One falling star, and nothing else.
///
/// Deliberately the smallest painter in the app. Everything expensive about a
/// sky lives in `_GrainPainter` on the layer underneath, which does not repaint
/// while this does — that separation is what makes an animated meteor cost
/// almost nothing on a page that costs a great deal to draw once.
class _FallingStarPainter extends CustomPainter {
  const _FallingStarPainter({
    required this.period,
    required this.progress,
    required this.dark,
    required this.ink,
  });

  /// Seeds where it starts and which way it goes.
  final int period;

  /// How far through its fall, 0 to 1. Outside that nothing is drawn.
  final double progress;

  final bool dark;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) => StarMap.paintShootingStar(
        canvas,
        size,
        period: period,
        progress: progress,
        dark: dark,
        ink: ink,
      );

  @override
  bool shouldRepaint(_FallingStarPainter old) =>
      old.progress != progress ||
      old.period != period ||
      old.dark != dark ||
      old.ink != ink;
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.base,
    required this.opacity,
    required this.ink,
    required this.accent,
    required this.ruling,
    this.turn,
    this.rule,
    this.glow,
    this.field,
  });

  final Color base;
  final double opacity;

  /// The size the sky is laid out for. **ISSUE 1.**
  ///
  /// The window, not the box being painted — so that opening the keyboard
  /// shows less of the same sky rather than generating a different one. Null on
  /// every surface that is not a sky. See `StarMap.paint`.
  final Size? field;

  /// How far the sky has turned, or null on a page that is not one.
  /// **ISSUE 7C.**
  final double? turn;

  /// The warm accent, for the horizon and the light of the galactic plane.
  final Color accent;

  /// What is printed on the page. **ISSUE 6.**
  final PageRuling ruling;

  /// The colour the lines are drawn in, at a very low alpha — the page's own
  /// ink rather than white or black, so the rule belongs to the palette
  /// instead of being a grey laid over it.
  final Color ink;

  /// The distance between ruled lines, or null on a plain page. **ISSUE 1.**
  final double? rule;

  /// Non-null on the Lamplit surface. The colour the light is.
  final Color? glow;

  /// One texture for the whole app, built the first time a page asks for it.
  ///
  /// Static because there is exactly one grain and every screen wants the
  /// same one. Rebuilding it per screen would be 96×96×4 bytes of pointless
  /// work on every push.
  static ui.Image? _texture;
  static bool _building = false;

  static const int _size = 96;

  static void _build(VoidCallback onReady) {
    if (_texture != null || _building) return;
    _building = true;
    // A fixed seed. The grain must be identical on every launch and every
    // device, or the page would shimmer differently each time it opened —
    // and `CLAUDE.md` rule 6 reserves the CSPRNG for things that are actually
    // secrets. A texture is not one.
    final rng = math.Random(0x1A3B5C);
    final pixels = Uint8List(_size * _size * 4);
    for (var i = 0; i < _size * _size; i++) {
      // Signed noise, rendered as white with varying alpha over the base. Two
      // samples averaged, which pulls the distribution towards the middle and
      // takes the harsh salt-and-pepper edge off single-sample noise.
      final n = (rng.nextDouble() + rng.nextDouble()) / 2;
      final v = (n * 255).round().clamp(0, 255);
      final o = i * 4;
      pixels[o] = v;
      pixels[o + 1] = v;
      pixels[o + 2] = v;
      pixels[o + 3] = 255;
    }
    ui.decodeImageFromPixels(
      pixels,
      _size,
      _size,
      ui.PixelFormat.rgba8888,
      (image) {
        _texture = image;
        _building = false;
        onReady();
      },
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);

    // ── The lamp, under the grain ──────────────────────────────────────
    //
    // Painted first so the texture sits on top of it, which is what makes it
    // read as light *falling on paper* rather than as a coloured shape stuck
    // over the top. It is an ellipse rather than a circle because a lampshade
    // throws an ellipse onto a flat surface, and it is anchored above the top
    // edge so the source itself is off-screen — you see the pool, not the bulb.
    final lamp = glow;
    if (lamp != null) {
      final centre = Offset(size.width * 0.28, -size.height * 0.10);
      final radius = size.height * 0.72;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            radius,
            [
              lamp.withValues(alpha: 0.16),
              lamp.withValues(alpha: 0.06),
              lamp.withValues(alpha: 0.0),
            ],
            const [0.0, 0.45, 1.0],
            TileMode.clamp,
            // Squashes the circle into an ellipse, wider than it is tall.
            Matrix4.diagonal3Values(1.35, 1.0, 1.0).storage,
          ),
      );
    }

    // ── The sky, if this page is one. ISSUE 7C ──────────────────
    //
    // Before the ruling and before the folds, for the same reason both of those
    // come before the grain: this is what the page is *made of*, and anything
    // printed on a page is printed on top of it. It replaces neither — a
    // ruling chosen in Appearance still applies over a sky, because taking a
    // setting away silently when another one is chosen is the invisible
    // machinery fault this project keeps finding.
    final sky = turn;
    if (sky != null) {
      StarMap.paint(
        canvas,
        size,
        turn: sky,
        dark: base.computeLuminance() < 0.5,
        base: base,
        ink: ink,
        glow: accent,
        // ISSUE 1. The sky belongs to the window, not to whatever is left of
        // it once the keyboard is up. See `StarMap.paint`'s `field`.
        field: field,
      );
    }

    // ── What is printed on the page. ISSUE 6 ───────────────────────────
    //
    // Under the grain and over the lamp, which is the order a real sheet has:
    // the light falls on the paper, the printing is part of the paper, and the
    // fibre is on top of both.
    //
    // Drawn with no left margin rule, whichever pattern is chosen. A margin
    // line is the most recognisable thing about ruled paper and it is the first
    // thing that would fight the layout — every screen now agrees on one
    // gutter, and a printed vertical either sits on that rule and doubles it or
    // sits near it and looks like a mistake.
    final gap = rule;
    if (gap != null && gap > 4 && ruling != PageRuling.none) {
      final paint = Paint()
        ..color = ink.withValues(alpha: 0.045)
        ..strokeWidth = 1
        ..isAntiAlias = ruling != PageRuling.lines;
      switch (ruling) {
        case PageRuling.none:
          break;
        case PageRuling.lines:
          // Half a line down, so the first rule is not welded to the top edge.
          for (var y = gap / 2; y < size.height; y += gap) {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
          }
        case PageRuling.isometric:
          // Verticals, plus two families at thirty degrees above and below the
          // horizontal. That is drafting paper: the three axes of an isometric
          // projection, so anything sketched on it is already in perspective.
          _paintVerticals(canvas, size, gap, paint);
          _paintDiagonals(canvas, size, gap, 30, paint);
          _paintDiagonals(canvas, size, gap, -30, paint);
        case PageRuling.triangle:
          // Three families at sixty degrees to each other — horizontal and two
          // diagonals — which tiles the page with equilateral triangles.
          for (var y = gap / 2; y < size.height; y += gap) {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
          }
          _paintDiagonals(canvas, size, gap, 60, paint);
          _paintDiagonals(canvas, size, gap, -60, paint);
        case PageRuling.dots:
          // A dot at every crossing of the same grid, and nothing between. The
          // quietest of the four: it marks the rhythm without drawing a line
          // through anything.
          final dot = Paint()..color = ink.withValues(alpha: 0.10);
          for (var y = gap / 2; y < size.height; y += gap) {
            for (var x = gap / 2; x < size.width; x += gap) {
              canvas.drawCircle(Offset(x, y), 1.0, dot);
            }
          }
      }
    }

    // ── The fibre, on top of everything ────────────────────────────────
    //
    // Last, so it falls across the lamp, the folds and the printing alike —
    // which is what stops a ruling looking like a drawn grid and starts it
    // looking like a printed sheet.
    if (opacity <= 0) return;

    final texture = _texture;
    if (texture == null) {
      // First frame: the page without its grain, and the texture arrives next
      // frame. A page that is briefly ungrained is invisible; a page that
      // blocks its first frame to build a texture is a stutter on every screen
      // push. Everything above has already been drawn, so a ruling is never
      // held back waiting for a texture it does not need.
      _build(() {
        WidgetsBinding.instance.scheduleFrame();
      });
      return;
    }

    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..shader = ui.ImageShader(
          texture,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        )
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

  /// Evenly spaced vertical rules.
  void _paintVerticals(Canvas canvas, Size size, double gap, Paint paint) {
    for (var x = gap / 2; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  /// A family of parallel lines at [degrees] from the horizontal.
  ///
  /// Spaced by the **perpendicular** distance between them rather than by where
  /// they cross the top edge, so a 30-degree family and a 60-degree family have
  /// the same visual density instead of one looking twice as crowded as the
  /// other. That is the difference between a grid and a moiré.
  ///
  /// ══ ROUND EIGHT, ISSUE 7B — "HALF DONE AND WORST" ═══════════════════════
  ///
  /// *"When you come to ruling section in Appearance — it's a blunder —
  /// isometric and triangles are half done and worst!"*
  ///
  /// **Half done is the literal truth**, and it was arithmetic. Every line in a
  /// family is identified by where it would cross `y = 0`, and the old loop ran
  /// that crossing from `-height / |sin θ|` to `width`. For a family that
  /// leans **down** to the right — the −30° and −60° halves of the two patterns
  /// he named — the lines that cover the bottom-left of the page cross `y = 0`
  /// at a **positive** x, far to the right of the sheet. On a 686 × 1000 page
  /// the −30° family needed crossings out to x = 2418 and the loop stopped at
  /// 752, so roughly the bottom-left third of the page had the up-sloping lines
  /// and nothing coming the other way.
  ///
  /// That is why only two of the four patterns were reported broken. Lines and
  /// the dot grid have no diagonals at all; isometric and triangle are the two
  /// that have a descending family, and both of them were drawing half of it.
  ///
  /// The range is no longer guessed. Each corner of the page is projected back
  /// onto `y = 0` along the family's own direction, and the loop runs between
  /// the extremes of those four numbers — which is the smallest range that
  /// provably covers the sheet, at any angle, on any page shape. The start is
  /// snapped to a whole multiple of the step so the pattern does not slide
  /// sideways when the page is resized.
  void _paintDiagonals(
    Canvas canvas,
    Size size,
    double gap,
    double degrees,
    Paint paint,
  ) {
    final radians = degrees * math.pi / 180;
    final dx = math.cos(radians);
    final dy = math.sin(radians);
    // ══ ROUND NINE, ISSUE 26 — "ISOMETRIC HAS FALLEN DOWN HERE" ═══════════
    //
    // *"Look closely how isometric has fallen down here! Why does it does not
    // work on different screen sizes."* Triangle, he notes, "have the same".
    //
    // He has diagnosed it. Round eight fixed **which** lines get drawn — the
    // list of crossings, and that fix was right and still is. It did not touch
    // **how far** each of them is drawn, which was `width + height`.
    //
    // A line entering at `y = 0` has to travel `height / |sin θ|` to reach the
    // bottom of the page. So `width + height` is only long enough when
    // `height / |sin θ| ≤ width + height` — which is a statement about the
    // page's *proportions*, and it is false for a shallow angle on a tall
    // screen. On his 686 × 1000 page the 30° families needed 2000 points and
    // got 1686, so the last 314 points of every one of them was missing: a
    // band across the bottom of the page with the verticals still there and
    // the diagonals stopping short. Exactly what he photographed, exactly the
    // patterns with a 30° family in them, and exactly why it depends on the
    // screen.
    //
    // `PagePattern.reach` is the bound, and it is exact rather than generous —
    // see the note there.
    final length = PagePattern.reach(size, degrees);
    for (final x in PagePattern.crossings(size, gap, degrees)) {
      canvas.drawLine(
        Offset(x - dx * length, -dy * length),
        Offset(x + dx * length, dy * length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.base != base ||
      old.opacity != opacity ||
      old.turn != turn ||
      old.accent != accent ||
      old.glow != glow ||
      old.rule != rule ||
      old.ruling != ruling ||
      old.field != field ||
      old.ink != ink;
}

/// The arithmetic behind a ruled page, pulled out of the painter so it can be
/// tested. **ISSUE 7B.**
///
/// A `CustomPainter` is the one part of a Flutter app a widget test cannot
/// really see: it draws into a canvas and returns nothing, so "is the pattern
/// actually on the whole page" is not a question `pumpWidget` can answer. It is
/// a question about a list of numbers, and this is the list.
class PagePattern {
  const PagePattern._();

  /// Where each line of a family at [degrees] crosses `y = 0`.
  ///
  /// A family of parallel lines is completely described by those crossings plus
  /// its angle, and spacing them by `gap / |sin θ|` puts exactly [gap] points
  /// of **perpendicular** distance between neighbours — so a 30-degree family
  /// and a 60-degree family have the same visual density rather than one
  /// looking twice as crowded as the other.
  ///
  /// ══ ROUND EIGHT, ISSUE 7B — "HALF DONE AND WORST" ═════════════════════
  ///
  /// *"When you come to ruling section in Appearance — it's a blunder —
  /// isometric and triangles are half done and worst!"*
  ///
  /// **Half done was the literal truth**, and it was this range. The old code
  /// ran the crossing from `-height / |sin θ|` to `width`, which is correct for
  /// a family leaning **up** to the right and wrong for one leaning **down**:
  /// the lines that cover the bottom-left of the page cross `y = 0` at a large
  /// **positive** x, far to the right of the sheet. On a 686 × 1000 page the
  /// −30° family needed crossings out to x = 2418 and the loop stopped at 752,
  /// so about the bottom-left third of the page had the up-sloping lines and
  /// nothing coming back the other way.
  ///
  /// That is also why exactly two of the four patterns were reported broken.
  /// Lines and the dot grid have no diagonals at all; isometric and triangle
  /// are the two with a descending family, and both drew half of it.
  ///
  /// The range is not guessed any more. Each corner of the page is projected
  /// back onto `y = 0` along the family's own direction, and the run covers the
  /// extremes of those four numbers — the smallest range that provably crosses
  /// the whole sheet, at any angle, on any page shape. The start is snapped to
  /// a whole multiple of the step so the pattern does not slide sideways as the
  /// page is resized.
  /// How far along a family's own direction a line must be drawn, from `y = 0`,
  /// to be sure of crossing the whole page. **ISSUE 26.**
  ///
  /// Every line in a family is drawn from `t = -reach` to `t = +reach` through
  /// its crossing point on `y = 0`. The page occupies `y` from 0 to `height`,
  /// and moving `t` along the line moves `y` by `t · sin θ` — so covering the
  /// page's whole vertical extent needs, and only needs,
  ///
  ///     |t| ≥ height / |sin θ|
  ///
  /// which is what this returns. It does not depend on the width at all, and
  /// that is the point: the old bound was `width + height`, and any bound
  /// involving the width is a bound that holds on some screens and not others.
  ///
  /// A `gap` of headroom on top, so the extreme lines of a family — the ones
  /// whose crossing sits outside the sheet — still have their end caps clear of
  /// the paper rather than landing exactly on the corner.
  static double reach(Size size, double degrees) {
    final dy = math.sin(degrees * math.pi / 180).abs();
    if (dy < 0.05) return size.width + size.height;
    return size.height / dy + size.width;
  }

  static List<double> crossings(Size size, double gap, double degrees) {
    final radians = degrees * math.pi / 180;
    final dx = math.cos(radians);
    final dy = math.sin(radians);
    // A family running along the horizontal never crosses y = 0 at a single
    // point, and every caller draws its horizontals directly. Guards the
    // division as well as the meaning.
    if (dy.abs() < 0.05 || gap <= 0) return const <double>[];

    final step = gap / dy.abs();

    var lowest = double.infinity;
    var highest = double.negativeInfinity;
    for (final corner in <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final crossing = corner.dx - dx * corner.dy / dy;
      if (crossing < lowest) lowest = crossing;
      if (crossing > highest) highest = crossing;
    }

    final out = <double>[];
    for (var x = (lowest / step).floorToDouble() * step;
        x <= highest + step;
        x += step) {
      out.add(x);
    }
    return out;
  }
}
