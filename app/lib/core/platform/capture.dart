import 'dart:io';

import 'package:flutter/services.dart';

import '../settings/photo_quality.dart';
import '../settings/video_quality.dart';

import 'document_store.dart';
import 'system_excursion.dart';

/// Getting a photo, a document or a recording out of Android and into the vault.
///
/// THE SHAPE OF EVERY PATH HERE, AND WHY IT IS THE SAME SHAPE
///
/// Android hands content over as a file. The camera writes a JPEG; the document
/// picker copies bytes; the recorder produces audio. **Every one of those is
/// plaintext, and `CLAUDE.md` rule 2 says no plaintext user content may sit on
/// disk.** The rule also names the remedy: "Every import path must scrub its
/// temp file and there must be a test proving it."
///
/// So every method here returns a [CapturedFile] pointing at a temp file in the
/// app's private cache, and every caller is expected to hand it straight to
/// `AttachmentImporter`, which encrypts it into the vault and then overwrites
/// and deletes it. The window in which plaintext exists is the few hundred
/// milliseconds between the picker returning and the encryption finishing, and
/// it is inside app-private storage the whole time.
///
/// **Voice is the exception, and deliberately.** `TECH-STACK.md` calls
/// streaming-encrypted recording "a hard requirement", because a recording is
/// not a few hundred milliseconds — it is however long someone talks, and a
/// plaintext audio file sitting on disk for four minutes is a different
/// proposition from one sitting there for a moment. So recording never touches
/// the filesystem at all: see [VoiceRecorder].
///
/// PERMISSIONS THIS DOES NOT NEED
///
/// Photos and documents cost **nothing** in the manifest. The camera is taken
/// by the *camera app*, which has the CAMERA permission; we hand it somewhere
/// to write and get a file back. The pickers are the Storage Access Framework,
/// which is designed so that the user granting a file IS the permission. The
/// manifest gains one entry for all of this — `RECORD_AUDIO` — and that is for
/// the microphone alone.
abstract final class Capture {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Opens the camera. Returns null if the user backed out.
  ///
  /// Singular, and it stays singular: a camera takes one photograph at a time.
  static Future<CapturedFile?> takePhoto() async {
    try {
      final result = await SystemExcursion.around(
          () => _channel.invokeMapMethod<String, Object?>('capturePhoto'));
      return result == null ? null : _fromMap(result);
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'The camera could not be opened.');
    }
  }

  /// Opens the gallery. **Several at once.**
  ///
  /// Plural because picking one photo, returning, and tapping the button again
  /// is the wrong unit of work — nobody has one photograph of an afternoon.
  /// Empty means the user backed out, which is not an error.
  static Future<List<CapturedFile>> pickPhotos() => _invokeMany('pickImage');

  /// Opens the system file picker. Also several at once.
  static Future<List<CapturedFile>> pickDocuments() =>
      _invokeMany('pickDocument');

  static Future<List<CapturedFile>> _invokeMany(String method) async {
    try {
      // Wrapped, so the vault knows this backgrounding is one we caused. See
      // system_excursion.dart — without it the camera locks the vault and the
      // photo comes back to a sealed database.
      final result = await SystemExcursion.around(
          () => _channel.invokeListMethod<Object?>(method));
      if (result == null) return const [];
      return [
        for (final item in result)
          _fromMap(Map<String, Object?>.from(item! as Map)),
      ];
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'That could not be opened.');
    }
  }

  static CapturedFile _fromMap(Map<String, Object?> m) => CapturedFile(
        file: File(m['path']! as String),
        name: m['name'] as String? ?? 'file',
        mimeType: m['mime'] as String? ?? 'application/octet-stream',
      );

  /// Re-encodes a video smaller before it is imported. **ISSUE 3 + ISSUE 4.**
  ///
  /// Returns a [CapturedFile] to import instead of [original], or [original]
  /// itself when nothing was gained.
  ///
  /// *"A one minute video can be of 100 mbs or more. I want you to store the
  /// video in the compressed size, in a way quality is not compromised."*
  ///
  /// **The failure mode is the design.** Every way this can go wrong — an
  /// unusual codec, no free hardware encoder, an audio track MP4 cannot carry,
  /// a phone that ran out of memory — returns the original untouched. A clip
  /// that failed to compress is a large clip; a clip lost to a compression bug
  /// is a memory somebody does not get back. Only one of those is acceptable
  /// and it is not the tidy one.
  ///
  /// The old file is scrubbed either way: [CapturedFile.scrub] is called on
  /// whichever file is *not* used, and `AttachmentImporter` scrubs the one that
  /// is. Neither is left behind, which `CLAUDE.md` rule 2 requires and
  /// `test/storage/attachment_importer_test.dart` proves.
  static Future<Compressed> compressVideo(
    CapturedFile original, {
    /// **ROUND EIGHT, ISSUE 2A** — *"do the user wants it compressed?"*
    ///
    /// `VideoQuality.original` never reaches the platform at all: the check is
    /// here rather than in Kotlin so that "keep the original" costs no channel
    /// call, no decoder, and no chance of a transcoder bug touching a file the
    /// user asked us not to touch.
    VideoQuality quality = VideoQuality.balanced,
  }) async {
    if (quality.keepsOriginal) {
      return Compressed(original, CompressionOutcome.notAsked);
    }
    try {
      final row = await _channel.invokeMapMethod<String, Object?>(
          'compressVideo', {'path': original.file.path, 'quality': quality.id});
      final path = row?['path'];
      final reason = row?['reason'];
      if (path is! String || path == original.file.path) {
        return Compressed(original, _outcomeFor(reason));
      }

      final smaller = CapturedFile(
        file: File(path),
        // The name and type the user sees stay theirs. What changed is the
        // bytes, and telling somebody their `holiday.mov` is now
        // `holiday.mov.mp4` would be the app talking about its own plumbing.
        name: original.name,
        mimeType: 'video/mp4',
      );
      // The original is finished with the moment the smaller one exists.
      await original.scrub();
      return Compressed(smaller, CompressionOutcome.smaller);
    } catch (_) {
      // Including a platform with no such method — a widget test, a desktop
      // build. The original is always a valid answer.
      return Compressed(original, CompressionOutcome.couldNot);
    }
  }

  static CompressionOutcome _outcomeFor(Object? reason) => switch (reason) {
        'alreadySmall' => CompressionOutcome.alreadySmall,
        'done' => CompressionOutcome.smaller,
        _ => CompressionOutcome.couldNot,
      };

  /// Re-encodes a photograph smaller before it is imported. **ISSUE 2.**
  ///
  /// Same contract as [compressVideo] in every respect that matters: the
  /// original is returned whenever nothing can be gained, and a failure is
  /// never allowed to cost somebody their photograph.
  ///
  /// Worth knowing about, because it is a real change to what is stored: the
  /// re-encode **drops EXIF**, which on a phone photograph routinely includes
  /// GPS coordinates. That is deliberate and good for a private journal — the
  /// orientation is applied to the pixels first, so nothing comes back
  /// sideways, and the date is already known from the day the entry is on.
  static Future<CapturedFile> compressPhoto(
    CapturedFile original, {
    /// **ROUND NINE, ISSUE 6** — *"photos and videos sizes"*.
    ///
    /// `PhotoQuality.original` never reaches the platform at all, exactly as
    /// `VideoQuality.original` does not: the check is here rather than in
    /// Kotlin so that "keep the original" costs no channel call, no decoder,
    /// and no chance of a re-encoding bug touching a file the user asked us
    /// not to touch.
    PhotoQuality quality = PhotoQuality.balanced,
  }) async {
    if (quality.keepsOriginal) return original;
    try {
      final path = await _channel.invokeMethod<String>(
          'compressPhoto', {'path': original.file.path, 'quality': quality.id});
      if (path == null || path == original.file.path) return original;

      final smaller = CapturedFile(
        file: File(path),
        name: original.name,
        mimeType: 'image/jpeg',
      );
      await original.scrub();
      return smaller;
    } catch (_) {
      return original;
    }
  }

  /// Hands a link to the browser.
  ///
  /// **No INTERNET permission is involved.** We are not opening a socket; we
  /// are asking Android to give an address to whichever app handles the web.
  /// `tool/verify_no_internet.sh` still passes, and that is the whole point —
  /// the app cannot reach the network, it can only ask the system to.
  static Future<bool> openUrl(String url) async {
    try {
      final ok = await SystemExcursion.around<bool?>(
          () => _channel.invokeMethod<bool>('openUrl', {'url': url}));
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// What a file at [path] is, measured once at import. **ISSUE 8.**
  ///
  /// Returns the picture's dimensions, a video's length and poster frame, and
  /// an audio file's length and waveform. See `MediaInfo.kt` for why the video
  /// frame is taken a second in rather than at zero, and why the waveform is
  /// decoded here and nowhere else.
  ///
  /// ── ISSUE 2: this used to take a boolean, and that was the bug ─────────
  ///
  /// The parameter was `poster`, meaning "is this a video". Everything that was
  /// not a video therefore went down the still-picture path, so an imported MP3
  /// was handed to `BitmapFactory`, which declined, and came back empty. That
  /// one boolean is why an imported voice note showed **no waveform** and a
  /// duration of **0:00** on something that plainly played.
  ///
  /// [kind] is the importer's own type string — `photo`, `video` or `voice` —
  /// so a fourth kind can be answered later without inventing a second boolean
  /// that has to agree with the first.
  ///
  /// **Never throws.** A file whose metadata cannot be read is still a
  /// perfectly good file to keep, and losing somebody's video because its
  /// thumbnail failed would be the app protecting a decoration at the cost of
  /// the thing it is decorating.
  static Future<MediaFacts> facts(String path, {required String kind}) async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>(
          'mediaInfo', {'path': path, 'kind': kind});
      if (m == null) return const MediaFacts();
      return MediaFacts(
        width: m['width'] as int?,
        height: m['height'] as int?,
        durationMs: m['durationMs'] as int?,
        poster: m['poster'] as Uint8List?,
        waveform: m['waveform'] as Uint8List?,
      );
    } catch (_) {
      return const MediaFacts();
    }
  }
}

