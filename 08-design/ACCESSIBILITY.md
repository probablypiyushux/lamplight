# Accessibility

**Target: WCAG 2.2 Level AA, with AAA on text contrast wherever it's free.**

Two reasons this isn't optional. The obvious one: roughly one in six people has a disability,
and an inaccessible app simply excludes them. The less obvious one, which matters for *this*
app specifically: **accessibility work is indistinguishable from quality work.** Bigger touch
targets, higher contrast, clearer labels, respect for the user's own settings — every one of
those makes the app better for everyone, in the dark, one-handed, on a cracked screen, at 2am.

---

## Colour and contrast ✅ verified

- **Every text token passes AA (4.5:1) in both modes; most reach AAA (7:1).** Computed, not
  guessed — full numbers in `CONTRAST-REPORT.md`.
- **Colour is never the only channel.** Every state that uses colour also uses a shape, an
  icon, a position, or a label. Recording is amber *and* a pulsing dot *and* a timer. Today is
  amber *and* bolder *and* labelled "Today".
- **Inherently colour-blind safe.** The palette has one accent, so there are no hue pairs to
  confuse. The year grid is a single-hue ramp whose steps are separated by ≥1.25× in luminance,
  which means they stay distinguishable in greyscale and to a fully monochromatic viewer.
- **Never `#000` on `#FFF` or `#FFF` on `#000`.** Maximum contrast is not optimum contrast —
  pure white on pure black causes halation (text appears to glow and blur), which is
  particularly hard on people with astigmatism. The warm near-blacks and off-whites in the
  palette are deliberate.

## Touch targets
- **Minimum 48×48dp** for anything tappable, always, including the capture bar icons and year
  grid cells. Visual size may be smaller; the *hit* area may not be.
- **8dp minimum between adjacent targets.**
- Primary actions within thumb reach on a 6.7" phone.

## Screen readers (TalkBack / VoiceOver)
- **Every interactive element has a label.** No unlabelled icon buttons — an icon-only button
  with no semantic label is announced as "button", which is useless.
- **Every entry announces meaningfully:** *"Voice note, 47 seconds, 9:15am"* — not "button".
- **Year grid cells:** *"4 March, 3 entries"*. This is what makes a visualisation accessible —
  the data is in the semantics, not only in the pixels.
- **Reading order follows visual order.** Test by swiping through every screen with the reader on.
- **State changes are announced** — recording started, entry saved, vault locked.
- **Decorative elements are explicitly hidden** from the reader rather than left to guess.

## Text scaling
- **Every size scales with the OS setting, to 200%, with no clipping and no overlap.** Never a
  hardcoded font size, never a fixed-height text container.
- Layouts reflow rather than truncate. Test at 200% on every screen — this is where most apps
  visibly break, and it's a five-minute test per screen.

## Motion and animation
- **`prefers-reduced-motion` respected**: transitions become instant cross-fades. One flag, and
  for people with vestibular disorders the difference is nausea versus no nausea.
- Nothing flashes more than 3 times per second (seizure safety).
- No auto-playing motion. Nothing moves unless the user caused it.

## Motor accessibility
- **No gesture is the only way to do anything.** Every swipe has a button or menu equivalent.
  Swipe-to-file is a convenience; long-press-menu is the guarantee.
- **No time limits.** Nothing disappears on its own.
- No action requires precision dragging or a double-tap.
- Auto-lock is user-configurable including "never", because a short timeout is a genuine
  barrier for someone who types slowly.

## Cognitive accessibility
- **Plain language everywhere.** *"That passcode doesn't open this file"*, never *"Authentication
  error: invalid credentials"*.
- Errors say what happened **and what to do next**.
- **Destructive actions are confirmed and reversible.** Trash holds for 30 days.
- No jargon in the interface. "Recovery phrase", not "BIP-39 mnemonic seed".
- Consistent placement — the capture bar never moves.

## Hearing
- Voice notes are **never the only carrier of information** in the app's own UI.
- If on-device transcription ships, it makes the user's *own* voice notes accessible to them —
  which is an accessibility win as much as a search feature.
- All haptics and sounds have visual equivalents.

---

## The testing checklist

Run this before every release. It takes about twenty minutes.

- [ ] TalkBack on — navigate every screen end to end, eyes closed for the last pass
- [ ] Text size at 200% — every screen, no clipping, no overlap
- [ ] `prefers-reduced-motion` on — no motion sickness triggers
- [ ] Grayscale filter on — is everything still distinguishable? (catches colour-only encoding)
- [ ] One-handed, thumb only — can you reach every primary action?
- [ ] In direct sunlight, light mode — is anything unreadable?
- [ ] Colour-blindness simulator (deuteranopia, protanopia, tritanopia)
- [ ] Keyboard only, on desktop — every action reachable, focus always visible
- [ ] Contrast checker on final screenshots, not just on the token table

**Ask Claude Code to write widget tests asserting semantic labels exist.** Accessibility
regressions are invisible until someone reports them, and by then it's shipped.
