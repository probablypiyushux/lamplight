import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/media/photo_viewer.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 14 and ISSUE 15 — the viewer's bar, and what is in the album.**
///
/// ISSUE 14: *"INTERCHANGING OF BUTTONS! IN VIEWERS"*, with the bar drawn as it
/// was, drawn again as he wanted it, and *"Interchange their position.
/// Understood?"* underneath. The counter goes first; the menu goes hard against
/// the trailing margin, which is where every gallery on the phone puts it.
///
/// ISSUE 15: *"\[V | P | P | P | P | P\] … when I slide it open V and I can't
/// slide to P. When I open P it shows me 1 of 5, and unable to slide to V."*
///
/// That second sentence is the one that pins the bug down. **An album of six
/// reported "1 of 5"** — the video had not merely been made unreachable, it had
/// been filtered out of the count, so the app was telling him his album was
/// smaller than it was. The first test below is that sentence, inverted.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_album_viewer');
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
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Attachment rows backed by real encrypted blobs, made once.
  ///
  /// **Made in `setUpAll`, and that is not tidiness.** Writing a blob is real
  /// file I/O, and a `testWidgets` body runs in a fake-async zone where real
  /// I/O futures never complete — building fixtures inside a test hangs it, and
  /// hangs every test after it. That happened on the second run of this file.
  ///
  /// They have to be real, too. An attachment pointing at a file that is not
  /// there throws while the page is being built, Flutter replaces the whole
  /// subtree with an error widget, and the play button disappears along with
  /// it — which looks exactly like the product bug this file exists to prevent.
  /// That happened on the *first* run. The bytes are not a real JPEG, so the
  /// decode still fails and the page shows its "could not be opened" panel;
  /// that is fine, and is not what is under test.
  late List<Attachment> pictures;
  late Attachment clip;
  late Attachment poster;

  Future<Attachment> make(String name, String mime) async {
    final stored = await vault.attachments
        .writeBytes(List<int>.generate(512, (i) => i % 256));
    return Attachment(
      id: stored.id,
      fileKey: stored.fileKey,
      originalName: name,
      mimeType: mime,
      byteSize: 512,
    );
  }

  setUpAll(() async {
    pictures = [
      for (var i = 0; i < 6; i++) await make('p$i.jpg', 'image/jpeg'),
    ];
    clip = await make('clip.mp4', 'video/mp4');
    poster = await make('clip_poster.jpg', 'image/jpeg');
  });

  ViewerItem photo(int i) =>
      ViewerItem(attachment: pictures[i], isVideo: false);

  ViewerItem video({bool withPoster = true}) => ViewerItem(
        attachment: clip,
        isVideo: true,
        poster: withPoster ? poster : null,
      );

  Future<void> show(
    WidgetTester tester,
    List<ViewerItem> items, {
    int initial = 0,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: PhotoViewer(
        items: items,
        store: vault.attachments,
        initialIndex: initial,
        onSave: (_) {},
        onTrash: (_) {},
      ),
    ));
    await tester.pump();
  }

  // ══ ROUND EIGHT, ISSUE 4A — THE PINCH THAT FAILED NINE TIMES IN TEN ═══
  //
  // *"So hard to view a photo dude! Double tap is better — when I try to pinch
  // the screen it fails! After 10 failed tries I get once the pinch right!"*
  //
  // Ten tries and one success is not a flaky gesture, it is a race. The page
  // carried a `VerticalDragGestureRecognizer` for pull-down-to-close and
  // `InteractiveViewer` carries a `ScaleGestureRecognizer` for the pinch, and a
  // drag recogniser declares victory the moment the **first** pointer moves
  // past the touch slop. Fingers do not land at the same millisecond, so in a
  // pinch it usually does — and the scale recogniser was rejected before it
  // ever saw two fingers.
  //
  // These tests are two-pointer for that reason. Nothing single-pointer can see
  // this bug, which is why nothing did.
  // ══ ROUND EIGHT, ISSUE 4A — THE PINCH THAT FAILED NINE TIMES IN TEN ═══
  //
  // *"So hard to view a photo dude! Double tap is better — when I try to pinch
  // the screen it fails! After 10 failed tries I get once the pinch right!"*
  //
  // Ten tries and one success is not a flaky gesture, it is a race with a
  // rigged finish line. A `VerticalDragGestureRecognizer` accepts at
  // `kTouchSlop` — **18 logical pixels on one finger** — while the
  // `ScaleGestureRecognizer` inside `InteractiveViewer` needs `kPanSlop`, 36,
  // or two fingers whose span has changed by 18. Fingers do not land at the
  // same millisecond, so whenever the first one drifted more than eighteen
  // pixels before the second arrived, the drag had already won the arena and
  // the pinch was over before it began.
  //
  // **The sweep below is the measurement.** Against the build on his phone it
  // reads: drift 0 → zooms, 10 → zooms, **20 → no zoom at all**, **30 → no
  // zoom at all**, 45 → zooms. That is not "sometimes"; it is a threshold, and
  // twenty pixels of drift is an ordinary hand.
  //
  // Nothing single-pointer can see any of this, which is why nothing did.
  group('ISSUE 4A — a pinch is a pinch', () {
    /// The photograph's current scale, read off the live transform.
    double scaleOf(WidgetTester tester) {
      final viewer = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer).first);
      return viewer.transformationController!.value.getMaxScaleOnAxis();
    }

    /// Two fingers landing a frame apart, the way real ones do.
    ///
    /// [drift] is how far the first finger travels before the second lands.
    /// It is the whole experiment: everything else is held still.
    Future<double> pinchOut(WidgetTester tester, {required double drift}) async {
      final iv = find.byType(InteractiveViewer).first;
      final centre = tester.getCenter(iv);

      final a = await tester.startGesture(centre - const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      if (drift > 0) {
        await a.moveBy(Offset(0, -drift));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final b = await tester.startGesture(centre + const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));

      // Diagonally apart, because real fingers are not on a rail — and the
      // vertical component is exactly what used to feed the wrong recogniser.
      for (var i = 0; i < 10; i++) {
        await a.moveBy(const Offset(-12, -4));
        await b.moveBy(const Offset(12, 4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final scale = scaleOf(tester);
      await a.up();
      await b.up();
      await tester.pump(const Duration(milliseconds: 200));
      return scale;
    }

    // The two that used to fail are 20 and 30. The rest are here so that a
    // future change cannot fix those two by breaking the others.
    for (final drift in <double>[0, 10, 20, 30, 45]) {
      testWidgets('two fingers zoom after ${drift.toInt()} points of drift',
          (tester) async {
        await show(tester, [photo(0)]);
        expect(await pinchOut(tester, drift: drift), greaterThan(1.5),
            reason: 'at ${drift.toInt()} points of drift the shipped build '
                'gave no zoom at all');
      });
    }

    testWidgets('and the photograph is not dragged towards being dismissed',
        (tester) async {
      // The half of the bug he could see: the pinch did not merely fail, it
      // started closing the picture instead.
      await show(tester, [photo(0)]);
      await pinchOut(tester, drift: 20);
      expect(find.byType(PhotoViewer), findsOneWidget);
    });

    testWidgets('one finger pulling down still closes it', (tester) async {
      // The gesture that was winning the arena still works. Fixing the pinch
      // by deleting drag-to-dismiss would have been a trade, not a fix.
      //
      // Pushed as a route rather than used as `home`, because closing is what
      // is under test and there is nothing under a root route to close to.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PhotoViewer(
                      items: [photo(0)],
                      store: vault.attachments,
                      initialIndex: 0,
                      onSave: (_) {},
                      onTrash: (_) {},
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(PhotoViewer), findsOneWidget);

      final centre = tester.getCenter(find.byType(InteractiveViewer).first);
      final one = await tester.startGesture(centre);
      for (var i = 0; i < 12; i++) {
        await one.moveBy(const Offset(0, 22));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await one.up();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(PhotoViewer), findsNothing,
          reason: 'pull down to close, on the scale recogniser now');
    });

    testWidgets('double tap zooms too, because he said it is better',
        (tester) async {
      // *"Double tap is better."* It already worked and it still does — stated
      // here so a future rewrite of the gesture handling cannot quietly take
      // away the one that was reliable.
      await show(tester, [photo(0)]);
      final at = tester.getCenter(find.byType(InteractiveViewer).first);

      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(at);

      // The zoom is a 220 ms animation, and an `AnimationController` needs one
      // frame to start its ticker and further frames to advance it. A single
      // long pump gives it exactly one tick at elapsed zero and it sits at 1.0
      // for ever — which reads as "double tap is broken" and is not.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(scaleOf(tester), greaterThan(1.3));
    });
  });

  group('ISSUE 15 — the album is one thing', () {
    testWidgets('a video and five photos count as six, not five',
        (tester) async {
      await show(tester, [
        video(),
        photo(0),
        photo(1),
        photo(2),
        photo(3),
        photo(4),
      ]);

      expect(find.text('1 of 6'), findsOneWidget,
          reason: 'he opened exactly this album and was shown "1 of 5"');
      expect(find.text('1 of 5'), findsNothing);
    });

    testWidgets('opening a photo can still reach the video', (tester) async {
      // "When I open P it shows me 1 of 5, and unable to slide to V."
      await show(
        tester,
        [video(), photo(0), photo(1)],
        initial: 1,
      );
      expect(find.text('2 of 3'), findsOneWidget);

      // Swipe back towards the clip.
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      // Bounded rather than `pumpAndSettle`: the picture's loading indicator
      // animates for as long as the decode is pending, and a decode that never
      // finishes means a tree that never settles.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('1 of 3'), findsOneWidget,
          reason: 'the video is a page like any other now');
      expect(find.byTooltip('Play this video'), findsOneWidget);
    });

    testWidgets('and opening the video can slide on to the photos',
        (tester) async {
      // "When I slide it open V and I can't slide to P."
      await show(tester, [video(), photo(0), photo(1)]);
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.byTooltip('Play this video'), findsNothing,
          reason: 'a photograph has nothing to play');
    });

    testWidgets('a video page offers play; a photo page does not',
        (tester) async {
      await show(tester, [video()]);
      expect(find.byTooltip('Play this video'), findsOneWidget);

      await show(tester, [photo(0)]);
      expect(find.byTooltip('Play this video'), findsNothing);
    });

    testWidgets('a lone photograph shows no counter at all', (tester) async {
      await show(tester, [photo(0)]);
      expect(find.textContaining(' of '), findsNothing,
          reason: '"1 of 1" is noise over somebody\'s picture');
    });

    testWidgets('a video with no poster frame still gets a page',
        (tester) async {
      // Imported before poster frames existed. It must not be dropped from the
      // album, which is the whole fault being fixed.
      await show(tester, [video(withPoster: false), photo(0)]);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.byTooltip('Play this video'), findsOneWidget);
    });
  });

  group('ISSUE 14 — which way round the bar goes', () {
    testWidgets('the counter comes first and the menu is furthest right',
        (tester) async {
      await show(tester, [photo(0), photo(1), photo(2)]);

      final counter = tester.getRect(find.text('1 of 3'));
      final menu = tester.getRect(find.byIcon(Icons.more_vert));
      final back = tester.getRect(find.byIcon(Icons.arrow_back));

      expect(menu.center.dx, greaterThan(counter.center.dx),
          reason: '"Interchange their position. Understood?" — the menu is the '
              'thing you press, so it takes the corner a thumb reaches');
      expect(counter.center.dx, greaterThan(back.center.dx));
    });

    testWidgets('and they sit on one line', (tester) async {
      await show(tester, [photo(0), photo(1)]);
      final counter = tester.getRect(find.text('1 of 2'));
      final menu = tester.getRect(find.byIcon(Icons.more_vert));
      expect(counter.center.dy, closeTo(menu.center.dy, 1.0));
    });
  });
}
