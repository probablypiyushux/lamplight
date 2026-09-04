import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/backup/plain_export.dart';
import '../../core/db/day_note_repository.dart';
import '../../core/db/entry_repository.dart';
import '../../core/platform/document_store.dart';
import '../../core/plain_words.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// "Export a readable copy" — the way out of Lamplight.
///
/// ── WHY THIS SCREEN IS SO INSISTENT ABOUT ONE THING ─────────────────────────
///
/// Everything else in this app is built so that content cannot be read without
/// the passcode. This screen deliberately produces a folder that **anybody can
/// read**, and a user who does not understand that has been badly served by us
/// — they will put a plaintext copy of their life in a Downloads folder while
/// believing they made a backup.
///
/// So the warning is not a footnote at the bottom in grey. It is above the
/// button, in full contrast, and it says the true thing in short words:
/// *anyone who opens this folder can read everything in it.*
///
/// `08-design/ETHICAL-DESIGN.md` forbids dark patterns, and it is worth being
/// clear that the same rule cuts both ways here. Making the export sound
/// frightening enough to discourage anyone from leaving would be a dark
/// pattern too — a retention trick wearing a safety warning's clothes. So the
/// screen says what is true, once, plainly, and then gets out of the way. The
/// button is not greyed out, there is no confirmation dialog, and nothing here
/// tries to talk anybody out of it.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.vault});

  final Vault vault;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

enum _Phase { idle, working, done }

class _ExportScreenState extends State<ExportScreen> {
  _Phase _phase = _Phase.idle;
  String _stage = '';
  double _progress = 0;
  String? _error;
  String? _savedAs;
  bool _cancelRequested = false;

  /// The export that asks for nothing. **The ordinary way now.**
  ///
  /// > *"it shows zero files in my redmi tab!"*
  ///
  /// The folder picker lists only directories and hides the ones Android will
  /// not grant, so at the root of internal storage it draws *"Can't use this
  /// folder"* over an empty list. Reproduced on his tablet on 4 September. So
  /// this writes to `Documents/Lamplight/<name>` the way automatic backup
  /// already does -- no permission, no picker, and a folder any file manager
  /// can open.
  Future<void> _runDefault() async {
    setState(() {
      _error = null;
      _cancelRequested = false;
      _phase = _Phase.working;
      _stage = L.of(context).exportStarting;
      _progress = 0;
    });
    final locale = Localizations.localeOf(context).toLanguageTag();
    await _export(const DefaultFolderSink(), locale);
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _cancelRequested = false;
    });

    // The folder is chosen before anything starts, so a user who backs out of
    // the picker has not started an export they now have to cancel.
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
    // ISSUE 2. A read-only tree is a legal answer from a document provider
    // and there is nothing to be done with one here. Said now, rather than
    // after the export has walked the whole vault.
    if (!chosen.writable) {
      setState(() => _error = L.of(context).folderNotWritable);
      return;
    }
    final tree = chosen.uri;

    setState(() {
      _phase = _Phase.working;
      _stage = L.of(context).exportStarting;
      _progress = 0;
    });

    // Read before the await, while the element is certainly still mounted.
    // `PlainExport` runs off the tree by design and cannot look this up itself.
    final locale = Localizations.localeOf(context).toLanguageTag();

    await _export(DocumentStoreSink(tree), locale);
  }

  /// Everything after the destination is decided, shared by both doors.
  Future<void> _export(ExportSink sink, String locale) async {
    try {
      final name = await PlainExport.run(
        sink: sink,
        repo: EntryRepository(widget.vault.database),
        dayNotes: DayNoteRepository(widget.vault.database),
        attachments: widget.vault.attachments,
        now: DateTime.now(),
        locale: locale,
        onProgress: (fraction, label) {
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
        _savedAs = name;
      });
    } on ExportCancelled {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _stage = '';
        _progress = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        // ISSUE 16. Half-written files are cleaned up above; what is left to
        // say is that nothing in the vault moved, which is the only thing a
        // person actually wants to know when an export stops.
        _error = plainFailure(e,
            fallback: L.of(context).exportCouldNotFinish,
            andThen: L.of(context).exportNothingChanged,
          words: L.of(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: L.of(context).settingsReadableCopy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x10),
        children: [
          Text(
            L.of(context).exportIntro,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x4),
          Text(
            L.of(context).exportNoLamplightNeeded,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.5),
          ),
          const SizedBox(height: Space.x6),

          // The one thing on this screen that must not be missed.
          _NotLockedNotice(),

          const SizedBox(height: Space.x6),

          if (_phase == _Phase.idle) ...[
            if (_error != null) ...[
              LampError(message: _error!),
              const SizedBox(height: Space.x5),
            ],
            // ── The default first, the picker second ────────────────────
            //
            // Reversed on 4 September. Choosing a folder used to be the only
            // way, and on his tablet it drew "Can't use this folder" over an
            // empty list -- *"it shows zero files in my redmi tab"*. The
            // picker still works and is still here, for an SD card or a folder
            // somebody wants for their own reasons; it is simply no longer the
            // thing standing between a person and their own writing.
            LampButton(
              label: L.of(context).exportSave, onPressed: _runDefault),
            const SizedBox(height: Space.x3),
            TextButton(
              onPressed: _run,
              child: Text(L.of(context).exportChooseFolder,
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
                      Text(L.of(context).exportWritten, style: t.bodyLarge),
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
              label: L.of(context).exportAgain,
              onPressed: () => setState(() {
                _phase = _Phase.idle;
                _savedAs = null;
              }),
            ),
          ],

          const SizedBox(height: Space.x10),
          Divider(color: c.borderHair),
          const SizedBox(height: Space.x5),
          Text(L.of(context).exportWhichOne, style: t.titleLarge),
          const SizedBox(height: Space.x3),
          Text(
            L.of(context).exportWhichOneBody,
            style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// The warning, given its own widget so it cannot be quietly demoted to a
/// footnote by a later layout change.
class _NotLockedNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.borderHair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_open_outlined, size: 20, color: c.inkSecondary),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.of(context).exportNotLocked, style: t.titleMedium),
                const SizedBox(height: Space.x2),
                Text(
                  L.of(context).exportNotLockedBody,
                  style: t.bodyMedium
                      ?.copyWith(color: c.inkSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
