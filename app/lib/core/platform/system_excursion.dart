/// The moments when Lamplight deliberately sends the user to another app.
///
/// WHY THIS IS ONE OBJECT AND NOT A LINE AT EACH CALL SITE
///
/// Every system round trip — the camera, the photo picker, the file picker, the
/// folder chooser, saving a backup — backgrounds this app, and backgrounding it
/// locks the vault. That locking rule is correct and is not negotiable; what
/// was missing was any way for the vault to tell *the user left* from *we sent
/// them somewhere and are expecting them back*.
///
/// The fix has to be impossible to forget. If it were a line at each call site,
/// the seventh picker somebody adds in a year's time would not have it, and the
/// symptom — "I took a photo and the app closed and nothing was saved" — points
/// nowhere near the cause. So it lives **inside the channel wrappers**: every
/// method that launches an activity goes through [around], and a new one cannot
/// be written without it.
///
/// The hooks are wired once, in `main.dart`, to the vault. Left unwired — in a
/// widget test, on a desktop build — this does nothing at all, which is the
/// correct behaviour rather than a special case.
abstract final class SystemExcursion {
  /// Called just before another app takes the foreground.
  static void Function()? onLeave;

  /// Called when it hands back, whether that was a result or a cancellation.
  static void Function()? onReturn;

  /// Runs [body] with the excursion open, and closes it however [body] ends.
  ///
  /// The `finally` matters: a picker that throws must still close the window,
  /// or a failed import would leave the vault refusing to lock on background
  /// until the safety timer fired.
  static Future<T> around<T>(Future<T> Function() body) async {
    onLeave?.call();
    try {
      return await body();
    } finally {
      onReturn?.call();
    }
  }
}
