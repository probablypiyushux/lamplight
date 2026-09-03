# Design language

You said: **"Aesthetic too! Minimal as fuck!"** Here is what that means concretely enough to
build, plus the reasoning, so you can tell good minimal from empty minimal.

---

## The principle

**Minimal is not "fewer pixels." Minimal is "nothing on screen that isn't the user's own
content."** Every chrome element you remove makes their words louder. That's the actual goal:
the app should feel like paper, not like software.

Test for every element: *if I delete this, does the user lose anything?* If the answer is
"it looks a bit empty" — delete it.

---

## Colour

Dark by default. Not black-black — true `#000000` looks harsh on LCD and causes smearing on
OLED scroll.

```
Background        #0D0D0F   near-black, faint blue cast
Surface           #16161A   cards, sheets
Border            #232329   1px, barely there
Text primary      #EDEDF0   never pure white
Text secondary    #8A8A94
Accent            ONE colour, used sparingly
Danger            #E5484D   destructive only, never decorative
```

Light mode is a real mode, not an afterthought — people journal in daylight. Warm off-white
(`#FAFAF8`), not clinical white.

**One accent colour, used for at most three things:** the record state, the current day, the
active selection. If everything is accented, nothing is.

Candidate accents: a deep amber (`#E0A458` — warm, lamplight, private) or a muted sage
(`#7C9885` — calm, notebook). Both are quieter than the default tech-blue and read as
*personal* rather than *productive*. Avoid blue: it reads corporate, and this is not a
corporate object.

---

## Type

**One typeface. Two if you must.**

- Body: **Inter** — or better, the platform's own (SF on iOS, Roboto on Android). Free, superb.
- Optional for the user's own writing: a serif (**Newsreader**, **Source Serif**) as a setting.
  This is a small thing with a large effect — a serif makes writing feel like writing rather
  than like filling in a field. Worth offering as a preference.

```
Date heading   32/38  Regular   ← generous. The date is the title of the day.
Body           17/26  Regular   ← 26 line-height is the whole game. Do not tighten it.
Time stamp     13/16  Medium    ← secondary colour
Meta           12/16  Medium    ← uppercase, letter-spaced, rare
```

Line length capped around 65–70 characters even on a tablet. Long lines are unreadable and
this app is for reading.

---

## Space

Space is the design. An 8pt grid, and be generous:

- 24pt screen margins (not 16 — 16 is the default and defaults look like defaults)
- 20pt between entries
- 32pt above a date heading
- Content is never wider than it is comfortable to read

---

## Motion

- 200ms, standard ease. Nothing longer.
- **Motion only to explain a spatial relationship** — a sheet rising, a day sliding sideways.
  Never as decoration.
- Nothing that blocks input. If the user can type during an animation, they can type.
- Haptics carry more than animation here: a firm tap on record start and stop, a light tick on
  autosave (optional, off by default), a soft thud on lock.

---

## The specific screens

**The day** — date at top, generous. Entries as a plain stream. **No cards, no shadows, no
boxes.** A thin left rule and a timestamp is all the structure needed. Content should look
like it's sitting on the page, not inside a container.

**The year grid** — 365 cells, one per day, intensity by how much you wrote. Yes, it's the
GitHub contributions graph, and no, that's not a problem: it's the most legible visualisation
of "a year of a habit" anyone has made. Make it beautiful — accent-tinted, not green, with
gentle rounding, tappable, and the month labels quiet. This screen is the emotional payoff of
the whole app. Someone opening it in year three should feel something.

**The explorer** — a plain tree. Folder icons subtle and monochrome except for the user's own
colour choices. Counts right-aligned in secondary text. Familiar shape, stripped of chrome.

**The recorder** — full-bleed. Live waveform, elapsed time, one big stop button. Nothing else
on screen. This screen should feel like the app is listening.

**The lock screen** — the app mark and a passcode field, centred, on the background colour.
Nothing else at all.

---

## Things we are not doing

- ❌ Gradients, glassmorphism, neumorphism, glow
- ❌ Illustrations, mascots, empty-state cartoons
- ❌ Streaks, badges, gamification, guilt mechanics — this is a private record, not a habit app
- ❌ A bottom bar with five tabs (we need two, maybe three)
- ❌ Onboarding carousels
- ❌ Confetti. Ever.
- ❌ Emoji in the UI chrome (the user may use them freely in their own writing)

---

## The reference points

- **Signal** — security invisible until it matters. Note that Signal does *not* cover the UI
  in lock icons. The safety is in the architecture; the interface is just calm. Copy that
  restraint, not the lock icons.
- **iA Writer** — reverence for the user's text. Everything else disappears.
- **Things 3** — how much personality lives in spacing and motion timing alone.
- **Bear** — proof that a notes app can be beautiful and still be fast.

## One line to hold the whole thing to

> **If it doesn't help someone record their life, it shouldn't be on the screen.**
