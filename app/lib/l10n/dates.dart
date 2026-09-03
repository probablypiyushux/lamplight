import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Every date and time the app says out loud, in the reader's own language.
///
/// ══ WHY THIS FILE EXISTS ════════════════════════════════════════════════════
///
/// > *"while localisation remember also the dates and everything should
/// > change!"* — 29 August 2026
///
/// He is right, and it was worse than one oversight. The twelve English month
/// names were written out **eight separate times** — in `day_header.dart`,
/// `day_screen.dart`, `calendar_sheet.dart` twice, `date_wheel.dart`,
/// `year_grid.dart`, `revisions_sheet.dart`, `folders_screen.dart` and
/// `plain_export.dart` — each a `static const` list of strings. So the app was
/// not only untranslatable in its dates, it had eight places to forget.
///
/// This is the one place now, and it is built on `intl`'s own locale data
/// rather than on lists of our own. That matters for far more than the words:
///
///  * **The order is not the same everywhere.** *20 August* is right for
///    English and Hindi; German wants *20. August*; Japanese and Chinese put
///    the year first and the day last — *8月20日*. A list of translated month
///    names glued to `${date.day} $month` produces something a reader
///    recognises as foreign in exactly the way he asked this app not to be.
///  * **Nor is the clock.** English and Hindi speakers here read 12-hour time;
///    German and French read 24-hour. `intl` knows which.
///  * **Nor does the week start on Monday.** It does in most of Europe and in
///    India; the calendar grid asks `intl` rather than assuming.
///
/// ══ THE ONE THING THIS DELIBERATELY DOES NOT DO ═════════════════════════════
///
/// **It never localises the digits.** Arabic and Hindi both have their own
/// numerals — ٢٠ and २० — and `intl` will use them for `ar` if asked. Lamplight
/// asks for Latin digits everywhere, because a day in this app is also a
/// **filename** in the readable export, a key in the database, and the thing
/// somebody types into the search box. A date drawn in one set of numerals and
/// stored in another is a date people cannot search for.
///
/// That is a deliberate narrowing, not an omission, and it is the same
/// reasoning as `safe_name.dart`: what is displayed and what is used have to
/// agree.
class LampDates {
  const LampDates._();

  /// Set up once, before the first frame.
  ///
  /// `intl`'s date symbols are loaded per locale and a `DateFormat` for a locale
  /// that has not been initialised throws. Doing it at startup for every locale
  /// costs a few hundred kilobytes of resident data and removes a whole class
  /// of "works in English, throws in Japanese" bug.
  static Future<void> prepare() => initializeDateFormatting();

  /// The BCP-47 tag `intl` should format for.
  ///
  /// `Localizations.localeOf` rather than the settings value, because it is the
  /// locale the app actually **resolved** to — somebody whose phone is set to a
  /// language Lamplight does not have gets English words, and their dates have
  /// to match the words rather than the phone.
  static String _tag(BuildContext context) {
    final locale = Localizations.localeOf(context);
    // ── The app's English is British, and CLDR's plain `en` is American ────
    //
    // `DateFormat.MMMMd('en')` returns *August 20*. Every date this app has
    // ever drawn has been *20 August*, and the rest of its English is British
    // too — "colour", "Readable copy", "Back up". Falling to `en_US` here would
    // have quietly reordered every date in the app as a side effect of
    // localising it, which is the opposite of what was asked for.
    if (locale.languageCode == 'en' &&
        (locale.countryCode == null || locale.countryCode!.isEmpty)) {
      return 'en_GB';
    }
    return locale.toLanguageTag();
  }

  /// Arabic-Indic and Devanagari digits, mapped back to ASCII.
  ///
  /// ══ WHY THE DIGITS ARE PULLED BACK AND THE WORDS ARE NOT ══════════════════
  ///
  /// `intl` formats an Arabic date as `٢٠ أغسطس ٢٠٢٦`, using Arabic-Indic
  /// numerals, and that is genuinely what CLDR says Arabic readers expect. It
  /// is still wrong **here**, for a reason that is about this app rather than
  /// about Arabic:
  ///
  /// A day in Lamplight is not only something to read. It is a **filename** in
  /// the readable export, a key in the encrypted database, and the thing
  /// somebody types into the search box. Drawn in one set of numerals and
  /// stored in another, a date becomes one its owner cannot search for — and
  /// search failing silently in a non-Latin script is a bug this project has
  /// already shipped once, when `\w` threw away every Devanagari word.
  ///
  /// So the words are the language's and the digits are the vault's. That is a
  /// deliberate narrowing, and it is the same rule `safe_name.dart` follows:
  /// what is shown and what is used have to agree.
  static String _latinDigits(String s) {
    var out = s;
    for (var i = 0; i < 10; i++) {
      out = out
          .replaceAll(String.fromCharCode(0x0660 + i), '$i') // Arabic-Indic
          .replaceAll(String.fromCharCode(0x06F0 + i), '$i') // Extended
          .replaceAll(String.fromCharCode(0x0966 + i), '$i'); // Devanagari
    }
    return out;
  }

