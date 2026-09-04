# Document formats — what opens inside Lamplight, and what does not

> **ISSUE 12, round five, 23 August 2026.** Piyush wrote out twenty-eight formats and asked
> for two things: *"make a list which can be opened and which can't be opened"*, and for the
> ones that cannot, *"before opening them, give them a soft warning that this makes it
> visible to other apps."*
>
> This is that list. The code that decides it is `kindOf` in
> `app/lib/features/media/document_viewer.dart`, and `opensInLamplight(mime, name)` answers
> the question in one call. **If this document and that function disagree, the function is
> right and this document is a bug** — `test/media/document_kind_test.dart` holds them
> together.

---

## Opens inside Lamplight ✅

Nothing here is ever written to disk unencrypted. It is decrypted into memory, drawn, and
forgotten when the screen closes.

| Group | Formats | How |
|---|---|---|
| **Pictures** | `jpg` `jpeg` `png` `webp` `gif` `bmp` `heic` `heif` `avif` | Flutter's decoder, falling back to Android's `ImageDecoder` for the HEIF family. GIFs animate. |
| **Documents** | `pdf` | Android's own `PdfRenderer`, over a proxy file descriptor served from memory — see `MemoryPdf.kt`. Pinch-zoom re-renders the page rather than magnifying it (ISSUE I). |
| **Text** | `txt` `md` `markdown` `csv` `tsv` `json` `xml` `yaml` `yml` `ini` `log` `conf` `srt` | Shown in the user's own writing face, selectable. Headed lines get a little more weight; nothing else is interpreted. |
| **Text, added in round five** | `html` `htm` `rtf` `vcf` `ics` | All of these are text with a particular shape, and the text is the useful part in a journal — a contact card is a name and a number, and reading it beats being told to go elsewhere. Not *rendered* as HTML; shown as source. |
| **Sound** | `wav` `m4a` `mp3` `aac` `opus` `ogg` | Never reaches this screen. `AttachmentImporter.typeForMime` routes audio to the voice player, which streams it decrypted through a pipe. |
| **Video** | `mp4` `mov` `mkv` `avi` `3gp` `webm` | Never reaches this screen either — the video player takes it. What the phone can actually decode is ISSUE 3's question, not this one. |

## Does not open inside Lamplight ❌

Every one of these needs a **third-party parser**, and `CLAUDE.md` rule 4 is that any package
added to this app can read all of the user's notes. That is the whole reason, and it is a
reason about risk rather than about effort.

| Formats | What it would cost |
|---|---|
| `docx` `doc` `xlsx` `xls` `pptx` `ppt` | An Office parser. The largest dependency on the list by a wide margin, to read a file type most journals never contain. |
| `zip` `rar` `7z` | An archive library. `rar` and `7z` additionally have no usable pure-Dart reader at all. |
| `epub` | A zip container plus an XHTML renderer — effectively a small browser. |
| `svg` | Not a bitmap. Neither Skia nor Android will decode one; rendering needs a package. This is why SVG is the one *picture* on the refusal list. |
| `apk` | Nothing to show. An APK is a program, not a document; Lamplight will keep one safely and hand it back, and that is all it can honestly do. |

**These can still be kept, backed up, restored and shared out.** Not opening is not the same
as not supporting — every one of them encrypts into the vault like anything else, travels in
the `.vault` backup, and comes back intact.

---

## The soft warning

Anything on the ❌ list offers *Save a copy*, and that now interrupts once before it happens:

> **This leaves Lamplight**
> The copy is written out in the clear, so any app that can read your files can read it.
> What is kept inside Lamplight stays encrypted either way.
> — *Keep it here* · *Save a copy*

Three things about it are deliberate:

- **The safe answer is the plain one.** *Keep it here* is in secondary ink; the action that
  hands the file out has to be chosen.
- **It is soft, and that word is doing work.** `ETHICAL-DESIGN.md` forbids frightening people
  out of things they have every right to do. This is their own file. No red, no warning
  triangle, no "are you sure?" — one fact they may not have thought of, at the moment it
  becomes true.
- **It says what stays safe as well as what does not.** A warning that only lists the danger
  reads as the app disclaiming responsibility.

---

## "Open in another app" now exists — ISSUE 4 and 13, 24 August 2026

**This section used to say the opposite.** It read *"There is no 'open in another app' button"*,
and explained that a true open-in-place would need a `FileProvider` directory and a read grant, and
that the plaintext would sit on disk for as long as the other app was reading it — a real exception
to `CLAUDE.md` rule 2, and Piyush's to make.

He made it, on 24 August 2026, having been shown the trade. His words: *"a way the user doesn't
download the file but is able to view this in another app which supports viewing the file format"*,
and *"I want it on every file type/format"*. The terms he approved were quoted back to him: a
private FileProvider folder, a one-time read to the chosen app, deletion the moment Lamplight is in
front again, and a test proving nothing is left behind.

The implementation is `app/lib/core/platform/hand_off.dart` and `HandOff.kt`. What it does:

| Step | What happens |
|---|---|
| 1 | The file is decrypted into `cache/handoff/` — app-private, in no media store, not listable by anything |
| 2 | Android shows a **chooser**, every time, never a remembered default |
| 3 | `FLAG_GRANT_READ_URI_PERMISSION` goes to the one app the user picked. Never write |
| 4 | On resume, the grant is revoked and the file is overwritten with zeroes and deleted |
| 5 | Also on vault lock, and swept at next launch if the process was killed mid-loan |

`test/storage/nothing_is_left_behind_test.dart` is the assertion the exception rests on. It reads
the disk and searches for the file's **content** rather than its name, because a file renamed or
truncated but not overwritten is still somebody's document in a cache. If that test ever fails, the
feature comes out rather than being argued about.

**The ❌ list below is now about where a file opens, not whether it opens.** Everything on it opens
in another app, one tap away, on every format.

---

## The plain-language version

`FILE-FORMATS.md`, at the root of the repo, because ISSUE 3 was *"write it somewhere so I don't need
to ask you this every time"* and then *"not inside the app! just somewhere else in the folder so I
can know!"*. This document is the technical one; that one is the answer.
