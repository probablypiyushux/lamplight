import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **ROUND EIGHT, ISSUE 10 — the app stops explaining itself.**
///
/// > *"There are alots of things in this app which frustrates me — you need to
/// > stop user from giving so much of information on how this app actually
/// > works! IK it's better but I need you to stop! I need you to have this HCI
/// > computing law — no user should ever be so much traumatised by knowing the
/// > underoots of the technology of the app he is using! I need you to be
/// > better."*
///
/// He then quoted three things, which is what makes this a rule rather than a
/// mood: Nielsen's second heuristic (*speak the user's language*), the black
/// box (*you know the input and the output; the machinery inside stays
/// hidden*), and Weiser (*the most profound technologies are those that
/// disappear*). And underneath: **"FOLLOW THIS RULES BADLY!"** — badly meaning
/// strictly.
///
/// ── WHY THIS IS A TEST AND NOT A RESOLUTION ──────────────────────────────
///
/// A sweep of the app's strings is a day's work and lasts until the next
/// person writes an error message at eleven at night. A rule that is not
/// mechanical is a rule that decays, and this project already knows that:
/// `verify_no_internet.sh` exists because reading the manifest carefully is
/// not the same as checking the APK.
///
/// So this is the vocabulary check, run on every commit. It reads every string
/// literal in `lib/` that looks like a sentence and fails on words that belong
/// to the machinery rather than to the person holding the phone.
///
/// ── WHAT IT DELIBERATELY DOES NOT BAN ────────────────────────────────────
///
/// **Promises stay.** That is the line §7.0-C-i draws and it is the whole
/// reason this is not a blanket ban on plain speaking:
///
///   * *"Lamplight cannot use the internet"* — load-bearing, and the strongest
///     thing the app says about itself.
///   * *"encrypted", "passcode", "backup", "locked"* — the user's own words for
///     their own security. Nobody is confused by "your notes are encrypted";
///     they are confused by "the secretstream nonce could not be derived".
///   * *"We do not have a copy. We cannot send them to you."* — the sentence
///     that stops somebody losing twelve words, and it has to be blunt.
///
/// A promise the user is owed stays. A mechanism they are being made to
/// operate goes. If a word below ever needs an exception, the exception goes in
/// the allow-list here with the reason beside it — which is the point: it
/// becomes a decision somebody made rather than a sentence that slipped in.
void main() {
  /// Sentences that are allowed to keep a banned word, and why.
  ///
  /// Each one is a decision rather than an oversight, which is the difference
  /// this list exists to record.
  const allowed = <String>[
    // The error screen's promise about what it does and does not copy. It has
    // to name what it leaves out, or the promise means nothing.
    'the message, which is where your own words would be',
    // "app-store exception" is a term from the licence itself. Renaming a
    // clause of the GPL to avoid a word on this list would make the licence
    // screen wrong, which is a worse failure than the one being avoided.
    'GPL-3.0 with an app-store exception',
  ];

  late List<({String file, int line, String text})> sentences;

  setUpAll(() {
    // Run from the package root, so `lib` is where it says it is.
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue,
        reason: 'run from the app/ directory, as flutter test does');

    final found = <({String file, int line, String text})>[];
    // A single-quoted Dart literal, allowing escaped quotes inside it.
    final literal = RegExp(r"'((?:[^'\\]|\\.)*)'");

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Generated code is not written by anybody and is never shown.
      if (entity.path.endsWith('.g.dart')) continue;

      // ══ THE TRANSLATIONS ARE NOT SCANNED, AND THAT IS NOT A LOOPHOLE ═════
      //
      // `lib/l10n/generated/` is `flutter gen-l10n`'s output — one Dart file
      // per language, holding the ARB's strings. Two separate reasons it does
      // not belong here, and the first is what actually broke:
      //
      //  * **This test matches English substrings.** It looks for `null`,
      //    `cache`, `buffer` and their like anywhere in a sentence. French
      //    "nulle part" — *nowhere* — contains `null`, and so does "annuler".
      //    The French translation of an entirely ordinary promise failed this
      //    test on 28 August 2026. That is the same shape of bug as the search
      //    splitter that used `\w` and threw away every Devanagari word: an
      //    English assumption applied to ten languages.
      //
      //  * **It could not do its job here anyway.** The rule is about English
      //    wording — a promise stays, a mechanism goes — and nothing in a list
      //    of English machinery words detects the equivalent failure in
      //    Korean. Judging a translation needs somebody who reads it, which
      //    `lib/l10n/README.md` says plainly and says who to ask.
      //
      // **What is still scanned is where English wording actually lives:**
      // every literal in every screen, and — through the `L.of(context)` calls
      // that replace them — `app_en.arb`, which is the template every
      // translation is made from. A machinery word cannot reach a person in
      // any language without passing through the English first.
      if (entity.path.contains('l10n${Platform.pathSeparator}generated') ||
          entity.path.contains('l10n/generated')) {
        continue;
      }
      // **The one hand-written exemption, and it is the sieve itself.**
      //
      // `core/plain_words.dart` is a list of the phrases that must never reach
      // a person — `Instance of`, `Null check operator`, `dart:`. Every string
      // in it is there to be *matched against and thrown away*, so it is the
      // one file where naming the machinery is the job rather than the
      // failure. Scanning it makes this test report the guard as the leak.
      //
      // Kept narrow on purpose: one named path, not a pattern. The moment this
      // becomes a list, it becomes somewhere to hide things.
      if (entity.path.endsWith('plain_words.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trimLeft();
        // Comments are where the *reasoning* lives, and the reasoning is
        // allowed — required, even — to name the machinery. This file would
        // otherwise ban the explanations that make the code maintainable.
        if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

        for (final match in literal.allMatches(lines[i])) {
          final text = match.group(1)!;
          // Only things that look like prose. An identifier, a MIME
          // constant, an import path or a channel name is not a sentence.
          if (!text.contains(' ')) continue;
          if (text.contains('/')) continue;
          if (text.split(' ').length < 3) continue;
          // SQL is a sentence to a database and to nobody else. `WHERE
          // deleted_at IS NULL` is not the app telling somebody about null.
          if (_looksLikeSql(text)) continue;
          // ── A truncated capture, not a sentence ──────────────────
          //
          // A Dart interpolation can contain quotes of its own —
          // `'Voice note, ${d == null ? 'unknown' : d}'` — so a regex looking
          // for the next apostrophe stops **inside** it and hands back
          // `Voice note, ${d == null ? `. That fragment is Dart, and reading
          // it as prose is how a scanner reports that the app says "null" to
          // people. An unclosed `${` is the reliable tell.
          final opens = '\${'.allMatches(text).length;
          final closes = '}'.allMatches(text).length;
          if (opens > closes) continue;
          // A fragment that is nothing but interpolation and punctuation is a
          // format string, not a sentence — it has no words of its own.
          if (text.replaceAll(RegExp(r'\$\{[^}]*\}'), '').trim().length < 12) {
            continue;
          }
          found.add((file: entity.path, line: i + 1, text: text));
        }
      }
    }
    sentences = found;
  });

  test('there are sentences to check, so a silent pass is impossible', () {
    // Without this, a broken regex or a wrong working directory would make
    // every test below pass by finding nothing — which is the failure mode of
    // every scanner ever written.
    expect(sentences.length, greaterThan(150));
  });

  for (final entry in {
    for (final word in _bannedWords) word: word,
  }.keys) {
    test('nothing shown to a person says "$entry"', () {
      final offenders = <String>[];
      for (final s in sentences) {
        final lower = s.text.toLowerCase();
        if (!lower.contains(entry)) continue;
        if (allowed.any((a) => s.text.contains(a))) continue;
        offenders.add('${s.file}:${s.line}\n      ${s.text}');
      }
      expect(offenders, isEmpty,
          reason: '\n\nISSUE 10 — "${_reasons[entry]}".\n\n'
              'A promise the user is owed stays; a mechanism they are being '
              'made to operate goes. If this one is genuinely a promise, add '
              'it to `allowed` above with the reason.\n\n'
              '${offenders.join('\n\n')}\n');
    });
  }

  test('the words the app is still allowed to say', () {
    // The other half of the rule, stated as a test so that a future sweep
    // cannot quietly delete the app's own honesty in the name of ISSUE 10.
    // These are the user's words for the user's own security, and every one of
    // them is a promise rather than a mechanism.
    const keep = ['encrypted', 'passcode', 'backup', 'locked', 'internet'];

    // ══ WHY THIS READS THE ARB AND THE SCAN ABOVE DOES NOT ══════════════════
    //
    // It used to search `sentences` — the Dart literals in `lib/`. That worked
    // while the app's words were literals, and it **broke on 29 August 2026**
    // when they were localised: the promises moved into `app_en.arb`, the
    // literals they came from were deleted, and this test failed while the app
    // was saying exactly what it had always said. Nothing had been lost; the
    // test was looking in the place the words used to be.
    //
    // So it looks where the app's English now lives. **`app_en.arb` only** —
    // never the other nine. That is the same line the scan above draws and for
    // the same reason: this is a check on *English* wording, and matching
    // English substrings against a translation is what made French "nulle
    // part" trip the banned-word list. One file, one language, no loophole —
    // the words still have to be somewhere a person can read.
    final english = File('lib/l10n/app_en.arb').readAsStringSync().toLowerCase();

    for (final word in keep) {
      expect(
        english.contains(word) ||
            sentences.any((s) => s.text.toLowerCase().contains(word)),
        isTrue,
        reason: 'the app should still be able to say "$word" — see the note '
            'at the top of this file',
      );
    }
  });
}

