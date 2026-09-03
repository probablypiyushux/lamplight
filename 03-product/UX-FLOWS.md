# UX flows

Screen by screen, from install to restore-on-a-new-phone. Written so you can hand any single
section to Claude Code and say "build this."

---

## Flow 1 — First launch (target: under 60 seconds)

**Screen 1 — The promise**
```
        There is no account.

        Your notes stay on this phone.
        We have no server. We can't read them.
        We can't recover them either.

                 [ Begin ]
```
Four lines. No signup form, no email field, no "Continue with Google". The absence of a
signup screen *is* the pitch — it's the first thing that tells the user this app is different
from every other one they've installed. Don't bury it in a privacy policy.

**Screen 2 — Set a passcode**
Numeric pad by default, with a visible `Use a passphrase instead` toggle. Honest strength
feedback (not a nagging red bar). Confirm once.

**Screen 3 — The recovery phrase**
```
        Write these twelve words on paper.

        1 harbour    5 gentle    9  window
        2 pilot      6 marble    10 season
        3 return     7 lantern   11 quiet
        4 index      8 valley    12 orchard

        We do not have a copy. There is no
        support email that can help you.

        [ I've written them down ]
```
Then: confirm three randomly chosen words. Screenshots are blocked here (`FLAG_SECURE`) —
a screenshot in the gallery is the single worst place these could live. Say why, briefly.

**Screen 4 — You (skippable, and clearly skippable)**
Display name, optional photo. One line under it: *Stored encrypted on this phone. Nobody sees
this but you.* Because you wanted a profile, and this is the version of a profile that costs
the user nothing.

**Screen 5 — Biometric?**
`Unlock with fingerprint?` — Yes / Not now. Explain in one line that the passcode is still
the real key.

**Then: straight into today.** No tutorial, no carousel, no permissions requested up front.
Ask for microphone the first time they tap record, camera the first time they tap the camera.
Just-in-time permission requests get dramatically higher acceptance rates and are less alarming.

---

## Flow 2 — The daily loop (the 95% case)

Open → app is locked → passcode or fingerprint → **today, already open, cursor ready.**

That's it. No home screen, no dashboard, no "what would you like to do?". Today is the home
screen. Yesterday is one swipe right. The year grid is one tap up.

Capture bar, always visible at thumb height: **🎙 voice · 📷 photo · 📎 file**

- **🎙** — one tap starts recording. Live waveform, elapsed time, one big stop button. Encrypted
  chunks written continuously. Haptic on start and stop. No "save" step — stop *is* save.
- **📷** — opens straight to the camera, not the gallery. Second tab for gallery import.
- **📎** — system file picker, encrypt on import, scrub the temp file.

**Writing has no button, and that is the change of 23 August 2026.**

This bar used to begin with **✎ text**, whose only job was to put the cursor in a composer
pinned above the bar. the maintainer's round-five note was *"typing doesn't feel like writing on any
kind of notes app"*, and he was describing the shape rather than the behaviour: a bordered
field at the bottom of the screen with your words appearing somewhere else is a chat app's
composer, however well it autosaves.

So the caret went onto the page. Writing starts by **tapping the page** — the empty day's
sheet, or the space after the last block — exactly as it does in every notes app on the
phone, and the words grow down the page in the page's own face. Voice, photo and file keep
their buttons because none of them can be started by tapping a page. Text no longer needs
one, and a button whose whole function is "put the cursor in the thing you can already see"
is what made the screen feel like a form.

Unchanged, and worth restating because both were asked about: **Enter makes a new line**, and
**autosave still runs on every keystroke** — plus on backgrounding, on a day change, and on
leaving the screen. **There is still no save button anywhere in the app.** What looked like
one was the draft being drawn twice; see ISSUE 14.

**Navigation:** swipe left/right between days. Tap the date → month calendar. Pinch out →
year grid. Search from anywhere. That's the whole navigation model — four gestures, nothing
to learn.

---

## Flow 3 — Filing into folders

Long-press an entry → `Add to folder` → picker tree with `+ New folder` at the top.

After the first time, once only:
> `Still on 4 March. Also in Kavya.`

That one sentence teaches the entire data model. Never show it again.

Explorer is reachable from a tab or an edge swipe. Windows/Finder shape: tree, breadcrumbs,
list/grid toggle, drag to nest, counts on the right.

---

## Flow 4 — Search

One field, top of the explorer and pull-down from the day view.

Searches across: note text, folder names, attachment filenames, and (if built) voice
transcripts. Results grouped by folder and by year, with the matched phrase in context.

