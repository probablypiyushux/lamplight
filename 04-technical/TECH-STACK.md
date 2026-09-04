# Tech stack

**Framework: Flutter (Dart).** Reasoning in `01-decisions/DECISIONS.md` → ADR-004.

**Rule for this file:** every dependency is a package that can read all of the user's notes.
A supply-chain compromise in any one of them defeats the entire security architecture. So:
**fewer packages is a security property.** Every addition needs a written justification here,
and a look at its maintainer, its release history, and its own dependency tree.

---

## Core

| Purpose | Package | Notes |
|---|---|---|
| Encrypted database | `drift` + `sqlite3` | Drift gives type-safe queries, generated code, and clean migrations — which matters enormously when you're not a coder and the schema changes 40 times. `sqlite3` 3.x now bundles the native library itself and selects a SQLCipher build via `hooks`. **The `sqlcipher_flutter_libs` named in the first draft is end-of-life — see below** |
| Crypto primitives | `sodium` | **libsodium.** Argon2id, XChaCha20-Poly1305, BLAKE2b-256, `secretstream` for chunked files. One audited C library, compiled from source at build time. Argon2id is in the *sumo* API: `SodiumSumoInit.init()`, synchronous in v4. Justified at length below |
| HKDF-SHA256 | **no package — ~30 lines of our own** | libsodium has no HKDF. RFC 5869 is genuinely short, and writing it over libsodium's HMAC-SHA256 is a smaller risk than adding a whole dependency for it. Verified against the RFC's own test vectors |
| Secure key storage | `flutter_secure_storage` | Android Keystore / iOS Keychain wrapper |
| Biometrics | `local_auth` | Fingerprint / Face |
| State management | `riverpod` | Testable, compile-safe, no magic |
| Routing | `go_router` | Official, declarative |
| Recovery phrase | **no package — our own** | `bip39` is unmaintained since 2021 and drags in `pointycastle`, `hex` and `crypto`: four packages in the most sensitive path in the app. BIP-39 is a frozen spec and an *encoding*, not a cipher. We implement it and prove it against the official test vectors |
| Compression | `archive` or zstd bindings | Compress **before** encrypt, per chunk |

### Justification: why libsodium and not `cryptography` ⭐

*Decided 18 August 2026. This supersedes the original entry naming `cryptography` /
`cryptography_flutter`, and it is the only place this stack deviates from the first draft.*

Four reasons, in order of weight:

1. **Speed, and it is not a nicety.** `cryptography` is pure Dart. Dart is a fine language and
   a poor one for grinding bytes. Attachments are encrypted in 64 KiB chunks, and
   `03-product/FEATURES-IN-AND-OUT.md` projects ~4 GB of photos and voice per year — a pure-Dart
   cipher turns importing a video into a visible wait. libsodium is C, compiled, and roughly an
   order of magnitude faster on exactly this work.
2. **Argon2id must be fast to be strong.** The security budget is "~500ms–1s of the user's
   time." Every millisecond wasted on a slow implementation is memory-hardness we could have
   bought and didn't. Native speed converts directly into attacker cost.
3. **Fewer libraries, and the one we keep is the most examined in existence.** This file's own
   rule is that fewer packages is a security property. libsodium covers Argon2id,
   XChaCha20-Poly1305, BLAKE2b and HMAC-SHA256 from a single audited C codebase used by Signal,
   WireGuard and most of the field. `01-decisions/DECISIONS.md` → ADR-004 already named
   "libsodium bindings for the modern ciphers" as a reason to choose Flutter, so this is the
   stack the decision log expected.
4. **`cryptography_flutter` would not have rescued it.** It accelerates AES and a few key
   exchanges through platform APIs. It does not accelerate Argon2id, which is the operation
   where the slowness matters most.

**What it costs us:** libsodium's Argon2id is single-threaded, so the documented `p=4` is
unreachable. `02-security/SECURITY-ARCHITECTURE.md` §2a records the parameter change and why
raising memory to 128 MiB more than compensates. That is a real deviation from the first draft
and it is written down rather than absorbed quietly.

**What the checklist turned up when it was actually run.**

- ✅ `sodium` 4.x exposes everything we need, but **Argon2id lives in the "sumo" API**, so the
      entry point is `SodiumSumoInit.init()` rather than `SodiumInit.init()`, and it is
      **synchronous** in v4. Easy to get wrong; noted here so nobody rediscovers it.
- ⚠️ **`sodium_libs` is discontinued**, folded into `sodium` itself. Removed. That is the third
      package in this file that died between the spec being written and the code being started.
- ⚠️ **v4 no longer ships prebuilt binaries. It compiles libsodium from source** through Dart
      build hooks, which means a working C toolchain is now a build requirement on every
      machine that touches this project. See "Build prerequisites" below — this was a genuine
      surprise and it is the reason `flutter doctor`'s Visual Studio warning turned out to
      matter after all.
