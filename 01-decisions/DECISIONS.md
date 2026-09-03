# Decision log

Every entry: the question, the options, the call, and **why**. When you or Claude Code
wonders "why is it built like this?" six months from now, the answer is here.

Format: `ADR-nnn` = Architecture Decision Record. Each has a status. Decisions can be
reversed later, but only by adding a new record that supersedes the old one — never by
quietly editing history.

---

## ADR-001 — No user account. At all. ✅ DECIDED

**The question you asked:** *"getting verification code on email or mobile — I need only
free options! or say me a criteria that he just signs in! apple / google / microsoft?"*

**The honest answer: none of them. Don't collect anything.**

Your original spec had the user filling in name, email, contact, and a profile photo. Then
two paragraphs later you wrote *"safe and secure like Signal"* and *"no option like forgot
passcode."* Those two halves of the spec are at war with each other, and it's worth being
blunt about why.

**Every piece of information you collect is a liability, not an asset.** Ask what an email
address would actually *do* in this app:

- Log you in? There's nothing on a server to log into.
- Recover your data? No — you've correctly decided there is no recovery. An email that
  can't recover anything is decoration.
- Recover your passcode? That would *destroy the entire security model*. If a reset email
  can unlock the vault, then anyone who controls the email controls the vault, and the app
  is no more private than Gmail.
- Let you market to users? Now you have a mailing list. Now you have a breach surface. Now
  you have GDPR and India's DPDP Act obligations, a data-deletion endpoint Google Play
  requires you to build, and a database that a court can compel you to produce.

So the email does nothing useful and costs you everything. Same for phone number — worse,
actually, since a phone number is a real-world identity, costs money to verify via SMS, and
is the single piece of metadata Signal has spent a decade trying to get away from.

**Decision:** No account. No email. No phone. No server. No OTP.

**What the user actually experiences on first launch:**
1. One screen explaining, in four lines, that there's no account and nothing is recoverable.
2. Set a passcode.
3. Write down a 12-word recovery phrase. Confirm three of the words.
4. Optionally type a display name and pick a photo — **stored encrypted on the device, seen
   by nobody, used only to make the app feel like theirs**. Skippable.
5. They're in. Total time: under 60 seconds.

**What this buys you, concretely:**

| | With accounts | With no account |
|---|---|---|
| Server cost | ₹500–5,000/month forever | **₹0** |
| Play Store "Data safety" declaration | A long, scary form | **"No data collected. No data shared."** |
| Account-deletion feature (Play requires it) | Must build it | Not applicable |
| Privacy policy | Complex, needs a lawyer | Short and honest |
| DPDP Act 2023 / GDPR exposure | Real | Essentially none |
| What a subpoena to you produces | A user table | **Nothing. You have nothing.** |
| Signup friction | 3 screens + waiting for an OTP | 1 screen |
| Chance of a breach making the news | Nonzero forever | **Zero. Structurally.** |

That last row is why this is the right call. You cannot leak what you never had. This is
the same reasoning that led Signal to store almost nothing — when they get a subpoena, they
publish the response, and it says the account creation date and the last connection date,
because that's all that exists.

**Supersedes:** the original "name, email, contact, profile photo" spec.
**Consequence:** there is now no way to do server-side sync, push notifications about
content, or cross-device anything. We accept this. See ADR-002.

---

## ADR-002 — Backup is an encrypted file the user controls. ✅ DECIDED

**The question you asked:** *"Back up the data in any cloud? or backup the data as a file?
(not zip file but a special file extension which only our app can restore)"*

