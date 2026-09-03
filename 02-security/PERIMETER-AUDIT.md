# The perimeter — audited against the built APK

*Run 28 August 2026, against `app-release.apk` built that day. This is
`09-build/SAFETY-PROMPTS.md` **PROMPT 3**, which says to run it before every release and
to check the **built artifact, not the source** — "they are not the same thing, and the gap
is where this class of problem hides."*

> Everything below was read out of the APK with `aapt2 dump xmltree`, `llvm-nm` and
> `pubspec.lock`. Where something could not be checked mechanically, it says so.

---

## Verdict

**Nothing found that blocks release.** One component in the merged manifest is not ours; it
is permission-protected and benign, and it is written down below so it is a known quantity
rather than a discovery.

---

## Dependencies

**Five direct, 102 in the lockfile.**

```
sodium ^4.0.4      the crypto. Everything in lib/core/crypto/ goes through it.
drift ^2.34.3      the database layer over SQLCipher.
crypto ^3.0.7      hashing outside the vault's own key hierarchy.
path_provider      where the sandbox is.
path               joining strings, carefully.
```

**Which of these could read the user's notes if it were malicious?** `sodium` and `drift`,
and that is the whole list. `crypto`, `path_provider` and `path` never see content. Keeping
that list at two is the point of `CLAUDE.md` rule 4 — every package added can read
everything.

**Network packages in the tree**: `http_parser`, `http_multi_server`, `web_socket`,
`web_socket_channel`. All four are `dependency: transitive` and all four arrive through
**dev tooling** — `flutter_test`, `build_runner`, `drift_dev` — not through the app.

**And it does not matter either way, which is the architecture working.** The shipped APK
has no `INTERNET` permission, so code that wanted to open a socket could not. That is
checked mechanically on every push by `tool/verify_no_internet.sh` against the built
artifact, precisely because a dependency can merge a permission in through its own manifest
without appearing in a diff.

**Pinned?** Yes — `pubspec.lock` is committed, so a build is reproducible against the same
resolved versions.

---

## The built manifest

| Check | Result |
|---|---|
| `INTERNET` | **Absent.** Five permissions total: `RECORD_AUDIO`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`. |
| `android:debuggable` | **Absent**, which is false. `build.gradle.kts` also states it explicitly. |
| `android:allowBackup` | **`false`**. |
| `dataExtractionRules` | **Present.** |
| `networkSecurityConfig` | **Present.** Belt and braces — with no `INTERNET` there is nothing for it to govern. |
| `testOnly` | **Absent.** |
| Self-namespaced permission | `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, `protectionLevel=signature`. Only a build signed with our key can hold it. |

### Exported components — all 18 accounted for

| Component | Exported | Why |
|---|---|---|
| `MainActivity` | **true** | It is the app. Carries `SEND` / `SEND_MULTIPLE` filters — sharing into Lamplight, ISSUE 13. Intended. |
| **12 × `activity-alias`** — `Ember`, `EmberLight`, `Plum`, `PlumLight`, `Slate`, `SlateLight`, `Sage`, `SageLight`, `Rose`, `RoseLight`, `Light`, … | **true** | The alternate launcher icons. A `MAIN`/`LAUNCHER` alias **must** be exported or the icon cannot be launched. Intended. |
| `FileProvider` | **false**, `grantUriPermissions=true` | The rule-2 exception — "Open with" hands one file, one read, to one app. Exactly right: not exported, grants per-URI. |
| `ReminderReceiver` | **false** | Ours. |
| `BootReceiver` | **false** | Ours, `BOOT_COMPLETED` only. |
| `InitializationProvider` | **false** | AndroidX Startup. |
| **`androidx.profileinstaller.ProfileInstallReceiver`** | **true** | **Not ours** — see below. |

#### The one that is not ours

`androidx.profileinstaller.ProfileInstallReceiver` is merged in by the AndroidX/Flutter
toolchain. It installs ART baseline profiles, which is why apps start faster after an
update.

**It is protected by `android:permission="android.permission.DUMP"`.** That is a
`signature|privileged` permission — the shell and the system can hold it and a third-party
app cannot. So the receiver is exported in the sense that `adb` and the platform can reach
it, and unreachable by anything installed alongside us.

**No finding.** It is recorded here so that the next person who dumps this manifest and
sees an exported receiver they did not write has the answer rather than the question.

### Deep links

**None.** No `VIEW` filters, no `android:scheme`, no App Links. Nothing outside the phone
can send this app anywhere.

---

## Native code

**There is no first-party native code any more.** `liblamplight_whisper.so` — 1,231 KB,
212 imported symbols, none of them a socket call — went with Whisper on 28 August 2026.
`tool/verify_no_sockets.sh` survives as an inventory of every `.so` in the artefact rather
than a check of one file, and still runs in CI with `LAMPLIGHT_STRICT=1` so a runner that
cannot check fails rather than passing quietly.

What ships now is five prebuilt libraries per architecture: `libflutter`, `libapp`,
`libsqlcipher`, `libsodium`, `libdartjni`.

### The processors, measured rather than asserted

This section used to read *"`arm64-v8a` only. No x86_64 slice ships."* **That was false**,
and it had been false for as long as the sentence existed. The release APK on 29 August 2026
was 78.5 MB and contained three complete slices:

