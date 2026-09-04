# Three claims, checked on a real phone

**Date:** 28 August 2026, with a fourth and fifth check added 31 August 2026
**Device:** Redmi Pad `22081283G` (`yunluo`), Android 14 (API 34), arm64-v8a
**Build:** `app-release.apk`, signed with the real key —
`CN=Lamplight, OU=Lamplight, O=Lamplight, C=IN`,
SHA-256 `CC:F5:D5:83:…:D1:7B`, which matches `05-shipping/FINGERPRINT.md`
**Package:** `com.probablypiyush.lamplight`, uid `10278`, `ceDataInode=113300`

Recorded here rather than in a chat log, for the same reason
`EXIT-TEST-EVIDENCE.md` exists: *"we checked once" is worth nothing in six months.*

> **Every claim below had only ever been argued from source or from a built artifact.
> None of them had been observed on hardware.** Two of the three are the app's central
> promise.

---

## Why this could be done at all, and it is not a happy reason

The vault that lived on this tablet was destroyed earlier the same day — `PLAN.md` §0 has
the full account. That is what made these checks safe to run: **there was nothing left to
lose.** Every one of them had been deferred for weeks precisely because the only device
available was the only device with somebody's journal on it.

The app has been reinstalled from a properly signed release. The vault is empty and new.

---

## 1 · It installs with the real key, and it runs

| | |
|---|---|
| `adb install -r` | **Success** |
| Signature | `1e5ecef5` — **the same certificate as the install it replaced.** A future update will go on cleanly. |
| Launch | pid 3118, splash rendered, `hardware acceleration = true`, window 1200 × 2000 |
| `FATAL` / `AndroidRuntime` in logcat | **None** |

The only `E` lines during launch are MIUI's own `BufferQueueDebug`, which every app on the
device produces.

### The permissions the operating system actually granted

```
android.permission.RECORD_AUDIO
android.permission.USE_BIOMETRIC
android.permission.USE_FINGERPRINT
android.permission.POST_NOTIFICATIONS
android.permission.RECEIVE_BOOT_COMPLETED
```

**Five, and not one of them is network.** `verify_no_internet.sh` reads this out of the APK
before it ships; this is the same list read out of the running system afterwards.

---

## 2 · The app holds no network socket — checked on the running process

This is the claim everything else rests on, and until today it had only ever been argued —
from the manifest, and from the symbols the native library imports.

Every socket table on the device, filtered to the app's uid:

```
$ adb shell cat /proc/net/tcp /proc/net/tcp6 /proc/net/udp /proc/net/udp6 \
      /proc/net/raw /proc/net/raw6 | awk '$8 == 10278'

  (no output)
  count: 0
```

**Zero.** And the check is genuinely reading the table, which matters more than the zero
does — the same command with the filter removed lists a dozen other uids holding sockets at
that moment:

```
0  1000  10059  10075  10113  10129  10149  10150  10151  10156  10169  10191 …
```

So: **other apps on this device had open sockets while Lamplight had none.** Not because it
chose not to open one — because Android never gave it the permission to.

---

## 3 · `FLAG_SECURE` blanks the screen on a release build

`CLAUDE.md` rule 7: the flag goes on in `onCreate`, before `super.onCreate`,
unconditionally.

With the app confirmed in focus —

```
mCurrentFocus=Window{… com.probablypiyush.lamplight/…MainActivity}
```

— `adb exec-out screencap -p` returns a frame in which **the entire application window is
black**. Only the system status bar and the gesture bar render, and those belong to the
system rather than to us.

**This is the app working, not a failed capture.** The same thing happens to a screen
recorder, to a screenshot the user takes, and to the thumbnail the system stores for the
recent-apps switcher — which is the one that matters most, because it is taken without
anybody asking and it survives the app being closed.

The screenshot setting was left **off**, which is its default. `PLAN.md` §0 is right that
only Piyush can turn it on: it lives inside the vault's own storage and a release build is
not debuggable.

---

## 4 · Why the app "suddenly closes", read off the device — 31 August 2026

**ISSUE 4:** *"LOOK INTO ANY CODE ISSUES - CS WHENEVER IDK WHEN OR HOW EVEN WHEN I AM
WORKING THE APP IDK SUDDENLY CLOSES! LOOK FOR ANY ISSUES! AND FIND THEM AND FIX IT!"*

