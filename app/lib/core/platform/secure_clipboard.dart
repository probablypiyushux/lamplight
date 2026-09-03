import 'dart:async';

import 'package:flutter/services.dart';

/// Putting something on the clipboard that should not stay there.
///
/// ══ ISSUE 16 — "Add an option to copy backup phrase" ═════════════════════
///
/// *"Add an option to copy Backup phrase — just make sure the user has written
/// it down somewhere."*
///
/// I said no first, and then said what it would take: the Android clipboard is
/// readable by every app on the phone, and Gboard keeps a clipboard history
/// that survives a reboot — so twelve words that unlock somebody's entire
/// journal would be sitting in the least private place on the device. He read
/// that and answered: *"Auto wipe it? Make it possible! Yesss!"*
///
/// So this is the narrowest possible version of a clipboard copy, and each of
/// the three parts does something a plain `Clipboard.setData` does not:
///
///   * **It is marked sensitive.** Android 13 and later show a floating preview
///     of whatever was just copied. `ClipDescription.EXTRA_IS_SENSITIVE` makes
///     the system show "•••" instead — so the recovery phrase does not appear,
///     in plain text, over whatever app the user opens next. Flutter's own
///     `Clipboard` cannot set that flag, which is the whole reason this goes
///     through a channel.
///   * **It is taken back.** After [holdFor] the clipboard is cleared.
///   * **Only if it is still ours.** If the user copied something else in the
///     meantime, that is now their clipboard and this must not touch it.
///     Wiping somebody's shopping list because they copied a passphrase a
///     minute ago would be its own small betrayal.
///
/// It is still a real trade and the UI says so out loud rather than burying it.
/// Paper remains the recommendation; this is for somebody who keeps a password
/// manager and knows what they are doing.
abstract final class SecureClipboard {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// How long the words stay available to paste.
  ///
  /// Sixty seconds. Long enough to switch to a password manager and paste,
  /// short enough that it is gone before the phone is put down. A value the
  /// user could raise would be a setting whose only purpose is to make this
  /// less safe.
  static const Duration holdFor = Duration(seconds: 60);

  static Timer? _wipe;

  /// What we put there, so we can tell whether it is still ours to clear.
  static String? _ours;

  /// Copies [text], marked sensitive, and schedules its removal.
  ///
  /// Returns false if the platform refused, so the caller can say so rather
  /// than showing a confirmation for something that did not happen.
  static Future<bool> copyBriefly(String text) async {
    _wipe?.cancel();
    var marked = false;
    try {
      marked =
          await _channel.invokeMethod<bool>('copySensitive', {'text': text}) ??
              false;
    } on MissingPluginException {
      marked = false;
    } catch (_) {
      marked = false;
    }

    if (!marked) {
      // No platform side — a test, or a build without the channel. The copy
      // still has to work; what is lost is only the sensitivity flag, and the
      // timed wipe below still runs.
      try {
        await Clipboard.setData(ClipboardData(text: text));
      } catch (_) {
        return false;
      }
    }

    _ours = text;
    _wipe = Timer(holdFor, () {
      clearIfStillOurs().ignore();
    });
    return true;
  }

  /// Clears the clipboard, but only if it still holds what we put there.
  ///
  /// Called by the timer, and again when the vault locks — leaving a recovery
  /// phrase pasteable behind a locked vault would make the lock decorative.
  static Future<void> clearIfStillOurs() async {
    final ours = _ours;
    _wipe?.cancel();
    _wipe = null;
    if (ours == null) return;
    _ours = null;
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      // Somebody else's clipboard now. Leave it alone.
      if (current?.text != ours) return;
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {
      // A clipboard that cannot be read is one we must not blindly overwrite.
    }
  }

  /// For tests, and for the vault locking.
  static void forget() {
    _wipe?.cancel();
    _wipe = null;
    _ours = null;
  }
}
