# Data model

How days, folders, and entries relate. This is the structural heart of the app — get it
right and features fall out for free; get it wrong and you fight it for years.

---

## The puzzle you set

You asked for two organising systems at once:

> *"Each day the man is given a tab! In that day he can record his voice notes, take
> pictures, write texts, add pdf, add any document in that day!"*

> *"The user is also given to create folder wise notes! Folders present in Windows or mac
> styled file explorer!"*

The naive build is two separate features — a journal *and* a file manager — that don't know
about each other. Users then have to decide, every single time, "does this go in today, or in
a folder?" That decision is friction, and friction is what stops people writing.

## The resolution: one pile, two lenses

**There is exactly one kind of object: the Entry.**

- Every entry has a `created_at` timestamp. That timestamp *is* its day. **Days are never
  created, deleted, or managed by the user — they exist because time exists.**
- Every entry may *also* be filed into one or more **Folders**. Filing is a link, not a move.
  The entry stays on its day forever and simultaneously appears in the folder.

So:

- **Day view** = a *time* lens. "What happened on 4 March?"
- **Explorer view** = a *space* lens. "Everything about Dad, across four years."

Same entries. No duplication. No decision at capture time — you just capture, and file later
if you feel like it. Most entries will never be filed, and that's fine.

**This is what makes your best line work.** *"Recording things about a particular phase or
particular person"* — that's a folder named `Kavya` or `The year I quit` or `Sleep
experiment`, quietly accumulating entries from across two hundred scattered days into one
readable thread. You don't build a feature for it. It's just what the model does.

---

## The entities

### Entry
The atom. One captured thing.

| Field | Notes |
|---|---|
| `id` | UUID |
| `created_at` | UTC + the original local offset. Store both — "what time did *I* think it was" matters in a journal, and travel breaks naive timestamps |
| `updated_at` | |
| `type` | `text` · `voice` · `photo` · `file` |
| `body` | Text content (encrypted with the DB) |
| `attachment_id` | For non-text types |
| `day_key` | `YYYY-MM-DD` in the *local* timezone at creation. Denormalised for fast day queries |
| `mood` / `marker` | Optional, single tap, no scale of 1–10. See below |
| `is_pinned` | |
| `deleted_at` | Soft delete → Trash for 30 days |

### Day
**Not a stored row. A derived view.** `SELECT * FROM entries WHERE day_key = ?`.

This is deliberate and important. If Days were rows you'd have to create them, migrate them,
worry about empty ones, handle timezone changes. As a query, a day with no entries simply
renders as empty — nothing to manage, nothing to corrupt.

The exception: an optional `day_notes` table for a one-line summary or a mood marker attached
to the *day itself* rather than to any entry. One row per day, created lazily only if used.

### Folder
| Field | Notes |
|---|---|
| `id` | UUID |
| `parent_id` | `NULL` = root. Self-referencing tree, arbitrary depth |
| `name` | Encrypted. Folder names are content — `Dr. Mehta — therapy` gives everything away |
| `icon` / `colour` | Small personalisation, big emotional payoff |
| `sort_order` | Manual ordering, because people care |
| `created_at` | |

### EntryFolder — the join
`(entry_id, folder_id, added_at)`. Many-to-many. **This one table is what makes the whole
model work.** One entry, many folders, zero duplication.

### Attachment
| Field | Notes |
|---|---|
| `id` | UUID — also the on-disk filename |
| `file_key` | Per-file 256-bit key |
| `original_name` | Encrypted |
| `mime_type`, `byte_size`, `duration_ms`, `width`, `height` | |
| `thumbnail_id` | Encrypted thumbnail, in a cache table |
| `transcript` | Nullable — on-device voice transcription, if we build it |

### Revision
`(entry_id, body, saved_at)`. Last ~20 per entry. Cheap insurance.

---

## What this model gives you for free

Features you don't have to design, because they're just queries:

- **"On this day, last year"** → `WHERE day_key LIKE '____-03-04'`
- **Year grid** (a contributions-graph, but beautiful) → count per `day_key`
- **Search across everything** → FTS5 over `body` + `transcript` + folder names
- **"Everything about Kavya, chronologically"** → join through `entry_folder`, order by date
- **A timeline of just voice notes** → `WHERE type = 'voice'`
- **"My first entry" / streaks / "you've written 40,000 words"** → aggregates
- **Smart folders** (saved searches that behave exactly like folders) → a folder row with a
  stored query instead of explicit links. Same UI, no new concepts.

That last one is the tell that the model is right: a whole extra feature slots in without
adding an idea to the user's head.

---

## The day tab, concretely

A day is a **vertical stream of blocks in the order you added them**, like a chat with
yourself:

```
   Tuesday, 4 March                        ← big, quiet, the date is the title
   ─────────────────────────────────────

   ▍ 8:42   Slept badly again. Third night.        ← text
   ▍ 9:15   ▶ 0:47 ────────────────                ← voice, waveform
   ▍ 13:30  [ photo ]                              ← photo, edge to edge
   ▍ 21:04  Called Ma. She sounded better than
            last week. I keep expecting bad news
            and it keeps not coming.

   ┌───────────────────────────────────┐
   │  ✎        🎙        📷        📎  │            ← always visible, thumb height
   └───────────────────────────────────┘
```

**Why a stream and not a form:** a form asks you to fill it in. A stream just accumulates.
The friction of a form is exactly what makes journalling apps die after nine days.

**Two seconds to capture.** Open app → today is already the screen → tap 🎙 → talking.
No "new entry" dialog, no title field, no category picker, no save button.

## The explorer, concretely

Familiar, because you asked for familiar — Windows/Finder shape, but stripped:

```
   ┌ Vault ──────────────────────────────────────┐
   │  ▸ 📁 People                    142          │
   │    ▾ 📁 Kavya                    38          │
   │        📁 Letters I didn't send   6          │
   │  ▸ 📁 Work                       91          │
   │  ▾ 📁 Experiments                27          │
   │      📁 Sleep                    19          │
   │      📁 Cold showers              8          │
   │  ▸ 📁 Health                     55          │
   └─────────────────────────────────────────────┘
```

Drag to reorder, drag to nest, long-press to rename, breadcrumbs at the top, list/grid
toggle. Nothing you have to learn. The counts do quiet emotional work — seeing `Kavya · 38`
tells you something about your own life.

**Filing an entry:** swipe it, or long-press → "Add to folder". It doesn't leave the day. Say
this explicitly in the UI the first time, once — `Still on 4 March. Also in Kavya.` — so the
mental model lands without a tutorial.

---

## The one modelling decision to get right early

**`day_key` uses the local timezone at the moment of creation, and we store the UTC instant
alongside it.**

Why this matters: someone writes at 1 a.m. — is that Tuesday or Wednesday? Someone flies
Delhi → London mid-journal — do their entries jump days? Get this wrong and you get bug
reports you cannot fix later without rewriting history.

**Rule:** `day_key` is fixed at creation from the device's local time and **never
recalculated**. If you wrote it on what felt like Tuesday, it's on Tuesday forever, in every
timezone, in every future version. A journal records your subjective day, not UTC.

Additionally: an optional per-user **"day starts at"** setting (default midnight, commonly set
to 3 or 4 a.m.) so late-night writing lands on the day it belongs to. Small setting, very
loved by exactly the kind of person who journals at 2 a.m.