- ✅ Dependency tree is clean: no telemetry, no HTTP client, nothing surprising.

**A better primitive than the spec assumed.** libsodium exposes `crypto_secretstream`, which is
precisely the chunked-file construction `02-security/SECURITY-ARCHITECTURE.md` §6 describes
building by hand — per-chunk authentication, automatic nonce handling, and an explicit final-chunk
tag so truncation is detected. Use it rather than reimplementing it. The spec's own rule is that
we are not going to be clever, and hand-rolling a framing format when the library ships one is
exactly the kind of clever it means.

**Fallback, if libsodium ever becomes untenable:** `cryptography` for the ciphers plus
`dargon2_flutter` for Argon2id. Worse on speed and on package count, so it is a fallback and
not a preference — recorded so the reasoning is not lost, not because it is expected.

---

### Justification: the database packages changed under us ⚠️

*Discovered 18 August 2026, while clearing the checklist above.*

**`sqlcipher_flutter_libs` is end-of-life.** Its own pub.dev description now reads
*"Not used anymore, update to version 3.x of package:sqlite3 instead"*. So is
`sqlite3_flutter_libs`. This is not abandonment — it is consolidation by the same
maintainer who writes `drift` — but the first draft of this file named a dead package, and
anything built on it would have started on sand.

**The replacement:** `sqlite3` 3.x bundles prebuilt native SQLite for Android, iOS, macOS,
Linux and Windows, and selects which *build* to bundle through Dart's new `hooks` mechanism
in `pubspec.yaml`. Three builds are offered: plain SQLite, SQLCipher, and SQLite3MultipleCiphers.

**Decision: `source: sqlcipher`.** ADR-006 names SQLCipher, `02-security/SECURITY-ARCHITECTURE.md`
opens by insisting we will not be clever, and the replacement package offers SQLCipher
directly. Taking the option the specification already chose is the boring move, and boring
is the stated policy.

The alternative considered was SQLite3MultipleCiphers, which tracks upstream SQLite more
closely and avoids an OpenSSL dependency. It was rejected for now on the "not clever" rule,
but it is a real fallback rather than a dismissed one — see the trigger below.

**Two costs that come with the SQLCipher build, both documented upstream:**

1. It links **OpenSSL** on Android, Windows and Linux. That is a large dependency with a long
   CVE history, and we do not control which version ships. It is also what Signal's Android
   client does, which is the precedent ADR-006 leans on.
2. It **may lag the upstream SQLite version** used by the other builds.

**Switch to `source: sqlite3mc` if any of these turn out to be true** — decided by test, not
by preference. **All three were measured on 18 August 2026 and none of them hold:**

- [x] ~~FTS5 unavailable or crippled~~ — **works.** `CREATE VIRTUAL TABLE … USING fts5` and a
      `MATCH` query both succeed. Asserted in `test/stack_verification_test.dart`.
- [x] ~~The bundled SQLite is too old~~ — **it is not.** The build reports
      **SQLite 3.53.3 with SQLCipher 4.17.0 community**. That is current, so the documented
      "the SQLCipher build may lag upstream" caveat did not materialise here. Re-check this
      whenever `sqlite3` is upgraded; it is a real risk that simply has not bitten yet.
- [x] ~~OpenSSL makes the APK unreasonable~~ — **it does not.** A single-ABI arm64 release APK
      with libsodium and SQLCipher compiled in is **19.9 MB**. For comparison, the empty
      Flutter app before any of this was 41 MB across four ABIs.

**Verified in the same run:** the database file contains no plaintext (a known marker string
is absent from the bytes on disk), it does not carry the plain `SQLite format 3` header, a
wrong key fails loudly rather than returning garbage, and WAL mode enables on an encrypted
database. That last one matters because `SECURITY-ARCHITECTURE.md` §7 leans on WAL for
autosave crash-safety.

**Decision holds: `source: sqlcipher`.** Nothing found so far argues for switching.

**A useful property either way:** SQLite3MultipleCiphers can read and write the SQLCipher
on-disk format. So choosing SQLCipher now does not trap us — the format stays readable by
both, which matters for `04-technical/BACKUP-FILE-FORMAT.md`'s promise that someone can
decrypt a vault in 2040 with the spec and the passcode.

**Not needed any more:** `sqlcipher_flutter_libs`, `sqlite3_flutter_libs`. Do not add either.
`sqlite3` now carries the binaries itself. One fewer package, which this file counts as a
security property.

---

## Media