**Your instinct was right.** File. Specifically: a single, self-contained, passcode-locked
file with our own extension and our own format. Proposed extension: **`.vault`**
(alternatives to consider: `.vlt`, `.locked`, or the app's own name — decide with the naming).

**Why not cloud:**

Cloud sync sounds like the premium option and it is actually the trap. It would mean:

- You now run infrastructure, forever, for free users, at your own cost.
- You now hold encrypted blobs belonging to strangers, which means you hold *metadata*:
  who has an account, how big their vault is, when they last wrote in it, from what IP.
  That metadata is the thing law enforcement actually asks for, and you'd have it.
- End-to-end-encrypted sync with conflict resolution across devices is one of the genuinely
  hard problems in software. Getting it *nearly* right produces silent data loss, which for
  a journal is the worst possible failure.
- It reintroduces accounts, which ADR-001 just deleted.

**Why the file wins:**

- Costs nothing, forever.
- You never possess the user's data, so you can never lose it, leak it, or be compelled to
  hand it over.
- The user can put the file wherever they trust: their own Google Drive, a USB stick, a
  laptop, three USB sticks in three places. **You have moved the trust decision to the person
  who should be making it.**
- It's inspectable and archival. In 2045 the file is still just bytes; anyone with the
  passcode and the open-source spec can decrypt it. That is a real promise a cloud service
  cannot make, because cloud services shut down.
- It's exactly the Signal model, and Signal is the reference you named.

**The custom extension is not just branding.** It signals to the OS and to the user that
this is not a document to be opened casually, and it lets the app register as the handler so
tapping the file on a new phone offers "Restore into Vault". Under the hood it is a
structured binary format, not a renamed zip — see `04-technical/BACKUP-FILE-FORMAT.md`.

**Optional add-on, later (v2):** an opt-in setting to auto-drop that same encrypted file into
the *user's own* Google Drive / iCloud app folder on a schedule. Still zero-knowledge to us —
we're just automating the copy the user would make by hand. This is worth building because
the honest failure mode of manual backups is that people don't make them, and then a phone
dies and two years are gone. But it is v2, and it is off by default.

**The thing that will actually bite you, so design for it now:** a single encrypted file is a
single point of catastrophic failure. One truncated upload, one bad flash sector, one
interrupted write, and it's unrecoverable — encryption removes all the partial-recovery
tricks you'd normally have. Mitigations, all specified in the format doc:

- Verify the file by *actually decrypting it* immediately after writing, before telling the
  user it succeeded.
- Store a whole-file hash and per-chunk authentication tags so corruption is *detected*
  rather than silently restored.
- Nag, gently but persistently, at 30 days since last backup.
- Keep the last N backups rather than overwriting a single file.

---

## ADR-003 — One-time recovery phrase, and no other escape hatch. ✅ DECIDED

**Your instinct:** *"No option like forgot passcode would be given."* Correct, and we're
keeping it. But with one refinement.

**The design:** at setup, the app generates 128 bits of entropy and renders it as a **12-word
phrase** (BIP-39 wordlist — standard, well-tested, unambiguous words). It is shown once. The
user must re-enter three randomly chosen words to prove they wrote it down. It is never stored
anywhere, never transmitted, never shown again.

That phrase is a second, independent key to the same vault. Forget the passcode → the phrase
gets you in. Lose both → the data is mathematically gone, and no one on earth can help,
including you.

**Why this is better than nothing at all, and still just as secure:**

It changes nothing about what an attacker can do. There is no server-side reset, no email
link, no support backdoor, no "verify your identity and we'll unlock it." The escape hatch
is a secret *only the user holds*, which means it cannot be subpoenaed from you, phished from
your support inbox, or leaked in your breach — because it does not exist in your world.

What it does change is the human failure rate. Pure no-recovery sounds hardcore, but in
practice it produces a steady trickle of people who lose years of their life to a forgotten
passcode and then, quite reasonably, hate you forever and say so in public. The recovery
phrase turns "you're doomed" into "you're doomed *unless you did the responsible thing we
told you to do at setup*" — which is a line you can defend without flinching.

**Also decided (you chose this option):** biometric unlock — fingerprint or face — as a
*convenience* layer on top. The passcode remains the only real key. The biometric unlocks a
copy of the vault key held in the phone's hardware secure element (Android StrongBox / iOS
Secure Enclave), and that copy is destroyed automatically if the user adds a new fingerprint
or face to the device. Details in the security architecture.

