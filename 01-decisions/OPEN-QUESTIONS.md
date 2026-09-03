# Open questions

Things we haven't decided. Roughly by how much they block progress.

---

## 🔴 Blocking

**None. Both blocking questions were resolved on 18 August 2026, before the first commit.**

### 1. The name ✅ RESOLVED → ADR-010
**Lamplight.** Package ID `com.probablypiyush.lamplight`. Reasoning in `DECISIONS.md` → ADR-010.

Two follow-ups that don't block building but do block *publishing*:
- [ ] Search the Indian and US trademark registries for conflicts.
- [ ] Check domain availability.

### 2. The licence ✅ RESOLVED → ADR-007
**GPL-3.0 with an App Store exception under §7.** The full text is in `LICENSE` at the repo
root, in place from commit one. Reasoning in `DECISIONS.md` → ADR-007.

---

## 🟠 Decide during Phase 2

### 3. Can you edit yesterday?
Journalling apps split on this. Locking past days makes the record feel like *evidence*;
unlocked feels like a *notebook*.

**Recommendation: fully editable, but show a small "edited" marker and keep revisions.** It's
his own private record, not a legal document. Locking would be a paternalistic gesture toward
a security property we don't actually need.

### 4. Plaintext export (PDF / Markdown)?
Users will demand it, and refusing looks like lock-in — the opposite of the "your data is
yours" promise. But an export button is by definition a plaintext-exfiltration path, and if
someone can get you to tap it, everything is out.

**Recommendation: allow it, per-entry or per-folder, behind a clear one-time warning.** Never
a silent "export everything". Frame it as *"this creates an unprotected file"*, and never
default it on.

### 5. Reminders / daily nudge
A quiet daily notification helps the habit enormously. But notifications are a leak surface.

**Recommendation: optional, off by default, and the notification text is fixed and generic
— never contains content, never a preview, never a count.** Something like *"A moment for
today?"* and nothing more.

### 6. Multiple vaults on one device?
Separate passcodes, separate keys. Useful for genuinely separating work and personal, or for
a shared phone. Adds real complexity to unlock, backup, and restore.

**Recommendation: not v1.** Revisit if people ask.

---

## 🟡 Later

### 7. Duress passcode
A second passcode that opens a decoy vault. Emotionally appealing, technically fraught: it's
detectable via file sizes and timestamps, being caught with one can escalate a bad situation
dangerously, and in some jurisdictions using one is itself an offence. Plausible deniability is
also genuinely hard to implement correctly.

**Recommendation: no, and say why publicly.** An honest "we don't offer this, here's why" is
better than a feature that fails when someone is relying on it.

### 8. On-device voice transcription
Whisper-tiny running fully offline would make years of voice notes searchable, which is a
genuinely large feature. Adds ~40 MB to the app and meaningful battery cost.

**Recommendation: v2, opt-in, and only if it can be proven fully offline.** No cloud
transcription, ever, under any circumstances. That would break the central promise.

### 9. Monetisation
Options: entirely free; free with donations (the Signal model); a one-time paid app; free with
a paid tier for something (but there's no server to gate anything behind).

Note that open source + paid means people can build it themselves for free. That's fine — the
people who would are not the people who'd pay.

**Recommendation: free, with a visible donation link.** Revisit once there are users. Never
ads — the business model must never create a reason to want their data.

### 10. Widgets and quick capture
A home-screen widget for one-tap voice capture would be genuinely great for the "record my
day" use case. It also means capturing while locked, which is a real security design problem
(write-only capture into an encrypted staging area is possible but fiddly).

**Recommendation: v2, and design it as write-only** — the widget can add, never read or display.

### 11. Padding backup file sizes
Round backups to size buckets so an observer of the user's Drive can't infer volume. Costs
disk space. **v2 setting.**
