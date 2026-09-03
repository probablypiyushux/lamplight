import 'dart:async';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../platform/capture.dart';
import '../settings/photo_quality.dart';
import '../settings/video_quality.dart';
import '../vault/vault.dart';
import 'attachment_store.dart';
import 'safe_name.dart';

/// The one road from "Android gave us a file" to "it is in the vault".
///
/// **Every capture path goes through here, and that is the point.** Photos,
/// documents and recordings arrive by three completely different mechanisms,
/// but they all need the same four things done in the same order, and the
/// consequences of getting the order wrong are not cosmetic:
///
/// 1. encrypt the content into the attachment store, streaming, never in RAM;
/// 2. write the database rows — the attachment's key and metadata, and the
///    entry that puts it on a day;
/// 3. **scrub the plaintext**, whatever happened;
/// 4. if anything failed, leave nothing behind.
///
/// Written once, three callers, one place to audit. `CLAUDE.md` rule 2 says
/// there must be a test proving the temp file is scrubbed —
/// `test/storage/attachment_importer_test.dart` proves it for the success path
/// and for every failure path, because the failure paths are the ones where a
/// plaintext photo would actually get left behind.
class AttachmentImporter {
  AttachmentImporter(
    this.vault, {
    VideoQuality Function()? videoQuality,
    PhotoQuality Function()? photoQuality,
  })  : _videoQuality = videoQuality,
        _photoQuality = photoQuality;

  /// How much to compress a video on the way in. **ROUND EIGHT, ISSUE 2A.**
  ///
  /// **A function rather than a value, and that is not indirection for its own
  /// sake.** The day screen builds one importer and keeps it for the life of
  /// the screen; the setting is changed on a different screen and comes back
  /// through a `Navigator.pop`. A value captured at construction would be the
  /// one that was true when the day view was first opened, so changing the
  /// setting and importing a video without leaving the day would quietly use
  /// the old answer — which is the same class of bug as not asking at all, and
  /// harder to notice.
  ///
  /// Read at the moment of import, therefore. Null means the default, so a
  /// caller with no settings to hand — the trash screen, a test — behaves
  /// exactly as the app always has.
  final VideoQuality Function()? _videoQuality;

  VideoQuality get videoQuality => _videoQuality?.call() ?? VideoQuality.balanced;

  /// The same, for a photograph. **ROUND NINE, ISSUE 6.**
  final PhotoQuality Function()? _photoQuality;

  PhotoQuality get photoQuality =>
      _photoQuality?.call() ?? PhotoQuality.balanced;

  final Vault vault;

  AttachmentStore get _store => vault.attachments;

  VaultDatabase get _db => vault.database;

