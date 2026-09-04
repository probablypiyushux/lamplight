/// The app's version and build number, as plain constants.
///
/// The version is written into every backup file's header —
/// `BACKUP-FILE-FORMAT.md` has an `app_version` field — so that someone opening
/// a file in 2035 can tell which build wrote it.
///
/// **Not read from the package metadata**, which would mean a plugin
/// (`package_info_plus`) with platform channels on both sides, and `CLAUDE.md`
/// rule 4 counts every avoided dependency as a security property. Every package
/// in this app can read all of the user's notes; one is not worth a string.
///
/// Keep both in step with `version:` in `pubspec.yaml`. `test/app_info_test.dart`
/// fails if they drift apart, so this is checked rather than remembered.
library;

/// The human version — `major.minor.patch`.
///
/// This is the one written into backup headers and shown in Settings.
const String kAppVersion = '0.5.3';

/// The build number — `versionCode` on Android, the `+N` in `pubspec.yaml`.
///
/// ══ WHY THIS EXISTS SEPARATELY, AND WHY IT ONLY EVER GOES UP ═════════════
///
/// He asked on 28 August 2026 whether to start incrementing now or wait until
/// the app is on the Play Store. **Now**, and there are three reasons, in
/// increasing order of how expensive they are to get wrong:
///
/// 1. **Right now nobody can tell which build is on the tablet.** Every APK
///    since the first has said `0.1.0`, so "is the fix on the device?" has been
///    answered by looking at install timestamps. That is the cheap reason and
///    it is already worth it.
///
/// 2. **Android will not install an update whose `versionCode` is lower than
///    the one already there**, and treats *equal* as "nothing to do" on the
///    real update paths. `adb install -r` is more forgiving than a store or a
///    sideloaded update ever will be, so a habit that works today quietly stops
///    working the day it matters.
///
/// 3. **The Play Store retires a `versionCode` permanently.** Upload build 7
///    once and no future artefact may ever call itself 7 again, even if the
///    upload was withdrawn. So the counter cannot be "started properly later" —
///    starting it late only means starting it at a number, and starting it now
///    costs nothing at all.
///
/// **The rule: every build that leaves this laptop increments this.** Not every
/// commit — every artefact. `tool/bump_version.ps1` does both files at once so
/// they cannot drift, and `05-shipping/RELEASE-CHECKLIST.md` has it as step one.
const int kAppBuild = 25;

/// The day the version above belongs to.
///
/// ── HIS RULE, 4 SEPTEMBER 2026 ──────────────────────────────────────────
///
/// > *"all changes done in a day keeps the version same — and make the 0.5.1 to
/// > 0.5.n (not something like build 21). And in another day if changes are
/// > done it's — 0.n+1.n"*
///
/// So the **minor** number is the day and the **patch** counts the artefacts
/// built on it. Everything built on one day shares a minor; the first build of
/// the next day moves it and restarts the patch at one. `0.6.3` is the third
/// thing built on the second day, which is more than `build 23` ever told
/// anybody.
///
/// This constant is what makes that decidable. `tool/bump_version.ps1` compares
/// it against today's date; written down rather than read off a file timestamp,
/// because a checkout, a copy or a zip destroys those and would silently start
/// a new "day" in the middle of an afternoon.
const String kVersionDay = '2026-09-04';

/// What Settings shows, and what a bug report should quote.
///
/// ── THE BUILD NUMBER IS NOT SHOWN ANY MORE ──────────────────────────────
///
/// > *"and why keep it 0.5.0 (Build 21)"*
///
/// A fair question, and the honest answer is that `build 21` was for us and was
/// being shown to him. The version now carries the information it used to: the
/// minor is the day and the patch is the build within it, so `0.6.3` already
/// says which artefact this is.
///
/// **`kAppBuild` still exists and still climbs**, because it must: Google Play
/// refuses an upload whose `versionCode` is not higher than the last, and
/// retires a number permanently once it has been used. It is simply not a
/// number a person should have to read.
String get kAppVersionLabel => kAppVersion;
