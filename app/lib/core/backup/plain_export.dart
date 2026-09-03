import 'dart:convert';
import 'dart:typed_data';

import '../db/database.dart';
import '../../l10n/dates.dart';
import '../storage/safe_name.dart';
import '../db/day_note_repository.dart';
import '../db/entry_repository.dart';
import '../platform/document_store.dart';
import '../storage/attachment_importer.dart' show stampedName;
import '../storage/attachment_store.dart';

/// Writing the whole vault out as Markdown and ordinary files.
///
/// ── THE ARGUMENT FOR THIS FEATURE ───────────────────────────────────────────
///
/// `08-design/ETHICAL-DESIGN.md` §3 says never obstruct leaving, and until this
/// existed the app obstructed leaving completely: the only way out was a
/// `.vault` file that only Lamplight can open. That is lock-in, and the first
/// question anybody sceptical asks a one-person privacy project is not *"is
/// your encryption good"* — it is **"what happens to my notes when you stop
/// working on this?"**
///
/// The answer has to be a folder they can open with anything they already own.
/// Not a proprietary archive, not a database, not a format that needs this app
/// to have survived. Markdown files and the original photographs.
///
/// This is also, counter-intuitively, a *trust* feature rather than a
/// concession. An app that will cheerfully hand back everything it holds, in
/// the clear, on demand, is an app you can afford to put your life into —
/// precisely because it is not holding you.
///
/// ── WHY IT DOES NOT WIDEN RULE 2 ────────────────────────────────────────────
///
/// It writes plaintext. It writes it **into the folder the user chose, and
/// nowhere else.** Every attachment is decrypted one 64 KiB chunk at a time and
/// each chunk goes straight out through the channel; Lamplight's own storage
/// never holds a plaintext byte at any point. See `Export.kt`.
///
/// The one exception in `CLAUDE.md` rule 2 — `cache/handoff/` — is untouched by
/// this, and this adds no second exception. That was a design constraint, not
/// an afterthought: staging the export in our own cache would have been three
/// times easier and would have put the user's entire life in the clear on the
/// phone for the length of the export.
///
/// ── THE SHAPE OF WHAT COMES OUT ─────────────────────────────────────────────
///
/// ```
/// Lamplight export 2026-08-24/
///   README.md                     what this folder is, in plain words
///   Journal/
///     2026/
///       2026-08-24.md             one file per day, entries in time order
///   Media/
///     IMG_2031.jpg                the originals, under their own names
/// ```
///
/// One file per **day** rather than per entry, because the day is the unit this
/// app is organised around and a folder of nine thousand two-line files is not
/// something a person can read. Years as directories because a flat folder of
/// three thousand days is the same problem one level up.
///
/// Relative links, always. An export that only resolves at the absolute path it
/// was written to is an export that breaks the first time somebody moves it,
/// which they will, immediately, because the first thing anyone does with a
/// backup is put it somewhere else.
/// Where an export's bytes go.
///
/// One interface with two implementations, and the reason is testability
/// rather than tidiness. The real one is a method channel into `Export.kt`,
/// which cannot run in a `flutter test` — so without this seam the only way to
/// check that the Markdown is correct would be to build an APK and read a
/// folder on a phone by hand, every time.
///
/// `CLAUDE.md` test 7 — *"stop the issue from taking place at first place"* —
/// applies with unusual force here. This code writes the copy somebody keeps
/// **after** they stop using Lamplight. A mistake in it is discovered years
/// later, by a person who no longer has the app that could regenerate it.
abstract interface class ExportSink {
  /// Creates the export folder and returns the name actually used.
  Future<String> begin(String folderName);

  /// Opens one file, creating any folders named in [relativePath].
  Future<void> open(String relativePath, String mime);

  /// Appends to the open file.
  Future<void> write(Uint8List bytes);

  /// Finishes the open file.
  Future<void> closeFile();

  /// Finishes the export.
  Future<void> finish();

  /// Gives up and removes what was written.
  Future<void> abort();
}

/// The real one: straight through the channel into the user's chosen folder.
class DocumentStoreSink implements ExportSink {
  const DocumentStoreSink(this.treeUri);

