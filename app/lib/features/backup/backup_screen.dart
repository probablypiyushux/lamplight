import 'dart:io';
import '../../l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';

import '../settings/settings_screen.dart' show AutomaticBackupTiles;
import 'silent_backup.dart';
import 'package:sodium/sodium_sumo.dart' show SecureKey;

import '../../core/backup/vault_file.dart';
import '../../core/db/entry_repository.dart';
import '../../core/plain_words.dart';
import '../../core/platform/document_store.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'restore_screen.dart';

/// `UX-FLOWS.md` flow 5 — "the flow that decides whether people lose their
/// lives' records."
///
/// The sequence is the specification's, in its order, and the order is the
/// design: **confirm the passcode, write, verify, then hand it over.** Verify
/// is not a nicety at step four. It is the step that separates a backup from
/// the belief that you have one, and the belief only ever gets tested on the
/// day it is too late to do anything about it.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.vault,
    required this.settings,
    this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;

  /// So the automatic rows can live here rather than on the settings screen.
  ///
  /// They used to sit loose above "Back up", which meant a person deciding
  /// about backups met half the subject on the way to the rest of it. Both
  /// halves are one screen now — it is one question.
  ///
  /// **Nullable, and the automatic group is simply absent when it is null.**
  /// This screen is also reached from the day view's backup banner and from
  /// the end of a passcode change, neither of which holds a `SilentBackup`.
  /// Threading one through both to render a group nobody arrived for would be
  /// more moving parts than the group is worth; what those two callers came
  /// for is the button that makes a file now.
  final SilentBackup? silentBackup;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

enum _Phase { idle, confirming, working, done }

class _BackupScreenState extends State<BackupScreen> {
  final _passcode = TextEditingController();

  _Phase _phase = _Phase.idle;
  String _stage = '';
  double _progress = 0;
  String? _error;
  bool _cancelRequested = false;
  String? _savedAs;

  @override
  void dispose() {
    _passcode.dispose();
    super.dispose();
  }

  /// `Lamplight.vault`. **One name, everywhere. ISSUE 18.**
  ///
  /// *"A backup made on 23rd August 2026. A backup made on 24th August 2026 —
  /// is nothing but the backup interchanged! Old one gone and new one stays! In
  /// simpler word — 23rd August backup is overwritten by 24th August. ONLY ONE
  /// BACKUP STAYS!"*
  ///
  /// The automatic backup has worked this way since round five. **This one did
  /// not**, and it is the half he was looking at: saving a backup by hand
  /// suggested `Lamplight-2026-08-24.vault`, so every manual save produced
  /// another file, and after a month his folder held a month of them with no
  /// way to tell which was current.
  ///
  /// The dated name was defended on the grounds that a date is informative.
  /// It is, and it is informative about the wrong thing: **the date the backup
  /// was taken is inside the file**, and the settings screen reads it back and
  /// shows it. A date in the filename only tells you when a file you can no
  /// longer distinguish from eleven others was written.
  ///
  /// Same name as the automatic backup, deliberately. Saving by hand into the
  /// folder the automatic backup uses now replaces it rather than sitting
  /// beside it under a second name, which is what "only one backup stays"
  /// means when it is taken seriously.
  String get _suggestedName => 'Lamplight.vault';

