# The ten languages

*Set up 28 August 2026. English, Spanish, Chinese (Simplified), Hindi, Arabic, Portuguese
(Brazil), German, French, Japanese, Korean.*

---

## Read this first if you are about to change a translation

**The machine translations in here are a starting point and I want to be blunt about
that.** They were written by me, not by a native speaker of nine languages, and this app's
value is unusually dependent on *tone*:

- `dayEmptyToday` is a **question**, not an instruction. Every language has a way to say
  *"Anything you want to keep?"* that sounds like an offer, and a way that sounds like
  homework. `ETHICAL-DESIGN.md` forbids the second and no test can tell them apart.
- `firstPagePromise` — *"None of it leaves this phone"* — is a **factual claim about the
  software**. It must stay exactly that strong and exactly that narrow. Not "your data is
  safe", not "we protect your privacy". Those are marketing; this is a fact.
- `folderAlsoIn` — the word **"also"** carries the entire folder model. A folder is a
  second place to find something, never a move. A translation that implies the entry left
  its day has misrepresented the app.
- `lockWrongPasscode` — *"That did not open the vault"* rather than "incorrect password".
  It says what happened instead of telling the person they are wrong.

**If you speak one of these languages, the most useful thing you can do is read the ten
strings above in your language and tell me whether they sound like a person or like a
form.** That is worth more than a hundred corrected articles.

---

## How it works

| | |
|---|---|
| **Where the words are** | `app_en.arb` is the template and the only file with `@`-metadata explaining intent. The other nine are translations. |
| **How they become code** | `flutter gen-l10n`, driven by `../../l10n.yaml`. Output lands in `generated/` **in the source tree**, deliberately — so a stranger auditing this app can read exactly what it says in every language without running a build. |
| **How a screen uses one** | `L.of(context).dayEmptyToday` |
| **Adding a language** | Drop in `app_xx.arb`. `supportedLocales` is generated from the files, and `kLanguages` in `features/settings/language_tile.dart` needs one row. `localisation_test.dart` fails if you do one and not the other. |
| **A missing key** | Falls back to English rather than failing the build. Nine languages will always be catching up with one, and a half-finished translation must never be why somebody cannot open their journal. |

---

## What the tests already hold, so you do not have to check it

`test/widget/localisation_test.dart`, 38 assertions:

- **No key missing from any language**, and none present that English does not have.
- **Every placeholder survives.** A dropped `{name}` gives *"Also in ."*, which reads as a
  bug about nothing.
- **Arabic has all six plural forms** — zero, one, two, few, many, other. A translator
  working from an English file will supply two, and the app then says the wrong thing for
  3, 11 and 100, which is most numbers.
- **The app name is never translated.** ADR-010.
- **The language list matches the locales that exist.**
- **No new hard-coded `left`/`right` padding.** See below.

---

## Right to left

Arabic mirrors the entire interface, and **Flutter does that on its own** — `MaterialApp`
resolves the locale's direction and wraps the tree in a `Directionality`, so every
`EdgeInsetsDirectional`, every `start`/`end` alignment and every `TextAlign.start` flips
without being asked.

**What does not flip is anything written as `left`/`right`.** That is the whole of the RTL
problem in this app, it is invisible in nine of the ten languages, and it is mechanical —
so it is a test rather than a habit.

The audit counted **77** hard-coded edges on the day it was written. `design/components.dart`
was converted immediately, because its seven were the padding of `LampTile`, `LampBanner`
and the sheet frame — most rows on most screens — so seven lines mirrored more of the app
than any other seven would have. **70 remain**, pinned as a ratchet that may only go down.

Converting is mechanical and changes nothing in the other nine languages:

```
EdgeInsets.only(left: x)        →  EdgeInsetsDirectional.only(start: x)
EdgeInsets.fromLTRB(a, b, c, d) →  EdgeInsetsDirectional.fromSTEB(a, b, c, d)
```

Worst first: `settings/appearance_screen.dart` (10), `search/search_screen.dart` (6),
`settings/settings_screen.dart` (5).

---

## Writing in these languages — which is a different thing entirely

**This has always worked and it is not what the language setting controls.** Somebody with
the app in English can write in Japanese; somebody with it in Arabic can write in English.
`settingsLanguageNote` says exactly that under the row, because it is the question people
actually have.

Two things had to be true for it to really work, and both are now:

1. **Search.** Until 28 August the query splitter was `[^\w]+`, and `\w` in Dart is
   ASCII-only even with the unicode flag — so every character of every non-Latin script
   counted as a separator, the words were thrown away, and a Hindi search returned
   *nothing*. That looked like an empty vault rather than a broken search. Fixed;
   `test/db/languages_test.dart`.