**Copy we should use at setup, and never soften:**

> These twelve words are the only way back in if you forget your passcode.
> We do not have them. We cannot send them to you. There is no support email that can help.
> Write them on paper. Not a screenshot — paper.

---

## ADR-004 — Flutter, Android first, then iOS. ✅ DECIDED

**Your answer:** *"i want this app on all the stores available! All the app would be made by
claude code only idk! It's my first app idk anything!"*

Understood — so this decision is made *for* the person you are: a first-timer who wants
maximum reach and has one AI assistant. Flutter is the right call, and the reasoning is
worth having on record.

**Flutter, because:**
- **One codebase → Android, iOS, Windows, macOS, Linux.** You said "all the stores." This is
  the only realistic way to get there without writing the app five times. Desktop is
  particularly relevant here: a file explorer and long-form writing are *better* on a laptop,
  and a desktop app is a natural v3.
- **You only ever debug one thing.** With two native codebases, every bug is potentially two
  bugs, and you'd have to understand both. That's a brutal way to learn.
- **The rendering model suits your aesthetic.** Flutter draws every pixel itself, so "minimal
  as fuck, identical on every device" is the easy path rather than a fight with platform widgets.
- **The security packages you need are mature:** SQLCipher for the encrypted database, libsodium
  bindings for the modern ciphers, first-class access to Android Keystore and iOS Keychain.
- **Claude Code is strong at Flutter.** Large training corpus, stable APIs, very good error
  messages. Practically, this means fewer sessions where you're both stuck.

**What you give up:** a few milliseconds of startup, a slightly larger app size (~15 MB
overhead), and the need to use a plugin for anything deeply platform-specific. For a notes
app, none of these matter.

**Order of platforms, and this part is firm:**
1. **Android first.** ~95% of the Indian market, a $25 one-time fee, and you can install
   builds on your own phone in seconds with no gatekeeping. You will learn everything here.
2. **iOS second**, once Android is real and stable. $99/year, and — the part nobody tells
   first-timers — **iOS builds require a Mac.** See `06-for-you/HOW-APPS-ACTUALLY-WORK.md` §7
   for the three ways around that.
3. **Desktop third**, if there's appetite.

**Rejected:** Kotlin-native (best security primitives, but Android-only and you'd rewrite for
iOS — wrong for "all the stores"). React Native (weaker local-encryption and file-handling
story, more moving parts to secure). No-code builders (cannot do custom cryptography at all;
disqualified on the first requirement).

---

## ADR-005 — Days and folders are two views of one pile. ✅ DECIDED

See `03-product/DATA-MODEL.md` for the full model. The short version: there is one entity,
the **Entry**. Its timestamp puts it on a Day automatically; Days are never created by hand.
Filing an entry into a Folder is *tagging*, not moving — the entry stays on its day forever
and appears in the folder too.

This is the decision that makes *"recording things about a particular phase or particular
person"* work without building a second feature. A folder is a thread that accumulates across
years of days.

---

## ADR-006 — SQLCipher for the database, per-file encryption for attachments. ✅ DECIDED

Full reasoning in `02-security/SECURITY-ARCHITECTURE.md`. Summary:

- **Text, metadata, structure** → a SQLCipher database. Whole-file page-level AES-256. Critical
  benefit: because the app sees a normal decrypted SQLite database in memory, **full-text
  search still works** (SQLite FTS5). If instead we encrypted individual fields, search would
  be impossible and the app would be useless at year three.
- **Photos, voice notes, PDFs, documents** → stored as individual files, each with its own
  random key, encrypted in chunks so a 400 MB video can stream without loading into RAM. The
  per-file keys live in the (encrypted) database. Filenames on disk are random UUIDs; the real
  filename is encrypted metadata. **The filesystem leaks nothing — not a name, not a type.**

