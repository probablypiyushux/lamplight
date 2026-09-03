import 'package:flutter/services.dart';

/// Whether the phone may capture this app's screen.
///
/// The Dart half of `setScreenSecurity` in `MainActivity.kt`. See
/// `AppSettings.allowScreenshots` for what is being traded and why it is a
/// setting rather than the build flag it used to be.
///
/// **The window is secure before this is ever called.** `MainActivity` sets
/// `FLAG_SECURE` unconditionally, before `super.onCreate`, so the first frame
/// of every launch is covered; this only ever *relaxes* that, and only when the
/// user has asked. Reading the setting first and then deciding would leave a
/// window capturable on every cold start, which is exactly when the system
/// takes the recents thumbnail.
abstract final class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Applies [allow]. Safe to call as often as you like; the platform side is
  /// two window-flag calls and no allocation.
  static Future<void> allowCapture(bool allow) async {
    try {
      await _channel.invokeMethod<void>('setScreenSecurity', {'allow': allow});
    } catch (_) {
      // A phone that will not take the call keeps the secure default, which is
      // the right direction to fail in. Nothing else depends on this.
    }
  }
}