  final String treeUri;

  @override
  Future<String> begin(String folderName) =>
      DocumentStore.exportBegin(treeUri: treeUri, folderName: folderName);

  @override
  Future<void> open(String relativePath, String mime) =>
      DocumentStore.exportOpen(relativePath: relativePath, mime: mime);

  @override
  Future<void> write(Uint8List bytes) => DocumentStore.exportWrite(bytes);

  @override
  Future<void> closeFile() => DocumentStore.exportCloseFile();

  @override
  Future<void> finish() => DocumentStore.exportFinish();

  @override
  Future<void> abort() => DocumentStore.exportAbort();
}

abstract final class PlainExport {
  /// 64 KiB, matching [AttachmentStore]'s chunk. Not a coincidence and not
  /// worth tuning: the decrypt yields chunks that size, so anything else here
  /// would mean buffering to re-cut them.
  static const int _chunk = 64 * 1024;

  /// Writes everything into a folder created inside [treeUri].
  ///
  /// [onProgress] is called with a fraction and a line to show. [isCancelled]
  /// is checked between files — between rather than during, because a half
  /// written photograph is not something to leave behind and finishing the one
  /// in hand costs at most a few hundred milliseconds.
  ///
  /// Returns the name of the folder that was created.
  static Future<String> run({
    required ExportSink sink,
    required EntryRepository repo,
    required DayNoteRepository dayNotes,
    required AttachmentStore attachments,
    required DateTime now,

    /// The reader's language tag, for the dates written into the Markdown.
    ///
    /// ══ WHY THIS IS A PARAMETER AND NOT `Localizations.localeOf` ══════════
    ///
    /// The export runs off the widget tree — that is the whole point of it,
    /// since it streams straight to a document provider and must not be tied
    /// to a screen that could be disposed halfway through. So it cannot look
    /// the locale up; it has to be handed one, by the screen that started it.
    ///
    /// Defaulted to `en_GB` rather than to `en`: CLDR's plain `en` writes
    /// *August 20*, and every date this app has ever produced is *20 August*.
    /// A default that silently reorders dates would be a strange thing for a
    /// fallback to do.
    String locale = 'en_GB',
    void Function(double fraction, String label)? onProgress,
    bool Function()? isCancelled,
  }) async {
    void report(double f, String label) => onProgress?.call(f, label);
    bool cancelled() => isCancelled?.call() ?? false;

    final folderName = 'Lamplight export ${_dayKey(now)}';
    final createdAs = await sink.begin(folderName);

    try {
      report(0, 'Reading your notes…');

      final entries = await repo.allForExport();
      final foldersByEntry = await repo.folderNamesByEntry();
      // The line that names each day. One query for the whole vault — see
      // `DayNoteRepository.all`. A day the user never named is simply absent
      // from the map, and the day file then has no subtitle rather than an
      // empty one.
      final notesByDay = await dayNotes.all();

      // Every attachment referenced by a surviving entry, in one query. The
      // alternative — a lookup per entry — is thousands of round trips into
      // SQLCipher for a vault of any age.
      final ids = <String>{
        for (final e in entries)
          if (e.attachmentId != null) e.attachmentId!,
      };
      final rows = await repo.attachmentsByIds(ids);
      final byId = {for (final a in rows) a.id: a};

      // Names are decided up front, for all of them, before a single byte is
      // written. Two photographs called `IMG_0001.jpg` are completely normal
      // and the second one must not overwrite the first — and the Markdown
      // cannot link to a name that has not been settled yet.
      final fileNames = _nameMedia(entries, byId);

      // Days, oldest first. `allForExport` already orders by day then time, so
      // this only has to notice the boundaries.
      final days = <String, List<Entry>>{};
      for (final e in entries) {
        (days[e.dayKey] ??= []).add(e);
      }

      final totalSteps = days.length + fileNames.length + 1;
      var step = 0;

      // ── The explainer ──────────────────────────────────────────────────────
      await _writeText(
        sink,
        'README.md',
        _readme(
            now: now,
            days: days.length,
            entries: entries.length,
            locale: locale),
      );
      report(++step / totalSteps, 'Writing…');

      // ── One file per day ───────────────────────────────────────────────────
      for (final dayKey in days.keys) {
        if (cancelled()) throw const ExportCancelled();
        final year = dayKey.substring(0, 4);
        await _writeText(
          sink,
          'Journal/$year/$dayKey.md',
          _dayFile(
            dayKey: dayKey,
            note: notesByDay[dayKey],
            entries: days[dayKey]!,
            attachments: byId,
            fileNames: fileNames,
            foldersByEntry: foldersByEntry,
            locale: locale,
          ),
        );
        report(++step / totalSteps, 'Writing $dayKey…');
      }

      // ── The originals ──────────────────────────────────────────────────────
      for (final entry in fileNames.entries) {
        if (cancelled()) throw const ExportCancelled();
        final attachment = byId[entry.key]!;
        await sink.open('Media/${entry.value}', attachment.mimeType);
        // The only place in the app where decrypted content leaves the vault
        // in a loop. It goes chunk → channel → the user's folder, and is never
        // accumulated: `readAllBytes` on a 500 MB video would be the end of the
        // app on the phones most people have.
        await for (final chunk
            in attachments.read(attachment.id, attachment.fileKey)) {
          await sink.write(_bytes(chunk));
        }
        await sink.closeFile();
        report(++step / totalSteps, 'Copying ${entry.value}…');
      }

      await sink.finish();
      report(1, 'Done.');
      return createdAs;
    } catch (_) {
      // Anything at all — a cancel, a full card, a revoked folder. The
      // half-written export goes with it, because a folder holding some of
      // somebody's life with no way to tell which part is worse than nothing.
      await sink.abort();
      rethrow;
    }
  }

