import 'dart:io';

import 'package:flutter/services.dart';

import 'capture.dart';

/// What another app handed to Lamplight. **ISSUE 13.**
///
/// *"Any app, any file → shared → Lamplight → saved as a note, according to
/// whatever the file is, on that day, that time."*
///
/// The Dart half is deliberately thin. Everything interesting — parking the
/// intent until the vault is open, copying content URIs into private storage,
/// reading display names — is in `Sharing.kt`, because all of it is Android's
/// share contract rather than anything about this app.
///
/// **Nothing here is a new import path.** What comes back is a list of
/// [CapturedFile]s, which is exactly what the camera, the gallery picker and
/// the document picker already return, so a shared photograph goes through
/// `AttachmentImporter` — the same encryption, the same database rows, and the
/// same `finally { scrub() }` that `CLAUDE.md` rule 2 requires. That reuse is
/// the point: a second import path would be a second place for plaintext to be
/// left behind.
abstract final class Sharing {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Something is waiting. Cheap; safe to call at every unlock.
  static Future<bool> hasPending() async {
    try {
      return await _channel.invokeMethod<bool>('hasShared') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Collects it, and clears it.
  ///
  /// **Call only once the vault is unlocked.** The platform side clears the
  /// parked intent as it hands over, so anything not imported after this
  /// returns is gone — which is the right way round. A share that half-arrives
  /// can be sent again; a note that appears twice has to be hunted down and
  /// deleted.
  static Future<SharedContent> take() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('takeShared');
      if (m == null) return const SharedContent();
      final files = <CapturedFile>[];
      for (final item in (m['files'] as List<Object?>? ?? const [])) {
        final f = Map<String, Object?>.from(item! as Map);
        files.add(CapturedFile(
          file: File(f['path']! as String),
          name: f['name'] as String? ?? 'shared',
          mimeType: f['mime'] as String? ?? 'application/octet-stream',
        ));
      }
      return SharedContent(
        text: (m['text'] as String?)?.trim(),
        files: files,
      );
    } catch (_) {
      // A share that could not be collected is not worth an error screen over.
      // Nothing was written, and the user can send it again.
      return const SharedContent();
    }
  }
}

/// One share: some words, some files, or both.
///
/// Both, because that is what the share sheet actually produces — sharing a
/// photograph from a gallery often carries a caption, and sharing a link from a
/// browser carries the page title as text beside it.
class SharedContent {
  const SharedContent({this.text, this.files = const []});

  final String? text;
  final List<CapturedFile> files;

  bool get isEmpty => (text == null || text!.isEmpty) && files.isEmpty;
}
