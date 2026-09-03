import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/day/day_screen.dart';
import 'package:lamplight/features/settings/settings_screen.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND FIFTEEN, ISSUE 12 — the window changing size under the app.**
///
/// > *"When the window is resized – when using split screen or floating screen
/// > – I want you to set that the app is responsive then too!"*
///
/// `responsive_test.dart` builds every screen fresh at a dozen sizes, split
/// screen and MIUI's floating window among them, and they all pass. This file
/// asks the different question, which is the one he actually asked: what
/// happens when a window that is **already running** changes shape.
///
/// It is a genuinely different failure mode. A fresh build lays out once
/// against final constraints. A resize hands new constraints to a tree that is
/// already alive — with a `PageController` positioned on a page, a database
/// stream mid-flight, a star map painted for the old window and a text field
/// holding a caret. Anything cached against the old width shows up here and
/// nowhere else.
///
/// ── AND THE MANIFEST NO LONGER DECIDES THIS ──────────────────────────────
///
/// Worth knowing, because `orientation.dart` reads as though it settles the
/// matter and on his own tablet it does not any more. Two rules apply:
///
///   * In **multi-window mode**, Android ignores an activity's
///     `screenOrientation` outright. Split screen can be short and wide
///     whatever the manifest asks.
///   * Since **Android 16**, for an app targeting SDK 36 — which this one does
///     — the system also ignores orientation, resizability and aspect-ratio
///     restrictions on any display whose smallest width is 600dp or more. The
///     Redmi Pad is 686dp. So on the device he judges this app on, it is
///     already fully rotatable and resizable, and no manifest line will bring
///     that back.
///
/// That is not a regression to fix. It is the reason this file exists.
void main() {
  late Vault vault;
  late AppSettings settings;
  late Directory tmp;

  setUpAll(() async {
    final sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_resize');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    settings = AppSettings.inMemory();
  });

  tearDownAll(() async {
    await vault.lock();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {
      // Windows keeps a handle on a database SQLite closes asynchronously.
    }
  });

  /// The shapes a window actually passes through on his tablet.
  ///
  /// Full screen, then half the height (split top and bottom), then half the
  /// width (split left and right), then MIUI's floating window, then back.
  /// In that order and without rebuilding, because the order is the test.
  const shapes = <String, Size>{
    'full screen': Size(686, 1143),
    'split top/bottom': Size(686, 571),
    'split left/right': Size(342, 1142),
    'floating window': Size(300, 520),
    'landscape': Size(1143, 686),
    'back to full screen': Size(686, 1143),
  };

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('the day survives being resized while it is running',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(shapes['full screen']);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.dark),
      home: DayScreen(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      ),
    ));
    await settle(tester);

    for (final entry in shapes.entries) {
      await tester.binding.setSurfaceSize(entry.value);
      // Pumped by hand: PaperGround always has a frame scheduled, so
      // pumpAndSettle can never return in this app.
      await settle(tester);
      expect(tester.takeException(), isNull, reason: entry.key);
      // The day is still there and still fills the window it has been given.
      expect(find.byType(DayScreen), findsOneWidget, reason: entry.key);
      final screen = tester.getSize(find.byType(DayScreen));
      expect(screen.width, closeTo(entry.value.width, 0.5), reason: entry.key);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('and so does Settings, which is the longest column in the app',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(shapes['full screen']);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.light),
      home: SettingsScreen(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      ),
    ));
    await settle(tester);

    for (final entry in shapes.entries) {
      await tester.binding.setSurfaceSize(entry.value);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('a resize at double text size does not overflow either',
      (tester) async {
    // The two things that make a layout fail are a narrow window and large
    // type, and split screen is how somebody gets both at once.
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(shapes['full screen']);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.dark),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: DayScreen(
          vault: vault,
          settings: settings,
          silentBackup: SilentBackup(vault: vault, settings: settings),
        ),
      ),
    ));
    await settle(tester);

    for (final entry in shapes.entries) {
      await tester.binding.setSurfaceSize(entry.value);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: '${entry.key} at 200%');
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });
}