  // ══ THE TWO THAT TAKE A TAG INSTEAD OF A CONTEXT ══════════════════════════
  //
  // The readable export runs off the widget tree on purpose — it streams
  // straight to a document provider and must not be tied to a screen that
  // could be disposed halfway through — so it cannot call
  // `Localizations.localeOf`. It is handed a tag by the screen that started it.
  //
  // Deliberately only two, and both used from exactly one place. Everything
  // that has a context uses the context, so there is no second way to get a
  // date that could quietly disagree with the first.

  /// Formats with [build], falling back to no locale if it is not loaded.
  ///
  /// ══ WHY THE EXPORT MAY NEVER THROW OVER A DATE ═══════════════════════════
  ///
  /// `DateFormat` throws `LocaleDataException` for a locale whose symbols have
  /// not been initialised. In the app that cannot happen — `main` awaits
  /// [prepare] before the first frame — but the readable export is also reached
  /// from tests and could one day be reached from an isolate, and neither is
  /// guaranteed to have run it.
  ///
  /// Somebody exporting their entire journal must not lose it because a date
  /// could not be formatted. The fallback is `DateFormat` with no locale, which
  /// is always available and produces the same English the app produced before
  /// any of this existed — a worse date, and a complete export.
  static String _orDefault(
    DateFormat Function(String? locale) build,
    String locale,
    DateTime at,
  ) {
    try {
      return _latinDigits(build(locale).format(at));
    } on Exception {
      return _latinDigits(build(null).format(at));
    }
  }

  /// `Thursday, 20 August 2026`, for a caller that has no context.
  static String longDateIn(String locale, DateTime date) =>
      _orDefault(DateFormat.yMMMMEEEEd, locale, date);

  /// `14:20`, for a caller that has no context.
  static String timeIn(String locale, DateTime at) =>
      _orDefault(DateFormat.jm, locale, at);

  /// `20 August` — the day and month, without the year.
  ///
  /// The day header's own line, for a date in the current year. In Japanese and
  /// Chinese this comes back as `8月20日`, which is the whole point.
  static String dayAndMonth(BuildContext context, DateTime date) =>
      _latinDigits(DateFormat.MMMMd(_tag(context)).format(date));

  /// `20 August 2026`.
  static String dayMonthYear(BuildContext context, DateTime date) =>
      _latinDigits(DateFormat.yMMMMd(_tag(context)).format(date));

  /// `Thursday, 20 August 2026` — the whole thing, for a screen reader.
  static String full(BuildContext context, DateTime date) =>
      _latinDigits(DateFormat.yMMMMEEEEd(_tag(context)).format(date));

  /// `August 2026` — the calendar's own heading.
  static String monthAndYear(BuildContext context, DateTime date) =>
      _latinDigits(DateFormat.yMMMM(_tag(context)).format(date));

  /// `August` on its own, for the year grid and the wheels.
  static String monthName(BuildContext context, int month) =>
      _latinDigits(DateFormat.MMMM(_tag(context)).format(DateTime(2000, month)));

  /// `Aug` — where a full month name will not fit.
  static String shortMonth(BuildContext context, int month) =>
      _latinDigits(DateFormat.MMM(_tag(context)).format(DateTime(2000, month)));

  /// `14:20`, or `2:20 PM` where that is what people read.
  static String time(BuildContext context, DateTime at) =>
      _latinDigits(DateFormat.jm(_tag(context)).format(at));

  /// `Thursday` — the weekday on its own, for the strip beside the date.
  static String weekdayName(BuildContext context, DateTime date) =>
      _latinDigits(DateFormat.EEEE(_tag(context)).format(date));

  /// The seven letters over a calendar grid, starting on [firstWeekday].
  ///
  /// Narrow forms — `M T W T F S S` in English, `月 火 …` in Japanese. Some
  /// languages repeat a letter and that is correct rather than a bug: English
  /// has two Ts and two Ss and nobody is confused, because position carries the
  /// meaning and the letter only confirms it.
  static List<String> weekdayInitials(BuildContext context) {
    final symbols = DateFormat(null, _tag(context)).dateSymbols;
    final narrow = symbols.NARROWWEEKDAYS;
    // `intl` indexes weekdays from Sunday; `DateTime.weekday` counts Monday as
    // 1. The calendar grid is Monday-first, so the list is rotated once here
    // rather than at every call site.
    return [for (var i = 1; i <= 7; i++) narrow[i % 7]];
  }
}
