/// What the user sees instead of a stack trace. **ISSUE 15.**
///
/// WHY THIS FILE EXISTS
///
/// Piyush photographed a red-and-yellow Flutter assertion screen and put it at
/// the top of his list. The defect he was reporting is not the assertion. It is
/// that he saw it at all — the app showed him its own machinery, which is
/// exactly what test 6 in `PLAN.md` §11 forbids: *"The user must never know how
/// complex the app is."*
///
/// Before this file there was **no `ErrorWidget.builder` and no
/// `FlutterError.onError` anywhere in `lib/`**, so every error in the app —
/// including every one not yet written — went straight to the screen as
/// developer output. In a release build it would have been a featureless grey
/// box instead: quieter, equally broken.
///
/// WHAT IT DELIBERATELY DOES NOT DO
///
/// It does not report anything anywhere. `CLAUDE.md` rule 3: no crash
/// reporting, ever. The error is printed to the debug console, where a
/// developer with the phone plugged in can read it, and nowhere else.
///
/// It also never shows the error text. Not because the text is embarrassing but
/// because **an exception message can contain the user's own words** — an
/// assertion inside a text layout can quote the string it was laying out. A
/// crash screen that quotes a journal entry, at the moment the user is most
/// likely to hand the phone to someone and say "look what it did", is a content
/// leak wearing a bug's clothes. So the surface says what happened in the app's
/// own voice, offers a way onward, and that is all.
///
/// WHY THE SIZE DECIDES WHICH ONE APPEARS
///
/// The framework inserts an [ErrorWidget] exactly where the failure was, and
/// that place can be a whole screen or a single row inside a day. One response
/// cannot be right for both: a full-page apology for one unreadable block would
/// throw away a day the user can otherwise still read, and a single grey line
/// where a screen should be reads as the app having given up silently.
///
/// So it asks the box. `LayoutBuilder` sees the constraints the failure was
/// handed, and anything with room for a page gets the page.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../design/lamp_mark.dart';
import '../../design/tokens.dart';

/// Installs the three handlers that stop raw framework output ever reaching a
/// person. Call once, from `main`, before `runApp`.
///
/// [onReport] is invoked for every caught error and exists so tests can watch
/// without touching a global. It is not a telemetry hook and must never become
/// one.
void installCalmErrors({
  void Function(Object error, StackTrace? stack)? onReport,
}) {
  // ── Anything that throws while *building* a widget ────────────────────────
  //
  // The framework's default replaces the offending widget with a red box full
  // of the exception text. This replaces it with the calm surface.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    onReport?.call(details.exception, details.stack);
    return CalmErrorSurface(
      report: describeFailure(details.exception, details.stack),
    );
  };

  // ── Anything the framework catches anywhere else ──────────────────────────
  //
  // Layout, painting, gestures, tickers. `presentError` is what prints to the
  // console; keeping it under `kDebugMode` means a plugged-in developer still
  // sees everything and a shipped build says nothing.
  FlutterError.onError = (FlutterErrorDetails details) {
    onReport?.call(details.exception, details.stack);
    if (kDebugMode) FlutterError.presentError(details);
  };

  // ── Anything that escapes the framework entirely ──────────────────────────
  //
  // An unawaited future that throws; a platform-channel reply that fails. These
  // never reach `FlutterError.onError`, and left alone they tear the isolate
  // down. Returning true says "handled": the app keeps running, which for a
  // journal is always the right answer — a half-drawn screen the user can back
  // out of loses nothing, and a dead process loses whatever was being typed.
  PlatformDispatcher.instance.onError = (error, stack) {
    onReport?.call(error, stack);
    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
    return true;
  };
}

