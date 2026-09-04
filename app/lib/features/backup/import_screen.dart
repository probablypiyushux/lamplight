import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/progress/time_remaining.dart';
import '../../core/db/entry_repository.dart';
import '../../core/platform/document_store.dart';
import '../../core/plain_words.dart';
import '../../core/storage/journal_import.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'time_left_line.dart';

/// "Bring in an old journal" — the way in.
///
/// ── WHY IT SHOWS A PLAN BEFORE IT WRITES ANYTHING ───────────────────────────
///
/// This is the largest single write the app will ever make to somebody's
/// vault: potentially thousands of entries, across years, in one tap. Doing
/// that and *then* reporting what happened would be the app rearranging
/// somebody's records and telling them afterwards.
///
/// So it scans first and says what it found — how many files, how many it can
/// date, and which ones it cannot — and the button underneath commits to
/// exactly that. `ETHICAL-DESIGN.md` is against surprises, and there is no
/// bigger surprise available here.
///
/// The undated files are listed rather than counted, because "15 files have no
/// date" is a shrug and "these 15 files have no date" lets somebody notice that
/// the fifteen are the ones that mattered.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.vault});

  final Vault vault;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum _Phase { idle, scanning, planned, working, done }

class _ImportScreenState extends State<ImportScreen> {
  _Phase _phase = _Phase.idle;
  ImportPlan? _plan;

  /// Whether to fall back to the file's own date for files whose name says
  /// nothing. **ROUND EIGHT, ISSUE 11.**
  ///
  /// Off until asked. See `JournalImport.plan` for why this is offered rather
  /// than assumed — a modification time is a real fact about a file and it is
  /// not the same fact as when something happened.
  bool _useFileDates = false;
  ImportSource? _source;
  ImportResult? _result;
  String _stage = '';
  double _progress = 0;
  final TimeRemaining _eta = TimeRemaining();
  String? _error;
  bool _cancelRequested = false;

