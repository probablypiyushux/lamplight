# Lamplight

**A private journal for Android. No account, no server, and no permission to reach the
internet.**

[![verify](https://github.com/probablypiyushux/lamplight/actions/workflows/verify.yml/badge.svg)](https://github.com/probablypiyushux/lamplight/actions/workflows/verify.yml)
[![licence](https://img.shields.io/badge/licence-GPL--3.0%20%2B%20app%20store%20exception-blue)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Android%208.0%2B-brightgreen)](#building-it-yourself)
[![tests](https://img.shields.io/badge/tests-1%2C512-brightgreen)](#building-it-yourself)

Write down your day — in words, your own voice, photographs, video, or documents. It is
kept on your phone, encrypted, organised by the day it happened. Nothing is uploaded,
because there is nowhere for it to go.

---

## Why this exists

Every journal app asks you to trust a promise. Lamplight is built so the promise can be
**checked instead of believed**.

The app declares no `INTERNET` permission. That is not a setting, a preference or a
policy — it is a line missing from the manifest of the file you install, and Android will
not let an app open a socket without it. Anyone holding the APK can confirm it in one
command, and the badge above runs that command against a real release build on every push:

```bash
aapt2 dump permissions app-release.apk
```

Everything else follows from that. There is no account to create, no password to reset, no
sync to configure, and no server that could be breached, subpoenaed or sold. If you lose
both your passcode and your recovery phrase, **your journal cannot be recovered** — by us
or by anyone. That is the honest consequence of the design rather than an oversight in it.

---

## What it does

| | |
|---|---|
| **Days, not files** | Entries live on the day they happened. A folder is a second way to find something, never a place it moves to. |
| **Everything, written down** | Text, voice notes with on-device transcription, photographs, video and documents — each with a viewer built in. |
| **Encrypted before it touches the disk** | Voice is recorded *into a pipe*: ciphertext before it reaches any filesystem. There is no plaintext temporary file to recover. |
| **A way out** | Export the whole vault as readable Markdown plus the original files, whenever you like. It is your journal, not our format. |
| **A way back in** | A `.vault` backup opens with your passcode *or* with your twelve-word recovery phrase. |
| **Ten languages** | English, हिन्दी, Español, Français, Deutsch, Português, 日本語, 한국어, 中文, العربية — asked as the very first question. |
| **Built to be read** | Ten writing faces, three themes, six accents, and a page that can be plain, paper, lamplit, or the real night sky turning at the sidereal rate. |

---

## The claims, and how to check them yourself

This is the part that matters. Each row is a claim, and the command beside it is how a
stranger settles it without trusting anybody.

| Claim | How you check it |
|---|---|
| The app cannot reach the network | `aapt2 dump permissions app-release.apk` — no `INTERNET` |
| …and no dependency slipped it back in | `tool/verify_no_internet.sh` reads the **built artefact**, not the source |
| No bundled native library opens a socket | `tool/verify_no_sockets.sh` lists every symbol each `.so` imports |
| The running app holds no connections | `adb shell cat /proc/net/tcp` while it is open |
| Screenshots are blocked by default | `adb shell screencap` returns a black frame |
| It is signed by the key it claims | `apksigner verify --print-certs`, against [`05-shipping/FINGERPRINT.md`](05-shipping/FINGERPRINT.md) |

**What this project does not claim.** Not "unbreakable", not "military-grade", not "as
secure as Signal". The honest sentence is the one the app itself uses: *designed so that we
cannot read your notes*. A `.vault` file is XChaCha20-Poly1305 under a key that exists only
in that file, wrapped by two secrets that exist only in your head. No engineer can promise
more than that truthfully, and the day this project says otherwise, none of its other
claims are worth reading.

---

## How it is built

**Flutter and Dart**, one Android target, minSdk 26, targetSdk 36. Kotlin at the platform
edges for what Flutter cannot reach — the camera, MediaStore, PDF rendering, the speech
recogniser. **There is no C or C++ in the tree.**

Cryptography goes through a single directory, `app/lib/core/crypto/`, deliberately kept
small enough for an auditor to read in an afternoon. No feature code ever touches a raw
key.

| Purpose | Primitive |
|---|---|
| Passcode → key | **Argon2id**, m = 128 MiB, t = 3, p = 1 |
| Key wrapping, database, attachments | **XChaCha20-Poly1305** |
| Attachments at rest | 64 KiB chunked frames — a 500 MB video is never whole in RAM |
| Subkeys | libsodium `crypto_kdf`, domain-separated |
| Whole-file integrity | **BLAKE2b-256** |

The full design — including what it deliberately does *not* defend against — is in
[`02-security/SECURITY-ARCHITECTURE.md`](02-security/SECURITY-ARCHITECTURE.md) and
[`02-security/THREAT-MODEL.md`](02-security/THREAT-MODEL.md).

**The permissions it declares**, in full: `RECORD_AUDIO` for voice notes, `USE_BIOMETRIC`
and `USE_FINGERPRINT` for unlocking, and `POST_NOTIFICATIONS` with
`RECEIVE_BOOT_COMPLETED` for the optional daily reminder. That is the whole list.

---

## Building it yourself

```bash
git clone https://github.com/probablypiyushux/lamplight.git
cd lamplight/app
flutter pub get
flutter build apk --release
```

A release build signed with your own key installs and runs with no further setup. There is
no API key to obtain, no service to register and no configuration file to fill in, because
there is nothing for the app to connect to.

To run the checks the badge runs:

```bash
flutter analyze && flutter test
tool/verify_no_internet.sh
tool/verify_no_sockets.sh
```

**1,512 tests.** They cover the crypto round-trips, the backup format across three reader
versions, interrupted writes, database migrations from v1 through v5, and a scan that reads
the disk after every import path looking for plaintext.
[`BUILDING.md`](BUILDING.md) has the detail.

---

## The thinking, kept in the open

Unusually for a repository, the decisions live here too — not as documentation written
afterwards, but as the specification the code was written from.

| | |
|---|---|
| [`01-decisions/DECISIONS.md`](01-decisions/DECISIONS.md) | Every architectural decision, and its reasoning |
| [`02-security/THREAT-MODEL.md`](02-security/THREAT-MODEL.md) | Who this defends against, and who it cannot |
| [`03-product/DATA-MODEL.md`](03-product/DATA-MODEL.md) | Days, entries, folders, and the schema |
| [`04-technical/BACKUP-FILE-FORMAT.md`](04-technical/BACKUP-FILE-FORMAT.md) | The `.vault` specification |
| [`08-design/DESIGN-SYSTEM.md`](08-design/DESIGN-SYSTEM.md) | Palette, type, spacing, components |
| [`08-design/ETHICAL-DESIGN.md`](08-design/ETHICAL-DESIGN.md) | No dark patterns, written down as a rule |
| [`08-design/ACCESSIBILITY.md`](08-design/ACCESSIBILITY.md) | WCAG AA targets, and how they are checked |
| [`03-product/UX-FLOWS.md`](03-product/UX-FLOWS.md) | Every screen, first launch to restore |

These are not written after the fact. Where a decision was reversed, the reversal and its
reasoning are in the document rather than in a commit message nobody will find — including
the ones that turned out to be wrong.

---

## Status

**Version 0.5.3.** Feature-complete, and in preparation for a Google Play closed test.
Not yet on the Play Store.

Bug reports and questions are welcome in
[Issues](https://github.com/probablypiyushux/lamplight/issues). Please do not paste
anything from your own journal into one — see [`SECURITY.md`](SECURITY.md).

---

## Licence

**GPL-3.0, with an App Store exception** — see [`LICENSE`](LICENSE). The exception exists
because plain GPL-3.0 is incompatible with Apple's App Store terms, which would rule out an
iOS release later. The reasoning is in
``05-shipping/OPEN-SOURCE-PLAN.md``.
