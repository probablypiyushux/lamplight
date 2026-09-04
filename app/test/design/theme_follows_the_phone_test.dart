import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/design/tokens.dart';

/// **ROUND NINETEEN — "Follow my phone … this doesn't works!"**
///
/// Reported against the Play Store closed-testing build: install it, open it,
/// and the app is dark on a phone that is set to light.
///
/// ── THE DIAGNOSIS, WHICH IS NOT WHAT THE REPORT SAYS ────────────────────
///
/// The obvious reading is that the Auto chip is broken, and it is worth being
/// precise that it is not — the first group below is that claim, kept as a
/// test so nobody "fixes" a working `ThemeMode.system` next time this is read.
///
/// What was actually wrong is quieter and was never a bug in any screen: a
/// fresh install has no `themeMode` written, and the fallback was **dark**. So
/// the app followed the phone the moment you asked it to, and never before —
/// and the first launch is the only one most people judge.
///
/// The fix is a default, not a behaviour, and the second group is the half
/// that matters more: it must apply to **new installs only**.
void main() {
  group('the chip was never broken', () {
    Widget app(ThemeMode mode) => MaterialApp(
          theme: lamplightTheme(LamplightColors.light),
          darkTheme: lamplightTheme(LamplightColors.dark),
          themeMode: mode,
          home: const Scaffold(body: SizedBox.shrink()),
        );

    Brightness painted(WidgetTester t) =>
        Theme.of(t.element(find.byType(Scaffold))).brightness;

    testWidgets('system on a dark phone paints dark', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(app(ThemeMode.system));
      expect(painted(tester), Brightness.dark);
    });

    testWidgets('system on a light phone paints light', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(app(ThemeMode.system));
      expect(painted(tester), Brightness.light);
    });

    testWidgets('and an explicit choice still overrules the phone',
        (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(app(ThemeMode.dark));
      expect(painted(tester), Brightness.dark,
          reason: 'someone who chose dark keeps dark on a light phone');
    });
  });

  group('the default, and who it reaches', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('lamplight-theme'));
    tearDown(() => dir.deleteSync(recursive: true));

    File at(String name) => File('${dir.path}/$name');

    test('a brand new install follows the phone', () async {
      final settings = await AppSettings.load(at('new.json'));
      expect(settings.themeMode, ThemeMode.system);
    });

    // ── The half that protects people who already have the app ──────────
    //
    // Every install made before this change has a settings.json — `app.dart`
    // stamps `firstRunAt` in `initState`, so the file exists after the first
    // launch — and almost none of them mention `themeMode`, because almost
    // nobody opens Appearance to choose the theme it already had.
    //
    // If the new default were a change to the getter's fallback rather than a
    // seed for a new file, every one of those installs would flip to whatever
    // the phone says on the morning they updated. That is the same class of
    // thing as changing the face somebody's writing is set in, which
    // `writingFace` refused to do for the same reason.
    test('an install that already exists is not repainted', () async {
      final file = at('existing.json');
      // What an older install looks like: it has been run, so it has a
      // firstRunAt, and it has never been told anything about the theme.
      file.writeAsStringSync(jsonEncode({'firstRunAt': 1756000000000}));

      final settings = await AppSettings.load(file);
      expect(settings.themeMode, ThemeMode.dark,
          reason: 'dark is what this install has always opened in, and an '
              'update may not change that on its own');
    });

    test('an explicit choice survives, in both directions', () async {
      for (final (stored, expected) in <(String, ThemeMode)>[
        ('light', ThemeMode.light),
        ('dark', ThemeMode.dark),
        ('system', ThemeMode.system),
      ]) {
        final file = at('chosen-$stored.json');
        file.writeAsStringSync(jsonEncode({'themeMode': stored}));
        expect((await AppSettings.load(file)).themeMode, expected);
      }
    });

    test('a settings file that will not parse is still an old install',
        () async {
      final file = at('broken.json');
      file.writeAsStringSync('{ this is not json');
      expect((await AppSettings.load(file)).themeMode, ThemeMode.dark,
          reason: 'the file is there, so somebody is already using this app. '
              'Failing to read a preference must not be read as a new phone.');
    });
  });
}
