# What we are building

## The sentence

> A private notebook for your life — voice, photos, writing, documents — where the record
> is organised by the day it happened, and no one but you can ever open it.

## The feeling

You described it better than a spec ever could:

> *"I want this app to feel like — the user is recording his experiments or recording his
> feelings! recording things about a particular phase or particular person."*

That line is the product. Hold onto it. Every feature request from here on gets tested
against it: **does this help someone record a phase of their life, or is it clutter?**

Three specific feelings to engineer for:

1. **Zero friction to capture.** The gap between "I want to say this" and "it is recorded"
   must be under two seconds. If someone has to think about *where* a thought goes before
   they can record it, they won't record it. This is why the day tab is the home screen and
   folders are secondary — the day already exists, so there is nothing to decide.

2. **Total safety to be honest.** People only write the true thing if they are certain no
   one will read it. Not "probably won't" — certain. That certainty is a *technical*
   property, and it's the entire reason the security architecture is as paranoid as it is.
   The security is not a feature bolted on the side; it is what makes the writing possible.

3. **Weight of accumulation.** After two years this should feel like something. A year grid
   that fills in. A folder called "Dad" with 340 entries in it. The app should quietly make
   you aware that you have been keeping a record, because that's what makes you keep going.

## What it is not

Saying no is most of the design work. This app is **not**:

- ❌ **Not a collaboration tool.** No sharing, no comments, no multiplayer. One person, one vault.
- ❌ **Not a task manager.** No to-dos, no checkboxes, no due dates. There are a thousand of those.
- ❌ **Not a second brain / knowledge base.** No backlinks, no graph view, no wiki. This is a
  record of a life, not a database of ideas. Notion and Obsidian exist.
- ❌ **Not AI-powered.** No cloud LLM reads your journal. Ever. That is the whole point.
  (On-device transcription is a possible exception — see `01-decisions/OPEN-QUESTIONS.md`.)
- ❌ **Not social.** No accounts, no profiles that anyone else sees, no streaks-as-guilt.
- ❌ **Not free-with-your-data.** There is no data to take. The business model can never be ads.

## The two organising ideas, and how they fit together

You asked for two things that sound like they conflict:

> *"Each day the man is given a tab"* — a chronological journal
> *"create folder wise notes! Folders present in Windows or mac styled file explorer"* — a spatial filing system

These are not two features. They are **two lenses on one pile of entries**.

- Every single thing you capture is an **Entry**, and every entry knows the moment it was made.
  That timestamp puts it on a **Day** automatically. Days are never created by hand; they
  simply exist because time does.
- Any entry can *also* be filed into one or more **Folders**. Filing does not move or copy it —
  the entry still lives on its day forever. A folder is a saved view, not a container.

Which means: a folder called **"Kavya"** or **"The Bangalore year"** or **"Sleep experiment"**
gathers entries from across two hundred different days into one continuous thread. That is
exactly your *"recording things about a particular phase or particular person"* — and it
falls out of the data model for free rather than being a separate feature.

The full model is in `03-product/DATA-MODEL.md`.

## The promise to the user, in the words we'd put on the store page

> There is no account. There is no server. Your notes never leave your phone unless you
> export them yourself, and when you do, the file is locked with a passcode we do not know
> and cannot recover. We can't read your notes. We can't lose your notes. We can't be made
> to hand them over. Not because we promise — because we built it so we couldn't.

Every clause of that is a technical commitment made in `02-security/SECURITY-ARCHITECTURE.md`.
If we ever have to soften one of those sentences, we have made a wrong turn.
