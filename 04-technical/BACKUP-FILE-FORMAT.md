# The `.vault` backup file format

**Freeze this before you ship v1.** Backups made by version 1 must open in version 9, in
2035, on a phone that doesn't exist yet. The single most common failure in file formats is
shipping without a version field and then being unable to change anything.

Extension: **`.vault`** (candidates: `.vlt`, `.locked`, or the app's own name once decided).
Registered as an app-handled MIME type so tapping it on a new phone offers **Restore**.

---

## Design goals, in priority order

1. **Confidential.** Reveals nothing without the passcode. Not a filename, not an entry count.
2. **Tamper-evident.** Any modification is detected. A wrong key fails loudly; it never
   returns plausible garbage.
3. **Streamable.** A 5 GB vault backs up and restores without loading into RAM.
4. **Verifiable.** Corruption is detected before restore begins, not halfway through.
5. **Versioned.** Forwards- and backwards-readable.
6. **Self-contained.** One file, no companions, no manifest to lose.
7. **Recoverable in principle.** With the spec and the passcode, someone can write their own
   decryptor in 2040 even if this project is long dead. **This is a promise no cloud service
   can make.**

---

## Layout

```
┌─────────────────────────────────────────────────────────────┐
│ MAGIC        8 bytes   "VAULT\x01\x00\x00"                  │  cleartext
│ HEADER_LEN   4 bytes   uint32 LE                            │
├─────────────────────────────────────────────────────────────┤
│ HEADER       CBOR, cleartext but AUTHENTICATED              │
│   format_version   uint                                     │
│   kdf              "argon2id"                               │
│   kdf_salt         16 bytes                                 │
│   kdf_memory_kib   uint      (e.g. 131072 = 128 MiB)        │
│   kdf_iterations   uint      (e.g. 3)                       │
│   kdf_parallelism  uint      (1 — see SECURITY-ARCH §2a)    │
│   cipher           "xchacha20poly1305"                      │
│   chunk_size       uint      (65536)                        │
│   compression      "zstd" | "none"                          │
│   created_at       ISO-8601                                 │
│   app_version      string                                   │
│   backup_id        UUID                                     │
│   recovery         bool     (v2+; absent means false)       │
├─────────────────────────────────────────────────────────────┤
│ WRAPPED_DEK  nonce(24) ‖ ciphertext(32) ‖ tag(16)           │
│              AAD = the full HEADER bytes                    │
│              KEK = Argon2id(passcode, kdf_salt)             │
├─────────────────────────────────────────────────────────────┤
│ WRAPPED_DEK_R  nonce(24) ‖ ciphertext(32) ‖ tag(16)         │  v2+, and
│              present iff header.recovery == true            │  only then
│              AAD = the full HEADER bytes                    │
│              KEK = BLAKE2b("lamplight:recovery" ‖ entropy)  │
├─────────────────────────────────────────────────────────────┤
│ BODY         sequence of encrypted chunks                   │
│              each: len(4) ‖ nonce(24) ‖ ciphertext ‖ tag(16)│
│              plaintext = zstd(inner stream)                 │
├─────────────────────────────────────────────────────────────┤
│ FOOTER       total_chunks(8) ‖ blake2b256(everything above) │
└─────────────────────────────────────────────────────────────┘
```

### The inner stream (what's inside BODY once decrypted)

A tar-like sequence — length-prefixed records, no filesystem semantics needed:

```
  manifest.cbor          schema version, counts, integrity hashes per member
  vault.db               the full SQLCipher database
  attachments/<uuid>     each attachment, still individually encrypted
  attachments/<uuid>
  ...
```

Attachments stay in their per-file encrypted form and get encrypted *again* by the backup
layer. Slightly redundant, deliberately so: it means the restore path is a plain copy rather
than a decrypt-then-re-encrypt cycle, which is faster, uses no scratch space, and — most
importantly — **removes any moment where plaintext exists on disk during a restore.**

---

## Decisions inside the format, and why

**Why the header is cleartext.** You need the KDF parameters *before* you can derive the key —
that's unavoidable in any password-based format. It's the standard approach (age, LUKS,
Signal's own backups all do it). The header is **authenticated as AAD** on the wrapped DEK, so
it cannot be tampered with — an attacker can't downgrade `kdf_memory_kib` to 1 to make brute
force cheap, because that change breaks the tag.

**Why no entry count in the header.** Tempting for a nice UI ("Restore 3,847 entries?") and a
metadata leak. Someone with the file learns how much you've written. It goes in the *encrypted*
manifest instead, and the pre-restore screen just says "Verifying…" until it can read it.

**Why compress before encrypting.** Ciphertext is incompressible by definition, so it's the
only order that works. Watch the CRIME/BREACH class of compression-oracle attacks — they
require an attacker who can inject chosen plaintext and observe sizes, which is not our threat
model (there's no network and no adversary-controlled input). Safe here; note it so a future
reader knows it was considered rather than missed.

**Why chunked rather than one big AEAD.** RAM. A single 5 GB AEAD would need 5 GB of memory
and couldn't be verified until fully read. Chunks let us stream, resume, and report progress.
The trade-off is chunk reordering/truncation attacks — handled by binding the chunk index into
each nonce and storing `total_chunks` in the authenticated footer.

**Why no password verifier.** There's no stored hash to check the passcode against. The only
way to test a guess is to run the full Argon2id and attempt the unwrap. This removes a cheap
oracle for offline attacks — an attacker must pay the full memory-hard cost per guess.

**Why a `backup_id`.** Lets the app recognise a re-import of the same backup and de-duplicate
rather than doubling every entry. Also lets it detect a *partial* previous restore and resume.

---

## Creating a backup

1. Confirm passcode. (Deliberate act — this file unlocks everything.)
2. Fresh random salt. Derive KEK. Generate a **fresh random DEK for this backup** — not the
   vault's DEK. Compromising one backup must not compromise the vault or other backups.
3. Wrap it, write the header.
4. Checkpoint the WAL, snapshot the database, stream through: compress → encrypt → write.
5. Write the footer.
6. **VERIFY: reopen the file and decrypt it end to end.** If this fails, delete the file and
   report failure. **Never** report success on an unverified backup.
7. Hand to the system share sheet.

## Restoring

1. Read magic + header. Reject unknown `format_version` with a clear message.
2. Passcode → Argon2id (using the file's stored params) → unwrap DEK. Tag failure = wrong passcode.
3. Verify the BLAKE2b footer hash **before importing anything**. Corrupt file → refuse cleanly.
4. Stream chunks → decompress → write members into a *staging* directory.
5. Validate the manifest and every member hash.
6. **Atomically swap** staging into place. Never a half-restored vault.
7. Report counts, open today.

---

## v2 — the recovery phrase opens the file. ISSUE 17, 24 August 2026

> *"Backup phrase is only able to open the app! I want that phrase to open the backup (.vault)
> file. Backup phrase should also be able to open the backup file (.vault)."*

**The problem he found is real and it is worse than an inconvenience.** The twelve words were
sold to him — correctly — as the thing that gets you back in when the passcode is gone. But
they only opened the *app on this phone*. If the phone was lost, the words were useless: the
only copy of his life was a `.vault` file that could be opened by a passcode he had, by
definition, forgotten. The recovery phrase recovered the one thing that did not need
recovering.

### What v2 adds

**A second wrapper of the same file key**, and nothing else. The body, the chunking, the
footer, the manifest and the passcode wrapper are byte-for-byte what they were.

- `header.recovery: true` says the second wrapper is present.
- `WRAPPED_DEK_R` follows `WRAPPED_DEK` immediately, at the same fixed size (72 bytes), so
  `BODY` starts 72 bytes later than in v1. A reader computes this from the header rather than
  guessing.
- The KEK is derived exactly as the on-device recovery wrapper's is —
  `BLAKE2b-256("lamplight:recovery" ‖ entropy)`, no Argon2id — and for the same reason:
  the input is already 128 bits of CSPRNG output, and Argon2id exists to make *guessable*
  inputs expensive. See SECURITY-ARCHITECTURE.md §2b, which this deliberately reuses rather
  than inventing a second derivation for the same secret.
- Both wrappers authenticate the **same** header as AAD, so the KDF parameters cannot be
  rewritten under either one.

### What this costs, stated plainly

**The file is now only as strong as the weaker of two secrets.** That was already true on the
device — the keyring has had both wrappers since ADR-003 — but it was not true of the backup
file, and it is worth writing down rather than discovering later.

It is the correct trade here, and the reason is that the alternative is not "a stronger file",
it is **"a file nobody can open"**. A backup that only the passcode opens is a backup that is
lost exactly when it is needed, and the threat model's most likely bad day is a lost phone,
not a cryptanalyst.

The phrase is 128 bits of full-strength entropy. A passcode is whatever the user typed. In
practice the recovery wrapper is the *stronger* of the two.

### Backwards and forwards

- **v1 files still open**, with the passcode, forever. `header.recovery` is absent, the reader
  sees no second wrapper, and `BODY` starts where it always did. Every version's reader stays
  in the codebase permanently — that rule is below and it is not negotiable.
- **A v2 file made by a vault with no recovery phrase** writes `recovery: false` and no second
  wrapper. It is a v1 file in all but the version number.
- **A v1 reader given a v2 file** refuses it by version, with the "update the app" message,
  rather than reading past the second wrapper and producing garbage.

### What is deliberately NOT claimed

He wrote: *"also make it confirm that .vault file is the most safest file for my app! nobody in
the whole world able to decrypt this other than Lamplight app"*.

The first half is built. The second half is a sentence `CLAUDE.md` rule 10 forbids, and the
prohibition is right: no honest engineer can promise nobody in the world can break a cipher.
What is true and is worth more than the slogan: **the file is encrypted with XChaCha20-Poly1305
under a key that exists only inside this file, wrapped by two keys that exist only in the
user's head.** Lamplight has no copy, there is no server to ask, and the format is written down
here so that in ten years somebody can still open it with the words. The app says "designed so
that we cannot read your notes", and that is the strongest claim it is entitled to make.

---

## Format versioning rules

- `format_version` bumps only on breaking changes.
- Every version's reader stays in the codebase **forever**. Reading v1 in 2035 is a promise.
- Additive fields go in the CBOR header/manifest and are ignored by older readers.
- **The spec lives in the public repo alongside the code**, permanently, so the format outlives
  the project. That is what makes "your data is yours" a fact rather than a slogan.

---

## Open questions on the format

- **Size padding?** Round the file up to a bucket (nearest 64 MB) so an observer of your Drive
  can't infer how much you write. Costs disk. Probably a v2 setting.
- **Split volumes?** For a 20 GB vault on FAT32 media (4 GB file limit). Probably v2.
- **Incremental backups?** Much more convenient, considerably more complex, and a whole new
  class of "the chain is broken" failure. Full-only for v1 is the right call.
