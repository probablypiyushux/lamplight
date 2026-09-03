import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/folder_ribbon.dart';

/// Filing, and the swipe that cannot exist. **`PLAN.md` §7.0-E.**
///
/// > *"Swipe an entry to file it — long-press → sheet → tick → Done is four
/// > steps for the app's central idea."*
///
/// ══ THE SWIPE IS REFUSED, AND THIS FILE IS WHY ═══════════════════════════
///
/// The day view is a horizontal `PageView`: swiping sideways is how you change
/// day, and `day_screen.dart` deliberately moved the pager *down* so that it
/// wraps the day's content and nothing else. A `Dismissible` — or any other
/// `HorizontalDragGestureRecognizer` — placed on an entry sits **deeper in the
/// tree** than the pager's, and Flutter sweeps the arena from the innermost
/// member outwards. It would win every horizontal drag that begins on an entry
/// block, and entry blocks are most of the screen.
///
/// The cost is not subtle: **swiping between days would stop working over most
/// of the day.** That is trading the app's primary navigation for a shortcut to
/// a secondary action, and it would be the fourth time gesture arenas have cost
/// this project something after the photo viewer, the PDF reader and the pencil.
///
/// The first test below fails if anybody adds a horizontal drag recogniser
/// inside the day's stream, so the next person to try this reads the reasoning
/// before they read the bug report.
///
/// **What the complaint was actually about is fixed**, in two halves that this
/// file also covers: the picker writes on the tick rather than on **Done**, and
/// filing is visible on the entry afterwards.
void main() {
  group('the day stream holds no horizontal drag recogniser', () {
    test('nothing in the day view installs one', () {
      // Read rather than pumped. A widget test can only see the recognisers
      // that happen to be built for the day it renders; the source is the
      // whole surface, and this is a rule about the surface.
      const suspects = [
        'Dismissible',
        'HorizontalDragGestureRecognizer',
        'onHorizontalDragStart',
        'onHorizontalDragUpdate',
        'onHorizontalDragEnd',
      ];

      final offenders = <String>[];
      for (final name in const [
        'lib/features/day/day_stream.dart',
        'lib/features/day/entry_block.dart',
        'lib/features/day/folder_ribbon.dart',
        'lib/features/capture/attachment_blocks.dart',
      ]) {
        final file = File(name);
        if (!file.existsSync()) continue;
        final source = file.readAsStringSync();
        for (final suspect in suspects) {
          // Skip the prose. This file's own argument, and the notes in
          // `folder_ribbon.dart`, name these deliberately.
          for (final line in source.split('\n')) {
            final code = line.trimLeft();
            if (code.startsWith('//') || code.startsWith('///')) continue;
            if (code.contains(suspect)) offenders.add('$name: $line');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'A horizontal drag recogniser inside the day would win the '
            'gesture arena against the day pager, because it is deeper in the '
            'tree — and swiping between days would stop working over every '
            'entry block. Read the argument at the top of folder_ribbon.dart '
            'before deleting this test.\n${offenders.join('\n')}',
      );
    });
  });

  group('where an entry is filed is visible on the entry', () {
    testWidgets('an unfiled entry draws nothing at all', (tester) async {
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: FolderRibbon(names: const [], onOpen: (_) {}),
        ),
      ));
      // Not an empty box with padding — nothing. A day of unfiled entries must
      // not grow a few points per block.
      expect(tester.getSize(find.byType(FolderRibbon)), Size.zero);
    });

    testWidgets('the folders an entry is in are named', (tester) async {
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: FolderRibbon(names: const ['Kavya', 'Work'], onOpen: (_) {}),
        ),
      ));
      expect(find.text('Kavya'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('a chip is the way into that folder', (tester) async {
      // The ribbon answers "where is this" and "what else is in there" with
      // one control. A line of text would only answer the first.
      String? opened;
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: FolderRibbon(
            names: const ['Kavya'],
            onOpen: (name) => opened = name,
          ),
        ),
      ));
      await tester.tap(find.text('Kavya'));
      await tester.pump();
      expect(opened, 'Kavya');
    });

    testWidgets('a screen reader is told it is a second place, not a move',
        (tester) async {
      // `folder_repository.dart`: "a folder is a link, never a move" is the one
      // idea the whole model rests on, and the label is where a screen-reader
      // user meets it.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: FolderRibbon(names: const ['Kavya'], onOpen: (_) {}),
        ),
      ));
      expect(find.bySemanticsLabel('Also in Kavya. Open the folder.'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('six folders wrap rather than scroll sideways',
        (tester) async {
      // A horizontal scroller inside a vertical list is a gesture conflict
      // waiting to happen, which is the subject of this whole file.
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: FolderRibbon(
              names: const [
                'Kavya',
                'Work',
                'Therapy',
                'Family',
                'Reading',
                'The move',
              ],
              onOpen: (_) {},
            ),
          ),
        ),
      ));
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
    });
  });

  group('ticking a folder is the act, not a draft', () {
    test('the picker has no pending state to lose', () {
      // Stated as a source rule rather than pumped, because what is being
      // asserted is the *absence* of a deferred write: `_apply` and the
      // before/after set comparison it needed are gone, and a tick calls
      // `add`/`remove` directly.
      final source =
          File('lib/features/folders/folder_picker.dart').readAsStringSync();
      expect(source.contains('setMembership'), isFalse,
          reason: 'setMembership is the batch write that made the ticks a '
              'draft — walking away from the sheet threw them away. A tick is '
              'one row now, written on the tap.');
      expect(source.contains('_repo.add('), isTrue);
      expect(source.contains('_repo.remove('), isTrue);
    });
  });
}