/// What could be learned about a file cheaply, at import.
///
/// Every field is nullable and every one of them is allowed to stay null: this
/// is a set of improvements to how something is *displayed*, and not one of
/// them is worth failing an import over.
class MediaFacts {
  const MediaFacts({
    this.width,
    this.height,
    this.durationMs,
    this.poster,
    this.waveform,
  });

  final int? width;
  final int? height;
  final int? durationMs;

  /// A JPEG, already scaled down. Encrypted into the attachment store like
  /// anything else — a plaintext thumbnail on disk is exactly the leak
  /// `CLAUDE.md` rule 2 names.
  final Uint8List? poster;

  /// **ISSUE 2.** 96 amplitude bytes for an audio file that arrived from
  /// somewhere else, in the same shape and normalisation the live recorder
  /// produces — so the player cannot tell an import from a recording, and
  /// neither can the painter.
  ///
  /// Null when the file could not be decoded, which the waveform painter
  /// already draws honestly as an even row rather than as invented peaks.
  final Uint8List? waveform;

  bool get isEmpty =>
      width == null &&
      height == null &&
      durationMs == null &&
      poster == null &&
      waveform == null;
}

/// A plaintext file, briefly, in app-private storage.
///
/// **Treat every one of these as radioactive.** It is the user's content, in
/// the clear, and the only correct thing to do with it is encrypt it and scrub
/// it. [scrub] is here rather than in the importer so that an error path can
/// reach for it without needing anything else.
class CapturedFile {
  const CapturedFile({
    required this.file,
    required this.name,
    required this.mimeType,
  });

