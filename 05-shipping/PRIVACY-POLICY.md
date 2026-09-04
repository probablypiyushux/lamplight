---
layout: default
title: Privacy policy
permalink: /privacy/
---

<!-- The four lines above are not decoration and must not be tidied
     away. Jekyll only renders a Markdown file that carries front
     matter, and `permalink` is the URL Google's reviewer opens. A
     sync overwrote this file with a copy that had none on 4
     September 2026, and the policy URL returned 404 for the ten
     minutes it took to notice -- which is the single thing that
     blocks the store listing. It lives here now so a copy in either
     direction carries it. -->

# Privacy policy

**Lamplight**
Last updated: 31 August 2026

---

## The short version

**Lamplight collects nothing. It sends nothing. There is no account, no server, and
no way for the app to reach the internet at all.**

Everything you write, photograph, record or file lives on your phone, encrypted, and
goes nowhere else unless you deliberately move it there yourself.

---

## Who this is

Lamplight is made by **Piyush Jain**, working alone, in India.
Contact: **piyushjain9486669328@gmail.com**

There is no company, no investor and no third party involved in the app.

---

## What data Lamplight collects

**None.**

Not "none that identifies you". Not "only anonymous usage data". None.

There is no analytics, no telemetry, no crash reporting, no advertising identifier,
no attribution SDK, no A/B testing framework, and no third-party software
development kit of any kind inside the app.

---

## What Lamplight stores, and where

Everything you put into Lamplight is stored **on your device only**:

- what you write
- photographs, videos, voice notes and documents you add
- the names you give days and folders
- your settings

All of it is encrypted on the device with **XChaCha20-Poly1305**, under a key
derived from your passcode using **Argon2id**. The key exists only while the app is
unlocked and is destroyed when it locks.

Your passcode is never stored anywhere. It cannot be recovered, by us or by anyone.
That is why the app gives you a twelve-word recovery phrase when you first set it
up, and asks you to write it down.

**Nothing is uploaded, backed up to a cloud, or synchronised. There is nowhere for
it to go.**

---

## How you can check that, rather than believe it

This is the part that matters, and it is why this policy is shorter than most.

**Lamplight does not declare the `INTERNET` permission.** On Android, an app can
only open a network connection if it declares that permission in its manifest, and
the permission list is visible to you:

> **Settings → Apps → Lamplight → Permissions**, or the *Permissions* section of the
> app's Google Play listing.

The only permissions Lamplight declares are:

| Permission | What it is for |
|---|---|
| `RECORD_AUDIO` | Voice notes. Asked for the first time you tap record, never at launch. |
| `POST_NOTIFICATIONS` | The optional daily reminder to write, if you turn it on. |
| `RECEIVE_BOOT_COMPLETED` | So that reminder survives your phone restarting. |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | Unlocking with your fingerprint, if you turn it on. |

`INTERNET` is not on that list. An app without it cannot send your data anywhere,
whatever its code says and whoever wrote it. **You do not have to trust this
document. You can check the list.**

The source code is public, and the release build is verified on every change by two
automated checks that read the permissions and the compiled libraries out of the
finished app rather than out of the source.

---

## Voice notes and transcription

If you turn on transcription, voice notes are written down **by Android's own
on-device speech recogniser**, running on your phone.

Lamplight specifically requests the *on-device* recogniser
(`createOnDeviceSpeechRecognizer`) and has no fallback to a network one. Your
recordings do not leave the device to be transcribed.

---

## When something leaves your phone, it is because you moved it

Four things in the app hand a file to somewhere else, and all four are actions you
take deliberately:

- **Create backup file** — writes one encrypted `.vault` file to a location you
  choose. It is locked with your passcode and is unreadable without it. Where you
  then keep it is your choice; if you put it on a cloud drive, that drive's privacy
  policy applies to the file, not this one.
- **Readable copy** — writes your journal out as plain Markdown and your original
  files, into a folder you choose. **This copy is not encrypted.** The app says so
  on the screen before you do it, and the folder it writes contains a README saying
  it again.
- **Save a copy** / **Open with** — hands one file to another app you pick from the
  system chooser.
- **Links** — tapping a web address you wrote asks Android to open it in your
  browser. Lamplight does not fetch it; it hands over the address.

Everything on that list is something you asked for, one item at a time.

---

## Children

Lamplight is not directed at children and does not knowingly collect information
from anyone, of any age, because it does not collect information.

---

## Deleting your data

There is no account to delete and no server holding anything.

To remove everything: **Settings → Delete everything**, which erases the vault and
its keys, or uninstall the app. Both remove all of it from the device permanently.

Because nothing is ever collected or transmitted, there is nothing held elsewhere
that could be requested or deleted.

---

## Your rights under data protection law

Under India's **Digital Personal Data Protection Act 2023**, the **GDPR**, and
comparable laws elsewhere, the rights you have — access, correction, deletion,
portability, objection — apply to a party that processes your personal data.

**Lamplight does not process your personal data.** It never receives it. There is
no data controller and no processor, because there is no transfer.

Portability is worth naming anyway, because it is the one right people most often
find is theoretical: **Readable copy** writes your entire journal out as plain
Markdown, openable in any text editor, on any computer, forever, with or without
this app. That is portability by construction rather than by request form.

---

## Changes to this policy

If this policy ever changes, the change will be published here with a new date, and
the change history is public in the app's source repository — so you can see not
just what it says now but what it used to say and when it changed.

**If Lamplight ever begins collecting anything, this document will say so plainly
and the `INTERNET` permission will appear in the app's permission list. Watch the
permission list rather than this page. It cannot be softened by wording.**

---

## Contact

**piyushjain9486669328@gmail.com**
