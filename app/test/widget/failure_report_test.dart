import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/app_info.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/error/error_surface.dart';

/// The one channel by which a fault on somebody else's phone can ever reach
/// the person who could fix it.
///
/// ── WHY THE PROMISE IS THE TEST ─────────────────────────────────────────────
///
/// There is no crash reporting in Lamplight and there will not be — rule 3.
/// The price is that a stranger who hits a bug deletes the app and no signal of
/// any kind reaches anybody. This is the version that costs the rule nothing:
/// nothing is sent, the text is shown in full first, and copying it is a thing
/// the person chooses to do.
///
/// The screen tells them, in words, that what they are copying *"does not
/// contain anything you have written"*. That sentence is a promise, and the
/// only thing keeping it true is `describeFailure` refusing to include
/// `error.toString()`. That refusal looks like an oversight — the message is
/// the most useful line for debugging — so it is exactly the kind of thing a
/// later session would helpfully add back.
///
/// Nothing else would fail if it did. This does.
void main() {
  group('what a failure report may contain', () {
    test('never the exception message', () {
      // The realistic leak: an exception raised while handling something the
      // user typed, carrying what they typed inside it.
      final secret = FormatException(
        'could not parse: I told my brother about the diagnosis today',
      );

      final report = describeFailure(secret, StackTrace.current);

      expect(report, isNot(contains('diagnosis')));
      expect(report, isNot(contains('my brother')));
      expect(report, isNot(contains(secret.message)));
    });

    test('never the message, even for a plain string thrown', () {
      final report = describeFailure(
        'the note said something private',
        StackTrace.current,
      );
      expect(report, isNot(contains('private')));
    });

    test('but does say what type of failure it was', () {
      // Without this it is not a report, it is a receipt. The type plus the
      // stack is what makes a bug findable at all.
      final report = describeFailure(
        const FormatException('x'),
        StackTrace.current,
      );
      expect(report, contains('FormatException'));
    });

    test('carries the version, so a report can be placed in time', () {
      final report = describeFailure(Exception('x'), StackTrace.current);
      expect(report, contains(kAppVersion));
    });

    test('keeps the stack, which is code locations and nothing else', () {
      final report = describeFailure(Exception('x'), StackTrace.current);
      expect(report, contains('failure_report_test.dart'));
    });

    test('is short enough for somebody to actually paste', () {
      // An untruncated Flutter stack runs to hundreds of lines and would be
      // pasted into a message by nobody.
      final report = describeFailure(
        Exception('x'),
        StackTrace.fromString(
          List.generate(400, (i) => '#$i      Some.method (file.dart:$i)')
              .join('\n'),
        ),
      );
      final lines = report.split('\n');
      expect(lines.length, lessThan(30));
      expect(report, contains('more'));
    });

    test('survives a null stack', () {
      // PlatformDispatcher.onError can hand one over. The error handler
      // throwing inside itself is the worst available outcome.
      expect(() => describeFailure(Exception('x'), null), returnsNormally);
    });
  });

  group('the screen', () {
    Widget host(Widget child) => MaterialApp(
      // The delegates the real `MaterialApp` installs. Without them
      // `L.of(context)` is null and any localised widget throws — which is a
      // failure of the harness rather than of the screen.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,

          theme: ThemeData(extensions: const [LamplightColors.dark]),
          home: child,
        );

    testWidgets('leads with reassurance, not with the fault', (tester) async {
      // Somebody who has just lost a screen wants one question answered before
      // any other: is my writing still there.
      await tester.pumpWidget(host(const CalmErrorPage(report: 'x')));
      await tester.pumpAndSettle();

      expect(find.text('That screen did not open.'), findsOneWidget);
      expect(find.textContaining('Nothing was lost'), findsOneWidget);
    });

    testWidgets('hides the details until they are asked for', (tester) async {
      await tester.pumpWidget(host(
        const CalmErrorPage(report: 'Lamplight 0.1.0\nFailure: StateError'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('StateError'), findsNothing);

      await tester.tap(find.text('Show the technical details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('StateError'), findsOneWidget);
    });

    testWidgets('shows the whole text before offering to copy it',
        (tester) async {
      // The safeguard is that they can read it. A "send report" button with
      // nothing shown would be asking for trust this app does not need.
      await tester.pumpWidget(host(const CalmErrorPage(report: 'the report')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show the technical details'));
      await tester.pumpAndSettle();

      expect(find.text('the report'), findsOneWidget);
      expect(find.text('Copy the details'), findsOneWidget);
      expect(
        find.textContaining('does not contain anything you have written'),
        findsOneWidget,
      );
    });

    testWidgets('offers nothing to copy when there is nothing', (tester) async {
      await tester.pumpWidget(host(const CalmErrorPage()));
      await tester.pumpAndSettle();

      expect(find.text('Show the technical details'), findsNothing);
    });
  });
}
