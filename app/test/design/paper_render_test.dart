@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/paper.dart';
import 'package:lamplight/design/tokens.dart';

/// Renders every page surface and ruling to PNGs so a person can look at them.
///
/// Tagged `render` so `flutter test` skips it. The app refuses screenshots on
/// every build — `FLAG_SECURE` is on from the first frame and only Piyush can
/// turn it off, from inside the vault — so this is the only way anybody working
/// on `paper.dart` can see what they have changed.
///
/// ```
/// flutter test test/design/paper_render_test.dart --tags render
/// ```
///
/// Writes into `TEMP/lamplight_paper/`, outside the repo. Nothing it produces
/// is user content and nothing is committed.
void main() {
  testWidgets('draw every surface and ruling', (tester) async {
    final out = Directory('${Directory.systemTemp.path}/lamplight_paper');
    out.createSync(recursive: true);

    // Half the Redmi Pad, so the files are quick to look at and the features
    // are still the size they will be on the device.
    const size = Size(430, 620);

    Future<void> shot(
      String name,
      PageSurface surface,
      PageRuling ruling,
      LamplightColors colours,
    ) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: size),
        child: MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: lamplightTheme(colours),
          home: SizedBox(
            width: size.width,
            height: size.height,
            child: RepaintBoundary(
              key: ValueKey(name),
              child: PaperGround(
                surface: surface,
                ruling: ruling,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ));
      // Long enough for two separate things. The grain texture is built
      // asynchronously and arrives on the frame after the first paint; and
      // `MaterialApp` crossfades between themes over about 200 ms, so a
      // light-theme capture taken 60 ms after a dark one is a picture of the
      // transition rather than of the page. The first version of this harness
      // reported the light paper as mid-grey for exactly that reason.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(ValueKey(name)));
      // `runAsync`, because `toImage` and the file write are real async work
      // and a `testWidgets` body runs in a fake-async zone where neither ever
      // completes. Without it this hangs on the first image.
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List(), flush: true);
        image.dispose();
      });
    }

    for (final surface in PageSurface.values) {
      await shot('dark_${surface.id}', surface, PageRuling.none,
          LamplightColors.dark);
    }
    for (final surface in PageSurface.values) {
      await shot('light_${surface.id}', surface, PageRuling.none,
          LamplightColors.light);
    }
    for (final ruling in PageRuling.values) {
      await shot('ruling_${ruling.id}', PageSurface.paper, ruling,
          LamplightColors.dark);
    }

    // Unmounted before the test ends, so the star map's clock is cancelled.
    // A pending `Timer.periodic` fails a widget test on the way out.
    await tester.pumpWidget(const SizedBox.shrink());

    // ignore: avoid_print
    print('wrote ${out.path}');
  });
}
