import 'dart:io';

import '../plain_words.dart';
import 'system_excursion.dart';

import 'package:flutter/services.dart';

/// Handing a file to the user, and taking one back.
///
/// The Dart half of the Storage Access Framework channel in `MainActivity.kt`.
/// Deliberately narrow: Dart names an app-private path and a suggested
/// filename, the platform shows the system picker, and the copy happens over
/// there. **No content URI ever crosses into Dart**, so there is no way for
/// this app to hold on to a handle on the user's storage after the one
/// operation they agreed to.
///
/// Both files that pass through here are already fully encrypted — a `.vault`
/// on the way out, a `.vault` on the way in. `CLAUDE.md` rule 2 is about
/// plaintext, and there is none on either path.
abstract final class DocumentStore {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Copies [source] to a location the user chooses.
  ///
  /// Returns the name it was saved as, or null if they backed out — which is
  /// not an error and must not be shown as one.
  static Future<String?> export({
    required File source,
    required String suggestedName,
  }) async {
    try {
      return await SystemExcursion.around(
        () => _channel.invokeMethod<String>('exportFile', {
          'path': source.path,
          'name': suggestedName,
        }),
      );
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The file could not be saved.');
    }
  }

  /// Copies a file the user chooses into [destination].
  ///
  /// Returns the name of the file they picked, or null if they backed out.
  static Future<String?> import({required File destination}) async {
    try {
      return await SystemExcursion.around(
        () => _channel.invokeMethod<String>('importFile', {
          'path': destination.path,
        }),
      );
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The file could not be opened.');
    }
  }

  /// A folder the user has chosen, and what may be done with it.
  ///
  /// **ISSUE 2.** [writable] is not a detail. A document provider is entitled
  /// to hand back a tree with read access only — which is a perfectly good
  /// answer for *Bring in an old journal* and a useless one for a backup — and
  /// finding that out weeks later, when the first automatic backup fails, is
  /// the exact "silently stopped working" this whole path exists to avoid.
  static const chosenFolderUri = 'uri';
  static const chosenFolderWritable = 'writable';

