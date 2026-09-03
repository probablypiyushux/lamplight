# Security architecture

The actual cryptographic design. Technical, but read it — this is the part you are asking
people to trust, so you should be able to explain it in your own words.

**Golden rule of this document:** we use boring, standard, well-tested primitives, combined
in the boring standard way. Every serious cryptographic failure in a consumer app comes from
someone being clever. We are not going to be clever.

---

## 1. The key hierarchy

The central idea: **the data is encrypted with one key, and that key is itself encrypted
several times over, once for each way you're allowed to unlock it.**

```
              ┌──────────────────────────────────────────┐
              │  DEK — Data Encryption Key (256-bit)     │
              │  random, generated once at first launch  │
              │  NEVER stored in plaintext anywhere      │
              └──────────────────────────────────────────┘
                    ▲            ▲             ▲
        wrapped by  │            │             │
        ┌───────────┴──┐  ┌──────┴───────┐  ┌──┴──────────────┐
        │  Passcode    │  │  Recovery    │  │  Biometric      │
        │  ↓ Argon2id  │  │  12 words    │  │  key in Secure  │
        │  → KEK-P     │  │  ↓ HKDF      │  │  Enclave /      │
        │              │  │  → KEK-R     │  │  StrongBox      │
        └──────────────┘  └──────────────┘  └─────────────────┘
```

Three sealed envelopes, each containing the same key, each openable a different way.

**Why this shape and not the obvious one?** The obvious design is "derive the encryption key
straight from the passcode." It's simpler and it's a mistake, because then:
- Changing your passcode means **re-encrypting every byte you have ever written**. With four
  years of photos that's a twenty-minute operation that can be interrupted and corrupt everything.
- You cannot have two ways in (passcode *and* recovery phrase) without two copies of all data.

With key wrapping, changing the passcode rewraps **one 32-byte key**. It's instant, atomic,
and cannot half-fail. This is the standard design — it is how full-disk encryption works.

---

## 2. The primitives, and why each one

| Job | Algorithm | Why this one |
|---|---|---|
| Passcode → key | **Argon2id**, m=128 MiB, t=3, **p=1** | Winner of the Password Hashing Competition. *Memory-hard*, so a GPU/ASIC farm can't parallelise it cheaply — this is what makes a 6-digit PIN survive an offline attack. Tune params per device so it takes ~500ms–1s on the target phone. Store the params in the header so future devices can still open old vaults. **`p=1`, not `p=4` as originally drafted — see §2a.** |
| Key wrapping | **XChaCha20-Poly1305** | Authenticated encryption — decryption *fails loudly* on a wrong key or tampering rather than returning garbage. 192-bit nonce means random nonces will never collide, which removes an entire class of catastrophic implementation bug. |
| Database at rest | **SQLCipher** (AES-256-CBC, page-level, HMAC per page) | Battle-tested for 15 years, used by Signal itself. Page-level means random access stays fast. |
| Attachments at rest | **XChaCha20-Poly1305**, 64 KiB chunked frames | Streaming: a 500 MB video encrypts and decrypts without ever being fully in RAM. Per-chunk auth tags mean corruption is localised and detected. |
| Deriving subkeys | **HKDF-SHA256** | Standard way to turn one key into many domain-separated keys. Never reuse a key for two purposes. |
| Recovery phrase | **BIP-39**, 12 words / 128 bits | Battle-tested wordlist designed so words are unambiguous, unique in their first 4 letters, and hard to mishear. Do not invent your own wordlist. |
| Whole-file integrity | **BLAKE2b-256** | Fast, modern, no length-extension weirdness. |
| Randomness | **OS CSPRNG only** (`SecureRandom` / `/dev/urandom` / `SecRandomCopyBytes`) | Never `Random()`. Never a seeded PRNG. This is the single most common fatal mistake in amateur crypto — if the randomness is predictable, everything else is theatre. |

**None of these are exotic.** Every one is a default recommendation in libsodium or a
platform library. That is the point.

---

## 2a. Why Argon2id parallelism is 1, not 4

