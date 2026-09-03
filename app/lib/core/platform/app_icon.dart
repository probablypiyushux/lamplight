import 'package:flutter/services.dart';

/// The launcher icon, following the theme.
///
/// Asked for as *"when you change theme, I want you to change the app icon
/// too"*. It is the one part of the app that lives outside the app: a warm
/// near-black tile sitting in a tray of light ones is the only thing about
/// Lamplight that could not follow the setting on its own.
///
/// **And the accent, since ISSUE 6b.** *"The request is that the icon's light
/// takes the colour of the chosen accent"* — he showed amber against purple.
/// Only the lamp's light changes; the shade stays the palette's ink, so it is
/// one mark under six lamps rather than six marks.
///
/// Android has no API for "use this drawable now" — the icon is a manifest
/// attribute fixed at install. The supported trick is several `activity-alias`
/// declarations with different icons, exactly one enabled. There are twelve of
/// them now: six accents, dark and light. See `IconSwitcher.kt` for the
/// ordering rule that keeps the home-screen shortcut from vanishing mid-swap —
/// which matters a great deal more with twelve than it did with two — and for
/// the honest caveat that some launchers cache icons and will redraw late.
abstract final class AppIcon {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Called whenever the resolved brightness or the accent changes, and once at
  /// launch.
  ///
  /// **This records the wanted icon; it does not change it. ISSUE A.**
  ///
  /// *"Whenever the icon colour or dark mode light mode is done I get out of
  /// the app."* Swapping the icon means disabling the `activity-alias` the
  /// running task was launched from, and Android answers that by finishing the
  /// task — the app disappears while the process is still alive, which is
  /// precisely why it read as a crash. `DONT_KILL_APP` does not cover it.
  ///
  /// So the platform side saves the request and performs it in `onStop`, once
  /// the user has left. The vault has locked and dropped its keys by then, so
  /// a task that goes away costs nothing. See `IconSwitcher.kt`.
  ///
  /// The visible consequence: the launcher icon changes a moment after the
  /// setting does, rather than with it. Some launchers cache icons and were
  /// already late by more than that.
  ///
  /// Cheap to call repeatedly: this writes two preference values, and the
  /// platform side no-ops at `onStop` if the wanted alias is already on.
  ///
  /// [accentId] is `LampAccent.id`. An id the platform does not recognise —
  /// an accent added in a future version, on a build that predates it — falls
  /// back to Amber on both sides, so the icon is never *missing*, only
  /// out of date.
  static Future<void> use({required String accentId, required bool light}) async {
    try {
      await _channel.invokeMethod<void>(
          'setIconTheme', {'accent': accentId, 'light': light});
    } catch (_) {
      // An icon that did not change is not worth an error. Nothing else in the
      // app depends on this having worked.
    }
  }
}
