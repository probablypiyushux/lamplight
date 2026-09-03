import 'dart:convert';
import 'package:lamplight/l10n/dates.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/plain_export.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/day_note_repository.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/storage/attachment_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:sodium/sodium_sumo.dart';

/// The readable export — the folder somebody keeps **after** Lamplight.
///
/// ── WHY THIS FILE IS LONGER THAN THE FEATURE DESERVES ───────────────────────
///
/// Every other output of this app can be regenerated. This one cannot: it is
/// what a person has left once they have moved to another app, or once this app
/// has stopped being updated. A mistake here is found years later by somebody
/// who no longer has the thing that could make a correct copy.
///
/// So the tests below are about the properties that would be *unrecoverable*
/// rather than merely annoying — content lost, files silently overwriting each
/// other, links that point at nothing, and a cancelled export leaving a folder
/// that looks complete and is not.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late VaultDatabase db;
  late EntryRepository repo;
  late DayNoteRepository dayNotes;
  late AttachmentStore attachments;

  setUpAll(() async {
    // The export formats dates through `intl`, which needs its symbols
    // loaded. `main` awaits this before the first frame; a test has to too,
    // or it exercises the fallback path instead of the real one.
    await LampDates.prepare();
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_export');
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    db = await openVaultDatabase(path: '${tmp.path}/vault.db', key: key);
    repo = EntryRepository(db);
    dayNotes = DayNoteRepository(db);
    attachments = AttachmentStore(
      directory: Directory('${tmp.path}/attachments'),
      sodium: sodium,
      crypto: crypto,
    );
    await attachments.directory.create(recursive: true);
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  var counter = 0;
  String nextId() => 'id-${counter++}';

  /// An attachment row plus the encrypted blob behind it.
  Future<String> addAttachment({
    required String dayKey,
    required String type,
    required String originalName,
    required String mimeType,
    required List<int> content,
    int? durationMs,
  }) async {
    final stored = await attachments.writeBytes(content);
    await db.into(db.attachments).insert(
          AttachmentsCompanion.insert(
            id: stored.id,
            fileKey: stored.fileKey,
            originalName: originalName,
            mimeType: mimeType,
            byteSize: content.length,
            durationMs: Value(durationMs),
          ),
        );
    final entryId = nextId();
    await db.into(db.entries).insert(
          EntriesCompanion.insert(
            id: entryId,
            createdAt: DateTime.utc(2026, 8, 24, 9, 30).millisecondsSinceEpoch,
            createdOffsetMinutes: 0,
            updatedAt: DateTime.utc(2026, 8, 24, 9, 30).millisecondsSinceEpoch,
            type: type,
            attachmentId: Value(stored.id),
            dayKey: dayKey,
          ),
        );
    return stored.id;
  }

  Future<Map<String, List<int>>> exportInto(_FakeSink sink) async {
    await PlainExport.run(
      sink: sink,
      repo: repo,
      dayNotes: dayNotes,
      attachments: attachments,
      now: DateTime(2026, 8, 24),
    );
    return sink.files;
  }

  String text(Map<String, List<int>> files, String path) {
    expect(files.containsKey(path), isTrue,
        reason: '$path is missing. Wrote: ${files.keys.join(', ')}');
    return utf8.decode(files[path]!);
  }

  group('what gets written', () {
    test('a day becomes one Markdown file, filed under its year', () async {
      await repo.createText(
          id: nextId(), dayKey: '2026-08-24', body: 'Went to the sea.');

      final files = await exportInto(_FakeSink());

      // The path shape is a promise to the user: the README tells them where
      // things are, and a reader following it must not hit a dead end.
      final day = text(files, 'Journal/2026/2026-08-24.md');
      expect(day, contains('Went to the sea.'));
      expect(day, contains('# Monday, 24 August 2026'));
      expect(files.keys, contains('README.md'));
    });

    test('the line that names a day is written under its date', () async {
      // `PLAN.md` §7.0-E. A blockquote rather than a second heading: it is
      // somebody's sentence about the day, not a section of it.
      await repo.createText(
          id: nextId(), dayKey: '2026-08-24', body: 'Went to the sea.');
      await dayNotes.setBody('2026-08-24', 'The day we drove to the coast');

      final day = text(await exportInto(_FakeSink()), 'Journal/2026/2026-08-24.md');

      expect(day, contains('> The day we drove to the coast'));
      // Under the date and above the writing, which is where a title goes.
      expect(day.indexOf('# Monday, 24 August 2026'),
          lessThan(day.indexOf('> The day we drove to the coast')));
      expect(day.indexOf('> The day we drove to the coast'),
          lessThan(day.indexOf('Went to the sea.')));
    });

    test('a day with no line gets no empty quote', () async {
      await repo.createText(
          id: nextId(), dayKey: '2026-08-24', body: 'Went to the sea.');

      final day = text(await exportInto(_FakeSink()), 'Journal/2026/2026-08-24.md');

      expect(day, isNot(contains('>')));
    });

    test('entries keep the order they happened in', () async {
      // A journal read back out of order is not a journal. The export is the
      // only artifact where this cannot be fixed afterwards by re-sorting,
      // because the file *is* the order.
      await repo.createText(id: nextId(), dayKey: '2026-08-24', body: 'first');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.createText(id: nextId(), dayKey: '2026-08-24', body: 'second');

      final files = await exportInto(_FakeSink());
      final day = text(files, 'Journal/2026/2026-08-24.md');

      expect(day.indexOf('first'), lessThan(day.indexOf('second')));
    });

    test('deleted entries stay deleted', () async {
      // Trash is a promise. An export that resurrects something the user threw
      // away is the single most upsetting way this feature could fail: it
      // hands them back, in the clear, the one thing they chose to remove.
      final id = nextId();
      await repo.createText(
          id: id, dayKey: '2026-08-24', body: 'regretted this');
      await repo.createText(
          id: nextId(), dayKey: '2026-08-24', body: 'kept this');
      await repo.softDelete(id);

      final files = await exportInto(_FakeSink());
      final day = text(files, 'Journal/2026/2026-08-24.md');

      expect(day, contains('kept this'));
      expect(day, isNot(contains('regretted this')));
    });

    test('an attachment is copied out whole, byte for byte', () async {
      // Not "a file appears" — the *content* matches. A copy that produces a
      // truncated JPEG would pass any test that only counted files, and would
      // be discovered by the user opening a photograph and seeing grey.
      final content = List<int>.generate(200 * 1024, (i) => i % 256);
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'photo',
        originalName: 'IMG_2031.jpg',
        mimeType: 'image/jpeg',
        content: content,
      );

      final files = await exportInto(_FakeSink());

      expect(files['Media/IMG_2031.jpg'], equals(content));
    });

    test('the day file links to the media, and the link resolves', () async {
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'photo',
        originalName: 'IMG_2031.jpg',
        mimeType: 'image/jpeg',
        content: [1, 2, 3],
      );

      final files = await exportInto(_FakeSink());
      final day = text(files, 'Journal/2026/2026-08-24.md');

      // `Journal/2026/x.md` → `../../Media/`. Off by one level and every
      // picture in the export is broken, in a way that looks fine in the
      // Markdown source and only shows when somebody opens it.
      expect(day, contains('![IMG_2031.jpg](../../Media/IMG_2031.jpg)'));
      expect(files.containsKey('Media/IMG_2031.jpg'), isTrue);
    });

    test('a document is a link, not an image', () async {
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'file',
        originalName: 'lease.pdf',
        mimeType: 'application/pdf',
        content: [1, 2, 3],
      );

      final day = text(
        await exportInto(_FakeSink()),
        'Journal/2026/2026-08-24.md',
      );
      expect(day, contains('[lease.pdf](../../Media/lease.pdf)'));
      expect(day, isNot(contains('![lease.pdf]')));
    });
  });

  group('names', () {
    test('two files with the same name both survive', () async {
      // Two phones both produce `IMG_0001.jpg`. This is not an edge case, it
      // is Tuesday — and the failure mode is silent: one photograph
      // overwrites the other and the export still reports success.
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'photo',
        originalName: 'IMG_0001.jpg',
        mimeType: 'image/jpeg',
        content: [1, 1, 1],
      );
      await addAttachment(
        dayKey: '2026-08-25',
        type: 'photo',
        originalName: 'IMG_0001.jpg',
        mimeType: 'image/jpeg',
        content: [2, 2, 2],
      );

      final files = await exportInto(_FakeSink());
      final media = files.keys.where((k) => k.startsWith('Media/')).toList();

      expect(media.length, 2);
      expect(files['Media/IMG_0001.jpg'], [1, 1, 1]);
      expect(files['Media/IMG_0001 (1).jpg'], [2, 2, 2]);
    });

    test('a name that would escape the folder cannot', () async {
      // Not attacker-controlled in any interesting way today. "Not interesting
      // today" is exactly how a path traversal gets left in a codebase.
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'file',
        originalName: '../../../etc/passwd',
        mimeType: 'application/octet-stream',
        content: [9],
      );

      final files = await exportInto(_FakeSink());
      final media = files.keys.where((k) => k.startsWith('Media/')).single;

      expect(media, isNot(contains('..')));
      expect(media.split('/').length, 2);
    });

    test('a nameless attachment still gets a sensible filename', () async {
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'voice',
        originalName: '',
        mimeType: 'audio/mp4',
        content: [7],
        durationMs: 84000,
      );

      final files = await exportInto(_FakeSink());
      final media = files.keys.where((k) => k.startsWith('Media/')).single;

      expect(media, contains('Voice'));
      expect(media, endsWith('.m4a'));
    });
  });

  group('what the reader is told', () {
    test('the README says the copy is not protected', () async {
      // The most important sentence in the whole feature. Somebody who
      // believes this folder is encrypted has been actively misled by us, and
      // they will put it in a shared Downloads folder.
      await repo.createText(id: nextId(), dayKey: '2026-08-24', body: 'x');
      final readme = text(await exportInto(_FakeSink()), 'README.md');

      final lower = readme.toLowerCase();
      expect(lower, contains('nothing here is encrypted'));
      expect(lower, contains('anyone who opens this folder can read'));
      // And it must point at the thing they probably wanted instead.
      expect(readme, contains('.vault'));
    });

    test('a voice note says how long it is', () async {
      await addAttachment(
        dayKey: '2026-08-24',
        type: 'voice',
        originalName: 'note.m4a',
        mimeType: 'audio/mp4',
        content: [1],
        durationMs: 84000,
      );

      final day = text(
        await exportInto(_FakeSink()),
        'Journal/2026/2026-08-24.md',
      );
      expect(day, contains('Voice note (1:24)'));
    });

    test('the time shown is the time it was written, not the reader\'s', () async {
      // `createdOffsetMinutes` exists for this. A note made at 09:00 in Delhi
      // reads 09:00 in the export even if the export runs in London.
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              id: nextId(),
              createdAt: DateTime.utc(2026, 8, 24, 3, 30).millisecondsSinceEpoch,
              createdOffsetMinutes: 330, // +05:30
              updatedAt: DateTime.utc(2026, 8, 24, 3, 30).millisecondsSinceEpoch,
              type: 'text',
              body: const Value('morning'),
              dayKey: '2026-08-24',
            ),
          );

      final day = text(
        await exportInto(_FakeSink()),
        'Journal/2026/2026-08-24.md',
      );
      expect(day, contains('## 09:00'));
    });
  });

  group('when it goes wrong', () {
    test('a cancel leaves nothing behind', () async {
      // A folder holding *some* of somebody's life, with no way to tell which
      // part is missing, is worse than no folder at all — they will trust it.
      for (var i = 0; i < 5; i++) {
        await repo.createText(
            id: nextId(), dayKey: '2026-08-2$i', body: 'day $i');
      }

      final sink = _FakeSink();
      var seen = 0;

      await expectLater(
        PlainExport.run(
          sink: sink,
          repo: repo,
          dayNotes: dayNotes,
          attachments: attachments,
          now: DateTime(2026, 8, 24),
          isCancelled: () => ++seen > 2,
        ),
        throwsA(isA<ExportCancelled>()),
      );

      expect(sink.aborted, isTrue);
      expect(sink.finished, isFalse);
    });

    test('a failure part-way through also aborts', () async {
      await repo.createText(id: nextId(), dayKey: '2026-08-24', body: 'x');
      final sink = _FakeSink(failOnOpen: 'Journal/2026/2026-08-24.md');

      await expectLater(
        PlainExport.run(
          sink: sink,
          repo: repo,
          dayNotes: dayNotes,
          attachments: attachments,
          now: DateTime(2026, 8, 24),
        ),
        throwsA(isA<Exception>()),
      );

      expect(sink.aborted, isTrue);
    });

    test('an empty vault still produces a readable folder', () async {
      // Nobody exports an empty vault on purpose. They do it by accident, on
      // a phone they have just restored, and a crash at that moment reads as
      // "the app has lost everything".
      final files = await exportInto(_FakeSink());
      expect(files.keys, contains('README.md'));
    });
  });
}

/// An [ExportSink] that keeps the files in memory.
///
/// It enforces the same ordering the real one does — you cannot write without
/// opening, and opening twice without closing is an error — so a bug in the
/// call sequence fails here rather than producing a corrupt file on a phone.
class _FakeSink implements ExportSink {
  _FakeSink({this.failOnOpen});

  /// A path that should blow up when opened, to exercise the failure path.
  final String? failOnOpen;

  final Map<String, List<int>> files = {};
  String? _open;
  bool finished = false;
  bool aborted = false;

  @override
  Future<String> begin(String folderName) async => folderName;

  @override
  Future<void> open(String relativePath, String mime) async {
    if (_open != null) {
      throw StateError('$_open was never closed before $relativePath.');
    }
    if (relativePath == failOnOpen) {
      throw Exception('The folder could not be written to.');
    }
    _open = relativePath;
    files[relativePath] = <int>[];
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final at = _open;
    if (at == null) throw StateError('Wrote with no file open.');
    files[at]!.addAll(bytes);
  }

  @override
  Future<void> closeFile() async => _open = null;

  @override
  Future<void> finish() async {
    _open = null;
    finished = true;
  }

  @override
  Future<void> abort() async {
    _open = null;
    aborted = true;
  }
}
