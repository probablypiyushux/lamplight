# Threat model

A threat model is a written answer to: **who are we defending against, what can they do,
and what do we honestly not protect against?**

Publishing this in the repo is itself a security feature. Apps that claim to protect against
everything are lying; apps that state their limits precisely are the ones worth trusting.

---

## Assets — what we are protecting

| Asset | Sensitivity | Notes |
|---|---|---|
| Note content (text, voice, photos, files) | **Critical** | The whole point |
| Note metadata (when written, how many, how long) | **High** | Timing patterns reveal a lot |
| Folder names | **High** | `Dr. Mehta — therapy` is content, not metadata |
| Display name & profile photo | Low | Local decoration; still encrypted |
| The vault key | **Critical** | Compromise = total loss |
| The recovery phrase | **Critical** | Equivalent to the key |
| Backup files | **Critical** | Contains everything, and leaves the device |

---

## Adversaries — ranked by how likely they are

### 1. The person who picks up the unlocked phone 🔴 Most likely by far
*Partner, sibling, parent, colleague, someone at a party.* Not sophisticated. Has physical
access to a device that is already unlocked.

**Defences:** app-level passcode separate from the device passcode; auto-lock after a short,
configurable idle timeout; lock immediately on backgrounding; `FLAG_SECURE` so the app's
contents don't appear in the recent-apps switcher or in screenshots; no note content in
notifications; no content in the app icon badge or widgets.

**Verdict: defended.** And this is the threat that actually happens to real people, so it
deserves the most polish. The auto-lock timing is a product decision as much as a security one.

### 2. A thief with the powered-off phone 🟠 Likely
Has the hardware. Wants the data or wants to resell.

**Defences:** all data at rest is encrypted under a key derived from a passcode they don't
have. Argon2id makes brute force expensive. Nothing plaintext ever hits disk.

**Verdict: defended**, assuming a decent passcode. A 4-digit PIN is weak against a
determined attacker with the storage chip desoldered — hence the recommendation to allow
(and gently encourage) a longer alphanumeric passphrase.

### 3. Forensic extraction 🟠 Plausible
Cellebrite/GrayKey-class tooling. Airport, police stop, border crossing, a legal case.

**Defences:** same as above, plus specific care that we never leave plaintext residue —
no temp files during PDF import, no unencrypted thumbnail cache, no plaintext in logs, no
crash reports containing content, memory zeroed after use where the platform allows.

**Verdict: mostly defended.** Honest caveats: (a) if the phone is seized while the app is
*unlocked*, keys are in RAM and a sophisticated attacker can extract them; (b) we cannot
control what the third-party keyboard did with your typing; (c) if the OS itself is
compromised at a level below us, nothing we do matters.

### 4. Us — the developer 🟡 Structurally impossible
Could a malicious future maintainer, or a compromised release, exfiltrate notes?

**Defences:** there is no server to send data to. The app requests no network permission at
all in v1 — this is checkable by anyone with the APK, and it makes exfiltration *visible*.
Source is public. Reproducible builds are a stated goal so the binary can be matched to
the source.

**Verdict: structurally defended for v1**, and the no-network-permission property is worth
protecting fiercely. The moment any feature needs the internet, this guarantee weakens and
we should think very hard.

### 5. Cloud providers and network observers 🟡 Limited exposure
Only relevant if the user stores a backup in Drive/iCloud.

**They see:** an opaque encrypted blob, its size, and the timestamps of changes.
**They do not see:** any content, any filename, any structure, any count of entries.

**Verdict: content defended, metadata partially leaked.** File size loosely correlates with
how much you've written. Mitigation (v2): pad backups to size buckets.

### 6. Legal compulsion against you 🟢 Nothing to give
A court orders you to produce a user's notes, or to add a backdoor.

**Defences:** you have no user list, no data, no key escrow. The correct and only possible
response is "I do not possess this." A backdoor order would be visible in the public source.

**Verdict: structurally defended.** This is the single biggest payoff of ADR-001.

### 7. A malicious app on the same phone 🟡 Partially defended
**Defences:** OS sandboxing keeps our files unreadable to other apps on a non-rooted device.
`allowBackup="false"` prevents ADB/cloud backup exfiltration of our directory. `FLAG_SECURE`
blocks screen capture by other apps. Clipboard is not used for content.

**Verdict: defended on a healthy device. Undefended on a rooted or malware-infected one.**

### 8. A targeted state-level attacker with a zero-day 🔴 Not defended — say so
Pegasus-class. Full device compromise, kernel-level, before our code runs.

**Verdict: NOT DEFENDED.** No app can defend against this, including Signal. If someone is
in your kernel, they read your screen. We must state this plainly in our public threat model
rather than let anyone believe otherwise.

### 9. Coercion — someone forcing the user to unlock 🔴 Not defended
Rubber-hose. A partner demanding to see it, a border officer, an abusive family member.

**Considered and deferred:** a *duress passcode* that opens a decoy vault. It's appealing but
genuinely dangerous — it can be detected (file sizes, timestamps), it can escalate the
situation badly when detected, and in some jurisdictions using one is itself an offence. Also
plausible-deniability schemes are extremely hard to get right and easy to get subtly wrong.
Logged as an open question, not a v1 feature.

**Verdict: NOT DEFENDED.** Stated honestly.

### 10. The user's own memory 🔴 The most likely total-loss event
Forgets the passcode, loses the phrase, never made a backup.

**Defences:** recovery phrase (ADR-003), aggressive but polite backup reminders, blunt copy
at setup, verified backups.

**Verdict: mitigated, not solved.** Realistically this will destroy more vaults than every
attacker on this list combined. Design accordingly — the backup nag is a security feature.

---

## The security rules that follow from all of this

Non-negotiable, and Claude Code should be held to them in every code review:

1. **No plaintext user content ever written to disk.** Not temp files, not caches, not
   thumbnails, not logs, not crash reports.
2. **No network permission in v1.** Not declared in the manifest. Provable by inspection.
3. **No analytics, no crash reporting SDK, no ad SDK, no attribution SDK.** Zero third-party
   telemetry of any kind. Audit every dependency for it.
4. **`FLAG_SECURE` on every screen** that can display content.
5. **`android:allowBackup="false"`** and explicit `dataExtractionRules` — otherwise Android's
   own backup system copies our encrypted directory to Google's cloud, which is both a leak
   and confusing.
6. **Lock on background**, not just on timeout. Keys cleared from memory on lock.
7. **Every dependency justified in writing.** A supply-chain compromise in a random package
   defeats all of the above. Fewer packages is a security property.
8. **The store listing links to this document.** Users deserve to read the limits.
