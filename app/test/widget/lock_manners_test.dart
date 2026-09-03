import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/plain_words.dart';

/// The three small things round nine found about locking, none of which is a
/// crash and all of which made the app feel like it was misbehaving.
///
/// ISSUE 19 — a settings tile that answered "5 minutes" with "300 seconds".
/// ISSUE 21 — an idle lock indistinguishable from a crash. (Its own tests are
///            in `test/vault/idle_timeout_test.dart`, where the timers are.)
/// ISSUE 22 — the "Deleted. Undo" bar photographed sitting on the lock screen.
void main() {
  group('ISSUE 19 — a setting reads back what you chose', () {
    test('never in the units the app happened to store it in', () {
      // The three he listed, in his words, against what the tile used to say.
      expect(humanDuration(const Duration(seconds: 30)), '30 seconds');
      expect(humanDuration(const Duration(minutes: 1)), '1 minute');
      expect(humanDuration(const Duration(minutes: 5)), '5 minutes');
      // And the two ISSUE 21 added.
      expect(humanDuration(const Duration(minutes: 30)), '30 minutes');
      expect(humanDuration(const Duration(hours: 1)), '1 hour');
    });

    test('zero says whatever zero means on that particular screen', () {
      expect(humanDuration(Duration.zero), 'Never');
      expect(humanDuration(Duration.zero, zero: 'Always ask'), 'Always ask');
    });

    test('nothing it can be handed comes out as raw seconds past a minute', () {
      // Every option in the app, swept. If somebody adds one that reads badly,
      // this is where they find out.
      const everyOption = <Duration>[
        Duration(seconds: 15),
        Duration(seconds: 30),
        Duration(minutes: 1),
        Duration(minutes: 5),
        Duration(minutes: 15),
        Duration(minutes: 30),
        Duration(hours: 1),
      ];
      for (final d in everyOption) {
        final said = humanDuration(d);
        if (d.inSeconds >= 60) {
          expect(said, isNot(contains('seconds')),
              reason: '$d is read back as "$said", which is the ISSUE 19 bug');
        }
      }
    });
  });

  group('ISSUE 22 — the undo bar does not follow you to the lock screen', () {
    testWidgets('clearing the messenger takes down a bar that is already up',
        (tester) async {
      // What `app.dart` does the instant the vault locks, reproduced at the
      // level that matters: the messenger lives above the Navigator, so the
      // route changing underneath it does nothing at all to a bar it is
      // showing. This is the assertion that the app does not rely on that.
      final messenger = GlobalKey<ScaffoldMessengerState>();

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        scaffoldMessengerKey: messenger,
        home: const Scaffold(body: Text('the day')),
      ));

      messenger.currentState!.showSnackBar(SnackBar(
        content: const Text('Deleted.'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
        duration: const Duration(seconds: 3),
      ));
      await tester.pump();
      expect(find.text('Deleted.'), findsOneWidget);

      // The vault locks: the whole screen is replaced…
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        scaffoldMessengerKey: messenger,
        home: const Scaffold(body: Text('Lamplight')),
      ));
      await tester.pump();
      expect(find.text('Deleted.'), findsOneWidget,
          reason: 'this is the bug: swapping the screen leaves the bar behind, '
              'which is why it has to be cleared explicitly');

      // …and this is the line that was missing.
      messenger.currentState!.clearSnackBars();
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('and it is cleared, not merely hidden', (tester) async {
      // `hideCurrentSnackBar` dismisses the visible one and lets the queue
      // through — so three deletes in a row would put the second bar up on the
      // lock screen the moment the first came down. Round five hit exactly this
      // and `clearSnackBars` is the answer both times.
      final messenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        scaffoldMessengerKey: messenger,
        home: const Scaffold(body: SizedBox()),
      ));

      for (final word in ['Deleted.', 'Deleted.', 'Deleted.']) {
        messenger.currentState!
            .showSnackBar(SnackBar(content: Text(word)));
      }
      await tester.pump();
      expect(find.text('Deleted.'), findsOneWidget);

      messenger.currentState!.clearSnackBars();
      await tester.pumpAndSettle();
      expect(find.text('Deleted.'), findsNothing,
          reason: 'a queued bar arrived after the clear');
    });
  });
}