/// What broke, in a form somebody can paste into a message.
///
/// -- THE PROMISE THIS FUNCTION HAS TO KEEP ----------------------------------
///
/// The screen above it tells the user, in words, that the text they are about
/// to copy *"does not contain anything you have written"*. That sentence is
/// only allowed to be there because of what this function refuses to include.
///
/// **The exception's message is deliberately left out.** `error.toString()` is
/// the single most useful line for debugging and it is also the one place user
/// content can appear — a `FormatException` on a parsed note quotes the note,
/// an assertion about a text field can carry its contents. There is no way to
/// look at a message and know whether it contains somebody's diary, so the
/// only safe rule is the blunt one.
///
/// What is left is still enough to find nearly any fault: the exception's
/// **type**, and the **stack**, which is function names and line numbers and
/// nothing else. If a bug ever genuinely needs the message, the answer is to
/// reproduce it — not to widen this.
///
/// -- WHY THIS EXISTS AT ALL ------------------------------------------------
///
/// There is no crash reporting in Lamplight and there will not be (rule 3).
/// The price of that rule is real: a fault on a stranger's phone is a fault
/// nobody will ever hear about, because they will delete the app and no signal
/// of any kind will reach anybody. This is the version that costs the rule
/// nothing — the text is shown to the person in full, and copying it is a
/// thing they choose to do.
String describeFailure(Object error, StackTrace? stack, {int frames = 20}) {
  final out = StringBuffer()
    ..writeln('Lamplight $kAppVersionLabel')
    ..writeln(_platform())
    // The type, not the message. See above.
    ..writeln('Failure: ${error.runtimeType}');

  if (stack != null) {
    final lines = stack.toString().trim().split('\n');
    out.writeln();
    for (final line in lines.take(frames)) {
      out.writeln(line.trimRight());
    }
    if (lines.length > frames) {
      out.writeln('... ${lines.length - frames} more');
    }
  }
  return out.toString().trimRight();
}

/// The OS version, without a plugin.
///
/// `Platform.operatingSystemVersion` is in `dart:io` and costs nothing. Device
/// model would need `device_info_plus`, and rule 4 counts an avoided
/// dependency as a security property — a model name is not worth a package
/// that could read every note.
String _platform() {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    // Reached under `flutter test` on some platforms. A missing line is
    // better than this function being the thing that throws inside the error
    // handler.
    return 'platform unknown';
  }
}

/// The thing that appears where a widget failed.
///
/// Sizes itself to the hole it is filling — see the note at the top of the
/// file. Everything it reads from the theme it reads defensively, because this
/// widget runs *after* something has already gone wrong and one of the things
/// that can be wrong is the theme not being there at all. A `Theme.of` that
/// threw here would recurse into the error builder forever.
class CalmErrorSurface extends StatelessWidget {
  const CalmErrorSurface({super.key, this.report});

  /// A sanitised description of what failed, from [describeFailure].
  ///
  /// Null where the surface is built by hand rather than by the error handler,
  /// in which case the page simply has nothing to offer and does not pretend
  /// otherwise.
  final String? report;

  /// Below this, there is no room for a page and the one-line form is used.
  /// 320dp is a little under half of the shortest phone in the responsive
  /// suite, so a genuine screen always clears it and a block never does.
  static const double _pageThreshold = 320;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxHeight.isFinite &&
              constraints.maxHeight >= _pageThreshold &&
              constraints.maxWidth >= 240;
          return roomy ? CalmErrorPage(report: report) : const _InlineFailure();
        },
      ),
    );
  }
}

/// One line where a broken block was.
///
/// Deliberately quiet. If a single entry fails to draw, the rest of the day is
/// still readable and still scrollable, and taking the whole screen for one bad
/// block would be the app over-reacting on the user's behalf.
class _InlineFailure extends StatelessWidget {
  const _InlineFailure();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LamplightColors>() ?? LamplightColors.dark;
    final style = theme.textTheme.labelMedium ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text(
        L.of(context).errorPartNotShown,
        style: style.copyWith(color: c.inkSecondary),
      ),
    );
  }
}

/// The full-page form, for when a whole screen could not be built.
///
/// It says three things and nothing else: that something went wrong, that
/// nothing was lost, and how to carry on. The middle one is the important one —
/// in an app whose entire promise is "losing this must be impossible", the
/// first question a failure raises is *"is my writing still there?"*, and the
/// answer is yes, because nothing on the failing path ever touches the vault.
class CalmErrorPage extends StatefulWidget {
  const CalmErrorPage({super.key, this.report});