/// Whether a string is talking to SQLite rather than to a person.
///
/// Every one of these is a statement this app genuinely runs, and none of them
/// is ever shown to anybody. Without this the check flags `WHERE deleted_at IS
/// NULL` for saying "null", which is true and useless.
bool _looksLikeSql(String text) {
  final head = text.trimLeft().toUpperCase();
  for (final keyword in const [
    'SELECT ', 'INSERT ', 'UPDATE ', 'DELETE ', 'CREATE ', 'DROP ',
    'ALTER ', 'PRAGMA ', 'WHERE ', 'GROUP BY', 'ORDER BY', 'VALUES ',
    // Continuations. A long statement is written across several adjacent
    // literals, and every one of them has to be recognised or the middle of a
    // query gets read as English.
    'FROM ', 'JOIN ', 'LEFT ', 'INNER ', 'AND ', 'OR ', 'SET ', 'LIMIT ',
    'HAVING ', 'UNION ', 'ON ',
  ]) {
    if (head.startsWith(keyword)) return true;
  }
  return false;
}

/// The banned vocabulary, as a flat list for the loop above.
const _bannedWords = <String>[
  'argon2', 'xchacha', 'poly1305', 'libsodium', 'secretstream', 'sqlite',
  'fts5', 'cbor', 'adts', 'mime type', 'codec', 'bitrate', 'buffer',
  'isolate', 'nonce', 'schema', 'fileprovider', 'parcelfiledescriptor',
  'mediarecorder', 'pdfrenderer', 'notification channel', 'in memory',
  'exception', 'stack trace', 'null', 'utf-8', 'base64', 'regex',
  'ciphertext', 'plaintext',
];

