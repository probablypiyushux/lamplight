# Feature ranking — everything free and possible

Every feature that costs **₹0 to run** and is achievable inside the no-server architecture,
ranked. Nothing here needs a backend, a subscription, or a third-party service.

**How the ranking works.** Each item is scored **Value 1–5** (how much it serves *recording
and re-reading a life*) and **Effort 1–5** (how hard for you + Claude Code). **Score = Value ÷
Effort.** Higher is better. Ties broken by whether it protects the core promise.

Build strictly top-down. **Do not skip to the fun ones.**

---

## TIER 0 — Foundation (not features; the app doesn't exist without them)

| # | Thing | V | E | Notes |
|---|---|---|---|---|
| 0.1 | Encrypted vault + key hierarchy | — | 5 | Phase 1. Everything sits on this |
| 0.2 | Passcode + Argon2id unlock | — | 3 | |
| 0.3 | Recovery phrase | — | 2 | ADR-003 |
| 0.4 | Encrypted database (SQLCipher) | — | 3 | |
| 0.5 | Encrypted attachment store (chunked) | — | 4 | Streaming is the hard part |
| 0.6 | Lock on background + auto-lock | — | 2 | Defends threat #1 |
| 0.7 | `FLAG_SECURE`, `allowBackup=false` | — | 1 | Two lines. Enormous value |

---

## TIER 1 — Ship in v1 🟢 *Score ≥ 2.0*

The app is not worth releasing without these.

| Rank | Feature | V | E | Score | Why |
|---|---|---|---|---|---|
| 1 | **Text entry + autosave** | 5 | 1 | **5.0** | The floor. No save button anywhere |
| 2 | **The day view (stream)** | 5 | 1 | **5.0** | Home screen. Today is always already open |
| 3 | **"On this day"** | 5 | 1 | **5.0** | One SQL query. Highest value-per-effort in the whole document. Fixes the write-only gap |
| 4 | **Swipe between days** | 4 | 1 | **4.0** | The entire navigation model |
| 5 | **Voice recording** | 5 | 2 | **2.5** | Your differentiator. Streaming encryption is the work |
| 6 | **Photo capture + import** | 5 | 2 | **2.5** | Scrub the temp files |
| 7 | **Dark + light mode** | 4 | 2 | **2.0** | See `08-design/DESIGN-SYSTEM.md` — tokens make this nearly free |
| 8 | **Folders (tree) + filing** | 5 | 2.5 | **2.0** | Your "phase or person" feature |
| 9 | **Full-text search** | 5 | 2.5 | **2.0** | Useless at year three without it. Free because SQLCipher gives us FTS5 |
| 10 | **The year grid** | 4 | 2 | **2.0** | The emotional payoff screen |
| 11 | **Backup export (.vault)** | 5 | 4 | 1.25 | Non-negotiable despite the score. Data loss is unforgivable |
| 12 | **Restore from backup** | 5 | 4 | 1.25 | Same. The moment that earns trust |
| 13 | **File / PDF import** | 3 | 2 | 1.5 | You asked for it; it's cheap |
| 14 | **Trash (30 days) + restore** | 4 | 1.5 | 2.7 | Cheap insurance against the user's own thumbs |
| 15 | **Screen reader + dynamic type** | 4 | 2 | **2.0** | Not optional. See `08-design/ACCESSIBILITY.md` |

## TIER 2 — v1.1, within weeks of launch 🟡 *Score 1.0–2.0*

| Rank | Feature | V | E | Score | Why |
|---|---|---|---|---|---|
| 16 | **Entry markers** (one tap: starred/mattered) | 4 | 1 | **4.0** | Not a mood scale. Enables "read back what mattered" |
| 17 | **Serif reading mode** | 3 | 1 | **3.0** | Trivial. Disproportionate effect on whether it feels like a notebook |
| 18 | **Calendar month view** | 3 | 1 | **3.0** | Jump to a date |
| 19 | **Revision history** | 4 | 1.5 | 2.7 | "I deleted a paragraph" is recoverable |
| 20 | **Pin entries** | 2 | 0.5 | 4.0 | Almost free |
| 21 | **Backup reminder banner** | 4 | 1 | **4.0** | Prevents the most likely total-loss event. A security feature |
| 22 | **Storage breakdown screen** | 3 | 1 | **3.0** | Users will need it by year two |
| 23 | **Attachment quality settings** | 3 | 1 | **3.0** | Opus 32 kbps is transparent for speech and a fraction of the size |
| 24 | **Folder-as-thread reading** | 4 | 1.5 | 2.7 | Makes `Kavya` read as a story, not a file listing |
| 25 | **Continue yesterday's thread** | 3 | 1 | **3.0** | Small, thoughtful, memorable |
| 26 | **Reduced-motion support** | 3 | 0.5 | 6.0 | One flag. Accessibility |
| 27 | **Smart folders (saved searches)** | 3 | 2 | 1.5 | Free extra feature — a folder row holding a query |
| 28 | **Discreet app icon + name** | 3 | 1.5 | **2.0** | Directly serves threat #1 (someone picks up your phone) |
| 29 | **Random past entry / "look back"** | 3 | 1 | **3.0** | Fills the "opened the app with nothing to say" moment |

