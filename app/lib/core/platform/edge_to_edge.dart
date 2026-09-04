import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Drawing under the system bars, on purpose rather than by surprise.
///
/// ── WHY THIS FILE EXISTS ─────────────────────────────────────────────────
///
/// The Play Console said it first:
///
/// > *"Edge-to-edge may not display for all users. From Android 15, apps
/// > targeting SDK 35 will display edge-to-edge by default. Apps targeting SDK
/// > 35 should handle insets to make sure that their app displays correctly on
/// > Android 15 and later."*
///
/// This app targets **36**. So on Android 15 and later the system already
/// stopped insetting the window for us, and it did that whether or not anybody
/// here had thought about it. Until this file, nothing had: there was no
/// `SystemUiMode`, no `SystemUiOverlayStyle`, and eighteen `SafeArea`s doing
/// the work by hand on some screens and not others.
///
/// The warning is therefore not a request to opt in to something new. It is a
/// notice that **an opt-out we were relying on has been removed**, and that the
/// two things it used to do for us are now ours:
///
///   1. **Keeping content out from under the bars.** That is [SafeArea], and
///      the audit is `edge_to_edge_test.dart`.
///   2. **Keeping the bars' own icons legible.** That is [styleFor]. Android
///      draws the clock and the battery into our window; if it picks the wrong
///      contrast the user gets a white clock on cream paper and cannot read the
///      time. Nothing in Flutter does this by default.
///
/// ── WHY IT IS ALSO SET EXPLICITLY, WHEN 15 DOES IT ANYWAY ────────────────
///
/// [SystemUiMode.edgeToEdge] is asked for in `main` even though Android 15
/// imposes it. Two reasons, and neither is superstition:
///
///   * **Android 14 and below do not impose it.** `minSdk` is 26. Without this
///     call the app is edge-to-edge on new phones and inset on old ones, which
///     means the layout he approves on one is not the layout that ships on the
///     other — and the difference is exactly the sort that only shows up in a
///     screenshot from somebody else's phone.
///   * **One behaviour is testable; two are not.** A rule that holds on every
///     supported version can be pinned. A rule with a version branch in it gets
///     verified on whichever version the person testing happens to hold.
///
/// ── WHAT IS DELIBERATELY NOT DONE ────────────────────────────────────────
///
/// No `systemNavigationBarColor`, no `statusBarColor`. Both are deprecated
/// under Android 15 and ignored: the platform composites the bars over the
/// app's own pixels now, so the colour behind them is whatever the app painted
/// there, which is the correct answer and needs no help. Setting them would be
/// code that reads as if it were doing something and is not.
abstract final class EdgeToEdge {
  /// Asks the engine to lay the app out under the system bars.
  ///
  /// Called once from `main`, before `runApp`, alongside [PortraitOnly.apply].
  static Future<void> apply() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  /// The overlay style for a page of the given [brightness].
  ///
  /// [brightness] is the brightness of the **app's own background** — the
  /// canvas the bars will be composited over — not the phone's setting and not
  /// [MediaQuery.platformBrightnessOf]. On a light page the icons must be dark
  /// and on a dark page light, and since the theme can be Dark, Light or follow
  /// the phone, the only reliable source is the resolved
  /// `Theme.of(context).brightness`.
  ///
  /// The two fields say the same thing twice on purpose:
  /// `statusBarIconBrightness` is the Android spelling and
  /// `statusBarBrightness` is the iOS one, which is inverted. Getting the
  /// inversion wrong is the classic version of this bug and it is invisible on
  /// whichever platform the author was testing.
  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final light = brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      // Android: the icons drawn INTO our window.
      statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness:
          light ? Brightness.dark : Brightness.light,
      // iOS: describes the BAR, so it is the other way round. Kept even though
      // this app ships on Android only, because the day it does not, a silent
      // inversion is not a thing anybody would think to look for.
      statusBarBrightness: light ? Brightness.light : Brightness.dark,
    );
  }
}
