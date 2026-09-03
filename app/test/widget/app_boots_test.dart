import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/app.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/features/backup/silent_backup.dart';
import 'package:lamplight/features/onboarding/onboarding_screen.dart';
import 'package:lamplight/l10n/dates.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:sodium/sodium_sumo.dart';

/// **The app starts.**
///
/// ══ WHY THIS FILE EXISTS, AND IT IS NOT A HAPPY REASON ══════════════════════
///
/// On 29 August 2026 Lamplight stopped opening. Not slowly, not on one screen —
/// it did not start at all, on any device, in any language. The cause was one
/// argument:
///
/// ```dart
/// title: L.of(context).appName,   //  inside MaterialApp(...)
/// ```
///
/// `title:` is an ordinary eager argument, so it is evaluated in
/// `_LamplightAppState.build`, whose `context` is **above** the `MaterialApp`
/// it is building. `Localizations` is installed by `WidgetsApp`, *inside* that
/// MaterialApp. So there was no `L` to find, `Localizations.of<L>` returned
/// null, and the generated `L.of`'s `!` threw on the first frame of every
/// launch, before a single screen was constructed. `installCalmErrors` caught
/// it and drew the apology page, which is why it looked like a hang rather than
/// a crash. The fix is `onGenerateTitle`, which the framework calls with a
/// context from below.
///
/// ══ THE PART WORTH LEARNING FROM ════════════════════════════════════════════
///
/// The suite was 1,217 tests and every one of them passed.
///
/// They passed because **every widget test builds its own `MaterialApp`** around
/// the one screen it is testing — they all carry the same pasted
/// `localizationsDelegates:` block and a comment explaining that without it
/// `L.of` is null. Everybody knew the hazard. Everybody worked around it in
/// their own harness. And so the one widget nobody ever pumped was
/// `LamplightApp` itself: the widget that has to work before any other one can
/// run at all.
///
/// A test harness that reconstructs the thing it is testing is a test harness
/// that stops testing it. This file pumps the **real** `LamplightApp` — the one
/// `main()` hands to `runApp` — with nothing rebuilt and nothing stubbed except
/// the platform channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SodiumSumo sodium;
  late Directory tmp;
  late AppSettings settings;
  late Vault vault;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    // `main()` awaits this before the first frame; a `DateFormat` for a locale
    // whose symbols are not loaded throws, and the lock screen draws a date.
    await LampDates.prepare();
  });

  // ══ EVERY `await` THAT TOUCHES THE DISK LIVES HERE, AND THAT IS LOAD-BEARING
  //
  // `testWidgets` runs its body inside a **fake-async zone**: `Future`s are
  // completed by the test's own clock, which only advances when you `pump`. So
  // an `await` on something real — libsodium initialising, a settings file
  // being read, the vault opening its database — is waiting on a callback the
  // fake clock will never deliver, and the test simply stops. Forever. No
  // failure, no output, just a run that never ends.
  //
  // The first draft of this file did the whole of `main()`'s wiring inside the
  // test body and hung for ten minutes at a time. What made it confusing is
  // that the identical code in a plain `test()` — no fake zone — finished in
  // under a second, so the setup looked innocent and the app looked broken.
  //
  // `setUp` runs *before* the binding enters that zone, so the awaits here are
  // ordinary Dart. The body is left with nothing asynchronous to do but pump
  // frames, which is the only thing it is actually trying to measure.
  // (`tester.runAsync` is the escape hatch when it has to be inline.)
  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_boot');
    // Every platform class in the app shares one channel. None of them has
    // anything to talk to in a test, and an unanswered channel call is a
    // `MissingPluginException` — which would fail this test for a reason that
    // has nothing to do with whether the app starts.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('lamplight/documents'),
      (call) async => null,
    );

    final root = Directory('${tmp.path}/vault');
    settings = await AppSettings.load(File('${root.path}/settings.json'));
    vault = Vault(
      sodium: sodium,
      root: root,
      // The idle timer is a real `Timer`. Left running it outlives the test and
      // the framework fails the *next* one with a pending-timer assertion, so
      // the vault is closed in `tearDown` rather than left to the collector.
      idleTimeout: settings.autoLock,
    );
    await vault.initialise();
  });

  tearDown(() async {
    await vault.lock();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lamplight/documents'), null);
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// The widget `main()` builds, from the parts `setUp` already made.
  ///
  /// Deliberately synchronous — see the note on `setUp`.
  Widget app() => LamplightApp(
        vault: vault,
        settings: settings,
        silentBackup: SilentBackup(vault: vault, settings: settings),
      );

  // ── Frames are pumped by hand; `pumpAndSettle` can never return here ───────
  //
  // A settle waits for no frame to be scheduled, and **this app always has one
  // scheduled**: `PaperGround` arms a `Timer.periodic` to turn the star map at
  // the sidereal rate. So settling would mean "the app stopped being itself".
  // Called anyway it spins to its own ten-minute timeout and reports a hang
  // instead of a result — which is exactly what the second draft of this file
  // did. Explicit pumps also state how much time is meant to pass, which is
  // the thing being asserted.
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const frame = Duration(milliseconds: 32);
    for (var spent = Duration.zero; spent < total; spent += frame) {
      await tester.pump(frame);
    }
  }

  testWidgets('the first frame of a cold start does not throw', (tester) async {
    await tester.pumpWidget(app());

    // `pumpWidget` does not rethrow a build error — the framework records it
    // and paints an error widget — so it has to be asked for. Before the fix
    // this held `_TypeError: Null check operator used on a null value`.
    expect(
      tester.takeException(),
      isNull,
      reason: 'the app threw while building its very first frame',
    );
  });

  testWidgets('the opening hands over to a real screen', (tester) async {
    await tester.pumpWidget(app());
    expect(tester.takeException(), isNull);

    // Past the lamp. A fresh vault is uninitialised, so what must be underneath
    // is onboarding — and reaching it proves the whole chain built: theme,
    // localisations, typography, the lock warning, the navigator.
    await pumpFor(tester, const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNull,
        reason: 'the app threw on the way out of the opening animation');
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  // ── Every language, because English working proves the least ──────────────
  //
  // The bug this file exists for was language-independent, but the class is
  // not: a missing ARB key, a plural rule a language does not have, a date
  // pattern `intl` cannot build. Each throws only in the language that has it,
  // and Lamplight ships ten. This is the cheapest possible insurance against a
  // launch that works here and is a black screen for somebody in Seoul.
  for (final locale in L.supportedLocales) {
    testWidgets('the app starts in ${locale.languageCode}', (tester) async {
      settings.locale = locale;
      await tester.pumpWidget(app());
      expect(tester.takeException(), isNull,
          reason: 'the app threw on its first frame in $locale');
      await pumpFor(tester, const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull,
          reason: 'the app threw after the opening in $locale');
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  }
}
