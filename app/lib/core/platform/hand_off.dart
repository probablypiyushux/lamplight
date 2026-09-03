import 'dart:io';
import '../storage/safe_name.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'capture.dart';
import 'system_excursion.dart';

/// Lending a file to another app for as long as it takes to look at it.
///
/// ══ ISSUE 4, 13 AND THE HANDWRITING — WHAT THIS IS FOR ═══════════════════
///
/// *"If file doesn't opens in Lamplight — I want you to give the option of open
/// with — that majority of messenger app gives."* (ISSUE 4)
///
/// *"Even if the document support is available in the app — I want you to give
/// the option to open with other app."* (ISSUE 13)
///
/// And, in the margin beside a .txt and a .pdf, the sentence that decides the
/// design: *"What I need? A way the user **doesn't download** the file but is
/// able to view this in another app which supports viewing the file format."*
/// With, underneath: *"Give me an option to open the file anywhere else. Why?
/// We can't provide anybody the best in file viewing. We can only give them
/// basic experience."* And: *"chosen these files for representation purpose. I
/// want it on every file type/format."*
///
/// He is right about the reason. Lamplight renders PDFs, pictures and text from
/// memory and does it well, and it is never going to be a better PDF reader
/// than a PDF reader. What it can be is the place the file lives.
///
/// ══ THIS COLLIDES WITH RULE 2, AND HERE IS EXACTLY HOW IT IS RESOLVED ════
///
/// `CLAUDE.md` rule 2 is *"no plaintext user content on disk. Ever."* Handing a
/// file to another app means Android reading it, and Android reads files.
/// `CLAUDE.md` listed this as open and Piyush's to decide. **He decided it on
/// 24 August 2026, in writing, having been shown the trade** — the exact terms
/// he approved were: *"write it to a private FileProvider folder, grant only
/// the chosen app a one-time read, and delete it the moment you come back —
/// plus a test proving nothing is left behind."*
///
/// So this is the narrowest possible version of that, and every clause is load
/// bearing:
///
///   * **App-private, never shared storage.** `cache/handoff/`, declared as the
///     only path in `file_paths.xml` besides the camera's. No other app can
///     list it, and nothing is registered with the media store — so the file is
///     invisible to everything on the phone except the one app given a URI.
///   * **One app, one read, one intent.** `FLAG_GRANT_READ_URI_PERMISSION` on a
///     chooser grants read to whichever app the *user* picks, and to nothing
///     else. Never `FLAG_GRANT_WRITE`.
///   * **It is taken back.** The permission is revoked and the file is
///     overwritten with zeroes and deleted the moment Lamplight is in front
///     again — see [reclaim] — and again when the vault locks, and again at the
///     next launch in case the process died while somebody else had it.
///   * **A test proves it.** `test/storage/nothing_is_left_behind_test.dart`.
///
/// **What this does not do**, and the distinction matters: it is not "save a
/// copy". A saved copy goes wherever the user chose, stays there, and is theirs
/// to manage. This lends a file that is deleted again minutes later without
/// anybody having to remember it. That is what *"doesn't download the file"*
/// means, and it is the safer of the two — which is why it is now the default
/// offer and saving is the deliberate one.
abstract final class HandOff {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// The one directory a lent file may ever live in.
  ///
  /// Under the cache, so that even in the worst case — the process killed
  /// between the grant and the reclaim, on a phone that never launches
  /// Lamplight again — Android will eventually clear it under storage
  /// pressure. That is a backstop, not the plan; the plan is [reclaim].
  static Future<Directory> directory() async {
    // The app's private cache, which is what `cache-path` in file_paths.xml
    // resolves to — the two have to agree or the FileProvider refuses the URI.
    final cache = await getTemporaryDirectory();
    final dir = Directory('${cache.path}/handoff');
    await dir.create(recursive: true);
    return dir;
  }

  /// Everything currently lent out, so it can be taken back.
  ///
  /// A list rather than a single path: a user can open a file, background the
  /// app from inside the other app, come back through the recents list and open
  /// a second one. Tracking only the most recent would strand the first.
  static final Set<String> _lent = <String>{};

  /// Writes [bytes] out under [name] and asks Android who can open it.
  ///
  /// Returns false when nothing on the phone claims the type, so the caller can
  /// say so instead of appearing to do nothing — a chooser with no choices is
  /// the invisible-machinery fault in a dialog.
  ///
  /// The file is scrubbed before this returns if the launch failed, and by
  /// [reclaim] if it succeeded.
  static Future<bool> open({
    required List<int> bytes,
    required String name,
    required String mimeType,
  }) async {
    final dir = await directory();
    // The real name, because the other app shows it and a UUID would be
    // useless to read. It is app-private and nothing else can list the
    // directory, so the name is not a leak here the way it would be in shared
    // storage.
    final file = File('${dir.path}/${_safe(name)}');
    await file.writeAsBytes(bytes, flush: true);
    _lent.add(file.path);

    try {
      final ok = await SystemExcursion.around(() async {
        return await _channel.invokeMethod<bool>('openWith', {
              'path': file.path,
              'mime': mimeType,
              'name': name,
            }) ??
            false;
      });
      // Nothing could open it, so nothing was ever granted and there is no
      // reason to leave the plaintext sitting there until the user comes back.
      if (!ok) await _scrub(file);
      return ok;
    } catch (_) {
      await _scrub(file);
      return false;
    }
  }

  /// Takes back everything that was lent.
  ///
  /// Called when Lamplight returns to the foreground, when the vault locks, and
  /// at launch. Idempotent, and safe to call when nothing is out.
  ///
  /// **Revoke first, then destroy.** The other way round leaves a moment where
  /// a grant is live against a path that has been recreated, which is a small
  /// hole but is exactly the kind that survives into a release.
  static Future<void> reclaim() async {
    try {
      await _channel.invokeMethod<void>('revokeHandOff');
    } catch (_) {
      // Nothing to revoke, or no platform side. The scrub below still runs,
      // which is the half that actually removes the plaintext.
    }
    // The tracked set first, then a sweep of the directory — because a process
    // that was killed mid-excursion comes back with an empty set and a full
    // folder, and that is precisely the case this has to cover.
    for (final path in _lent.toList()) {
      await _scrub(File(path));
    }
    _lent.clear();
    try {
      final dir = await directory();
      await for (final entity in dir.list()) {
        if (entity is File) await _scrub(entity);
      }
    } catch (_) {
      // No directory yet is the common case and is not a failure.
    }
  }

  /// Overwrite, then delete. The same treatment every other temporary
  /// plaintext in this app gets — see [CapturedFile.scrub], which this reuses
  /// rather than reimplements so there is one definition of "gone".
  static Future<void> _scrub(File file) async {
    if (!await file.exists()) return;
    await CapturedFile(
      file: file,
      name: file.uri.pathSegments.last,
      mimeType: 'application/octet-stream',
    ).scrub();
  }

  /// A filename Android will accept and that cannot climb out of the folder.
  ///
  /// The name comes from the attachment row, which came from a picker, which
  /// got it from another app. It has never been trusted and it is not going to
  /// start being trusted at the one point where it becomes a path.
  static String _safe(String name) =>
      safeFileName(name, fallback: 'document');
}
