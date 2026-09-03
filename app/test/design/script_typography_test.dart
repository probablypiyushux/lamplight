import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/tokens.dart';

/// Type that is set for the script actually being read.
///
/// > *"as the language is changed! i want you to use the best font for them
/// > too! the change should be subtle! unnoticed! par it improves the overall
/// > feel to 200%"* — 28 August 2026
///
/// ══ WHY THIS IS TESTABLE AT ALL, GIVEN THAT IT IS MEANT TO BE INVISIBLE ═════
///
/// Nothing here checks that the result looks good — no test can. What it checks
/// is the two mechanical facts underneath, both of which are silently wrong by
/// default and neither of which anybody would notice from a laptop:
///
///  1. **The font order.** Han codepoints are shared between Chinese, Japanese
///     and Korean and are drawn differently in each. The codepoint does not say
///     which language it is, so whichever family is first in the fallback list
///     wins — and a Japanese reader given the Simplified Chinese forms sees
///     their own language set subtly and persistently wrong.
///
///  2. **The leading.** Devanagari hangs matras above and below, Arabic stacks
///     marks, CJK fills the em square. At Latin's line height all three crowd.
void main() {
  group('the fallback list is reordered for the reader', () {
    test('Japanese asks for the Japanese forms first', () {
      expect(scriptFallbackFor(const Locale('ja')).first, 'Noto Sans CJK JP');
    });

    test('Korean asks for Korean', () {
      expect(scriptFallbackFor(const Locale('ko')).first, 'Noto Sans CJK KR');
    });

    test('Chinese asks for Simplified, and Taiwan for Traditional', () {
      expect(scriptFallbackFor(const Locale('zh')).first, 'Noto Sans CJK SC');
      expect(scriptFallbackFor(const Locale('zh', 'TW')).first,
          'Noto Sans CJK TC');
      expect(scriptFallbackFor(const Locale('zh', 'HK')).first,
          'Noto Sans CJK TC');
    });

    test('Arabic and Hindi ask for their own scripts', () {
      expect(scriptFallbackFor(const Locale('ar')).first, 'Noto Sans Arabic');
      expect(
          scriptFallbackFor(const Locale('hi')).first, 'Noto Sans Devanagari');
    });

    test('a Latin locale is left exactly as it was', () {
      // Reordering CJK families for a Spanish reader changes nothing anybody
      // can see, so it is not done — churn without benefit is how a subtle
      // system acquires a bug nobody can explain.
      for (final code in ['en', 'es', 'de', 'fr', 'pt']) {
        expect(scriptFallbackFor(Locale(code)), kScriptFallback,
            reason: '$code should not have been touched');
      }
    });

    test('following the phone changes nothing', () {
      // `settings.locale` is null in the common case. Null has to behave
      // exactly as this did before it was locale-aware at all.
      expect(scriptFallbackFor(null), kScriptFallback);
    });
  });

  group('nothing can become unrenderable by choosing a language', () {
    test('every family survives every reordering', () {
      // The whole safety property. Somebody with the app in Japanese who
      // writes one line of Hindi must still get Devanagari — it is later in
      // the list, not absent from it.
      for (final code in ['ja', 'ko', 'zh', 'ar', 'hi', 'en']) {
        final list = scriptFallbackFor(Locale(code));
        expect(list.toSet(), kScriptFallback.toSet(),
            reason: '$code lost or invented a family');
        expect(list.length, kScriptFallback.length,
            reason: '$code duplicated a family');
      }
    });

    test('the catch-all stays last', () {
      for (final code in ['ja', 'ko', 'zh', 'ar', 'hi']) {
        expect(scriptFallbackFor(Locale(code)).last, 'Noto Sans',
            reason: 'the family Android resolves for anything unmatched has '
                'to remain the final word');
      }
    });
  });

  group('leading follows the script', () {
    test('scripts with marks above and below get more room', () {
      expect(lineHeightScaleFor(const Locale('hi')), greaterThan(1.0));
      expect(lineHeightScaleFor(const Locale('ar')), greaterThan(1.0));
      expect(lineHeightScaleFor(const Locale('ja')), greaterThan(1.0));
    });

    test('Devanagari gets the most, because it needs the most', () {
      // Matras above the shirorekha and below the baseline, on the same line.
      expect(lineHeightScaleFor(const Locale('hi')),
          greaterThan(lineHeightScaleFor(const Locale('ja'))));
    });

    test('Latin is untouched, and so is following the phone', () {
      expect(lineHeightScaleFor(const Locale('en')), 1.0);
      expect(lineHeightScaleFor(null), 1.0);
    });

    test('and none of it is large enough to read as a layout change', () {
      // He asked for this to be unnoticed. A leading change big enough to see
      // when switching language is the opposite of the brief.
      for (final code in ['hi', 'ar', 'ja', 'ko', 'zh']) {
        expect(lineHeightScaleFor(Locale(code)), lessThan(1.2),
            reason: '$code would visibly reflow the page');
      }
    });
  });

  group('it actually reaches the theme', () {
    // Everything above tests the two functions. This is the wiring, which is
    // where a change like this normally dies unnoticed.
    TextStyle bodyFor(Locale? locale) => lamplightTheme(
          LamplightColors.dark,
          face: WritingFace.serif,
          locale: locale,
        ).textTheme.bodyLarge!;

    test('the Japanese theme prefers the Japanese family', () {
      expect(bodyFor(const Locale('ja')).fontFamilyFallback,
          contains('Noto Sans CJK JP'));
      final fallback = bodyFor(const Locale('ja')).fontFamilyFallback!;
      expect(fallback.indexOf('Noto Sans CJK JP'),
          lessThan(fallback.indexOf('Noto Sans CJK SC')));
    });

    test('the Hindi theme is set with more leading than the English one', () {
      final hi = bodyFor(const Locale('hi')).height!;
      final en = bodyFor(const Locale('en')).height!;
      expect(hi, greaterThan(en));
    });

    test('two locales do not share a cached theme', () {
      // The theme is cached by accent, face and now locale. Leaving the locale
      // out of the key would set Japanese in the Chinese forms for the life of
      // the process, depending only on which was asked for first.
      // Compared on the script families rather than on `.first`, which is the
      // *face's* own fallback — 'Noto Serif' here — and is the same for both.
      final ja = bodyFor(const Locale('ja')).fontFamilyFallback!;
      final ko = bodyFor(const Locale('ko')).fontFamilyFallback!;
      expect(ja.indexOf('Noto Sans CJK JP'),
          lessThan(ja.indexOf('Noto Sans CJK KR')));
      expect(ko.indexOf('Noto Sans CJK KR'),
          lessThan(ko.indexOf('Noto Sans CJK JP')));
    });

    test('and the system face, which has no family, is left alone', () {
      // `WritingFace.system` resolves every script the phone can draw on its
      // own. Attaching a fallback list to a null family is meaningless.
      final style = lamplightTheme(
        LamplightColors.dark,
        face: WritingFace.system,
        locale: const Locale('ja'),
      ).textTheme.bodyLarge!;
      // `fontFamily` is inherited from the base theme, so it is Roboto rather
      // than null. What must be absent is the *fallback list*: "whatever the
      // rest of your phone uses" means the platform resolves scripts, and a
      // list here would quietly override that with our opinion.
      expect(style.fontFamilyFallback, isNull);
    });
  });
}
