import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/platform/secure_clipboard.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/onboarding/onboarding_screen.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 16 — the hole he walked through and photographed.**
///
/// He numbered the steps:
///
///   1. "Write these twelve words on paper" — *"user ignores this"* — press
///      "I've written them down".
///   2. "Check three of them" — words 5, 7 and 11 — press *"Show me the words
///      again"*.
///   3. Back on the twelve words — *"user goes back, memorise 5, 7, 11"*.
///   4. "Check three of them" — **the same three**. *"User's memory works
///      here."*
///
/// And the instruction: *"every time the user reaches this page you need to ask
/// random — not that random order you choose before."*
///
/// The cause was one line: the indexes were drawn once, when the vault was
/// created, and the confirm screen read that same list forever. So the check
/// could be passed by memorising three words for twenty seconds — which is
/// exactly what it exists to stop.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_phrase');
  });

  tearDown(() {
    SecureClipboard.forget();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows keeps the SQLCipher file handle open a moment after close, and
      // a tidy-up that throws would replace a real failure message with a
      // meaningless one. The directory is under the system temp and the OS
      // will clear it.
    }
  });

  /// Which three words the confirm screen is currently asking about, as a
  /// string like "5,7,11".
  ///
  /// **A string, deliberately.** The first version of this returned a
  /// `Set<int>` and compared with `seen.toSet().length > 1` — and Dart's `Set`
  /// uses identity equality, so ten distinct objects with identical contents
  /// counted as ten different answers and the test passed against the bug it
  /// was written to catch. Verified the other way round afterwards: with the
  /// old fixed-roll behaviour restored, this now fails.
  String asked(WidgetTester tester) {
    final found = <int>{};
    for (final widget in tester.widgetList<Text>(find.byType(Text))) {
      final data = widget.data;
      if (data == null) continue;
      final match = RegExp(r'^Word (\d+)$').firstMatch(data);
      if (match != null) found.add(int.parse(match.group(1)!));
    }
    final sorted = found.toList()..sort();
    return sorted.join(',');
  }

  testWidgets('THE BUG: bouncing between the two pages asks something new',
      (tester) async {
    final vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await tester.runAsync(vault.initialise);
    final settings =
        await tester.runAsync(() => AppSettings.load(File('${tmp.path}/s.json')));

    // A tall surface. The phrase screen is a long ListView, and on the default
    // 800x600 the button below the twelve words is outside the viewport and
    // therefore never built — which looks exactly like the button not existing.
    tester.view.physicalSize = const Size(1080, 3400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: OnboardingScreen(
        vault: vault,
        settings: settings!,
        onDone: () {},
      ),
    ));
    await tester.pump();

    // Through the welcome and into the passcode, whatever the wording is.
    Future<void> tapText(String label) async {
      final target = find.text(label);
      if (target.evaluate().isEmpty) {
        // Say what IS on screen, rather than only what is not. A bare "found 0
        // widgets" in a five-screen flow tells you nothing about where you are.
        final visible = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .whereType<String>()
            .take(12)
            .toList();
        fail('"$label" is not on screen. Visible text: $visible');
      }
      await tester.ensureVisible(target);
      await tester.pump();
      await tester.tap(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    // Screen 0 is the language list, added 2 September 2026 — "i need you to
    // give localisation - language option from the very first step". Choosing
    // English here is what a first-run English user does, and it is also what
    // keeps the rest of this test able to read the screen it is on.
    await tapText('English');

    // Screen 1 is the promise; "Begin" leads to the passcode.
    await tapText('Begin');

    final passcodeField = find.byType(TextField);
    expect(passcodeField, findsNWidgets(2),
        reason: 'a passcode and its confirmation');

    await tester.enterText(passcodeField.at(0), 'a long enough passphrase');
    await tester.enterText(passcodeField.at(1), 'a long enough passphrase');
    await tester.pump();

    // Creating the vault is real Argon2id at the real parameters, and real
    // file I/O. Both have to happen INSIDE `runAsync` — a future started in the
    // fake-async zone that waits on real work never completes, however long the
    // test then waits for it.
    await tester.runAsync(() async {
      await tester.tap(find.text('Continue'));
      await Future<void>.delayed(const Duration(seconds: 15));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Write these twelve words'), findsOneWidget,
        reason: 'the phrase screen — step 1 of his four');

    // Now his loop, ten times over. A single comparison could pass by luck;
    // ten cannot — the chance of the same three coming up every time is about
    // one in 220 to the ninth.
    final seen = <String>[];
    for (var i = 0; i < 10; i++) {
      await tapText("I've written them down");
      final now = asked(tester);
      expect(now.split(',').where((s) => s.isNotEmpty), hasLength(3),
          reason: 'three words are asked about');
      seen.add(now);
      await tapText('Show me the words again');
    }

    expect(seen.toSet().length, greaterThan(1),
        reason: 'ten visits asked the same three words every time — this is '
            'exactly the four screenshots he sent, and it means the check can '
            'be passed by memorising three words for twenty seconds');

    await tester.runAsync(vault.lock);
  });

  group('the clipboard, which he asked for and I argued about', () {
    setUp(() {
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          if (call.method == 'Clipboard.getData') {
            for (final earlier in log.reversed) {
              if (earlier.method == 'Clipboard.setData') {
                return <String, Object?>{
                  'text': (earlier.arguments as Map)['text'],
                };
              }
            }
            return <String, Object?>{'text': ''};
          }
          return null;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
    });

    test('copying works even with no platform side, and then clears itself',
        () async {
      const phrase = 'remember story industry bundle three alarm shed suit '
          'salmon crunch bone notable';

      expect(await SecureClipboard.copyBriefly(phrase), isTrue);
      expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, phrase);

      await SecureClipboard.clearIfStillOurs();

      expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '',
          reason: 'twelve words that unlock everything do not get to live on '
              'the clipboard');
    });

    test('it does NOT wipe a clipboard that is no longer ours', () async {
      await SecureClipboard.copyBriefly('the twelve words');
      // The user copies something of their own in the meantime.
      await Clipboard.setData(const ClipboardData(text: 'milk, bread, eggs'));

      await SecureClipboard.clearIfStillOurs();

      expect((await Clipboard.getData(Clipboard.kTextPlain))?.text,
          'milk, bread, eggs',
          reason: 'wiping somebody\'s shopping list because they copied a '
              'passphrase a minute ago is its own small betrayal');
    });

    test('clearing when nothing was copied is harmless', () async {
      await SecureClipboard.clearIfStillOurs();
      await SecureClipboard.clearIfStillOurs();
    });

    test('the hold is a minute — long enough to paste, short enough to forget',
        () {
      expect(SecureClipboard.holdFor, const Duration(seconds: 60));
    });
  });
}
