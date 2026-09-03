
import 'package:flutter/services.dart';

/// The Dart half of the fingerprint.
///
/// Narrow on purpose. It seals and unseals **one 32-byte per-device secret**,
/// and knows nothing about the vault, the DEK, or what the secret is for. The
/// key that does the sealing lives in Android's secure element and never enters
/// this process at all — see `BiometricVault.kt` for what that buys and for the
/// enrolment trap it closes.
abstract final class Biometrics {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// What this phone can do.
  static Future<BiometricStatus> status() async {
    try {
      final s = await _channel.invokeMethod<String>('biometricStatus');
      return switch (s) {
        'ready' => BiometricStatus.ready,
        'none_enrolled' => BiometricStatus.noneEnrolled,
        'no_hardware' => BiometricStatus.noHardware,
        _ => BiometricStatus.unavailable,
      };
    } catch (_) {
      return BiometricStatus.unavailable;
    }
  }

  /// Seals [secret] behind the fingerprint. Null if the user cancelled.
  static Future<SealedSecret?> enrol(Uint8List secret) async {
    try {
      final m = await _channel
          .invokeMapMethod<String, Object?>('biometricEnrol', {'secret': secret});
      if (m == null) return null;
      return SealedSecret(
        sealed: m['sealed']! as String,
        iv: m['iv']! as String,
      );
    } on PlatformException catch (e) {
      if (e.message == _cancelled) return null;
      throw BiometricFailure(e.message ?? 'That did not work.');
    }
  }

  /// Opens what [enrol] sealed. Null if the user cancelled or chose the
  /// passcode instead.
  static Future<Uint8List?> unlock({
    required String sealed,
    required String iv,
  }) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'biometricUnlock',
        {'sealed': sealed, 'iv': iv},
      );
    } on PlatformException catch (e) {
      if (e.message == _cancelled) return null;
      if (e.message == _invalidated) throw const BiometricInvalidated();
      throw BiometricFailure(e.message ?? 'That did not work.');
    }
  }

  static Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('biometricClear');
    } catch (_) {}
  }

  static const _cancelled = 'cancelled';
  static const _invalidated = 'invalidated';
}

enum BiometricStatus {
  ready,
  noneEnrolled,
  noHardware,
  unavailable;

  bool get usable => this == BiometricStatus.ready;

  /// What to tell the user, in words rather than a status code.
  String get describe => switch (this) {
        BiometricStatus.ready => 'Ready',
        BiometricStatus.noneEnrolled =>
          'Add a fingerprint in your phone settings first',
        BiometricStatus.noHardware => 'This phone has no fingerprint reader',
        BiometricStatus.unavailable => 'Not available on this phone',
      };
}

class SealedSecret {
  const SealedSecret({required this.sealed, required this.iv});

  final String sealed;
  final String iv;
}

/// The keystore key is gone, which almost always means a fingerprint was added
/// or removed on the phone.
///
/// **That is the feature working, not failing.** The key is destroyed on
/// enrolment change on purpose, so somebody who can unlock the phone once
/// cannot add their own finger and inherit the vault. The passcode still opens
/// everything; the fingerprint just has to be set up again.
class BiometricInvalidated implements Exception {
  const BiometricInvalidated();

  @override
  String toString() =>
      'Your fingerprints changed, so Lamplight turned off fingerprint unlock. '
      'Your notes are safe — open with your passcode and you can set it up '
      'again.';
}

class BiometricFailure implements Exception {
  const BiometricFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
