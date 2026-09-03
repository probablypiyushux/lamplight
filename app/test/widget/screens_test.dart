import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/database.dart' show debugUseInProcessDatabase;
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/components.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/day/day_screen.dart';
import 'package:lamplight/features/lock/lock_screen.dart';
import 'package:lamplight/features/settings/appearance_screen.dart';
import 'package:lamplight/features/settings/security_screen.dart';
import 'package:lamplight/features/settings/settings_screen.dart';
import 'package:lamplight/features/trash/trash_screen.dart';
import 'package:sodium/sodium_sumo.dart';

/// The screens, as a person meets them.
///
/// `08-design/ACCESSIBILITY.md` asks for widget tests asserting that semantic
/// labels exist, and `STATE.md` recorded honestly that there were none and that
/// text scaling to 200% had never been checked on any screen. Both gaps are
/// closed here.
///
/// **The 200% tests are the ones to keep.** Scaling is where most apps visibly
/// break, it takes five minutes a screen to check, and nobody ever does it —
/// which is exactly the argument for it being a test rather than a habit. A
/// fixed-height row or a `Row` of unwrapped text passes at 100% and clips
/// someone's settings label in half at 200%, and the person it happens to is
/// the person who most needed the larger text.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late SilentBackup silentBackup;
  late AppSettings settings;

  setUpAll(() async {
    // -- THIS FILE READS THE VAULT THROUGH WIDGETS, SO THE DATABASE STAYS
    //    IN THIS ISOLATE ------------------------------------------------
    //
    // The app runs the database on a worker isolate, which is the whole point
    // of that change. `testWidgets` cannot observe one: its body runs in a
    // fake-async zone, and a worker delivers stream events on the real event
    // loop. Measured rather than assumed -- a two-second real-time window
    // inside `runAsync` still produced nothing, so this is structural and not
    // a matter of waiting longer.
    //
    // Only this file needs it, because only this file asserts on data that
    // arrived through a watched query. Everything else in the suite runs
    // against the real worker, and `background_database_test.dart` covers the
    // worker path directly.
    debugUseInProcessDatabase = true;

    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_widget');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      // Never. A live idle countdown would sit in the fake-async zone as a
      // pending timer and fail every test that touched the vault.
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    // The one expensive call in this file — real Argon2id at the real
    // parameters. Done once, shared by every test below.
    await vault.create(passcode: 'a passphrase');
  });

  // Fresh preferences for every test.
  //
  // Sharing one object across the file made the suite order-dependent: a test
  // that switched the theme to light left the next one asserting on "Dark" and
  // failing for a reason that had nothing to do with what it was testing. A
  // test that only passes when its neighbours run in a particular order is
  // worse than no test, because it fails on the day someone adds one.
  setUp(() {
    settings = AppSettings.inMemory();
    silentBackup = SilentBackup(vault: vault, settings: settings);
  });

  tearDownAll(() async {
    debugUseInProcessDatabase = false;
    await vault.lock();
    // Best effort, and the try is not laziness.
    //
    // Windows refuses to delete a file another handle still has open, and
    // SQLite closes its own asynchronously — so a temp directory that held an
    // open database sometimes survives a moment longer than the test does.
    // Failing the suite over a leftover folder in %TEMP% would be reporting a
    // problem the user does not have, and it would hide the real failures
    // underneath it.
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Lets real asynchronous work finish, then rebuilds.
  ///
  /// A widget test runs on a fake clock, so anything that touches the real
  /// filesystem or spends real CPU — reading the keyring, running Argon2id —
  /// makes no progress while the test pumps. `runAsync` steps outside the fake
  /// zone for a moment so it can. Polling rather than sleeping once, because
  /// Argon2id at 256 MiB takes as long as the machine takes.
  Future<void> settleRealAsync(
    WidgetTester tester, {
    required Finder Function() until,
    Duration limit = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(limit);
    while (DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (until().evaluate().isNotEmpty) return;
    }
  }

  /// Pumps a screen on a phone-shaped window at a chosen text size.
  ///
  /// [settle] is false for anything driven by a database stream. `pumpAndSettle`
  /// waits for the frame queue to go quiet, and a screen with a live query
  /// behind it plus a blinking text cursor never does — it sits there until its
  /// own ten-minute timeout and takes the whole suite with it. Those screens get
  /// a bounded pump and a real-async window instead, which is both faster and
  /// honest about what it is waiting for.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
    ThemeMode mode = ThemeMode.dark,
    bool settle = true,
  }) async {
    // A small phone, on purpose: 360x800 is where things are tight, and a test
    // that only ever runs on a tablet-sized default surface proves nothing
    // about the device this app is for.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.light),
      darkTheme: lamplightTheme(LamplightColors.dark),
      themeMode: mode,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    ));
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    // One frame, a real-time window for the query to come back, then a frame
    // to draw what it returned.
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Runs database work from inside a widget test.
  ///
  /// **Every `await` on the vault in this file has to go through here.**
  /// `testWidgets` runs its body in a fake-async zone where real file I/O never
  /// completes, so `await repo.watchDay(key).first` in a test body does not
  /// return slowly — it never returns at all, and the whole suite sits there
  /// until its ten-minute timeout with no failure to point at. `runAsync` steps
  /// out of that zone for the duration of the callback.
  ///
  /// It cost most of an afternoon to find, so it is written down rather than
  /// remembered.
  Future<T> db<T>(WidgetTester tester, Future<T> Function() work) async {
    final result = await tester.runAsync(work);
    return result as T;
  }

  /// Takes a stream-backed screen down, inside the test body.
  ///
  /// **Every test that pumps with `settle: false` has to end with this.** A live
  /// drift query posts a zero-duration timer when its subscription is cancelled.
  /// Left to the framework's own teardown, that cancellation happens *after* the
  /// point where pending timers are checked, and the test fails with "pending
  /// timers" and a hundred lines of unmount stack that say nothing about what it
  /// was testing. `addTearDown` does not help — it runs after the check too.
  /// Unmounting here means the cancellation happens while there are still frames
  /// to pump.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Twice, with time on the clock: the first pump lets the timer fire, the
    // second lets anything it posted in turn finish.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    // And past `announce`'s dismissal backstop, which outlives all of the
    // above by design -- see `design/announce.dart`. A pending `Timer` is a
    // test failure in Flutter, so a screen that said anything at all would
    // otherwise fail here rather than where the fault was.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Advances a stream-backed screen after an interaction, without settling.
  Future<void> nudge(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // ═════════════════════════════════════════════════════════════════════════
  group('the lock screen', () {
    testWidgets('says the app exists and nothing else', (tester) async {
      await pump(tester, LockScreen(vault: vault, settings: settings, silentBackup: silentBackup));

      expect(find.text('Lamplight'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('I forgot my passcode'), findsOneWidget);

      // UX-FLOWS flow 7. Nothing about what is inside — no counts, no preview,
      // no dates. If any of these ever appear here, it is a leak to whoever is
      // holding someone else's phone.
      expect(find.textContaining('entries'), findsNothing);
      expect(find.textContaining('days'), findsNothing);
    });

    testWidgets('the mark is not announced as an unlabelled image',
        (tester) async {
      // It is decoration; the word "Lamplight" is directly underneath it. A
      // screen reader saying "image" here would be noise, not information.
      final handle = tester.ensureSemantics();
      await pump(tester, LockScreen(vault: vault, settings: settings, silentBackup: silentBackup));
      expect(find.bySemanticsLabel(RegExp(r'image', caseSensitive: false)),
          findsNothing);
      handle.dispose();
    });

    testWidgets('a wrong passcode is refused in plain language',
        (tester) async {
      await pump(tester, LockScreen(vault: vault, settings: settings, silentBackup: silentBackup));
      await tester.enterText(find.byType(TextField).first, 'wrong');
      // ── This pump is the test, not tidiness ────────────────────────────
      //
      // `enterText` does not build a frame. The Unlock button is wrapped in a
      // `ValueListenableBuilder` on "is there anything in the field", which was
      // added so the button could explain why it is off — so between typing and
      // the next frame the button is still disabled, and a tap on it lands on a
      // real widget and does nothing at all. No hit-test warning, no error, no
      // message: the test simply waited twenty seconds for a refusal that was
      // never asked for.
      //
      // It is worth knowing that this failure looked exactly like a wording
      // change and was not one. The message is the same as it always was.
      await tester.pump();
      await tester.tap(find.text('Unlock'));

      // `pumpAndSettle` would return immediately here and the test would fail
      // looking for a message that had not arrived yet. Unlocking reads the
      // keyring off the real filesystem and runs real Argon2id, and neither of
      // those advances when a test pumps a fake clock. `runAsync` steps outside
      // the fake zone so the real work can happen; the loop is because how long
      // Argon2id takes at 256 MiB depends on the machine, and a single fixed
      // sleep would either be flaky on a slow one or waste seconds on a fast one.
      await settleRealAsync(tester, until: () => find.byType(LampError));

      expect(find.text('That passcode does not open this vault.'),
          findsOneWidget);
      // Never a jargon string. ACCESSIBILITY.md, cognitive section.
      expect(find.textContaining('invalid credentials'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('survives 200% text without clipping', (tester) async {
      await pump(tester, LockScreen(vault: vault, settings: settings, silentBackup: silentBackup), textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(find.text('Unlock'), findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('settings', () {
    // ── Where these rows went ──────────────────────────────────────────
    //
    // The settings screen used to be a flat list with Theme and Auto-lock on
    // it. It is now three doors — Appearance, Locking and security, Folders —
    // and the rows live behind them. These tests were asserting against the old
    // shape and had been failing since the day it changed.
    //
    // They are rewritten rather than deleted, because the guarantee they were
    // protecting is still a guarantee: **a row says what it is currently set
    // to, not just what it is called.** A settings screen you have to open a
    // row to read is a settings screen you cannot scan.
    testWidgets('a row says what it is set to, not just what it is called',
        (tester) async {
      settings.themeMode = ThemeMode.dark;
      settings.autoLock = const Duration(minutes: 1);
      await pump(tester, SettingsScreen(vault: vault, settings: settings, silentBackup: silentBackup));

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Locking and security'), findsOneWidget);
      // The state of the lock, on the row, without opening it.
      expect(find.textContaining('1 minute'), findsOneWidget);
    });

    testWidgets('a row reads as one sentence, not two loose labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      settings.autoLock = const Duration(minutes: 1);
      await pump(tester, SecurityScreen(vault: vault, settings: settings));

      // "Lock after, After 1 minute" — a screen-reader user gets the setting
      // AND its value in one utterance, the way a sighted user gets them in one
      // glance, rather than two loose labels to stitch together.
      //
      // Matched as a pattern rather than as the whole label, because Flutter
      // may merge this node with its neighbours and the assertion is about the
      // words being said together, not about what else is in the utterance.
      expect(find.bySemanticsLabel(RegExp(r'Lock after, .+minute')),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('choosing a theme changes it, in place and at once',
        (tester) async {
      // The modal this used to open is gone. Appearance was rebuilt around a
      // live specimen with the controls inline underneath it, because a modal
      // covers the thing you are changing — so the assertion is no longer
      // "the sheet closed", it is "the choice took effect where you made it".
      settings.themeMode = ThemeMode.dark;
      await pump(tester, AppearanceScreen(settings: settings));

      expect(find.text('Theme'.toUpperCase()), findsOneWidget);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.light);
      // Still on the same screen, with the choice visible on it.
      expect(find.text('Light'), findsOneWidget);
    });

    test('a vault that had the old serif switch on still gets the serif', () {
      // This replaces a test that tapped a switch labelled "Set my writing in
      // a serif". The switch is gone: one bit where there should have been a
      // choice, now fourteen named typefaces on the Appearance screen.
      //
      // What survives the rewrite is the part that could hurt somebody. A
      // person who chose the serif months ago must not open the app after an
      // update to find their journal reset to the platform default, so
      // `AppSettings` reads the old key when there is no new one — and that
      // migration, not the widget, is what is worth a test now.
      expect(
        AppSettings.inMemory({'serifBody': true}).writingFace,
        WritingFace.serif,
      );
      expect(
        AppSettings.inMemory({'serifBody': false}).writingFace,
        WritingFace.system,
      );
      // An explicit choice always wins over the legacy key.
      expect(
        AppSettings.inMemory({'serifBody': true, 'writingFace': WritingFace.system.id})
            .writingFace,
        WritingFace.system,
      );
      // And a brand new vault gets the serif, because this is a journal.
      expect(AppSettings.inMemory().writingFace, WritingFace.serif);
    });

    testWidgets('survives 200% text without clipping', (tester) async {
      settings.autoLock = const Duration(minutes: 1);
      await pump(tester, SettingsScreen(vault: vault, settings: settings, silentBackup: silentBackup),
          textScale: 2.0);
      expect(tester.takeException(), isNull);
      // The rows grow rather than clipping, so what is on screen is still
      // legible. Only what is on screen: at double size the list is taller than
      // the phone and the rows further down have not been built yet, which is
      // the list doing its job rather than anything being lost.
      expect(find.text('Appearance'), findsOneWidget);
      // Its subtitle is still under it rather than pushed off the edge — the
      // thing that was actually broken before the flex fix in LampTile.
      expect(find.text('Theme, font, colour, page'), findsOneWidget);
    });

    testWidgets('works in light mode as well as dark', (tester) async {
      // Both palettes are separately chosen rather than inverted, so both are
      // separately capable of being wrong.
      await pump(tester, SettingsScreen(vault: vault, settings: settings, silentBackup: silentBackup),
          mode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      // A group label, set in the meta style and upper-cased by LampGroup.
      //
      // The **first** one, deliberately. This used to look for "YOUR NOTES",
      // which was above the fold when the screen had two groups and is not now
      // that it has four — and a smoke test that fails because a label moved
      // is a test about layout pretending to be a test about colour. What it
      // is actually asserting is that the light palette renders a group header
      // at all.
      expect(find.text('How it looks and speaks'.toUpperCase()),
          findsOneWidget);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('the day view', () {
    late EntryRepository repo;

    setUp(() => repo = EntryRepository(vault.database));

    Future<void> clearToday(WidgetTester tester) => db(tester, () async {
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

    Future<void> seed(WidgetTester tester, String body) => db(
          tester,
          () => repo.createText(
            id: vault.newId(),
            dayKey: EntryRepository.dayKeyFor(DateTime.now()),
            body: body,
          ),
        );

    testWidgets('an empty day asks a question rather than applying pressure',
        (tester) async {
      await clearToday(tester);
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup), settle: false);

      // ETHICAL-DESIGN.md: the empty first day must not guilt anyone into
      // writing. A streak counter or "you haven't written today!" would be the
      // usual thing here, and it is the thing this app exists not to do.
      expect(find.text('Anything you want to keep?'), findsOneWidget);
      expect(find.textContaining('streak'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the date is a button that says where it goes',
        (tester) async {
      final handle = tester.ensureSemantics();
      await clearToday(tester);
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup), settle: false);

      // ANNOYANCES.md: "No way to jump to a date." The date itself is now the
      // way, and it announces that it is.
      // "…, today. Choose a different date." The wording moved on; the
      // guarantee did not, so neither does the test.
      expect(
        find.bySemanticsLabel(RegExp(r'today\. Choose a different date\.')),
        findsOneWidget,
      );
      handle.dispose();
      await unmount(tester);
    });

    testWidgets('an entry announces that it can be edited', (tester) async {
      await clearToday(tester);
      await seed(tester, 'something worth keeping');

      final handle = tester.ensureSemantics();
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup), settle: false);

      expect(find.text('something worth keeping'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Entry at \d\d:\d\d\. Tap to edit\.')),
          findsOneWidget);
      handle.dispose();
      await unmount(tester);
    });

    testWidgets('tapping an entry opens it for editing, in place',
        (tester) async {
      await clearToday(tester);
      await seed(tester, 'the original wording');
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup), settle: false);

      await tester.tap(find.text('the original wording'));
      await nudge(tester);

      // In place: Done and Delete appear next to the block, and the composer
      // steps aside so there are never two places a keystroke could go.
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Start a new block'), findsNothing);
      await unmount(tester);
    });

    testWidgets('deleting offers an undo in the same breath', (tester) async {
      await clearToday(tester);
      await seed(tester, 'delete me');
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup), settle: false);

      await tester.longPress(find.text('delete me'));
      await nudge(tester);
      await tester.tap(find.text('Delete'));
      await nudge(tester);

      // ETHICAL-DESIGN.md: destructive actions are reversible. The undo catches
      // the mis-tap you notice straight away; the trash catches the rest.
      expect(find.text('Deleted.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('survives 200% text without clipping', (tester) async {
      await clearToday(tester);
      await seed(tester, 'a sentence long enough to wrap several times at double size');
      await pump(tester, DayScreen(vault: vault, settings: settings, silentBackup: silentBackup),
          textScale: 2.0, settle: false);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  group('the trash', () {
    testWidgets('an empty trash says so instead of showing a blank screen',
        (tester) async {
      final repo = EntryRepository(vault.database);
      await db(tester, () async {
        for (final e in await repo.watchTrash().first) {
          await repo.purge(e.id);
        }
      });
      await pump(tester, TrashScreen(vault: vault), settle: false);

      expect(find.text('Nothing here.'), findsOneWidget);
      expect(find.textContaining('30 days'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a deleted entry can be put back from here', (tester) async {
      final repo = EntryRepository(vault.database);
      final id = vault.newId();
      await db(tester, () async {
        await repo.createText(
            id: id, dayKey: '2026-08-18', body: 'recoverable');
        await repo.softDelete(id);
      });

      await pump(tester, TrashScreen(vault: vault), settle: false);
      expect(find.text('recoverable'), findsOneWidget);

      await tester.tap(find.text('Put back'));
      await nudge(tester);

      final restored =
          await db(tester, () => repo.entryById(id));
      expect(restored!.deletedAt, isNull);
      await db(tester, () => repo.purge(id));
      await unmount(tester);
    });
  });
}
