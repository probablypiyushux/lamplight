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

  test('the label identifies the artefact on its own', () {
    // ── This used to require the build number too, and that was right then ──
    //
    // The old label was `0.5.0 (build 21)`, and the old comment said a report
    // naming only "0.5.0" cannot distinguish the build that had the bug from
    // the build that fixed it. True, because the version moved rarely and the
    // build number moved every time.
    //
    // The scheme changed on 4 September at his request -- *"why keep it 0.5.0
    // (Build 21)"*. The minor is the day and the patch is the artefact within
    // it, so the version now moves on every build and carries the information
    // the build number used to. `0.6.3` is the third thing built on the second
    // day.
    //
    // So the property is unchanged and only its carrier moved: **the label
    // must name exactly one artefact.** `kAppBuild` still climbs, because Play
    // demands it; it is simply no longer a number a person is shown.
    expect(kAppVersionLabel, kAppVersion);
    expect(kAppVersionLabel, isNot(contains('build')));
    expect(
      RegExp(r'^\d+\.\d+\.\d+$').hasMatch(kAppVersion),
      isTrue,
      reason: 'The version is what identifies a build now, so it has to be a '
          'full three-part number rather than a marketing string.',
    );
  });

  test('the version knows which day it belongs to', () {
    // `tool/bump_version.ps1` compares this against today to decide whether to
    // move the minor. Without it every build would be a new "day".
    expect(
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(kVersionDay),
      isTrue,
      reason: 'kVersionDay must be an ISO date; bump_version.ps1 parses it.',
    );
  });
}