*Added 18 August 2026, before any code was written. The first draft of this document said
`p=4`; this section records why it doesn't any more.*

We build on **libsodium**, and libsodium's Argon2id is deliberately single-threaded — its
`crypto_pwhash` fixes the number of lanes at 1 and exposes no way to change it. So `p=4` is
simply not reachable without bolting a second, far less scrutinised cryptographic library
alongside it, which `04-technical/TECH-STACK.md` is right to resist. Two crypto libraries is
two supply chains, and the smaller one would be the weak link.

**Dropping to `p=1` while raising memory is not a downgrade.** What actually costs an attacker
money is **peak memory per guess** — that is the number deciding whether a guessing rig can be
built cheaply out of massively parallel hardware, because memory is the resource GPUs and ASICs
cannot conjure. Lanes and passes mostly trade against the *defender's* wall-clock time. Going
from `m=64 MiB, p=4` to `m=128 MiB, p=1` **doubles** what an attacker must commit to every
single guess. We pay for it by doing that work on one thread instead of four.

**The ceiling on `m` is the user's cheapest plausible phone, not our ambition.** A 2 GB-RAM
Android device cannot allocate 256 MiB inside a foreground app without risking an
out-of-memory kill. Worse, `kdf_memory_kib` travels *inside the vault header and inside every
backup file* — so a vault created on a good phone must still open on a bad one, years later,
possibly during a restore after that good phone died. Choosing this number too aggressively
turns a security setting into a data-loss bug.

**So the number is set by measurement on real hardware, not by preference.** 128 MiB / t=3 is
the working target.

**First measurement, 18 August 2026:** `m=128 MiB, t=3, p=1` takes **170 ms** on the
development laptop (libsodium 1.0.21). A mid-range phone is typically two to four times slower
on memory-bound work, which projects to roughly 350–700 ms — inside the target window, with
room to raise memory if the phone turns out faster than expected.

**Still to do:** measure on the actual device before this is final. The laptop figure is a
sanity check, not the answer — the budget is the *user's* second, and the user is holding a
phone. If the phone lands well under 500 ms, raise `m` until it doesn't, because every
millisecond left unspent is attacker cost we declined to charge.

---

## 2b. Subkey derivation: `crypto_kdf`, not HKDF-SHA256

*Changed 18 August 2026.*

§2 specifies **HKDF-SHA256** for turning the DEK into domain-separated subkeys, and §3 step 7
uses it as `HKDF(DEK, "db")`. We use libsodium's **`crypto_kdf`** instead.

**Why.** The Dart binding for libsodium does not expose HMAC-SHA256 — its `crypto_auth` is
HMAC-SHA512-256, a different function. Implementing HKDF-SHA256 would therefore have meant
either adding a second cryptographic dependency or hand-writing HMAC, and §2's opening rule is
that we do not get clever with primitives.

`crypto_kdf` is libsodium's purpose-built answer to exactly this problem: derive many
independent subkeys from one master key, with an 8-byte context string and a numeric subkey
id providing the domain separation. It is BLAKE2b-based, which is a hash this design already
depends on for whole-file integrity, so it adds no new primitive to the trust surface.

**What is unchanged:** the property that actually matters. Each subsystem gets a key that is
independent of every other, and none of them can be worked backwards to the DEK. If the
database key is ever compromised, it does not hand over the attachment keys or the master key.
Domain separation was the requirement; HKDF was one way to spell it.

---

## 3. First launch, step by step

1. Read 32 bytes from the OS CSPRNG → this is the **DEK**. It will never be seen again in
   plaintext outside of RAM.
2. User sets a passcode. Generate a random 16-byte salt. `Argon2id(passcode, salt)` → **KEK-P**.
3. `XChaCha20-Poly1305(DEK, key=KEK-P)` → store the wrapped blob + salt + Argon2 params.
4. Read 16 bytes of entropy → encode as a **12-word BIP-39 phrase**. Show it once. Take the
   raw entropy → `HKDF` → **KEK-R** → wrap the DEK a second time and store it.
