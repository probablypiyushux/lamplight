import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/plain_words.dart';

/// **ISSUE 16, round nine.** The rule with a mechanism behind it.
///
/// > *"You need to stop user from giving so much of information on how this app
/// > actually works! I need you to have this HCI computing law — no user should
/// > ever be so much traumatised by knowing the underroots of the technology of
/// > the app he is using."*
///
/// He then quoted Nielsen's second heuristic and the black-box principle and
/// wrote **"FOLLOW THIS RULES BADLY!"** — badly meaning strictly.
///
/// `plain_language_test.dart` already polices the app's *vocabulary*: words
/// like *codec* and *isolate* written deliberately into a sentence. This file
/// polices the other half, which is the half that actually bit him — text the
/// app never wrote at all, arriving through `'$e'` and landing on screen at
/// whatever length the VM felt like.
///
/// Two tiers, on purpose:
///
/// 1. **The function.** Fed the real string from his screenshot, and a
///    selection of what Android throws, and the app's own sentences. It must
///    refuse the first two and pass the third.
/// 2. **The source.** No screen may put a bare exception into a message field
///    again. Sanitising fifteen call sites is worth nothing if the sixteenth
///    is written next week by somebody who never read this.
void main() {
  group('the sanitiser itself', () {
    test('the exact text from his screenshot never reaches a person', () {
      // Trimmed, but this is the shape and the opening is verbatim. The real
      // one ran to about two hundred of these lines.
      const asShown =
          'Invalid argument(s): Illegal argument in isolate message: object is '
          "unsendable - Library:'dart:isolate' Class: _Timer@1026248 (see "
          'restrictions listed at `SendPort.send()` documentation for more '
          "information)\n"
          " <- Instance of 'Vault' (from package:lamplight/core/vault/vault.dart)\n"
          " <- Instance of 'LamplightApp' (from package:lamplight/app.dart)\n"
          " <- Instance of '_FocusScopeWithExternalFocusNode'";

      final shown = plainFailure(
        _Raw(asShown),
        fallback: 'The backup could not be saved.',
        andThen: 'Nothing was lost.',
      );

      expect(shown, 'The backup could not be saved. Nothing was lost.');
      for (final leak in [
        'isolate',
        'Instance of',
        'package:',
        'SendPort',
        '_Timer',
        'Vault',
      ]) {
        expect(shown, isNot(contains(leak)),
            reason: '"$leak" reached the user');
      }
    });

    test('what Android actually throws is refused', () {
      const platform = [
        'PlatformException(io, EACCES permission denied, null, null)',
        'MissingPluginException(No implementation found for method x)',
        'FileSystemException: Cannot open file, path = /data/user/0/x '
            '(OS Error: No such file or directory, errno = 2)',
        'SqliteException(11): database disk image is malformed',
        'Bad state: Stream has already been listened to.',
        'type \'Null\' is not a subtype of type \'String\'',
      ];
      for (final raw in platform) {
        expect(
          plainFailure(_Raw(raw), fallback: 'That did not work.'),
          startsWith('That did not work.'),
          reason: 'this one got through: $raw',
        );
      }
    });

    test("the app's own sentences pass through unaltered", () {
      // Rule 3 of PLAN.md §7.0-C-i: a promise the user is owed stays. These
      // are all promises or plain facts, and replacing them with "that did not
      // work" would make the app less honest, not more polished.
      const ours = [
        'That passcode is not right.',
        'This backup does not contain a vault. It may have been made by a '
            'different app.',
        'Your phone is holding Lamplight back to save battery.',
        'There is not enough space on this phone to open that.',
      ];
      for (final sentence in ours) {
        expect(
          plainFailure(_Raw(sentence), fallback: 'Something went wrong.'),
          sentence,
        );
      }
    });

    test('a PlainlySaid exception is taken at its word', () {
      expect(
        plainFailure(_Ours('Your notes are back as they were.'),
            fallback: 'unused'),
        'Your notes are back as they were.',
      );
    });

    test('a sentence that runs on is treated as a dump', () {
      // 160 characters is two lines on his tablet. Past that it is not a
      // sentence any more, whatever it is made of.
      final long = '${'A quiet true sentence about your notes. ' * 5}.';
      expect(long.length, greaterThan(160));
      expect(
        plainFailure(_Raw(long), fallback: 'That did not work.'),
        startsWith('That did not work.'),
      );
    });
  });

  group('and no screen may bypass it', () {
    test('nothing assigns a bare exception to a message the user reads', () {
      final offenders = <String>[];
      // `_error` is this app's universal name for "the line shown under the
      // form". Anything assigned to one is on screen by definition.
      final bare = RegExp(
        r"""_error\s*=\s*(?:'\$(?:e|error|err)'|\$?(?:e|error|err)\.toString\(\))""",
      );

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        for (final match in bare.allMatches(source)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line — ${match.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These put a raw exception in front of the user. Wrap them in '
            'plainFailure(), and give it a fallback that names what failed in '
            'the words the person would use. See core/plain_words.dart.\n'
            '${offenders.join('\n')}',
      );
    });
  });
}

/// An exception whose `toString` is whatever the test needs. Stands in for the
/// platform, which is where all of this comes from.
class _Raw implements Exception {
  const _Raw(this._text);
  final String _text;
  @override
  String toString() => _text;
}

class _Ours implements Exception, PlainlySaid {
  const _Ours(this.plainMessage);
  @override
  final String plainMessage;
  @override
  String toString() => 'Ours: $plainMessage';
}