  /// Asks the user to choose a folder.
  ///
  /// Returns the tree URI and whether it can be written to, or null if they
  /// backed out — which is not an error and must not be shown as one.
  ///
  /// **Android persists this grant across reboots**, which is what makes a
  /// silent backup possible without asking again, and it is still narrower
  /// than a storage permission: it is one folder, chosen deliberately, and it
  /// can be revoked from the system settings like any other grant.
  ///
  /// ── WHY THIS RETURNS A PAIR NOW. ROUND FIFTEEN, ISSUE 2 ─────────────────
  ///
  /// > *"CHOOSE FOLDER OPTION IS GIVEN THAT IS BROKEN! I AM UNABLE TO CHOOSE
  /// > FOLDER"*
  ///
  /// The platform half of that is in `MainActivity.kt`: the grant was being
  /// persisted with hard-coded read **and** write flags rather than with the
  /// flags the picker actually returned, and asking to persist a mode you were
  /// not given throws rather than degrading. The rest of the fix is here and on
  /// the screens: the app now knows whether it may write, so it can say so
  /// while the user is still standing in front of the setting.
  static Future<ChosenFolder?> pickFolder() async {
    try {
      final row = await SystemExcursion.around(() =>
          _channel.invokeMapMethod<String, Object?>('pickBackupFolder'));
      if (row == null) return null;
      final uri = row[chosenFolderUri];
      if (uri is! String || uri.isEmpty) return null;
      return ChosenFolder(uri: uri, writable: row[chosenFolderWritable] == true);
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'That folder could not be used.');
    }
  }

  /// Copies [source] into a folder previously granted by [pickFolder].
  ///
  /// Returns the name it was written as. Android does not overwrite on a name
  /// clash — it appends ` (1)` — so a second backup on the same day sits beside
  /// the first rather than replacing it. `UX-FLOWS.md` flow 5 calls a corrupt
  /// overwrite of your only backup the worst outcome in the entire app, and
  /// this is the cheapest possible defence against it.
  static Future<String> writeIntoFolder({
    required String treeUri,
    required File source,
    required String name,
  }) async {
    try {
      final written = await _channel.invokeMethod<String>('writeIntoFolder', {
        'tree': treeUri,
        'path': source.path,
        'name': name,
      });
      return written ?? name;
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The backup could not be saved.');
    }
  }

  // ── The backup destination that cannot be refused ──────────────────────────
  //
  // ══ "CHOOSE FOLDER DOESN'T WORK MAN! I BEG YOU TO FIX THE FOLDER ISSUE!"
  //    2 September 2026 ═════════════════════════════════════════════════════
  //
  // He sent a photograph: Android's picker at the root of internal storage,
  // *"Can't use this folder — to protect your privacy, choose another
  // folder"*, the button greyed out. He was on `versionCode=12`, which already
  // carried round sixteen's fix, so the fix was not enough.
  //
  // The reason is in `BackupFolder.kt` at length and is one sentence here:
  // **asking Android for a folder is asking for something it is entitled to
  // refuse, and no amount of hinting where the picker opens changes that.**
  // Round sixteen's `EXTRA_INITIAL_URI` decides where the picker *starts*; one
  // tap on the drawer leaves it, and the refusal is Android's own screen.
  //
  // So automatic backup does not ask for a folder any more. On Android 10 and
  // later there is a place every app may write without any permission at all —
  // the shared `Documents` collection — and files put there **outlive the
  // app**, which is the entire requirement. Nothing is granted, so nothing can
  // be refused.
  //
  // Choosing a folder still exists for somebody who wants their backups on an
  // SD card. It is no longer the price of having a backup at all.

  /// Whether this device has the no-permission backup location.
  ///
  /// False below Android 10, where writing outside the sandbox needs
  /// `WRITE_EXTERNAL_STORAGE` — a permission this app will not add, because it
  /// grants the whole of shared storage and would sit in the store listing
  /// beside the claim that Lamplight asks for almost nothing. Those devices
  /// use the picker, and Settings says so instead of offering a switch that
  /// cannot work.
  static Future<bool> defaultFolderAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('defaultBackupFolderAvailable') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// What to call that place on screen — `Documents/Lamplight`.
  ///
  /// Read from the platform rather than written twice, so the folder somebody
  /// is told to look in is the folder the file is actually put in.
  static Future<String?> defaultFolderLabel() async {
    try {
      return await _channel.invokeMethod<String>('defaultBackupFolderLabel');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Writes [source] into `Documents/Lamplight` as [name], replacing whatever
  /// was there, and returns the label to show.
  ///
  /// Safe against interruption in exactly the way [writeIntoFolder] is: a part
  /// file is written and completed first, and only then does the previous
  /// backup go. `UX-FLOWS.md` flow 5 calls a corrupt overwrite of your only
  /// backup the worst outcome in the app, and that does not stop being true
  /// because the destination got easier to reach.
  static Future<String> writeIntoDefaultFolder({
    required File source,
    required String name,
  }) async {
    try {
      final label = await _channel.invokeMethod<String>('writeIntoDefaultFolder', {
        'path': source.path,
        'name': name,
      });
      return label ?? name;
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The backup could not be saved.');
    }
  }

  // ── The readable export ────────────────────────────────────────────────────
  //
  // Everything above this line moves an already-encrypted file. Everything
  // below it moves **plaintext**, and the reason that does not put a hole in
  // rule 2 is that the plaintext never lands on Lamplight's own disk: it is
  // decrypted a chunk at a time in memory and pushed straight into the folder
  // the user chose. See `Export.kt` for the full argument, and
  // `lib/core/backup/plain_export.dart` for what gets written.

  /// Creates the export folder inside a tree granted by [pickFolder].
  ///
  /// Returns the name Android actually used, which may not be the name asked
  /// for — SAF appends ` (1)` rather than overwriting.
  static Future<String> exportBegin({
    required String treeUri,
    required String folderName,
  }) async {
    final name = await _call<String>(
      'exportBegin',
      {'tree': treeUri, 'name': folderName},
    );
    return name ?? folderName;
  }

  /// Opens one file inside the export folder, creating any folders it names.
  ///
  /// [relativePath] uses forward slashes — `2026/2026-08-24.md`.
  static Future<void> exportOpen({
    required String relativePath,
    required String mime,
  }) =>
      _call<void>('exportOpen', {'path': relativePath, 'mime': mime});

  /// Appends to the file opened by [exportOpen].
  static Future<void> exportWrite(Uint8List bytes) =>
      _call<void>('exportWrite', {'bytes': bytes});

  /// Finishes the current file.
  static Future<void> exportCloseFile() => _call<void>('exportCloseFile');

  /// Finishes the export.
  static Future<void> exportFinish() => _call<void>('exportFinish');

  /// Gives up, and deletes the half-written folder.
  ///
  /// Deliberately swallows its own failure. This is what runs when something
  /// has already gone wrong, and the user needs to see the *first* error rather
  /// than a second one about the cleanup.
  static Future<void> exportAbort() async {
    try {
      await _call<void>('exportAbort');
    } catch (_) {}
  }

  // ── The way in ─────────────────────────────────────────────────────────────
  //
  // Note what does NOT come back from `folderScan`: URIs. The platform keeps
  // the list and Dart addresses files by position in it, so the promise at the
  // top of this file — that no content URI ever crosses into Dart — survives a
  // feature that looked like it would have to break it. See `Import.kt`.

  /// Every text file inside a tree granted by [pickFolder].
  ///
  /// Records rather than a domain type, so this file stays at the bottom of
  /// the import's dependency chain rather than in a cycle with it.
  static Future<List<({int index, String path, int size, int modified})>>
      folderScan(
      String treeUri) async {
    final rows = await _call<List<Object?>>('folderScan', {'tree': treeUri});
    return [
      for (final row in rows ?? const <Object?>[])
        if (row is Map)
          (
            index: row['index'] as int,
            // ISSUE 11. Milliseconds since the epoch, or 0 when the provider
            // will not say. Zero means "unknown", never 1970.
            modified: (row['modified'] as int?) ?? 0,
            path: row['path'] as String,
            size: (row['size'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  /// The journal's files, picked one by one, when the folder cannot be given.
  ///
  /// ── WHY THERE IS A SECOND WAY IN ─────────────────────────────────────────
  ///
  /// [pickFolder] asks Android for a whole folder, and Android 11 and later
  /// refuses some of them outright: the root of internal storage, an SD-card
  /// root, and **Downloads** — which is exactly where a journal exported from
  /// another app lands. The refusal is shown inside Android's own picker, in
  /// Android's own words, before anything returns to this app, so nothing here
  /// can catch it or soften it. Three rounds were spent establishing that.
  ///
  /// Picking files is never refused, because it does not ask for the folder.
  /// The person chooses exactly which files, and the grant is per file rather
  /// than a standing key to a directory — which is the smaller ask as well as
  /// the one that works.
  ///
  /// Returns the same rows [folderScan] does, and fills the same platform-side
  /// list, so [folderReadText] and the whole import work unchanged. **No
  /// content URI crosses into Dart** through this door either.
  ///
  /// Null when the person changed their mind.
  static Future<List<({int index, String path, int size, int modified})>?>
      pickTextFiles() async {
    // ── `SystemExcursion.around`, and the reason it is not optional ────────
    //
    // Without it the vault locks the moment DocumentsUI takes the foreground,
    // and the person comes back from choosing their journal to a passcode
    // screen with the import gone. It was written without this line first, and
    // it failed on the tablet exactly that way -- twice, because the second
    // attempt looked like slowness rather than a missing wrapper.
    //
    // `system_excursion.dart` says, at the top: *"the seventh picker somebody
    // adds in a year's time would not have it"*. This was the seventh picker.
    // The rule was right, the prediction was right, and nothing enforced it --
    // so `every_excursion_is_wrapped_test.dart` enforces it now.
    final rows = await SystemExcursion.around(
        () => _call<List<Object?>>('pickTextFiles'));
    if (rows == null) return null;
    return [
      for (final row in rows)
        if (row is Map)
          (
            index: row['index'] as int,
            modified: (row['modified'] as int?) ?? 0,
            path: row['path'] as String,
            size: (row['size'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  /// The contents of one file found by [folderScan].
  static Future<String> folderReadText(int index) async {
    final text = await _call<String>('folderReadText', {'index': index});
    return text ?? '';
  }

  /// Drops the scanned list. Called when an import ends, however it ends.
  static Future<void> folderForget() async {
    try {
      await _call<void>('folderForget');
    } catch (_) {}
  }

  /// The one place the export calls turn a platform failure into ours.
  static Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The export could not be written.');
    }
  }

  /// Whether a folder grant is still good.
  ///
  /// Grants survive reboots but not everything: the user can revoke one, and
  /// an SD card can be removed. Checked before telling anyone their backups are
  /// running, because a settings screen that says "backing up nightly" about a
  /// folder that stopped existing in March is worse than saying nothing.
  static Future<bool> canWriteToFolder(String treeUri) async {
    try {
      return await _channel
              .invokeMethod<bool>('canWriteToFolder', {'tree': treeUri}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

/// Thrown where there is no platform side — a widget test, or a desktop build.
///
/// A distinct type rather than a generic failure so a test can assert on it and
/// so the UI can say something true instead of blaming the user's storage.
class DocumentStoreUnavailable implements Exception, PlainlySaid {
  const DocumentStoreUnavailable();

  @override
  String get plainMessage => toString();

  @override
  String toString() =>
      'Saving and opening files is only available in the Android app.';
}

class DocumentStoreError implements Exception, PlainlySaid {
  const DocumentStoreError(this.message);

  final String message;

  @override
  String get plainMessage => message;

  @override
  String toString() => message;
}

/// A folder the user picked, and what the system will let us do in it.
///
/// **ISSUE 2.** See [DocumentStore.pickFolder].
class ChosenFolder {
  const ChosenFolder({required this.uri, required this.writable});

  /// The opaque tree URI. Never shown to anybody — see `_readableFolder`.
  final String uri;

  /// Whether a file can be created in it. False is a legitimate answer from a
  /// document provider and has to be handled rather than assumed away.
  final bool writable;
}
