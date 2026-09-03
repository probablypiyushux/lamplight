# Writing down what was said

*ISSUE 15, round nine. Written 27 August 2026. This is the plain-language
version; the arguments live in `Transcribe.kt` and `core/platform/transcription.dart`.*

---

## What it does

Turn it on and Lamplight writes down what you said in your voice notes, so you
can **search for a voice note by what is in it** rather than by which day it was.

Settings → Your notes → **Write down what is said.**

It is **off** until you turn it on.

---

## Where the words are worked out

**On your phone. Nothing is sent anywhere.**

There are two ways it can happen and both are on the phone: Android's own
recogniser, which is already there, or a Whisper model you add yourself, which
is better. The rest of this section is about the first one; the Whisper part is
further down and is, if anything, easier to be sure about — that code runs
inside Lamplight itself rather than in another app, and
`tool/verify_no_sockets.sh` proves the compiled library cannot open a network
connection at all.

This is the part that mattered most and it is worth being exact about how it is
guaranteed, because "it's private" is what every app says.

Android has two speech recognisers:

| | |
|---|---|
| The ordinary one | On most phones it **uploads the audio** to Google and gets text back. |
| The on-device one | Added in Android 13, specifically so an app can insist the work happens on the phone. |

Lamplight uses **only the second one, and has no fallback to the first**. If your
phone does not have it, the setting does not appear at all — you will not see a
switch that quietly does something worse.

That is not a promise in a document. It is a different function call, and
`test/platform/transcription_stays_on_the_phone_test.dart` reads the code and
fails if anybody ever changes it — including if they change it as a *kindness*,
to make the feature work on an older phone. That is the shape the mistake would
take, and it is the one the test is watching for.

**Lamplight still has no internet permission.** That, on its own, would not have
been enough: the recogniser runs in a different app, with its own permissions,
and could have uploaded your diary without a single line of Lamplight's manifest
changing. Which is exactly why the guarantee had to be the function call.

---

## The one thing you should check yourself

Everything above is checkable by reading the code, and it is still worth ten
minutes with the phone in your hand, because it is your claim as much as mine:

1. Turn the setting on and record a voice note. Let it write itself down.
2. Put the phone in **aeroplane mode**. Wi-Fi off, mobile data off.
3. Record another one. Say something distinctive.
4. Wait a minute. Open the note.

**The words should appear exactly as before.** If they do, the audio never
needed a network, because there was not one.

It is in `05-shipping/RELEASE-CHECKLIST.md` so it does not get forgotten.

---

## What it cannot do, said plainly

### One language at a time — unless you add the better model

You wrote: *"remember people 99% of the time will speak multilingually — not
just one language!"*

You are right about people, and **Android's own recogniser cannot do it.** It
takes one language per recording, full stop. There is no multilingual mode to
ask for. So out of the box: one language, you choose it, and it starts as
whatever your phone is set to — Settings → Your notes → Language.

Then you asked about Whisper, and you were right about that too.

## Better transcription — the Whisper model

Settings → Your notes → **Better transcription.**

Whisper is a speech model whose weights are published openly. It runs entirely
on your phone, and it does the thing Android's recogniser cannot: **it works out
which language you are speaking, by itself, and it copes when you switch between
two in the same sentence.** *"Kal main office nahi gaya, I was completely wiped
out"* comes out as that, rather than as two attempts at one language.

**Why you have to fetch it yourself.** It needs a model file of a few hundred
megabytes, and **Lamplight cannot download it** — there is no internet permission
and there is not going to be one. That is not a limitation to work around; it is
the whole point of the app, showing up somewhere you can see it. So the row gives
you the link, you save the file in your browser, and then you pick it with the
same picker you use for documents. Once.

### Two of them, and which one to take

You asked for the choice — *"one which is 200mb or one which is 500mb"* — and the
row offers exactly those two. Both understand every language Whisper does; the
difference is how well and how fast.