  final String? report;

  @override
  State<CalmErrorPage> createState() => _CalmErrorPageState();
}

class _CalmErrorPageState extends State<CalmErrorPage> {
  /// Folded away until asked for. A person who has just lost a screen wants to
  /// know their writing is safe; a stack trace in their face says the opposite
  /// of that, however calm the sentence above it is.
  bool _showing = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<LamplightColors>() ?? LamplightColors.dark;
    final t = theme.textTheme;
    // `maybeOf` — the failure may be above the navigator, in which case there
    // is nothing to go back to and the button correctly does not appear.
    final navigator = Navigator.maybeOf(context);
    final canGoBack = navigator?.canPop() ?? false;

    return Semantics(
      container: true,
      label: L.of(context).errorScreenDidNotOpen,
      child: ColoredBox(
        color: c.canvas,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The app's own mark, dimmed. It is still Lamplight; it has
                  // just lost its footing for a moment.
                  const Opacity(opacity: 0.5, child: LampMark(size: 72)),
                  const SizedBox(height: Space.x6),
                  Text(
                    L.of(context).errorScreenShort,
                    textAlign: TextAlign.center,
                    style: t.displaySmall ??
                        TextStyle(fontSize: 32, color: c.inkPrimary),
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    L.of(context).errorNothingLost,
                    textAlign: TextAlign.center,
                    style: (t.bodyLarge ?? const TextStyle(fontSize: 17))
                        .copyWith(color: c.inkSecondary),
                  ),
                  if (canGoBack) ...[
                    const SizedBox(height: Space.x8),
                    TextButton(
                      onPressed: () => navigator!.maybePop(),
                      style: TextButton.styleFrom(
                        foregroundColor: c.accent,
                        minimumSize:
                            const Size(kMinTouchTarget * 2, kMinTouchTarget),
                      ),
                      child: Text(L.of(context).errorGoBack),
                    ),
                  ],

                  // ── The only way anybody will ever hear about this ────────
                  //
                  // There is no crash reporting in this app and there is not
                  // going to be — CLAUDE.md rule 3, and it is the right rule.
                  // The price of it is that a fault on somebody else's phone
                  // is a fault nobody will ever learn about: they delete the
                  // app and the developer never knows they existed.
                  //
                  // This is the version that does not break the rule. Nothing
                  // is sent. Nothing is collected. The text is shown to the
                  // person FIRST, in full, and copying it is their decision —
                  // which is also why it is not summarised or hidden behind a
                  // "send report" button that implies somewhere to send it.
                  //
                  // Signal does exactly this, for the same reasons.
                  if (widget.report != null) ...[
                    const SizedBox(height: Space.x6),
                    TextButton(
                      onPressed: () => setState(() => _showing = !_showing),
                      style: TextButton.styleFrom(
                        foregroundColor: c.inkSecondary,
                        minimumSize:
                            const Size(kMinTouchTarget * 2, kMinTouchTarget),
                      ),
                      child: Text(_showing
                          ? L.of(context).errorHideDetails
                          : L.of(context).errorShowDetails),
                    ),
                    if (_showing) ...[
                      const SizedBox(height: Space.x3),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        padding: const EdgeInsets.all(Space.x3),
                        decoration: BoxDecoration(
                          color: c.raised,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: Border.all(color: c.borderHair),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            widget.report!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.4,
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.x3),
                      Text(
                        L.of(context).errorDetailsNote,
                        textAlign: TextAlign.center,
                        style: (t.labelMedium ?? const TextStyle(fontSize: 12))
                            .copyWith(color: c.inkMuted, height: 1.5),
                      ),
                      const SizedBox(height: Space.x3),
                      TextButton(
                        onPressed: _copied
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: widget.report!),
                                );
                                if (mounted) setState(() => _copied = true);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: c.accent,
                          minimumSize:
                              const Size(kMinTouchTarget * 2, kMinTouchTarget),
                        ),
                        child: Text(_copied
                            ? L.of(context).aboutCopied
                            : L.of(context).aboutCopyDetails),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
