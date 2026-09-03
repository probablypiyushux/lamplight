import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/database.dart' show Entry;
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/day/day_screen.dart';
import 'package:lamplight/features/day/empty_day.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 7 — "STATIC BOX — PENCIL ICON — DOESN'T WORKS??? WHY?"**
///
/// With, in the margin beside the same screenshot: *"This box even after
/// touching here don't open write tab"* and *"This icon → wire this icon at
/// least to write"*.
///
/// The empty-day sheet is drawn to look like somewhere to write — that is the
/// whole endowed-progress argument in `EmptyDay` — and it carries a pencil,
/// which is the most literal "you may write here" symbol there is. If either
/// one does not put the caret on the page, the app has invited a tap and
/// ignored it, which `PLAN.md` §11 test 6 calls the same defect as a crash
/// wearing better clothes.
///
/// These tests press both, on today and on a day that is not today, and check
/// the keyboard would actually come up.
/// Pumps until [finder] matches, or gives up after two seconds of app time.
///
/// A fixed delay is an assumption about how fast something else is. This is the
/// same wait expressed as the condition it is actually waiting for, which
/// survives the database moving to a background isolate — and would survive it
/// moving back.
Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AppSettings settings;
  late EntryRepository repo;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_writing');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    repo = EntryRepository(vault.database, attachments: vault.attachments);
  });

  setUp(() async {
    settings = await AppSettings.load(
      File('${tmp.path}/settings_${DateTime.now().microsecondsSinceEpoch}.json'),
    );
  });

  tearDownAll(() async {
    await vault.lock();
    // ── Why this waits, and why it stopped being optional ─────────────────
    //
    // `AppSettings._write` saves fire-and-forget — `unawaited(_save())` — which
    // is right for the app: a failed preference write is not worth blocking a
    // tap for. It means a save can still be in flight when a test finishes.
    //
    // These tests never tripped it until `SilentBackup.markDirty` started
    // writing `vaultChangedSinceBackup` to disk instead of to a field. Writing
    // to the day now touches settings, and on Windows deleting a directory
    // with an open handle in it fails outright (errno 32) rather than being
    // tidied up later as it is on Linux.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // A leftover temp directory is not a failing test. It is in the OS
      // scratch space and the next boot clears it.
    }
  });

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Long enough for the 400 ms autosave debounce to fire and for anything it
    // posts in turn to finish. Putting the caret on the page is what arms that
    // timer, so every test in this file leaves one running.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> open(WidgetTester tester) async {
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
      home: DayScreen(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      ),
    ));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Unconditionally, including after a failure. A DayScreen left mounted
    // keeps a live database stream open, and `vault.lock()` in tearDownAll
    // then waits for it forever — one failing expectation turning into a suite
    // that never finishes. `addTearDown` runs inside the test's own zone,
    // which a bare `tearDown` does not.
    addTearDown(() => unmount(tester));
  }

  Future<void> clearToday(WidgetTester tester) async {
    await tester.runAsync(() async {
      final key = EntryRepository.dayKeyFor(DateTime.now());
      for (final e in await repo.watchDay(key).first) {
        await repo.purge(e.id);
      }
      // ── AND THE VAULT IS NOT BRAND NEW ────────────────────────────
      //
      // Every one of these tests means *an empty day in a journal somebody
      // is keeping*, not *the first minute anybody has ever spent in this
      // app*. Those are different pages now — see `EmptyDay` and
      // `first_page_test.dart` — and purging today's entries used to leave
      // the vault with no rows at all, which is the second one.
      //
      // One entry, on a day far enough away that nothing here can see it.
      if (await repo.watchIsBrandNew().first) {
        await repo.createTextOn(
          id: vault.newId(),
          dayKey: '2001-01-01',
          body: 'so this vault is not brand new',
        );
      }
    });
  }

  /// Whether anything on screen currently holds the caret.
  ///
  /// The real question is "would the keyboard come up", and this is the closest
  /// a widget test gets to it: an `EditableText` with focus is what the engine
  /// shows a keyboard for.
  bool caretIsOnThePage(WidgetTester tester) {
    for (final element in find.byType(EditableText).evaluate()) {
      final state = element as StatefulElement;
      if ((state.state as EditableTextState).widget.focusNode.hasFocus) {
        return true;
      }
    }
    return false;
  }

  testWidgets('the empty-day sheet puts the caret on the page when tapped',
      (tester) async {
    await clearToday(tester);
    await open(tester);

    expect(find.text('Anything you want to keep?'), findsOneWidget,
        reason: 'the sheet under test');
    expect(caretIsOnThePage(tester), isFalse, reason: 'nothing focused yet');

    await tester.tap(find.text('Anything you want to keep?'));
    await tester.pump();

    expect(caretIsOnThePage(tester), isTrue,
        reason: '"This box even after touching here don\'t open write tab" — '
            'a sheet drawn to look like somewhere to write must accept writing');
    await unmount(tester);
  });

  testWidgets('the pencil on the sheet does it too', (tester) async {
    await clearToday(tester);
    await open(tester);

    final pencil = find.descendant(
      of: find.byType(InkWell),
      matching: find.byIcon(Icons.edit_outlined),
    );
    expect(pencil, findsWidgets, reason: 'the icon he circled');

    await tester.tap(pencil.first);
    await tester.pump();

    expect(caretIsOnThePage(tester), isTrue,
        reason: '"This icon → wire this icon at least to write"');
    await unmount(tester);
  });

  testWidgets('the sheet on a day that is NOT today is tappable as well',
      (tester) async {
    // His screenshot reads "Nothing on this day." rather than the invitation,
    // so that is the wording under test. Exercised directly rather than by
    // swiping the day view, because what is in question is this widget's own
    // wiring — the day screen's half is proved by the two tests above, which
    // go through the whole screen.
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: EmptyDay(
          date: DateTime(2026, 8, 26),
          isToday: false,
          onTap: () => tapped++,
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Nothing on this day.'), findsOneWidget);
    // The pencil he circled is drawn whenever the sheet accepts a tap, and
    // never when it does not — an icon that says "you may write here" on a
    // sheet that will not take writing is the whole complaint.
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.tap(find.text('Nothing on this day.'));
    await tester.pump();
    expect(tapped, 1, reason: 'a past day is still a day you can add to');

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    expect(tapped, 2, reason: 'and the pencil is part of the same target');
  });

  testWidgets('a sheet that cannot take writing does not show a pencil',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: EmptyDay(date: DateTime(2026, 8, 26), isToday: false),
      ),
    ));
    await tester.pump();

    expect(find.text('Nothing on this day.'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing,
        reason: 'never invite a tap that will be ignored');
  });

  // ══ ROUND EIGHT, ISSUE 6 ══════════════════════════════════════
  //
  // *"Those still don't work! … Sometimes what happens? If the pencil is
  // working for one day — and I swipe to next day pencil stops working on that
  // day."* On the screenshot, an arrow to the pencil: **"Doesn't works
  // anymore."**
  //
  // Every test above this line passes on the build he was complaining about,
  // and they always did. They all press the pencil **once**, on a screen that
  // has just been built, and that is the one case that was never broken. The
  // two below are the ones he was actually reporting.

  testWidgets('the pencil works the SECOND time, after the keyboard is closed',
      (tester) async {
    await clearToday(tester);
    await open(tester);

    final pencil = find.descendant(
      of: find.byType(InkWell),
      matching: find.byIcon(Icons.edit_outlined),
    );

    await tester.tap(pencil.first);
    await tester.pump();
    expect(caretIsOnThePage(tester), isTrue);
    expect(tester.testTextInput.isVisible, isTrue, reason: 'first tap');

    // The Android Back button closes the keyboard **without moving focus**.
    // `TestTextInput.hide` is that exact situation: the keyboard goes away,
    // the field keeps the caret. This is what put the app into the state he
    // describes, and it is why it looked intermittent — it depends on how you
    // got rid of the keyboard last time, which nobody thinks about.
    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(caretIsOnThePage(tester), isTrue,
        reason: 'focus never left — that is the whole trap');

    await tester.tap(pencil.first);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue,
        reason: '"Doesn\'t works anymore" — `if (hasFocus) return` swallowed '
            'this tap and every one after it, for as long as the caret stayed '
            'where it already was');
    await unmount(tester);
  });

  testWidgets('the pencil still works after swiping to another day',
      (tester) async {
    await clearToday(tester);
    await open(tester);

    Finder pencil() => find.descendant(
          of: find.byType(InkWell),
          matching: find.byIcon(Icons.edit_outlined),
        );

    // His sentence, in order. Write on today — the pencil works, as it always
    // has on a freshly built screen.
    await tester.tap(pencil().first);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    // Put the keyboard away with the Back button, which is how anybody gets
    // rid of it, and which leaves the caret exactly where it was.
    tester.testTextInput.hide();

    // Swipe to another day. Backwards, to yesterday, because tomorrow is not a
    // day you can write on and yesterday certainly has nothing on it.
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();

    // ── Waited for, not slept for ──────────────────────────────
    //
    // This was a flat 300 ms, which was enough while the database ran on the
    // same isolate as the widgets and stopped being enough the moment it moved
    // to a worker — the day's first rows now arrive over a port. The test
    // failed on a change that made the app *faster*, which is the least useful
    // way for a test to fail.
    //
    // So it waits for the thing it is waiting for. Bounded, so a genuine
    // regression is still a failure rather than a hang.
    await _until(tester, find.text('Nothing on this day.'));

    expect(find.text('Nothing on this day.'), findsOneWidget,
        reason: 'we are on a different day now');
    expect(pencil(), findsWidgets,
        reason: 'the sheet still offers to be written on');

    // "… and I swipe to next day pencil stops working on that day."
    await tester.tap(pencil().first);
    // Two pumps, deliberately. The composer is rebuilt into the new page's
    // list, so on the frame the day changes this node can be detached from the
    // focus tree — and `requestFocus` on a detached node returns without doing
    // anything at all. The fix waits a frame and asks again; a test that only
    // pumped once could pass for the wrong reason.
    await tester.pump();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue,
        reason: 'the caret came across the swipe with the composer, so the '
            'old guard saw "already focused" and did nothing — on the new day '
            'the pencil was dead before it was ever pressed');
    expect(caretIsOnThePage(tester), isTrue);
    await unmount(tester);
  });

  testWidgets('the blank page below the sheet is a writing target as well',
      (tester) async {
    await clearToday(tester);
    await open(tester);

    // Well below the sheet and the composer, in the empty part of the day.
    await tester.tapAt(const Offset(180, 600));
    await tester.pump();

    expect(caretIsOnThePage(tester), isTrue,
        reason: 'tapping the page is how writing starts');
    await unmount(tester);
  });

  // ══ ROUND NINE, ISSUE 4 ═══════════════════════════════════════════════════
  //
  // *"STATIC BOXES — OPENS KEYBOARD BUT WHEN I WRITE THEY DON'T WRITE — IT
  // FEELS LIKE A WAY TO OPEN KEYBOARD! IT WRITES ONLY ON TODAY! AND IN OTHER
  // PAGES IT DOESN'T WRITE JUST OPENS THE KEYBOARD!"*
  //
  // Every test above this line is either on today, or on an `EmptyDay` widget
  // held in isolation with a counter wired to its `onTap`. Neither is what he
  // described, and neither could have seen this.
  //
  // The cause was one `await` in `_onPageChanged`: the day's words were
  // flushed to the database *before* `_page` and `_date` moved. The `PageView`
  // has already moved by then, so for the length of that write the screen
  // showed one day and the state believed another — the visible page had no
  // composer, its static box was inert, and the composer that still held the
  // caret was filing keystrokes under the day he had just left.
  //
  // **The test is synchronous on purpose.** Waiting for the write and then
  // checking the row would pass on the old code too, because the state does
  // catch up — after the write, which on a laptop is the same frame. What was
  // broken is the window in between, so what is asserted is the window: one
  // pump after the day changes, everything on screen already agrees about
  // which day it is.
  group('ISSUE 4 — the page and the composer move together', () {
    testWidgets('the day on screen is the day the words will go to',
        (tester) async {
      await clearToday(tester);
      await open(tester);

      // Something in the composer, so the flush this used to wait for has real
      // work to do. With an empty composer there was nothing to await and the
      // race never opened — which is why this only ever happened to somebody
      // who was actually writing.
      await tester.tap(find.text('Anything you want to keep?'));
      await tester.pump();
      await tester.enterText(
          find.byType(EditableText).first, 'something on today');
      await tester.pump();

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      String dayLabel(DateTime d) =>
          '${d.day} ${const [
            'January', 'February', 'March', 'April', 'May', 'June', 'July',
            'August', 'September', 'October', 'November', 'December'
          ][d.month - 1]}';

      expect(find.text(dayLabel(today)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      // ── Why this pumps but never calls `runAsync` ────────────────────────
      //
      // `pump` advances the test's own clock and drains microtasks. It does
      // **not** give a background isolate any real time, and since 25 August
      // the database lives on one — so a write started here cannot finish
      // inside this loop, however many frames it runs for.
      //
      // That is precisely the discriminator. On the old code the page change
      // was behind `await _flush()`, so `_page` and `_date` could not move
      // until that write completed, and under pumps alone they would never
      // move at all — the header would sit on today for ever. On the fixed
      // code the move is synchronous and the write follows it, so the header
      // is yesterday as soon as the pager's animation has landed.
      //
      // Long enough for that animation and nothing else.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text(dayLabel(yesterday)), findsOneWidget,
          reason: 'the header still showed today while the page showed '
              'yesterday — so anything typed went to today');
      expect(find.text(dayLabel(today)), findsNothing);

      // And the invitation stops claiming to be about today, which was the
      // small lie that made this visible in the first place.
      expect(find.text('Write about today…'), findsNothing);

      await unmount(tester);
    });

    testWidgets('what was typed on the old day still lands on the old day',
        (tester) async {
      // The other half. Moving first must not lose the words being left
      // behind, and must not file them under the day being arrived at.
      await clearToday(tester);
      await open(tester);

      const onToday = 'the sentence I was in the middle of';
      await tester.tap(find.text('Anything you want to keep?'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, onToday);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();

      const onYesterday = 'and one for the day before';
      final sheet = find.text('Nothing on this day.');
      await _until(tester, sheet);
      await tester.tap(sheet);
      await tester.pump();
      await tester.enterText(find.byType(EditableText).first, onYesterday);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();

      // Unmounted before reading, so the screen's own live query is not still
      // holding the database while a one-shot read waits behind it.
      await unmount(tester);

      late List<Entry> rows;
      await tester.runAsync(() async => rows = await repo.allForExport());
      String? dayOf(String body) => rows
          .where((e) => e.body == body)
          .map((e) => e.dayKey)
          .firstOrNull;

      expect(dayOf(onToday), EntryRepository.dayKeyFor(DateTime.now()),
          reason: 'the words being left behind followed the page');
      expect(
          dayOf(onYesterday),
          EntryRepository.dayKeyFor(
              DateTime.now().subtract(const Duration(days: 1))),
          reason: '"it writes only on TODAY"');
    });
  });
}
