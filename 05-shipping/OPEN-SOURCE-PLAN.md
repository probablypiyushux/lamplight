# Open source plan

## Why this is not optional

**An unauditable privacy claim is just marketing.** You cannot credibly say "we can't read
your notes" while the code is secret — the user has only your word, and your word is worth
exactly nothing to a stranger. Signal is trusted because it is open, audited, and its
protocol is analysed by academics who would love to find a flaw.

Open-sourcing costs you nothing here. There's no server to protect, no proprietary algorithm,
no moat in the code. Your moat is taste, execution, and trust — and openness *builds* the third.

---

## 🚨 The licence trap (read before your first public commit)

**GPL-family licences conflict with Apple's App Store terms.** This is the famous VLC removal:
Apple's ToS impose usage restrictions (DRM, device limits) that GPLv2/v3 forbid downstream.
Publish GPL code, ship it on the App Store yourself, and you're in a genuine conflict.

Since you want *all* the stores, this matters. Options:

### Option A — **GPL-3.0 + an explicit App Store exception** ⭐ Recommended
Strong copyleft: anyone forking must also open-source. Nobody can take your code, add
telemetry, and ship a closed version — which for a privacy app is exactly the protection you
want. The exception is a standard extra paragraph in `LICENSE` granting the additional
permission to distribute through app stores with their usual terms. Signal does something
analogous; the pattern is well-trodden.

### Option B — **MPL-2.0**
File-level copyleft. Modifications to your files must be shared; someone can combine it with
proprietary code. No App Store friction at all. Weaker protection, zero legal headache.

### Option C — **MIT / Apache-2.0**
Maximum adoption, zero protection. Anyone can fork it, close it, add tracking, and ship
"VaultPro+" with your code and your design. For a privacy app, this is the wrong trade.

### Option D — **AGPL-3.0**
GPL plus a network clause. Meaningless for an app with no server. Skip.

**Recommendation: Option A**, with Option B as the low-friction fallback if the exception
paperwork feels like too much for a first project.

**Decide before the first public commit.** Relicensing after contributors arrive requires
permission from every one of them, and that is a genuinely miserable thing to discover.

---

## Repository shape

```
README.md                 what it is, the promise, screenshots, install links
LICENSE                   ← decide first
SECURITY.md               how to report a vulnerability, and how fast you'll respond
THREAT-MODEL.md           copied from 02-security/ — publish it, it builds trust
docs/
  BACKUP-FORMAT.md        the spec. Publish it. It's the "your data is yours" guarantee.
  ARCHITECTURE.md
  BUILDING.md             so a stranger can build it themselves and compare
CONTRIBUTING.md
.github/workflows/        tests on push, signed build on tag
```

**Publishing the threat model and the backup spec is a competitive advantage, not a risk.**
Every serious privacy project does it; the ones that don't get correctly treated as suspect.

---

## Things to get right

**`.gitignore` on commit one.** Keystores, `key.properties`, `*.jks`, `*.p12`, provisioning
profiles, `.env`. Ask Claude Code to verify this explicitly before the first push. Secrets
committed to a public repo are permanent — GitHub history keeps them even after deletion, and
bots scrape for them within minutes.

**Reproducible builds — the long-term goal.** Open source proves the *source* is clean. It
does not prove the APK on the Play Store was built from that source. Reproducible builds close
that gap and are what F-Droid wants. Hard, worth aiming at, not a v1 blocker.

**`SECURITY.md` with a real contact and an honest response time.** "Best effort, I'm one
person" is a fine and respectable answer. Silence is not.

**Be gracious about security reports.** Someone finding a bug in your crypto is doing you an
enormous favour, even when they're rude about it. Fix, credit, publish. The projects that get
defensive are the ones that lose the community.

**Don't accept crypto PRs you can't evaluate.** For most of the codebase, welcoming
contributions is great. For `core/crypto`, be conservative — a subtle malicious change there
is the highest-value attack on your users, and "it looked fine to me" is not a review.
