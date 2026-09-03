import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/day_note_repository.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/day/day_line.dart';
import 'package:sodium/sodium_sumo.dart';

/// The day's own line, on screen. **`PLAN.md` §7.0-E, first item.**
///
/// ── WHAT IS WORTH HOLDING STILL HERE ──────────────────────────────────────
///
/// Not "does it look right" — that is an eye's job. What a test can hold is
/// the **rule about when it appears**, which is the part of the design that a
/// later simplification would quietly undo:
///
///   * a line that exists is always shown, on any day, in any state;
///   * the *invitation* to write one appears only once the day has something
///     on it, because an empty day already carries `EmptyDay`'s invitation and
///     two prompts on a blank page is the app asking twice;
///   * a page that is not the one on screen offers nothing, because the caret
///     belongs to the day the finger is on.
///
/// "Always show the prompt" is a completely reasonable-sounding change that
/// would put two invitations on every empty day, so it fails a build.
///
/// ── THE TWO RULES THIS FILE OBEYS, BOTH LEARNED IN `screens_test.dart` ────
///
///  1. **Every `await` on the database goes through `tester.runAsync`.** A
///     `testWidgets` body runs in a fake-async zone where real file I/O never
///     completes — it does not return slowly, it never returns, and the suite
///     sits there until its ten-minute timeout with nothing to point at.
///  2. **Every test unmounts before it ends.** A live drift query posts a
///     zero-duration timer when its subscription is cancelled, and left to the
///     framework's teardown that happens *after* the pending-timer check.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late VaultDatabase db;
  late DayNoteRepository notes;
  late EntryRepository entries;

  setUpAll(() async {
    // Same reasoning as `screens_test.dart`: a fake-async zone cannot observe
    // a worker isolate delivering stream events on the real event loop, and
    // this file asserts on watched queries.
    debugUseInProcessDatabase = true;
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  tearDownAll(() {
    debugUseInProcessDatabase = false;
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_dayline');
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    db = await openVaultDatabase(path: '${tmp.path}/vault.db', key: key);
    notes = DayNoteRepository(db);
    entries = EntryRepository(db);
  });

  tearDown(() async {
    await db.close();
    // Best effort: Windows refuses to delete a file another handle still has
    // open, and SQLite closes its own asynchronously.
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Database work, from inside a widget test. Rule 1 above.
  Future<T> work<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  Future<void> pump(
    WidgetTester tester, {
    String dayKey = '2026-08-28',
    bool editable = true,
    VoidCallback? onFocused,
  }) async {
    await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: DayLine(
          notes: notes,
          entries: entries,
          dayKey: dayKey,
          editable: editable,
          onFocused: onFocused,
        ),
      ),
    ));
    // A frame, a real-time window for the two queries to come back, then a
    // frame to draw what they returned.
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Rule 2 above.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> addEntry(WidgetTester tester, String dayKey) => work(
        tester,
        () => entries.createTextOn(
            id: 'e-$dayKey', dayKey: dayKey, body: 'something happened'),
      );

  group('when the line is offered at all', () {
    testWidgets('an empty day offers nothing — EmptyDay already asks',
        (tester) async {
      await pump(tester);
      expect(find.text('What was this day?'), findsNothing);
      await unmount(tester);
    });

    testWidgets('a day with something on it offers the line', (tester) async {
      await addEntry(tester, '2026-08-28');
      await pump(tester);
      expect(find.text('What was this day?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a page that cannot be typed on offers nothing',
        (tester) async {
      await addEntry(tester, '2026-08-28');
      await pump(tester, editable: false);
      expect(find.text('What was this day?'), findsNothing);
      await unmount(tester);
    });

    testWidgets('a line that exists shows on an empty day too', (tester) async {
      // Somebody can empty a day after naming it — trash everything on it —
      // and the name they gave it must not vanish with the last entry.
      await work(tester,
          () => notes.setBody('2026-08-28', 'The day the results came'));
      await pump(tester);
      expect(find.text('The day the results came'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a line that exists shows even when it cannot be edited',
        (tester) async {
      await work(tester,
          () => notes.setBody('2026-08-28', 'The day the results came'));
      await pump(tester, editable: false);
      expect(find.text('The day the results came'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('writing one', () {
    testWidgets('tapping the invitation opens a field and saves on blur',
        (tester) async {
      await addEntry(tester, '2026-08-28');
      await pump(tester);

      await tester.tap(find.text('What was this day?'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Results day');

      // Losing focus is what saves. There is no button, because a title that
      // needs confirming is a form.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();

      expect(await work(tester, () => notes.read('2026-08-28')), 'Results day');
      await unmount(tester);
    });

    testWidgets('opening the field hands the caret over', (tester) async {
      // The composer has to give focus up, or the first thing typed into the
      // day's line lands in the day's writing instead.
      var handed = false;
      await addEntry(tester, '2026-08-28');
      await pump(tester, onFocused: () => handed = true);

      await tester.tap(find.text('What was this day?'));
      await tester.pump();
      expect(handed, isTrue);
      await unmount(tester);
    });

    testWidgets('the field cannot be typed past the cap', (tester) async {
      await addEntry(tester, '2026-08-28');
      await pump(tester);
      await tester.tap(find.text('What was this day?'));
      await tester.pump();
      await tester.pump();

      final long = 'x' * (DayNoteRepository.maxLength + 200);
      await tester.enterText(find.byType(TextField), long);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text.length, DayNoteRepository.maxLength,
          reason: 'the cap is enforced where the finger is, so nobody types '
              'past it and watches their words disappear on save');
      await unmount(tester);
    });

    testWidgets('the field is one line', (tester) async {
      await addEntry(tester, '2026-08-28');
      await pump(tester);
      await tester.tap(find.text('What was this day?'));
      await tester.pump();
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
      await unmount(tester);
    });
  });

  group('the day underneath it changes', () {
    testWidgets("swiping to another day shows that day's line", (tester) async {
      await work(tester, () async {
        await notes.setBody('2026-08-27', 'Rain all afternoon');
        await notes.setBody('2026-08-28', 'Results day');
      });

      await pump(tester, dayKey: '2026-08-28');
      expect(find.text('Results day'), findsOneWidget);

      // The header is one widget for every page, so the same State survives
      // the day changing underneath it — this is `didUpdateWidget`, not a
      // rebuild from scratch.
      await pump(tester, dayKey: '2026-08-27');
      expect(find.text('Rain all afternoon'), findsOneWidget);
      expect(find.text('Results day'), findsNothing);
      await unmount(tester);
    });
  });
}
