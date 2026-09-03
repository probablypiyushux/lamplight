# Features — what's in, what's missing, what we refuse

*Written 17 Aug 2026, answering: "Do you think it needs more features?"*

## The short answer

**No. It needs fewer features and three missing pieces.**

Those are different things. A *feature* is something you add to do more. A *gap* is something
that's broken about what you already promised. Right now the spec has no feature shortage —
it has three gaps, and one of them is serious.

The discipline to hold: **every feature is a tax on "minimal as fuck."** Notes apps don't die
from having too few features. They die from becoming Notion — a beautiful idea buried under
four years of "could we also…". Your brief's best instinct was restraint. Protect it.

---

# Part 1 — The three gaps 🔴

## Gap 1: The app is currently write-only. This is the serious one.

Read back through `UX-FLOWS.md`. Almost every screen is about **capture** — record, photo,
text, file, autosave. Barely anything is about **re-reading**.

But nobody journals for the writing. **They journal for the reading.** The value of a record
of your life is realised entirely in the future, when you look back at it. An app you only
write into is a hole you throw things down. That's why people stop after nine days: they never
get anything back.

Every journalling app that has retained users has solved this, and always the same way:
**resurfacing.**

**What's needed (and it's small):**

- **"On this day"** — one line at the top of today: *4 March 2025 · you wrote about the interview*.
  Tap to go there. This is the single highest-value feature in every journal app that has it,
  and it's one SQL query: `WHERE day_key LIKE '____-03-04'`.
- **The year grid as an actual destination**, not a stat screen. 365 cells that fill in. Tap to
  travel. In year three, this screen is the reason someone still uses the app.
- **A quiet "look back" surface** — a random past entry, a folder you haven't opened in months.
  Not a notification. Just something present when you open the app with nothing to say.
- **Folder-as-thread reading.** Opening `Kavya` should read like a continuous story across four
  years, not like a file listing. Dates as quiet dividers, entries flowing.

None of these are new machinery. They're queries against the model in `DATA-MODEL.md`. But
without them, the app is a very secure void.

## Gap 2: Day one is empty, and empty feels dead

The user installs, sets a passcode, writes down twelve words, and arrives at… a blank screen
and an empty year grid. This is where most journalling apps lose people before they start.

**What's needed:** not a tutorial or a carousel. Something more like a first prompt that
doesn't feel like homework — one line, dismissible, the app quietly asking a question. And the
year grid should show the shape of the year ahead, not just an empty box, so it reads as *a
thing beginning* rather than *a thing that's empty*.

## Gap 3: Year three will break it, and nobody plans for this

Do the arithmetic on your own spec:

| | Per day | Per year |
|---|---|---|
| 5 min of voice | ~2.5 MB | **~900 MB** |
| 3 photos | ~9 MB | **~3.3 GB** |
| Text | trivial | trivial |

**Roughly 4 GB per year.** After five years that's 20+ GB sitting on a phone, in one app,
that can never offload to a cloud — because you deliberately have no cloud. Users will hit
storage limits and start deleting things, which is exactly the failure you built this to prevent.

**The solution is already in your architecture, which is the nice part.** You have an encrypted
archive format. So:

> **Archive a year.** *"2024 — 1,203 entries, 3.8 GB. Archive it?"* Produces `Vault-2024.vault`,
> the user stores it wherever they keep backups, and the phone keeps only text and thumbnails
> for that year — fully searchable and browsable, with attachments marked as archived. Tap an
> archived photo and it says *"in Vault-2024.vault"* and offers to re-import.

That's a genuinely good feature nobody in this category has, and it falls out of the backup
format for almost free. Also worth having from day one:

- Voice codec and photo quality settings (Opus at 32 kbps is transparent for speech and a
  fraction of the size)
- A storage screen that shows where the space went, by year and by type
- Directory sharding for the attachment store — 20,000 files in one folder is slow on Android

---

# Part 2 — The one thing worth doubling down on 🟢

**Voice. Go much harder than the brief does.**

Here's the strategic case. `REALITY-CHECK.md` established that your differentiator is *no
account + capture that isn't typing*. Push on that second half and something interesting
happens:

**Most people cannot write every day. Almost everyone can talk for two minutes.**

Writing a journal entry is work — it requires composing, and composing requires energy you
don't have at 11pm. Talking is free. And your exact brief — *"recording his experiments,
recording his feelings, recording things about a particular phase or particular person"* —
is much more natural spoken than written. People say true things out loud that they'd edit
out of writing.

