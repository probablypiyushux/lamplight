import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/design/typefaces.dart';

/// **Retiring a typeface must not change anybody's journal.**
///
/// > *"there are alots of fonts option given by us! reduce them! keep the ones
/// > which are better and would loved — actually keep all categories still
/// > reduce some fonts."* — 29 August 2026
///
/// Four faces went on 29 August 2026, because each was a near-duplicate of a
/// neighbour and fourteen of them were 4.3 MB of a 78 MB app: IBM Plex Sans,
/// Poppins, Cormorant Garamond and Baloo 2.
///
/// The risk in that is not the deletion, it is the **stored preference**.
/// `WritingFace.id` is written into `settings.json` and `fromId` used to fall
/// through to `WritingFace.system` for anything it did not recognise — so
/// somebody who had chosen Baloo 2 would have opened the app after an update to
/// find their entire journal set in their phone's default font, with nothing
/// telling them why and no way to get back to what they had. That is a small
/// betrayal of exactly the kind `08-design/ETHICAL-DESIGN.md` exists to stop.
///
/// These tests pin the alternative: every retired id resolves to the nearest
/// surviving face in the *same category*, so the change is invisible rather
/// than destructive.
void main() {
  group('a retired face lands on its nearest neighbour', () {
    test('IBM Plex Sans becomes Manrope, not the system font', () {
      expect(WritingFace.fromId('business'), WritingFace.modern);
    });

    test('Poppins becomes Nunito Sans', () {
      expect(WritingFace.fromId('geometric'), WritingFace.calm);
    });

    test('Cormorant Garamond becomes EB Garamond — both are Garamonds', () {
      expect(WritingFace.fromId('sophisticated'), WritingFace.oldStyle);
    });

    test('Baloo 2 becomes Fredoka — both are round and warm', () {
      expect(WritingFace.fromId('cute'), WritingFace.playful);
    });

    test('and none of them lands on System, which was the old behaviour', () {
      for (final id in ['business', 'geometric', 'sophisticated', 'cute']) {
        expect(WritingFace.fromId(id), isNot(WritingFace.system), reason: id);
      }
    });
  });

  test('a genuinely unknown id still falls back to the phone', () {
    // A typo, a hand-edited settings file, a preference from a future version
    // read by an older build. There is nothing sensible to map it to.
    expect(WritingFace.fromId('rosewood'), WritingFace.system);
    expect(WritingFace.fromId(null), WritingFace.system);
  });

  test('the retirement survives a real settings read', () {
    // The path that actually matters: the value as it sits on somebody's disk.
    final settings = AppSettings.inMemory({'writingFace': 'cute'});
    expect(settings.writingFace, WritingFace.playful);
  });

  group('what was kept', () {
    test('every category still has a face in it', () {
      // The instruction was explicit — reduce the count, keep the range. If a
      // later tidy-up takes one of these out, the app has lost a *kind* of
      // choice rather than a duplicate, and this fails.
      final ids = WritingFace.values.map((f) => f.id).toSet();
      for (final needed in const [
        'system', // the phone's own
        'serif', // the phone's serif
        'modern', // a plain neutral sans
        'calm', // a soft humanist sans
        'old-style', // a book serif
        'playful', // round and warm
        'childlike', // an exercise book
        'handwritten', // actual handwriting
        'medieval', // a scribe's hand
        'mono', // every letter the same width
      ]) {
        expect(ids, contains(needed), reason: 'the $needed category is gone');
      }
    });

    test('ten faces, and every bundled one names a licence', () {
      expect(WritingFace.values, hasLength(10));
      for (final face in WritingFace.values) {
        if (face.family == null || face.id == 'serif') continue;
        expect(
          kFontLicences.values.any((path) =>
              path.contains(face.family!.toLowerCase().replaceAll(' ', ''))),
          isTrue,
          reason: '${face.label} ships without its licence text',
        );
      }
    });
  });
}
