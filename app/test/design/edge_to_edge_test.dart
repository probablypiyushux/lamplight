import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/edge_to_edge.dart';

/// **ROUND NINETEEN — the Play Console's edge-to-edge warning.**
///
/// > *"From Android 15, apps targeting SDK 35 will display edge-to-edge by
/// > default. Apps targeting SDK 35 should handle insets to make sure that
/// > their app displays correctly on Android 15 and later."*
///
/// This app targets **36**, so the behaviour was already in force on every
/// Android 15 phone it had been installed on, including the closed-testing
/// ones. The warning is not "please opt in to something new" — it is "the
/// opt-out you were relying on is gone", and the two jobs it used to do are
/// now the app's own:
///
///   1. keep content out from under the bars, and
///   2. keep the bars' own icons legible against whatever is behind them.
///
/// The second is the one nothing in Flutter does by default, and the one that
/// produces a white clock on cream paper.
void main() {
  group('the bars stay readable against the page behind them', () {
    test('a light page gets dark icons', () {
      final style = EdgeToEdge.styleFor(Brightness.light);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    });

    test('a dark page gets light icons', () {
      final style = EdgeToEdge.styleFor(Brightness.dark);
      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });

    // The classic version of this bug, and it is invisible on whichever
    // platform the author happened to be testing: `statusBarBrightness` is
    // iOS and describes the BAR, `statusBarIconBrightness` is Android and
    // describes the ICONS. They are always opposites.
    test('the iOS field is the inverse of the Android one', () {
      for (final page in Brightness.values) {
        final style = EdgeToEdge.styleFor(page);
        expect(style.statusBarBrightness, isNot(style.statusBarIconBrightness),
            reason: 'one names the bar and the other names what is drawn on '
                'it; equal means one of them is wrong');
      }
    });

    // Deprecated and ignored under Android 15 — the platform composites the
    // bars over the app's own pixels, so the colour behind them is whatever
    // the app painted. Transparent is the only honest value.
    test('and nothing pretends to colour them', () {
      final style = EdgeToEdge.styleFor(Brightness.light);
      expect(style.statusBarColor, Colors.transparent);
      expect(style.systemNavigationBarColor, Colors.transparent);
    });
  });

  group('it is actually turned on, and actually applied', () {
    test('main asks for edge-to-edge before the first frame', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('EdgeToEdge.apply()'),
          reason: 'Android 15 imposes this anyway; asking for it explicitly is '
              'what makes Android 14 and below behave the same way, so that '
              'the layout reviewed on one phone is the layout that ships on '
              'the other');
      // Before runApp, not after — the first frame is the one that matters.
      expect(main.indexOf('EdgeToEdge.apply()'),
          lessThan(main.indexOf('runApp(')));
    });

    test('and the overlay style follows the RESOLVED theme, not the phone',
        () {
      final app = File('lib/app.dart').readAsStringSync();
      expect(app, contains('EdgeToEdge.styleFor(Theme.of(context).brightness)'),
          reason: 'the theme can be Dark, Light or follow the phone. Reading '
              'platformBrightness here would be wrong for everybody who chose '
              'one explicitly, and reading the setting would be wrong for '
              'everybody on System default.');
      expect(app, contains('AnnotatedRegion<SystemUiOverlayStyle>'),
          reason: 'declarative, so it re-applies when the theme changes '
              'instead of once during startup');
    });
  });

  // ── Content, not just icons ──────────────────────────────────────────────
  //
  // The other half of the warning. Every screen with a `Scaffold` of its own
  // has to keep its content out from under the bars, either with a `SafeArea`
  // or by being built on `LampPage`, which carries one.
  //
  // `day_screen` is the deliberate exception and is worth naming rather than
  // excluding silently: it uses `SafeArea(bottom: false)` so the page itself
  // runs to the bottom edge — the paper is meant to be full-bleed — and the
  // capture bar sitting on top of it carries its own `SafeArea` instead.
  test('every screen with a Scaffold handles its insets', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      if (!src.contains('Scaffold(')) continue;
      final handled = src.contains('SafeArea(') ||
          src.contains('LampPage(') ||
          src.contains('viewPadding') ||
          src.contains('viewInsets');
      // The opening animation is one centred mark on a full-bleed canvas with
      // nothing near an edge to be clipped. It is allowed to fill the window.
      if (!handled && !entity.path.contains('opening.dart')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'these screens draw a Scaffold but never mention an inset, so '
            'on Android 15 their content sits under the status bar or the '
            'gesture pill');
  });
}
