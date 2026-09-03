import 'package:flutter/material.dart';

/// The six accents, and the year-grid ramp that belongs to each.
///
/// WHY AMBER IS STILL THE DEFAULT
///
/// `DESIGN-SYSTEM.md` picked amber on warm neutrals because it reads as *lamp*,
/// and that reasoning is untouched: it is the app's own metaphor and it is why
/// the first launch looks like an evening rather than like a productivity tool.
/// What the document never said is that it had to be the only option, and a
/// private object somebody keeps for a decade is exactly the kind of thing
/// people want to be theirs.
///
/// HOW THESE WERE PICKED, WHICH IS NOT BY EYE
///
/// Every value below was generated and then measured. Each accent clears
/// **4.5:1 against `canvas`, `surface` and `raised` in both palettes** — the
/// full body-text threshold, not the 3:1 one for large text, because the accent
/// is used on timestamps and small labels as well as on headings.
///
/// The ramps are not hand-picked either. Each one starts at a neutral empty
/// and then walks the accent's own hue with a **geometric progression in
/// relative luminance**, so every adjacent pair is separated by at least 1.40×
/// — comfortably past the 1.25× that `DESIGN-SYSTEM.md` requires. That is what
/// keeps the year grid readable in greyscale, in sunlight, and to somebody who
/// sees no colour at all. `test/design/accents_test.dart` recomputes all of it
/// and fails the build rather than trusting this comment.
///
/// THE SECOND CHANNEL
///
/// Colour is never the only signal. Each accent has a name, the setting shows
/// the name beside the swatch, and the currently chosen one carries a tick as
/// well as a ring. Somebody who cannot tell Sage from Slate can still tell
/// which one is on.
enum LampAccent {
  amber(
    id: 'amber',
    label: 'Amber',
    note: 'A lamp at night. The default.',
    dark: Color(0xFFE9A94B), // 9.35:1 on canvas · 8.76 surface · 8.06 raised
    light: Color(0xFF9A6212), // 4.83:1 on canvas · 5.08 surface · 4.50 raised
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF483415),
      Color(0xFF694818),
      Color(0xFF8A5B18),
      Color(0xFFAE7015),
      Color(0xFFD58610),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFE2C49A),
      Color(0xFFD79E4E),
      Color(0xFFC07E20),
      Color(0xFFA16613),
      Color(0xFF825109),
    ],
  ),

  rose(
    id: 'rose',
    label: 'Rose',
    note: 'Warm pink. Softer than the amber.',
    dark: Color(0xFFF08CA0), // 8.19 · 7.67 · 7.06
    light: Color(0xFFB03050), // 5.89 · 6.20 · 5.49
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF661E2D),
      Color(0xFF922339),
      Color(0xFFC12343),
      Color(0xFFE53B5D),
      Color(0xFFF36A86),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFE4BFC9),
      Color(0xFFD896A7),
      Color(0xFFD06E87),
      Color(0xFFCA3E61),
      Color(0xFFAA2748),
    ],
  ),

  sage(
    id: 'sage',
    label: 'Sage',
    note: 'Quiet green. The calmest of the six.',
    dark: Color(0xFF8FC69A), // 9.78 · 9.16 · 8.43
    light: Color(0xFF2F6E43), // 5.81 · 6.12 · 5.42
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF263C2B),
      Color(0xFF33563A),
      Color(0xFF3D7047),
      Color(0xFF478B55),
      Color(0xFF50A962),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFAED1B9),
      Color(0xFF74B889),
      Color(0xFF499D64),
      Color(0xFF37804E),
      Color(0xFF28673C),
    ],
  ),

  slate(
    id: 'slate',
    label: 'Slate',
    note: 'Cool blue-grey. The most neutral.',
    dark: Color(0xFF9DB6D4), // 9.20 · 8.62 · 7.93
    light: Color(0xFF3C5F87), // 6.27 · 6.61 · 5.85
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF2A394A),
      Color(0xFF39506C),
      Color(0xFF45678F),
      Color(0xFF5480B4),
      Color(0xFF759BC8),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFBECAD9),
      Color(0xFF94ABC6),
      Color(0xFF6C8FB8),
      Color(0xFF4A75A7),
      Color(0xFF385D89),
    ],
  ),

  plum(
    id: 'plum',
    label: 'Plum',
    note: 'Deep purple.',
    dark: Color(0xFFC79BE0), // 8.40 · 7.86 · 7.24
    light: Color(0xFF7A3E96), // 6.74 · 7.10 · 6.29
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF4A2A5C),
      Color(0xFF6B3888),
      Color(0xFF8D42B8),
      Color(0xFFA55FCD),
      Color(0xFFBC80DD),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFD5C3DE),
      Color(0xFFBE9CCE),
      Color(0xFFAB79C2),
      Color(0xFF9A57B9),
      Color(0xFF823CA2),
    ],
  ),

  ember(
    id: 'ember',
    label: 'Ember',
    note: 'Burnt orange. The warmest.',
    dark: Color(0xFFF29470), // 8.44 · 7.91 · 7.28
    light: Color(0xFFA8442A), // 5.65 · 5.96 · 5.27
    darkRamp: <Color>[
      Color(0xFF1E1E1A),
      Color(0xFF5B2A18),
      Color(0xFF84371A),
      Color(0xFFAF4219),
      Color(0xFFDC4C14),
      Color(0xFFF66E3A),
    ],
    lightRamp: <Color>[
      Color(0xFFEFEDE6),
      Color(0xFFE2C1B9),
      Color(0xFFD69B8B),
      Color(0xFFCE745C),
      Color(0xFFC14E30),
      Color(0xFF9F3B20),
    ],
  );

  const LampAccent({
    required this.id,
    required this.label,
    required this.note,
    required this.dark,
    required this.light,
    required this.darkRamp,
    required this.lightRamp,
  });

  /// Stored in preferences. Permanent — see the same note on `WritingFace.id`.
  final String id;
  final String label;
  final String note;

  final Color dark;
  final Color light;
  final List<Color> darkRamp;
  final List<Color> lightRamp;

  static LampAccent fromId(String? id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return LampAccent.amber;
  }
}