| Purpose | Package | Notes |
|---|---|---|
| Audio recording | `record` | Must support **streaming to a sink** so we encrypt chunks as they arrive rather than writing a plaintext file first — this is a hard requirement, verify it early |
| Audio playback | `just_audio` | Needs a custom source that decrypts on the fly |
| Camera | `camera` | Direct capture, bytes in memory → encrypt → write |
| Gallery / file import | `file_picker`, `image_picker` | **Both hand you plaintext temp files. Scrub them after import — write a test for this** |
| PDF preview | `pdfrx` or `syncfusion_flutter_pdfviewer` | Must render from bytes, never from a plaintext path on disk |
| Image handling | `image` | Thumbnails generated in memory only |

### Justification: whisper.cpp, the only native code in the project ⭐

*Added 27 August 2026, round nine, ISSUE 15. `CLAUDE.md` rule 4 requires the argument to be
written here, and this is the biggest dependency in the project, so here it is at length.*

| | |
|---|---|
| What | `whisper.cpp` v1.7.4, CPU backend only, **vendored** into `app/android/app/src/main/cpp/whisper/` |
| Size | ~2.6 MB of C and C++ in the repository; **6.7 MB** added to the release APK |
| Licence | MIT. The text travels with it at `cpp/whisper/LICENSE`; the exact upstream commit is in `cpp/whisper/VERSION` |
| Why not a package | There is no Flutter package for this that does not either bundle a model or fetch one over a network |

**What it buys, and it is not a nicety.** Android's own on-device recogniser — which the app
also uses, and which needs nothing at all — takes **one** BCP-47 language tag per session.
Piyush's sentence about this is the whole case: *"remember people 99% of the time will speak
multilingually — not just one language!"* He is right, and a Hindi sentence with English words
in it comes back mangled from a recogniser that has been told to expect Hindi. Whisper detects
the language itself and handles code-switching. There is no other way to get that on a phone
with no network.

**What was left out, deliberately.** Only `ggml`'s CPU backend is compiled. Not CUDA, Vulkan,
Metal, SYCL, OpenCL, CANN, Kompute, BLAS — and critically **not the RPC backend**, which is the
one piece of ggml that opens sockets. `llamafile/sgemm.cpp` is also out: it needs ARMv8.2
instructions that would crash the Snapdragon 680 in his Redmi Pad, and nothing calls it because
`GGML_USE_LLAMAFILE` is undefined.

**How that is checked rather than asserted.** `tool/verify_no_sockets.sh` reads the *shipped*
`.so` out of the APK and lists every function it imports from outside itself. A library that
does not import `socket`, `connect` or `getaddrinfo` **cannot** call them. 212 imports, none of
them networking. Run it beside `verify_no_internet.sh` on every release — the two together
cover both halves, because a permission check says nothing about native code and a symbol check
says nothing about the manifest.

**Against rule 4's actual question** — *what does this cost, given that every dependency can
read all of the user's notes?* Four answers:

1. It is **vendored, not fetched**, so a build is reproducible and an auditor can diff the
   files against upstream rather than trusting a version range.
2. It is **narrow**: the JNI bridge in `transcribe_jni.cpp` is under 200 lines and is the only
   C++ written for this project. Open a model, hand it samples, read text back, close it.
3. The audio it sees **never touches a disk** and never leaves the process — which makes it
   *more* private than the alternative, not less. Android's recogniser is a service in another
   app that we cannot audit and that has a network-using sibling one function call away.
4. It is **optional twice over**: no native library (a 32-bit phone) and no imported model both
   mean the feature falls back to Android's recogniser, which needs nothing.

**The model is not in the APK.** Piyush's decision, asked and answered on 27 August: the user
downloads one file in a browser and imports it with the ordinary picker. That keeps the APK its
own size and — the part that actually matters — **Lamplight still cannot download anything**,
so rule 1 is untouched. See `lib/core/platform/whisper.dart` and
`03-product/HOW-TRANSCRIPTION-WORKS.md`.

**`arm64-v8a` only.** Every Android phone made since about 2017 is 64-bit ARM and both of his
are. Each extra ABI is another copy of a megabyte of compiled ggml. A 32-bit phone still runs
the app; the library is simply absent and `Whisper.available` is false.

---

## Localisation

| Purpose | Package | Notes |
|---|---|---|
| Material's own translated strings | `flutter_localizations` | Ships with Flutter. Carries the words *we* do not write — Cancel, the date picker, the text field's Cut/Copy/Paste menu |
| Date, number and plural formatting per locale | `intl` | Published by the Dart team. Already in the tree as a dependency of the above; naming it is what lets our own code call `DateFormat` |

### Justification: two packages, and rule 4's question has an easy answer

*Added 28 August 2026. `CLAUDE.md` rule 4 requires the argument to be written here for
every package, and this is the shortest one in the file.*

**The question rule 4 actually asks is "what can this read?"** Every package added can, in
principle, read all of the user's notes — that is why the list is five long and why each
one has a paragraph. These two are different in kind:

- **They are not third-party.** `flutter_localizations` ships inside the Flutter SDK;
  `intl` is published by the Dart team and is already in the tree as a transitive
  dependency of it. Adding them widens the trusted set by **nobody**.
- **They never see a note.** `flutter_localizations` reads ARB files at build time and a
  locale at run time. `intl` formats dates and numbers. Neither touches the vault, the
  database or an attachment, and neither can — they are given a `Locale` and a number.
- **The alternative is worse on rule 4's own terms.** The third-party localisation
  packages (`easy_localization`, `slang`) load translations at run time from assets or —
  in some configurations — from a **network**, which this app does not have and must never
  appear to want.

**And `flutter_localizations` is not optional in practice.** Without it the app speaks
Spanish while every system dialog says "Cancel", the date picker stays in English, and the
text selection menu never changes at all. That half-done state is worse than English
throughout, because it looks like carelessness rather than like a limit.

**What is deliberately NOT added:** any translation-management service, any string
extraction tool that phones home, and any package that fetches locales at run time. The
ARB files are in the repository, the generated Dart is in the repository, and a stranger
can read exactly what the app says in every language without running anything. That is the
same argument as publishing the source. See `app/lib/l10n/README.md`.

---

## Explicitly NOT used

Not an oversight — a decision:

- ❌ **Firebase, in any form.** Analytics, Crashlytics, Auth, Firestore. All of it phones home.
- ❌ **Any analytics or attribution SDK.** Zero telemetry means zero.
- ❌ **Any crash-reporting service.** A stack trace can contain user content.
- ❌ **Any ad SDK.**
- ❌ **Any HTTP client.** We don't need one, and its absence is provable — in Dart by reading
  the dependencies, and in the one native library by `tool/verify_no_sockets.sh`, which lists
  every function it imports and finds no `socket` among them.
- ❌ **`shared_preferences` for anything sensitive.** It's an unencrypted plist/XML file.
- ❌ **`path_provider` temp directories for plaintext.** Ever.

**And the big one:** v1 declares **no `INTERNET` permission** in `AndroidManifest.xml`. This
is the strongest privacy claim available to any Android app, because anyone can verify it in
thirty seconds by decompiling the APK. Protect this property. If a future feature requires
the network, that is a serious architectural decision, not a shrug.

---

## Project shape

```
lib/
  core/
    crypto/        key derivation, wrapping, chunked stream cipher
    storage/       encrypted attachment store
    db/            drift schema, migrations, DAOs
    vault/         lock/unlock state machine, key lifecycle
  features/
    onboarding/    passcode, recovery phrase, profile
    day/           the daily stream — the home screen
    explorer/      folder tree
    capture/       text, voice, photo, file
    search/
    backup/        export + restore
    settings/
  design/          colours, type, spacing, components
test/
  crypto/          ← the most important tests in the project
  backup/          ← round-trip, corruption, interruption
integration_test/
```

**Rule:** nothing in `features/` ever touches raw keys. All crypto goes through `core/crypto`,
which is small, heavily tested, and the only thing an auditor really has to read closely.

---

## Testing, and why it matters more here than in a normal app

For most apps, a bug means an annoyed user. Here, a bug in the wrong place means someone's
four-year record is permanently unreadable. So:

1. **Crypto round-trip tests** — encrypt/decrypt every type, every size, empty, 1 byte,
   1 GB. Wrong key must fail. Tampered ciphertext must fail. Truncated file must fail.
2. **Backup round-trip tests** — export → wipe → import → assert byte-identical. With 10,000
   entries. With a 2 GB vault. With multibyte text, emoji, RTL scripts.
3. **Corruption tests** — flip a random bit in a backup, assert it's *detected and refused*,
   never silently half-restored.
4. **Interruption tests** — kill the process mid-backup, mid-restore, mid-record. Assert no
   corruption, no plaintext residue.
5. **Plaintext-leak tests** — after every import path, scan the app's storage and temp
   directories for known plaintext markers. Automate this. It's the test that catches the
   mistake everyone makes.
6. **Migration tests** — every schema version must upgrade from every previous one, on a
   real database with real data.

Claude Code writes all of these. **Ask for them.** A non-coder's best defence against
invisible breakage is a test suite that shouts.

---

## Build & release

- **Git from commit one.** Everything in version control, keystores excluded.
- **GitHub Actions:** run tests on every push; build a signed release on tag. Free.
- **`flutter build appbundle --release`** → `.aab` for Play. Also publish a `.apk` on GitHub
  Releases so people can install without the Play Store (privacy-minded users care about this,
  and it's free goodwill).
- **Enrol in Play App Signing.** Back up the upload keystore in two places off your laptop.
- **Reproducible builds** — a long-term goal. It's the only way to *prove* the published APK
  matches the published source. Hard, but it's what separates "open source" from "verifiably
  open source", and it's the thing that would let you truly stand next to Signal.