  // ── Writing ────────────────────────────────────────────────────────────────

  static Future<void> _writeText(
      ExportSink sink, String path, String content) async {
    await sink.open(path, 'text/markdown');
    final bytes = utf8.encode(content);
    for (var at = 0; at < bytes.length; at += _chunk) {
      final end = (at + _chunk < bytes.length) ? at + _chunk : bytes.length;
      await sink.write(Uint8List.fromList(bytes.sublist(at, end)));
    }
    await sink.closeFile();
  }

  static Uint8List _bytes(List<int> chunk) =>
      chunk is Uint8List ? chunk : Uint8List.fromList(chunk);

  // ── The documents themselves ───────────────────────────────────────────────

  /// The day file. Plain CommonMark — no front matter, no custom syntax.
  ///
  /// Front matter was considered and dropped. It is useful to exactly one
  /// audience (people who already use Obsidian) and it is noise to everybody
  /// else, who will open this in Notepad. The date is in the heading and in the
  /// filename, which is where a person looks for it.
  static String _dayFile({
    required String dayKey,
    required String? note,
    required List<Entry> entries,
    required Map<String, Attachment> attachments,
    required Map<String, String> fileNames,
    required Map<String, List<String>> foldersByEntry,
    required String locale,
  }) {
    final out = StringBuffer()
      ..writeln('# ${_longDate(dayKey, locale)}')
      ..writeln();

    // The day's own line, under its date. A blockquote rather than a second
    // heading: it is somebody's sentence about the day, not a section of it,
    // and every Markdown reader ever written draws a blockquote as an aside.
    //
    // It is stored as one line and cannot contain a newline, so it cannot
    // break out of the quote — but `>` is written once rather than per line
    // on the strength of that, so if the cap in `DayNoteRepository` ever goes,
    // this is the second place that has to know.
    if (note != null && note.trim().isNotEmpty) {
      out
        ..writeln('> ${note.trim()}')
        ..writeln();
    }

    for (final e in entries) {
      final time = _timeOf(e, locale);
      final marked = e.marker != null && e.marker!.isNotEmpty;
      final heading = StringBuffer('## $time');
      final kind = _kindLabel(e, attachments);
      if (kind != null) heading.write(' — $kind');
      if (marked) heading.write(' ★');
      out
        ..writeln(heading)
        ..writeln();

      final folders = foldersByEntry[e.id];
      if (folders != null && folders.isNotEmpty) {
        out
          ..writeln('*Filed in: ${folders.join(', ')}*')
          ..writeln();
      }

      final body = (e.body ?? '').trim();
      if (body.isNotEmpty) {
        out
          ..writeln(body)
          ..writeln();
      }

      final id = e.attachmentId;
      if (id != null) {
        final name = fileNames[id];
        if (name != null) {
          final link = '../../Media/${Uri.encodeComponent(name)}';
          // An image gets an image link so it renders in place; everything else
          // gets an ordinary link, because a `!` in front of a PDF produces a
          // broken image icon in every reader there is.
          final isImage =
              (attachments[id]?.mimeType ?? '').startsWith('image/');
          out
            ..writeln('${isImage ? '!' : ''}[$name]($link)')
            ..writeln();
        }
      }
    }

    return out.toString();
  }

