import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/app_info.dart';

/// The version constants are checked, not remembered.
///
/// `kAppVersion` is written into every backup file's header so that someone
/// opening one in 2035 can tell which build wrote it. A constant that has
/// drifted from `pubspec.yaml` is worse than no version field at all: it
/// answers the question confidently and wrongly, and nothing in a normal
/// working day would ever surface it.
///
/// `kAppBuild` is the `+N` in `pubspec.yaml`, which becomes Android's
/// `versionCode`. It has its own failure mode: Android refuses an update whose
/// versionCode is not higher than the installed one, and the Play Store retires
/// a versionCode permanently once it has seen it. A drifted build number is
/// therefore not a cosmetic problem — it is an update that silently does not
/// happen. See `lib/core/app_info.dart` for the whole argument.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// `version: 1.2.3+45` — the semantic version and the build number.
  final match = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
          multiLine: true)
      .firstMatch(pubspec);

  test('pubspec.yaml states a version and a build number', () {
    expect(match, isNotNull,
        reason: 'pubspec.yaml needs a line of the form `version: 1.2.3+45`. '
            'The `+45` is the build number and Android will not ship without '
            'one.');
  });

  test('kAppVersion matches pubspec.yaml', () {
    expect(
      kAppVersion,
      match!.group(1),
      reason: 'lib/core/app_info.dart has drifted from pubspec.yaml. Both have '
          'to say the same thing, because the backup format writes this one '
          'into files that outlive the app. `tool/bump_version.ps1` changes '
          'both at once so this cannot happen by hand.',
    );
  });

  test('kAppBuild matches pubspec.yaml', () {
    expect(
      kAppBuild,
      int.parse(match!.group(2)!),
      reason: 'the build number in lib/core/app_info.dart has drifted from '
          'pubspec.yaml. pubspec is what Android actually ships, so a drifted '
          'constant means Settings and every copied bug report name a build '
          'that was never built.',
    );
  });

  test('the build number is a real one', () {
    // Not a range check on the future — just a floor. A zero or negative
    // versionCode is rejected by the Android build, and finding that out from
    // Gradle rather than from here wastes a five-minute build.
    expect(kAppBuild, greaterThanOrEqualTo(1));
  });

  test('the label a person quotes carries both', () {
    // Settings shows this, and so does the copyable failure report. A report
    // that names only "0.2.0" cannot distinguish the build that had the bug
    // from the build that fixed it, which is the entire reason the report has
    // a version in it.
    expect(kAppVersionLabel, contains(kAppVersion));
    expect(kAppVersionLabel, contains('$kAppBuild'));
  });
}