---

## ADR-007 — GPL-3.0, with an App Store exception. ✅ DECIDED

*Decided 18 August 2026, before commit one.*

Open-sourcing is non-negotiable for a privacy app: an unauditable privacy claim is just
marketing. But there is a specific trap here — **GPL-family licences conflict with Apple's App
Store terms** (this is the famous VLC removal). Publishing GPLv3 code and shipping it on the
App Store yourself requires adding an explicit exception.

**Decision: Option A from `05-shipping/OPEN-SOURCE-PLAN.md`** — GPL-3.0, plus an additional
permission under §7 granting the right to distribute through app stores under their standard
terms. The `LICENSE` file at the repo root carries both.

**Why the strong copyleft rather than the easy MPL-2.0:** for most software the trade is
adoption versus protection, and adoption usually wins. Here it doesn't. The specific bad
outcome we are guarding against is somebody forking this app, adding an analytics SDK, and
shipping "Lamplight Pro" with our design and our privacy language attached to a product that
phones home. GPL-3.0 makes that fork open too, so it would be visible. That is worth more to
this project than the extra adoption a permissive licence would buy.

**The "paperwork" the plan warned about turned out to be one paragraph**, so the low-friction
argument for MPL-2.0 didn't apply. The exception is not lawyer-reviewed and says so in the file.

**Supersedes:** the 🟡 LEANING status this record carried until 18 August 2026.

---

## ADR-008 — No security claims until an audit exists. ✅ DECIDED

We will describe the app as *"designed so that we cannot read your notes"* and publish the
threat model and the source. We will not write *"unbreakable"*, *"military-grade"*, *"as
secure as Signal"*, or *"NSA-proof"* in any store listing, screenshot, or post until an
independent cryptographer has reviewed the implementation.

This costs nothing and protects you from the worst outcome available to a privacy app: making
a loud claim, being wrong, and having someone demonstrate it publicly. Reputation in this
category is spent once.

---

## ADR-010 — The app is called Lamplight. ✅ DECIDED

*Decided 18 August 2026. Note this is permanent — see below.*

**Name: Lamplight.** **Package ID: `com.probablypiyush.lamplight`.** Display name: `Lamplight`.

The placeholder `Insights Pro` was correctly diagnosed in `OPEN-QUESTIONS.md` as sounding like
a B2B analytics dashboard. Lamplight was already the name of the design system, and it turns
out to satisfy every criterion that document set:

- It claims nothing about security, so it can't age into an embarrassment or a promise we
  can't back with an audit. `SecureVault` would have.
- It is a plain, ordinary word used as a proper noun — the pattern the document identified as
  strongest, and the one Bear, Things, Notion and Signal all use.
- It suggests *privacy through quietness* and *a private room at the end of the day*, which is
  what `00-vision/WHAT-WE-ARE-BUILDING.md` says the product actually is.
- Spellable after hearing it once. One word. No ambiguous letters.

**On the package ID:** reverse-domain form (`com.x.y`) is a naming *convention*, not a
requirement — nothing verifies that you own the domain, and no store checks. So this is not
tied to `paperseasons.co.in` or to any domain that could lapse. `com.probablypiyush.lamplight`
uses the handle rather than the legal name; Google Play displays the verified legal name as the
developer regardless, so this changes nothing about identity, only about the string.

**This string can never be changed after the first Play Store publication.** Changing it means
a new listing, and every install, review, and rating starts from zero.

**Still to do:** search the Indian and US trademark registries before publishing, and check
domain availability. Neither blocks Phase 1, and neither blocks a local repository — but both
must happen before the app is public.

---

## Decisions still open

See `01-decisions/OPEN-QUESTIONS.md`. With the name (ADR-010) and the licence (ADR-007) now
settled, nothing blocking remains. The unresolved ones are all Phase 2 or later: whether
plaintext export is allowed at all, whether past days stay editable, whether a duress passcode
is worth the risk, and monetisation.