  Future<void> _choose() async {
    setState(() => _error = null);

    final ChosenFolder? chosen;
    try {
      chosen = await DocumentStore.pickFolder();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).folderRefused,
          andThen: L.of(context).folderTryAnother,
          words: L.of(context)));
      return;
    }
    // The picker came back with nothing. That is a change of mind, or — far
    // more often — Android refusing the folder inside its own picker, with a
    // message we did not write and never hear about. It will not hand any app
    // the root of internal storage, an SD card root, or Downloads. See the long
    // note in `settings_screen.dart`'s `_chooseFolder`.
    if (chosen == null) {
      if (mounted) {
        setState(() => _error = L.of(context).folderAndroidRestriction);
      }
      return;
    }
    if (!mounted) return;
    // ISSUE 2. Read is all this needs, and read is what a picker will always
    // grant, so there is deliberately no writable check here — asking for
    // write on the way in is what broke all three of these paths.
    final tree = chosen.uri;

    setState(() => _phase = _Phase.scanning);

    try {
      final source = DocumentStoreImportSource(tree);
      final plan =
          await JournalImport.plan(source, useFileDates: _useFileDates);
      if (!mounted) return;
      setState(() {
        _source = source;
        _plan = plan;
        _phase = _Phase.planned;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _error = plainFailure(e,
            fallback: L.of(context).importFolderUnreadable,
            andThen: L.of(context).importNothingBrought,
          words: L.of(context));
      });
    }
  }

  /// The same import, from files rather than from a folder.
  ///
  /// Everything after the picking is shared with [_choose] — the platform
  /// keeps one list of files whichever door filled it, so the plan, the
  /// preview and the run are the same code.
  Future<void> _chooseFiles() async {
    setState(() => _error = null);

    final List<({int index, String path, int size, int modified})>? rows;
    try {
      rows = await DocumentStore.pickTextFiles();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).importFolderUnreadable,
          andThen: L.of(context).importNothingBrought,
          words: L.of(context)));
      return;
    }
    // Backed out. Not an error, and deliberately not a red message: unlike the
    // folder route there is nothing Android could have refused here, so a null
    // means exactly what it looks like.
    if (rows == null) return;
    if (!mounted) return;

    setState(() => _phase = _Phase.scanning);

    try {
      final source = PickedFilesImportSource([
        for (final r in rows)
          ImportFile(
            index: r.index,
            path: r.path,
            size: r.size,
            modified: r.modified,
          ),
      ]);
      final plan =
          await JournalImport.plan(source, useFileDates: _useFileDates);
      if (!mounted) return;
      setState(() {
        _source = source;
        _plan = plan;
        _phase = _Phase.planned;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _error = plainFailure(e,
            fallback: L.of(context).importFolderUnreadable,
            andThen: L.of(context).importNothingBrought,
            words: L.of(context));
      });
    }
  }

  Future<void> _run() async {
    final plan = _plan;
    final source = _source;
    if (plan == null || source == null) return;

    setState(() {
      _phase = _Phase.working;
      _progress = 0;
      _stage = 'Reading…';
      _cancelRequested = false;
    });

    try {
      final result = await JournalImport.run(
        plan: plan,
        source: source,
        repo: EntryRepository(widget.vault.database),
        newId: widget.vault.newId,
        onProgress: (fraction, label) {
          _eta.update(fraction);
          if (!mounted) return;
          setState(() {
            _progress = fraction;
            _stage = label;
          });
        },
        isCancelled: () => _cancelRequested,
      );
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.planned;
        // Whatever landed before the failure is already in the vault and is
        // kept — so the sentence says so rather than implying a clean slate.
        _error = plainFailure(e,
            fallback: L.of(context).importStoppedPartWay,
            andThen: L.of(context).importWhatArrivedKept,
          words: L.of(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: L.of(context).settingsBringIn,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x10),
        children: [
          Text(
            L.of(context).importIntro,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x4),
          Text(
            // ISSUE 11 widened both halves of this, so the old sentence was
            // out of date as well as long. ISSUE 10 took the list of exact
            // formats out: three worked examples of a date is a rule somebody
            // can follow, and a specification of the separators it accepts is
            // the parser talking.
            L.of(context).importHowDates,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x4),
          Text(
            L.of(context).importAmbiguousDates,
            style: t.bodyMedium?.copyWith(color: c.inkMuted, height: 1.5),
          ),
          const SizedBox(height: Space.x6),

          if (_error != null) ...[
            LampError(message: _error!),
            const SizedBox(height: Space.x5),
          ],

          if (_phase == _Phase.idle) ...[
            LampButton(
              label: L.of(context).importChooseFolder, onPressed: _choose),
            const SizedBox(height: Space.x3),
            // ── The way through when the folder is refused ─────────────────
            //
            // Android will not hand any app the root of internal storage, an
            // SD-card root, or **Downloads** -- and Downloads is exactly where
            // a journal exported by another app arrives. The refusal is shown
            // inside Android's own picker, in Android's own words, so no
            // amount of care on this side reaches it.
            //
            // Picking the files is never refused. It is second rather than
            // first because for a real journal folder it is far more tapping;
            // it is here because for the folder Android will not give, it is
            // the only way in.
            // A quiet button, not a second filled one: choosing the folder
            // is the ordinary way and this is the way round a wall. Two equal
            // buttons would make somebody decide before they have hit it.
            TextButton(
              onPressed: _chooseFiles,
              child: Text(L.of(context).importChooseFiles,
                  style: TextStyle(color: c.inkSecondary)),
            ),
            const SizedBox(height: Space.x3),
            Text(
              L.of(context).importChooseFilesNote,
              style: t.bodyMedium?.copyWith(color: c.inkMuted, height: 1.5),
            ),
          ],

          if (_phase == _Phase.scanning) ...[
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Space.x3),
                Text(L.of(context).importLooking, style: t.bodyLarge),
              ],
            ),
          ],

          if (_phase == _Phase.planned) _plannedBody(context),

          if (_phase == _Phase.working) ...[
            Semantics(
              liveRegion: true,
              label: L.of(context).importProgress((_progress * 100).round()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_stage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge),
                  const SizedBox(height: Space.x3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: LinearProgressIndicator(
                        value: _progress, minHeight: 6),
                  ),
                  TimeLeftLine(estimate: _eta),
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

          if (_phase == _Phase.done) _doneBody(context),
        ],
      ),
    );
  }

  Widget _plannedBody(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final plan = _plan!;

    if (plan.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).importNoTextFiles, style: t.bodyLarge),
          const SizedBox(height: Space.x2),
          Text(
            // ISSUE 11 widened this considerably, so the sentence that told
            // people it was two extensions is no longer true — and a screen
            // that understates what it accepts sends somebody away who could
            // have been helped.
            L.of(context).importFormats,
            style: t.bodyMedium?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x5),
          LampButton(
            label: L.of(context).importChooseDifferentFolder,
            onPressed: () => setState(() => _phase = _Phase.idle),
          ),
        ],
      );
    }

    final n = plan.dated.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n == 0
              ? L.of(context).importNoReadableDates
              : L.of(context).importReadyToBring(n),
          style: t.titleLarge,
        ),
        if (n > 0) ...[
          const SizedBox(height: Space.x2),
          Text(
            // Only drawn when `n > 0`, and a plan with notes in it always has
            // both ends — the `??` is for the type system, not for a case
            // that happens.
            L.of(context).importRange(
                plan.earliest ?? '', plan.latest ?? ''),
            style: t.bodyLarge?.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: Space.x4),
          Text(
            L.of(context).importAtStartOfDay,
            style: t.bodyMedium?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
        ],
        if (plan.undated.isNotEmpty) ...[
          const SizedBox(height: Space.x5),
          _UndatedList(paths: plan.undated),
          // ══ ROUND EIGHT, ISSUE 11 — the way to accept the rest ════════
          //
          // *"I want you to make the importing 100% possible! At all times!
          // Accept everything!"*
          //
          // "Skipped" is not an answer to that, and the app cannot invent a
          // date it does not have. What it *can* do is offer the one other
          // fact it knows about the file and say plainly what it is worth —
          // which is what this switch does. Shown only when there are files it
          // would help with, because a control that does nothing is worse than
          // no control.
          //
          // Off by default and phrased as a trade rather than as a
          // recommendation: copying a folder between phones rewrites every
          // modification time to the day it was copied, and the user is the
          // one who knows whether that happened to theirs.
          const SizedBox(height: Space.x4),
          LampSwitchTile(
            title: L.of(context).importUseFileDate,
            subtitle: L.of(context).importFileDateNote,
            value: _useFileDates,
            onChanged: (v) {
              setState(() => _useFileDates = v);
              // Re-planned rather than adjusted, so the counts above and the
              // list below are always the plan that will actually run.
              _replan();
            },
          ),
        ],
        const SizedBox(height: Space.x6),
        if (n > 0)
          LampButton(
              label: L.of(context).importBringIn(n), onPressed: _run),
        const SizedBox(height: Space.x2),
        TextButton(
          onPressed: () => setState(() {
            _phase = _Phase.idle;
            _plan = null;
            _source = null;
          }),
          child: Text(L.of(context).importChooseDifferentFolder,
              style: TextStyle(color: c.inkSecondary)),
        ),
      ],
    );
  }

  /// Works the plan out again with the current options. **ISSUE 11.**
  ///
  /// The screen's whole promise is that what it shows is what will happen, so
  /// changing an option that affects the outcome has to change the numbers on
  /// screen before the button is pressed rather than after.
  Future<void> _replan() async {
    final source = _source;
    if (source == null) return;
    final plan = await JournalImport.plan(source, useFileDates: _useFileDates);
    if (mounted) setState(() => _plan = plan);
  }

  Widget _doneBody(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final r = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, size: 20, color: c.good),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Text(
                r.added == 0
                    ? L.of(context).importNothingNew
                    : L.of(context).importBroughtIn(r.added),
                style: t.bodyLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x4),
        // Every number, including the unflattering ones. A report that only
        // counts successes is how somebody discovers in a year that forty
        // entries never arrived.
        if (r.alreadyHere > 0)
          _Line(L.of(context).importAlreadyHere(r.alreadyHere)),
        if (r.skippedUndated > 0)
          _Line(L.of(context).importNoDateSkipped(r.skippedUndated)),
        if (r.failed.isNotEmpty)
          _Line(L.of(context).importCouldNotRead(
              r.failed.length,
              '${r.failed.take(3).join(', ')}'
                  '${r.failed.length > 3 ? '…' : ''}')),
        const SizedBox(height: Space.x6),
        LampButton(
          label: L.of(context).actionDone,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.x2),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.lamplight.inkSecondary, height: 1.5),
        ),
      );
}

/// The files with no readable date, shown rather than counted.
class _UndatedList extends StatelessWidget {
  const _UndatedList({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final shown = paths.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.borderHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).importFoundUndated(paths.length),
            style: t.titleMedium,
          ),
          const SizedBox(height: Space.x2),
          Text(
            L.of(context).importSkippedNote,
            style: t.bodyMedium?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x3),
          for (final p in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.x1),
              child: Text(
                p,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelMedium?.copyWith(color: c.inkMuted),
              ),
            ),
          if (paths.length > shown.length)
            Text(
              L.of(context).andMore(paths.length - shown.length),
              style: t.labelMedium?.copyWith(color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}
