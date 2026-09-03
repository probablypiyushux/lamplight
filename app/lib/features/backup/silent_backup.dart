import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/backup/vault_file.dart';
import '../../core/db/entry_repository.dart';
import '../../core/platform/document_store.dart';
import '../../core/plain_words.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../l10n/generated/app_localizations.dart';

/// Backing up without being asked, and without anyone noticing.
///
/// WHEN IT RUNS
///
/// **At unlock. Only at unlock**, and that is the correction rather than the
/// original design.
///
/// Unlock is the one moment the passcode is in our hands, so it is the only
/// moment a backup key can be derived at all. Everything else in this file
/// exists because of that fact.
///
/// ══ IT USED TO ALSO RUN ON THE WAY OUT, AND THAT NEVER WORKED ═════════════
///
/// A second trigger fired on `AppLifecycleState.inactive` — the app has lost
/// focus but is still foregrounded — chosen over `paused` because `paused` is
/// where `UX-FLOWS.md` flow 7 locks the vault and destroys the keys. The
/// security reasoning was right. The timing arithmetic was never done.
///
/// A backup is a second Argon2id at 256 MiB, a copy of the whole database, a
/// verify pass and a write through the Storage Access Framework. `hidden`,
/// where the lock actually happens, arrives **a frame or two** after
/// `inactive`. Seconds of work do not fit in a frame or two, so the run was
/// killed by the lock on essentially every real exit — and having already
/// recorded an attempt, it then blocked the next one for ten minutes.
///
/// It completed only when `inactive` did *not* mean leaving: a notification
/// shade pulled down, an incoming call, a permission dialog. So it succeeded
/// precisely when there was nothing to protect against, failed whenever there
/// was, and left the settings screen saying *"the last automatic backup did not
/// finish"* most of the time.
///
/// **The fix is not to hold the lock open.** `Vault.onBackgrounded` is explicit
/// that settling is for one small write already committed to, and that waiting
/// on a whole backup would keep the DEK alive for as long as the app sat in the
/// background — the one thing lock-on-background exists to prevent. That trade
/// is still refused.
///
/// Instead the *fact* that a backup is owed is written to disk as it happens
/// ([markDirty] → `AppSettings.vaultChangedSinceBackup`), so it survives the
/// process, and the backup runs at the next unlock where it has as long as it
/// needs. The cost is honest and worth stating: what you wrote in a session is
/// backed up when you next open the app, not as you leave it. The quiet
/// reminder banner in flow 5 is what covers somebody who never comes back.
///
/// WHAT STOPS IT THRASHING
///
/// Two guards: nothing runs unless the vault has actually been written to since
/// the last finished backup, and nothing runs twice within [_minimumGap]. Both
/// are in [isDue], which is separated out precisely so it can be tested —
/// tangled inside the run path it had no test, and that is how the above
/// survived.
///
/// WHERE IT WRITES
///
/// A folder the user picked once, through the Storage Access Framework, whose
/// permission Android persists across reboots. We can write into that folder
/// and nowhere else, and the app still has no storage permission of any kind.
class SilentBackup {
  SilentBackup({required this.vault, required this.settings});

  final Vault vault;
  final AppSettings settings;

  /// The app's words, for the one sentence this class writes on its own.
  ///
  /// ── WHY THIS IS SET RATHER THAN LOOKED UP ──────────────────────────────
  ///
  /// A silent backup runs from `app.dart` at unlock, on a path with no
  /// `BuildContext` anywhere in it — that is the whole point of it being
  /// silent. Everything else it might say is written by the screen that shows
  /// it (see `SilentBackupStatus.describeIn`); the exception is the fallback
  /// text on a failure, which is composed here at the moment it happens.
  ///
  /// So the words are handed in once, by the first screen that has a context,
  /// and are null until then. Null falls back to English, which is exactly the
  /// rule the ARB files already follow: **a half-finished translation must
  /// never be why somebody cannot read what happened to their backup.**
  L? words;

  /// Never twice inside this window, however many lifecycle events arrive.
  static const Duration _minimumGap = Duration(minutes: 10);

  bool _running = false;
  DateTime? _lastAttempt;

  /// The most recent outcome, for the settings screen to report honestly.
  final ValueNotifier<SilentBackupStatus> status =
      ValueNotifier(const SilentBackupStatus.idle());

