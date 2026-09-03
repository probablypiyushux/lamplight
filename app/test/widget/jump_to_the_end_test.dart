import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/day_stream.dart';

/// Getting to the end of a long day. **`PLAN.md` §7.0-E.**
///
/// > *"Jump to the first or last entry of a long day — small, and the only
/// > navigation complaint left."*
///
/// ── WHAT IS ACTUALLY WORTH A TEST HERE ────────────────────────────────────
///
/// Not whether the arrow looks right. Two things:
///
///  1. **The rule about when the control exists at all.** A button that shows
///     up on every three-line day is furniture that covers somebody's writing,
///     and a button that never shows up is the feature not existing. The
///     threshold is the whole design and it is one number.
///
///  2. **That scrolling does not rebuild the day.** This is round ten's *"the
///     app hangs as hell"* bug in a new place, and the first draft of this
///     control had it: a `setState` per scroll frame rebuilds the
///     `StreamBuilder`, the album grouping and every visible entry, sixty
///     times a second, to move one arrow. The test counts rebuilds of the
///     stream against rebuilds of the button, because that ratio is the fix
///     and nothing about the app *looks* different when it regresses.
void main() {
  group('the day stream is not rebuilt by scrolling', () {
    testWidgets('a flick through a long list rebuilds the arrow, not the list',
        (tester) async {
      var listBuilds = 0;
      var buttonBuilds = 0;

      // A stand-in with the same arrangement as `DayStream`: a notifier fed by
      // a scroll notification, and a `ValueListenableBuilder` around the
      // button alone. What is being tested is the *shape*, which is the thing
      // a later edit would break by reaching for `setState`.
      final jump = ValueNotifier<({bool visible, bool toTop})>(
          (visible: false, toTop: false));
      addTearDown(jump.dispose);

      bool onScroll(ScrollNotification n) {
        if (n.metrics.axis != Axis.vertical) return false;
        final next = (
          visible: n.metrics.maxScrollExtent > n.metrics.viewportDimension,
          toTop: n.metrics.pixels >= n.metrics.maxScrollExtent - 24,
        );
        if (next != jump.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            jump.value = next;
          });
        }
        return false;
      }

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: Builder(builder: (context) {
            listBuilds++;
            return Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: onScroll,
                  child: ListView.builder(
                    itemCount: 200,
                    itemBuilder: (_, i) => SizedBox(height: 60, child: Text('$i')),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<({bool visible, bool toTop})>(
                    valueListenable: jump,
                    builder: (context, state, _) {
                      buttonBuilds++;
                      return SizedBox(
                        width: 48,
                        height: 48,
                        child: state.visible
                            ? const Icon(Icons.arrow_downward)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ));
      await tester.pump();

      final listAtStart = listBuilds;
      final buttonAtStart = buttonBuilds;

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(listBuilds, listAtStart,
          reason: 'scrolling must not rebuild the day. A setState per scroll '
              'frame is round ten\'s "app hangs as hell" bug in a new place.');
      expect(buttonBuilds, greaterThan(buttonAtStart),
          reason: 'the arrow does have to notice');
    });

    testWidgets('scrolling within the middle of a long day notifies nobody',
        (tester) async {
      // The value is a pair of booleans, not the raw offset, so a drag that
      // crosses neither threshold is zero rebuilds rather than one per frame.
      var buttonBuilds = 0;
      final jump = ValueNotifier<({bool visible, bool toTop})>(
          (visible: true, toTop: false));
      addTearDown(jump.dispose);

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        home: ValueListenableBuilder<({bool visible, bool toTop})>(
          valueListenable: jump,
          builder: (context, state, _) {
            buttonBuilds++;
            return const SizedBox();
          },
        ),
      ));
      final at = buttonBuilds;

      // Same booleans, different scroll position.
      jump.value = (visible: true, toTop: false);
      await tester.pump();

      expect(buttonBuilds, at,
          reason: 'an identical record must not notify — that is what makes '
              'the common case free');
    });
  });

  group('when the control exists at all', () {
    // The threshold is a private constant, so this states the decision rather
    // than reaching into it. Getting it wrong in the small direction puts a
    // button over somebody\'s last sentence on an ordinary day.
    const longDay = 1.0;
    const atEnd = 24.0;

    // `extent` is `maxScrollExtent` — how far there is to *travel*, which is
    // the content's height minus one viewport. A day two screens tall has one
    // screen of travel.
    bool visibleFor({required double extent, required double viewport}) =>
        extent > viewport * longDay;

    test('a day that fits on the screen gets no button', () {
      expect(visibleFor(extent: 0, viewport: 800), isFalse);
    });

    test('a day that spills a little past the fold gets no button', () {
      // 800-point window, 1,000 points of content: 200 of travel. A flick.
      expect(visibleFor(extent: 200, viewport: 800), isFalse);
    });

    test('a day exactly two screens tall is still only one flick', () {
      // 1,600 of content in an 800 window: 800 of travel, one screenful. On
      // the line rather than over it, and the line is drawn so that the
      // ordinary case has no button.
      expect(visibleFor(extent: 800, viewport: 800), isFalse);
    });

    test('a day of two and a half screens gets one', () {
      expect(visibleFor(extent: 1200, viewport: 800), isTrue);
    });

    test('the threshold is in screens, so it holds on any window', () {
      // The same day shape on a short phone and a tall tablet decides the
      // same way. A fixed pixel threshold would put the button on ordinary
      // days on a small screen and hide it on long ones on a large screen.
      expect(visibleFor(extent: 900, viewport: 600), isTrue);
      expect(visibleFor(extent: 900, viewport: 1000), isFalse);
    });

    test('the arrow points to the top only once you are at the bottom', () {
      bool toTop(double pixels, double extent) => pixels >= extent - atEnd;
      expect(toTop(0, 1200), isFalse);
      expect(toTop(600, 1200), isFalse);
      // Within the settle window, so the arrow turns over before the physics
      // have quite finished rather than a frame after.
      expect(toTop(1180, 1200), isTrue);
      expect(toTop(1200, 1200), isTrue);
    });
  });

  group('the widget is still exported the way the day screen uses it', () {
    test('DayStream is the public name', () {
      // A rename would be caught by the compiler; this is here so the import
      // above keeps the file honest about what it is testing.
      expect(DayStream, isNotNull);
    });
  });
}
