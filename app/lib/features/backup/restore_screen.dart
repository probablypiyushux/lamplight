import 'dart:io';
import '../../l10n/dates.dart';
import '../../l10n/generated/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:sodium/sodium_sumo.dart' show SecureKey;

import '../../core/backup/vault_file.dart';
import '../../core/crypto/mnemonic.dart';
import '../../core/platform/document_store.dart';
import '../../core/plain_words.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// `UX-FLOWS.md` flow 6 — "the moment that earns trust."
///
/// No login. No email. No server round-trip. **Works on a plane.** A file and a
/// passcode, and in ten years when this project is archived, the file and the
/// published format specification are still all it ever needed.
///
/// THE ORDER, AND WHY NOTHING IS DESTROYED UNTIL THE END
///
/// The file is decrypted into a staging directory first and every member is
/// checked against the manifest before anything live is touched. Only then is
/// the current vault *moved aside* — not deleted — and the restored one moved
/// in. The passcode is then used to actually open the result, and only when
/// that works is the old vault let go. If any of it fails, the swap is rolled
/// back and the user is exactly where they started.
///
/// That is what flow 6's "Never leave a half-restored vault" costs, and it is
/// worth every line: this is the screen someone uses on the worst day, holding
/// a new phone, having lost the old one.
class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key, required this.vault});

  final Vault vault;

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

enum _Phase { picking, passcode, working, done }

class _RestoreScreenState extends State<RestoreScreen> {
  final _passcode = TextEditingController();

  /// The twelve words, typed in. **ISSUE 17.**
  final _phrase = TextEditingController();

  _Phase _phase = _Phase.picking;
  File? _picked;
  String? _pickedName;
  BackupInfo? _info;
  String _stage = '';
  double _progress = 0;
  String? _error;
  RestoreSummary? _restored;

  late final VaultFile _format = VaultFile(
    sodium: widget.vault.sodium,
    crypto: widget.vault.crypto,
  );

  /// Whether this app has a backup of its own, so the picker can be skipped.
  bool _hasOwnBackup = false;

  File get _incoming =>
      File('${widget.vault.root.path}/restore-incoming/backup.vault');

  Directory get _staging =>
      Directory('${widget.vault.root.path}/restore-staging');

