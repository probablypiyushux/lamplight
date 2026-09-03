import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/linked_text.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **ROUND FIFTEEN, ISSUE 11 — a link in your own writing.**
///
/// > *"if a text has a link – I want you to make that link look like a link
/// > text and works like a link if I tap that opens! (here text I mean is the
/// > text written by user)"*
///
/// Most of this file is about what is **not** a link, because in a journal
/// that is the harder half. An ordinary paragraph is full of things that look
/// like web addresses, and a page speckled with false links is worse than one
/// with a link you have to copy out by hand.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what is a link', () {
    test('an https address on its own', () {
      expect(findLinks('https://example.com'),
          [const LinkRun(text: 'https://example.com', url: 'https://example.com')]);
    });

    test('one in the middle of a sentence, with the sentence kept', () {
      expect(
        findLinks('read this https://example.com/a today'),
        [
          const PlainRun('read this '),
          const LinkRun(
              text: 'https://example.com/a', url: 'https://example.com/a'),
          const PlainRun(' today'),
        ],
      );
    });

    test('www. gets a scheme, and only in the destination', () {
      final runs = findLinks('www.example.com');
      expect(runs.single, isA<LinkRun>());
      final link = runs.single as LinkRun;
      expect(link.text, 'www.example.com', reason: 'what is on the page');
      expect(link.url, 'https://www.example.com', reason: 'where it goes');
    });

    test('several in one paragraph', () {
      final runs = findLinks('a https://one.example b www.two.example c');
      expect(runs.whereType<LinkRun>().length, 2);
    });
  });

  group('what is not a link, which is the harder half', () {
    for (final ordinary in [
      'I had a good day, e.g. the walk.',
      'Went to the shop.Then came home.',
      'i.e. nothing much happened',
      'The file was scan.pdf and it opened fine.',
      'It cost 12.50 and was worth it.',
      'bbc.co.uk was on the telly',
    ]) {
      test('"$ordinary"', () {
        expect(findLinks(ordinary).whereType<LinkRun>(), isEmpty,
            reason: 'a bare domain is not recognised on purpose. A link that '
                'is missed costs a tap; a paragraph speckled with false links '
                'costs the page');
      });
    }

    test('a scheme with nothing after it', () {
      expect(findLinks('https://').whereType<LinkRun>(), isEmpty);
      expect(findLinks('http://').whereType<LinkRun>(), isEmpty);
    });
  });

  group('where the address stops', () {
    test('a full stop belongs to the sentence', () {
      final runs = findLinks('see https://example.com/x. Then home.');
      expect((runs[1] as LinkRun).text, 'https://example.com/x');
    });

    test('so does a comma, a colon and a question mark', () {
      for (final mark in [',', ':', '?', '!', ';']) {
        final runs = findLinks('at https://example.com$mark and');
        expect((runs[1] as LinkRun).text, 'https://example.com', reason: mark);
      }
    });

    test('a Japanese full stop does too', () {
      // The app speaks ten languages. A sentence in Japanese ends in 。 and a
      // URL followed by one is exactly the same situation as the Latin case.
      final runs = findLinks('これ https://example.com。 つぎ');
      expect((runs[1] as LinkRun).text, 'https://example.com');
    });

    test('an Arabic comma and question mark do too', () {
      expect((findLinks('هنا https://example.com، ثم')[1] as LinkRun).text,
          'https://example.com');
      expect((findLinks('هنا https://example.com؟')[1] as LinkRun).text,
          'https://example.com');
    });

    test('but a balanced bracket is part of the address', () {
      final runs = findLinks(
          'https://en.wikipedia.org/wiki/Lamp_(disambiguation) and');
      expect((runs.first as LinkRun).text,
          'https://en.wikipedia.org/wiki/Lamp_(disambiguation)');
    });

    test('and an unbalanced one is not', () {
      final runs = findLinks('(see https://example.com/x) then');
      expect((runs[1] as LinkRun).text, 'https://example.com/x');
    });

    test('a path in Devanagari survives', () {
      // `\\w` in a Dart RegExp is ASCII-only even with the unicode flag, which
      // is the bug that made search return nothing in every non-Latin script
      // until 28 August. It would have truncated this address at the scheme.
      final runs = findLinks('https://example.com/लैंपलाइट');
      expect((runs.single as LinkRun).text, 'https://example.com/लैंपलाइट');
    });
  });

  group('on the page', () {
    Future<void> pump(WidgetTester tester, String text) => tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            theme: lamplightTheme(LamplightColors.dark),
            home: Scaffold(body: LinkedText(text)),
          ),
        );

    testWidgets('writing with no link is a plain Text, not a rich one',
        (tester) async {
      await pump(tester, 'Rained all afternoon so we stayed in.');
      final widget = tester.widget<Text>(find.byType(Text));
      expect(widget.textSpan, isNull,
          reason: 'Text.rich sets a paragraph subtly differently, and a '
              'journal should not change how it sets one depending on whether '
              'it happens to mention a website');
    });

    testWidgets('a link is coloured and underlined, not only coloured',
        (tester) async {
      await pump(tester, 'here https://example.com now');
      final widget = tester.widget<Text>(find.byType(Text));
      final spans = (widget.textSpan! as TextSpan).children!.cast<TextSpan>();
      final link = spans.firstWhere((s) => s.text!.startsWith('https'));
      expect(link.style!.decoration, TextDecoration.underline,
          reason: 'ACCESSIBILITY.md does not allow colour to be the only way '
              'a thing is marked');
      expect(link.style!.color, isNotNull);
    });

    testWidgets('tapping one hands the address to the system', (tester) async {
      const channel = MethodChannel('lamplight/documents');
      String? asked;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'openUrl') {
          asked = (call.arguments as Map)['url'] as String?;
          return true;
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      await pump(tester, 'go www.example.com now');
      final widget = tester.widget<Text>(find.byType(Text));
      final spans = (widget.textSpan! as TextSpan).children!.cast<TextSpan>();
      final link = spans.firstWhere((s) => s.recognizer != null);
      (link.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pump();

      expect(asked, 'https://www.example.com',
          reason: 'the scheme is added on the way out, never on the page');
    });
  });
}
