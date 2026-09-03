import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **The rule `system_excursion.dart` states, made into a mechanism.**
///
/// That file opens by explaining why the excursion window is not a line at each
/// call site:
///
/// > *"The fix has to be impossible to forget. If it were a line at each call
/// > site, the seventh picker somebody adds in a year's time would not have it,
/// > and the symptom — 'I took a photo and the app closed and nothing was
/// > saved' — points nowhere near the cause."*
///
/// On 3 September 2026 the seventh picker was added — `pickTextFiles`, the way
/// into the journal importer that Android cannot refuse — and it did not have
/// it. The prediction was right down to the symptom pointing elsewhere: on the
/// tablet it looked like the vault locking because the tester was slow, and the
/// second attempt was made *faster* rather than correctly, because that is what
/// the evidence appeared to say.
///
/// The reason it happened is worth more than the fix. **The rule lived in a
/// comment, and a comment is a claim rather than a mechanism.** The sentence "a
/// new one cannot be written without it" was not true — nothing stopped one
/// being written without it, and one was. Round seventeen learned the same
/// thing in `day_stream.dart`: when a comment states a rule, check that the
/// code implements it. This is that lesson applied to the comment itself.
///
/// ── What is checked ──────────────────────────────────────────────────────
///
/// The list of methods that background this app is not maintained by hand,
/// because a hand-maintained list is the same failure one level up. It is read
/// out of `MainActivity.kt`: every `"name" ->` branch whose body calls
/// `startActivityForResult` genuinely sends the user to another app, and every
/// one of those must be invoked from Dart inside `SystemExcursion.around`.
///
/// So an eighth picker cannot pass this suite without the wrapper, and nobody
/// has to remember anything.
void main() {
  test('every platform call that leaves the app opens an excursion window', () {
    final kotlin = File(
      'android/app/src/main/kotlin/com/probablypiyush/lamplight/MainActivity.kt',
    ).readAsStringSync();

    // Each `"name" ->` branch runs until the next one begins.
    final branches = RegExp(r'"([A-Za-z]\w*)"\s*->')
        .allMatches(kotlin)
        .map((m) => (at: m.start, name: m.group(1)!))
        .toList();

    final launchers = <String>{};
    for (var i = 0; i < branches.length; i++) {
      final end = i + 1 < branches.length ? branches[i + 1].at : kotlin.length;
      if (kotlin
          .substring(branches[i].at, end)
          .contains('startActivityForResult')) {
        launchers.add(branches[i].name);
      }
    }

    expect(
      launchers,
      isNotEmpty,
      reason: 'No activity-launching methods were found at all, which means '
          'this test is reading the Kotlin wrongly and checking nothing. Fix '
          'the parsing rather than deleting the test.',
    );

    // ── Comments are stripped first, and that is not tidiness ────────────
    //
    // The first version of this test passed while the bug was still in the
    // file, because the walk backwards from a method name runs until the
    // previous `;` or `{` — and above `pickTextFiles` sits a long comment
    // explaining the wrapper, which contains the words `SystemExcursion
    // .around`. The test was reading its own explanation and calling it
    // evidence.
    //
    // Which is the same failure it exists to catch, one level up: a claim in
    // prose standing in for a fact about the code.
    String code(String src) {
      final noBlocks = src.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ');
      return noBlocks
          .split('\n')
          .map((l) => l.replaceAll(RegExp(r'//.*$'), ''))
          .join('\n');
    }

    final sources = <String>[
      for (final f in Directory('lib/core/platform').listSync())
        if (f is File && f.path.endsWith('.dart')) code(f.readAsStringSync()),
    ];

    /// The statement containing [at] — back to the previous `;` or `{`.
    String statement(String src, int at) {
      final start = [src.lastIndexOf(';', at), src.lastIndexOf('{', at)]
          .reduce((a, b) => a > b ? a : b);
      return src.substring(start + 1, at + 1);
    }

    // Helpers that hold the window on behalf of their callers. `pickPhotos`
    // and `pickDocuments` are one-line members that hand the method name to
    // `_invokeMany`, and `_invokeMany` opens the window — good code, since the
    // wrapper is still in exactly one place.
    //
    // **Deliberately a list of one.** Anything added here is a place the rule
    // is being taken on trust again, so it should cost a conversation.
    const holdsTheWindow = ['_invokeMany'];

    bool isWrapped(String name) {
      final literal = "'$name'";
      for (final src in sources) {
        var i = src.indexOf(literal);
        while (i != -1) {
          final st = statement(src, i);
          if (st.contains('SystemExcursion.around')) return true;
          if (holdsTheWindow.any(st.contains)) return true;
          i = src.indexOf(literal, i + 1);
        }
      }
      return false;
    }

    final unwrapped = launchers.where((n) => !isWrapped(n)).toList()..sort();

    expect(
      unwrapped,
      isEmpty,
      reason: 'These platform methods launch another app, so the vault must be '
          'told the backgrounding was ours — otherwise it locks while the '
          'person is choosing a file, and they come back to a passcode screen '
          'with their work gone.\n'
          'Wrap the Dart call in SystemExcursion.around. See '
          'lib/core/platform/system_excursion.dart.\n'
          'Unwrapped: $unwrapped',
    );
  });
}
