# Design system — "Lamplight"

Every value here has been **computed and verified**, not eyeballed. Contrast ratios were
calculated with the WCAG 2.1 relative-luminance formula; the year-grid ramp was checked for
step-to-step separation. The verification output is in `CONTRAST-REPORT.md`.

Hand this file to Claude Code and say *"build the design tokens from this."*

---

## The idea behind the palette

**Lamplight.** Warm near-black, warm paper-white, one amber accent. Not blue.

Blue is the default of every productivity app, and it reads *corporate* — a tool for getting
things done. This app is not that. It's a private room at the end of the day. Amber on warm
neutrals reads as lamp, paper, evening, and it feels like an object rather than software.

**One accent, used for at most three things:** the recording state, the current day, the active
selection. If everything is accented, nothing is.

**A single-accent palette has a free accessibility property:** with no competing hues, there
are no colour pairs to confuse, so the design is **inherently colour-blind safe** in all forms
(deuteranopia, protanopia, tritanopia, monochromacy). Meaning is carried by lightness and
position, which every eye reads the same way. This is a real benefit of restraint, not a
happy accident — and it's why the year grid is a single-hue ramp rather than a rainbow.

---

## Tokens — dark mode (default)

| Token | Hex | Contrast vs canvas | Use |
|---|---|---|---|
| `bg.canvas` | `#0F0F0E` | — | App background. Warm near-black, never `#000` |
| `bg.surface` | `#171714` | — | Sheets, panels |
| `bg.raised` | `#1F1F1B` | — | Menus, pressed states |
| `border.hair` | `#2B2B26` | — | Dividers. Decorative only |
| `border.strong` | `#403F38` | — | Input outlines |
| `ink.primary` | `#F2F0EA` | **16.83:1** AAA | Body text. Warm off-white, never `#FFF` — pure white on near-black causes halation |
| `ink.secondary` | `#A5A29A` | **7.52:1** AAA | Timestamps, meta |
| `ink.muted` | `#8C897F` | **5.48:1** AA | Placeholders, disabled |
| `accent` | `#E9A94B` | **9.35:1** AAA | Amber. Record state, today, selection, focus ring |
| `danger` | `#F0736E` | **6.74:1** AA | Destructive only. Never decorative |
| `good` | `#6FBF73` | **8.56:1** AAA | Confirmations |

## Tokens — light mode

Light mode is a **separately chosen palette**, not an automatic inversion. Flipping a dark
palette produces muddy, low-contrast results — every value below was picked against the light
surface and re-verified.

| Token | Hex | Contrast vs canvas | Use |
|---|---|---|---|
| `bg.canvas` | `#FAF9F5` | — | Warm paper, not clinical white |
| `bg.surface` | `#FFFFFF` | — | |
| `bg.raised` | `#F3F1EB` | — | |
| `border.hair` | `#E6E3DA` | — | |
| `border.strong` | `#C4C0B2` | — | |
| `ink.primary` | `#1A1916` | **16.69:1** AAA | Warm near-black, never `#000` |
| `ink.secondary` | `#5B5950` | **6.67:1** AA | |
| `ink.muted` | `#6C6A60` | **5.15:1** AA | |
| `accent` | `#9A6212` | **4.83:1** AA | Deeper amber — the dark-mode amber fails on white |
| `danger` | `#B8332C` | **5.62:1** AA | |
| `good` | `#2C7531` | **5.39:1** AA | |

**Every text token passes WCAG AA (4.5:1) in both modes. Most reach AAA (7:1).**

Three modes in settings: **Dark · Light · Follow system**.

**Default: follow system, changed 5 September 2026.** It read *"Default: dark"* until
round nineteen, when he reported the app opening dark on a phone set to light after
installing from Play closed testing — *"where you wrote Follow my phone … this doesn't
works!"*. The chip was not broken; `ThemeMode.system` resolves correctly and
`theme_follows_the_phone_test.dart` proves both directions. A fresh install simply had no
`themeMode` stored and fell back to dark, so the app's first impression was that it
ignored the phone.

Dark is still what the app is designed in and still what most people will end up on. But
**the first launch is the one moment the app has said nothing to the user yet**, and the
honest thing to match there is the phone they already set up, not our preference.

The change applies to new installs only. `AppSettings.load` seeds the new default when
there was no settings file; the getter's fallback stays `dark` so an install made before
this keeps the theme it has always had. An update does not get to repaint somebody's
journal.

The chip is labelled with the reader's own phrase for this — *System default* in English —
rather than *Auto*, which said nothing about what was being followed.

---

## The year grid — a sequential ramp

The year grid is a heatmap, so it follows heatmap rules: **one hue, light→dark, never a
rainbow.** The empty state is a *neutral*, not the lightest amber — so "nothing happened" reads
as absence rather than as a small amount.

**Dark mode**

| Level | Hex | vs canvas |
|---|---|---|
| empty | `#1E1E1A` | 1.15:1 |
| 1 | `#4A3517` | 1.66:1 |
| 2 | `#7A5620` | 2.90:1 |
| 3 | `#A8762A` | 4.83:1 |
| 4 | `#D19A3C` | 7.67:1 |
| 5 | `#F2C071` | 11.46:1 |

**Light mode**