  @override
  void initState() {
    super.initState();
    // Asked once, so the button that needs no picker can be offered when there
    // is something for it to open. A false answer simply leaves the picker as
    // the only route, which is where this screen started.
    DocumentStore.latestBackupExists().then((has) {
      if (mounted) setState(() => _hasOwnBackup = has);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _passcode.dispose();
    _phrase.dispose();
    super.dispose();
  }

  /// Restore from the backup this app wrote, without opening a picker.
  ///
  /// > *"so man it never shows folders too!"* — and on his tablet the file
  /// picker at the top of internal storage shows `No items`. Everything after
  /// the file is in place is shared with [_pick]; only how it got there
  /// differs.
  Future<void> _useLatest() async {
    setState(() {
      _error = null;
      _stage = L.of(context).restoreCheckingFile;
    });
    try {
      final name = await DocumentStore.copyLatestBackup(destination: _incoming);
      if (name == null) {
        setState(() {
          _stage = '';
          _hasOwnBackup = false;
        });
        return;
      }
      await _inspectAndAsk(name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = '';
        _error = plainFailure(e,
            fallback: L.of(context).restoreCouldNotOpen,
            words: L.of(context));
      });
    }
  }

  Future<void> _pick() async {
    setState(() {
      _error = null;
      _stage = 'Opening…';
    });
    try {
      final name = await DocumentStore.import(destination: _incoming);
      if (name == null) {
        setState(() => _stage = '');
        return;
      }

      await _inspectAndAsk(name);
    } catch (e) {
      await _cleanIncoming();
      setState(() {
        _stage = '';
        _error = plainFailure(e,
            fallback: L.of(context).restoreCouldNotOpen,
            andThen: L.of(context).restoreCheckItIsTheOne,
          words: L.of(context));
      });
    }
  }

  /// Reads the header of whatever is now at [_incoming], and asks for the way in.
  ///
  /// Shared by both doors: the picker and `Use my latest backup`. Only how the
  /// file arrived differs, and nothing downstream should have to know which.
  Future<void> _inspectAndAsk(String name) async {
    // Read the header and check the file's integrity **before** asking for a
    // passcode. Being asked to type a passcode and only then told the file is
    // damaged is a small cruelty, and it is avoidable — none of these checks
    // need a key.
    setState(() => _stage = L.of(context).restoreCheckingFile);
    final info = await _format.inspect(_incoming);
    if (!mounted) return;

    setState(() {
      _picked = _incoming;
      _pickedName = name;
      _info = info;
      // ISSUE 17. Read from the header, so the words are only offered for a
      // file that actually carries the second wrapper.
      _fileTakesPhrase = info.hasRecoveryWrapper;
      _usingPhrase = false;
      _phase = _Phase.passcode;
      _stage = '';
    });
  }

  /// Whether the words are being used instead of the passcode. **ISSUE 17.**
  bool _usingPhrase = false;

  /// Whether this particular file can be opened by the words at all.
  ///
  /// Read from the header when the file is inspected. A v1 backup, or one made
  /// by a vault with no recovery phrase, has only the passcode wrapper — and
  /// offering a way in that the file does not have would be the
  /// invisible-machinery fault in the cruellest possible place: somebody
  /// standing there with the right twelve words being told they are wrong.
  bool _fileTakesPhrase = false;

  Future<void> _restore() async {
    final passcode = _passcode.text;
    final phrase = _phrase.text;
    _passcode.clear();
    setState(() {
      _phase = _Phase.working;
      _stage = 'Decrypting…';
      _progress = 0;
      _error = null;
    });

    Directory? aside;
    try {
      // ── ISSUE 17 — either secret opens the file ──────────────────────
      //
      // The key is derived here rather than inside the format, so that a
      // mistyped word fails as "that is not a word from the list" before
      // anything is decrypted — a different failure from "these are valid
      // words for a different vault", and the two should never be reported
      // the same way.
      SecureKey? recoveryKek;
      if (_usingPhrase) {
        final words = phrase
            .toLowerCase()
            .split(RegExp(r'[\s,]+'))
            .where((w) => w.isNotEmpty)
            .toList();
        try {
          recoveryKek = widget.vault.crypto
              .deriveKeyFromRecoveryEntropy(Mnemonic.toEntropy(words));
        } on MnemonicException catch (e) {
          throw BackupError(e.message);
        }
      }

      final RestoreSummary summary;
      try {
        summary = await _format.extract(
          source: _picked!,
          passcode: _usingPhrase ? null : passcode,
          recoveryKek: recoveryKek,
          staging: _staging,
          onProgress: (f) => setState(() => _progress = f * 0.8),
        );
      } finally {
        recoveryKek?.dispose();
      }

      setState(() {
        _stage = L.of(context).restorePuttingInPlace;
        _progress = 0.85;
      });
      aside = await widget.vault.swapIn(_staging);

      // The proof. A restore that produces a vault which does not open is a
      // failed restore, however cleanly every earlier step went — and the only
      // way to know is to open it.
      setState(() => _stage = L.of(context).backupCheckingItOpens);
      // ISSUE 17. Opened with whichever secret opened the file — the restored
      // vault's own keyring holds both wrappers, so either works, and using
      // the one the user actually has is the only honest check.
      if (_usingPhrase) {
        await widget.vault.unlockWithRecoveryPhrase(
          phrase
              .toLowerCase()
              .split(RegExp(r'[\s,]+'))
              .where((w) => w.isNotEmpty)
              .toList(),
        );
      } else {
        await widget.vault.unlockWithPasscode(passcode);
      }

      await widget.vault.commitSwap(aside);
      aside = null;

      setState(() {
        _phase = _Phase.done;
        _restored = summary;
        _progress = 1;
      });
    } catch (e) {
      if (aside != null) {
        // Put everything back exactly as it was. This is the branch that makes
        // the whole screen safe to use.
        setState(() => _stage = L.of(context).restorePuttingBack);
        await widget.vault.rollbackSwap(aside);
      }
      setState(() {
        _phase = _Phase.passcode;
        _error = e is WrongSecret
            ? "That passcode doesn't open this file."
            // The rollback above has already put the old vault back, so the
            // second sentence is a statement of fact rather than reassurance.
            : plainFailure(e,
                fallback: L.of(context).restoreCouldNotFinish,
                andThen: L.of(context).restoreBackAsTheyWere,
          words: L.of(context));
      });
    } finally {
      if (await _staging.exists()) await _staging.delete(recursive: true);
    }
  }

  Future<void> _cleanIncoming() async {
    final dir = _incoming.parent;
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return PopScope(
      // Not while the vault is mid-swap. There is a handful of milliseconds in
      // which leaving would abandon a rollback, and the cheapest fix is not to
      // allow leaving.
      canPop: _phase != _Phase.working,
      child: LampPage(
        title: L.of(context).restoreTitle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x10),
          children: [
            if (_phase == _Phase.picking) ...[
              Text(
                L.of(context).restoreChooseNote,
                style: t.bodyLarge?.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: Space.x5),
              if (_error != null) ...[
                LampError(message: _error!),
                const SizedBox(height: Space.x5),
              ],
              if (_stage.isNotEmpty) ...[
                Text(_stage, style: t.bodyLarge),
                const SizedBox(height: Space.x4),
              ],
              // ── The door that needs no picker, when there is one ───────
              //
              // Offered first because it is the ordinary case: putting your own
              // journal back from your own backup. The picker below is for a
              // backup kept somewhere else, on a memory card, or sent from
              // another phone -- and it stays, because those are real.
              if (_hasOwnBackup) ...[
                LampButton(
                  label: L.of(context).restoreUseLatest,
                  busy: _stage.isNotEmpty,
                  onPressed: _useLatest,
                ),
                const SizedBox(height: Space.x3),
                TextButton(
                  onPressed: _stage.isNotEmpty ? null : _pick,
                  child: Text(L.of(context).restoreChooseFile,
                      style: TextStyle(color: c.inkSecondary)),
                ),
              ] else
                LampButton(
                  label: L.of(context).restoreChooseFile,
                  busy: _stage.isNotEmpty,
                  onPressed: _pick,
                ),
            ],

            if (_phase == _Phase.passcode) ...[
              Text(_pickedName ?? '', style: t.bodyLarge),
              if (_info?.createdAt != null) ...[
                const SizedBox(height: Space.x1),
                Text(
                  // The date through `LampDates`, so it reads the way the
                  // reader writes dates rather than always d/m/y.
                  '${L.of(context).restoreMadeOn(LampDates.dayMonthYear(context, _info!.createdAt!.toLocal()))}'
                  '${_info!.appVersion != null ? ' · Lamplight ${_info!.appVersion}' : ''}',
                  style: t.labelMedium?.copyWith(color: c.inkSecondary),
                ),
              ],
              const SizedBox(height: Space.x6),
              if (!_usingPhrase) ...[
                Text(
                  // Never "your account password". There isn't one, and saying
                  // so here is the moment the promise from the first screen
                  // becomes something the user has now personally verified.
                  L.of(context).restorePasscodeNote,
                  style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                ),
                const SizedBox(height: Space.x4),
                LampPasscodeField(
                  controller: _passcode,
                  hint: 'Passcode',
                  autofocus: true,
                  onSubmitted: (_) => _restore(),
                ),
              ] else ...[
                // ── ISSUE 17 — the other way in ─────────────────────────
                //
                // "Backup phrase should also be able to open the backup file."
                //
                // The case this is for is the one that actually happens: the
                // phone is gone, and with it the muscle memory of a passcode
                // typed twice a day for a year. The twelve words are the thing
                // that was written down precisely because it would be needed
                // on a day like that.
                Text(
                  L.of(context).restoreWordsNote,
                  style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                ),
                const SizedBox(height: Space.x4),
                TextField(
                  controller: _phrase,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 2,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    hintText: L.of(context).restorePhraseHint,
                  ),
                  onSubmitted: (_) => _restore(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: Space.x4),
                LampError(message: _error!),
              ],
              const SizedBox(height: Space.x5),
              LampButton(
                  label: L.of(context).restoreAction, onPressed: _restore),
              const SizedBox(height: Space.x2),

              // ── ISSUE 17 — offered only when the file has it ───────────
              //
              // A v1 backup, or one made by a vault with no recovery phrase,
              // carries only the passcode wrapper. Showing this for such a file
              // would put somebody in front of a control that accepts their
              // correct twelve words and then tells them they are wrong, which
              // is the worst possible place for a control that does nothing.
              if (_fileTakesPhrase)
                TextButton(
                  onPressed: () => setState(() {
                    _usingPhrase = !_usingPhrase;
                    _error = null;
                    _passcode.clear();
                    _phrase.clear();
                  }),
                  child: Text(
                    _usingPhrase
                        ? L.of(context).restoreUsePasscodeInstead
                        : L.of(context).restoreUseWordsInstead,
                    style: TextStyle(color: c.accent),
                  ),
                ),
              TextButton(
                onPressed: () async {
                  await _cleanIncoming();
                  setState(() {
                    _phase = _Phase.picking;
                    _error = null;
                  });
                },
                child: Text(L.of(context).restoreChooseDifferent,
                    style: TextStyle(color: c.inkSecondary)),
              ),
            ],

            if (_phase == _Phase.working)
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
                          value: _progress, minHeight: 6),
                    ),
                    const SizedBox(height: Space.x4),
                    Text(
                      L.of(context).restoreDoNotClose,
                      style: t.labelMedium?.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),

            if (_phase == _Phase.done) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: c.good),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Text(
                      L.of(context).restoreDone(
                        L.of(context).entriesCount(_restored!.entryCount),
                        L.of(context).daysCount(_restored!.dayCount),
                      ),
                      style: t.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x6),
              LampButton(
                label: L.of(context).calendarGoToToday,
                onPressed: () async {
                  await _cleanIncoming();
                  if (!context.mounted) return;
                  // Straight into today, with nothing in between. The vault is
                  // already unlocked, so popping to the root lands on the day
                  // view — flow 6 step 5.
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
