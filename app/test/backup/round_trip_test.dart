import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/plain_export.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/day_note_repository.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/storage/attachment_store.dart';
import 'package:lamplight/core/storage/journal_import.dart';
import 'package:lamplight/l10n/dates.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND FIFTEEN, ISSUE 13 — "do their features work or not?"**
///
/// > *"I want you to check the code of features – Readable copy and bring in
/// > old journal! And test actually do their features work or not?"*
///
/// Both features had thorough tests already, and neither of them tested the
/// thing the two are *for*. `plain_export_test.dart` checks what the export
/// writes. `journal_import_test.dart` checks what the import reads. Nobody had
/// ever put the second one's mouth on the first one's output.
///
/// That matters more than it sounds, because **`CLAUDE.md` has been claiming
/// they round-trip since 27 August** — *"It round-trips with the export"* — and
/// that claim was made by reading two files rather than by running them. This
/// project's own scoreboard on that is unambiguous: every claim checked
/// mechanically has held, and the ones checked by reading have eventually been
/// wrong.
///
/// So this file is the claim, executed: a real vault written out to a real
/// folder on a real disk, then read back into a **different, empty** vault
/// through the real importer, with nothing faked in between except the two
/// platform channels that cannot exist off a phone.
///
/// ── WHAT IT PROVES, STATED EXACTLY ─────────────────────────────────────────
///
/// **Every day that had writing on it comes back, on the same day, with the
/// words in it.** That is the promise worth having and it is the one that is
/// true. It is not entry-by-entry: the export writes one Markdown file per day
/// and the importer files one entry per file, so a day that held three entries
/// comes back as one. That is a real limit, it is written down in
/// `WHAT-TO-CHANGE-AND-WHAT-NOT.md`, and the alternative — an importer that
/// splits any file on `##` — would carve up other people's journals on
/// headings that mean something else to them.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;

  setUpAll(() async {
    // The export formats dates through `intl`. `main` awaits this before the
    // first frame; a test has to too, or it exercises the fallback instead.
    await LampDates.prepare();
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  /// A vault on disk, opened the way the app opens one.
  Future<(VaultDatabase, AttachmentStore)> makeVault(Directory root) async {
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    final db = await openVaultDatabase(path: '${root.path}/vault.db', key: key);
    final store = AttachmentStore(
      directory: Directory('${root.path}/attachments'),
      sodium: sodium,
      crypto: crypto,
    );
    await store.directory.create(recursive: true);
    return (db, store);
  }

  test('a vault written out and read back keeps every day and its words',
      () async {
    final tmp = Directory.systemTemp.createTempSync('lamplight_round_trip');
    addTearDown(() {
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      } catch (_) {
        // Windows keeps a handle on a database SQLite closes asynchronously.
      }
    });

    // ── One: a vault with something in it ─────────────────────────────────
    final (db, store) = await makeVault(Directory('${tmp.path}/first'));
    final repo = EntryRepository(db);
    final dayNotes = DayNoteRepository(db);

    // Three days, one of them with two entries and a line of its own, and one
    // with an attachment — so the export has every shape it can produce.
    final written = <String, List<String>>{
      '2026-08-24': ['Rained all afternoon so we stayed in.'],
      '2026-08-25': [
        'Walked to the bridge before it got light.',
        'She sent the photograph from last summer.',
      ],
      '2026-08-26': ['Nothing much. A quiet one, and that was fine.'],
    };
    var n = 0;
    for (final day in written.keys) {
      for (final body in written[day]!) {
        await repo.createText(id: 'e${n++}', dayKey: day, body: body);
      }
    }
    await dayNotes.setBody('2026-08-25', 'The morning at the bridge');

    final bytes = Uint8List.fromList(utf8.encode('not really a photograph'));
    final stored = await store.writeBytes(bytes);
    await db.into(db.attachments).insert(AttachmentsCompanion.insert(
          id: stored.id,
          fileKey: stored.fileKey,
          originalName: 'bridge.jpg',
          mimeType: 'image/jpeg',
          byteSize: bytes.length,
        ));
    await db.into(db.entries).insert(EntriesCompanion.insert(
          id: 'photo-1',
          createdAt: DateTime.utc(2026, 8, 25, 7, 10).millisecondsSinceEpoch,
          createdOffsetMinutes: 0,
          updatedAt: DateTime.utc(2026, 8, 25, 7, 10).millisecondsSinceEpoch,
          type: 'photo',
          attachmentId: Value(stored.id),
          dayKey: '2026-08-25',
        ));

    // ── Two: the readable copy, onto a real disk ──────────────────────────
    final out = Directory('${tmp.path}/out')..createSync(recursive: true);
    final folder = await PlainExport.run(
      sink: _DiskSink(out),
      repo: repo,
      dayNotes: dayNotes,
      attachments: store,
      now: DateTime(2026, 8, 31),
      locale: 'en',
    );
    await db.close();

    final exported = Directory('${out.path}/$folder');
    expect(exported.existsSync(), isTrue,
        reason: 'the export folder is the deliverable; if this fails there is '
            'nothing to import and the feature does not exist');

    // ── Three: back in, through the real importer, into an empty vault ────
    final (db2, _) = await makeVault(Directory('${tmp.path}/second'));
    final repo2 = EntryRepository(db2);
    addTearDown(db2.close);

    final source = _DiskSource(exported);
    final plan = await JournalImport.plan(source);
    expect(plan.dated.length, greaterThanOrEqualTo(written.length),
        reason: 'every day file the export wrote is dated in its own name, so '
            'the importer must be able to read all of them');

    var ids = 0;
    final result = await JournalImport.run(
      plan: plan,
      source: source,
      repo: repo2,
      newId: () => 'back-${ids++}',
    );
    expect(result.added, greaterThanOrEqualTo(written.length));

    // ── Four: is it all there? ────────────────────────────────────────────
    for (final day in written.keys) {
      final back = (await repo2.allForExport()).where((e) => e.dayKey == day).toList();
      expect(back, isNotEmpty, reason: '$day came back empty');
      final all = back.map((e) => e.body ?? '').join('\n');
      for (final sentence in written[day]!) {
        expect(all, contains(sentence),
            reason: 'this is somebody\'s own writing and it has to survive the '
                'journey out and back');
      }
    }

    // ── And a day that was several entries is several entries again ──────
    //
    // **ISSUE 13.** This is the half that did not work before. The export
    // writes one file per day with a `## HH:MM` heading over each entry; the
    // importer had one rule — one file, one entry — so the structure was
    // written out perfectly and thrown away coming back in.
    final busy = (await repo2.allForExport())
        .where((e) => e.dayKey == '2026-08-25')
        .toList();
    expect(busy.length, greaterThanOrEqualTo(2),
        reason: 'two written entries plus a photograph. If this is 1, the '
            'timed headings are being flattened again');
    expect(
      busy
          .map((e) => e.body ?? '')
          .where((b) => b.contains('Walked to the bridge'))
          .length,
      1,
      reason: 'and the two written entries stayed separate rather than being '
          'merged into one block with the other',
    );
    expect(
      busy.where((e) => (e.body ?? '').contains('She sent the photograph')),
      hasLength(1),
    );

    // The line he gave a day is written as a blockquote and comes back with it.
    final theDay = (await repo2.allForExport()).where((e) => e.dayKey == '2026-08-25');
    expect(theDay.map((e) => e.body ?? '').join('\n'),
        contains('The morning at the bridge'));

    // And the attachment is a file on disk beside the day that names it. The
    // importer only reads text — a picture is not brought back into the vault,
    // and it is right there in the folder either way, which is the point of a
    // readable copy.
    final media = exported
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'));
    expect(media, isNotEmpty,
        reason: 'the photograph is copied out whole even though the importer '
            'will not read it back');
  });

  test('the copy is readable without Lamplight, which is the whole point',
      () async {
    final tmp = Directory.systemTemp.createTempSync('lamplight_readable');
    addTearDown(() {
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    final (db, store) = await makeVault(Directory('${tmp.path}/v'));
    addTearDown(db.close);
    final repo = EntryRepository(db);
    await repo.createText(
        id: 'x', dayKey: '2026-08-24', body: 'A sentence, plainly written.');

    final out = Directory('${tmp.path}/out')..createSync(recursive: true);
    final folder = await PlainExport.run(
      sink: _DiskSink(out),
      repo: repo,
      dayNotes: DayNoteRepository(db),
      attachments: store,
      now: DateTime(2026, 8, 31),
      locale: 'en',
    );

    final files = Directory('${out.path}/$folder')
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
    expect(files.any((f) => f.path.endsWith('README.md')), isTrue);

    final day = files.firstWhere((f) => f.path.endsWith('2026-08-24.md'));
    final text = day.readAsStringSync();
    expect(text, contains('A sentence, plainly written.'));
    // No ciphertext, no base64, no wrapper. A text editor opens it.
    expect(text.startsWith('# '), isTrue,
        reason: 'the first byte of the file is a Markdown heading, which is '
            'what "readable" has to mean');
  });
}

/// The export, onto an ordinary directory.
///
/// Stands in for `DocumentStoreSink`, which needs a phone. It is deliberately
/// the same shape — one file open at a time, bytes pushed through — so what is
/// exercised here is the real streaming path rather than a convenience.
class _DiskSink implements ExportSink {
  _DiskSink(this.root);

  final Directory root;
  late Directory _folder;
  IOSink? _open;

  @override
  Future<String> begin(String folderName) async {
    _folder = Directory('${root.path}/$folderName')..createSync(recursive: true);
    return folderName;
  }

  @override
  Future<void> open(String relativePath, String mime) async {
    final file = File('${_folder.path}/$relativePath');
    file.parent.createSync(recursive: true);
    _open = file.openWrite();
  }

  @override
  Future<void> write(Uint8List bytes) async => _open!.add(bytes);

  @override
  Future<void> closeFile() async {
    await _open?.flush();
    await _open?.close();
    _open = null;
  }

  @override
  Future<void> finish() async => closeFile();

  @override
  Future<void> abort() async {
    await closeFile();
    if (_folder.existsSync()) _folder.deleteSync(recursive: true);
  }
}

/// The import, from an ordinary directory.
class _DiskSource implements ImportSource {
  _DiskSource(this.root);

  final Directory root;
  final _files = <File>[];

  @override
  Future<List<ImportFile>> scan() async {
    _files
      ..clear()
      ..addAll(root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md') || f.path.endsWith('.txt')));
    return [
      for (var i = 0; i < _files.length; i++)
        ImportFile(
          index: i,
          // Relative, as the platform scanner returns it, so the date in the
          // path is read from the same shape of string on both sides.
          path: _files[i].path.substring(root.path.length + 1).replaceAll(r'\', '/'),
          size: _files[i].lengthSync(),
          modified: _files[i].lastModifiedSync().millisecondsSinceEpoch,
        ),
    ];
  }

  @override
  Future<String> readText(int index) async => _files[index].readAsString();

  @override
  Future<void> forget() async => _files.clear();
}
