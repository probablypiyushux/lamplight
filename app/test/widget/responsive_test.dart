import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/components.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/backup/backup_screen.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/capture/capture_bar.dart';
import 'package:lamplight/features/day/day_screen.dart';
import 'package:lamplight/features/lock/lock_screen.dart';
import 'package:lamplight/features/settings/appearance_screen.dart';
import 'package:lamplight/features/settings/change_passcode_screen.dart';
import 'package:lamplight/features/settings/security_screen.dart';
import 'package:lamplight/features/settings/settings_screen.dart';
import 'package:lamplight/features/trash/trash_screen.dart';
import 'package:sodium/sodium_sumo.dart';

/// Does it work on other phones?
///
/// This file exists because that question deserves an answer with evidence
/// behind it rather than "it uses flexible layouts, so probably". Every screen
/// is built at seven real window sizes — the narrowest Android phone still
/// sold, a normal phone, a large one, both orientations, and a tablet — at
/// normal and at double text size, in both palettes, and any overflow fails the
/// test.
///
/// WHAT THIS CATCHES AND WHAT IT DOES NOT
///
/// It catches layout that breaks: text clipped off an edge, a row that will not
/// fit, a fixed height that stops holding its contents. That is the class of
/// bug that makes an app unusable on someone's phone, and it is the class that
/// is invisible on the one device a developer happens to own.
///
/// It does not catch ugliness. A screen can pass every assertion here and still
/// look wrong on a tablet — too wide a measure, too much empty space — and no
/// test will ever tell you that. Those need eyes.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AppSettings settings;
  late SilentBackup silentBackup;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_responsive');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      // Never. A live idle countdown would sit in the fake-async zone as a
      // pending timer and fail every test that touched the vault.
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    settings = AppSettings.inMemory();
    silentBackup = SilentBackup(vault: vault, settings: settings);

    // One entry, so the day view is not being tested empty — an empty screen is
    // the easy case and it is not the one that breaks.
    final repo = EntryRepository(vault.database);
    await repo.createText(
      id: vault.newId(),
      dayKey: EntryRepository.dayKeyFor(DateTime.now()),
      body: 'A sentence with enough words in it to wrap onto several lines '
          'when the text size is doubled on a narrow phone.',
    );
  });

  tearDownAll(() async {
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

  /// Logical sizes, and the devices they stand for.
  const windows = <String, Size>{
    // The floor. Android's smallest widely-supported width; if anything is
    // going to overflow, it does so here first.
    'small phone 320x640': Size(320, 640),
    // A Pixel-class phone, and the size most of these screens were drawn at.
    'phone 360x800': Size(360, 800),
    // A large phone — the Vivo V2318 this is built for is about this.
    'large phone 412x915': Size(412, 915),
    // Landscape. Short and wide is a different problem from tall and narrow,
    // and it is the one people forget.
    'phone landscape 800x360': Size(800, 360),
    'small landscape 640x320': Size(640, 320),
    // A tablet, and a big one. Nothing here is designed for a tablet, but
    // nothing should break on one either.
    'tablet 768x1024': Size(768, 1024),
    'tablet landscape 1024x768': Size(1024, 768),
    // ── ROUND FIFTEEN, ISSUE 12 — split screen and floating windows ────────
    //
    // > *"When the window is resized – when using split screen or floating
    // > screen – I want you to set that the app is responsive then too!"*
    //
    // He has been running Lamplight in MIUI's freeform mode; the system's own
    // `readFreeformTimestamps` on his tablet lists this package. These are not
    // hypothetical sizes.
    //
    // **`android:screenOrientation="portrait"` does not apply here.** Android
    // ignores an activity's orientation request in multi-window mode, so the
    // app genuinely can be short and wide however firmly the manifest asks
    // otherwise — one more reason a layout must not assume portrait.
    //
    // The three below are: half of his tablet's height, half of its width, and
    // MIUI's floating window, which is smaller than any phone Android still
    // supports.
    'split top/bottom 686x571': Size(686, 571),
    'split left/right 342x1142': Size(342, 1142),
    'floating window 300x520': Size(300, 520),
  };

  /// Lets a stream-backed screen finish arriving, without guessing how long.
  ///
  /// ── WHY THIS IS A POLL AND NOT A `Future.delayed(250ms)` ─────────────────
  ///
  /// It was three copies of a fixed 250 ms wait, and on 28 August one of them
  /// started failing about one run in three. Nothing was wrong with the screen:
  /// the day view had grown a second and third watched query — folder
  /// memberships, and "has anything ever been written here" — so there were
  /// more round trips to the worker isolate to get through before the first
  /// entry could be drawn, and 250 ms of real time stopped being reliably
  /// enough on a loaded machine.
  ///
  /// **A fixed sleep in a test is a race that has not failed yet.** Waiting for
  /// the condition instead is both faster in the common case and correct in the
  /// slow one, and it does not have to be re-tuned every time the screen learns
  /// to ask another question.
  Future<void> settleStream(
    WidgetTester tester, {
    Finder? until,
    Duration limit = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(limit);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      if (until == null || until.evaluate().isNotEmpty) return;
    }
  }

  Future<void> buildAt(
    WidgetTester tester,
    Widget child,
    Size size, {
    required double textScale,
    required ThemeMode mode,
    required bool stream,
  }) async {
    tester.view.physicalSize = size * 3.0;
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

    if (stream) {
      await settleStream(tester);
    } else {
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);

    // Down again inside the body — a live query posts a timer when its
    // subscription is cancelled, and the framework checks for pending timers
    // before its own teardown runs.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Screens that do not read from the database, and can settle normally.
  final still = <String, Widget Function()>{
    'lock screen': () => LockScreen(vault: vault, settings: settings, silentBackup: silentBackup),
    'settings': () => SettingsScreen(vault: vault, settings: settings, silentBackup: silentBackup),
    'change passcode': () =>
        ChangePasscodeScreen(vault: vault, settings: settings),
    // Added 22 Aug, after it turned out to overflow on the right at a normal
    // phone width in three separate rows. It had never been built at any size
    // by anything — the suite covered the settings screen and stopped at the
    // door. A screen that is not in this list is a screen nobody has measured.
    'appearance': () => AppearanceScreen(settings: settings),
    'locking and security': () => SecurityScreen(vault: vault, settings: settings),
    'backup': () => BackupScreen(vault: vault, settings: settings),
  };

  // Screens with a live query behind them.
  final streaming = <String, Widget Function()>{
    'day view': () => DayScreen(vault: vault, settings: settings, silentBackup: silentBackup),
    'trash': () => TrashScreen(vault: vault),
  };

  windows.forEach((label, size) {
    group('on a $label', () {
      still.forEach((name, build) {
        testWidgets('$name fits', (tester) async {
          await buildAt(tester, build(), size,
              textScale: 1.0, mode: ThemeMode.dark, stream: false);
        });

        testWidgets('$name fits at 200% text', (tester) async {
          await buildAt(tester, build(), size,
              textScale: 2.0, mode: ThemeMode.dark, stream: false);
        });

        testWidgets('$name fits in light mode', (tester) async {
          // Light is a separately chosen palette rather than an inversion, so
          // it is separately capable of being wrong.
          await buildAt(tester, build(), size,
              textScale: 1.0, mode: ThemeMode.light, stream: false);
        });
      });

      streaming.forEach((name, build) {
        testWidgets('$name fits', (tester) async {
          await buildAt(tester, build(), size,
              textScale: 1.0, mode: ThemeMode.dark, stream: true);
        });

        testWidgets('$name fits at 200% text', (tester) async {
          await buildAt(tester, build(), size,
              textScale: 2.0, mode: ThemeMode.dark, stream: true);
        });
      });
    });
  });

  group('the things that should hold at any width', () {
    testWidgets('an entry fills the width, gutter to gutter', (tester) async {
      // **ROUND FIVE, ISSUE 6b. This test used to assert the opposite**, and it
      // is inverted rather than deleted so the reversal is visible to whoever
      // reads it next.
      //
      // It was called "reading measure stays capped on a tablet" and it cited
      // DESIGN-SYSTEM.md's 65–70 character measure, which is real and which the
      // cap served. Piyush overruled it after seeing what it does to a
      // landscape window: a third of blank, a third of content, a third of
      // blank. *"If you make everything full, everything blends consistently."*
      //
      // So the assertion is now that the entry reaches the same rule as
      // everything else on the screen. See the long note in `tokens.dart`.
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: DayScreen(vault: vault, settings: settings, silentBackup: silentBackup),
      ));
      final entry = find.textContaining('A sentence with enough words');
      // Waits for the entry rather than for a number of milliseconds — see
      // `settleStream`. This is the test that started flaking when the day
      // grew two more watched queries.
      await settleStream(tester, until: entry);

      expect(entry, findsOneWidget);
      expect(tester.getSize(entry).width, greaterThan(Layout.maxContent),
          reason: 'an entry should reach the same rule as everything else, '
              'not stop short of it at the old 560 measure');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    // ═══════════════════════════════════════════════════════════════════
    //  ISSUE 1 and the tablet instruction, as assertions rather than as care
    //
    //  "Nothing lines up on the right-hand side", with a red line drawn down
    //  five screenshots. The cause was that there was no grid: every component
    //  chose its own inset and they came out at 44, 40, 32, 24 and 20 points
    //  from the edge. Fixing the five screens he photographed would have left
    //  the sixth wrong, so what follows measures the *rule* instead.
    // ═══════════════════════════════════════════════════════════════════
    testWidgets('every settings row ends on the same rule, whatever its value',
        (tester) async {
      // The defect in one line: a short value shrink-wrapped inside a
      // `Flexible` and handed its unused share back as slack, and a Row puts
      // slack at the end — so the chevron after `21:00` sat eighty points left
      // of the chevron after a long value. Three rows, three different right
      // edges, on one screen.
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: const Scaffold(
          body: LampGroup(
            children: [
              LampTile(title: 'Short', value: '21:00', onTap: _noop),
              LampTile(
                  title: 'Long', value: 'Skip for 60 seconds', onTap: _noop),
              LampTile(title: 'None at all', onTap: _noop),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final edges = tester
          .widgetList<Icon>(find.byIcon(Icons.chevron_right))
          .toList()
          .asMap()
          .keys
          .map((i) => tester
              .getBottomRight(find.byIcon(Icons.chevron_right).at(i))
              .dx)
          .toSet();

      expect(edges, hasLength(1),
          reason: 'three rows ended at ${edges.length} different places: '
              '$edges');
    });

    testWidgets('a group label, its rows and its footer share one rule',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: const Scaffold(
          body: LampGroup(
            label: 'Your notes',
            footer: 'One quiet sentence underneath.',
            children: [LampTile(title: 'A row', onTap: _noop)],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      double leftOf(Finder f) => tester.getTopLeft(f).dx;
      final label = leftOf(find.text('YOUR NOTES'));
      final row = leftOf(find.text('A row'));
      final footer = leftOf(find.text('One quiet sentence underneath.'));

      expect(row, label,
          reason: 'a section heading should sit over the first word beneath '
              'it, not eight points to its left');
      expect(footer, label);
      expect(label, Layout.contentGutter);
    });

    testWidgets('a row fills whatever it is given, at every width',
        (tester) async {
      // **ROUND FIVE, ISSUE 6. This test used to assert the opposite** — it was
      // called "a tablet gets the phone's proportions, not a stretched phone"
      // and it proved that past `Layout.maxContent` a row stopped growing.
      //
      // That mechanism is gone. He photographed eight screens on one device,
      // marked four "Full" and four "Has space", and asked for one answer:
      // *"if you make everything full, everything has a consistent space on the
      // side."* A row that stops at 560 on a 1024-wide window is the "Has
      // space" half of the thing he reported.
      //
      // The 22 August instruction — one layout, not a separate tablet build —
      // is still obeyed and is still worth testing, which is why the shape of
      // this test survives: one rule, checked at three widths.
      Future<double> rowWidthAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: lamplightTheme(LamplightColors.dark),
          home: const Scaffold(
            body: LampGroup(
              children: [LampTile(title: 'A row', value: '21:00', onTap: _noop)],
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(LampTile)).width;
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));
      final phone = await rowWidthAt(const Size(412, 915));
      // Piyush's actual tablet: a Redmi Pad reports 685.7 x 1142.9 logical.
      final tablet = await rowWidthAt(const Size(686, 1143));
      final desktopish = await rowWidthAt(const Size(1024, 768));

      // One rule at every width: the row is the window less a gutter each side.
      expect(phone, 412 - Layout.gutter * 2);
      expect(tablet, 686 - Layout.gutter * 2,
          reason: 'the row should track the glass, not stop at 560');
      expect(desktopish, 1024 - Layout.gutter * 2,
          reason: 'and keep tracking it, however wide it gets');
    });

    testWidgets('the day fills the window, with no blank thirds',
        (tester) async {
      // **ROUND FIVE, ISSUE 6b — the drawing on page 9, as an assertion.**
      //
      // He drew the landscape day as three boxes: "Blank 1/3", "Content 1/3,
      // very small", "Blank 1/3", with "very much negative space" written down
      // both sides. This is that, measured on the screen he actually looks at.
      //
      // The test it replaces asserted the blank thirds were correct — it was
      // called "the day itself is the same width on a tablet as on a phone" and
      // it checked the column stopped at `Layout.maxColumn` and centred. That
      // was a faithful test of a decision he has since reversed.
      Future<Rect> dayColumnAt(Size size) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: lamplightTheme(LamplightColors.dark),
          home: DayScreen(
              vault: vault, settings: settings, silentBackup: silentBackup),
        ));
        await settleStream(tester, until: find.byType(CaptureBar));
        // The capture bar spans the day's column and nothing else, so its box
        // is the column's box.
        final rect = tester.getRect(find.byType(CaptureBar));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        return rect;
      }

      addTearDown(() => tester.binding.setSurfaceSize(null));

      final phone = await dayColumnAt(const Size(412, 915));
      // His actual tablet: a Redmi Pad reports 685.7 x 1142.9 logical.
      final tablet = await dayColumnAt(const Size(686, 1143));
      // The same tablet on its side, which is where he drew the thirds.
      final landscape = await dayColumnAt(const Size(1143, 686));

      expect(phone.width, 412, reason: 'a phone was never capped');
      expect(tablet.width, 686, reason: 'nor is the tablet now');
      expect(landscape.width, 1143,
          reason: 'and landscape fills the window — this is the blank thirds');

      // Flush to the left edge, not floating in the middle of the glass. If
      // this ever goes non-zero again, the centred column is back.
      expect(landscape.left, 0);
    });

    testWidgets('one number decides the measure, in every place that caps it',
        (tester) async {
      // Four screens had `maxWidth: 560` written out as a literal and one had
      // 420. Literals drift: somebody widens one of them for a reason that is
      // good on that screen, and the app quietly stops being one object.
      //
      // There is nothing clever to assert here — the point is that the numbers
      // are named — so this asserts the relationship between them, which is the
      // part that carries meaning and the part a future edit could break.
      expect(Layout.maxColumn, Layout.maxContent + Layout.gutter * 2);
      expect(Layout.maxForm, lessThan(Layout.maxContent),
          reason: 'a form should be narrower than a page of prose');
      // ISSUE 6: one margin, at every width, forever. This is the whole of the
      // change and it is one line to check.
      for (final w in [320.0, 412.0, 686.0, 1024.0, 1143.0, 2000.0]) {
        expect(Layout.marginFor(w), Layout.gutter,
            reason: 'the side margin must not vary with the glass');
      }
      expect(Layout.contentGutter, Layout.gutter + Layout.rowInset);
      // The optical correction: an icon button is pulled out by half the
      // difference between its 48-point target and its 24-point glyph, so the
      // glyph lands on the gutter.
      expect(Layout.iconInset, Layout.gutter - 12);
    });

    testWidgets('touch targets stay at the floor on the narrowest phone',
        (tester) async {
      // ACCESSIBILITY.md: 48dp for anything tappable. The calendar is where
      // this is tightest — seven cells across a 320dp screen — so the screen
      // margin gives way before the target size does.
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: SettingsScreen(vault: vault, settings: settings, silentBackup: silentBackup),
      ));
      await tester.pumpAndSettle();

      // The rows these three names belonged to moved behind Appearance and
      // Locking and security when the settings screen was rebuilt, so the test
      // was measuring rows that no longer exist — and `scrollUntilVisible`
      // throws `Bad state: No element` when it runs out of list, which is why
      // this reported as a framework error rather than as a failed assertion.
      //
      // **That is the finding worth keeping.** For a fortnight the app's only
      // mechanical proof of `ACCESSIBILITY.md`'s 48dp floor had not measured
      // anything at all, and nothing said so, because a suite that is always
      // red cannot report an eleventh failure.
      for (final label in ['Appearance', 'Locking and security', 'Trash']) {
        // Scroll it into view first. A ListView does not build what it cannot
        // show, so a row below the fold is not "too small" — it does not exist
        // yet, and measuring it throws a StateError that says nothing about
        // touch targets. This test failed exactly that way the moment a row was
        // added above these ones, which is a trap worth disarming rather than
        // rediscovering.
        await tester.scrollUntilVisible(
          find.text(label),
          80,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(row, findsWidgets, reason: '"$label" is not on the screen');
        expect(tester.getSize(row.first).height,
            greaterThanOrEqualTo(kMinTouchTarget),
            reason: '"$label" is smaller than the 48dp touch floor');
      }
    });
  });
}

/// A tap handler that does nothing, so a row under test is a *tappable* row —
/// `LampTile` only draws its chevron when there is somewhere to go.
void _noop() {}
