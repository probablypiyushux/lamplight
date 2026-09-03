# Phase 1 exit test — evidence

**Date:** 18 August 2026
**Device:** Vivo V2318, Android 16 (API 36), arm64
**Build:** `app-debug.apk`, package `com.probablypiyush.lamplight`

The exit test from `06-for-you/ROADMAP.md`:

> Write a note, force-kill the app, reopen it, unlock, and read it back.
> Nothing readable exists on disk.

Recorded here rather than in a chat log, because "we checked once" is worth nothing
in six months and this is the gate the whole phase was built to pass.

---

## Part 1 — write, kill, reopen, unlock, read back

**Performed by the maintainer on the physical device. Result: passed.**

Also confirmed on device: unlock by twelve-word recovery phrase, and lock-on-background.

An automated equivalent runs in `test/vault/vault_test.dart` — "the Phase 1 exit test, in
miniature" — which writes a note, locks, constructs an entirely new `Vault` over the same
files, unlocks and reads it back. That test guards the behaviour from now on; the manual
run is what proves it on real hardware.

---

## Part 2 — nothing readable on disk

Every file the app wrote to its private storage:

```
app_flutter/lamplight/vault.db      94208 bytes
app_flutter/lamplight/keyring.json    356 bytes
```

Nothing else. No WAL left behind after a clean close, no journal, no cache, no temp file.
(The other files under `app_flutter/` — `kernel_blob.bin`, the snapshot data — are
Flutter's own debug-build assets, not ours, and contain no user content.)

### `vault.db`

Pulled byte-exact with `adb exec-out` (plain `adb shell cat` mangles binary):

```
first 32 bytes:
  de 4b 82 fc bd 33 38 46 b3 e4 d6 a0 02 14 d2 b3
  3c 5a 12 48 e2 50 af 1a 35 12 9d 69 1e 96 47 df
```

A plain SQLite file begins `53 51 4c 69 74 65` — the ASCII for `SQLite`. This does not.

Searched the whole 94208 bytes:

| Looked for | Found |
|---|---|
| `SQLite` | 0 |
| `CREATE TABLE` | 0 |
| `entries` | 0 |
| `sqlite_master` | 0 |
| `fts5` | 0 |
| `lamplight` | 0 |
| `keyring` | 0 |

114 runs of six or more printable characters exist, which is expected — in 94 KB of
random bytes some ASCII appears by chance. Every one inspected was gibberish
(`t\cJg3{`, `"Go>xXu=`, `$A<iPQ`). **No table name, no column name, no SQL keyword and
no note text is present.** The schema itself is invisible, not merely the content.

### `keyring.json`

The one deliberately unencrypted file. Its entire contents:

```json
{"version":1,"kdf":"argon2id","salt":"N7oWQHaj0Ns+zq/5dB3zLQ==",
 "memLimit":134217728,"opsLimit":3,
 "passcode":{"nonce":"...","key":"..."},
 "recovery":{"nonce":"...","key":"..."}}
```

Nothing here is secret, and `lib/core/crypto/keyring.dart` explains why at length. The
wrapped keys are 32 bytes of noise without the passcode. The salt is not a secret. The
Argon2id parameters *must* be readable before unlocking, because the key cannot be derived
without them — every password-based format has this property, including age, LUKS and
Signal's own backups.

`memLimit` reads 134217728, which is 128 MiB, matching `SECURITY-ARCHITECTURE.md` §2a.

Editing any of it breaks the authentication tag on the wrapped key it belongs to, and the
vault refuses to open rather than opening weakly. That is the parameter-downgrade defence
in §4, and it has its own test.

---

## Still outstanding

- **Argon2id has not been timed on this phone.** 170 ms on the development laptop. The
  budget is the user's 500 ms–1 s, and if the phone comes in well under it the memory
  should be raised — unspent milliseconds are attacker cost we declined to charge.
- **Attachments were not exercised on device.** The store is covered by 24 tests on the
  laptop, but the debug screen has no button for it. Phase 2 adds real capture.