  /// The vault has been written to, so the backup on disk is behind.
  ///
  /// **Written to `settings`, not to a field.** See
  /// `AppSettings.vaultChangedSinceBackup` for what keeping it in memory cost —
  /// in short, the flag died with the process, so the only trigger left was one
  /// that fired in the frame before the vault locked and could never finish.
  ///
  /// Cheap to call repeatedly: the setter returns without touching the disk
  /// when the value is unchanged, which is the common case on every keystroke.
  void markDirty() => settings.vaultChangedSinceBackup = true;

  /// Whether there is somewhere for a backup to go.
  ///
  /// == THIS SAID `backupFolderUri != null` AND IT WAS MINE. 3 Sept 2026 =====
  ///
  /// On 2 September automatic backup stopped needing a chosen folder:
  /// `Documents/Lamplight` is writable with no permission and no picker, which
  /// is the whole repair for "choose folder doesn't work". `silentBackupEnabled`
  /// was updated to match. **This was not**, and it is the second guard on the
  /// same question.
  ///
  /// So for anybody using the new default - which is everybody who has not
  /// deliberately picked a folder - the switch read ON, the screen named the
  /// destination, and `maybeRun` returned on its first line. Every time.
  ///
  /// Two guards asking the same question in two different ways is the defect.
  /// This one now asks `silentBackupEnabled`, which already encodes the whole
  /// rule: enabled, and a destination that exists. There is one answer again.
  bool get isConfigured => settings.silentBackupEnabled;

  /// Derives and keeps this session's backup key.
  ///
  /// Called from the unlock paths, which are the only places a passcode exists.
  /// Cheap to call when silent backup is off: it does nothing, so someone who
  /// does not use the feature never pays the Argon2id and never carries a key.
  ///
  /// Async, and on a worker isolate, because it is a second full Argon2id at
  /// 256 MiB immediately after the one that just opened the vault. Run inline
  /// it doubled the length of every unlock, on the frame the user is watching.
  Future<void> rememberKey(String passcode) async {
    if (!settings.silentBackupEnabled) return;
    final format =
        VaultFile(sodium: vault.sodium, crypto: vault.crypto);
    final key = await format.deriveBackupKey(passcode);
    vault.keepSessionBackupKey(key);
    // Kept for the unlocks that never see a passcode. See the long note on
    // `Vault.sealSilentBackupKey`: a fingerprint unlock could not derive this,
    // so it never backed anything up, and on a phone with a fingerprint that is
    // every launch.
    await vault.sealSilentBackupKey(key);
  }

  /// Recovers the kept backup key after an unlock that had no passcode.
  ///
  /// **This is the fingerprint path, and it is the whole of ISSUE "automatic
  /// backup doesn't work".** `_tryBiometrics` opens the vault through the
  /// keystore and never sees a passcode, so before this existed it left
  /// `sessionBackupKey` null - and `maybeRun` correctly declined every single
  /// time, silently, for as long as the fingerprint kept working.
  ///
  /// Null is not a failure. A vault whose owner has not typed their passcode
  /// since this shipped has nothing kept yet, and the next passcode unlock
  /// puts it there.
  Future<void> recallKey() async {
    if (!settings.silentBackupEnabled) return;
    if (vault.sessionBackupKey != null) return;
    final key = await vault.silentBackupKey();
    if (key != null) vault.keepSessionBackupKey(key);
  }