Nobody has built a genuinely great voice journal. The category is wide open, and the reason
is that voice has always meant *sending your audio to someone's server to transcribe it*,
which is fatally at odds with privacy. **On-device transcription removes that conflict
entirely** — and that changes the calculus:

**On-device transcription (Whisper-tiny/base, fully offline) should move from "v2 nice-to-have"
to a serious candidate for your core feature.** Because with it:

- Voice notes become searchable, so years of talking become a usable archive rather than
  hundreds of unlistenable recordings
- The entry can show a text preview, so scanning back through a year actually works
- It stays 100% offline, so the privacy promise is untouched — and "your voice never leaves
  your phone, not even to be transcribed" is a *genuinely* rare sentence in 2026

Cost: ~40–75 MB of app size, meaningful battery during transcription (do it on charge), and
real implementation work. **Still not v1** — Phase 1–4 must ship first. But design the data
model for it now (`transcript` column already exists in `DATA-MODEL.md`), and treat it as the
thing that could make this app matter rather than a bonus.

---

# Part 3 — Worth adding, small, high payoff 🟡

Ranked by value per unit of complexity:

1. **"On this day"** — Gap 1. One query. Highest value in the document.
2. **Archive a year** — Gap 3. Solves a real problem, uses machinery you already have.
3. **Entry markers** — a single optional tap: a dot, a star, a colour. *Not* a 1–10 mood
   scale, not an emotion wheel. Just "this one mattered." Enables "show me the entries I
   marked," which is a beautiful way to read back a year.
4. **A serif reading mode** — a typeface toggle for the user's own writing. Trivial to build,
   disproportionate effect on whether the app feels like a notebook or a form.
5. **Continue yesterday's thread** — if you were mid-thought at 1am, opening the app should
   offer to keep going rather than starting cold.
6. **Import from Day One / Google Keep / Apple Notes** — without it, anyone with existing
   history can't switch, and switching cost is the biggest barrier in this category. Do it as
   a one-time import that scrubs its plaintext source afterwards. **Phase 5+, but real.**
7. **A discreet icon and name option** — for your #1 threat (someone picks up the unlocked
   phone), the app's *existence* on the home screen is itself information. Let the user change
   the icon and label. Cheap, and it directly serves the most realistic threat in the model.

---

# Part 4 — The refusals, and why 🔴

Saying no is the design work. Each of these will be requested; each should be declined.

| Request | Why no |
|---|---|
| **Tags** | Folders already do this and folders are many-to-many. Two organising systems means deciding twice. |
| **Rich text / markdown / formatting toolbar** | A formatting bar between you and your feelings. iA Writer's whole thesis. Plain text, maybe bold and a bullet. Nothing more. |
| **Templates** | Turns journalling into paperwork. The blank page is the point. |
| **Any AI feature** | Summarising your journal, "insights", sentiment analysis. Even done locally, it converts a private record into a thing being *analysed*, and it breaks the emotional contract of the app. This is the easiest and most important no in the list. |
| **Sharing / export-to-social** | The app is a room with one person in it. |
| **Streaks, badges, gamification** | Guilt mechanics on a mental-health-adjacent product. Actively harmful. Missing a day should cost nothing. |
| **Cloud sync (as a core feature)** | ADR-002. Kills the model. |
| **Multiple accounts / profiles** | ADR-001. |
| **A web version** | Browser crypto is a fundamentally weaker trust model. Never. |
| **Collaboration, comments, shared folders** | Not what this is. |
| **Calendar / task integration** | Not a productivity app. |

## The genuinely hard call: location and weather

Day One's most-loved feature is automatically tagging entries with where you were and what
the weather was. It's genuinely magical for a life record — *"reading this back, I'd forgotten
it was the week it wouldn't stop raining."*

Both are technically possible offline (GPS is a device sensor; weather is not, it needs the
network — which would break the no-INTERNET-permission property that is currently one of your
strongest verifiable claims).

**Recommendation: no weather, ever** — it costs you the network-permission guarantee, which is
worth more than the feature. **Location: optional, off by default, coarse-only, stored encrypted
like everything else, and never in v1.** Location history is the most sensitive metadata a
person has, and having it be *possible* to store means having it be possible to lose.

---

## The test for every future feature

Two questions, in order:

1. **Does this help someone record, or re-read, their life?**
2. **Would removing it make the app feel emptier, or lighter?**

If the answer to (2) is "lighter" — don't build it.