Nothing was installed for this. Both commands are read-only, and the device held a real
vault at the time — `tool/check_device_safe.ps1` said `REFUSED` and it was right to.

```
adb shell dumpsys activity exit-info com.probablypiyush.lamplight
```

Twelve process exits are recorded. **Exactly one is a crash.**

| when | reason | pss | rss |
|---|---|---|---|
| 2026-08-30 21:46 | 13 · OTHER KILLS BY SYSTEM · SwipeUpClean | 70 MB | 96 MB |
| 2026-08-29 17:42 | 13 · OTHER KILLS BY SYSTEM · SwipeUpClean | 0 | 0 |
| 2026-08-29 16:29 | 13 · OTHER KILLS BY SYSTEM · SwipeUpClean | **250 MB** | **360 MB** |
| 2026-08-29 16:28 | 13 · OTHER KILLS BY SYSTEM · SwipeUpClean | **410 MB** | **526 MB** |
| 2026-08-29 16:18 | **4 · APP CRASH (EXCEPTION)** | 53 MB | 81 MB |
| 2026-08-28 01:47 | 13 · OTHER KILLS BY SYSTEM · SwipeUpClean | **795 MB** | **876 MB** |

*(The `PACKAGE UPDATED` rows are `adb install` and are omitted.)*

**The single crash is round fourteen's**, on 29 August at 16:18 — `title:` in `MaterialApp`,
fixed the same day. Every other exit is the low-memory killer.

```
adb shell dumpsys meminfo com.probablypiyush.lamplight
```

On an **idle, backgrounded** app showing one screen:

```
GL mtrack   152044 KB      ← GPU textures
TOTAL PSS   290202 KB
TOTAL SWAP  113985 KB
```

```
adb shell cat /proc/meminfo
MemTotal:  5987200 kB      MemFree:  123648 kB
```

### What this means, stated plainly

**The app was not crashing. It was being killed for being enormous**, on a 6 GB tablet with
123 MB free — and "SwipeUpClean" is MIUI reclaiming memory when the user swipes up, which is
precisely *"IDK SUDDENLY CLOSES"* from the outside.

152 MB of GPU textures on an idle notes app is the number to be alarmed by. A backgrounded
app holding a quarter of a gigabyte is a process the system will take the moment anything
else wants memory.

### What round fifteen took back

| | |
|---|---|
| **Crumpled**, removed at his request | two 768 × 1536 RGBA sheets = **9 MB**, uploaded as textures the moment anybody chose the surface |
| **The glass blur**, 18σ → 7σ | `BackdropFilter` cost scales with the kernel, on two panels |
| **PDF base pages** that fail to draw at full width | drawn at half, twice, before giving up — a 40 MB ten-page scan used to show two pages and then a wall of grey |
| **PDF renders** | queued one at a time and cancelled when scrolled past, instead of thirty deep behind a fling |

### What is still missing, and it is the important half

**Nothing in this project measures memory.** 1,434 tests, an analyzer with no issues, two
release gates that read the built artefact — and not one of them would notice a feature that
allocates a full-screen bitmap and keeps it.

`dumpsys meminfo` before and after a change is a two-minute check. It is not in
`RELEASE-CHECKLIST.md` and it should be. **This is the highest-value unchecked thing in the
project**, and it is written down in `Honest Review/WHAT-LAMPLIGHT-LACKS.md` as an evening.

*Recorded here rather than in a chat log for the same reason as everything else in this
file: none of the numbers above had ever been looked at, and the diagnosis they give is not
the one anybody would have guessed from the report.*

---

## 5 · The memory reductions, measured on the device — 31 August 2026

**The other half of §4.** That section diagnosed the low-memory killer and listed what
round fifteen took back. This is what it was actually worth, read off the same tablet.

`app-release.apk` 0.5.0+10 was installed with `adb install -r` over the 0.4.0+8 build.
Both are signed with the same certificate — checked first, by pulling the installed APK
and comparing:

```
installed 0.4.0+8   ccf5d58316f3663b212d0a5dd56752674b7c2df041a2f35863d8a5d1eb95d17b
new       0.5.0+10  ccf5d58316f3663b212d0a5dd56752674b7c2df041a2f35863d8a5d1eb95d17b
```

