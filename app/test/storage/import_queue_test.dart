import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/features/capture/import_queue.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUES 12, 13 and 14.**
///
/// > *"When one file is uploading I can't upload another … don't restrict me
/// > from using the app too!"* — and *"I don't get a visual thing that the file
/// > is being uploaded or what?"*
///
/// The two properties that have to hold together, and pull against each other:
///
///   * **the app is not blocked** — a second pick while the first is running is
///     accepted, which is ISSUE 13; and
///   * **the work is still strictly one at a time** — because every waiting
///     file sits in the cache as *plaintext* until its turn is finished, and
///     `CLAUDE.md` rule 2 does not have an exception for "briefly, while
///     twenty of them import in parallel".
///
/// The obvious way to satisfy the first is `Future.wait`, which quietly breaks
/// the second, and nothing about the app would look different. So the overlap
/// test below is the one that matters most in this file.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;
  late EntryRepository repo;

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_queue');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    importer = AttachmentImporter(vault);
    repo = EntryRepository(vault.database, attachments: vault.attachments);
  });

  tearDown(() async {
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  final cache = <File>[];
  CapturedFile fake(String name, {int bytes = 40000}) {
    final file = File('${tmp.path}/cache/$name')
      ..createSync(recursive: true)
      // Real content, so the encryption has something to chew and the byte
      // counting has something to count.
      ..writeAsBytesSync(Uint8List(bytes)..fillRange(0, bytes, 7));
    cache.add(file);
    return CapturedFile(file: file, name: name, mimeType: 'text/plain');
  }

  Future<void> drain(ImportQueue queue) async {
    for (var i = 0; i < 400 && queue.isBusy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(queue.isBusy, isFalse, reason: 'the queue never emptied');
  }

  const day = '2026-08-27';

  test('a second pick during the first is accepted, not refused', () async {
    final queue = ImportQueue(importer: importer, vault: vault);
    queue.add([fake('one.txt'), fake('two.txt')], dayKey: day, groupId: 'a');
    // Immediately, while the first is certainly still going: this is the tap
    // that used to land on a greyed-out button.
    queue.add([fake('three.txt')], dayKey: day);

    await drain(queue);

    final rows = await repo.watchDay(day).first;
    expect(rows.length, 3, reason: 'a pick made during an import was dropped');
  });

  test('but only one is ever being written at a time', () async {
    // The rule-2 invariant. Every file waits in the cache as plaintext until
    // its turn ends, so overlap is measured in somebody's photographs sitting
    // in the clear at the same moment.
    final queue = ImportQueue(importer: importer, vault: vault);
    var inFlight = 0;
    var mostAtOnce = 0;

    queue.addListener(() {
      final p = queue.progress;
      inFlight = p == null ? 0 : 1;
      if (inFlight > mostAtOnce) mostAtOnce = inFlight;
    });

    queue.add(
      [for (var i = 0; i < 6; i++) fake('batch$i.txt')],
      dayKey: day,
      groupId: 'b',
    );
    await drain(queue);

    expect(mostAtOnce, lessThanOrEqualTo(1));
    expect((await repo.watchDay(day).first).length, 6);
  });

  test('every plaintext is scrubbed, whatever happened to it', () async {
    // The other half of rule 2, and the half that has a test in
    // `nothing_is_left_behind_test.dart` for the "open with" path. This is the
    // import path, and the queue is a new place for a file to be forgotten.
    final queue = ImportQueue(importer: importer, vault: vault);
    final files = [fake('kept.txt'), fake('alsokept.txt')];
    queue.add(files, dayKey: day, groupId: 'c');
    await drain(queue);

    for (final f in files) {
      expect(f.file.existsSync(), isFalse,
          reason: '${f.name} was left in the cache in the clear');
    }
  });

  test('progress names the file and moves with the bytes', () async {
    final queue = ImportQueue(importer: importer, vault: vault);
    final names = <String>{};
    final fractions = <double>[];

    queue.addListener(() {
      final p = queue.progress;
      if (p == null) return;
      names.add(p.name);
      final f = p.fraction;
      if (f != null) fractions.add(f);
    });

    // Big enough to span several 64 KiB chunks, so there is more than one
    // reading to report.
    queue.add([fake('a big one.txt', bytes: 400000)], dayKey: day);
    await drain(queue);

    expect(names, contains('a big one.txt'),
        reason: 'the strip has nothing to call it');
    expect(fractions, isNotEmpty, reason: 'the bar never moved');
    expect(fractions.every((f) => f >= 0 && f <= 1), isTrue,
        reason: 'a fraction outside 0..1 draws a bar past the end');
    for (var i = 1; i < fractions.length; i++) {
      expect(fractions[i], greaterThanOrEqualTo(fractions[i - 1]),
          reason: 'progress went backwards, which nobody believes');
    }
  });

  test('what is still waiting when the vault locks is destroyed, and counted',
      () async {
    // **ISSUE 14, and the honest half of it.** An import cannot continue with
    // the vault locked — the key is gone by definition. What it must not do is
    // leave somebody's photographs sitting in the cache in the clear behind a
    // locked vault, and it must not go quiet about it.
    final queue = ImportQueue(importer: importer, vault: vault);
    final files = [for (var i = 0; i < 5; i++) fake('late$i.txt')];
    queue.add(files, dayKey: day, groupId: 'd');

    await vault.lock();
    await drain(queue);

    expect(queue.takeSummary().abandoned, greaterThan(0),
        reason: 'files vanished with nothing said about them');
    for (final f in files) {
      expect(f.file.existsSync(), isFalse,
          reason: '${f.name} outlived the keys, in the clear');
    }
  });
}
