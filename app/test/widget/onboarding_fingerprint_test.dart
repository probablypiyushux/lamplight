import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/biometrics.dart';

/// **"One more notable change", 24 August 2026.**
///
/// *"If the mobile support fingerprint or face ID? Please set it up from the
/// very beginning the app is set up! Don't make it tedious that a user needs to
/// go to the setting and find that! Make it possible from the very start!"*
///
/// Onboarding now offers it, between the phrase check and the name — but only
/// on a phone that can actually do it. The rule this pins down is the one that
/// decides whether the screen appears at all: **a screen that says "your phone
/// does not support this" is a screen that wasted somebody's time**, and a
/// permanently greyed switch is a small daily reminder of something the user
/// cannot fix. Settings has taken the same view since it was built; this makes
/// the two agree.
void main() {
  test('offered when the phone is ready', () {
    expect(BiometricStatus.ready.usable, isTrue);
  });

  test('not offered when there is no hardware', () {
    expect(BiometricStatus.noHardware.usable, isFalse);
  });

  test('not offered when nothing is enrolled', () {
    // Nothing to authenticate against. Sending somebody into the system
    // fingerprint settings from the middle of onboarding, to come back and
    // resume, is exactly the tedium he was objecting to.
    expect(BiometricStatus.noneEnrolled.usable, isFalse);
  });

  test('not offered when the platform could not be asked', () {
    expect(BiometricStatus.unavailable.usable, isFalse);
  });

  test('every status can explain itself', () {
    for (final status in BiometricStatus.values) {
      expect(status.describe, isNotEmpty, reason: '$status');
    }
  });
}