5. Discard the phrase from memory. **It is never stored.**
6. If the user enables biometrics: generate a key inside Android Keystore (`setUserAuthenticationRequired(true)`,
   StrongBox where available) or the iOS Secure Enclave, wrap the DEK a third time with it.
   Set `setInvalidatedByBiometricEnrollment(true)` so adding a new fingerprint destroys this
   wrapper — otherwise someone who can add their own fingerprint to the phone gets in.
7. `HKDF(DEK, "db")` → the SQLCipher key. Create the database.

Note step 7: the database key is *derived from* the DEK, not the DEK itself. Domain
separation. If one subsystem is ever broken, it doesn't hand over the master key.

---

## 4. Unlocking

1. User enters the passcode.
2. `Argon2id` with the stored salt and params → candidate KEK-P.
3. Attempt to unwrap the DEK. **If the Poly1305 tag fails, the passcode was wrong.**

That third line matters more than it looks. We are **not** storing a hash of the passcode to
compare against. There is nothing on the device that can be tested against a password list
except the actual encrypted key. There is no "password verifier" field for an attacker to
attack cheaply — the only way to test a guess is to run the full Argon2id and try the unwrap.

**Rate limiting:** exponential backoff on failures (1s, 2s, 4s, 8s… capped at 5 min), enforced
against a monotonic clock so changing the system time doesn't reset it. Optional user setting:
**wipe the vault after N failed attempts**, default off, with an unmissable warning.

---

## 5. The database

- **SQLCipher**, keyed with `HKDF(DEK, "db")`, 256-bit.
- **WAL mode** for crash safety — a power loss mid-write cannot corrupt the database.
- **FTS5 full-text search** over note text.

That last point is why SQLCipher rather than encrypting individual fields. SQLCipher decrypts
transparently at the page level, so from SQLite's point of view it is an ordinary database and
every feature works — indexes, joins, full-text search. If we encrypted field-by-field instead,
search would be impossible without loading and decrypting every note in the vault, and by year
three with 5,000 entries the app would be unusable. **Searchability is a feature we would lose
forever if we got this decision wrong**, so it is worth understanding.

---

## 6. Attachments — photos, voice, PDFs, documents

Each attachment:
1. Gets a random 256-bit **file key** and a random UUID.
2. Is encrypted in **64 KiB chunks**, each with XChaCha20-Poly1305 and a nonce derived from
   a random file nonce plus the chunk index. The final chunk is flagged, so truncating the
   file is detected rather than silently accepted.
3. Is written to disk as `attachments/<uuid>.enc`. **No extension hint. No real name.**
4. Its file key, true filename, MIME type, and dimensions are stored as columns in the
   encrypted database.

**Consequence, and it's a good one:** someone browsing the app's storage directory sees a
flat pile of identically-shaped random-named blobs. They cannot tell a voice note from a
photo from a tax PDF. They cannot count how many are photos. The filesystem layout itself
leaks nothing.

**Thumbnails** are generated in memory and encrypted with the same scheme into a separate
cache table. Never, ever written as plaintext JPEGs — this is the most common way "encrypted"
gallery apps leak everything, and forensic tools look for exactly this.

**The temp-file trap:** when you import a PDF or pick a photo, the OS hands you a file in a
shared temp directory, in plaintext. Our import routine must: copy → encrypt → **overwrite
and delete the temp file** → verify it's gone. Similarly, voice recording must write encrypted
chunks *as it records*, never a plaintext `.m4a` that gets encrypted afterwards. This is a
real, specific implementation requirement and it needs a test.

---

## 7. Autosave, without losing data or leaking it

You said: *"The thing he does Autosaves even if he forgets to save!"* Here's how.

- **Text:** keystrokes go to an in-memory buffer. Flushed to the encrypted database on a
  400ms debounce, and *immediately* on every lifecycle event — app backgrounded, screen off,
  navigation away, incoming call. WAL mode means the write is atomic; a crash mid-write loses
  nothing. Worst case the user loses 400ms of typing.
- **Voice:** encrypted chunks are written continuously during recording. A crash or a battery
  death loses at most the final 64 KiB (a second or two), and the partial recording is still
  playable because each chunk is independently authenticated.
