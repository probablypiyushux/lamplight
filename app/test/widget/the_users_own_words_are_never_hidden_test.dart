import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **The rule that three separate bugs were each a violation of.**
///
/// `LinkedText` is the only widget in this app that draws a person's own
/// writing — the body of an entry, the caption under a photograph, the words
/// typed against an album. It is never used for a label, a heading, or anything
/// the app composed itself. That makes it a reliable marker for *user content*,
/// and it is what this test is built on.
///
/// On 3 September 2026, **all three** of its call sites sat inside a
/// `Semantics(..., excludeSemantics: true)` whose `label` named only the kind of
/// thing and the time it happened. `excludeSemantics` drops every descendant, so
/// what somebody using TalkBack actually got was:
///
/// ```
/// Entry at 12:21. Tap to edit.
/// Photo, 12:21.
/// 6 photos, 12:21.
/// ```
///
/// The times they had written at, and not one word of what they wrote.
///
/// Two of the three were found an hour apart — the first by reading the
/// accessibility tree of a real day on the tablet, the second by an audit that
/// went looking for the same shape once the first was known. **The second is why
/// this file exists rather than a third fix.** A defect found twice in one
/// morning in two sibling files will be introduced a third time by whoever adds
/// the next kind of block, and a rule nobody can see is a rule that holds only
/// while somebody remembers it.
///
/// `attachment_blocks.dart` also had the rule written down four lines from the
/// violation — *"the words under a photograph or a recording are the user's own
/// writing as much as an entry is"* — while the code did the opposite. Round
/// seventeen learned that lesson once already, in `day_stream.dart`: **when a
/// comment states a rule, check that the code implements that rule and not a
/// neighbouring one.**
///
/// ── What this test does and does not say ─────────────────────────────────
///
/// It does **not** ban `excludeSemantics`. There are forty-seven uses of it in
/// `lib/` and nearly all are right: a switch, a tile, a circular icon button —
/// the label carries everything, and letting the children through would announce
/// the same thing three times. `_JumpButton` in `day_stream.dart` is the model
/// of correct use.
///
/// It says one narrow thing: **where the user's own words are drawn, they must
/// also be reachable.** `value:` is the slot Flutter and TalkBack both mean by
/// "the content of this thing", and it is chosen over folding the text into
/// `label` so that no English sentence has to be bolted onto ten localised
/// strings.
void main() {
  test("every place the user's own writing is drawn also announces it", () {
    // How far above a `LinkedText(` to look for the Semantics enclosing it.
    // Generous: the three real cases sit 40–60 lines below their `Semantics(`,
    // because a block draws a rail, a timestamp and a picture first.
    const window = 140;

    final failures = <String>[];

    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      // The widget's own definition, which naturally mentions its own name.
      if (path.endsWith('design/linked_text.dart')) continue;

      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // A call site, not a mention of the name in prose.
        if (!lines[i].contains('LinkedText(')) continue;
        if (lines[i].trimLeft().startsWith('//')) continue;

        // Walk back to the nearest enclosing `Semantics(` and read what it set.
        var excluded = false;
        var hasValue = false;
        for (var j = i; j >= 0 && i - j < window; j--) {
          final l = lines[j];
          if (l.contains('excludeSemantics: true')) excluded = true;
          if (l.contains('value:')) hasValue = true;
          if (l.contains('return Semantics(')) break;
        }

        if (excluded && !hasValue) {
          failures.add('$path:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: "These draw the user's own writing inside a Semantics node that "
          'excludes its children, and set no `value:` — so a screen reader '
          'announces the timestamp and never the words.\n'
          'Add `value:` to the enclosing Semantics, as entry_block.dart does.\n'
          '${failures.join('\n')}',
    );
  });

  test('the marker widget is still the marker, so this test means something',
      () {
    // If `LinkedText` ever stops being the one widget that draws user writing,
    // the check above quietly starts checking nothing.
    var sites = 0;
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.replaceAll(r'\', '/').endsWith('design/linked_text.dart')) {
        continue;
      }
      for (final l in f.readAsLinesSync()) {
        if (l.contains('LinkedText(') && !l.trimLeft().startsWith('//')) {
          sites++;
        }
      }
    }
    expect(
      sites,
      greaterThan(0),
      reason: 'No LinkedText call sites found, so the check above is vacuous. '
          'Either the widget was renamed, or user writing is now drawn some '
          'other way — in which case teach this test the new marker.',
    );
  });
}
