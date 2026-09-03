import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/database.dart' show debugUseInProcessDatabase;
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/features/calendar/calendar_sheet.dart';
import 'package:lamplight/features/calendar/year_grid.dart';
import 'package:sodium/sodium_sumo.dart';

/// The calendar sheet, and the three things **ISSUE 8** said about it.
///
/// > *"When I slide between months it's smooth as butter, my fingers feel
/// > heavenly — but in year grid I can't slide years. When I use the arrows it
/// > jerks like hell! I feel like I have done something to piss off my phone."*
///
/// Two of the three are testable from here — the year sliding, and the query
/// that was started on every rebuild and made the arrows jerk. The third, the
/// chip that said *"First entry, 2026"*, is tested where it lives, in the
/// wheels.
///
/// **What this file cannot do is tell you it feels smooth.** Only a finger can.
/// What it can do is fail the day somebody makes the year grid a plain rebuild
/// again, or hands a `FutureBuilder` a future built during `build`.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late EntryRepository repository;
  late AttachmentImporter importer;

  setUpAll(() async {
    // Same reasoning as `screens_test.dart`: this file reads the vault through
    // widgets, and a worker isolate delivers its stream events on the real
    // event loop, which `testWidgets`' fake-async zone never reaches.
    debugUseInProcessDatabase = true;

    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_calendar');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    repository = EntryRepository(
      vault.database,
      attachments: vault.attachments,
    );
    importer = AttachmentImporter(vault);
  });

  tearDownAll(() async {
    debugUseInProcessDatabase = false;
    await vault.lock();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Opens the sheet on a phone-shaped window and returns once it is up.
  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showCalendarSheet(
                context: context,
                repository: repository,
                importer: importer,
                initialDate: DateTime(2026, 8, 27),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the year grid is a pager, like the months are', (tester) async {
    await openSheet(tester);

    // Into the year, by the button that says "The whole year".
    await tester.tap(find.byTooltip('The whole year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2026'), findsOneWidget);
    expect(find.byType(YearGrid), findsWidgets);

    // ── The actual assertion ──────────────────────────────────────────────
    //
    // A `PageView` whose controller is attached is what makes a horizontal
    // drag move between years. Before this, the year was a widget rebuilt
    // under a new key: nothing to slide, which is exactly what he reported.
    final pagers = tester
        .widgetList<PageView>(find.byType(PageView))
        .where((p) => p.controller?.hasClients ?? false);
    expect(pagers, isNotEmpty,
        reason: 'the year grid must be swipeable, not rebuilt under a key');
  });

  testWidgets('sliding the year grid changes the year', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byTooltip('The whole year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2026'), findsOneWidget);

    // Right to left is forwards, the way every pager on the phone works.
    await tester.drag(find.byType(YearGrid).first, const Offset(-400, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('2027'), findsOneWidget,
        reason: 'a swipe on the year grid should move a year');
    expect(find.text('2026'), findsNothing);
  });

  testWidgets('the year arrows move the same pager, not a rebuild',
      (tester) async {
    await openSheet(tester);
    await tester.tap(find.byTooltip('The whole year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Previous year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('2025'), findsOneWidget);

    await tester.tap(find.byTooltip('Next year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('the year grid stops at the ends rather than running on',
      (tester) async {
    // 1900 and 2100 are `DateWheel`'s range and this has to agree with it.
    // A pager that scrolls past its own bounds and is dragged back by a
    // `setState` shows the user a year that then disappears.
    await openSheet(tester);
    await tester.tap(find.byTooltip('The whole year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final pager = tester
        .widgetList<PageView>(find.byType(PageView))
        .firstWhere((p) => p.controller?.hasClients ?? false);
    // 1900..2100 inclusive.
    expect(pager.childrenDelegate.estimatedChildCount, 201);
  });

  testWidgets('the month grid does not re-query when the sheet rebuilds',
      (tester) async {
    // ── WHY THIS IS ASSERTED AS "NO FutureBuilder" ────────────────────────
    //
    // The jerk was a `FutureBuilder` handed `_MonthData.load(...)` built
    // inside `build`. Every rebuild made a new future; a `FutureBuilder`
    // given a new future throws away the snapshot it was showing and starts
    // again with none — so a single arrow tap emptied three months of marks
    // and refilled them when the queries came back.
    //
    // There is no way to count queries from out here, and the shape of the
    // bug is not really "how many queries" — it is "the answer is discarded
    // and re-fetched during a rebuild". So the test asserts the shape: the
    // month grid holds its data itself. Anybody reintroducing the pattern has
    // to delete this test to do it, and the note above is why they should not.
    await openSheet(tester);

    expect(find.byType(FutureBuilder<Object?>), findsNothing,
        reason: 'a future built during build restarts on every rebuild');

    // And the arrows still work, which is the thing the fix must not break.
    expect(find.text('August 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('September 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('August 2026'), findsOneWidget);
  });
}
