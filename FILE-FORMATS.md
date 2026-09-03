# What Lamplight opens — the short answer

> **ISSUE 3, 24 August 2026.** *"What kind of files open in Lamplight and what doesn't. Write it
> somewhere so I don't need to ask you this every time."* And then, when I offered to put it inside
> the app: *"Not inside the app! Just somewhere else in the folder so I can know!"*
>
> So it is here, at the top of the project, in plain language. The long technical version — which
> formats map to which decoder, and what each refusal would cost in dependencies — is
> `04-technical/DOCUMENT-FORMATS.md`.

---

## The one-sentence answer

**Every file can be kept, and every file can be opened.** The only question is *where* it opens:
inside Lamplight, or in another app that Lamplight hands it to and then takes back.

That second half is new as of 24 August 2026 (ISSUE 4 and 13). Before it, a file Lamplight could not
draw was a dead end.

---

## Opens inside Lamplight, without ever touching your disk

These are decrypted into memory, drawn on screen, and forgotten when you close them. Nothing is
written out, not even briefly.

| What | Formats |
|---|---|
| **Photos** | jpg · jpeg · png · webp · gif · bmp · heic · heif · avif |
| **PDFs** | pdf — including pinch-zoom, which re-renders the page rather than magnifying it |
| **Text of any kind** | txt · md · markdown · csv · tsv · json · xml · yaml · yml · ini · log · conf · srt · html · htm · rtf · vcf · ics |
| **Voice and audio** | wav · m4a · mp3 · aac · opus · ogg — these go to the voice player, with a waveform |
| **Video** | mp4 · mov · mkv · avi · 3gp · webm — these go to the video player |

## Opens in another app, borrowed and returned

| What | Formats |
|---|---|
| **Office files** | docx · doc · xlsx · xls · pptx · ppt |
| **Archives** | zip · rar · 7z |
| **Books** | epub |
| **Drawings** | svg |
| **Anything else at all** | any extension, including ones nobody has heard of |

**Why these do not open inside.** Each would need someone else's code added to Lamplight to read it
— an Office parser, an archive library, effectively a small web browser for epub. Rule 4 in
`CLAUDE.md` is that any package added to this app can read *all* of your notes, so a parser for
spreadsheets is a very large risk for a small feature. That is the whole reason, and it is about
risk rather than effort.

---

## "Open with…" — what actually happens

It is on **every** file, whatever the format, in the three-dot menu at the top right of any viewer.

1. Lamplight decrypts the file into a private folder that no other app can see or list.
2. Android shows you the list of apps that can open it. **You** pick one.
3. That one app — and nothing else on the phone — is given permission to read that one file.
4. The moment you come back to Lamplight, the permission is taken back and the file is overwritten
   with zeroes and deleted.

It is also cleaned up if the vault locks while you are away, and again the next time you open the
app, in case the phone killed Lamplight while you were reading.

**This is the only place in the whole app where your content exists unencrypted on disk**, and it
exists there for as long as you are looking at it. You approved that trade on 24 August 2026 on
exactly those terms, and `test/storage/nothing_is_left_behind_test.dart` is the test that proves the
last step happens — it reads the disk afterwards and searches for the file's actual contents, not
just its name.

## "Save a copy" — the other option, and the heavier one

Still there, in the same menu. The difference:

|  | Open with… | Save a copy |
|---|---|---|
| Where it goes | A private folder only the app you chose can read | Wherever you choose — Downloads, Drive, anywhere |
| How long it lasts | Until you come back to Lamplight | Forever, until you delete it |
| Who can read it | One app, once | Anything on your phone that can read files |

Open with is the lighter one, so it is listed first. Save a copy is for when you actually want to
keep a copy, and it asks once before it does it.

---

## Things worth knowing

- **Not opening is not the same as not supporting.** Every format encrypts into the vault, travels
  inside the `.vault` backup, and comes back intact — including the ones Lamplight cannot draw.
- **A file with no extension, or a type Android cannot identify**, is still kept. Lamplight guesses
  from the name when the type is missing, and offers "Open with…" regardless.
- **If nothing on your phone can open a format**, Lamplight says so in a sentence rather than
  showing you an empty chooser.
- **APKs are kept but never installed.** An APK is a program, not a document. Lamplight will hold
  one and hand it back and that is all it will honestly do.

---

*If this file and the app ever disagree, the app is right and this file is out of date — tell me and
I will fix it. The function that actually decides is `opensInLamplight()` in
`app/lib/features/media/document_viewer.dart`, and `test/media/document_kind_test.dart` holds the
two together.*