  /// Whether a backup is warranted right now.
  ///
  /// ══ SEPARATED OUT SO IT CAN BE TESTED ════════════════════════════════════
  ///
  /// This decision used to live inline inside [maybeRun], tangled up with real
  /// Argon2, a real database and a real Storage Access Framework write — none
  /// of which a laptop test can do. So it had **no test at all**, and the bug
  /// it was hiding survived every one of the suite's assertions: the automatic
  /// backup was triggered at a moment it could never finish, and the guard that
  /// should have caught that instead blocked the retry.
  ///
  /// Two things warrant a run, and both are read from disk rather than from
  /// memory, because both outlive the process that noticed them:
  ///
  ///   * the vault has been written to since the last finished backup; or
  ///   * ISSUE 20 — the passcode changed, so the file on disk opens only with
  ///     one its owner has deliberately stopped using. Rewrapping the keyring
  ///     writes nothing anybody would call a change, so the first condition
  ///     never fires for it.
  ///
  /// **The twenty-hour staleness clause that used to be here is gone.** It was
  /// standing in for a dirty flag that could not survive a restart, and it had
  /// both failure modes of any such stand-in: it rewrote an identical vault for
  /// somebody who had not written in a week, and it refused to run for somebody
  /// who wrote every day and opened the app every few hours.
  bool get isDue {
    if (!settings.vaultChangedSinceBackup && !settings.backupOutOfDate) {
      return false;
    }
    // Never twice inside the window, however many unlocks arrive. Unlike the
    // conditions above this one is genuinely per-process: it exists to stop
    // thrashing within a session, not to remember anything across one.
    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < _minimumGap) {
      return false;
    }
    return true;
  }

  /// Runs a backup if one is warranted. Never throws.
  ///
  /// [force] skips [isDue] entirely — used by the settings screen when someone
  /// taps "Back up now" and expects something to happen whatever the guards
  /// think.
  ///
  /// There is no `reason` parameter any more. It used to select between two
  /// different sets of guards for the unlock and leaving triggers; there is one
  /// trigger now, and a parameter that is accepted and ignored reads like it
  /// still steers something.
  Future<void> maybeRun({bool force = false}) async {
    if (!isConfigured || !vault.isUnlocked || _running) return;
    if (!force && !isDue) return;

    final key = vault.sessionBackupKey;
    if (key == null) {
      // Silent backup was switched on during a session that began without it,
      // so there is no key. Nothing is wrong; it starts working at the next
      // unlock, and the settings screen says so rather than failing silently.
      status.value = const SilentBackupStatus.waitingForUnlock();
      return;
    }

    _running = true;
    _lastAttempt = DateTime.now();
    status.value = const SilentBackupStatus.running();

    final scratch = Directory('${vault.root.path}/silent-backup');
    final working = File('${scratch.path}/${_fileName()}');

    try {
      await scratch.create(recursive: true);
      final stats = await EntryRepository(vault.database).stats();
      await vault.checkpoint();

      final format = VaultFile(sodium: vault.sodium, crypto: vault.crypto);
      // ISSUE 17 — so the twelve words open this file too. Null for a vault
      // with no recovery phrase, and for one created before the sealed KEK-R
      // was kept; both then get a file with one wrapper, as before.
      final recoveryKek = await vault.recoveryKekForBackups();
      await format.writeOffThread(
        recoveryKek: recoveryKek,
        destination: working,
        key: key,
        vaultRoot: vault.root,
        counts: {
          'entry_count': stats.entries,
          'day_count': stats.days,
          'attachment_count': 0,
        },
      );

      // Verified before it is handed over, exactly as a manual backup is.
      // BACKUP-FILE-FORMAT.md step 6 does not have an exception for backups
      // nobody watched — if anything, an unwatched backup needs it more,
      // because there is no one there to notice it went wrong.
      await format.verifyOffThread(
        source: working,
        key: key,
        scratch: Directory('${scratch.path}/verify'),
      );

      // ── Where it goes, and why there are two answers ──────────────────
      //
      // `Documents/Lamplight` unless the user has deliberately chosen
      // somewhere else. See `AppSettings.useDefaultBackupFolder` for the whole
      // argument; the short version is that asking Android for a folder is
      // asking for something it may refuse, and a backup nobody could turn on
      // is not a backup.
      //
      // The chosen-folder branch is kept and is not a legacy path: somebody
      // who wants their vault on an SD card should have it there, and anybody
      // who picked a folder before today keeps it without being asked again.
      if (settings.useDefaultBackupFolder || settings.backupFolderUri == null) {
        await DocumentStore.writeIntoDefaultFolder(
          source: working,
          name: _fileName(),
        );
      } else {
        await DocumentStore.writeIntoFolder(
          treeUri: settings.backupFolderUri!,
          source: working,
          name: _fileName(),
        );
      }

      settings.lastBackupAt = DateTime.now();
      // ISSUE 20. Whatever was wrong with the last file, this one does not
      // have it.
      settings.backupOutOfDate = false;
      // Cleared only here, at the end, after the file has been verified *and*
      // handed to the document provider. Clearing it optimistically at the top
      // would mean a backup that failed halfway leaves the vault looking backed
      // up, which is the one lie this feature must never tell.
      settings.vaultChangedSinceBackup = false;
      status.value = SilentBackupStatus.done(DateTime.now());
    } catch (e) {
      // **Never surfaced as a dialog.** A silent backup that failed is a thing
      // to tell someone calmly, on the settings screen, next time they look —
      // not an alert thrown across a journal entry they were in the middle of.
      // The reminder banner in flow 5 is the escalation path, and it is enough.
      status.value = SilentBackupStatus.failed(plainFailure(e,
          fallback: words?.backupAutomaticDidNotFinish ??
              'The automatic backup did not finish.', words: words));
      // Debug builds only. `debugPrint` still writes to logcat in a release
      // build, and an exception's text can carry a filesystem path — which
      // names the user's chosen backup folder, and by extension something about
      // them. The leak hunt in SAFETY-PROMPTS.md lists "exception messages and
      // stack traces" as a classic escape route, and this was one.
      assert(() {
        debugPrint('silent backup failed: $e');
        return true;
      }());
    } finally {
      _running = false;
      if (await scratch.exists()) {
        await scratch.delete(recursive: true).catchError((_) => scratch);
      }
    }
  }

  /// `Lamplight.vault`. **One file, replaced every time. ISSUE B.**
  ///
  /// It was `Lamplight-2026-08-19.vault` — one per day — and the reasoning was
  /// that Android's document provider does not overwrite on a name clash, so a
  /// second backup on the same day became `Lamplight-2026-08-19 (1).vault`
  /// rather than replacing a good copy with a possibly bad one.
  ///
  /// That protected the right thing and produced the wrong result. He counted
  /// it: *"I open the app twice a day, two backups a day; if I open thrice, do
  /// three changes, three backups a day."* Over a month that is a folder nobody
  /// can read, and the person it protects cannot tell which file is current.
  ///
  /// **What he asked for and what he gets:** *"There is a backup file which
  /// gets overwritten every time a backup is done. Just a single backup file
  /// which always gets overwritten. Find a way that it never crashes."*
  ///
  /// The "never crashes" half is not solved here. It is solved in
  /// `MainActivity.writeIntoTree`, which writes the new backup beside the old
  /// one as `Lamplight.vault.part` and only swaps it into place once it is
  /// complete — so there is a complete backup in that folder at every instant,
  /// and the flow-5 rule about never replacing the one good copy with a bad one
  /// is still obeyed. It is obeyed by *ordering* now rather than by
  /// accumulating files.
  ///
  /// No date in the name. A dated name for a file that is replaced would be a
  /// lie the moment the date changed, and the date the backup was taken is
  /// inside it — the settings screen reads it back and shows it.
  String _fileName() => 'Lamplight.vault';
}