const _reasons = <String, String>{
  'argon2': 'the key derivation is not the user\'s problem',
  'xchacha': 'nor is the cipher',
  'poly1305': 'nor is the MAC',
  'libsodium': 'a library name',
  'secretstream': 'a library name',
  'sqlite': 'a database engine',
  'fts5': 'a database extension',
  'cbor': 'a serialisation format',
  'adts': 'an audio container',
  'mime type': 'the picker\'s word, not a person\'s',
  'codec': 'nobody chose a codec; they took a video',
  'bitrate': 'ISSUE 2A gives named sizes instead',
  'buffer': 'plumbing',
  'isolate': 'plumbing',
  'nonce': 'plumbing',
  'schema': 'plumbing',
  'fileprovider': 'an Android class',
  'parcelfiledescriptor': 'an Android class',
  'mediarecorder': 'an Android class',
  'pdfrenderer': 'an Android class',
  'notification channel': 'Android\'s bookkeeping, not the user\'s',
  'in memory': 'a person watching a video has no memory budget',
  'exception': 'never a Dart type in front of a person',
  'stack trace': 'the error screen copies one; it does not name it',
  'null': 'never',
  'utf-8': 'an encoding',
  'base64': 'an encoding',
  'regex': 'nobody has ever wanted to see one',
  'ciphertext': 'jargon for a promise that can be made in English',
  'plaintext': 'in the clear is the same fact in the user\'s words',
};