| | Size | What it is for |
|---|---|---|
| **Good** | about **180 MB** | Hindi, English, both in one sentence. Roughly twice as slow as the recording is long. |
| **Best** | about **500 MB** | Noticeably better on strong accents, on quiet rooms and on background noise. Two or three times slower again, and it wants a phone with room to spare. |

Pick **Good** unless you have a reason not to. It is the one the row starts on,
and for most recordings the difference is small enough that the extra wait and
the extra 320 MB are not worth it.

**Only one is kept at a time.** Keeping both would cost 700 MB on your phone to
save one download, and this is the app that will not write a thumbnail to disk.
To swap, open the same row, choose **Change the level**, fetch the other file and
pick it. **The one you already have keeps working until the new one is in** — so
if the download fails or you change your mind halfway, nothing has been taken
away from you. That matters more here than anywhere else in the app: recovering
from it would need the internet, in an app that has none.

**The row tells you the exact filename to save.** The download page lists about
thirty files whose names differ by four characters, and picking the wrong one is
easy. If you come back with the other level, Lamplight opens it, recognises which
one it actually is, and says so — it works, it is just not the one you set out
for.

**What happens then.** Lamplight opens the file to check it really is a model
before keeping it — a half-finished download or the wrong file is refused and
deleted rather than kept to fail quietly later. If you accidentally pick one
whose name ends in `.en`, it will say so: those are English-only and smaller,
which makes them exactly the wrong choice here.

**It is slower.** A five-minute note might take five or ten minutes on the
phone's own processor, in the background, while you use the app. You said slower
output is not an issue when the output is better, and that is the trade being
made. It never blocks anything and it never has to finish — see below.

**You can remove it** at any time, from the same row. That frees the whole of it
and puts transcription back to Android's own, which still works.

**This is the engine, not an upgrade.** That sentence used to read the other way
round and it was wrong from 28 August, when you said *"remove whatever standard
you had — make the Whisper the base"*. Android's own recogniser is still there,
as a switch that is **off**, because it takes one language per session and
therefore cannot write down a sentence that changes language halfway — which is
the only thing you actually want from this. Without a Whisper model, there is no
transcription unless you turn that switch on.

### "Is there anything better than Whisper?" — 28 August 2026

Asked directly, after the transcripts came back poor: *"that can't even
understand mono lingual! and the standard one is waste as fuck! anything
better?"*

**Read the next paragraph before spending five hundred megabytes on a new
model.**

#### First: a bug in this app was making every model look bad

A voice note is recorded at 44.1 kHz. Both transcription paths dropped it to the
16 kHz that every speech model wants by **picking the nearest sample and
throwing the rest away**, with no filter in front of it.

That is not a loss of quality. It is **aliasing**: everything above 8 kHz does
not disappear, it folds back down into the middle of the speech band, where
nothing afterwards can tell it apart from something you said. A 10 kHz `s`
arrives as a 6 kHz tone sitting on top of your words.

And the band it lands in is exactly where the consonants are — `s`, `sh`, `f`,
`th`, and the aspirated and retroflex consonants that carry most of the
distinctions in Hindi. Vowels come through; consonants smear. What comes back is
words-shaped and wrong, which reads as *the model cannot understand a language*
rather than as *four lines above the model are broken*.

Fixed on 28 August — `Resample.kt`, a proper band-limited resampler.
`test/platform/resampling_test.dart` measures it: a 12 kHz tone that the old
code passed through at 0.5 RMS, at the wrong frequency, in the middle of the
speech band, now comes out below 0.05.

**So try it again before changing anything else.** This affects every recording
ever made, because the transcript is worked out from the stored audio each time.

#### Second: no, there is nothing better for what you want

The requirement is unusual and it narrows the field to almost nothing:
**on-device, no network ever, Hindi and English mixed inside one sentence.**