2. **Glyphs.** All ten bundled writing faces are Latin. (Fourteen until 29 August 2026;
   four near-duplicates were retired — see `design/typefaces.dart`.) Not one has a CJK or Arabic
   character in it. The engine usually falls through to the system font for a missing
   glyph — *usually* — and when it does not, the result is **tofu**: empty rectangles where
   somebody's diary entry was. `kScriptFallback` in `design/typefaces.dart` now names the
   Noto families explicitly, so it is a request rather than a hope.

**Still honestly imperfect:** Japanese and Chinese are written without spaces, so a run of
them is one search token. It matches when the whole run is typed and not when a word inside
it is. Fixing that needs a dictionary tokeniser, which is a real dependency and against
rule 4. Writing, storing, exporting and restoring those scripts all work.

---

## What is not translated

*Rewritten 31 August 2026, round fifteen. The previous version of this section
said **486 strings and 99.4%**, and listed three exceptions. A mechanical scan
of every string literal in `lib/` that looks like a sentence found around a
hundred more — the recorder, the album sheet, all three media viewers, the
calendar, the day, the trash, folders, four settings screens, backup, restore,
the readable copy and the importer each still held English of its own.*

**That is the useful lesson from it and it is this project's recurring one:
the 99.4% was arrived at by reading, and reading has been wrong every time.
`tool/audit_localisation.py` is the scan, it is checked in, and it is what any
future number in this file has to come from.**

**Everything drawn on a screen is now in all ten languages.** What is left is
five things, and each one is deliberate:

| | |
|---|---|
| `© 2026 Piyush Jain · Lamplight 0.5.x` | A name, a year and a version number. |
| `SIL Open Font License 1.1` | The actual name of a licence. Translating it would name a licence that does not exist. |
| `Chinese (Simplified)`, `Português (Brasil)` | Language names, in their own language. A person looking for their language needs to find it written the way they write it. |
| The failure report behind **Copy the details** | A bug report, addressed to whoever can read the stack trace beside it. Translating the word `Failure:` would help nobody and would make two copies of the same report incomparable. The *screen* around it is translated; the report is not. |
| ~~The messages inside `core/backup/`, `core/crypto/` and `core/db/`~~ | ✅ **Done, 31 August 2026.** They were the last English a person could see, and the worst place for it — the sentences shown when a backup or a restore fails. See below. |

### How `core/` came to speak ten languages without a `BuildContext`

**The problem, stated exactly.** These sentences are thrown from `core/`, which has no
context and must not grow one: `vault_file.dart` runs inside isolates, from background
paths, and from tests with no widget tree at all. `L.of(context)` was never available and
never will be.

**The answer is `Localisable` in `core/plain_words.dart`.** The exception carries *what went
wrong* as a key; the screen, which has a context, decides how to say it:

```dart
abstract interface class Localisable {
  String describeIn(L l);
}
```

Three enums implement it — `BackupProblem` (19 cases), `KeyringProblem` (2) and
`MnemonicProblem` (3) — plus `VaultTooNew`. `plainFailure` takes an optional `L` and prefers
`describeIn` when it has one.

**The English sentence stays on the exception too**, and that is not redundancy. It is what
the tests assert against, what `assert`s print, and the fallback for a caller with no `L` in
hand. Null falls back to English, which is the same rule the ARB files already follow.

`test/backup/failures_speak_your_language_test.dart` proves every case in every language,
that a detail — a filename, a count — is passed through untranslated, and that no two
problems say the same thing.

*One case is deliberately shared by seven throw sites: `damaged`. A person cannot act on
**which** header field failed to parse, and `UX-FLOWS.md` flow 6 asks for a distinct message
per case somebody can do something about rather than per branch.*

**Two classes take an `L` rather than holding words.** `SilentBackup` and
`TranscriptionQueue` both run on background paths where no context exists, and
both write one or two sentences of their own. The words are handed to them by
the first screen that has a context and are null until then; null falls back to
English, which is the same rule the ARB files already follow — *a half-finished
translation must never be why somebody cannot read what happened to their
backup.*

**Dates are localised too, and that is a separate job from words.** See
`dates.dart`: the twelve month names had been written out in **eight** places,
and translating them would still have produced *20 8月* in Japanese, because the
*order* differs. `intl` supplies both, plus the 12- or 24-hour clock and the
weekday letters. English resolves to `en_GB`, because CLDR's plain `en` writes
*August 20* and every date this app has ever drawn is *20 August*.

**And the type follows the script.** `scriptFallbackFor` reorders the CJK font
families by locale — a shared Han codepoint is drawn differently in each
language and the codepoint does not say which — and `lineHeightScaleFor` gives
Devanagari, Arabic and CJK the leading their marks need.

## What is still worth doing

**A native reader for each language.** Every translation here is mine. The
mechanical things are held by tests — no missing key, no dropped placeholder,
Arabic's six plural forms, the app name never translated — but no test can tell
whether `dayEmptyToday` sounds like an offer or like homework.

**If you speak one of these languages**, the most useful ten minutes you can
spend is reading the strings named at the top of this file in your language and
saying whether they sound like a person or like a form. That is worth more than
a hundred corrected articles.

