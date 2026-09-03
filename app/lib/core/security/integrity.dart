import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';

/// What the app can tell about the phone it is running on.
///
/// ── THIS IS A REPORT, NOT A GATE ─────────────────────────────────────────
///
/// Nothing here refuses to run, locks anybody out, or wipes anything. That is
/// a deliberate refusal of what "root detection" usually means, and the
/// reasoning is in `Integrity.kt` at length. The short version:
///
/// Every check runs **inside the process it is trying to protect**, on hardware
/// the attacker controls. A Magisk module hides the files; Frida rewrites the
/// function before it returns. An app that blocks on a root check is one patch
/// away from not blocking, and it has spent that security locking out the
/// honest person who roots their own phone.
///
/// What a report *does* buy is real: somebody whose phone is rooted, or who has
/// USB debugging on, is carrying a risk they may not know about, and telling
/// them is worth more than pretending to defend against it. The sentences it
/// produces say what the risk actually is, in words, with no jargon and no
/// alarm.
class Integrity {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Cheap — a handful of file checks and three property reads. Run on demand
  /// from a settings screen, never on a path anybody is waiting on.
  static Future<IntegrityReport> check() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('integrityCheck');
      if (m == null) return const IntegrityReport(details: [], signer: '');
      return IntegrityReport(
        details: (m['findings'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(),
        signer: m['signer'] as String? ?? '',
      );
    } catch (_) {
      // The platform side is not there — a test, or a desktop build. Silence
      // is the right answer: an inability to check is not a finding.
      return const IntegrityReport(details: [], signer: '');
    }
  }
}

class IntegrityReport {
  const IntegrityReport({required this.details, required this.signer});

  /// One plain sentence per finding, already written for a person to read.
  final List<String> details;

  /// SHA-256 of the certificate this build was signed with, so somebody can
  /// compare it by hand against the one published with the source.
  final String signer;

  bool get isClean => details.isEmpty;

  String describeIn(L l) {
    if (isClean) return l.integrityNothingUnusual;
    return details.join(' ');
  }
}
