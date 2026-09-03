import 'package:flutter/services.dart';

/// One way up. **ISSUE 5.**
///
/// *"Let's stop over complicating things — the app has just one mode — portrait
/// mode — it doesn't rotate if the screen is rotated, and also it doesn't
/// rotate even if the phone has auto rotate turned on! Everything stays in one
/// mode."*
///
/// ── WHY THIS IS TWO THINGS AND NOT ONE ───────────────────────────────────
///
/// There are two separate machines that can turn a screen sideways, and asking
/// only one of them politely is why "I locked it" reports keep coming back.
///
///   * **Android**, via `android:screenOrientation` on the activity. This is
///     the authoritative one: it is read by the window manager before Flutter
///     exists, so the very first frame is already upright and the recents
///     thumbnail is too. It also overrules the phone's auto-rotate setting,
///     which a Flutter-side preference alone does not do reliably on every
///     OEM's build — Samsung and Xiaomi both ship rotation behaviour of their
///     own on top of stock Android.
///
///   * **Flutter**, via [SystemChrome.setPreferredOrientations]. This is what
///     stops the engine from asking for a rotation back, which it will do on
///     any configuration change if nobody has said otherwise.
///
/// Doing both is not belt and braces for the sake of it. The manifest attribute
/// alone leaves the engine's preference unset, and the engine's preference
/// alone leaves a window that the system may still rotate before the first
/// Dart line runs.
///
/// ══ AND ON A TABLET, NEITHER OF THEM APPLIES ANY MORE ════════════════════
///
/// This used to end *"together there is no moment and no code path where the
/// app is anything but upright"*. That was true when it was written and it is
/// **false on the device this app is judged on**, which is worth correcting
/// here rather than discovering from a screenshot. Two rules overrule both
/// machines above:
///
///   * In **multi-window mode** Android has always ignored an activity's
///     orientation request, and ignores [SystemChrome.setPreferredOrientations]
///     with it. Split screen can be short and wide however firmly either half
///     of this asks otherwise.
///   * Since **Android 16**, for an app targeting SDK 36 — which this one does
///     — the system additionally ignores orientation, resizability and
///     aspect-ratio restrictions on any display whose smallest width is 600dp
///     or more. The Redmi Pad is 686dp.
///
/// So this is now a **phone** rule. It is kept, because a phone is where he
/// asked for it and it still works there; what has gone is the claim that it
/// is absolute. **ROUND FIFTEEN, ISSUE 12** — *"when using split screen or
/// floating screen — I want you to set that the app is responsive then too!"*
/// — is the same fact arriving from his side, and the answer is that every
/// screen is built at those sizes in `responsive_test.dart` and walked through
/// a live resize in `resizing_test.dart`.
///
/// ── WHAT IS DELIBERATELY NOT EXCEPTED ────────────────────────────────────
///
/// Video. The usual instinct is to let a video player rotate, because every
/// other video player does. He said *everything* stays in one mode, and he is
/// right for this app: a journal that flips sideways while you are watching
/// something back, then flips again on the way out, is a journal that moved
/// under you. The video viewer fills the width and letterboxes, which is what
/// it did in portrait anyway.
abstract final class PortraitOnly {
  /// The orientations the app will accept. Exactly one.
  ///
  /// `portraitDown` is **not** here. Upside-down portrait is a rotation, and
  /// on most phones it is the one nobody ever wants — it happens when the
  /// handset is put down on a table, not when somebody meant it.
  static const List<DeviceOrientation> allowed = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ];

  /// Asks the engine to keep the app upright.
  ///
  /// Called once from `main`, before `runApp`, so it is in force before the
  /// first frame rather than after it.
  static Future<void> apply() =>
      SystemChrome.setPreferredOrientations(allowed);
}
