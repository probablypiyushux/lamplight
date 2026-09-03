import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/announce.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **ROUND EIGHTEEN — "can you see the notification below? it doesn't goes!"**
///
/// A `Deleted. Undo` bar that never left. Not slow to leave: it survived
/// backgrounding the app, the vault re-locking itself and unlocking again, and
/// it was still on screen while the entry it offered to undo was visibly back
/// on the page above it, restored from Trash minutes earlier. Only
/// force-stopping the process cleared it.
///
/// **He reported the same sentence in round five** — *"it should have gone
/// automatically — 2 or 3 seconds — but it doesn't go"* — and it was answered
/// then with a shorter duration and `clearSnackBars`. Both were right; neither
/// was the bug. The report coming back word for word is the tell that the fix
/// was at the wrong layer.
///
/// The layer is that a `SnackBar`'s dismiss timer is created inside
/// `ScaffoldMessengerState.build`, and only once the entrance animation has
/// completed. If that rebuild does not land at the right moment then nothing
/// ever tries again, and `duration:` is never read by anybody. See
/// `design/announce.dart`.
void main() {
  Widget harness(void Function(BuildContext) act) => MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => act(context),
              child: const Text('go'),
            ),
          ),
        ),
      );

  testWidgets('a bar leaves on its own, without depending on the framework to '
      'arm that', (tester) async {
    await tester.pumpWidget(harness((c) => announce(c, 'Deleted.')));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('Deleted.'), findsOneWidget);

    // Past the three seconds and the four-hundred-millisecond grace. Pumped by
    // hand rather than settled: `pumpAndSettle` can never return in this app,
    // because `PaperGround` always has a frame scheduled — the star map turns
    // at the sidereal rate. See `app_boots_test.dart`.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('Deleted.'),
      findsNothing,
      reason: 'The bar must dismiss itself. A message that will not go away is '
          'not a small defect in a journal, and this one said "Deleted."',
    );
  });

  testWidgets('the undo still works while it is up', (tester) async {
    var undone = false;
    await tester.pumpWidget(harness((c) => announce(
          c,
          'Deleted.',
          action: SnackBarAction(label: 'Undo', onPressed: () => undone = true),
        )));
    await tester.tap(find.text('go'));
    await tester.pump();
    // The bar has to finish sliding in before its action is a real target.
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);

    // Let the bar finish leaving, so no timer is pending when the test ends.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('a second message replaces the first rather than queueing behind '
      'it', (tester) async {
    // Round five: deleting three things in a row queued three bars, and the
    // last one left the screen eighteen seconds after the first delete.
    late BuildContext ctx;
    await tester.pumpWidget(harness((c) => ctx = c));
    await tester.tap(find.text('go'));
    await tester.pump();

    announce(ctx, 'First.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('First.'), findsOneWidget);

    announce(ctx, 'Second.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('First.'), findsNothing);
    expect(find.text('Second.'), findsOneWidget);

    // Let the bar finish leaving, so no timer is pending when the test ends.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
  });

  // ── The ratchet ──────────────────────────────────────────────────────────
  //
  // Twenty-five call sites still build a `SnackBar` by hand, and every one of
  // them carries the same hazard: a bar whose dismissal depends on a rebuild
  // nobody controls. They are not all converted in one go on the eve of a
  // closed test, because a twenty-five-site refactor of every message the app
  // says is a worse risk than the messages themselves.
  //
  // So this is a ratchet, exactly like the seventy right-to-left insets in
  // `localisation_test.dart`: the number may go **down** and never up. A new
  // screen that wants to say something routes it through `announce`, and
  // anybody with ten minutes can convert one of the twenty-five and lower this
  // line by one.
  test('no new hand-built SnackBar is added', () {
    final offenders = <String, int>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      if (path.endsWith('design/announce.dart')) continue;
      final n = 'showSnackBar'.allMatches(f.readAsStringSync()).length;
      if (n > 0) offenders[path] = n;
    }
    final total = offenders.values.fold(0, (a, b) => a + b);

    expect(
      total,
      lessThanOrEqualTo(25),
      reason: 'A hand-built SnackBar cannot be relied on to dismiss itself in '
          'this app. Route it through `announce` in design/announce.dart.\n'
          'Sites: $offenders',
    );
  });
}