  Future<void> _run() async {
    final passcode = _passcode.text;
    _passcode.clear();

    setState(() {
      _phase = _Phase.working;
      _stage = 'Preparing…';
      _progress = 0;
      _error = null;
      _cancelRequested = false;
    });

    // Written into app-private storage first, then copied out through the
    // system picker. The file is fully encrypted from the moment it exists, so
    // it is not plaintext sitting on disk — rule 2 is not in play — and doing
    // it this way means the verify step reads back the exact bytes that will be
    // handed over, rather than a hopeful copy of them.
    final scratch = Directory('${widget.vault.root.path}/backup-scratch');
    final working = File('${scratch.path}/$_suggestedName');

    // Derived once, on its own worker, and used for both the write and the
    // read-back that checks it. Argon2id is a quarter of a second and 256 MiB
    // by design; paying it twice for one backup would be paying it for
    // nothing. Disposed in the `finally` below, whatever happens in between.
    BackupKey? backupKey;
    // ISSUE 17. Disposed in the same finally the backup key is.
    SecureKey? recoveryKek;

    try {
      await scratch.create(recursive: true);

      final stats = await EntryRepository(widget.vault.database).stats();
      // Fold the write-ahead log in first, or the backup is missing everything
      // written since SQLite last checkpointed on its own.
      await widget.vault.checkpoint();

      final format = VaultFile(
        sodium: widget.vault.sodium,
        crypto: widget.vault.crypto,
      );

      backupKey = await format.deriveBackupKey(passcode);
      // ISSUE 17 — the twelve words open this file too.
      recoveryKek = await widget.vault.recoveryKekForBackups();

      setState(() => _stage = 'Writing…');
      await format.writeOffThread(
        destination: working,
        key: backupKey,
        recoveryKek: recoveryKek,
        vaultRoot: widget.vault.root,
        counts: {
          // Counts live in the *encrypted* manifest and never in the header.
          // BACKUP-FILE-FORMAT.md is explicit: an entry count in the header
          // would tell anyone holding the file how much you have written.
          'entry_count': stats.entries,
          'day_count': stats.days,
          'attachment_count': 0,
        },
        onProgress: (f) => setState(() => _progress = f * 0.7),
        isCancelled: () => _cancelRequested,
      );

      setState(() {
        _stage = L.of(context).backupCheckingItOpens;
        _progress = 0.75;
      });
      await format.verifyOffThread(
        source: working,
        key: backupKey,
        scratch: Directory('${scratch.path}/verify'),
      );

      setState(() {
        _stage = 'Saving…';
        _progress = 0.95;
      });
      final savedAs = await DocumentStore.export(
        source: working,
        suggestedName: _suggestedName,
      );

      if (savedAs == null) {
        // They closed the picker. Nothing failed, so nothing is reported as
        // having failed — they are simply back where they started.
        setState(() {
          _phase = _Phase.idle;
          _stage = '';
        });
        return;
      }

      widget.settings.lastBackupAt = DateTime.now();
      // ISSUE 20. This file is sealed under whatever the passcode is now.
      widget.settings.backupOutOfDate = false;
      setState(() {
        _phase = _Phase.done;
        _savedAs = savedAs;
        _progress = 1;
      });
    } on BackupCancelled {
      setState(() {
        _phase = _Phase.idle;
        _stage = '';
      });
    } catch (e) {
      setState(() {
        _phase = _Phase.idle;
        // **ISSUE 2, round nine.** This line used to read
        // `'The backup could not be finished. $e'`, and on the day the backup
        // actually broke, `$e` was two hundred lines of retaining path — three
        // screenshots of it, scrolled past the bottom of the tablet. His note:
        // *"If backup is not possible just give a fucking simple error."*
        //
        // He is owed the first sentence and nothing after it. The cause is a
        // bug in this app, and a bug in this app is not the user's to read.
        _error = plainFailure(
          e,
          fallback: L.of(context).backupCouldNotSave,
          andThen: L.of(context).backupNothingLost,
          words: L.of(context));
      });
    } finally {
      backupKey?.dispose();
      recoveryKek?.dispose();
      // The working copy goes whatever happened. Leaving a spare vault lying
      // around in app storage is exactly the sort of thing that is fine until
      // the day it is not.
      if (await scratch.exists()) {
        await scratch.delete(recursive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: L.of(context).backupTitle,
      child: ListView(
        // ── THREE LEFT EDGES ON ONE SCREEN. 31 August 2026 ────────────────
        //
        // *"UI issue for back up tab under security is also not fixed."* This
        // padding was `fromLTRB(Space.x6, 0, Space.x6, Space.x10)`, and a
        // horizontal pad here is exactly what a screen holding a [LampGroup]
        // must not have: the group carries its **own** margins — `Layout.gutter`
        // for the sheet, `Layout.contentGutter` for the label and footer —
        // because that is the one place the app decides where content starts.
        // Adding 24 outside it did not move the group, it *doubled* it:
        //
        //     the summary, the button, every paragraph   24
        //     the group's sheet          24 + gutter   = 48
        //     "ON ITS OWN" and its footer 24 + content = 64
        //
        // Three edges, in one column, which is the precise complaint
        // `LampGroup`'s own ISSUE 1 note says it exists to prevent. Every other
        // screen that stacks groups — settings, security, media, trash — pads
        // `bottom` only. **This was the only one that did not**, which is why
        // it is the only one that was reported.
        //
        // So the list is flush and the gutter is applied to the children that
        // need it, leaving the group to place itself. `stretch` reproduces the
        // tight cross-axis constraint a `ListView` child already had, so the
        // button stays full width.
        padding: const EdgeInsets.only(bottom: Space.x10),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
            child: _Summary(vault: widget.vault, settings: widget.settings),
          ),
          const SizedBox(height: Space.x8),

          // ── The automatic half, moved here on 28 August 2026 ───────────
          //
          // Automatic and by-hand backups are the same subject and were on two
          // different screens. The footer says when the automatic one runs,
          // which changed the same day: it used to claim it also ran "as you
          // leave", and that had never once finished — see `silent_backup.dart`
          // for what the lock was doing to it.
          //
          // **Not wrapped in the gutter**, and that is the fix above: it places
          // itself, like it does on every other screen in the app.
          if (widget.silentBackup case final backup?) ...[
          LampGroup(
            label: L.of(context).backupOnItsOwn,
            footer: L.of(context).backupAutoFooter,
            children: [
              AutomaticBackupTiles(
                vault: widget.vault,
                settings: widget.settings,
                silentBackup: backup,
              ),
            ],
          ),
          const SizedBox(height: Space.x6),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Layout.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

          if (_phase == _Phase.idle) ...[
            if (_error != null) ...[
              LampError(message: _error!),
              const SizedBox(height: Space.x5),
            ],
            LampButton(
              label: L.of(context).backupCreateFile,
              onPressed: () => setState(() {
                _phase = _Phase.confirming;
                _error = null;
              }),
            ),
          ],

          if (_phase == _Phase.confirming) ...[
            Text(
              // Flow 5 step 1, and the sentence explaining why. A passcode
              // prompt with no reason attached reads as an obstacle; with the
              // reason it reads as the app taking the thing seriously.
              L.of(context).backupConfirmNote,
              style: t.bodyLarge?.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: Space.x4),
            LampPasscodeField(
              controller: _passcode,
              hint: 'Passcode',
              autofocus: true,
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: Space.x5),
            LampButton(
                label: L.of(context).backupCreateFile, onPressed: _run),
            const SizedBox(height: Space.x2),
            TextButton(
              onPressed: () => setState(() {
                _phase = _Phase.idle;
                _passcode.clear();
              }),
              child: Text(L.of(context).actionNotNow,
                  style: TextStyle(color: c.inkSecondary)),
            ),
          ],

          if (_phase == _Phase.working) ...[
            Semantics(
              liveRegion: true,
              label: L.of(context)
                  .backupProgress(_stage, (_progress * 100).round()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_stage, style: t.bodyLarge),
                  const SizedBox(height: Space.x3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x4),
            TextButton(
              onPressed: _cancelRequested
                  ? null
                  : () => setState(() => _cancelRequested = true),
              child: Text(
                _cancelRequested ? 'Stopping…' : 'Stop',
                style: TextStyle(color: c.inkSecondary),
              ),
            ),
          ],

          if (_phase == _Phase.done) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 20, color: c.good),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.of(context).backupCreatedChecked, style: t.bodyLarge),
                      const SizedBox(height: Space.x1),
                      Text(
                        _savedAs ?? '',
                        style: t.labelMedium?.copyWith(color: c.inkSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x5),
            LampButton(
              label: L.of(context).backupMakeAnother,
              onPressed: () => setState(() => _phase = _Phase.idle),
            ),
          ],

          const SizedBox(height: Space.x10),
          Text(
            L.of(context).backupKeepSafeNote,
            style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.6),
          ),
          const SizedBox(height: Space.x8),
          Divider(color: c.borderHair),
          const SizedBox(height: Space.x5),
          Text(L.of(context).backupRestoreHeading, style: t.titleLarge),
          const SizedBox(height: Space.x2),
          Text(
            L.of(context).backupRestoreWarning,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: Space.x4),
          TextButton(
            onPressed: _phase == _Phase.working
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RestoreScreen(vault: widget.vault),
                      ),
                    ),
            child: Text(L.of(context).backupRestoreFrom,
                style: TextStyle(color: c.accent)),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatefulWidget {
  const _Summary({required this.vault, required this.settings});

  final Vault vault;
  final AppSettings settings;

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  // A future built inside `build` is a new query on every rebuild, and a
  // `FutureBuilder` handed a new future goes back to having no data — so the
  // count blinked to an em-dash and back every time anything above it changed.
  // Counting every entry in the vault is not free; doing it once is right.
  late final Future<({int days, int entries})> _stats =
      EntryRepository(widget.vault.database).stats();

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return FutureBuilder<({int days, int entries})>(
      future: _stats,
      builder: (context, snap) {
        final s = snap.data;
        final last = settings.lastBackupAt;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, L.of(context).backupLast,
                last == null
                    ? L.of(context).backupNever
                    : _friendlyDate(last)),
            const SizedBox(height: Space.x2),
            _row(
              context,
              L.of(context).backupInTheVault,
              s == null
                  ? '—'
                  : '${L.of(context).countEntries(s.entries)} · '
                      '${L.of(context).countDays(s.days)}',
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: t.bodyLarge?.copyWith(color: c.inkSecondary)),
        ),
        Expanded(child: Text(value, style: t.bodyLarge)),
      ],
    );
  }

  static String _friendlyDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