  /// Imports a file the platform handed us, and puts it on [dayKey].
  ///
  /// The [CapturedFile] is scrubbed before this returns, in every case —
  /// success, failure, or an exception thrown halfway through. That is what the
  /// `finally` is for and it is the most important line in the method.
  Future<String> importCaptured({
    required CapturedFile captured,
    required String dayKey,
    String? caption,
    String? groupId,
    /// **ISSUE 12.** 0..1 through this one file, so something on screen can
    /// move. Called with the bytes that have actually been sealed, not with a
    /// timer — a bar that moves on its own is a lie about the thing it claims
    /// to be measuring.
    void Function(double fraction)? onProgress,
    /// What was chosen for **this batch**, if anything was. **ISSUE 6.**
    ///
    /// *"Photos and videos sizes — ask when uploading!"* The sheet's answer
    /// applies to the pick it was asked about and to nothing else — it is not
    /// written to the settings file, because somebody keeping one holiday
    /// video at full size has not changed their mind about every video from
    /// now on. Null falls through to the settings, which is what every other
    /// caller — the share receiver, the journal importer, a test — does.
    PhotoQuality? photoSize,
    VideoQuality? videoSize,

    /// Told when a video was asked to be made smaller and came back the same.
    /// **ISSUE 10.** Not an error path — see the note at the call site.
    void Function(CompressionOutcome outcome)? onVideoKept,
  }) async {
    // ── ISSUE 3 + ISSUE 4 — a video is made smaller before anything else ───
    //
    // *"One minute video can be of 100 mbs or more. Store the video in the
    // compressed size, in a way quality is not compromised."*
    //
    // Here, and not later, for three reasons that all point the same way. The
    // plaintext is already in hand at this moment and will not be again. The
    // poster frame and the dimensions read below must describe the file that
    // is actually stored, not the one that arrived. And doing it before
    // `_ingest` means the encryption, the row and the scrub all happen exactly
    // once, on one file, by the code that already does them.
    //
    // It also quietly answers ISSUE 3's *"play all the formats"*: whatever
    // container the clip arrived in, what gets stored is H.264 in an MP4,
    // which every Android device made in the last decade can play.
    //
    // `compressVideo` returns the original when it cannot help, so this line
    // is safe for a codec nobody has ever heard of.
    // ── ISSUE 12 — what it weighed before ────────────────────────────────
    //
    // "How do I know that the thing is getting compressed?" Measured here,
    // before anything touches it, because this is the last moment the original
    // exists — `compressPhoto` and `compressVideo` scrub what they replace.
    //
    // Never allowed to fail an import: a size that could not be read is a
    // missing claim, not a missing file.
    int? originalSize;
    try {
      originalSize = await captured.file.length();
    } catch (_) {
      originalSize = null;
    }

    var file = captured;
    switch (typeForMime(file.mimeType, file.name)) {
      case 'video':
        // ISSUE 2A. His choice, not ours. `videoQuality` defaults to what the
        // app has always done, so a vault whose owner never opens the setting
        // behaves exactly as it did. ISSUE 6: and a choice made about this
        // particular batch outranks the standing one.
        //
        // **ISSUE 10 — and what came back, not only what.** A transcode that
        // declines is not a failure of the import and must never look like
        // one; it is a fact the person is owed, because they were asked a
        // question and answered it. The outcome is handed to `onVideoKept` so
        // the batch summary can say one plain sentence about it.
        final compressed = await Capture.compressVideo(
          file,
          quality: videoSize ?? videoQuality,
        );
        file = compressed.file;
        if (compressed.outcome != CompressionOutcome.smaller &&
            compressed.outcome != CompressionOutcome.notAsked) {
          onVideoKept?.call(compressed.outcome);
        }
      case 'photo':
        // ISSUE 2. A GIF is skipped — re-encoding one to JPEG would keep the
        // first frame and throw the animation away, which is not compression,
        // it is destruction wearing compression's clothes.
        final n = file.name.toLowerCase();
        if (file.mimeType.toLowerCase() != 'image/gif' && !n.endsWith('.gif')) {
          file = await Capture.compressPhoto(
            file,
            quality: photoSize ?? photoQuality,
          );
        }
    }

    try {
      final bytes = await file.file.length();
      final type = typeForMime(file.mimeType, file.name);

      // ── Measured here, and only here. ISSUE 8. ────────────────────────────
      //
      // The plaintext is in hand for exactly this long, so everything that
      // needs to look at the *content* rather than at the ciphertext has to
      // happen now. A video's poster frame and a picture's dimensions are both
      // that: cheap while the file is open, and ruinous later — extracting a
      // frame on the day view's frame budget would mean decrypting the whole
      // clip every time somebody scrolled past it.
      //
      // Never allowed to fail the import. `Capture.facts` swallows its own
      // errors and returns empty; a video with no thumbnail is a video, and a
      // video that failed to import is a memory somebody has lost.
      //
      // ISSUE 2. This said `poster: type == 'video'`, which meant every audio
      // file imported from elsewhere was probed as if it were a still picture.
      // It came back with nothing, which is why those notes showed 0:00 and a
      // flat bar. The type is passed through now, so audio is probed as audio.
      final facts = await Capture.facts(file.file.path, kind: type);

      return await _ingest(
        // ── ISSUE 12 — the bar moves because bytes moved ──────────────────
        //
        // Counted here, on the plaintext going in, against the size measured
        // a few lines above. Not on the ciphertext coming out, and not on a
        // timer: the point of showing this at all is that he asked what was
        // happening, and a bar that animates regardless answers the question
        // dishonestly.
        //
        // Video is the case that made him ask, and the honest thing about it
        // is that by this point the slow part is over — `compressVideo` above
        // has already run, with no progress of its own to report. So the bar
        // moves at the end of a long silence rather than through it. That is
        // still better than nothing, and the strip says *Adding* rather than
        // claiming to know how far along it is.
        source: _counted(file.file.openRead(), bytes, onProgress),
        dayKey: dayKey,
        type: type,
        originalName: file.name,
        mimeType: file.mimeType,
        byteSize: bytes,
        caption: caption,
        groupId: groupId,
        facts: facts,
        // Only when it actually changed. A PDF or a text file is stored exactly
        // as it arrived, and claiming a saving of zero on it would be a number
        // the app cannot stand behind. Null means "no claim".
        originalSize:
            (originalSize != null && originalSize != bytes) ? originalSize : null,
      );
    } finally {
      // `file`, not `captured`. When a video was compressed, `captured` is the
      // original and `Capture.compressVideo` has already scrubbed it; scrubbing
      // it twice is harmless but scrubbing *only* it would leave the compressed
      // copy on disk in the clear, which is the rule-2 failure this whole
      // method exists to prevent. When nothing was compressed the two are the
      // same object and this is exactly what it always was.
      await file.scrub();
    }
  }

