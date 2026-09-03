import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/features/settings/language_tile.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// Ten languages, and the things that go wrong in every app that has them.
///
/// ══ WHAT THIS IS FOR ══════════════════════════════════════════════════════
///
/// Not "are the translations good" — that needs a native reader and no test can
/// stand in for one. `lib/l10n/README.md` says so plainly and says who to ask.
///
/// What a test *can* hold is everything mechanical, and mechanical failures are
/// most of what actually ships broken in a localised app:
///
///   * a key added to English and forgotten in nine other files, so somebody's
///     Japanese app has one English sentence in the middle of it;
///   * a placeholder dropped in translation, so a name never appears and the
///     sentence reads as though it is about nobody;
///   * a plural form that is wrong for the language's own rules — Arabic has
///     six, and a translator working from English will supply two;
///   * **right-to-left**, which is not a translation problem at all: it is a
///     layout problem, it is invisible until somebody sets the phone to Arabic,
///     and it is caused by `left`/`right` where `start`/`end` was meant.
void main() {
  final l10nDir = Directory('lib/l10n');

  Map<String, Object?> arb(String code) => jsonDecode(
        File('${l10nDir.path}/app_$code.arb').readAsStringSync(),
      ) as Map<String, Object?>;

  /// Message keys only — the `@`-prefixed entries are metadata for translators.
  Set<String> keysOf(Map<String, Object?> data) =>
      data.keys.where((k) => !k.startsWith('@')).toSet();

  const locales = ['en', 'es', 'zh', 'hi', 'ar', 'pt', 'de', 'fr', 'ja', 'ko'];

  group('every language says everything', () {
    final english = arb('en');
    final englishKeys = keysOf(english);

    test('English is the template and has messages in it', () {
      expect(englishKeys, isNotEmpty);
      expect(englishKeys, contains('appName'));
    });

    for (final code in locales.where((c) => c != 'en')) {
      test('$code is missing nothing English has', () {
        final missing = englishKeys.difference(keysOf(arb(code)));
        expect(missing, isEmpty,
            reason: 'app_$code.arb is missing: ${missing.join(', ')}. '
                'A missing key falls back to English at run time, so the '
                'symptom is one English sentence in the middle of a '
                'translated screen — which nobody reports, because it looks '
                'deliberate.');
      });

      test('$code has nothing English does not', () {
        // A key that exists only in a translation is a key nothing reads. It is
        // usually a typo in the name, and the English sentence it was meant to
        // replace is still showing.
        final extra = keysOf(arb(code)).difference(englishKeys);
        expect(extra, isEmpty,
            reason: 'app_$code.arb has keys nothing uses: ${extra.join(', ')}');
      });
    }
  });

  group('placeholders survive translation', () {
    final english = arb('en');
    final englishKeys = keysOf(english);

    /// Every `{name}` in a message, ignoring ICU plural *categories* — those
    /// are keywords rather than placeholders and differ by language on purpose.
    Set<String> placeholders(String message) {
      const categories = {
        'plural', 'select', 'zero', 'one', 'two', 'few', 'many', 'other',
      };
      // ══ TWO SHAPES, AND ONLY TWO ══════════════════════════════════════
      //
      // A placeholder is either `{name}` on its own, or the `{name, plural,`
      // that opens an ICU argument. Nothing else is.
      //
      // This used to be `\{(\w+)[},]`, which also matched the `{name,` shape
      // — and therefore matched **any plural branch whose text begins with a
      // word and a comma**. `other{Recording, {count} seconds}` read as a
      // placeholder called `Recording`, so every language failed for having
      // translated it. The branch body is prose; only the argument head is a
      // placeholder, and the way to tell them apart is what follows the comma.
      // `{name}` on its own — but **not** when it is a plural branch whose body
      // happens to be a single word. `zero{nothing}` is indistinguishable from
      // a placeholder by shape alone, and the Spanish `zero{nada}` duly failed
      // this test for translating it. What tells them apart is the keyword
      // immediately before the brace, so that is what is checked.
      final named = RegExp(r'(\w*)\{(\w+)\}');
      final icu = RegExp(r'\{(\w+),\s*(?:plural|select)');
      return {
        for (final m in named.allMatches(message))
          if (!categories.contains(m.group(1))) m.group(2)!,
        ...icu.allMatches(message).map((m) => m.group(1)!),
      }.where((p) => !categories.contains(p)).toSet();
    }

    for (final code in locales.where((c) => c != 'en')) {
      test('$code keeps every placeholder', () {
        final translated = arb(code);
        final wrong = <String>[];
        for (final key in englishKeys) {
          final source = english[key];
          final target = translated[key];
          if (source is! String || target is! String) continue;
          final want = placeholders(source);
          final got = placeholders(target);
          if (want.length != got.length || !want.containsAll(got)) {
            wrong.add('$key: expected {${want.join('}, {')}}, '
                'found {${got.join('}, {')}}');
          }
        }
        expect(wrong, isEmpty,
            reason: 'a dropped placeholder in app_$code.arb means the value '
                'never appears — "Also in ." rather than "Also in Kavya.":\n'
                '${wrong.join('\n')}');
      });
    }
  });

  group('plurals follow the language, not English', () {
    test('Arabic supplies more than the two English has', () {
      // Arabic distinguishes zero, one, two, few, many and other. A translator
      // handed an English file with `one`/`other` will supply two, and the app
      // will then say the wrong thing for 3, 11 and 100 — which is most
      // numbers.
      final ar = arb('ar');
      for (final key in ['lockTryAgainSeconds', 'lockTryAgainMinutes']) {
        final message = ar[key] as String;
        expect(message, contains('plural'));
        for (final form in ['zero', 'one', 'two', 'few', 'many', 'other']) {
          expect(message, contains('$form{'),
              reason: '$key in Arabic is missing the "$form" form');
        }
      }
    });

    test('Chinese, Japanese and Korean need only one form', () {
      // These languages do not inflect for number. Supplying `one` and `other`
      // is not wrong, but supplying only `other` is correct and simpler, and a
      // test that demanded English's shape would be imposing English grammar.
      for (final code in ['zh', 'ja', 'ko']) {
        final message = arb(code)['lockTryAgainSeconds'] as String;
        expect(message, contains('other{'),
            reason: '$code must at least have the "other" form');
      }
    });
  });

  group('the name of the app is never translated', () {
    test('every locale says Lamplight', () {
      // ADR-010 calls the name permanent. It is in the package id, the signing
      // certificate and the icon; a translated name would be a different app
      // with the same key.
      for (final code in locales) {
        expect(arb(code)['appName'], 'Lamplight',
            reason: 'app_$code.arb translated the app name');
      }
    });
  });

  group('the language list', () {
    test('offers every locale the app actually supports', () {
      final offered = kLanguages
          .where((e) => e.locale != null)
          .map((e) => e.locale!.languageCode)
          .toSet();
      final supported = L.supportedLocales.map((l) => l.languageCode).toSet();
      expect(offered, supported,
          reason: 'a language the app is translated into but does not offer is '
              'unreachable; one it offers but is not translated into shows '
              'English and looks broken');
    });

    test('names every language in its own words', () {
      // Somebody looking for their language is scanning for the shape of their
      // own word, and may well not read the language the app is currently in —
      // which is exactly why they are on this screen.
      final byCode = {
        for (final e in kLanguages)
          if (e.locale != null) e.locale!.languageCode: e.name
      };
      expect(byCode['es'], 'Español');
      expect(byCode['ar'], 'العربية');
      expect(byCode['ja'], '日本語');
      expect(byCode['hi'], 'हिन्दी');
      expect(byCode['ko'], '한국어');
      expect(byCode['zh'], '简体中文');
    });

    test('the first row is "follow the phone"', () {
      // The default, and it must stay first: an app that picks a language on
      // first launch is one that thinks it knows better than the device.
      expect(kLanguages.first.locale, isNull);
    });
  });

  group('the setting round-trips', () {
    test('a chosen language survives being written and read', () {
      final settings = AppSettings.inMemory();
      expect(settings.locale, isNull, reason: 'the default follows the phone');
      settings.locale = const Locale('ar');
      expect(settings.locale?.languageCode, 'ar');
      settings.locale = null;
      expect(settings.locale, isNull);
    });

    test('it is stored as a tag rather than a position in a list', () {
      // An index would silently mean a different language the day a locale is
      // inserted in the middle of `kLanguages`.
      final settings = AppSettings.inMemory({'locale': 'ja'});
      expect(settings.locale?.languageCode, 'ja');
    });

    test('a language the app has never heard of does not crash it', () {
      final settings = AppSettings.inMemory({'locale': 'xx-YY'});
      expect(settings.locale?.languageCode, 'xx');
      // Unsupported locales fall back through MaterialApp's own resolution,
      // which lands on the first supported locale rather than failing.
    });
  });

  group('a screen actually renders in every language', () {
    // ══ THE ONE THAT PROVES THE PIPELINE ═══════════════════════════════════
    //
    // Everything above reads the ARB files. This builds a real widget under a
    // real `Localizations`, ten times, and reads the words off the screen. It
    // is the difference between "the translations exist" and "the app uses
    // them" — and 76 translated strings that nothing reads would look exactly
    // like a finished job.
    for (final code in locales) {
      testWidgets('$code draws the empty day in its own words', (tester) async {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          locale: Locale(code),
          home: Scaffold(
            body: Builder(
              builder: (context) => Text(L.of(context).dayEmptyToday),
            ),
          ),
        ));
        await tester.pump();

        final expected = arb(code)['dayEmptyToday'] as String;
        expect(find.text(expected), findsOneWidget,
            reason: 'the $code build did not show its own translation');
        if (code != 'en') {
          expect(find.text(arb('en')['dayEmptyToday'] as String), findsNothing,
              reason: '$code fell back to English, which means the locale '
                  'never reached the widget');
        }
      });
    }

    testWidgets('Arabic lays the interface out right to left', (tester) async {
      // Nothing asks for this. `MaterialApp` resolves the locale's direction
      // and wraps the tree in a `Directionality`, and the whole RTL story is
      // that the *directional* APIs then follow it on their own.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) => Text(Directionality.of(context).name),
        ),
      ));
      await tester.pump();
      expect(find.text('rtl'), findsOneWidget);
    });

    testWidgets('and every other language left to right', (tester) async {
      for (final code in locales.where((c) => c != 'ar')) {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          locale: Locale(code),
          home: Builder(
            builder: (context) => Text(Directionality.of(context).name),
          ),
        ));
        await tester.pump();
        expect(find.text('ltr'), findsOneWidget, reason: '$code should be ltr');
      }
    });
  });

  group('onboarding, which is the one screen where English is a lockout', () {
    // ══ WHY THIS SCREEN HAS ITS OWN GROUP ══════════════════════════════════
    //
    // `lib/l10n/README.md` says onboarding is translated first and gives the
    // reason: everywhere else in the app an English string is untidy, and a
    // person can poke at a button to find out what it does. Here they cannot.
    // They are choosing the passphrase that is the only thing that ever opens
    // the vault, and then copying twelve recovery words onto paper, and if
    // they misread either instruction the journal is gone before they have
    // written in it.
    //
    // So these are not "is the translation nice" tests. They pin the three
    // sentences whose *meaning* is load-bearing, and the placeholder that
    // would otherwise silently point somebody at the wrong word.

    /// Every message the onboarding screen reads, so a key deleted from the
    /// ARB while the screen still calls it fails here rather than at runtime
    /// in front of the one person this screen exists for.
    const onboardingKeys = [
      'onboardNoAccount', 'onboardPromiseBody', 'onboardBegin',
      'onboardHaveBackup', 'onboardSetPasscode', 'onboardPasscodeBody',
      'onboardPasscodeLabel', 'onboardPasscodeAgain', 'onboardSettingUp',
      'onboardContinue', 'onboardPasscodesDiffer', 'onboardVaultFailed',
      'onboardVaultFailedThen', 'onboardWriteWords', 'onboardWordsBody',
      'onboardWrittenDown', 'onboardCopyWords', 'onboardClipboardNote',
      'onboardCopied', 'onboardCopyFailed', 'onboardCheckThree',
      'onboardCheckBody', 'onboardWordNumber', 'onboardWordWrong',
      'onboardShowWords', 'onboardFingerprintTitle', 'onboardFingerprintBody',
      'onboardFingerprintExplain', 'onboardFingerprintWaiting',
      'onboardFingerprintUse', 'onboardFingerprintFailed',
      'onboardOneLastThing', 'onboardNameBody', 'onboardFingerprintOn',
      'onboardYourName', 'onboardStartWriting', 'onboardSkip',
    ];

    for (final code in locales) {
      test('$code has all of onboarding, with nothing left blank', () {
        final data = arb(code);
        for (final key in onboardingKeys) {
          final value = data[key];
          expect(value, isA<String>(),
              reason: '$code is missing $key, so that step of onboarding '
                  'would fall back to English');
          expect((value! as String).trim(), isNotEmpty,
              reason: '$code has $key as an empty string, which renders as '
                  'a blank button or a blank instruction');
        }
      });
    }

    // ── The screen has no English left in it ─────────────────────────────
    //
    // A ratchet, not a style rule. The failure it exists to catch is somebody
    // adding a sentence to onboarding later, in English, and nine languages
    // acquiring one untranslated line in the most consequential screen in the
    // app — which nothing else here would notice.
    test('the onboarding screen holds no English sentence of its own', () {
      final source =
          File('lib/features/onboarding/onboarding_screen.dart').readAsStringSync();

      // Code, not prose: strip comments first, or the (long, deliberate)
      // explanations above each screen count as literals.
      final withoutComments = source
          .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
          .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

      // A "sentence" is a quoted run with a space in it and a lower-case
      // letter — which excludes identifiers, asset paths and single words
      // like 'en'. Deliberately crude: it only has to catch prose.
      final literals = RegExp(r"'([^'\\\n]{12,})'")
          .allMatches(withoutComments)
          .map((m) => m.group(1)!)
          .where((v) => v.contains(' '))
          .where((v) => RegExp('[a-z]').hasMatch(v))
          .toList();

      expect(literals, isEmpty,
          reason: 'onboarding is meant to be fully localised — see '
              'lib/l10n/README.md. These are still English literals: '
              '$literals');
    });

    // ── The three sentences whose meaning is the feature ─────────────────

    // ══ COUNT SENTENCES, NEVER CHARACTERS ══════════════════════════════
    //
    // The first version of the two tests below asserted a minimum *length* in
    // characters, and Chinese and Japanese failed it immediately — the full
    // Chinese paragraph is 64 characters and the English one is 196. Nothing
    // was wrong with the translation. The test was carrying a Latin-script
    // assumption, which is the same mistake as the search splitter that used
    // `\w` and threw away every Devanagari word (§7.0-D).
    //
    // What actually has to survive is the *structure*: the claims are made in
    // separate sentences, and a translation that merges them into a slogan has
    // dropped one. So count sentence endings, in every script that has one.
    int sentences(String text) => RegExp(
          // Latin/Arabic full stop and question mark, the CJK ideographic
          // full stop and its full-width question mark, and the Devanagari
          // danda. Arabic uses the Latin '.' in practice; Hindi uses '।'.
          r'[.!?\u0964\u3002\uFF1F\uFF01\u061F]',
        ).allMatches(text).length;

    test('every language still says there is no copy of the words', () {
      // The single most important sentence in the app. If a translation
      // softens this into "keep them safe", somebody loses a journal
      // believing support can recover it. No test can check the wording is
      // graceful; it can check nobody quietly shortened it to a slogan.
      //
      // Four sentences minimum: no copy, cannot send them, no support email,
      // and the screenshot warning with its reason.
      for (final code in locales) {
        final body = arb(code)['onboardWordsBody']! as String;
        expect(sentences(body), greaterThanOrEqualTo(4),
            reason: '$code has ${sentences(body)} sentences in '
                'onboardWordsBody. It carries three separate refusals — no '
                'copy, no way to send them, no support email — plus the '
                'reason paper beats a screenshot.');
        expect(body, contains('\n\n'),
            reason: '$code lost the paragraph break, so the screenshot '
                'warning runs into the sentence before it');
      }
    });

    test('the fingerprint promise stays as narrow as the Settings one', () {
      // Four scoped claims: this vault, this phone, switched off by Android
      // if the fingerprints change, never in a backup. A translation that
      // compresses it into "secure and private" has promised something
      // broader than the code does, which is the failure CLAUDE.md rule 10
      // exists to prevent.
      for (final code in locales) {
        final text = arb(code)['onboardFingerprintExplain']! as String;
        expect(sentences(text), greaterThanOrEqualTo(3),
            reason: '$code has ${sentences(text)} sentences in '
                'onboardFingerprintExplain; it makes four separate claims '
                'and compressing them widens the promise');
        expect(text, contains('Android'),
            reason: '$code dropped Android from the sentence that explains '
                'who turns the fingerprint off, which is the part that '
                'makes the promise checkable rather than a reassurance');
      }
    });

    test('the app never asks somebody to trust a name it translated', () {
      // ADR-010 again, but specifically on the two onboarding strings that
      // embed the app's name in a sentence. A translated product name reads
      // as a different app to the person who was told to install this one.
      for (final code in locales) {
        for (final key in ['onboardNameBody', 'onboardFingerprintOn']) {
          expect(arb(code)[key], contains('Lamplight'),
              reason: '$code translated the app name inside $key');
        }
      }
    });

    // ── The placeholder that points at a word ────────────────────────────

    testWidgets('the word number survives into every language', (tester) async {
      // `onboardWordWrong` names which of the twelve words is wrong. A
      // translation that drops {number} produces "That word is not right",
      // which is advice about nothing when there are three fields on screen.
      for (final code in locales) {
        late String asked;
        late String wrong;
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          locale: Locale(code),
          home: Builder(builder: (context) {
            asked = L.of(context).onboardWordNumber(7);
            wrong = L.of(context).onboardWordWrong(7);
            return const SizedBox();
          }),
        ));
        await tester.pump();

        expect(asked, contains('7'),
            reason: '$code lost the number from the field label, so all '
                'three boxes in the check read the same');
        expect(wrong, contains('7'),
            reason: '$code lost the number from the error, so it does not '
                'say which word to look at');
      }
    });
  });

  group('right to left', () {
    test('nothing in the app hard-codes a left or right edge', () {
      // ══ THE RTL AUDIT, AS A TEST ═══════════════════════════════════════
      //
      // Arabic mirrors the whole interface, and Flutter does that on its own —
      // but only for the *directional* APIs. `EdgeInsets.only(left: 16)` stays
      // on the left in Arabic, so a row of text that should start at the right
      // margin starts at the wrong one, and a chevron that should point the
      // other way does not.
      //
      // This is invisible in nine of the ten languages and is the single most
      // common way a localised app ships broken. It is mechanical, so it is a
      // test rather than a habit.
      final offenders = <String>[];
      final allowed = <String>[
        // Genuinely non-directional: a gradient across a *painting*, and the
        // page texture, neither of which is reading order.
        'design/paper.dart',
        'design/star_map.dart',
        'design/lamp_mark.dart',
        'design/passcode_meter.dart',
      ];

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        if (path.contains('/l10n/generated/')) continue;
        if (path.endsWith('.g.dart')) continue;
        if (allowed.any(path.contains)) continue;

        var line = 0;
        for (final text in file.readAsLinesSync()) {
          line++;
          final code = text.trimLeft();
          if (code.startsWith('//') || code.startsWith('///')) continue;
          if (RegExp(r'EdgeInsets\.only\([^)]*\b(left|right):').hasMatch(code) ||
              RegExp(r'EdgeInsets\.fromLTRB\(').hasMatch(code)) {
            offenders.add('$path:$line  $code');
          }
        }
      }

      // Reported rather than asserted to zero, for now: this is a real audit of
      // an app that was written before it had a second language, and the number
      // is the work. It is pinned so it can only go DOWN — a new hard-coded
      // edge fails the build.
      expect(offenders.length, lessThanOrEqualTo(_knownDirectionalEdges),
          reason: 'new left/right padding was added. Use '
              'EdgeInsetsDirectional.only(start:/end:) so Arabic mirrors:\n'
              '${offenders.take(10).join('\n')}');
    });
  });
}

