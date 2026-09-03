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
const String kAppVersion = '0.5.0';

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
const int kAppBuild = 19;

/// What Settings shows, and what a bug report should quote.
///
/// The build number is the part that identifies an artefact; the version is the
/// part a person can hold in their head. Both, because either alone loses
/// something.
String get kAppVersionLabel => '$kAppVersion (build $kAppBuild)';
