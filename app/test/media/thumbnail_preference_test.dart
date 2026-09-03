import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/features/media/media_album.dart';

/// Which picture a tile actually draws.
///
/// ── WHY THIS IS WORTH A TEST FILE OF ITS OWN ────────────────────────────────
///
/// `KeyPurpose.thumbnails` existed from the first commit and nothing ever
/// wrote one. The cost was invisible in every way that matters for finding a
/// bug: nothing looked wrong, nothing was logged, no test failed. A day with
/// twenty photographs simply read and decrypted twenty full-size files —
/// tens of megabytes through libsodium — in order to draw twenty small
/// squares, and the only symptom was the app feeling heavy.
///
/// The rule that fixes it is one line, which is exactly the problem. A line
/// that short reads like an accident and invites being "tidied" back to
/// `isVideo ? thumbnailId : id`, which would silently restore the old
/// behaviour for every photograph in the app. Nothing would fail. This does.
void main() {
  Attachment row({
    required String id,
    String? thumbnailId,
    String mimeType = 'image/jpeg',
  }) =>
      Attachment(
        id: id,
        fileKey: Uint8List(32),
        originalName: 'x',
        mimeType: mimeType,
        byteSize: 1,
        thumbnailId: thumbnailId,
      );

  group('a photograph', () {
    test('draws its thumbnail when it has one', () {
      // The whole point: 40 KB decrypted instead of 4 MB, per tile, every
      // time the day scrolls back into view.
      final a = row(id: 'photo', thumbnailId: 'small');
      expect(MediaAlbum.pictureIdFor(a, isVideo: false), 'small');
    });

    test('falls back to the original when it has none', () {
      // Everything imported before thumbnails existed. It must keep drawing —
      // a migration that made old photographs disappear would be far worse
      // than the performance problem being fixed.
      final a = row(id: 'photo');
      expect(MediaAlbum.pictureIdFor(a, isVideo: false), 'photo');
    });
  });

  group('a video', () {
    test('draws its poster frame', () {
      final a = row(id: 'clip', thumbnailId: 'poster', mimeType: 'video/mp4');
      expect(MediaAlbum.pictureIdFor(a, isVideo: true), 'poster');
    });

    test('draws nothing at all when it has no poster', () {
      // Not the original. An MP4 handed to an image decoder is a broken tile,
      // and a clip imported before poster frames existed should get the dark
      // square with a play badge instead.
      final a = row(id: 'clip', mimeType: 'video/mp4');
      expect(MediaAlbum.pictureIdFor(a, isVideo: true), isNull);
    });
  });

  test('the video rule is not applied to photographs', () {
    // The specific regression this file exists to catch. Under the old rule a
    // photograph with a thumbnail and a photograph without behaved the same,
    // and reverting to it would look like a simplification.
    final withThumb = row(id: 'a', thumbnailId: 't');
    final without = row(id: 'b');

    expect(MediaAlbum.pictureIdFor(withThumb, isVideo: false), isNot('a'));
    expect(MediaAlbum.pictureIdFor(without, isVideo: false), isNotNull);
  });
}
