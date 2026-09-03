import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/entry_block.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **FAIL 5, found on hardware on 3 September 2026 — a person using a screen
/// reader could not read their own journal.**
///
/// `EntryBlock` wraps itself in `Semantics(..., excludeSemantics: true)`, and
/// that is the right call for the rail, the star and the timestamp: the time is
/// already in the label, and three extra nodes in front of every entry is worse
/// than none. But `excludeSemantics` drops **everything** underneath, and what
/// is underneath is `LinkedText(entry.body)`.
///
/// So the accessibility tree of a real day on a real tablet read:
///
/// ```
/// Entry at 12:21. Tap to edit.
/// Entry at 14:03. Tap to edit.
/// Entry at 19:40. Tap to edit.
/// ```
///
/// A list of the times somebody had written at, and not one word of what they
/// wrote. **The single thing this app is for, unreachable.**
///
/// It was invisible to every one of the 1,478 tests in this suite for a reason
/// worth writing down: **not one of them had ever called `getSemantics`.**
/// Every widget test here checks what is *drawn*. The tree is what a blind
/// person is handed instead of the drawing, and nothing was looking at it.
///
/// Same shape as the recovery-phrase ordering bug found an hour earlier: the
/// pixels right, the tree wrong. Both found by reading the tree on a device
/// rather than the screen.
///
/// **Do not delete `value:` from `EntryBlock` to tidy it.** It is the slot
/// Flutter and TalkBack both mean by "the content of this thing", and it is
/// chosen over appending to `label` precisely so that no English sentence has
/// to be bolted onto ten localised strings.
void main() {
  Entry entryWith(String? body, {String? marker}) => Entry(
        id: 'e1',
        createdAt: DateTime(2026, 9, 3, 12, 21).millisecondsSinceEpoch,
        createdOffsetMinutes: 330,
        updatedAt: DateTime(2026, 9, 3, 12, 21).millisecondsSinceEpoch,
        type: 'text',
        body: body,
        dayKey: '2026-09-03',
        marker: marker,
        isPinned: false,
      );

  Widget harness(Entry entry) => MaterialApp(
        // Every widget test in this project builds its own MaterialApp and
        // carries this block, because without it `L.of` returns null and the
        // generated `!` throws. `app_boots_test.dart` records what that cost
        // once.
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: EntryBlock(
            entry: entry,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );

  testWidgets('the words are in the tree, not only on the screen',
      (tester) async {
    final handle = tester.ensureSemantics();
    const words =
        'A quiet Tuesday. The rain stopped just long enough to walk to the '
        'end of the road and back.';

    await tester.pumpWidget(harness(entryWith(words)));
    await tester.pump();

    final node = tester.getSemantics(find.byType(EntryBlock));

    // The defect, stated as the thing it broke: a screen reader must be able
    // to reach the words. Asserted on the node's own content slot so it holds
    // however the block is later restructured, as long as the words come out.
    expect(
      node.value,
      contains('The rain stopped'),
      reason: 'The entry body must reach the accessibility tree. If this '
          'fails, a TalkBack user hears a timestamp and nothing else.',
    );

    // And the label still says what it is and how to open it.
    expect(node.label, contains('Tap to edit'));
    handle.dispose();
  });

  testWidgets('an empty entry says nothing rather than "null"', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(entryWith(null)));
    await tester.pump();

    final node = tester.getSemantics(find.byType(EntryBlock));
    expect(node.value, isEmpty);
    expect(node.value, isNot(contains('null')));
    handle.dispose();
  });

  testWidgets('a marked entry still reads its words', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(entryWith('The one that mattered.', marker: 'star')),
    );
    await tester.pump();

    final node = tester.getSemantics(find.byType(EntryBlock));
    // Both channels survive: the mark is said out loud *and* the words are
    // still reachable. Round nine added the first; this test exists because
    // adding it did not add the second.
    expect(node.value, contains('The one that mattered'));
    expect(node.label.toLowerCase(), contains('mattered'));
    handle.dispose();
  });
}
