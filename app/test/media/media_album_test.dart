import 'dart:typed_data';

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/media/media_album.dart';
import 'package:sodium/sodium_sumo.dart';

/// ISSUE 7 — the album grid, and the two things he asked for.
///
/// *"Make it perfect — like how the album grid is presented in WhatsApp or
/// Telegram or Signal or Snapchat, and make multiple uploads support both
/// images and video in the album."*
///
/// The layout rules are the interesting part to test, because they are the
/// difference between a grid and a mosaic and they are silent when wrong: two
/// landscape photographs side by side are not an error, they are just two
/// slivers, and nothing would ever report it.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_album');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
  });

  tearDownAll(() async {
    await vault.lock();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  var seq = 0;

  /// One entry and its attachment row, at a given shape.
  (Entry, Attachment) item({
    required String type,
    required int width,
    required int height,
    String? thumbnailId,
    int? durationMs,
  }) {
    final id = 'e${seq++}';
    final aid = 'a$id';
    return (
      Entry(
        id: id,
        createdAt: DateTime(2026, 8, 21, 13, 30).millisecondsSinceEpoch,
        createdOffsetMinutes: 0,
        updatedAt: DateTime(2026, 8, 21, 13, 30).millisecondsSinceEpoch,
        type: type,
        attachmentId: aid,
        dayKey: '2026-08-21',
        groupId: 'g1',
        isPinned: false,
      ),
      Attachment(
        id: aid,
        fileKey: Uint8List(32),
        originalName: '$id.bin',
        mimeType: type == 'video' ? 'video/mp4' : 'image/jpeg',
        byteSize: 1000,
        width: width,
        height: height,
        thumbnailId: thumbnailId,
        durationMs: durationMs,
      ),
    );
  }

  Future<Size> pumpAlbum(
    WidgetTester tester,
    List<(Entry, Attachment)> items, {
    double width = 360,
  }) async {
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MediaAlbum(
              entries: [for (final i in items) i.$1],
              attachments: {for (final i in items) i.$2.id: i.$2},
              store: vault.attachments,
              onMenu: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    // The *content* box, not the widget's own box. `MediaAlbum` fills the width
    // it is given; the arrangement decides the shape of the picture block
    // inside it, and that is what is being tested.
    return tester.getSize(find.byType(AspectRatio).first);
  }

  // \u2550\u2550 ROUND EIGHT, ISSUE 3 \u2014 THE GREY BOX \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
  //
  // *"Some times it works sometimes it doesn't \u2014 photos clicked via mobile
  // camera? They suffer **having** a thumbnail! It looks like a grey box!"*
  //
  // He named the cause without meaning to. A photograph only gets a thumbnail
  // above `THUMB_WORTH_IT`; below it the file is its own thumbnail and
  // `pictureIdFor` falls back to the original. So small pictures drew and
  // camera photographs did not \u2014 every time, not sometimes, once you know
  // which population is which.
  //
  // `thumbnail_preference_test.dart` covers the *rule* and passed throughout:
  // the rule was right. What was wrong was a caller handing over a map that
  // did not contain the row the rule asks for, and no test could see that
  // because no test drew a tile from an incomplete map. These do.
  group('a tile never draws nothing when there is something to draw', () {
    /// Whether a real picture was put on screen, as opposed to the empty
    /// coloured background a tile falls back to.
    bool drewAPicture(WidgetTester tester) =>
        find.byType(Image).evaluate().isNotEmpty;

    testWidgets('the bug: a photograph whose thumbnail row is missing',
        (tester) async {
      // Exactly the map the single-photograph path used to build: the original
      // and nothing else, on a photograph that has a thumbnail.
      final photo = item(type: 'photo', width: 3000, height: 4000,
          thumbnailId: 'not-in-this-map');

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MediaAlbum(
              entries: [photo.$1],
              attachments: {photo.$2.id: photo.$2},
              store: vault.attachments,
              onMenu: () {},
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(drewAPicture(tester), isTrue,
          reason: 'a big decrypt for a small square is the wrong cost and it '
              'is still a photograph; a blank square is not');
    });

    testWidgets('a photograph with its thumbnail row present draws it',
        (tester) async {
      final photo = item(type: 'photo', width: 3000, height: 4000,
          thumbnailId: 'small');
      final small = item(type: 'photo', width: 400, height: 533).$2;

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MediaAlbum(
              entries: [photo.$1],
              attachments: {
                photo.$2.id: photo.$2,
                'small': small.copyWith(id: 'small'),
              },
              store: vault.attachments,
              onMenu: () {},
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(drewAPicture(tester), isTrue);
    });

    testWidgets('a video with no poster still draws no picture', (tester) async {
      // The half of the fallback that must NOT change. A clip's own bytes are
      // not an image, and handing them to a decoder draws a broken tile rather
      // than a slow one \u2014 so a video keeps the dark square and the play badge,
      // which is what every gallery on the phone shows for this case.
      final clip = item(type: 'video', width: 1920, height: 1080);

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MediaAlbum(
              entries: [clip.$1],
              attachments: {clip.$2.id: clip.$2},
              store: vault.attachments,
              onMenu: () {},
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(drewAPicture(tester), isFalse,
          reason: 'an MP4 in an image decoder is a broken tile');
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });

  group('the mosaic chooses its arrangement from the pictures', () {
    testWidgets('two landscapes stack, so neither becomes a sliver',
        (tester) async {
      // Side by side, each would get 180 points of width at 16:9 — a pair of
      // 100-point-tall letterboxes. Every one of the four reference apps
      // stacks this case, and it is the clearest single tell of a mosaic.
      final size = await pumpAlbum(tester, [
        item(type: 'photo', width: 1920, height: 1080),
        item(type: 'photo', width: 1920, height: 1080),
      ]);
      expect(size.height, greaterThan(size.width * 0.45),
          reason: 'two landscapes should be stacked, not side by side');
    });

    testWidgets('two portraits sit side by side, so neither becomes a tower',
        (tester) async {
      final size = await pumpAlbum(tester, [
        item(type: 'photo', width: 1080, height: 1920),
        item(type: 'photo', width: 1080, height: 1920),
      ]);
      // Two 9:16 tiles side by side make a block wider than it is tall.
      expect(size.width, greaterThan(size.height),
          reason: 'two portraits should be side by side, not stacked');
    });

    testWidgets('a landscape hero goes on top; a portrait hero goes down the '
        'left', (tester) async {
      final wideHero = await pumpAlbum(tester, [
        item(type: 'photo', width: 1920, height: 1080),
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
      ]);
      final tallHero = await pumpAlbum(tester, [
        item(type: 'photo', width: 1080, height: 1920),
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
      ]);
      // The two arrangements have genuinely different proportions. If this ever
      // stops being true, the branch has been flattened back into one layout
      // and the mosaic is a grid again.
      expect(wideHero.height, isNot(closeTo(tallHero.height, 1)));
      expect(wideHero.height, greaterThan(tallHero.height),
          reason: 'the stacked arrangement is the taller of the two');
    });

    testWidgets('four or more is a square, whatever shape they are',
        (tester) async {
      final size = await pumpAlbum(tester, [
        item(type: 'photo', width: 1920, height: 1080),
        item(type: 'photo', width: 1080, height: 1920),
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1920, height: 1080),
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
      ]);
      expect(size.width, closeTo(size.height, 1));
      // And the two that did not fit are counted rather than dropped.
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('one picture keeps its own shape, up to the cap',
        (tester) async {
      final wide = await pumpAlbum(
          tester, [item(type: 'photo', width: 1920, height: 1080)]);
      final tall = await pumpAlbum(
          tester, [item(type: 'photo', width: 1080, height: 1920)]);

      // A landscape photograph is drawn at its own proportions.
      expect(wide.width / wide.height, closeTo(16 / 9, 0.05));

      // A portrait one is **capped and cropped**, not drawn at its true height.
      // That is deliberate and it is what the reference apps do: a 9:16 photo
      // at full width is 640 points tall on this screen, and a day where one
      // picture fills the viewport is a day you cannot read. The crop is
      // `BoxFit.cover`, so it is the middle of the picture rather than a
      // squashed version of it, and tapping opens the whole thing.
      expect(tall.height, 340);
      expect(tall.height, lessThan(wide.width / (1080 / 1920)),
          reason: 'the cap should actually be binding on a portrait photo');
    });
  });

  group('a video is in the album, not beside it', () {
    testWidgets('a video tile carries the play badge and its length',
        (tester) async {
      final poster = item(type: 'photo', width: 1920, height: 1080);
      final video = item(
        type: 'video',
        width: 1920,
        height: 1080,
        thumbnailId: poster.$2.id,
        durationMs: 42000,
      );
      await pumpAlbum(tester, [
        item(type: 'photo', width: 1000, height: 1000),
        video,
      ]);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget,
          reason: 'the video tile should look like a video');
      expect(find.textContaining('42'), findsOneWidget,
          reason: 'and say how long it is, as it does everywhere else');
    });

    testWidgets('a photo tile does not', (tester) async {
      await pumpAlbum(tester, [
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
      ]);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('the +N tile is a count, not a count over a play badge',
        (tester) async {
      // Two overlays on one tile is a mess, and the count is the more useful.
      final poster = item(type: 'photo', width: 1000, height: 1000);
      await pumpAlbum(tester, [
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
        item(type: 'photo', width: 1000, height: 1000),
        item(
          type: 'video',
          width: 1000,
          height: 1000,
          thumbnailId: poster.$2.id,
          durationMs: 5000,
        ),
        item(type: 'photo', width: 1000, height: 1000),
      ]);
      expect(find.text('+1'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });
  });

  group('the day view puts them in one run', () {
    test('a photo and a video captured together are one album', () {
      // The actual ISSUE 7 defect: `_group` required every entry in a run to
      // be a photo, so one multi-select containing a clip came apart into an
      // album plus a stray grey video row. Asserted through the repository's
      // own grouping rule so the day view and this test cannot disagree.
      final entries = [
        item(type: 'photo', width: 1000, height: 1000).$1,
        item(type: 'video', width: 1000, height: 1000).$1,
        item(type: 'photo', width: 1000, height: 1000).$1,
      ];
      final runs = groupIntoAlbums(entries);
      expect(runs, hasLength(1));
      expect(runs.first, hasLength(3));
    });

    test('a document captured in the same batch stays its own block', () {
      // WhatsApp does the same. A grey rectangle where a picture should be is
      // not an album.
      final entries = [
        item(type: 'photo', width: 1000, height: 1000).$1,
        item(type: 'file', width: 0, height: 0).$1,
        item(type: 'photo', width: 1000, height: 1000).$1,
      ];
      final runs = groupIntoAlbums(entries);
      expect(runs.map((r) => r.length), [1, 1, 1]);
    });

    test('anything not captured together is never merged', () {
      final a = item(type: 'photo', width: 1000, height: 1000).$1;
      final b = item(type: 'photo', width: 1000, height: 1000).$1
          .copyWith(groupId: const Value('g2'));
      expect(groupIntoAlbums([a, b]), hasLength(2));
    });
  });
}
