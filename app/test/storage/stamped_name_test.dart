import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';

/// Names for the things Lamplight records itself.
///
/// > *"Fix this issue — every voice is saved as voice.aac."*
///
/// It was never a correctness bug, which is why it survived two rounds of
/// somebody looking at the export: the Readable copy already refuses to
/// overwrite, so a year of recordings came out as `Voice note.aac`,
/// `Voice note (1).aac`, and on to `Voice note (137).aac`. Nothing was lost and
/// nothing could be found.
///
/// These are the four properties that make the fix worth having, and each one
/// is a way it could quietly be undone.
void main() {
  group('a name that says when', () {
    test('carries the date and the time, to the second', () {
      expect(
        stampedName(
          kind: 'Voice',
          at: DateTime(2026, 8, 27, 14, 32, 5),
          extension: '.aac',
        ),
        'Voice 2026-08-27 14-32-05.aac',
      );
    });

    test('two recordings a minute apart do not collide', () {
      // The counter came back for exactly this pair without seconds — and
      // start, stop, remember one more thing, start again is an ordinary way
      // to use a voice recorder.
      final first = stampedName(
        kind: 'Voice',
        at: DateTime(2026, 8, 27, 14, 32, 5),
        extension: '.aac',
      );
      final second = stampedName(
        kind: 'Voice',
        at: DateTime(2026, 8, 27, 14, 32, 41),
        extension: '.aac',
      );
      expect(first, isNot(second));
    });

    test('sorts chronologically as text', () {
      // The whole point. `(10)` sorts before `(2)`, so the old names were not
      // even in the order they were made — which is the one order a folder of
      // somebody's recordings should be in.
      final names = [
        stampedName(
            kind: 'Voice',
            at: DateTime(2026, 9, 1, 9, 0, 0),
            extension: '.aac'),
        stampedName(
            kind: 'Voice',
            at: DateTime(2026, 8, 27, 23, 59, 59),
            extension: '.aac'),
        stampedName(
            kind: 'Voice',
            at: DateTime(2026, 8, 27, 2, 0, 0),
            extension: '.aac'),
      ]..sort();
      expect(names.first, contains('2026-08-27 02-00-00'));
      expect(names.last, contains('2026-09-01 09-00-00'));
    });

    test('contains nothing a filesystem will refuse', () {
      // Colons are illegal on Windows and on every FAT-formatted card, and the
      // Readable copy is meant to be a folder somebody can carry anywhere.
      final name = stampedName(
        kind: 'Picture',
        at: DateTime(2026, 1, 2, 3, 4, 5),
        extension: '.gif',
      );
      for (final bad in [':', '/', r'\', '*', '?', '"', '<', '>', '|']) {
        expect(name, isNot(contains(bad)), reason: '$bad is not a filename');
      }
    });

    test('pads every field, so the width never changes', () {
      expect(
        stampedName(
          kind: 'Video',
          at: DateTime(2026, 1, 2, 3, 4, 5),
          extension: '.mp4',
        ),
        'Video 2026-01-02 03-04-05.mp4',
      );
    });
  });
}
