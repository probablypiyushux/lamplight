import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../core/db/folder_repository.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../core/settings/app_settings.dart';
import '../../design/tokens.dart';

/// Putting one entry into folders.
///
/// A sheet of tick boxes with `+ New folder` at the top, and a single sentence
/// underneath that teaches the entire model:
///
/// > **Still on 4 March. Also in Kavya.**
///
/// `PLAN.md` §9.1 asks for that sentence and asks for it **once, then never
/// again**, which is the correct instinct: it is the one non-obvious thing
/// about folders here, everybody needs to be told it exactly once, and an app
/// that keeps explaining itself is an app that thinks you are slow.
///
/// Whether it has been shown is a display preference, so it lives in the
/// plaintext settings file with the theme — it says nothing about the vault,
/// only that somebody has seen a sentence.
Future<void> showFolderPicker({
  required BuildContext context,
  required Vault vault,
  required String entryId,
  required AppSettings settings,

  /// The day this entry is on, in words — *"4 March"*. Used once, in the one
  /// sentence that teaches what a folder is. See [AppSettings.folderLessonSeen].
  required String dayLabel,
  VoidCallback? onChanged,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  // Read before the sheet, like the messenger above: `L.of(context)` is an
  // inherited lookup and this element may be gone by the time the sheet closes.
  final lesson = L.of(context).folderStill;
  final learned = await showLampSheet<String>(
    context: context,
    builder: (_) => _FolderPicker(
      vault: vault,
      entryId: entryId,
      onChanged: onChanged,
    ),
  );

  // ── The sentence, once, and only when something actually happened ────────
  //
  // Named rather than abstract: *"Still on 4 March. Also in Kavya."* beats
  // *"an entry can be in several places"* because it is about the thing the
  // person is holding. `PLAN.md` §9.1 writes it in exactly those words.
  //
  // Not shown when nothing was added — somebody who opened the picker and
  // changed their mind has not learned anything and should not be taught.
  if (learned == null || settings.folderLessonSeen) return;
  settings.folderLessonSeen = true;
  messenger.showSnackBar(SnackBar(
    content: Text(lesson(dayLabel, learned)),
    duration: const Duration(seconds: 5),
  ));
}

class _FolderPicker extends StatefulWidget {
  const _FolderPicker({
    required this.vault,
    required this.entryId,
    required this.onChanged,
  });

  final Vault vault;
  final String entryId;
  final VoidCallback? onChanged;

  @override
  State<_FolderPicker> createState() => _FolderPickerState();
}

class _FolderPickerState extends State<_FolderPicker> {
  late final FolderRepository _repo = FolderRepository(widget.vault.database);

  List<Folder>? _folders;
  Set<String> _chosen = <String>{};

  /// The first folder this visit *added* the entry to, for the one-time
  /// lesson. Held rather than recomputed, because with instant writing there is
  /// no moment at the end where the before and after can be compared.
  String? _firstAdded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folders = await _repo.all();
    final chosen = await _repo.foldersFor(widget.entryId);
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _chosen = {...chosen};
    });
  }

  /// ══ TICKING IS THE ACT. `PLAN.md` §7.0-E ═════════════════════════════════
  ///
  /// > *"Long-press → sheet → tick → **Done** is four steps for the app's
  /// > central idea."*
  ///
  /// The **Done** is the one of those four that was buying nothing. It made
  /// filing a *form*: the ticks were a draft, and walking away — the phone
  /// ringing, the sheet dragged down, a back gesture — silently threw them
  /// away. Nothing else in this app works like that. Writing an entry saves as
  /// you type; marking one that mattered writes on the tap.
  ///
  /// So a tick writes. `add` and `remove` are a single row each, and there is
  /// no state left to lose by leaving. The button at the bottom stays, and now
  /// only closes — worth keeping rather than removing, because a sheet with no
  /// button is a sheet somebody using a screen reader or a keyboard has to
  /// guess their way out of.
  ///
  /// The vault is marked dirty on the first change and not on every one: a
  /// backup is a whole-file operation and ticking four folders is one edit to
  /// the person doing it.
  Future<void> _toggle(Folder folder, bool on) async {
    setState(() {
      if (on) {
        _chosen.add(folder.id);
        _firstAdded ??= folder.name;
      } else {
        _chosen.remove(folder.id);
      }
    });
    if (on) {
      await _repo.add(widget.entryId, folder.id);
    } else {
      await _repo.remove(widget.entryId, folder.id);
    }
    widget.onChanged?.call();
  }

  Future<void> _newFolder() async {
    final name = await promptForFolderName(context);
    if (name == null || name.trim().isEmpty) return;
    final folder = await _repo.create(id: widget.vault.newId(), name: name);
    if (!mounted) return;
    setState(() => _folders = [...?_folders, folder]);
    // A folder made from inside the picker is made *in order to* put this
    // entry in it. Ticking it as well would be asking the same question twice.
    await _toggle(folder, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final folders = _folders;

    return SafeArea(
      child: Padding(
        // Room for the keyboard when the new-folder dialog is up behind this.
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x5, Space.x6, Space.x2),
              child: Text(L.of(context).folderAddTo, style: t.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, 0, Space.x6, Space.x4),
              child: Text(
                // The standing version, shown every time. The *named* one —
                // "Still on 4 March. Also in Kavya." — is shown once, after the
                // first entry actually lands in a folder. See
                // `AppSettings.folderLessonSeen`.
                L.of(context).folderStaysHere,
                style: t.labelMedium?.copyWith(color: c.inkMuted),
              ),
            ),
            Divider(height: 1, color: c.borderHair),
            Flexible(
              child: folders == null
                  ? const Padding(
                      padding: EdgeInsets.all(Space.x8),
                      child: Center(child: LampBusy()),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        LampTile(
                          title: L.of(context).folderNew,
                          icon: Icons.create_new_folder_outlined,
                          onTap: _newFolder,
                        ),
                        if (folders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                Space.x6, Space.x4, Space.x6, Space.x6),
                            child: Text(
                              L.of(context).folderNoneYet,
                              style:
                                  t.bodyLarge?.copyWith(color: c.inkMuted),
                            ),
                          ),
                        for (final f in folders)
                          _FolderCheck(
                            folder: f,
                            checked: _chosen.contains(f.id),
                            onChanged: (on) => _toggle(f, on),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x4, Space.x6, Space.x5),
              child: LampButton(
                label: L.of(context).actionDone,
                // Closes, and that is all it does — every tick has already been
                // written. See `_toggle`. It returns the first folder this
                // visit added the entry to, which is what the one-time lesson
                // names.
                onPressed: () => Navigator.of(context).pop(_firstAdded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCheck extends StatelessWidget {
  const _FolderCheck({
    required this.folder,
    required this.checked,
    required this.onChanged,
  });

  final Folder folder;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      checked: checked,
      inMutuallyExclusiveGroup: false,
      label: folder.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.x6, vertical: Space.x3),
            child: Row(
              children: [
                // A real box with a real tick. Colour is never the only signal
                // — the tick is the signal and the accent is emphasis on it.
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  color: checked ? c.accent : c.borderStrong,
                  size: 22,
                ),
                const SizedBox(width: Space.x4),
                Expanded(
                  child: Text(folder.name, style: t.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks for a folder name.
///
/// A dialog rather than a sheet, because this one can lose what you typed if
/// it is dismissed by accident — and `DESIGN-SYSTEM.md` reserves dialogs for
/// exactly that.
Future<String?> promptForFolderName(BuildContext context,
    {String initial = ''}) async {
  final controller = TextEditingController(text: initial);
  final c = context.lamplight;
  final result = await showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(initial.isEmpty ? L.of(context).folderNew : L.of(context).folderRenameTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        // A folder name is content — a person's name, a diagnosis, a place.
        // The keyboard may not learn it, for the same reason it may not learn
        // the entries.
        enableIMEPersonalizedLearning: false,
        decoration: InputDecoration(
          hintText: L.of(context).folderNameHint,
          hintStyle: TextStyle(color: c.inkMuted),
        ),
        onSubmitted: (v) => Navigator.of(dialog).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: Text(L.of(context).actionCancel, style: TextStyle(color: c.inkSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(controller.text),
          child: Text(initial.isEmpty ? 'Create' : 'Rename',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
