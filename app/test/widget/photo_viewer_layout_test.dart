import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// ISSUE 9 — "the photo opens as a postage stamp at the top of a black screen".
///
/// The cause was never `BoxFit` and never the image. `Scaffold` hands its body
/// **loose** constraints, and a `Stack` sizes itself to its *non-positioned*
/// children. The viewer's chrome row — back button, "4 of 6" — was not
/// positioned, so the Stack collapsed to the height of a button and
/// `Positioned.fill` filled that instead of the screen.
///
/// Confirmed on the real device by dumping the live render tree: the pager's
/// viewport was `Size(685.7, 98.3)` on a 685.7 x 1142.9 screen.
///
/// This test is deliberately about the *shape* rather than about PhotoViewer,
/// so it stays true if the viewer is rewritten. The first case is the bug as it
/// was; the second is the arrangement that fixes it.
void main() {
  Widget harness({required bool positionChrome, required bool expand}) {
    final chrome = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
        const Spacer(),
        const Text('4 of 6'),
      ]),
    );
    return MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      home: Scaffold(
        body: Stack(
          fit: expand ? StackFit.expand : StackFit.loose,
          children: [
            Positioned.fill(
              child: Container(key: const Key('page'), color: Colors.blue),
            ),
            if (positionChrome)
              Positioned(top: 0, left: 0, right: 0, child: chrome)
            else
              chrome,
          ],
        ),
      ),
    );
  }

  testWidgets('the old arrangement really did collapse (guards the diagnosis)',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(positionChrome: false, expand: false));
    final page = tester.renderObject<RenderBox>(find.byKey(const Key('page')));
    final screen = tester.getSize(find.byType(Scaffold));
    expect(page.size.height, lessThan(screen.height / 2),
        reason: 'this is the bug: the page collapsed to the chrome height');
  });

  testWidgets('a positioned chrome row lets the page fill the screen',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(positionChrome: true, expand: true));
    final page = tester.renderObject<RenderBox>(find.byKey(const Key('page')));
    final screen = tester.getSize(find.byType(Scaffold));
    expect(page.size, screen,
        reason: 'the photograph must get the whole screen, on any device');
  });

  testWidgets('and it still fills on a phone, not just a tablet',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(positionChrome: true, expand: true));
    final page = tester.renderObject<RenderBox>(find.byKey(const Key('page')));
    expect(page.size, tester.getSize(find.byType(Scaffold)));
  });
}