/// How many hard-coded left/right edges the app had when the RTL audit was
/// written, on 28 August 2026. **Counted, not estimated.**
///
/// **This number may only ever go down.** It is not a target and it is not an
/// excuse — it is a ratchet, so the app can be made right-to-left-correct one
/// screen at a time without the next person silently adding to the pile.
/// Convert a screen, count again, lower this.
///
/// ── WHERE THEY ARE, WORST FIRST ──────────────────────────────────────────
///
/// ```
///  10  features/settings/appearance_screen.dart
///   6  features/search/search_screen.dart
///   5  features/settings/settings_screen.dart
///   4  features/capture/size_sheet.dart
///   4  features/folders/folder_picker.dart
///   3  features/day/day_header.dart
///   3  features/day/day_stream.dart
/// ```
///
/// **`design/components.dart` was done first, on the day of the audit**, and
/// that is why the count starts at 70 rather than 77. Its seven edges were the
/// padding of `LampTile`, `LampBanner` and the sheet frame — most rows on most
/// screens — so seven lines mirrored far more of the interface than the ten in
/// Appearance would have. The rest are per-screen and can be done as each
/// screen is next touched for another reason.
///
/// The conversion itself is mechanical: `EdgeInsets.only(left: x)` becomes
/// `EdgeInsetsDirectional.only(start: x)`, and `EdgeInsets.fromLTRB(a,b,c,d)`
/// becomes `EdgeInsetsDirectional.fromSTEB(a,b,c,d)`. Nothing else changes, and
/// in the nine left-to-right languages nothing looks different at all.
const int _knownDirectionalEdges = 70;