  /// Wraps a source so somebody can watch it go past. **ISSUE 12.**
  ///
  /// A null [onProgress] returns the stream untouched, so the ordinary path
  /// pays nothing at all — not a wrapper, not a closure, not a count.
  static Stream<List<int>> _counted(
    Stream<List<int>> source,
    int total,
    void Function(double)? onProgress,
  ) {
    if (onProgress == null || total <= 0) return source;
    var seen = 0;
    return source.map((chunk) {
      seen += chunk.length;
      // Clamped, because a file can grow between being measured and being
      // read, and a bar that goes past the end is worse than one that stalls
      // at it.
      onProgress((seen / total).clamp(0.0, 1.0));
      return chunk;
    });
  }

  /// Imports a live stream — a recording, which never existed as a file.
  ///
  /// [byteSize] is not known in advance for a recording, so it is measured as
  /// the bytes go past rather than asked for up front.
  Future<String> importStream({
    required Stream<List<int>> source,
    required String dayKey,
    required String type,
    required String originalName,
    required String mimeType,
    int? durationMs,
  }) async {
    var measured = 0;
    final counted = source.map((chunk) {
      measured += chunk.length;
      return chunk;
    });
    return _ingest(
      source: counted,
      dayKey: dayKey,
      type: type,
      originalName: originalName,
      mimeType: mimeType,
      byteSize: () => measured,
      durationMs: durationMs,
    );
  }