  static String? _kindLabel(Entry e, Map<String, Attachment> attachments) {
    switch (e.type) {
      case 'text':
        return null;
      case 'voice':
        final ms = attachments[e.attachmentId]?.durationMs;
        return ms == null ? 'Voice note' : 'Voice note (${_duration(ms)})';
      case 'photo':
        return 'Photo';
      case 'video':
        final ms = attachments[e.attachmentId]?.durationMs;
        return ms == null ? 'Video' : 'Video (${_duration(ms)})';
      case 'file':
        return 'File';
      default:
        return null;
    }
  }

  /// What the folder is, for somebody who finds it in five years.
  ///
  /// Written for a person who may never have heard of this app — possibly
  /// somebody's family, going through their files. It says what the format is
  /// and that nothing here needs Lamplight to read it.
  static String _readme({
    required DateTime now,
    required int days,
    required int entries,
    required String locale,
  }) =>
      '''
# Lamplight export

This folder was written by Lamplight on ${_longDate(_dayKey(now), locale)}.
It contains $entries ${entries == 1 ? 'entry' : 'entries'} across $days ${days == 1 ? 'day' : 'days'}.

## What is in here

- **`Journal/`** — one Markdown file for each day, inside a folder for its year.
  Markdown is ordinary text. You can open these in Notepad, TextEdit, Word,
  Obsidian, or anything else that reads a text file.
- **`Media/`** — every photograph, video, voice note and document, under its
  own name, in its original format.

The day files link to the media using relative paths, so you can move this
whole folder anywhere and the links will keep working. Do not rename the
`Journal` or `Media` folders if you want that to stay true.

## Nothing here is encrypted

That is deliberate, and it is the point of this folder. **You asked Lamplight
for a copy you can read without Lamplight, and this is it.** It has no
password on it. Anyone who opens this folder can read everything in it, so
keep it somewhere you are happy for it to be.

If you want a copy that stays private, use **Settings → Backup** instead. That
writes a single `.vault` file which is encrypted, and which needs your passcode
or your twelve-word recovery phrase to open.

## This folder does not need Lamplight

Nothing in here is in a Lamplight format. If this app stops being updated,
disappears, or you simply stop using it, everything here still opens. That is
why the export exists.
''';

  // ── Naming ─────────────────────────────────────────────────────────────────

  /// Decides one filename per attachment, before anything is written.
  ///
  /// Three problems solved in one pass, and all three are real rather than
  /// theoretical: names repeat (`IMG_0001.jpg` from two different phones),
  /// names contain characters a filesystem will not take, and names can be
  /// missing entirely.
  static Map<String, String> _nameMedia(
    List<Entry> entries,
    Map<String, Attachment> byId,
  ) {
    final names = <String, String>{};
    final used = <String>{};

    for (final e in entries) {
      final id = e.attachmentId;
      if (id == null || names.containsKey(id)) continue;
      final a = byId[id];
      if (a == null) continue;

      // ── The typed fallback has to be chosen BEFORE cleaning ───────────
      //
      // `safeFileName` guarantees a non-empty result, which is right for it —
      // every caller needs *a* name, and one that has to handle null will
      // eventually write `null` into a path. But it means the old
      // `if (base.isEmpty)` below could never fire, so a nameless voice note
      // came out as `file` instead of `Voice note 14 August.m4a`.
      //
      // So the question "did this attachment have a name at all" is asked of
      // the raw value, and the cleaner is only asked about names that exist.
      final raw = a.originalName.trim();
      var base = raw.isEmpty ? _fallbackName(e, a) : _safeName(raw);
      // And a name made entirely of things that get stripped — `...`, a lone
      // separator — reaches the fallback too rather than the generic word.
      if (base == 'file') base = _fallbackName(e, a);

      var candidate = base;
      var n = 1;
      while (!used.add(candidate.toLowerCase())) {
        final dot = base.lastIndexOf('.');
        candidate = dot > 0
            ? '${base.substring(0, dot)} ($n)${base.substring(dot)}'
            : '$base ($n)';
        n++;
      }
      names[id] = candidate;
    }
    return names;
  }

