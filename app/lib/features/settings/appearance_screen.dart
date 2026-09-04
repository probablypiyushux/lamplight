import 'package:flutter/material.dart';
import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';

import 'design_names.dart';
import 'package:flutter/services.dart';

import '../../core/settings/app_settings.dart';
import '../../design/paper.dart';
import '../../design/tokens.dart';

/// How the app looks, with the app looking like it while you decide.
///
/// ── WHAT WAS WRONG WITH THE LAST ONE ─────────────────────────────────────
///
/// Called, accurately, a blunder. It was a settings *list* wearing a design
/// screen's job: theme behind a sheet, text size behind another sheet, then a
/// vertical run of fourteen font rows, then swatches, then three radio buttons.
/// Four different interaction models stacked on one page, nothing showing you
/// what any of it would do, and the two things people change most — the font
/// and its size — as far apart as they could be.
///
/// The rule it broke is the oldest one in interface design: **for a choice
/// about appearance, the preview is the control.** You do not read that
/// Cormorant is "sophisticated" and then commit. You look at it.
///
/// ── HOW IT IS BUILT NOW ──────────────────────────────────────────────────
///
/// One live specimen pinned at the top, set in the exact face, size, colour and
/// page you currently have, updating as you touch anything. Under it, four
/// controls in the order people actually reach for them:
///
///   1. **Theme** — three tiles you can see, not a sheet you have to open.
///   2. **Font** — a horizontal rail of specimens. Horizontal because fourteen
///      vertical rows is a scroll away from the preview, and the whole point is
///      that you can see the preview change as you move along the rail.
///   3. **Size** — a slider, 0.8 to 1.6. Not four named steps; see the note on
///      `AppSettings.textScale` for why named steps stopped working the moment
///      there was more than one typeface.
///   4. **Page and colour** — the two smallest decisions, last.
///
/// Nothing here opens a modal. A modal covers the thing you are changing,
/// which on this screen is the entire screen.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final c = context.lamplight;
        return Scaffold(
          backgroundColor: c.canvas,
          body: PaperGround(
            surface: settings.pageSurface,
            ruling: settings.pageRuling,
            child: SafeArea(
              child: Column(
                children: [
                  _Bar(title: L.of(context).appearanceTitle),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: Space.x10),
                      children: [
                        _Specimen(settings: settings),
                        _ThemeRow(settings: settings),
                        _FontRail(settings: settings),
                        _SizeSlider(settings: settings),
                        _AccentRow(settings: settings),
                        _PageRow(settings: settings),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      // On the app's grid, like every other row of icon buttons. ISSUE 1.
      padding: const EdgeInsets.fromLTRB(
          Layout.iconInset, Space.x2, Layout.gutter, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            color: c.inkPrimary,
            tooltip: L.of(context).searchBack,
          ),
          const SizedBox(width: Space.x1),
          // Expanded, or the word "Appearance" at 200% text is wider than the
          // room left beside a 48-point back button and runs off the edge of
          // every phone in the suite. Found the day this screen was first
          // built at a size — it had never been in the responsive suite.
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// The page, as it will be, above everything that changes it.
///
/// A real paragraph rather than "Aa" or the alphabet. A typeface is a rhythm
/// and a rhythm only appears in a sentence — two letters tell you about two
/// letters. The words are deliberately ordinary and slightly personal, because
/// that is what will actually be set in this face for the next ten years.
class _Specimen extends StatelessWidget {
  const _Specimen({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final face = settings.writingFace;
    final scale = settings.textScale;

    TextStyle at(TextStyle base) {
      final applied = face.apply(base);
      return applied.copyWith(fontSize: (applied.fontSize ?? 17) * scale);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x6, Space.x4, Space.x6, Space.x2),
      child: AnimatedContainer(
        duration: Motion.duration(context),
        curve: Motion.curve,
        padding: const EdgeInsets.all(Space.x5),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.borderHair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 2,
                  height: 18,
                  margin: const EdgeInsets.only(right: Space.x3),
                  color: c.accent.withValues(alpha: 0.45),
                ),
                // Flexible, because the specimen is set in the *user's*
                // face at the *user's* size: Caveat at 160% is nearly twice
                // the width of IBM Plex at 100%, and a plain Text in a Row
                // demands its full natural width and runs off the edge. Found
                // by the widget suite the day the Appearance screen was first
                // pumped at a phone width, which is also the day this screen
                // joined the responsive suite.
                Flexible(
                  child: Text(
                    // A real date through `LampDates`, so the specimen is
                    // set the way this reader's dates actually look.
                    LampDates.dayAndMonth(context, DateTime(2026, 8, 20)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: at(t.displaySmall!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            Text(
              L.of(context).appearanceSample,
              style: at(t.bodyLarge!).copyWith(color: c.inkPrimary),
            ),
            const SizedBox(height: Space.x3),
            Row(
              children: [
                Text('21:04', style: t.labelMedium),
                const SizedBox(width: Space.x3),
                Flexible(
                  child: Text(
                    // The one thing the specimen has to say in words, because
                    // it is the one thing the specimen cannot show: this
                    // setting does not touch the controls.
                    L.of(context).appearanceChromeNote,
                    style: t.labelSmall?.copyWith(color: c.inkMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading. Small, letter-spaced, outside the control it names.
class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});

  final String text;

  /// The current value of whatever this heading names, at the right.
  ///
  /// **A string rather than a Widget, on purpose.** It used to take any widget
  /// and drop it at the end of a Row with a `Spacer` in front, so a long note
  /// like "Warm, readable, made for long-form" demanded its full natural width
  /// and pushed the row off the edge of a 320-point phone. Narrowing the type
  /// is what makes that impossible rather than unlikely: there is one text
  /// style, one alignment and one flex share, decided here.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x6, Space.x6, Space.x6, Space.x3),
      child: Row(
        children: [
          // The same 3:2 split as a settings row, for the same reason: two
          // tight shares cannot overflow at any text size, and the value ends
          // on the right-hand rule instead of wherever its own width happens
          // to put it. See the long note on `Expanded` in `LampTile`.
          Expanded(
            flex: 3,
            child: Text(text.toUpperCase(),
                style: t.labelSmall?.copyWith(color: c.inkMuted)),
          ),
          if (trailing != null)
            Expanded(
              flex: 2,
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                style: t.labelSmall?.copyWith(color: c.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Three tiles you can see, instead of a sheet you have to open.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.settings});

  final AppSettings settings;

  /// The three chips, named in the reader's language.
  ///
  /// A method rather than the `static const` list this used to be: the labels
  /// come from `L.of(context)` now, and a const list cannot hold them. The
  /// order and the icons are unchanged, and `_options` is still read twice —
  /// once to build the row and once for `.first`, to decide which chip gets no
  /// leading gap — so it is built once per frame and passed around rather than
  /// called twice.
  static List<(ThemeMode, String, IconData)> _optionsFor(L l) => [
        (ThemeMode.dark, l.appearanceThemeDark, Icons.dark_mode_outlined),
        (ThemeMode.light, l.appearanceThemeLight, Icons.light_mode_outlined),
        (ThemeMode.system, l.appearanceThemeAuto, Icons.brightness_auto_outlined),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final options = _optionsFor(L.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(L.of(context).appearanceTheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x6),
          child: Row(
            children: [
              for (final (mode, label, icon) in options) ...[
                if (mode != options.first.$1) const SizedBox(width: Space.x3),
                Expanded(
                  child: _Choice(
                    selected: settings.themeMode == mode,
                    label: label,
                    onTap: () {
                      settings.themeMode = mode;
                      HapticFeedback.selectionClick();
                    },
                    child: Icon(icon,
                        size: 22,
                        color: settings.themeMode == mode
                            ? c.accent
                            : c.inkSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (settings.themeMode == ThemeMode.system)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.x6, Space.x3, Space.x6, 0),
            child: Text(
              L.of(context).appearanceThemeAutoNote,
              style: t.labelMedium?.copyWith(color: c.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// A tile that is selected or not. One shape, used by theme and page.
///
/// Selection is a **fill, a ring and a tick** — three channels. `ACCESSIBILITY`
/// forbids colour being the only one, and on this screen in particular the
/// accent itself is one of the things being changed, so a selection state that
/// depended on it would be at its least visible exactly when somebody is
/// choosing a subtle accent.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: AnimatedContainer(
          duration: Motion.duration(context),
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(vertical: Space.x3),
          decoration: BoxDecoration(
            color: selected ? c.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: selected ? c.accent : c.borderHair,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 26, child: Center(child: child)),
              const SizedBox(height: Space.x2),
              // ── Two lines, centred. **Round 19.** ────────────────────
              //
              // "Auto" became "System default", which is two words in English
              // and one long one in German — `Systemstandard` does not fit a
              // third of a 360-point row on one line, and at 160% text nor
              // does anything else here. Wrapping is the correct answer and
              // was already the behaviour; what was missing was the centring
              // that makes a wrapped chip look deliberate, and a ceiling so a
              // translation nobody has measured cannot grow the row without
              // limit. Never measured in characters — ten scripts.
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.labelMedium?.copyWith(
                  color: selected ? c.inkPrimary : c.inkSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fourteen faces as a horizontal rail of specimens.
///
/// Horizontal because the preview is at the top of the screen and a vertical
/// list of fourteen rows pushes it out of sight — which defeats the only thing
/// this screen is for. Sideways, the specimen you are choosing and the page it
/// will produce are visible at the same time.
///
/// Each card is set **in its own face**, so the rail is a type specimen book
/// rather than a list of names. The name is underneath as the second channel
/// and for screen readers.
class _FontRail extends StatefulWidget {
  const _FontRail({required this.settings});

  final AppSettings settings;

  @override
  State<_FontRail> createState() => _FontRailState();
}

class _FontRailState extends State<_FontRail> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Open with the current face in view. Landing on "System" when you are
    // eleven faces along means scrolling to find where you already are.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final index = WritingFace.values.indexOf(widget.settings.writingFace);
      final target = (index * 132.0 - 60).clamp(
          0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final current = widget.settings.writingFace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(L.of(context).appearanceFont,
            trailing: current.noteIn(L.of(context))),
        SizedBox(
          height: 108,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.x6),
            itemCount: WritingFace.values.length,
            itemBuilder: (context, i) {
              final face = WritingFace.values[i];
              final on = face == current;
              return Padding(
                padding: const EdgeInsets.only(right: Space.x3),
                child: Semantics(
                  button: true,
                  selected: on,
                  label: '${face.labelIn(L.of(context))}. '
                      '${face.noteIn(L.of(context))}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () {
                      widget.settings.writingFace = face;
                      HapticFeedback.selectionClick();
                    },
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: AnimatedContainer(
                      duration: Motion.duration(context),
                      curve: Motion.curve,
                      width: 120,
                      padding: const EdgeInsets.all(Space.x3),
                      decoration: BoxDecoration(
                        color: on ? c.raised : c.surface,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: on ? c.accent : c.borderHair,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // The specimen. Two lines of real letters, at a size
                          // where the shapes are actually distinguishable.
                          Expanded(
                            child: Text(
                              L.of(context).appearanceAaQuiet,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: face.apply(
                                t.titleLarge!.copyWith(
                                  color: on ? c.inkPrimary : c.inkSecondary,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (on) ...[
                                Icon(Icons.check, size: 13, color: c.accent),
                                const SizedBox(width: 3),
                              ],
                              Expanded(
                                child: Text(
                                  face.labelIn(L.of(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelSmall?.copyWith(
                                    color: on ? c.accent : c.inkMuted,
                                    fontWeight:
                                        on ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Size, as a dial rather than four presets.
class _SizeSlider extends StatelessWidget {
  const _SizeSlider({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final value = settings.textScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(
          L.of(context).appearanceSize,
          // A percentage, because it is the only honest label. "Larger" told
          // you nothing about how much larger, and with a slider you can see
          // where you are.
          trailing: '${(value * 100).round()}%',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x5),
          child: Row(
            children: [
              // The two ends labelled in the thing being changed, so the
              // direction of the slider needs no explaining.
              Text('A', style: t.labelMedium?.copyWith(color: c.inkMuted)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: c.accent,
                    inactiveTrackColor: c.raised,
                    thumbColor: c.accent,
                    overlayColor: c.accent.withValues(alpha: 0.14),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 9),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                    // ── The bubble is its own ground. **Round 19.** ────────
                    //
                    // He photographed "85%" glowing. The value indicator takes
                    // its text style from the theme, and on Star Map the theme
                    // carries `pageHalo` — a wash of the *canvas* colour round
                    // every glyph. On the page that is a knockout; on an
                    // accent-filled bubble it is a near-black smear round dark
                    // letters, which is what he saw. Stated, not stripped by a
                    // wrapper, because the indicator is painted by the slider's
                    // own overlay layer and never sees an `OffThePage` above it.
                    valueIndicatorColor: c.accent,
                    valueIndicatorTextStyle: t.labelMedium?.copyWith(
                      color: c.canvas,
                      fontWeight: FontWeight.w600,
                      shadows: const <Shadow>[],
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: AppSettings.minTextScale,
                    max: AppSettings.maxTextScale,
                    // Eighteen stops, five percent apart — 75, 80, 85 … 160.
                    // **ISSUE 3.** Derived from the step rather than written
                    // down, because a hard-coded count is what put 86, 91 and
                    // 102 on this slider: the floor moved and the count did
                    // not. See AppSettings.textScaleStep.
                    divisions: AppSettings.textScaleDivisions,
                    label: '${(value * 100).round()}%',
                    onChanged: (v) => settings.textScale = v,
                    onChangeEnd: (_) => HapticFeedback.selectionClick(),
                  ),
                ),
              ),
              Text('A',
                  style: t.titleLarge?.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.x6, Space.x2, Space.x6, 0),
          child: Text(
            L.of(context).appearanceSizeNote,
            style: t.labelMedium?.copyWith(color: c.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = settings.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(L.of(context).appearanceColour,
            trailing: current.labelIn(L.of(context))),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.x6),
            children: [
              for (final accent in LampAccent.values)
                Padding(
                  padding: const EdgeInsets.only(right: Space.x3),
                  child: Semantics(
                    button: true,
                    selected: accent == current,
                    label: accent.labelIn(L.of(context)),
                    excludeSemantics: true,
                    child: Tooltip(
                      message: accent.labelIn(L.of(context)),
                      child: InkWell(
                        onTap: () {
                          settings.accent = accent;
                          HapticFeedback.selectionClick();
                        },
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: Motion.duration(context),
                          curve: Motion.curve,
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dark ? accent.dark : accent.light,
                            // The ring is the selection, in the ink colour
                            // rather than the accent — an accent ring around an
                            // accent circle is invisible.
                            border: accent == current
                                ? Border.all(color: c.inkPrimary, width: 2.5)
                                : null,
                          ),
                          child: accent == current
                              ? Icon(Icons.check, size: 20, color: c.canvas)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    // ── ISSUE 17 — both of these are rails now ─────────────────────────────
    //
    // *"Make these carousel styled like → Theme & Font."* The whole argument,
    // including the one-word layout bug that made the old version look the way
    // it did, is on `_PreviewRail`.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewRail<PageSurface>(
          heading: L.of(context).appearancePage,
          options: PageSurface.values,
          current: settings.pageSurface,
          labelOf: (s) => s.labelIn(L.of(context)),
          noteOf: (s) => s.noteIn(L.of(context)),
          // Each tile is the surface itself, drawn with the ruling that is
          // actually chosen — so the preview is the answer rather than an
          // illustration of it. The star map tile is a real sky at tile size,
          // turning on the same clock as the page behind it.
          previewOf: (s) => PaperGround(
            surface: s,
            ruling: settings.pageRuling,
            child: const SizedBox.expand(),
          ),
          onChosen: (s) => settings.pageSurface = s,
        ),

        // ── ISSUE 6 — the ruling, and who gets to choose it ──────────────
        //
        // "You have added Lines. Why don't you give the user choices in this
        // too: Lines → already there · Isometric grid · triangle · dot grid",
        // with an arrow to the screen reading "can be changed from
        // Appearances". So: here, and all of them.
        _PreviewRail<PageRuling>(
          heading: L.of(context).appearanceRuling,
          options: PageRuling.values,
          current: settings.pageRuling,
          labelOf: (r) => r.labelIn(L.of(context)),
          noteOf: (r) => r.noteIn(L.of(context)),
          previewOf: (r) => PaperGround(
            surface: settings.pageSurface,
            ruling: r,
            child: const SizedBox.expand(),
          ),
          onChosen: (r) => settings.pageRuling = r,
        ),
      ],
    );
  }
}

/// The page and the ruling, as rails of previews. **ROUND NINE, ISSUE 17.**
///
/// ══ WHAT HE ASKED FOR, AND THE BUG UNDERNEATH IT ═══════════════════════════
///
/// Two arrows on the Appearance screenshots. One to the theme row and the font
/// rail: *"look at here — the best ergonomic way to choose an option!"* The
/// other to the page and ruling controls: *"why so odd looking way to choose —
/// and so much bad!"*, and then the instruction: **"make these carousel styled
/// like → Theme & Font."**
///
/// He is describing a real defect rather than a preference, and it took a
/// moment to see. These two controls were already a `Wrap` of small tiles —
/// they were *meant* to sit side by side, four or five across. What actually
/// happened is that every tile came out **full width**, so the `Wrap` put each
/// one on its own line and the result was five stacked bars with a 46-point
/// picture marooned in the middle of each.
///
/// The cause is one word. Each tile's preview was wrapped in a `Center`, and a
/// `Center` given loose constraints — which is what a `Wrap` hands its children
/// — **expands to the widest thing it is allowed to be.** The tile inherited
/// that width, and the `Wrap` had nothing left to fit beside it.
///
/// It is the same family as the two ISSUE 3 faults on the other screenshot from
/// the same page of his document: *a loose fit takes only what it needs, or all
/// there is, and then something else decides where that goes.* Three of them in
/// one round, and this is the third.
///
/// ── SO IT IS A RAIL, WHICH IS WHAT HE ASKED FOR ANYWAY ─────────────────────
///
/// Fixing the width would have given back the four-across `Wrap`. A rail is
/// better and he is right that it is better, for the reason the font rail's own
/// note gives: **the preview at the top of the screen and the thing you are
/// choosing stay visible at the same time.** A `Wrap` of five grows downward
/// and pushes the specimen off the screen; a rail never does, however many
/// surfaces there turn out to be one day.
///
/// One widget for both, rather than two that drift apart — the ruling rail and
/// the page rail differ only in what they list.
class _PreviewRail<T> extends StatefulWidget {
  const _PreviewRail({
    required this.heading,
    required this.options,
    required this.current,
    required this.labelOf,
    required this.noteOf,
    required this.previewOf,
    required this.onChosen,
  });

  final String heading;
  final List<T> options;
  final T current;
  final String Function(T) labelOf;
  final String Function(T) noteOf;

  /// What the page would look like. Drawn at 46 × 32 inside the tile, so the
  /// difference between Plain and Paper — which is the entire question — is
  /// visible in the control rather than described beside it.
  final Widget Function(T) previewOf;

  final ValueChanged<T> onChosen;

  @override
  State<_PreviewRail<T>> createState() => _PreviewRailState<T>();
}

class _PreviewRailState<T> extends State<_PreviewRail<T>> {
  final _scroll = ScrollController();

  static const double _tile = 92;
  static const double _gap = Space.x3;

  @override
  void initState() {
    super.initState();
    // Open with the current one in view, exactly as the font rail does.
    // Landing on "Plain" when you are four along means scrolling to find where
    // you already are.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(jump: true));
  }

  @override
  void didUpdateWidget(covariant _PreviewRail<T> old) {
    super.didUpdateWidget(old);
    // Tapping the last tile in a rail that is scrolled part way should not
    // leave it half off the edge.
    if (old.current != widget.current) _reveal(jump: false);
  }

  void _reveal({required bool jump}) {
    if (!_scroll.hasClients) return;
    final index = widget.options.indexOf(widget.current);
    if (index < 0) return;
    final target = (index * (_tile + _gap) - 60)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (jump) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target,
          duration: Motion.duration(context), curve: Motion.curve);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(widget.heading),
        SizedBox(
          height: 96,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.x6),
            itemCount: widget.options.length,
            itemBuilder: (context, i) {
              final option = widget.options[i];
              final on = option == widget.current;
              return Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: Semantics(
                  button: true,
                  selected: on,
                  label: '${widget.labelOf(option)}. ${widget.noteOf(option)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () {
                      widget.onChosen(option);
                      HapticFeedback.selectionClick();
                    },
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: AnimatedContainer(
                      duration: Motion.duration(context),
                      curve: Motion.curve,
                      // **A fixed width, which is the fix.** Everything in a
                      // rail is the same size, so nothing inside a tile can
                      // decide how wide the tile is.
                      width: _tile,
                      padding: const EdgeInsets.all(Space.x2),
                      decoration: BoxDecoration(
                        color: on ? c.raised : c.surface,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: on ? c.accent : c.borderHair,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: widget.previewOf(option),
                            ),
                          ),
                          const SizedBox(height: Space.x2),
                          Text(
                            widget.labelOf(option),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: t.labelMedium?.copyWith(
                              color: on ? c.inkPrimary : c.inkSecondary,
                              fontWeight:
                                  on ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.x6, Space.x3, Space.x6, Space.x5),
          child: Text(
            widget.noteOf(widget.current),
            style: t.labelMedium?.copyWith(color: c.inkMuted),
          ),
        ),
      ],
    );
  }
}