  /// The shared middle. [byteSize] is either an int or a callback read after
  /// the stream has been consumed.
  Future<String> _ingest({
    required Stream<List<int>> source,
    required String dayKey,
    required String type,
    required String originalName,
    required String mimeType,
    required Object byteSize,
    int? durationMs,
    String? caption,
    String? groupId,
    MediaFacts facts = const MediaFacts(),
    int? originalSize,
  }) async {
    final stored = await _store.write(source);
    final size = byteSize is int ? byteSize : (byteSize as int Function())();

    // ── The poster frame, encrypted like everything else ──────────────────
    //
    // A second blob in the same store, with its own file key, pointed at by
    // `attachments.thumbnailId`. Reusing the store rather than inventing a
    // thumbnail cache is the whole reason this is a dozen lines: it is already
    // streaming, already keyed per file, already a random UUID on disk that
    // leaks nothing about what it holds.
    //
    // If writing it fails, the import carries on without it. The video is what
    // matters; the picture of the video is not.
    String? posterId;
    final poster = facts.poster;
    if (poster != null && poster.isNotEmpty) {
      try {
        final written = await _store.write(Stream.value(poster));
        await _db.into(_db.attachments).insert(
              AttachmentsCompanion.insert(
                id: written.id,
                fileKey: written.fileKey,
                // Named for what it is, and never shown. The day view reaches
                // it through `thumbnailId`, never by browsing.
                originalName: 'poster.jpg',
                mimeType: 'image/jpeg',
                byteSize: poster.length,
              ),
            );
        posterId = written.id;
      } catch (_) {
        posterId = null;
      }
    }

    final entryId = vault.newId();
    final now = DateTime.now();

    try {
      await _db.transaction(() async {
        await _db.into(_db.attachments).insert(
              AttachmentsCompanion.insert(
                id: stored.id,
                fileKey: stored.fileKey,
                // The real name lives here, in the encrypted database, and
                // never on the filesystem. On disk it is a random UUID with no
                // extension, so browsing app storage cannot tell a voice note
                // from a tax return.
                //
                // ── CLEANED HERE, AT THE INLET ────────────────────────────
                //
                // This name came from a document picker, which got it from
                // another app, which may have got it from anywhere. It is the
                // one part of an imported file that Lamplight actually uses:
                // shown on screen, written into the readable export, and
                // turned into a real path when a file is handed to another
                // app.
                //
                // It used to be stored raw and cleaned at each exit, with a
                // different regex in each. `safe_name.dart` says why that
                // shape of defence loses. Cleaned once, on the way in, so
                // nothing downstream ever holds a hostile name — the exits
                // still clean too, for rows written before this existed.
                originalName: safeFileName(originalName),
                mimeType: mimeType,
                byteSize: size,
                durationMs: Value(durationMs ?? facts.durationMs),
                // ISSUE 12.
                originalSize: Value(originalSize),
                // ISSUE 2. Measured at import for an audio file that arrived
                // from elsewhere; a recording made in the app fills this in
                // afterwards through `setDuration`, because its own shape is
                // only known once it has stopped.
                waveform: Value(facts.waveform),
                // Null for everything until now, which is why the album
                // letterboxed a single portrait photograph into a 4:3 box.
                width: Value(facts.width),
                height: Value(facts.height),
                thumbnailId: Value(posterId),
              ),
            );
        await _db.into(_db.entries).insert(
              EntriesCompanion.insert(
                id: entryId,
                createdAt: now.millisecondsSinceEpoch,
                createdOffsetMinutes: now.timeZoneOffset.inMinutes,
                updatedAt: now.millisecondsSinceEpoch,
                type: type,
                body: Value(caption),
                attachmentId: Value(stored.id),
                dayKey: dayKey,
                groupId: Value(groupId),
              ),
            );
      });
    } catch (_) {
      // The blob is already encrypted and on disk but nothing points at it.
      // An orphan is not a leak — it is unreadable without the key that just
      // failed to be written — but it is wasted space that nothing will ever
      // reclaim, so it goes now rather than waiting for a sweep that does not
      // exist yet.
      await _store.delete(stored.id).catchError((_) {});
      rethrow;
    }

    return entryId;
  }