Filters as chips, not a settings screen: `voice` `photos` `files` `this year` `in Kavya`.

---

## Flow 5 — Backup (the flow that decides whether people lose their lives' records)

Settings → Backup.

```
   Last backup:  never
   Vault size:   1.2 GB · 3,847 entries · 892 days

   [ Create backup file ]

   ─────────────────────────────────────────
   Your backup is locked with your passcode.
   Keep it somewhere you trust. We never see it.
```

On tap:
1. **Confirm the passcode.** (This backup can unlock everything — make it a deliberate act.)
2. Progress bar, honest and per-file, cancellable.
3. Write `Vault-2026-08-17.vault`.
4. **Verify: reopen the file we just wrote and decrypt it end to end.** Do not report success
   until this passes. This step is not optional — it is the difference between a backup and
   the *belief* that you have a backup.
5. System share sheet: save to Drive, Files, a USB stick, wherever they like.

```
   ✓ Backup created and verified.
     Vault-2026-08-17.vault · 1.2 GB

     [ Save to… ]
```

**The nag:** after 30 days without a backup, a single quiet banner on the day view — not a
modal, not a red badge. Dismissible, returns in 7 days. Escalate the wording gently, never
the intrusiveness.

**Retention:** keep the last 3 backup files rather than overwriting one. A corrupt overwrite
of your only backup is the worst outcome in the entire app.

---

## Flow 6 — Restore on a new phone (the moment that earns trust)

Install → the *very first screen* has a small `I have a backup` link under `[ Begin ]`.

1. `I have a backup` → system file picker.
2. Enter the passcode for **that backup**. (Not "your account password" — there isn't one.)
3. Progress bar. Decrypt, verify, import.
4. `Restored. 3,847 entries across 892 days. Welcome back.`
5. Straight into today.

No login. No email. No server round-trip. No waiting. **Works on a plane.** Works in ten
years when your GitHub is archived and you've moved on, because the file and the published
spec are all it ever needed.

Failure cases, each with a distinct and honest message:
- Wrong passcode → *"That passcode doesn't open this file."* (Never "invalid credentials".)
- Corrupt file → *"This file is damaged and can't be opened. If you have an older backup, try that."*
- Newer format → *"This backup was made with a newer version. Update the app."*
- Interrupted → resume, or restart cleanly. Never leave a half-restored vault.

---

## Flow 7 — Locking

- Lock immediately on backgrounding. Non-negotiable.
- Auto-lock after idle: default 1 minute, configurable 15s → 15min → never.
- `FLAG_SECURE` everywhere, so the app is a blank rectangle in the recent-apps switcher.
- On the lock screen: **no preview, no counts, no "3,847 entries", nothing.** Just the app
  mark and the passcode field. The lock screen should reveal that the app exists and nothing more.

---

## Flow 8 — Changing the passcode

Settings → Change passcode. Old → new → confirm. **Instant**, because we only rewrap a
32-byte key (see `02-security/SECURITY-ARCHITECTURE.md` §1) rather than re-encrypt gigabytes.

Warn clearly: *"Backup files you already made still open with your old passcode. Make a new
backup."* This is a genuine footgun and users will not work it out themselves.

---

## Round six amendments — 24 August 2026

Recorded here rather than edited into the flows above, so that what changed and why stays
readable next to what it replaced.

**Flow 1, first launch — a fifth screen.** Between the recovery-phrase check and the name,
Lamplight now offers fingerprint unlock, on phones that have it enrolled. His instruction:
*"If the mobile support fingerprint or face ID? Please set it up from the very beginning the app
is set up! Don't make it tedious that a user needs to go to the setting and find that!"* It is
skipped entirely on a phone that cannot do it, and "Not now" sits under the button at the same
size — a fingerprint is easier to compel than a passphrase, so declining has to be as easy as
accepting.

**Flow 1, screen 3 — the check re-rolls.** The three words asked about are drawn fresh every
time the screen is reached, not once when the vault is made. He found the hole and drew it in
four steps: ignore the words, see which three are asked, go back, memorise those three, return.
The old behaviour asked the same three, so the check proved nothing.

**Flow 2, the capture bar — three buttons, each with a word.** Voice · Photo · File. The glyphs
were unlabelled and a tooltip only appears on a long press, so the only way to learn what the
paperclip did was to press it.

**Flow 5, backup — one filename.** `Lamplight.vault`, for the manual save as well as the
automatic one. *"Only one backup stays."*

**Flow 6, restore — the twelve words are an alternative to the passcode**, offered only for
files whose header says they carry the recovery wrapper.

**Everywhere — portrait only.** The app does not rotate, including the video viewer.
