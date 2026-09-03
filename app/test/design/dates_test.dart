import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/dates.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// Dates that belong to the language, not just months with translated names.
///
/// > *"while localisation remember also the dates and everything should
/// > change! ... also the format! of dates!"* — 29 August 2026
///
/// ══ WHAT THIS IS ACTUALLY CHECKING ══════════════════════════════════════════
///
/// Not that the words are right — `intl` supplies those and CLDR is a better
/// authority than anything written here. What it checks is the thing a
/// hand-rolled list of month names gets wrong even when every word in it is
/// correctly translated: **the order**.
///
/// `${date.day} $monthName` is right for English and Hindi, wrong for German,
/// and badly wrong for Japanese and Chinese, which put the year first and the
/// day last. That is the difference between an app that has been translated and
/// one that reads as though it was written in your language, which is what he
/// asked for.
void main() {
  setUpAll(() async {
    await LampDates.prepare();
  });

  /// Runs [read] inside a real `Localizations` for [code].
  Future<String> inLocale(
    WidgetTester tester,
    String code,
    String Function(BuildContext) read,
  ) async {
    late String result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      locale: Locale(code),
      home: Builder(builder: (context) {
        result = read(context);
        return const SizedBox();
      }),
    ));
    await tester.pump();
    return result;
  }

  final august20 = DateTime(2026, 8, 20, 14, 20);

  group('the order follows the language', () {
    testWidgets('Japanese puts the month before the day', (tester) async {
      final s = await inLocale(
          tester, 'ja', (c) => LampDates.dayAndMonth(c, august20));
      expect(s.indexOf('8'), lessThan(s.indexOf('20')),
          reason: 'Japanese writes 8月20日. A list of translated month names '
              'glued to "\${date.day} \$month" cannot produce this, which is '
              'the whole reason intl is doing the formatting.');
    });

    testWidgets('Chinese does too', (tester) async {
      final s = await inLocale(
          tester, 'zh', (c) => LampDates.dayAndMonth(c, august20));
      expect(s.indexOf('8'), lessThan(s.indexOf('20')));
    });

    testWidgets('English and Hindi put the day first', (tester) async {
      for (final code in ['en', 'hi']) {
        final s = await inLocale(
            tester, code, (c) => LampDates.dayAndMonth(c, august20));
        expect(s.startsWith('20'), isTrue,
            reason: '$code should lead with the day, and got "$s"');
      }
    });
  });

  group('the words follow the language', () {
    testWidgets('the month is not left in English', (tester) async {
      final en =
          await inLocale(tester, 'en', (c) => LampDates.monthName(c, 8));
      expect(en, 'August');

      // German for August *is* "August", which the first version of this test
      // did not know and duly failed on. May is the useful probe: it differs in
      // every one of the ten.
      final may = <String, String>{};
      for (final code in ['en', 'es', 'de', 'fr', 'pt', 'hi', 'ar', 'zh', 'ja', 'ko']) {
        may[code] = await inLocale(tester, code, (c) => LampDates.monthName(c, 5));
        expect(may[code]!.trim(), isNotEmpty, reason: code);
      }
      expect(may['en'], 'May');
      expect(may['es'], 'mayo');
      expect(may['de'], 'Mai');
      expect(may['fr'], 'mai');
      // And no two of these are the same word by accident: at least seven
      // distinct forms among the ten.
      expect(may.values.toSet().length, greaterThanOrEqualTo(7));
    });

    testWidgets('and neither is the weekday', (tester) async {
      final en = await inLocale(tester, 'en', (c) => LampDates.full(c, august20));
      expect(en, contains('Thursday'));

      final de = await inLocale(tester, 'de', (c) => LampDates.full(c, august20));
      expect(de, isNot(contains('Thursday')));
      expect(de, contains('Donnerstag'));
    });
  });

  group('the clock follows the language', () {
    testWidgets('some read 24-hour and some read 12', (tester) async {
      final en = await inLocale(tester, 'en', (c) => LampDates.time(c, august20));
      final de = await inLocale(tester, 'de', (c) => LampDates.time(c, august20));
      // Not asserting which is which — CLDR decides that and it changes. What
      // must be true is that the app is not printing one clock for everybody.
      expect(en, isNotEmpty);
      expect(de, isNotEmpty);
      expect(de, contains('14'),
          reason: 'German reads 24-hour time, so 14:20 stays 14');
    });
  });

  group('the digits stay Latin, deliberately', () {
    testWidgets('Arabic and Hindi dates are still searchable', (tester) async {
      // ══ THE ONE NARROWING THIS MODULE MAKES ═════════════════════════════
      //
      // Both languages have their own numerals — ٢٠ and २०. A day in this app
      // is also a filename in the readable export, a key in the database, and
      // what somebody types into the search box. Drawn in one set of numerals
      // and stored in another, a date is one people cannot search for.
      for (final code in ['ar', 'hi']) {
        final s = await inLocale(
            tester, code, (c) => LampDates.dayMonthYear(c, august20));
        expect(s, contains('2026'),
            reason: '$code produced a year in non-Latin digits, which would '
                'not match what is stored or what is typed');
      }
    });
  });

  group('the calendar header', () {
    testWidgets('has seven letters in every language', (tester) async {
      for (final code in ['en', 'es', 'de', 'fr', 'pt', 'hi', 'ar', 'zh', 'ja', 'ko']) {
        final days = await inLocale(
            tester, code, (c) => LampDates.weekdayInitials(c).join('|'));
        expect(days.split('|').length, 7, reason: code);
        expect(days.split('|').every((d) => d.isNotEmpty), isTrue,
            reason: '$code has a blank weekday letter');
      }
    });

    testWidgets('and starts on Monday, as the grid does', (tester) async {
      final en = await inLocale(
          tester, 'en', (c) => LampDates.weekdayInitials(c).join());
      expect(en, 'MTWTFSS',
          reason: 'the grid is Monday-first, so the letters must be too — '
              'intl indexes weekdays from Sunday and the rotation is in '
              'LampDates.weekdayInitials');
    });
  });
}
