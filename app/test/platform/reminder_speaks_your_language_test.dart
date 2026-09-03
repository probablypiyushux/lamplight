import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/reminders/reminders.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **31 August 2026 — the heading was translated and the reason was not.**
///
/// > *"In localisation mistake — in settings tab — The Reminder may not arrive
/// > — This phone is saving battery by holding lamplight back. That is the
/// > actual reason a reminder is late or never arrives. (this never gets
/// > localised!)"*
///
/// He is quoting a screen at me, and the quote contains its own diagnosis: the
/// first half is the tile's **title**, which had an ARB key and ten
/// translations, and the second half is its **subtitle**, which came out of
/// `core/reminders/reminders.dart` as an English literal.
///
/// A Hindi reader therefore got a Hindi heading over an English paragraph.
/// That is worse than the whole tile being English — a wholly untranslated
/// string reads as a gap, whereas a translated title over an untranslated body
/// reads as the app having tried and failed. And it is the *reason* half, so
/// the part that is lost is the only part that tells you what to do.
///
/// The fix is the one `core/backup/` already uses: the class hands over
/// **which** gate is shut and the screen decides how to say it. This file is
/// the proof that it arrives, in all ten languages, for all four gates.
///
/// **`test/platform/reminder_health_test.dart` is the other half** and pins the
/// English, because those assertions carry round eight's ISSUE 10 — no
/// "channel", no "override", and the phone named as the thing doing it.
void main() {
  late Map<Locale, L> languages;

  setUpAll(() async {
    // Real awaits belong in `setUp`, which runs before `testWidgets` enters its
    // fake-async zone. See round fourteen's note in PLAN.md §7.0-I — this is a
    // plain `test()` file, but the habit is the one that stops the hangs.
    languages = {
      for (final locale in L.supportedLocales)
        locale: await L.delegate.load(locale),
    };
  });

  test('all ten languages are actually loaded', () {
    // If this ever drops, every assertion below gets weaker without failing.
    expect(languages, hasLength(10));
  });

  group('every gate that can stop a reminder speaks the reader language', () {
    test('each problem has a sentence in each language', () {
      for (final language in languages.entries) {
        for (final problem in ReminderProblem.values) {
          final said = problem.describeIn(language.value);
          expect(said, isNotEmpty,
              reason: '$problem in ${language.key.languageCode}');
        }
      }
    });

    test('no language falls through to the English literal', () {
      // The failure this catches is a missing ARB key, which `gen_l10n` fills
      // in from the template — so the app keeps building, the screen keeps
      // working, and one language quietly shows English. Exactly the bug being
      // fixed, reintroduced silently.
      for (final language in languages.entries) {
        if (language.key.languageCode == 'en') continue;
        for (final problem in ReminderProblem.values) {
          expect(problem.describeIn(language.value), isNot(problem.message),
              reason: '$problem in ${language.key.languageCode} came back as '
                  'the English sentence, which means the key is missing from '
                  'app_${language.key.languageCode}.arb');
        }
      }
    });

    test('no two gates say the same thing in any language', () {
      // Four faults, four different settings screens to go and fix them on. Two
      // that read alike send somebody to the wrong one, which is the whole
      // reason `firstProblem` reports them one at a time in a fixed order.
      for (final language in languages.entries) {
        final said = <String>{};
        for (final problem in ReminderProblem.values) {
          final sentence = problem.describeIn(language.value);
          expect(said.add(sentence), isTrue,
              reason: 'two problems say "$sentence" in '
                  '${language.key.languageCode}');
        }
      }
    });

    test('the battery sentence is the one he quoted, in every language', () {
      // The specific string in the report. Named on its own because it is the
      // most common of the four by a wide margin — vendor battery management is
      // what `Reminders.batteryRestricted`'s long note says was the original
      // cause — so it is the sentence most readers will actually meet.
      for (final language in languages.entries) {
        final said =
            ReminderProblem.batterySaving.describeIn(language.value);
        expect(said, isNotEmpty);
        expect(said.trim(), said,
            reason: 'stray whitespace in ${language.key.languageCode}');
      }
    });
  });

  group('what the sentences may not say, in every language', () {
    test('never the word "channel", and never in English only', () {
      // ROUND EIGHT, ISSUE 10, extended to the other nine languages. A
      // notification channel is Android's word for Android's own bookkeeping.
      // The English assertion has existed since round eight; a translator with
      // the key and no context is exactly who would put the jargon back.
      for (final language in languages.entries) {
        final said = ReminderProblem.remindersOff.describeIn(language.value);
        expect(said.toLowerCase(), isNot(contains('channel')),
            reason: 'in ${language.key.languageCode}');
      }
    });

    test('the app does not explain its own limits at somebody', () {
      for (final language in languages.entries) {
        final said = ReminderProblem.batterySaving.describeIn(language.value);
        expect(said.toLowerCase(), isNot(contains('override')),
            reason: 'in ${language.key.languageCode}');
      }
    });
  });

  test('a healthy phone has nothing to translate', () {
    // Not a formality: `firstProblem` returning null is what makes the tile
    // disappear, and a tile that says "everything is fine" in ten languages
    // would be ten translations of nagging. `ETHICAL-DESIGN.md` forbids it.
    const healthy = ReminderHealth(
      permission: true,
      notificationsEnabled: true,
      channelEnabled: true,
      batteryRestricted: false,
    );
    expect(healthy.firstProblem, isNull);
  });
}
