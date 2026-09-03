import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/empty_day.dart';

/// The first minute anybody spends in this app.
///
/// **`Honest Review`, the small ones: "a real empty state for a brand-new
/// vault."** It was being drawn as an ordinary quiet Tuesday — one line saying
/// *"Anything you want to keep?"* — which is a good sentence in the third year
/// and the wrong one in the first minute, because it answers a question they
/// have not asked and not the one they have.
///
/// ── WHAT THESE HOLD ───────────────────────────────────────────────────────
///
/// The three ways this could go wrong, none of which is "does it look nice":
///
///  1. **It shows to the wrong person.** An established vault must never flash
///     a welcome at somebody who has been here three years.
///  2. **It becomes a tour.** No steps, no counter, no dismiss button. The
///     moment it grows one it is a task, and `PLAN.md` §3 and
///     `ETHICAL-DESIGN.md` both rule that out.
///  3. **It stops fitting.** It is the longest thing on the emptiest screen,
///     so it is the first thing to break at 200% text.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isFirstEver,
    bool isToday = true,
    double textScale = 1.0,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: EmptyDay(
              date: DateTime(2026, 8, 28),
              isToday: isToday,
              isFirstEver: isFirstEver,
              onTap: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('who sees it', () {
    testWidgets('a brand-new vault gets the page', (tester) async {
      await pump(tester, isFirstEver: true);
      expect(find.textContaining('you have not written in it yet'),
          findsOneWidget);
    });

    testWidgets('an established vault gets the ordinary line', (tester) async {
      await pump(tester, isFirstEver: false);
      expect(find.text('Anything you want to keep?'), findsOneWidget);
      expect(find.textContaining('you have not written in it yet'), findsNothing);
    });

    testWidgets('a past day never gets it, even in a brand-new vault',
        (tester) async {
      // A new vault swiped back to last March is a day in the past. Greeting
      // somebody there would be greeting them in the wrong room.
      await pump(tester, isFirstEver: true, isToday: false);
      expect(find.text('Nothing on this day.'), findsOneWidget);
      expect(find.textContaining('you have not written in it yet'), findsNothing);
    });
  });

  group('it is a page, not a tour', () {
    testWidgets('it names the three ways in', (tester) async {
      // Three unlabelled glyphs at the bottom of the screen get names exactly
      // once, in the order of the bar they point at.
      await pump(tester, isFirstEver: true);
      expect(find.textContaining('Tap this page to write'), findsOneWidget);
      expect(find.textContaining('microphone'), findsOneWidget);
      expect(find.textContaining('photograph'), findsOneWidget);
    });

    testWidgets('there is no dismiss, no step counter and no next',
        (tester) async {
      await pump(tester, isFirstEver: true);
      for (final word in const [
        'Dismiss',
        'Got it',
        'Next',
        'Skip',
        'Step 1',
        '1 of 3',
      ]) {
        expect(find.textContaining(word), findsNothing,
            reason: 'the moment this grows a "$word" it is a task, and a '
                'journal that sets tasks is the thing PLAN.md §3 refuses');
      }
    });

    testWidgets('it makes exactly one promise', (tester) async {
      // The onboarding has already made the longer argument. Repeating it here
      // would be the app selling itself to somebody who has already bought it.
      await pump(tester, isFirstEver: true);
      expect(find.text('None of it leaves this phone.'), findsOneWidget);
    });

    testWidgets('tapping it starts writing', (tester) async {
      // The sheet looks like somewhere to write. ISSUE 9: an interface that
      // invites a tap and ignores it is worse than one that never invited it.
      var started = false;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: EmptyDay(
            date: DateTime(2026, 8, 28),
            isToday: true,
            isFirstEver: true,
            onTap: () => started = true,
          ),
        ),
      ));
      await tester.tap(find.textContaining('you have not written in it yet'));
      await tester.pump();
      expect(started, isTrue);
    });

    testWidgets('a screen reader is told what it is for', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, isFirstEver: true);
      expect(
          find.bySemanticsLabel('Write the first thing in your journal'),
          findsOneWidget);
      handle.dispose();
    });
  });

  group('it still fits', () {
    testWidgets('at 200% text on the narrowest phone', (tester) async {
      // It is the longest thing on the emptiest screen, so it is the first
      // thing to break at 200% — and the person it breaks for is the person
      // who most needed the larger text.
      await pump(
        tester,
        isFirstEver: true,
        textScale: 2.0,
        size: const Size(320, 720),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('you have not written in it yet'),
          findsOneWidget);
    });

    testWidgets('on a tablet', (tester) async {
      await pump(tester, isFirstEver: true, size: const Size(1200, 800));
      expect(tester.takeException(), isNull);
    });
  });
}