| | Why it does not help |
|---|---|
| **NVIDIA Parakeet** | Genuinely excellent, and English only. |
| **NVIDIA Canary** | Four European languages. No Hindi. |
| **SenseVoice-Small** | Fast and small, and covers Chinese, Cantonese, English, Japanese, Korean. No Hindi. |
| **Meta MMS** | Over a thousand languages including Hindi — but you choose the language per recording, which is the exact thing Android's recogniser already fails at. |
| **SeamlessM4T v2** | Very good and about 2.3 billion parameters. Not a phone. |
| **Vosk** | Offline, small, has a Hindi model, and is much less accurate. Built for commands, not for a diary. |
| **Gemini Nano, Apple's** | Not something this app can carry, and not something it can reach. |

**Whisper is the answer because it is the only one that was trained to
code-switch at all.** The upgrade path is a better *file*, not a different
project.

#### The file that is actually worth trying

**`ggml-large-v3-turbo-q5_0.bin`, about 550 MB.** It is `large-v3`'s full
encoder with a distilled four-layer decoder — roughly eight times faster than
`large-v3` and close to it in quality for transcription, in the **same size
class as the Best level you already have**. If any single change improves
Hinglish, it is this one.

It drops straight into what is already here. `whisper.cpp` reads it, the level is
recognised by the layer count the model reports rather than by its size, and no
code changes.

#### Two other things to try, both free

- **Say which language, instead of "auto".** Whisper detects the language
  **once**, from the first thirty seconds, and then decodes the whole recording
  as that. On a Hinglish note it commits early and leans that way for the rest.
  Setting it to `hi` or to `en` deliberately can be better than letting it
  guess, and which of the two is better is a question for your ear on your own
  voice. It is one parameter in `transcribe_jni.cpp`.
- **The recording itself is thin.** 32 kbps AAC at 44.1 kHz, chosen when the
  only consumer was a human ear and the priority was a quarter of a megabyte a
  minute. The model would be handed more to work with at a higher rate. **Not
  changed unilaterally** — it makes every future voice note bigger, and that is
  your decision rather than mine.

#### What is honestly still not possible

A model that reliably writes a code-switched sentence in the script each half
was spoken in — Devanagari for the Hindi, Latin for the English — does not exist
in a form that runs on a phone. Whisper will usually pick one script and
transliterate the rest. That is the state of the art, not a shortcoming here.

### It cannot run while the app is closed

You wrote *"take your time"* three times, and *"even if the app is closed"*.

The first part is honoured completely. The second one cannot be, and here is
why: reading a recording needs the key, the key only exists while Lamplight is
unlocked, and Lamplight locks the moment it goes into the background. That is
the rule the whole app is built on and it is not worth trading for this.

**What "take your time" buys instead is that it never has to finish.** The work
is resumable by design — Lamplight simply asks which recordings have no
transcript yet, does one, and asks again. Close the app halfway through and the
next time you open it, it carries on from the same place. There is nothing to
lose, so nothing is lost.

Which means: if you turn this on with a year of voice notes already recorded, it
will work through them over several sessions, quietly, while you use the app.
You do not have to wait for it or watch it.

### The first time in a language may need a download

If you pick a language your phone has never used, Android has to fetch the model
for it. **That is a download from Google, of a language model.** Nothing of
yours goes with it — not your recordings, not your notes, nothing. The row says
*"Not on this phone yet"* before you tap, so it is never a surprise.

Once it is on the phone, that language never needs a network again.

---

## Where the words show up

- **Under the voice note** — a small *"What was said"* row. Tap it to read.
  Nothing appears when there is no transcript, and nothing appears for a
  recording that genuinely had no speech in it.
- **In search** — type a word you said out loud and the note comes up, marked
  *said out loud* so you can see why it matched.

The transcript lives in the encrypted database like everything else. It is in
your backups. It comes out in a Readable copy.

---

## If it is wrong

It will sometimes be wrong. It is a small model running on a phone, and names,
places and anything half-heard are where it struggles.

**The recording is untouched.** The transcript is a way to *find* the note, not
a replacement for it — the sound of what you actually said is still exactly what
it was, and always will be.