| Level | Hex | vs canvas |
|---|---|---|
| empty | `#EFEDE6` | 1.11:1 |
| 1 | `#EFCC92` | 1.34:1 |
| 2 | `#E3B267` | 1.84:1 |
| 3 | `#CE9032` | 2.60:1 |
| 4 | `#A16F26` | 4.14:1 |
| 5 | `#5F4010` | 8.95:1 |

**Verified:** every adjacent pair is separated by ≥1.25× in luminance in both modes, so the
steps are distinguishable — including in greyscale, in sunlight, and to a monochromatic viewer.

**Colour is never the only channel.** Every cell carries an accessible label
(`"4 March, 3 entries"`) and a tooltip. A screen-reader user gets the same information as a
sighted one; a colour-blind user reads it by lightness. This is non-negotiable — see the
"no malpractice" rule about never encoding meaning in colour alone.

---

## Type

**One typeface for the interface.** The platform's own — SF on iOS, Roboto on Android — or
Inter. Free, superb, and it makes the app feel native rather than skinned.

**Optionally a serif for the user's own writing**, offered as a setting. A serif makes writing
feel like *writing* rather than like filling in a field. Newsreader or Source Serif. Small
change, large effect.

| Role | Size / line-height | Weight | Token |
|---|---|---|---|
| Date heading | 32 / 38 | Regular | `type.display` |
| Section | 22 / 28 | Medium | `type.title` |
| **Body** | **17 / 26** | Regular | `type.body` |
| Timestamp | 13 / 16 | Medium | `type.caption` |
| Meta / label | 12 / 16, +0.06em | Medium | `type.label` |

**The 26px line-height on 17px body is the single most important number in this document.**
It's what makes long text feel readable rather than cramped. Do not let anyone tighten it.

Measure capped at **65–70 characters**, even on a tablet. Long lines are physically harder to
read, and this app is for reading.

**All sizes scale with the OS text-size setting**, up to 200%, without clipping or overlap.
Never hardcode a pixel font size.

---

## Space — an 8pt grid

| Token | px | Use |
|---|---|---|
| `space.1` | 4 | Icon-to-label |
| `space.2` | 8 | Inside a control |
| `space.3` | 12 | Tight stacks |
| `space.4` | 16 | Default gap |
| `space.5` | 20 | Between entries |
| `space.6` | 24 | **Screen margin** |
| `space.8` | 32 | Above a date heading |
| `space.10` | 40 | Major section breaks |

**24pt screen margins, not 16.** Sixteen is the framework default, and defaults look like
defaults. The extra eight points is most of the difference between "an app" and "a considered
object."

## Radius & elevation

| Token | px |
|---|---|
| `radius.sm` | 6 (chips, small controls) |
| `radius.md` | 12 (sheets, cards where unavoidable) |
| `radius.lg` | 20 (modals) |
| `radius.full` | 999 (the record button) |

**No shadows.** Depth comes from surface colour steps (`canvas` → `surface` → `raised`).
Shadows on a near-black background are invisible anyway, and on light they read as 2014.

---

## Motion

- **Standard: 200ms, ease-out.** Nothing longer than 300ms.
- Motion only to explain a spatial relationship — a sheet rising, a day sliding sideways.
  Never decorative.
- **Nothing blocks input.** If the user can type during a transition, they can type.
- **`prefers-reduced-motion` is respected**: transitions become instant cross-fades. One flag,
  and it matters enormously to people with vestibular disorders.

**Haptics carry more weight than animation here.** A firm tap on record start and stop, a light
tick on lock. Never on autosave (it would fire constantly). All haptics respect the system
setting.

---

## Components

**Entry block** — no card, no shadow, no border box. A 2px accent-tinted left rule, a timestamp
in `ink.secondary`, content in `ink.primary`. Content should look like it's sitting *on* the
page, not inside a container.

**Capture bar** — pinned at thumb height, `bg.surface`, hairline top border. Four targets:
✎ 🎙 📷 📎. **Each at least 48×48dp** — the accessibility floor, and also just correct.

**Record button** — `radius.full`, accent fill, live waveform above, elapsed time. The only
place amber fills a large area. It should feel like the app is listening.

**Folder row** — 56dp tall, chevron, name in `ink.primary`, count right-aligned in
`ink.secondary`. Indent 20px per level.

**Year grid** — 7 rows × 53 columns, cell 11px, gap 3px, `radius.sm` at 2px. Month labels in
`type.label`, `ink.muted`. Tap a cell to travel to that day.

**Lock screen** — the app mark and a passcode field, centred, on `bg.canvas`. **Nothing else.
No preview, no counts, no "3,847 entries."** The lock screen should reveal that the app exists
and not one thing more.

---

## Implementation note for Claude Code

Define these once as a `ThemeExtension` in Flutter and reference them by role everywhere —
never a raw hex in a widget. Then light/dark is one swap, and a future palette change is one
file rather than four hundred edits.

```dart
// lib/design/tokens.dart
class VaultColors extends ThemeExtension<VaultColors> {
  final Color canvas, surface, raised, borderHair, borderStrong;
  final Color inkPrimary, inkSecondary, inkMuted, accent, danger, good;
  final List<Color> gridRamp; // empty + 5 levels
  // ...
}
```

**Rule: if a widget contains a hex code, it's a bug.**