/// What the page itself is made of.
///
/// WHY NOT A WALLPAPER
///
/// WhatsApp's chat wallpaper works because a bubble needs something to sit
/// *on*. Lamplight's entries deliberately sit **on the page** rather than in
/// bubbles, so a busy image behind them would fight the words for the same
/// space and lose — and losing, here, means somebody's own writing becomes
/// harder to read.
///
/// So the surface is the page, and there are three of them.
enum PageSurface {
  /// Flat colour. What the app has always been.
  plain(
    id: 'plain',
    label: 'Plain',
    note: 'A flat page.',
  ),

  /// A grain, drawn rather than loaded.
  ///
  /// **Raised until you can actually see it.** The first version was tuned to
  /// be below the threshold of notice, on the theory that the best texture is
  /// one you only miss when it is gone. Reported as "there is no difference
  /// between paper and plain", which settles it: a setting nobody can see the
  /// effect of is not a setting, it is a placebo with a radio button.
  ///
  /// It is still a texture rather than a pattern — no visible tiling, no
  /// repeating motif, nothing that competes with the writing. It just now
  /// reads as a surface at arm's length instead of only under scrutiny.
  paper(
    id: 'paper',
    label: 'Paper',
    note: 'A soft grain, so the page reads as a surface. The default.',
  ),