/// What the last silent backup did, for the settings screen.
class SilentBackupStatus {
  const SilentBackupStatus.idle()
      : _state = _State.idle,
        at = null,
        message = null;
  const SilentBackupStatus.running()
      : _state = _State.running,
        at = null,
        message = null;
  const SilentBackupStatus.waitingForUnlock()
      : _state = _State.waiting,
        at = null,
        message = null;
  const SilentBackupStatus.done(DateTime this.at)
      : _state = _State.done,
        message = null;
  const SilentBackupStatus.failed(String this.message)
      : _state = _State.failed,
        at = null;

  /// Private, because `_State` is. It used to be a public field of a
  /// private type, which the analyzer objects to for a good reason: nothing
  /// outside this file could name the type, so nothing outside this file could
  /// usefully read the field. Everything a caller wants is below.
  final _State _state;
  final DateTime? at;
  final String? message;

  bool get isRunning => _state == _State.running;

  /// One line, in plain language, for a person who is not a programmer.
  ///
  /// Takes the words rather than holding them, because this object is created
  /// on a background path where there is no `BuildContext` to ask — see the
  /// note on `SilentBackup._l`.
  String describeIn(L l) => switch (_state) {
        _State.idle => l.backupNothingYet,
        _State.running => l.backupInProgress,
        _State.waiting => l.backupStartsAtUnlock,
        _State.done => l.backupDoneAutomatically,
        _State.failed => l.backupLastOneFailed,
      };
}

enum _State { idle, running, waiting, done, failed }