  /// Records how long a recording turned out to be.
  ///
  /// Not known when the rows are written, because a recording's length is only
  /// known once it has stopped, and the rows have to exist before then so the
  /// encryption has somewhere to go. Written afterwards rather than held back:
  /// an entry that exists without its duration shows "voice note" instead of
  /// "0:42", which is a cosmetic gap. An entry that does not exist until the
  /// recording ends would be lost entirely if the app died mid-recording.
  Future<void> setDuration(
    String entryId,
    int milliseconds, {
    /// The shape of the recording, one byte per sample. See the column comment
    /// on `Attachments.waveform` for why this is written once and never
    /// recomputed.
    Uint8List? waveform,
  }) async {
    final entry = await (_db.select(_db.entries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    final attachmentId = entry?.attachmentId;
    if (attachmentId == null) return;
    await (_db.update(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .write(AttachmentsCompanion(
      durationMs: Value(milliseconds),
      waveform: waveform == null ? const Value.absent() : Value(waveform),
    ));
    forget(attachmentId);
  }

  /// What was said in a recording. **ISSUE 15.**
  ///
  /// The empty string is a real answer — a recording with no speech in it — and
  /// is stored as such rather than as null, so that "we have looked at this and
  /// there was nothing" is distinguishable from "we have not looked at this
  /// yet". `TranscriptionQueue` depends on being able to tell those apart, or
  /// it would try the same silent recording again on every launch for ever.
  /// Puts a recording back in the queue, as if it had never been tried.
  ///
  /// **ROUND TEN.** *"If it can't provide me a transcript don't say nothing was
  /// said in this one!"* — and he is right, so an empty transcript is no longer
  /// presented as an answer. It is still *stored*, because the queue needs a
  /// mark that says "this one has been through" or it would grind the whole
  /// backlog again on every unlock. What changes is that the mark can now be
  /// taken off, by the person looking at the recording, on the one screen where
  /// they can see that it did not work.
  ///
  /// The recording itself is untouched. Only the note about it goes.
  Future<void> forgetTranscript(String attachmentId) async {
    await (_db.update(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .write(const AttachmentsCompanion(transcript: Value(null)));
    forget(attachmentId);
  }

  Future<void> setTranscript(String attachmentId, String text) async {
    await (_db.update(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .write(AttachmentsCompanion(transcript: Value(text)));
    forget(attachmentId);
  }

  /// Voice notes with nothing written down for them yet. **ISSUE 15.**
  ///
  /// Oldest first, so a backlog is worked through in the order it was recorded
  /// — which is the order somebody would want to read it back in, and means the
  /// note you made this morning is not stuck behind six months of history.
  Future<List<Attachment>> voiceWithoutTranscript({int limit = 50}) {
    final query = _db.select(_db.attachments)
      ..where((t) => t.transcript.isNull())
      ..where((t) => t.mimeType.like('audio/%'))
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(limit);
    return query.get();
  }

  /// Where the reader had got to in a document. **ROUND EIGHT, ISSUE 1B.**
  ///
  /// *"It doesn't remembers what was the last page when I closed that PDF."*
  ///
  /// Written once, when the viewer closes, rather than on every frame of a
  /// flick through four hundred pages — that would be four hundred encrypted
  /// writes to record something that only matters when you leave.
  ///
  /// Zero-based. `forget` afterwards, so the next time this attachment's row is
  /// read it comes from the database rather than from a cache that still
  /// believes the old number.
  Future<void> rememberPage(String attachmentId, int page) async {
    await (_db.update(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .write(AttachmentsCompanion(lastPage: Value(page)));
    forget(attachmentId);
  }

  /// Writes down a duration the player discovered. **ISSUE 2 / the 0:00.**
  ///
  /// A voice note in the vault from before any of this — imported when nothing
  /// probed audio files at all — has no stored duration, so its row shows
  /// `--:--` rather than a made-up number. The moment somebody plays it, the
  /// media player knows exactly how long it is, and there is no reason for the
  /// app to forget that again the instant the note scrolls away.
  ///
  /// So it is written down, once, the first time it is learned.
  ///
  /// **Only ever fills a hole.** It refuses to overwrite a duration that is
  /// already there: what was measured from the file at import is more
  /// trustworthy than what a player reports mid-stream, and a value that
  /// rewrites itself on every play is a value nobody can reason about.
  Future<void> learnDuration(String attachmentId, int milliseconds) async {
    if (milliseconds <= 0) return;
    final existing = await (_db.select(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .getSingleOrNull();
    if (existing == null) return;
    if ((existing.durationMs ?? 0) > 0) return;
    await (_db.update(_db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .write(AttachmentsCompanion(durationMs: Value(milliseconds)));
    forget(attachmentId);
  }

  // ── The metadata cache ─────────────────────────────────────────────────────
  //
  /// WHY A CACHE FOR A QUERY THAT RETURNS ONE ROW
  ///
  /// [attachmentFor] used to be called from inside a `FutureBuilder` in a
  /// `build` method, which means it ran **again on every rebuild** — a
  /// keystroke in the composer re-queried the metadata of every photograph on
  /// the day. Each one is a round trip to SQLCipher, which decrypts a page to
  /// answer it. Twenty attachments on a day and a fast typist is a few hundred
  /// decryptions a second, all of them on the isolate drawing the screen.
  ///
  /// An attachment row is written once and then changes exactly once more, when
  /// a recording's duration and waveform land. So it is safe to cache
  /// permanently and invalidate by hand at that one point — [forget].
  ///
  /// Static because the day view builds a fresh [AttachmentImporter] per page,
  /// and the ids are UUIDs, so there is no way for two vaults to collide. It is
  /// emptied when the vault locks, along with everything else.
  static final Map<String, Attachment> _meta = {};

  /// What is already known, with no `await` and no rebuild.
  ///
  /// The reason a scroll past a photograph does not cost a database query: the
  /// widget asks this first and only falls back to the future on a real miss.
  static Attachment? cachedAttachment(String? id) =>
      id == null ? null : _meta[id];

  /// The attachment belonging to an entry id. **ISSUE 12.**
  ///
  /// Used at import to read back the size that was actually written, rather
  /// than trusting an estimate — the number he is shown is the number that is
  /// really in the vault.
  Future<Attachment?> attachmentForEntryId(String entryId) async {
    final entry = await (_db.select(_db.entries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    final id = entry?.attachmentId;
    return id == null ? null : attachmentById(id);
  }

  static void forget(String id) => _meta.remove(id);

  /// Called from the vault when it locks. Metadata is not secret on its own,
  /// but it names files and it belongs to a session that has ended.
  static void forgetEverything() => _meta.clear();

  /// Removes an entry and its blob outright, with no trip through the trash.
  ///
  /// For a capture the user abandoned — a discarded recording, a photo import
  /// that failed halfway. Nothing here was ever finished, so nothing here
  /// should sit in the trash for thirty days waiting to be reconsidered.
  Future<void> discardEntry(String entryId) async {
    final entry = await (_db.select(_db.entries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (entry == null) return;
    final attachmentId = entry.attachmentId;

    await _db.transaction(() async {
      await (_db.delete(_db.entries)..where((t) => t.id.equals(entryId))).go();
      if (attachmentId != null) {
        await (_db.delete(_db.attachments)
              ..where((t) => t.id.equals(attachmentId)))
            .go();
      }
    });
    if (attachmentId != null) {
      forget(attachmentId);
      await _store.delete(attachmentId).catchError((_) {});
    }
  }

  /// Reads an attachment back into memory.
  ///
  /// **In memory, deliberately.** Showing a photo or playing a voice note by
  /// decrypting it to a temp file would put plaintext back on disk and undo the
  /// entire point. Voice notes and photos are small enough for this; a 500 MB
  /// video would not be, and when video arrives it needs a streaming player fed
  /// through a pipe rather than this method.
  /// **On a worker isolate.** Every caller of this is a screen, and decrypting
  /// four megabytes on the isolate that draws the screen is what "the app
  /// hangs" turned out to mean. See `AttachmentStore.readAllBytesOffThread`.
  Future<Uint8List> bytesOf(Attachment attachment) =>
      _store.readAllBytesOffThread(attachment.id, attachment.fileKey);

  Future<Attachment?> attachmentFor(Entry entry) async {
    final id = entry.attachmentId;
    if (id == null) return null;
    return attachmentById(id);
  }

  /// The same lookup, by id rather than by entry.
  ///
  /// A poster frame is an attachment with no entry pointing at it — it is
  /// reached through `attachments.thumbnailId` instead — so it needs this door.
  /// Same cache, same reasoning: a day with six videos should cost six cached
  /// lookups rather than six queries on every rebuild.
  Future<Attachment?> attachmentById(String id) async {
    final hit = _meta[id];
    if (hit != null) return hit;
    final row = await (_db.select(_db.attachments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row != null) _meta[id] = row;
    return row;
  }

  /// The entry type, from a MIME type.
  ///
  /// **Video is its own kind now.** It used to fall through to `file`, so a
  /// clip picked from the gallery arrived as a grey document chip with a name
  /// on it — indistinguishable from a spreadsheet, and giving no hint that
  /// there was anything to watch. `DATA-MODEL.md` names four types and video
  /// was quietly being filed as the wrong one.
  ///
  /// Some pickers hand back `application/octet-stream` for a video they could
  /// not identify, so the filename is the fallback. Guessing from an extension
  /// is not something to be proud of; being wrong about what a file *is* is
  /// worse.
  static String typeForMime(String mime, [String? name]) {
    if (mime.startsWith('image/')) return 'photo';
    if (mime.startsWith('audio/')) return 'voice';
    if (mime.startsWith('video/')) return 'video';

    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp')) {
      return 'video';
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        // ── ISSUE 4 addon ────────────────────────────────────────────────
        //
        // `.gif` was missing from this list, so a GIF whose MIME type the
        // picker could not work out — which is common, because a GIF arriving
        // from a keyboard or a share sheet often comes through as
        // `application/octet-stream` — was filed as a *document* and drawn as
        // a grey file chip. It would never animate because it was never
        // treated as a picture in the first place.
        //
        // `.heif` and `.avif` were missing for the same reason. Android can
        // decode all three, and `EncryptedImage` already falls back to the
        // platform decoder when Skia refuses.
        lower.endsWith('.gif') ||
        lower.endsWith('.heif') ||
        lower.endsWith('.avif') ||
        lower.endsWith('.bmp')) {
      return 'photo';
    }
    if (lower.endsWith('.m4a') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.wav')) {
      return 'voice';
    }
    return 'file';
  }

  /// Takes the attachment off an entry, keeping the words — **into the trash**.
  ///
  /// **The missing half of editing.** A block can hold a photograph *and* a
  /// paragraph about it, and until now the only way to remove the photograph
  /// was to delete the whole entry and retype the paragraph. Reported as
  /// "imagine a block has photo and some texts — if I want to remove the photo
  /// while keeping the texts, not possible", which was exactly true.
  ///
  /// ══ ROUND FIVE, ISSUE C — WHY THIS NO LONGER DESTROYS ANYTHING ═══════════
  ///
  /// It used to delete the attachment row and overwrite the blob, immediately
  /// and for good. He found it and wrote the two lines that describe it better
  /// than this comment could:
  ///
  ///   *Delete → ends up in Trash / sometimes not*
  ///   *Remove → vanishes in thin air, never ends up in trash*
  ///
  /// Both halves were true, and the second was the dangerous one. "Remove the
  /// photo" was an unrecoverable delete presented in softer language than the
  /// recoverable one next to it — the menu's gentlest-sounding option was its
  /// only irreversible one. `ETHICAL-DESIGN.md` calls a control that does
  /// something worse than it says a dark pattern whether or not anybody meant
  /// it that way, and this qualified.
  ///
  /// The "sometimes not" in his first line is the same bug seen from the other
  /// side: on an entry with **no words**, this path hard-deleted the entry row
  /// as well, so deleting a bare photograph skipped the trash entirely while
  /// deleting a photograph with a caption did not. Same menu, same word, two
  /// different fates depending on something invisible.
  ///
  /// So there is now exactly one rule in this file and in `_delete`: **nothing
  /// leaves except through the trash.** Concretely:
  ///
  ///   • **No words** — soft-delete the entry as it stands. It is already
  ///     carrying the attachment, so the trash shows the photograph and *Put
  ///     back* returns it whole. Nothing is copied and nothing is destroyed.
  ///
  ///   • **Words to keep** — the block is *split*. The original keeps the
  ///     paragraph and loses its attachment, and a new, already-soft-deleted
  ///     entry is created carrying the attachment. That row is what appears in
  ///     the trash; putting it back restores the picture as its own block on
  ///     the same day, beside the words it came from.
  ///
  /// Splitting rather than tracking a detached attachment is deliberate. The
  /// trash, the thirty-day purge, restore, and the backup format all already
  /// understand entries and none of them understand an orphaned attachment. A
  /// second concept would have needed a change in each of those four places and
  /// a migration; this needs none, and the thing in the bin is the same kind of
  /// object as everything else in the bin.
  ///
  /// The blob is now deleted in exactly one place — `EntryRepository.purge`,
  /// when the thirty days are up or the trash is emptied by hand.
  /// Returns the id of the row now sitting in the trash, so the caller can
  /// offer an Undo that puts back the right thing. Null only if there was
  /// nothing to remove.
  Future<String?> removeAttachment(String entryId) async {
    final entry = await (_db.select(_db.entries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (entry == null) return null;
    final attachmentId = entry.attachmentId;
    if (attachmentId == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final keepsWords = (entry.body ?? '').trim().isNotEmpty;

    if (!keepsWords) {
      // Nothing to keep, so nothing to split. The entry itself goes to the
      // trash carrying its own attachment.
      await (_db.update(_db.entries)..where((t) => t.id.equals(entryId)))
          .write(EntriesCompanion(deletedAt: Value(now)));
      return entryId;
    }

    final trashedId = vault.newId();
    await _db.transaction(() async {
      // The attachment moves to a new row that is born deleted. It keeps the
      // original's day, time and offset so that it sits where it belongs in
      // the trash list and lands back in the right place if restored.
      await _db.into(_db.entries).insert(
            EntriesCompanion.insert(
              id: trashedId,
              createdAt: entry.createdAt,
              createdOffsetMinutes: entry.createdOffsetMinutes,
              updatedAt: now,
              type: entry.type,
              dayKey: entry.dayKey,
              attachmentId: Value(attachmentId),
              deletedAt: Value(now),
            ),
          );

      await (_db.update(_db.entries)..where((t) => t.id.equals(entryId)))
          .write(EntriesCompanion(
        attachmentId: const Value(null),
        type: const Value('text'),
        updatedAt: Value(now),
      ));
    });
    return trashedId;
  }

  /// Removes the blob behind an entry, if it has one.
  ///
  /// Called from the trash purge. Deleting the row without deleting the blob
  /// would leave an encrypted file nobody can open and nobody will remove,
  /// growing forever.
  static Future<void> deleteBlobFor(Vault vault, Entry entry) async {
    final id = entry.attachmentId;
    if (id == null) return;
    final db = vault.database;
    forget(id);
    await vault.attachments.delete(id).catchError((_) {});
    await (db.delete(db.attachments)..where((t) => t.id.equals(id))).go();
  }
}

/// A filename that says when the thing was made.
///
/// ══ "EVERY VOICE IS SAVED AS voice.aac" ═══════════════════════════════════
///
/// It was, and so was every picture pasted from the keyboard. Anything
/// Lamplight records itself has no name of its own — there is no file on disk
/// to take one from, because the bytes go straight into the vault encrypted —
/// so the capture code passed a constant, and a hundred recordings all arrived
/// called the same thing.
///
/// It was never a *correctness* bug, which is why it survived: the export
/// already refuses to overwrite, so a year of voice notes came out as
/// `Voice note.aac`, `Voice note (1).aac`, `Voice note (2).aac`, all the way to
/// `Voice note (137).aac`. Nothing was lost. But a folder of a hundred and
/// thirty-seven identical names with a counter on them is not a set of
/// recordings anybody can find anything in, and the number says nothing about
/// which is which — they are not even in order, because `(10)` sorts before
/// `(2)`.
///
/// So the name carries the one fact that distinguishes one recording from
/// another and that somebody might actually search for: **when it was made.**
/// `Voice 2026-08-27 14-32-05.aac` sorts chronologically, is unique without a
/// counter, and tells you what you are looking at before you open it.
///
/// ── WHY SECONDS, AND WHY DASHES ──────────────────────────────────────────
///
/// Seconds because two notes a minute apart is an ordinary way to use this app
/// — start, stop, remember one more thing, start again — and without them the
/// counter comes straight back for exactly the pair a person is most likely to
/// want to tell apart.
///
/// Dashes rather than colons because a colon is illegal in a filename on
/// Windows and on every FAT-formatted memory card, and the Readable copy is
/// meant to be a folder somebody can carry anywhere.
///
/// [at] is local time on purpose. The export's own fallback re-derives it from
/// the entry's stored offset, so a note made at nine in the morning in Delhi
/// reads 09-00 even when it is exported from a laptop in London.
String stampedName({
  required String kind,
  required DateTime at,
  required String extension,
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${at.year}-${two(at.month)}-${two(at.day)}';
  final time = '${two(at.hour)}-${two(at.minute)}-${two(at.second)}';
  return '$kind $day $time$extension';
}

/// Human sizes, for a file chip. Not a design flourish — "2.4 MB" tells you
/// whether a document is the one you meant and "2411724" does not.
String humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// `4:07`, from milliseconds.
String humanDuration(int ms) {
  final total = (ms / 1000).round();
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}


/// What compression saved, in words, or null when there is nothing to claim.
///
/// **ISSUE 12 — "how do I know that the thing is getting compressed?"**
///
/// The honest answer had been that he could not know. Photos and videos have
/// been re-encoded at import since round five and the only evidence was a
/// number with nothing to compare it to.
///
/// Three rules, and each of them is about not overclaiming:
///
///   * **Null when the original size is unknown**, which is everything imported
///     before the column existed. The app says nothing rather than implying
///     zero.
///   * **Null when nothing was saved.** A file that grew, or stayed the same,
///     gets no line. Re-encoding occasionally makes a small image slightly
///     larger, and announcing "saved -2%" would be absurd.
///   * **Null below a tenth of a megabyte.** True, uninteresting, and a line of
///     text on screen for it costs more attention than the fact is worth.
String? humanSaving({required int? originalSize, required int storedSize}) {
  if (originalSize == null || originalSize <= storedSize) return null;
  final saved = originalSize - storedSize;
  if (saved < 100 * 1024) return null;
  final percent = ((saved / originalSize) * 100).round();
  return '${humanSize(saved)} smaller — $percent% less than the original';
}