## TIER 3 — v2 🟠 *Real work, real payoff*

| Rank | Feature | V | E | Score | Why |
|---|---|---|---|---|---|
| 30 | **Archive a year** | 5 | 3 | 1.7 | Solves the 4 GB/year problem. Uses the backup format you already built. Nobody else has this |
| 31 | **On-device voice transcription** | 5 | 4.5 | 1.1 | Could be the thing that makes the app matter. Must be provably offline. See `FEATURES-IN-AND-OUT.md` |
| 32 | **Import from Day One / Keep / Notes** | 4 | 3.5 | 1.1 | Removes the biggest barrier to switching |
| 33 | **Quick-capture widget (write-only)** | 4 | 3 | 1.3 | Design it so it can add but never read or display |
| 34 | **Plaintext export (per entry/folder)** | 3 | 1.5 | **2.0** | Behind a clear warning. "Your data is yours" demands it |
| 35 | **Desktop build** | 4 | 3 | 1.3 | Flutter gives most of it free. Long writing is better on a laptop |
| 36 | **Bulk actions (multi-select)** | 2 | 2 | 1.0 | Filing 40 entries at once |
| 37 | **Optional auto-backup to user's own cloud** | 4 | 3.5 | 1.1 | Still zero-knowledge. Prevents real data loss |
| 38 | **Wipe after N failed attempts** | 2 | 1 | **2.0** | Default off, loud warning |
| 39 | **Localisation (Hindi first)** | 3 | 2.5 | 1.2 | Your home market |

## TIER 4 — Someday, if people ask 🔵

| Feature | V | E | Note |
|---|---|---|---|
| Sketch / handwriting entries | 3 | 4 | Lovely, expensive |
| Multiple vaults on one device | 2 | 3 | Adds complexity everywhere |
| Extra-locked "hidden" folder | 2 | 3 | Second key layer. Requested often, rarely used |
| Share-to-app (receive from other apps) | 3 | 2 | Android intent filter; convenient |
| Keyboard shortcuts | 2 | 1 | Desktop only |
| Backup size padding | 2 | 2 | Metadata hygiene |
| Split-volume backups | 1 | 3 | Only for enormous vaults |
| Optional coarse location | 2 | 3 | Off by default, never v1. See the hard-call section |
| Reproducible builds | 3 | 4 | Not a user feature — a *trust* feature. Needed for F-Droid |

## NEVER 🔴

Not "later." Never. Each would damage the thing that makes this app worth building.

| | Why |
|---|---|
| Any AI feature — summaries, "insights", sentiment | Converts a private record into a thing being analysed. Breaks the emotional contract even done locally |
| Cloud sync as a core feature | ADR-002 |
| Accounts, profiles, social anything | ADR-001 |
| Web version | Browser crypto is a fundamentally weaker trust model |
| Streaks, badges, guilt mechanics | See `08-design/ETHICAL-DESIGN.md` |
| Ads, tracking, analytics of any kind | The business model must never want their data |
| Weather auto-tagging | Needs the network. Costs the no-INTERNET-permission guarantee, which is worth more |
| Tags (as a separate system from folders) | Two organising systems means deciding twice |
| Formatting toolbar | A ribbon between you and your feelings |

---

## What "free" actually means here

**Every single feature above costs ₹0 to operate**, no matter how many users you get. That is
not normal, and it's worth naming: there is no feature on this list that starts a monthly bill.
The only costs in the whole project are the one-time $25 Play registration and, if you ever
want iOS, $99/year.

The scarce resource isn't money. **It's your evenings.** Which is exactly why the ranking
exists — spend them top-down.

## The build order, condensed

```
  Tier 0  →  ranks 1–4    →  ranks 5–10   →  ranks 11–15  →  Tier 2   →  Tier 3
  vault      the loop        the substance    trust & a11y    polish      ambition
```

Ranks 1–4 alone give you an app you'd use. Get there first — the momentum from *using your own
app daily* is what carries a solo project through the months that follow.
