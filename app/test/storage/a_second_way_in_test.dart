import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/storage/journal_import.dart';

/// **"Can't use this folder — to protect your privacy, choose another folder."**
///
/// 3 September 2026, and it is the fourth round this sentence has appeared in.
/// He hit it on the journal importer and asked for it to be *fixed* rather than
/// explained again.
///
/// It cannot be fixed where it happens. That sentence belongs to DocumentsUI
/// and is shown inside Android's own picker, before anything returns to this
/// app. Android 11 and later will not hand any app the root of internal
/// storage, an SD-card root, or **Downloads** — which is exactly where a
/// journal exported by another app lands. Round fifteen fixed the grant flags.
/// Round sixteen added `EXTRA_INITIAL_URI`. Round seventeen wrote down why
/// neither could have worked: **a hint cannot fix a restriction.**
///
/// So the importer stops asking for the folder, the way automatic backup
/// stopped asking the day before. `ACTION_OPEN_DOCUMENT` asks for the *files*,
/// and Android does not refuse that — the person picks exactly which ones, and
/// the grant is per file rather than a standing key to a directory, which is
/// the smaller ask as well as the one that works.
///
/// **The property this file exists to hold is that there are two doors and one
/// room.** Everything after the picking is shared: the same platform-side list,
/// the same `readText`, the same plan, the same run. If the two ever diverge
/// one of them will quietly rot, and it will be this one — because it is the
/// door only used when the other is barred.
void main() {
  ImportFile file(int i, String path, {int size = 100, int modified = 0}) =>
      ImportFile(index: i, path: path, size: size, modified: modified);

  group('the picked-files door', () {
    test('hands back exactly the files it was given, in order', () async {
      final source = PickedFilesImportSource([
        file(0, '2026-08-12.txt'),
        file(1, '2026-08-14.txt'),
        file(2, '2026-08-19.md'),
      ]);

      final scanned = await source.scan();

      // The picking *is* the scanning — `pickTextFiles` returns the rows,
      // because the platform has already looked at what was chosen. There is
      // no second walk, and adding one would ask the provider for a directory
      // listing it may have no way to give.
      expect(scanned.map((f) => f.path), [
        '2026-08-12.txt',
        '2026-08-14.txt',
        '2026-08-19.md',
      ]);
      expect(scanned.map((f) => f.index), [0, 1, 2]);
    });

    test('an empty pick is an empty scan, not a crash', () async {
      expect(await const PickedFilesImportSource([]).scan(), isEmpty);
    });
  });

  group('both doors admit the same things', () {
    // `Import.adopt` in Kotlin applies `isText`, the same name test the folder
    // walk uses, rather than trusting the picker's MIME filter — a provider may
    // call a `.md` an `application/octet-stream`, and some file managers offer
    // everything regardless of what was asked for.
    //
    // Read out of the Kotlin rather than restated here, so that adding an
    // extension to one door cannot silently leave the other behind.
    test("the file picker applies the folder walk's own name test", () {
      final kotlin = File(
        'android/app/src/main/kotlin/com/probablypiyush/lamplight/Import.kt',
      ).readAsStringSync();

      expect(kotlin, contains('fun adopt('),
          reason: 'The picked-files door is gone. If it was removed on '
              'purpose, remove this test and put back a note in '
              'import_screen.dart explaining why Downloads cannot be used.');

      final start = kotlin.indexOf('fun adopt(');
      final after = kotlin.indexOf('\n    fun ', start + 1);
      final body = kotlin.substring(start, after == -1 ? kotlin.length : after);

      expect(
        body,
        contains('isText(name)'),
        reason: 'adopt() must filter by the same name test scan() uses, or the '
            'two ways in accept different files — and the one nobody uses by '
            'default is the one that rots.',
      );
      expect(
        body,
        contains('MAX_FILES'),
        reason: 'The same ceiling as the folder walk. A picker offering '
            '"select all" over an enormous folder is a real thing.',
      );
    });

    test('the picker asked for is one Android does not refuse', () {
      final kotlin = File(
        'android/app/src/main/kotlin/com/probablypiyush/lamplight/MainActivity.kt',
      ).readAsStringSync();

      final start = kotlin.indexOf('"pickTextFiles" ->');
      expect(start, greaterThan(0), reason: 'pickTextFiles is gone.');
      final body = kotlin.substring(start, start + 1400);

      // ACTION_OPEN_DOCUMENT, never ACTION_OPEN_DOCUMENT_TREE. The whole point
      // is that this asks for files; asking for a tree here would reintroduce
      // the refusal it exists to route around, and would look correct.
      expect(body, contains('Intent.ACTION_OPEN_DOCUMENT)'));
      expect(body, isNot(contains('ACTION_OPEN_DOCUMENT_TREE')));
      expect(body, contains('EXTRA_ALLOW_MULTIPLE'));
    });
  });
}
