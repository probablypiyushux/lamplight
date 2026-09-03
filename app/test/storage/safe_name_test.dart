import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/storage/safe_name.dart';

/// The inlet, as a test.
///
/// > *"Every inlet should be top focus now! ... the way i upload photos,
/// > videos, documents those can be corrupted!"* — 28 August 2026
///
/// A filename is the part of an imported file Lamplight actually uses: stored,
/// shown under an entry, written into the readable export, and turned into a
/// real path when a file is handed to another app. The bytes are never
/// interpreted; the name is interpreted everywhere.
///
/// Each case below is a way a name can do something other than name a file.
void main() {
  group('climbing out of the folder', () {
    test('a relative path cannot escape', () {
      // The readable export writes attachments into a folder the user picked.
      // A name of `../../../secrets` would put one wherever it liked.
      expect(safeFileName('../../../etc/passwd'), isNot(contains('..')));
      expect(safeFileName('../../../etc/passwd'), isNot(contains('/')));
    });

    test('backslashes count too, because the export folder is often synced', () {
      expect(safeFileName(r'..\..\Windows\System32\drivers'),
          isNot(contains(r'\')));
    });

    test('a name that is only traversal still yields a usable name', () {
      // Every caller needs *a* name. Returning empty here means a caller
      // eventually builds a path ending in a separator.
      expect(safeFileName('../..'), isNotEmpty);
      expect(safeFileName('...'), isNotEmpty);
      expect(safeFileName(''), isNotEmpty);
      expect(safeFileName('   '), isNotEmpty);
    });
  });

  group('names that are read differently by different code', () {
    test('a NUL does not split the name in two', () {
      // Dart keeps everything after a NUL. Every C API underneath — which is
      // all of them, eventually — stops there. So this is one name to the
      // database and a different one to the filesystem.
      final safe = safeFileName('holiday.png\u0000.exe');
      expect(safe, isNot(contains('\u0000')));
    });

    test('control characters cannot forge a second line on screen', () {
      // `originalName` is drawn under an entry. A newline in it is a second
      // line of text the app did not write.
      final safe = safeFileName('receipt.pdf\nDeleted by Lamplight');
      expect(safe, isNot(contains('\n')));
      expect(safe, isNot(contains('\r')));
    });
  });

  group('the attack that is aimed at the person, not the parser', () {
    test('a right-to-left override cannot disguise an extension', () {
      // ══ THE ONE WORTH READING TWICE ═════════════════════════════════════
      //
      // U+202E makes everything after it render backwards, so this name is
      // *drawn* as something ending in `.png` while actually ending in `.exe`.
      // Somebody reads the row, believes it is a photograph, and taps
      // "Open with". Nothing about the bytes is wrong; the deception is
      // entirely in how the name is painted.
      const hostile = 'holiday\u202egnp.exe';
      final safe = safeFileName(hostile);

      expect(safe, isNot(contains('\u202e')),
          reason: 'the override survived, so the name still lies about itself');
      expect(safe, endsWith('.exe'),
          reason: 'once the override is gone the name must read as what it is');
    });

    test('the isolates and the marks go too', () {
      for (final c in ['\u202a', '\u202b', '\u202c', '\u202d', '\u2066',
                       '\u2067', '\u2068', '\u2069', '\u200e', '\u200f']) {
        expect(safeFileName('a${c}b.txt'), 'ab.txt',
            reason: 'U+${c.codeUnitAt(0).toRadixString(16)} was left in');
      }
    });
  });

  group('names that collide or disappear on a real filesystem', () {
    test('a leading dot does not hide the file', () {
      // An exported attachment called `.receipt.pdf` is simply not there as
      // far as the person looking in the folder is concerned.
      expect(safeFileName('.receipt.pdf'), 'receipt.pdf');
    });

    test('trailing dots and spaces are removed, because Windows removes them',
        () {
      // Windows strips these silently when creating the file, so `report.` and
      // `report` become one file — the second attachment overwrites the first
      // and nothing is said about it.
      expect(safeFileName('report.  '), 'report');
      expect(safeFileName('report...'), 'report');
    });

    test('Windows device names are defused, including with an extension', () {
      // `CON.txt` is not a file on Windows; the OS intercepts the name. The
      // readable export very often lands in a synced folder.
      expect(safeFileName('CON'), isNot('CON'));
      expect(safeFileName('con.txt'), isNot('con.txt'));
      expect(safeFileName('LPT1.pdf'), isNot('LPT1.pdf'));
      // And a name that merely starts with those letters is left alone.
      expect(safeFileName('control-panel.png'), 'control-panel.png');
      expect(safeFileName('conference.pdf'), 'conference.pdf');
    });

    test('a very long name is cut but keeps its extension', () {
      final long = '${'a' * 400}.pdf';
      final safe = safeFileName(long);
      expect(safe.length, lessThanOrEqualTo(kMaxNameLength));
      expect(safe, endsWith('.pdf'),
          reason: 'the extension is what tells the next app how to open it');
    });

    test('a long name with no extension is simply cut', () {
      expect(safeFileName('b' * 400).length, kMaxNameLength);
    });
  });

  group('ordinary names are left completely alone', () {
    // A sanitiser that mangles real filenames gets switched off. These are the
    // cases that must survive untouched.
    const ordinary = [
      'IMG_20260823_174212.jpg',
      'Scan 2026-08-14 at 09.32.11.pdf',
      'notes (final) v2.md',
      'Bill — August.pdf',
      ' maa ke saath.jpg',
      '写真.png',
      'صورة.jpg',
      'फोटो.jpeg',
      'résumé.docx',
    ];

    for (final name in ordinary) {
      test('"$name"', () {
        // The leading space in one of these is trimmed, which is correct and
        // is the only change any of them should see.
        expect(safeFileName(name), name.trim());
      });
    }

    test('and non-Latin names are not treated as suspicious', () {
      // The bidi *marks* are stripped; Arabic and Devanagari letters are not,
      // and a name in those scripts is as ordinary as any other.
      expect(isSafeFileName('صورة.jpg'), isTrue);
      expect(isSafeFileName('फोटो.jpeg'), isTrue);
      expect(isSafeFileName('写真.png'), isTrue);
    });
  });

  group('the result is always already clean', () {
    test('cleaning twice changes nothing the second time', () {
      // Idempotence is what lets the exits keep calling this as defence in
      // depth without a name drifting each time it passes through.
      const hostile = [
        '../../x', 'a\u0000b', '.hidden', 'CON.txt', 'x\u202ey.exe',
        'trailing.  ', '..', '', '   ', r'a\b/c:d*e?f"g<h>i|j',
      ];
      for (final raw in hostile) {
        final once = safeFileName(raw);
        expect(safeFileName(once), once, reason: 'not idempotent for "$raw"');
        expect(isSafeFileName(once), isTrue,
            reason: '"$once" is still not considered clean');
      }
    });
  });
}