| slice | size | ships now |
|---|---|---|
| `arm64-v8a` | 26.06 MB | yes |
| `armeabi-v7a` | 22.91 MB | yes — 32-bit devices, `minSdk` is 26 |
| `x86_64` | **28.51 MB** | **no, since 29 August 2026** |

The `ndk { abiFilters }` block that was supposed to prevent it governs libraries the Android
plugin *builds itself*, through `externalNativeBuild`. Since Whisper went there is no such
build, and every `.so` in the APK arrives as a prebuilt **jniLib**, which that filter never
sees. It was written when there was a CMake step and it went on compiling afterwards, which
is why nobody caught it: the code looked right and only the artefact was wrong.

The filter that works is `packaging.jniLibs.excludes`, applied to the release variant through
`androidComponents` so the debug build keeps x86_64 and still runs on an emulator. The APK is
**51.2 MB**. `--split-per-abi` takes it to roughly 24 MB per device at the cost of one file per
architecture.

**Re-measured 31 August 2026, on the first Play Store build.** Nothing regressed and one
thing is better than the APK number suggests:

| artefact | size | slices |
|---|---|---|
| `app-release.apk` | **53.5 MB** | arm64-v8a 25.16 MB · armeabi-v7a 22.16 MB |
| `app-release.aab` | **50.2 MB** | the same two |

The APK grew 2.3 MB, which is round fifteen's code and a hundred new translated strings in
ten languages. **The bundle is the number that matters from now on and it is not what anybody
downloads**: Play generates a per-device APK from it, so a 64-bit phone receives the arm64
slice and nothing else. Under the 200 MB Play limit by a wide margin either way.

`armeabi-v7a` stays on purpose. 32-bit Android phones exist, `minSdk` is 26, and dropping the
slice would silently exclude them from a single-file download.

### One string in the bundle manifest that looks alarming and is not

Grepping `base/manifest/AndroidManifest.xml` finds **`android.permission.DUMP`**, which is
not in our source manifest and is not something this app could hold.

It is the `android:permission` **guard** on `androidx.profileinstaller.ProfileInstallReceiver`
— meaning only a caller already holding DUMP (signature|privileged, so in practice the shell)
may broadcast to it. **A lock on a door, not a key being asked for.** `aapt` correctly does
not list it as a `uses-permission`, which is why `verify_no_internet.sh` passes and should.

Written down because the next person to grep the artefact will find it and worry, as I did.

**The lesson is the one this document exists for: a claim about an artefact has to be read
off the artefact.** Every other line in this file is measured. That one was not, and it was
the only one that was wrong.

---

## Obfuscation

R8 is on for release: `isMinifyEnabled = true`, `isShrinkResources = true`,
`proguard-android-optimize.txt` plus `proguard-rules.pro`.

**What that buys and does not buy** is argued at length in `build.gradle.kts` and the
argument is right: it is the outer wall, not the vault. The security rests on Argon2id and
XChaCha20-Poly1305, both public, both designed to be safe while the attacker holds the
algorithm. **An app whose safety depended on nobody reading its source would have no
security at all** — which is also why publishing the source costs nothing.

---

## Secrets and signing

| Check | Result |
|---|---|
| Keystore, `.jks`, `.p12`, `.pem`, `key.properties` **ever committed** — full history | **None.** `git log --all --diff-filter=A` over every file ever added. |
| Secrets or keys in history | **None.** The only `storePassword` / `keyPassword` matches are inside `tool/make_release_key.ps1`, which *writes* those lines from a value it just prompted for. |
| `.gitignore` coverage | `*.jks`, `*.keystore`, `*.p12`, `key.properties`, `keystore.properties`, `.env`, `.env.*`, `local.properties` — root and `app/android/`. |
| Signing config reads from an untracked file | Yes. `rootProject.file("key.properties")`, absent → debug signing, loudly. Never a literal in Gradle. |
| The key in CI | **Deliberately not there.** `.github/workflows/verify.yml` holds no secret of any kind; a CI secret is a copy of the signing key on somebody else's computer. |

**Nothing to rotate.** That is the expensive outcome this audit exists to rule out — a
secret in public git history is permanent and cannot be un-published.

---

## What this audit could not do

Stated rather than left as a silent gap.

- **Decompiling the DEX** to confirm R8 left nothing readable. `verify_no_internet.sh` and
  `verify_no_sockets.sh` check what actually matters — capability, not readability — and
  the obfuscation argument above is that readability was never the defence.
- **Reproducible builds.** `PROMPT 3` asks what prevents one. Untouched: timestamps in the
  APK, absolute paths in the NDK build, and the Flutter engine hash. **Real work, and
  nobody has asked for it.** It becomes worth doing the day somebody wants to verify that a
  published APK matches published source — which is the day after the repository goes
  public, not before.
- **The on-device leak scan.** Written — `integration_test/nothing_in_the_clear_test.dart`,
  which is PROMPT 2 STEP 1 — and **it has never run.** It needs a device or an emulator with
  KVM. Until it does, `CLAUDE.md` rule 1's claim that the debug `INTERNET` permission exists
  to run it is a promise rather than a fact.

---

*Re-run before every release. `09-build/SAFETY-PROMPTS.md` PROMPT 3 is the checklist this
follows; `05-shipping/RELEASE-CHECKLIST.md` is where it sits in the order of things.*
