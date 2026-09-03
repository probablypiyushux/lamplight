import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/capture/capture_bar.dart';
import 'package:lamplight/features/day/empty_day.dart';
import 'package:lamplight/features/media/document_viewer.dart';

/// **ROUND FIVE, ISSUE H — "find a way that these issues never occurs again".**
///
/// The small, visible ones. Each of these is a number or a condition somebody
/// could reasonably change back while tidying, without ever knowing it had been
/// asked for — which is exactly the kind of regression a comment does not stop
/// and an assertion does.
///
/// The one genuine data-loss bug of the round has its own file:
/// `test/storage/nothing_leaves_except_through_trash_test.dart`.
void main() {
  group('ISSUE 7 — the default text size', () {
    test('is 90%, which he asked for in those words', () {
      // "This looks like it's an app for old age people, looks worst" at 100%,
      // against "this maintains aesthetics, looks perfect" at 85%. He asked for
      // the middle: "Default sizing is 100% → make it 90%."
      expect(AppSettings.defaultTextScale, 0.9);
    });

    test('and is inside the range the slider offers', () {
      // A default outside the slider's own range would be unreachable again
      // once it had been moved, which is a trap rather than a default.
      expect(AppSettings.defaultTextScale,
          greaterThanOrEqualTo(AppSettings.minTextScale));
      expect(AppSettings.defaultTextScale,
          lessThanOrEqualTo(AppSettings.maxTextScale));
    });
  });

  group('ISSUE 6 — one margin, at every width', () {
    test('the side margin does not vary with the glass', () {
      // The centred 560-point column is what produced "a third of blank, a
      // third of content, a third of blank" in landscape. If this ever starts
      // returning something width-dependent again, the blank thirds are back.
      for (final width in [320.0, 412.0, 686.0, 1024.0, 1143.0, 2560.0]) {
        expect(Layout.marginFor(width), Layout.gutter,
            reason: 'at ${width}pt wide');
      }
    });
  });

  group('ISSUE 9 + 14 — writing happens on the page', () {
    testWidgets('the capture bar has three buttons and none of them is a pencil',
        (tester) async {
      // The pencil's only job was to focus a composer pinned above this bar.
      // The caret is on the page now, and a button whose whole function is
      // "put the cursor in the thing you can already see" is what made the
      // screen feel like a form. UX-FLOWS.md flow 2 was changed to match.
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: CaptureBar(
            onVoice: () {},
            onPhoto: () {},
            onFile: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_file_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing,
          reason: 'writing starts by tapping the page, not by a button');
    });

    testWidgets('the empty day is tappable on today, and inert on a past day',
        (tester) async {
      // "Static boxes which does nothing. I want them to be wired up to be
      // able to write." An interface that invites a tap and ignores it is
      // worse than one that never invited it.
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: EmptyDay(
            date: DateTime(2026, 8, 23),
            isToday: true,
            onTap: () => tapped++,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anything you want to keep?'));
      await tester.pumpAndSettle();
      expect(tapped, 1, reason: 'the sheet must accept the tap it invites');

      // A day that is over is a fact, not an invitation. No handler, no tap.
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: EmptyDay(date: DateTime(2026, 8, 20), isToday: false),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('the date is not printed twice on one page', (tester) async {
      // He circled both and wrote "why two date on one page" and "why another
      // date?". The header already carries it, in the largest type on screen.
      await tester.pumpWidget(MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

        theme: lamplightTheme(LamplightColors.dark),
        home: Scaffold(
          body: EmptyDay(date: DateTime(2026, 8, 24), isToday: true),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('24'), findsNothing,
          reason: 'the empty sheet must not repeat the header’s date');
      expect(find.textContaining('August'), findsNothing);
    });
  });

  group('ISSUE 12 — what opens in place', () {
    test('the formats he listed as openable, open', () {
      for (final name in [
        'a.pdf', 'b.jpg', 'c.png', 'd.webp', 'e.gif', 'f.heic', 'g.heif',
        'h.avif', 'i.csv', 'j.rtf', 'k.vcf', 'l.html', 'm.json', 'n.txt',
      ]) {
        expect(opensInLamplight('application/octet-stream', name), isTrue,
            reason: '$name should open without leaving Lamplight');
      }
    });

    test('the ones needing a third-party parser are refused', () {
      // CLAUDE.md rule 4: every package added here can read all of the user's
      // notes. SVG is on this list despite being a picture, because nothing on
      // the phone will decode one without a renderer.
      for (final name in [
        'a.docx', 'b.xlsx', 'c.pptx', 'd.zip', 'e.rar', 'f.7z', 'g.epub',
        'h.apk', 'i.svg',
      ]) {
        expect(opensInLamplight('application/octet-stream', name), isFalse,
            reason: '$name must reach the panel that explains itself');
      }
    });
  });
}
