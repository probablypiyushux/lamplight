# BUILDING — how to build Lamplight, and how to check I am telling the truth

Two audiences, and this file is for both.

**If you are a stranger**, the point of this file is that you can build the app yourself from
this source and compare what comes out against what is on your phone. `PLAN.md` §11 test 3 calls
it the stranger test, and a privacy claim you cannot verify is a slogan. §4 below is the part you
want.

**If you are working on it**, §2 and §3 are the two things that will otherwise cost you an
afternoon each, because both of them fail with an error that blames the wrong thing.

---

## 1. What you need

| Tool | Version used | Why it is not optional |
|---|---|---|
| Flutter | 3.47.0 stable | — |
| Dart | 3.13.0 | Comes with Flutter |
| JDK | Temurin 17 | Android Gradle Plugin |
| Android SDK | 36, NDK 28.2.13676358 | — |
| A C++ toolchain | Visual Studio Build Tools 2026, C++ workload | **`flutter test` cannot run at all without it** |
| GNU Make | 4.4.1 | libsodium's autotools build |
| Git Bash | any recent | libsodium's autotools build |

The last three are the surprising ones. `sodium` v4 **compiles libsodium from source at build
time** through Dart's build hooks, and Flutter builds native assets for the test platform before
running anything — even a test that never touches libsodium. So a machine with no C compiler
cannot run the test suite, and the error it gives you will be about a missing DLL rather than
about a missing compiler.

```bash
flutter pub get
```

---

## 2. `flutter test` fails with a libsodium error about `rename` (Windows)

**Symptom.** The suite will not start. The output blames libsodium, mentions a `rename` and
`errno = 17`, and gives no hint that anything else is involved.

**Cause, and it is neither of the things it looks like.** libsodium's build hook extracts to a
path about 230 characters long, against a 218-character limit. Having failed, it falls back to
the system temp directory — which on a normal Windows install is on `C:` — builds there, and then
tries to `rename` the finished DLL onto the project's drive. Windows cannot rename across drives.

It shows up in a git worktree first, because a worktree path is longer than the repo's own.

**Fix.** Point the temp directory at the same drive as the project before running anything:

```bash
export TEMP="E:\\tmp" TMP="E:\\tmp"
```

or in PowerShell:

```powershell
$env:TEMP = "E:\tmp"; $env:TMP = "E:\tmp"; flutter test
```

Create `E:\tmp` first. Nothing is left in it that matters.

---

## 3. The project must live at `E:\Lamplight`

Not a preference. libsodium's build system cannot handle the space in a path like
`…\Claude Code\…`, and its own workaround — build in the Windows temp folder — then hits §2.
Proven, not assumed. `STATE.md` records the same thing.

---

## 4. Building a release, and checking it

```bash
flutter build apk --release
```

The result is at `app/build/app/outputs/flutter-apk/app-release.apk`.

**Then run the check that matters:**

```bash
tool/verify_no_internet.sh app/build/app/outputs/flutter-apk/app-release.apk
```

It reads the permissions out of the **built APK** and fails if any appear. That is deliberately
not a source review: source review cannot see a permission that a dependency merged in through
its own manifest, and the APK is what actually ships. `CLAUDE.md` rule 1 requires this before
every release, and you can run it against the APK on your own phone without trusting anything in
this repository.

You should see no `INTERNET`, no `CAMERA` and no storage permission.

> **The debug and profile builds *do* declare `INTERNET`,** and that is settled and written into
> rule 1 — Flutter needs it to drive hot reload and on-device integration tests. Those variants
> are never uploaded anywhere, and the check above is what enforces the rule mechanically rather
> than by care.

Installing over an existing build:

```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```

**`-r` is not optional.** It patches in place and keeps the vault. And never switch between debug
and release builds on a phone that has a real vault on it: Android treats a different signing key
as a different app and uninstalls first, which deletes everything.

---

## 5. The suite

```bash
flutter test
```

475 tests, and **it is expected to be green**. A red suite here is not a known-issues list; the
22 August 2026 audit found it had been red long enough to stop working as an alarm, and the
finding was not the ten failures — it was that a permanently red suite cannot report an eleventh.
If you see red, that is the thing to fix.

```bash
flutter analyze
```

Also expected to be at zero, for the same reason.

> If a fresh checkout reports something like 7,900 analyzer errors, every one of them is the same
> missing `package_config.json`: the analyzer cannot find Flutter itself, so every widget in every
> file is undefined. Run `flutter pub get` first.