  /// Paper, with a lamp actually on.
  ///
  /// ── WHAT THIS USED TO BE, AND WHY IT WAS WRONG ──────────────────────
  ///
  /// It shifted the canvas by a few points of lightness across the day and
  /// called that "follows the time of day". The reasoning was that the best
  /// version of an effect like this is one you never consciously notice.
  ///
  /// That reasoning is right about *grain* and wrong about this. Reported as
  /// "you wrote follows the time of the day — does it? it feels weird", and
  /// both halves are fair: it was too small to see, so the label was a claim
  /// the screen could not back up; and the little it did do read as the
  /// screen being slightly off rather than as anything intentional. An
  /// invisible effect with a visible name is worse than no effect, because
  /// now the app has said something untrue about itself.
  ///
  /// So it is a lamp now — a warm pool of light falling from above the page,
  /// which you can see, which matches the app's own name and mark, and which
  /// is the one signature moment  allows. The clock is not
  /// involved.
  lamplit(
    id: 'lamplit',
    label: 'Lamplit',
    note: 'Paper, with the lamp on.',
  ),

  /// ── CRUMPLED WAS HERE, AND IT IS GONE. ROUND FIFTEEN, ISSUE 1 ──────────
  ///
  /// > *"REMOVE CRUMPLED OPTION"*
  ///
  /// He asked for it in round eight, judged three separate versions of it —
  /// facets, drawn creases, a shaded height field — overruled `CLAUDE.md` on
  /// 28 August to get the height field back, and has now decided against the
  /// whole thing. That is his call and it is the fourth time he has looked at
  /// it, so there is nothing left to argue.
  ///
  /// **What was deleted with it, so nobody goes looking:** `_paintCrumple`,
  /// the two 768 × 1536 sheets it cached, the ridged fractal noise that
  /// generated them, `crumple_test.dart`, and the two `surfaceCrumpled`
  /// strings in all ten languages. About 250 lines and, on the device, **nine
  /// megabytes of GPU texture** that were allocated the moment anybody chose
  /// it — which matters more than it sounds, because round fifteen's ISSUE 4
  /// is the app being killed for memory.
  ///
  /// [fromId] already returns [paper] for an id it does not know, so a vault
  /// that has `"crumpled"` in its settings opens on Paper — the nearest
  /// surviving neighbour, and the one Crumpled was described as a variation
  /// of. There is a test.

  /// A night sky, drawn, that turns with the clock. **ISSUE 7C — and he asked
  /// for it twice inside one document.**
  ///
  /// *"THE MOST IMPORTANT FEATURE! I NEED THIS AT ANY WAY POSSIBLE! A STAR MAP
  /// — ORIGINAL ONE WHICH CHANGES EVERYTIME — BUT WHICH IS SUBTLE AND LOOKS
  /// LIKE A STAR MAP NOT JUST DOTS! … IT SHOULD LOOK LIKE SOMEONE IS STAR
  /// GAZING!"* And, in red across the middle of the screenshot, **"STAR MAP AS
  /// A BACKGROUND"**.
  ///
  /// It lives here with the other four because ISSUE 7 is headed
  /// **APPEARANCES**, and because this is where he asked for Crumpled to go a
  /// round ago. It is a surface, not a mode: a ruling still applies over it,
  /// the theme still decides the ink, and nothing routes through it.
  ///
  /// **The note is a promise the screen keeps.** There is one sky, and the page
  /// is a window onto it that turns at the real sidereal rate — 15.04 degrees
  /// an hour, so it is somewhere else every time you open it and back where it
  /// started roughly a day later. `star_map.dart` is the whole argument,
  /// including why a *new random* sky every launch was the wrong answer to
  /// "changes everytime".
  ///
  /// On a light theme it is the same sky in ink on paper, which is what a
  /// celestial chart has always been.
  starMap(
    id: 'starmap',
    label: 'Star map',
    note: 'One sky, turning with the clock. Never the same twice in a day.',
  );

  const PageSurface({required this.id, required this.label, required this.note});

  final String id;
  final String label;
  final String note;

  /// Whether the page carries a fibre texture over the top of everything.
  ///
  /// The star map does **not**. Paper grain over a night sky reads as a dirty
  /// screen rather than as atmosphere, and it is the one surface here that is
  /// not made of paper. **ISSUE 7C.**
  bool get hasGrain =>
      this != PageSurface.plain && this != PageSurface.starMap;