  final File file;

  /// The name Android gave it. Goes into the encrypted database, never onto
  /// the filesystem — a blob on disk is a random UUID with no extension.
  final String name;

  final String mimeType;

  /// Overwrite, then delete.
  ///
  /// The same honest caveat as `AttachmentStore.delete`: on a flash device with
  /// wear levelling, overwriting does not reliably erase the physical cells.
  /// What actually protects this content is that it existed in the clear for
  /// under a second and never left app-private storage. The overwrite is
  /// defence in depth, not the defence — and it does defeat the ordinary case,
  /// which is another app or a file manager reading a deleted file's bytes.
  Future<void> scrub() async {
    if (!await file.exists()) return;
    try {
      final length = await file.length();
      final handle = await file.open(mode: FileMode.writeOnly);
      try {
        const block = 64 * 1024;
        final blank = List<int>.filled(block, 0);
        var remaining = length;
        while (remaining > 0) {
          final n = remaining < block ? remaining : block;
          await handle.writeFrom(blank, 0, n);
          remaining -= n;
        }
        await handle.flush();
      } finally {
        await handle.close();
      }
    } catch (_) {
      // Even if the overwrite fails, the delete below must still happen.
    }
    try {
      await file.delete();
    } catch (_) {}
  }
}

/// What happened to a video on the way in. **ROUND FIFTEEN, ISSUE 10.**
///
/// > *"Video Size – when uploaded it does prompts but never resizes – I want
/// > those features to work!"*
///
/// Half of that was a bug and is fixed in `Transcode.kt`: the resolution cap
/// was applied to the long edge, so "1080" turned a 1920x1080 recording into
/// 1080x606 rather than leaving it alone. The other half is this type.
///
/// `Transcode` has always had a dozen ways to decline — too small to bother,
/// already at a sane bitrate, an audio codec MP4 cannot carry, no free
/// hardware encoder, a ten-bit HDR source an AVC encoder will not take — and
/// every one of them came back as the same silence. The app asked a question,
/// he answered it, and then nothing happened and nothing was said.
///
/// **Three outcomes rather than seven**, because a person can only act on
/// three. There is deliberately no code here for *which* codec was missing:
/// that is a fact about the phone, it changes nothing they can do, and
/// `plain_language_test.dart` would fail the sentence that said it.
enum CompressionOutcome {
  /// It was made smaller.
  smaller,

  /// It was already about as small as it is going to get.
  alreadySmall,

  /// This phone's codecs would not do it. Not something the user can change.
  couldNot,

  /// Nobody asked. "Keep the original" is a setting, not a failure.
  notAsked,
}

/// A file to import, and what happened to it on the way.
class Compressed {
  const Compressed(this.file, this.outcome);

  final CapturedFile file;
  final CompressionOutcome outcome;
}
