import 'dart:async';

import 'package:flutter/material.dart';

/// One transient sentence at the bottom of the screen — and a dismissal that
/// does not depend on the framework deciding to arm one.
///
/// ── WHY THIS EXISTS, AND WHY IT IS NOT A WRAPPER FOR TIDINESS ────────────
///
/// **Round eighteen, 3 September 2026.** *"can you see the notification below?
/// it doesn't goes!"* — a `Deleted. Undo` bar that never left. Not slow to
/// leave: it survived backgrounding the app, the vault re-locking itself, and
/// unlocking again. Only force-stopping the process cleared it. It was on
/// screen while the entry it offered to undo was visibly back on the page
/// above it, restored from Trash minutes earlier.
///
/// **He reported this same sentence in round five** — *"I want you to make it
/// go away automatically… but it doesn't go"* — and it was answered then by
/// shortening the duration to three seconds and swapping `hideCurrentSnackBar`
/// for `clearSnackBars`. Both of those were right and neither was the bug, and
/// the report coming back word for word is the tell: **a repeated report means
/// the fix was at the wrong layer.**
///
/// The layer is this. A `SnackBar`'s auto-dismiss timer is not armed when it is
/// shown. `ScaffoldMessengerState` creates it inside its own `build`, and only
/// once the entrance animation has already completed:
///
/// ```dart
/// if (route == null || route.isCurrent) {
///   if (_snackBarController!.isCompleted && _snackBarTimer == null) {
///     _snackBarTimer = Timer(snackBar.duration, ...);
///   }
/// }
/// ```
///
/// So the dismissal depends on a rebuild landing at the right moment, in a
/// widget this app never rebuilds directly. When that rebuild does not land,
/// **nothing ever tries again** — there is no second chance in that code path,
/// and the bar is simply permanent. Setting `duration:` cannot help, because
/// `duration` is only ever read by a timer that was never created.
///
/// Which is the same shape as two other things already written down in this
/// project: the PDF page whose dropped render was never asked for again, and
/// the shooting star sampled less often than it fires. **Something attempted
/// once, on a trigger you do not control, is something that sometimes never
/// happens.**
///
/// The answer is not to understand Flutter's rebuild timing well enough to be
/// sure of it. It is to stop depending on it: arm our own timer, which runs off
/// `Timer`'s own clock and cannot be skipped. Flutter's still runs and normally
/// wins — ours is four hundred milliseconds behind and does nothing at all when
/// the bar has already gone.
///
/// **A message that will not go away is not a small defect in a journal.** The
/// word left on his screen was `Deleted.`, permanently, over an app whose whole
/// claim is that it looks after what you write.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> announce(
  BuildContext context,
  String words, {
  SnackBarAction? action,

  /// Three seconds, from round five, and the reasoning there still holds:
  /// `ACCESSIBILITY.md` puts undo behind a real target, and two seconds is not
  /// long enough to see a bar, read it and reach it. The shortest defensible
  /// number rather than the smallest one in his sentence.
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);

  // `clearSnackBars` rather than `hideCurrentSnackBar`: the second dismisses
  // only what happens to be visible and lets the backlog through, so deleting
  // three things in a row used to queue three bars and the last one left the
  // screen eighteen seconds after the first delete. Round five.
  //
  // It also makes the fallback below safe: after this line ours is the only bar
  // there is, so closing it late can never close somebody else's.
  messenger.clearSnackBars();

  final bar = messenger.showSnackBar(
    SnackBar(
      content: Text(words),
      action: action,
      duration: duration,
    ),
  );

  var gone = false;

  // Cancelled rather than left to fire into a flag, so that a bar which
  // dismissed itself normally leaves nothing behind. A `Timer` still pending
  // when a widget test finishes is a test failure in Flutter, and a helper that
  // makes every screen's tests fail would not survive its first week.
  //
  // The assignment lands before the `then` callback can run: `bar.closed` is a
  // Future, so its continuation is a microtask, and microtasks wait for this
  // synchronous block to finish.
  late final Timer fallback;
  unawaited(bar.closed.then((_) {
    gone = true;
    fallback.cancel();
  }));

  // The grace is so the framework's own timer wins whenever it was armed, and
  // this one is never the reason a bar disappears on a working path. A
  // backstop, not a mechanism.
  fallback = Timer(duration + const Duration(milliseconds: 400), () {
    // `messenger.mounted` is not belt-and-braces. If the screen is torn down
    // while a bar is still up -- the vault idle-locks, the app is killed and
    // restored, a route is popped from underneath -- the messenger is disposed
    // and `close()` would call `setState` on a dead `State` and throw. The
    // whole point of this timer is to be the thing that always runs; it must
    // therefore also be the thing that never explodes.
    if (!gone && messenger.mounted) bar.close();
  });

  return bar;
}
