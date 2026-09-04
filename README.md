# Lamplight — working folder

[![verify](https://github.com/probablypiyushux/lamplight/actions/workflows/verify.yml/badge.svg)](https://github.com/probablypiyushux/lamplight/actions/workflows/verify.yml)

> The badge is the analyser, the whole suite, and **both release gates run against a
> built release APK** — `verify_no_internet.sh` reads the permissions out of the artifact,
> `verify_no_sockets.sh` reads the symbols the native library imports. The app's central
> claim is that a stranger can check it rather than trust us, and a check that only ever
> ran on one laptop was not one a stranger could rely on.

**Name:** Lamplight · package ID `com.probablypiyush.lamplight` (ADR-010, permanent)
**Licence:** GPL-3.0 with an App Store exception (ADR-007) — see `LICENSE`
**Started:** 17 August 2026
**Owner:** Piyush
**Status:** Phase 3 — publication. A signed Android App Bundle exists as of 31 August 2026
(`0.5.0+10`, targetSdk 36, both release gates passing against the artefact). What is left
before the Play Store is in `05-shipping/STORE-LISTING.md` and none of it is code.

> Day-to-day state lives in `STATE.md`. Read that first; this file is the map of the
> specification, and the specification changes far more slowly than the work does.

---

## What this folder is

Everything we decide about this app lives here, in plain Markdown, in version-controllable
text. Nothing is in anyone's head. When you sit down with Claude Code in three weeks and
can't remember why the backup file has two key wrappers, the answer is in
`02-security/SECURITY-ARCHITECTURE.md`.

Write things down before you build them. This is the single highest-leverage habit for
someone who doesn't code, because the documents are the part you *can* fully understand
and control, and they are what you hand to the AI that writes the code.

## Read in this order

| # | File | Why |
|---|---|---|
| 1 | `06-for-you/HOW-APPS-ACTUALLY-WORK.md` | **Start here.** You said you know nothing about how an app gets made or shipped. This fixes that in one read. |
| 2 | `00-vision/WHAT-WE-ARE-BUILDING.md` | The idea, sharpened. What it is, what it refuses to be. |
| 3 | `01-decisions/DECISIONS.md` | Every decision made so far, and the reasoning. The most important file here. |
| 4 | `02-security/THREAT-MODEL.md` | Who we are defending against, and — just as important — who we cannot defend against. |
| 5 | `02-security/SECURITY-ARCHITECTURE.md` | The actual crypto design. Technical, but read it anyway. |
| 6 | `03-product/DATA-MODEL.md` | How days, folders, and entries relate. Solves the "daily tab AND file explorer" puzzle. |
| 7 | `03-product/UX-FLOWS.md` | Screen by screen, first launch to restore-on-new-phone. |
| 8 | `03-product/DESIGN-LANGUAGE.md` | The "minimal as fuck" brief, made concrete. |
| 9 | `04-technical/TECH-STACK.md` | Flutter, and why. Plus the exact packages. |
| 10 | `04-technical/BACKUP-FILE-FORMAT.md` | The `.vault` file spec. Freeze this before shipping. |
| 11 | `05-shipping/STORE-REQUIREMENTS.md` | What Google and Apple demand in 2026. Money, testers, deadlines. |
| 12 | `05-shipping/OPEN-SOURCE-PLAN.md` | Licence choice — there is a real trap here that kills App Store releases. |
| 13 | `06-for-you/ROADMAP.md` | Phases, and an honest timeline. |
| 14 | `01-decisions/OPEN-QUESTIONS.md` | What we still have to decide. |
| 15 | `00-vision/REALITY-CHECK.md` | Honest assessment: where the idea is strong, where it's harder than it looks. |
| 16 | `03-product/FEATURES-IN-AND-OUT.md` | The three gaps, what's worth adding, what we refuse. |
| 17 | **`03-product/FEATURE-RANKING.md`** | **Every free feature, scored and ranked. Build top-down.** |
| 18 | `05-shipping/DISTRIBUTION.md` | GitHub vs Play Store vs F-Droid, and the order. |
| 19 | **`08-design/DESIGN-SYSTEM.md`** | **"Lamplight" — the full palette, type, spacing, components.** |
| 20 | `08-design/CONTRAST-REPORT.md` | Computed WCAG verification for every colour, both modes. |
| 21 | `08-design/ACCESSIBILITY.md` | WCAG AA targets and the pre-release checklist. |
| 22 | `08-design/ETHICAL-DESIGN.md` | The "no malpractice" charter. No dark patterns, ever. |
| 23 | `08-design/design-reference.html` | **Open this in a browser** — the design system, live, with a light/dark toggle. |
| 24 | `07-conversation/` | Raw session logs. The discussion itself. |

## The one-line version

> A private notebook for your life that no one — not us, not Google, not Apple, not a
> court order — can read, because there is no account, no server, and no copy of your
> key anywhere but in your own head.

## Ground rules we are holding ourselves to

1. **No account, no server, no telemetry.** If a feature needs a server, the feature is wrong.
2. **Nothing plaintext ever touches disk.** Not a temp file, not a cache, not a thumbnail.
3. **Format versioning from day one.** Backups made in v1 must open in v9.
4. **No security claims in the store listing until an independent audit exists.**
5. **Ship small.** A tiny app that is genuinely secure beats a big one that is nearly secure.
