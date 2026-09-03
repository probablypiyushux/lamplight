import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/photo_quality.dart';
import 'package:lamplight/core/settings/video_quality.dart';

/// The two sizes, and the one question that sets them. **ISSUE 6.**
///
/// > *"Photos and videos sizes — ask when uploading! The setting just has video
/// > size."*
///
/// What is worth holding still here is not the numbers — those belong to
/// `Transcode.kt` and only a phone can judge them. It is the three properties
/// that would silently break the feature if anybody changed them without
/// meaning to.
void main() {
  group('the two enums answer to the same three ids', () {
    test('because the sheet asks one question and sets both', () {
      // A person picking fourteen things off their camera roll is not thinking
      // about which of them are videos, so the sheet asks once and reads the
      // answer into both. That only works while the ids line up.
      final photo = PhotoQuality.values.map((q) => q.id).toSet();
      final video = VideoQuality.values.map((q) => q.id).toSet();
      expect(photo, video);
      expect(photo, {'original', 'balanced', 'smaller'});
    });

    test('and a shared id round-trips through both', () {
      for (final id in ['original', 'balanced', 'smaller']) {
        expect(PhotoQuality.fromId(id).id, id);
        expect(VideoQuality.fromId(id).id, id);
      }
    });
  });

  group('the default does not move', () {
    test('an unknown id is balanced, on both', () {
      // Everybody upgrading, and everybody who never opens the setting, keeps
      // doing exactly what they were doing. A vault written before this
      // existed has no `photoQuality` key at all, which arrives here as null.
      expect(PhotoQuality.fromId(null), PhotoQuality.balanced);
      expect(PhotoQuality.fromId('enormous'), PhotoQuality.balanced);
      expect(VideoQuality.fromId(null), VideoQuality.balanced);
    });

    test('balanced is what the app has always done', () {
      // Stated as a test rather than as a comment, because "the default is
      // unchanged" is the sentence that stops a future round quietly altering
      // what happens to the next photograph somebody imports.
      expect(PhotoQuality.balanced.keepsOriginal, isFalse);
      expect(PhotoQuality.original.keepsOriginal, isTrue);
      expect(PhotoQuality.smaller.keepsOriginal, isFalse);
    });
  });

  group('every option says what it costs', () {
    test('and not only what it gives', () {
      // A settings row that lists the upside of each choice and none of the
      // downsides is not offering a choice. Each note has to carry the price:
      // the original is the largest and keeps the location the photograph was
      // taken; smaller is visible if you crop in.
      expect(PhotoQuality.original.note, contains('largest'));
      expect(PhotoQuality.original.note, contains('place the photo was taken'));
      expect(PhotoQuality.smaller.note, contains('notice'));
      expect(PhotoQuality.balanced.note, contains('default'));
      expect(VideoQuality.original.note, contains('largest'));
      expect(VideoQuality.smaller.note, contains('notice'));
    });

    test('none of them names the machinery', () {
      // The same rule `plain_language_test.dart` enforces over `lib/`. He is
      // choosing how big a photograph is, not a JPEG quality factor.
      final all = <(String, String, String)>[
        for (final q in PhotoQuality.values) (q.id, q.label, q.note),
        for (final q in VideoQuality.values) (q.id, q.label, q.note),
      ];
      for (final (id, label, note) in all) {
        final words = '$label $note'.toLowerCase();
        for (final banned in [
          'jpeg',
          'bitrate',
          'codec',
          're-encode',
          'pixel',
          'compression ratio',
        ]) {
          expect(words, isNot(contains(banned)), reason: '"$banned" in $id');
        }
      }
    });
  });
}