**`ceDataInode` is 113300 before and after, and `firstInstallTime` is unchanged.** The
vault was updated in place, not replaced. That is the check `PLAN.md` §0 demands after
every install and it is the only one that matters.

### Backgrounded, which is the state the 28 August reading was taken in

| | 0.4.0+8 | 0.5.0+10 |
|---|---|---|
| `GL mtrack` | **152,044 KB** | **23,696 KB** |
| `Graphics` total | — | 71,636 KB |
| `TOTAL PSS` | **290,202 KB** | **190,564 KB** |

**GPU textures are down from 152 MB to 24 MB, and total PSS by 100 MB.**

### What is honest about that number and what is not

**It is not a controlled experiment, and it should not be quoted as one.** The 28 August
reading was of an app that had been used for a while; this one had been launched and
backgrounded a few seconds earlier, and neither run recorded which page surface was
showing or whether a document had been opened. A like-for-like comparison would fix the
state on both sides.

**What is safe to say is the direction and the order of magnitude.** A 128 MB gap in GPU
textures is far larger than measurement noise, and it is larger than the 9 MB Crumpled was
worth — so most of it is the **blur**. `BackdropFilter` allocates an offscreen render
target and its cost scales with the kernel; taking two panels from 18σ to 7σ was made for
a visual reason (ISSUE 6) and turns out to have been the biggest single memory saving in
the round. That was not predicted, and it is the argument for measuring rather than
reasoning.

### And the permissions, on the installed app rather than on the APK

```
requested permissions:
  android.permission.RECORD_AUDIO
  android.permission.USE_BIOMETRIC
  android.permission.USE_FINGERPRINT
  android.permission.POST_NOTIFICATIONS
  android.permission.RECEIVE_BOOT_COMPLETED
  com.probablypiyush.lamplight.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

`grep -c android.permission.INTERNET` over the whole package dump: **0**. The release gate
says this about the artefact; this says it about the thing installed on the phone.

### It launches, which is not a given

Round fourteen shipped a build that did not open while 1,217 tests passed. Launched by
`am start`, the process was alive after seven seconds with nothing in the crash buffer and
no Dart exception in logcat.

**One surprise worth recording:** the enabled launcher alias after the update is
`.PlumLight`, not `.Plum`. `am start -n …/.Plum` fails with *"Activity class does not
exist"* — the alias is disabled, not missing. Resolve it rather than assuming:

```
adb shell cmd package resolve-activity --brief     -a android.intent.action.MAIN -c android.intent.category.LAUNCHER     com.probablypiyush.lamplight
```

---

## What is still unchecked, and it is the interesting half

**None of these needs a laptop. All of them need a finger.**
`05-shipping/HARDWARE-CHECKS.md` is the procedure.

| | Why it could not be done from here |
|---|---|
| **Play a video** | Needs a clip imported through the UI, and the UI cannot be seen — `FLAG_SECURE` is doing its job, which is exactly the point of §3 above. |
| **Import a Whisper model** | Both files are already on the tablet, in `Download`. It is four taps and then several minutes of waiting. |
| **The aeroplane-mode transcription check** | The claim §2 proves *architecturally* — no socket, no permission — confirmed end to end by a transcript arriving with the radios off. |
| **The first ten minutes in somebody else's hands** | The one that cannot be automated and cannot be done twice. |

---

## The install restriction, so nobody debugs it twice

The tablet refused `adb install` repeatedly with:

```
Failure [INSTALL_FAILED_USER_RESTRICTED: Install canceled by user]
```

**That is not a build problem, a signing problem, or a Flutter problem.** It is MIUI's
*Settings → Additional settings → Developer options → **Install via USB***, which is off by
default, cannot be set from `adb`, and turns itself back off after a while. It succeeded the
moment Piyush allowed it on the device.

**It is also what destroyed the vault**, indirectly: the refusal is what sent Flutter's
tooling down its cleanup path. See `PLAN.md` §0.

---

*Companion: `02-security/EXIT-TEST-EVIDENCE.md` (Phase 1, 18 August) and
`02-security/PERIMETER-AUDIT.md` (the same claims read out of the built artifact rather than
the running system).*
