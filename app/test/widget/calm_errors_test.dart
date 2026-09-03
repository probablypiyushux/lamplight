import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/error/error_surface.dart';

/// ISSUE 15, both halves.
///
/// The first group proves the user never sees framework output. The second
/// proves the *specific* assertion Piyush photographed — and it is written so
/// that it reproduces the old arrangement rather than the new one, so the
/// diagnosis cannot rot into a test that would pass either way.
void main() {
  group('a failure never reaches the user as developer output', () {
    late ErrorWidgetBuilder original;

    setUp(() {
      original = ErrorWidget.builder;
      installCalmErrors();
    });

    tearDown(() {
      ErrorWidget.builder = original;
    });

    testWidgets('a screen-sized hole gets the page, in the app\'s own voice',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: lamplightTheme(LamplightColors.dark),
          home: Scaffold(body: Builder(builder: (_) => throw StateError('x'))),
        ),
      );

      expect(find.text('That screen did not open.'), findsOneWidget);
      expect(find.textContaining('Nothing was lost'), findsOneWidget);
      // The thing that must never appear.
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      tester.takeException();
    });

    testWidgets('a block-sized hole gets one quiet line, not a whole page',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: lamplightTheme(LamplightColors.dark),
          home: Scaffold(
            body: Column(
              children: [
                const Text('the day is still readable'),
                SizedBox(
                  height: 80,
                  child: Builder(builder: (_) => throw StateError('x')),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('This part could not be shown.'), findsOneWidget);
      // The rest of the day survived, which is the entire reason the small
      // form exists.
      expect(find.text('the day is still readable'), findsOneWidget);
      expect(find.text('That screen did not open.'), findsNothing);
      tester.takeException();
    });

    testWidgets('an async error that escapes the framework does not kill the app',
        (tester) async {
      final seen = <Object>[];
      installCalmErrors(onReport: (e, _) => seen.add(e));

      final handled = PlatformDispatcher.instance.onError!(
        StateError('an unawaited future'),
        StackTrace.current,
      );

      // True means "handled": the isolate lives, and whatever was being typed
      // is still on screen.
      expect(handled, isTrue);
      expect(seen, hasLength(1));
    });
  });

  // ── What the text-size slider does to the tree underneath it ──────────
  //
  // `app.dart`'s builder used to insert a MediaQuery above the app's Navigator
  // only when the text-size setting was off its default — `if (factor == 1.0)
  // return content;`. That makes the *shape* of the tree depend on a setting,
  // and the first drag of the slider therefore changed the depth of everything
  // below it.
  //
  // What that costs is measured here rather than argued: the InheritedWidget
  // between the wrapper and the Navigator is destroyed and rebuilt, so every
  // screen in the stack is remounted mid-gesture. The Navigator's own state
  // survives — it has a GlobalKey — which is exactly what makes the damage
  // easy to miss.
  group('the text-size slider does not rebuild the tree under it', () {
    testWidgets('the old arrangement tore down the inherited widget',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_shell(wrapped: false, navKey: navKey));
      final before = tester.element(find.byType(_Typography));
      final navBefore = navKey.currentState;

      // The slider moves off 100%: a MediaQuery appears above everything.
      await tester.pumpWidget(_shell(wrapped: true, navKey: navKey));

      expect(tester.element(find.byType(_Typography)), isNot(same(before)),
          reason: 'the inherited element was destroyed and rebuilt');
      expect(navKey.currentState, same(navBefore),
          reason: 'the navigator survived, which is what hid this');
    });

    testWidgets('a constant depth keeps every element in place, which is the fix',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_shell(wrapped: true, navKey: navKey, scale: 1.0));
      final before = tester.element(find.byType(_Typography));

      await tester.pumpWidget(_shell(wrapped: true, navKey: navKey, scale: 1.2));

      expect(tester.element(find.byType(_Typography)), same(before));
      expect(tester.takeException(), isNull);
    });
  });
}

/// The two shapes `app.dart`'s builder could have: with the MediaQuery always
/// present, and with it appearing only once the setting moves.
Widget _shell({
  required bool wrapped,
  required GlobalKey<NavigatorState> navKey,
  double scale = 1.2,
}) {
  final content = _Typography(
    child: Navigator(
      key: navKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) {
          // A dependent. This is what every screen does through
          // `writingStyle(context)`.
          _Typography.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  if (!wrapped) {
    return Directionality(textDirection: TextDirection.ltr, child: content);
  }
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: content,
    ),
  );
}

/// A stand-in for `LampTypography` with the same two properties that matter:
/// it is an [InheritedWidget], and screens below it depend on it.
class _Typography extends InheritedWidget {
  const _Typography({required super.child});

  static _Typography of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Typography>()!;

  @override
  bool updateShouldNotify(_Typography old) => false;
}