  /// Whether a warm pool of light falls across the top of the page.
  bool get isLit => this == PageSurface.lamplit;

  /// Whether the page is a sky. **ISSUE 7C.**
  bool get isStarMap => this == PageSurface.starMap;

  /// Whether this surface draws marks at the scale of type. **ISSUE 9.**
  ///
  /// The star map does: constellation lines are strokes 0.6–1 point wide at
  /// 34% ink on the light page, and body type at 17pt has stems about the same
  /// width. Two families of marks at the same scale and the same colour is
  /// what he photographed and wrote *"can you understand"* beside — and it is
  /// a frequency problem rather than a contrast one, so no colour change fixes
  /// it. The type carries a halo on these surfaces; see `pageHalo` in
  /// `tokens.dart` for the whole argument.
  ///
  /// Nothing else here qualifies. The grain is sub-pixel, the lamp is a
  /// screen-wide gradient, and Plain draws nothing. **The ruling deliberately
  /// does not count**: it is drawn at 4.5% ink, it is one repeated direction
  /// rather than a scatter, and it is the one mark on the page the user chose
  /// on purpose.
  bool get marksThePage => this == PageSurface.starMap;

  static PageSurface fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return PageSurface.paper;
  }
}

/// What is printed on the page, as opposed to what the page is made of.
///
/// ══ ISSUE 6 — AND WHY THE TYPED INSTRUCTION IS NOT THE WHOLE ONE ═════════
///
/// The typed line was *"CHAT BACKGROUND — LINES?? SERIOUSLY! REMOVE THOSE LINES
/// BACKGROUND!"*. In his own handwriting on the same page, beside the same
/// screenshot, is the rest of it:
///
/// > *"You have added Lines. Why don't you give the user choices in this too:
/// > Lines → already there · Isometric grid · triangle · dot grid"* — and, with
/// > an arrow to the screen, *"can be changed from Appearances"*.
///
/// So the answer is not to delete the ruling. It is that **the ruling was never
/// his to be given without asking** — round five chose lines on his behalf,
/// printed them on every page, and offered no way out. The complaint is one
/// about consent as much as about lines, which is why the fix is a setting and
/// why the default is now nothing at all.
///
/// **[none] is the default**, and that is the "REMOVE THOSE LINES" half honoured
/// literally: a fresh install, and his existing install the moment this ships,
/// has a clean page. Lines are one tap away for anybody who wants them.
///
/// Every ruling is spaced off the *writing* line height rather than a fixed
/// number of pixels, so the pattern grows with the text-size setting. A ruled
/// page whose rules do not match the text sitting on them is the uncanny half
/// of skeuomorphism.
enum PageRuling {
  /// Nothing printed. The default, and the literal reading of "remove those
  /// lines".
  none(id: 'none', label: 'None', note: 'Nothing printed on the page.'),

  /// Horizontal rules, as round five drew them.
  lines(
    id: 'lines',
    label: 'Lines',
    note: 'Ruled like a notebook.',
  ),

  /// Verticals plus two diagonals at thirty degrees — drafting paper.
  isometric(
    id: 'isometric',
    label: 'Isometric',
    note: 'Drafting paper, for thinking in three dimensions.',
  ),

  /// Three sets of lines at sixty degrees to each other.
  triangle(
    id: 'triangle',
    label: 'Triangle',
    note: 'A field of equilateral triangles.',
  ),

  /// A dot at every crossing, and nothing between them.
  ///
  /// The quietest of the four, and the one most likely to survive a long
  /// session: a dot marks the rhythm without drawing a line through anything.
  dots(
    id: 'dots',
    label: 'Dot grid',
    note: 'A dot at each crossing. The quietest of the four.',
  );

  const PageRuling({required this.id, required this.label, required this.note});

  final String id;
  final String label;
  final String note;

  static PageRuling fromId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    // Nothing, for anybody who has never chosen — including everybody upgrading
    // from the build he photographed, which is the point.
    return PageRuling.none;
  }
}
