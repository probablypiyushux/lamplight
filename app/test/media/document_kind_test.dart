import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/features/media/document_viewer.dart';

/// ISSUE 4 — what the viewer decides to do with a file, and why it must be a
/// pure function with a test rather than a chain of `if`s inside a build method.
///
/// Every wrong answer here is a *silent* wrong answer: a PDF classed as
/// unsupported shows the "save a copy" panel and looks like the old bug coming
/// back, and a `.docx` classed as text shows a screenful of ZIP noise. Neither
/// throws, so neither would ever be noticed by anything except a person.
void main() {
  group('what Lamplight can show without writing anything to disk', () {
    test('a PDF, however the picker described it', () {
      expect(kindOf('application/pdf', 'ticket.pdf'), DocumentKind.pdf);
      // The case that made this a function rather than a MIME lookup: some
      // pickers hand back octet-stream for a file they could not identify.
      expect(kindOf('application/octet-stream', 'ticket.pdf'), DocumentKind.pdf);
      expect(kindOf('application/pdf', 'no-extension'), DocumentKind.pdf);
    });

    test('text and the things that are text underneath', () {
      expect(kindOf('text/plain', 'notes.txt'), DocumentKind.text);
      expect(kindOf('text/markdown', 'README.md'), DocumentKind.text);
      expect(kindOf('application/octet-stream', 'notes.md'), DocumentKind.text);
      expect(kindOf('application/json', 'export.json'), DocumentKind.text);
      expect(kindOf('application/octet-stream', 'rows.csv'), DocumentKind.text);
    });

    test('a picture that came in through the file picker', () {
      expect(kindOf('image/png', 'scan.png'), DocumentKind.image);
      expect(kindOf('application/octet-stream', 'scan.HEIC'), DocumentKind.image);
    });
  });

  group('what it says so out loud about', () {
    test('the office formats, which would each cost a large dependency', () {
      for (final name in [
        'letter.docx',
        'accounts.xlsx',
        'deck.pptx',
        'letter.doc',
      ]) {
        expect(kindOf('application/octet-stream', name),
            DocumentKind.unsupported,
            reason: '$name must reach the panel that explains itself, not a '
                'screen of nonsense');
      }
    });

    // ══ ROUND FIVE, ISSUE 12 — the twenty-eight he wrote out ═════════════
    //
    // He listed the formats he wanted and asked for "a list which can be
    // opened and which can't". `04-technical/DOCUMENT-FORMATS.md` is that
    // list in prose; this is the same list as assertions, so the two cannot
    // drift apart without something going red.
    test('every format he listed as openable, opens', () {
      const text = [
        'notes.csv', 'letter.rtf', 'contacts.vcf', 'page.html', 'page.htm',
        'data.json', 'diary.txt', 'readme.md', 'invite.ics',
      ];
      for (final name in text) {
        expect(kindOf('application/octet-stream', name), DocumentKind.text,
            reason: '$name is text with a different extension on it');
      }

      const pictures = [
        'a.jpg', 'a.jpeg', 'b.png', 'c.webp', 'd.gif', 'e.heic', 'f.heif',
        'g.avif',
      ];
      for (final name in pictures) {
        expect(kindOf('application/octet-stream', name), DocumentKind.image,
            reason: '$name is a bitmap something on this phone can decode');
      }

      expect(kindOf('application/pdf', 'report.pdf'), DocumentKind.pdf);
    });

    test('the ones that need a package are refused, including SVG', () {
      // SVG is the interesting one: it is a *picture* and it is still on the
      // refusal list, because it is not a bitmap and nothing on the phone will
      // decode it without a renderer. Somebody widening the picture branch by
      // extension would otherwise sweep it in and show an empty box.
      for (final name in [
        'drawing.svg', 'photos.zip', 'photos.rar', 'photos.7z',
        'book.epub', 'app.apk',
      ]) {
        expect(kindOf('application/octet-stream', name),
            DocumentKind.unsupported,
            reason: '$name needs a third-party parser — CLAUDE.md rule 4');
      }
    });

    test('opensInLamplight agrees with kindOf, which is the whole point', () {
      // The function the rest of the app is meant to ask. If these ever
      // disagree there are two answers to one question, which is how the
      // eight-screens-two-margins problem in ISSUE 6 started.
      for (final name in ['a.pdf', 'b.png', 'c.csv', 'd.vcf']) {
        expect(opensInLamplight('application/octet-stream', name), isTrue);
      }
      for (final name in ['a.docx', 'b.zip', 'c.svg', 'd.apk']) {
        expect(opensInLamplight('application/octet-stream', name), isFalse);
      }
    });

    test('an archive is not text, however hopeful that would be', () {
      // A .docx *is* a zip, and treating it as text would show a screenful of
      // binary rather than a sentence. This is the assertion that stops
      // somebody "helpfully" widening the text branch later.
      expect(kindOf('application/zip', 'photos.zip'), DocumentKind.unsupported);
      expect(kindOf(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'letter.docx'), DocumentKind.unsupported);
    });
  });
}