- **Photos/files:** encrypted and committed on import, before the UI reports success.
- **Revision history:** keep the last ~20 versions of each text entry, plus a rolling daily
  snapshot. Cheap in storage, and it means "I accidentally deleted a paragraph" is recoverable.
  For an app whose promise is *a record of your life*, this is not a nice-to-have.
- **Deletion:** entries go to a Trash for 30 days, then are securely purged — the row deleted,
  the attachment file overwritten and unlinked, and `VACUUM` run so the pages are actually
  reclaimed rather than left in free space.

---

## 8. Key handling in memory

- The DEK lives in RAM only while unlocked. Zeroed on lock, on background, on timeout.
- Never logged. Never in a crash report — there are no crash reports.
- Never placed in a Dart `String` if avoidable (strings are immutable and can't be reliably
  zeroed); use `Uint8List` and overwrite.
- Honest caveat: a garbage-collected runtime cannot *guarantee* a key is gone from memory.
  This is a known limitation of any managed language and applies equally to most of the field.
  Note it in the public threat model rather than pretending otherwise.

---

## 9. What could still go wrong

Written down so we test for it:

1. **A weak user passcode.** Argon2id buys a lot but not everything. Encourage a passphrase;
   show honest strength feedback; never *block* a weak one (that just makes people quit).
2. **Randomness failure.** If the CSPRNG is broken, all is lost. Use only the OS source.
3. **A malicious dependency.** Every package we add can read everything. Minimise, pin
   versions, review each addition, and justify it in writing.
4. **Implementation bugs.** The design here is sound; the implementation is where real apps
   die. Nonce reuse, an off-by-one in chunking, a forgotten `FLAG_SECURE`, a plaintext temp
   file. **This is precisely why ADR-008 forbids strong public claims before an audit.**
5. **A backup file that silently fails to restore.** Mitigated by verify-on-write. Must be
   tested obsessively, on real devices, with large vaults, with interrupted writes.

---

## §2c — KEK-R, kept for backups. ISSUE 17, 24 August 2026

> *"Backup phrase is only able to open the app! I want that phrase to open the backup (.vault)
> file."*

He is right, and the hole was worse than an inconvenience. The twelve words were sold as the
way back in when the passcode is gone — and they opened the app **on that phone**. Lose the
phone and the words were useless: the only copy of a life was a file openable by a passcode
that had, by definition, been forgotten. The recovery phrase recovered the one thing that did
not need recovering.

`.vault` format v2 adds a second wrapper of the same file key, under KEK-R. See
`04-technical/BACKUP-FILE-FORMAT.md`.

### The new stored value, and exactly what it is

Writing that wrapper needs KEK-R at backup time, and the recovery **entropy** is generated
once, shown once, and deliberately never stored. That stays true.

So the keyring gains `recoveryKekForBackups`: **KEK-R itself, sealed under the DEK**.

| | Kept? | Why it matters |
|---|---|---|
| Recovery entropy (the 12 words) | **No.** Never was, still isn't | Cannot be recovered from what is stored |
| KEK-R = BLAKE2b(domain ‖ entropy) | Yes, sealed under the DEK | One-way. Opens backups; yields nothing about the words |

### What it costs, stated rather than glossed

Reading it requires the DEK, so an attacker must already have unlocked the vault. At that point
they can read every note, photograph and recording, and make their own backup of all of it.
KEK-R lets them additionally open `.vault` files of the same vault — which hold the data they
are already holding. **It does not let them derive the phrase**, so it does not survive a
passcode change into a way back in, and it cannot be written down and used in a year. That is
the line that matters, and a one-way hash is what keeps it.

### Vaults created before this

They have no sealed KEK-R, so their backups carry one wrapper and the restore screen does not
offer the words for them — deliberately, because offering a way in that the file does not have
would leave somebody holding the right twelve words and being told they are wrong.

It is filled in the next time the user unlocks with their recovery phrase, which is the only
other moment the app legitimately holds the entropy. From then on their backups carry both.