  /// Strips what a filesystem will not take, and what a path traversal needs.
  ///
  /// `..` and `/` are the two that matter: an attachment whose stored name is
  /// `../../../secrets` must not be able to write outside the export folder.
  /// The name comes from a file the user imported, so it is not attacker
  /// controlled in any interesting way — but "not interesting today" is how
  /// these get left in.
  static String _safeName(String raw) => safeFileName(raw, fallback: 'file');

  /// A name for an attachment that arrived without one.
  ///
  /// Rarer than it was: anything Lamplight records itself is named at capture
  /// now — see `stampedName`, and the note there about a hundred and
  /// thirty-seven files called `Voice note`. This still runs for an import
  /// whose source gave no name at all, and it produces the same shape, from the
  /// same function, so the two can never drift into two conventions.
  static String _fallbackName(Entry e, Attachment a) {
    return stampedName(
      kind: switch (e.type) {
        'voice' => 'Voice',
        'photo' => 'Photo',
        'video' => 'Video',
        _ => 'File',
      },
      // The offset it was written at, not the one it is being exported at.
      // `createdOffsetMinutes` is stored beside the instant precisely so this
      // can be right.
      at: DateTime.fromMillisecondsSinceEpoch(e.createdAt, isUtc: true)
          .add(Duration(minutes: e.createdOffsetMinutes)),
      extension: _extensionFor(a.mimeType),
    );
  }

  static String _extensionFor(String mime) {
    switch (mime) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'video/mp4':
        return '.mp4';
      case 'audio/mp4':
      case 'audio/m4a':
        return '.m4a';
      case 'audio/aac':
        return '.aac';
      case 'audio/ogg':
        return '.ogg';
      case 'application/pdf':
        return '.pdf';
      default:
        return '';
    }
  }

  // ── Dates and times ────────────────────────────────────────────────────────

  static String _dayKey(DateTime d) => EntryRepository.dayKeyFor(d);

  /// The time the entry was written, in the offset it was written at.
  ///
  /// `createdOffsetMinutes` is stored beside the instant precisely so this can
  /// be right: a note made at nine in the morning in Delhi should read 09:00 in
  /// the export even if it is being exported from a laptop in London.
  static String _timeOf(Entry e, String locale) {
    final local = DateTime.fromMillisecondsSinceEpoch(e.createdAt, isUtc: true)
        .add(Duration(minutes: e.createdOffsetMinutes));
    // Was a 24-hour clock for everybody. `intl` knows which readers use one.
    return LampDates.timeIn(locale, local);
  }

  static String _duration(int ms) {
    final total = (ms / 1000).round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// `Thursday, 20 August 2026`, in the reader's language and their ordering.
  ///
  /// This was two `static const` English lists and a hand-built sentence. It is
  /// `intl` now, for the reason `l10n/dates.dart` gives at length: translating
  /// the month names alone would still have produced *20 8月 2026* in Japanese.
  static String _longDate(String dayKey, String locale) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) return dayKey;
    return LampDates.longDateIn(locale, DateTime(y, m, d));
  }
}

/// Thrown when the user stopped it. Not an error, and must not be shown as one.
class ExportCancelled implements Exception {
  const ExportCancelled();

  @override
  String toString() => 'The export was stopped.';
}
