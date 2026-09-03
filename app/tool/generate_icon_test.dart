@Tags(['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/lamp_mark.dart';
import 'package:lamplight/design/tokens.dart';

/// Generates the launcher icons. Not a test — a build tool wearing a test's
/// clothes.
///
/// Run it deliberately:
///
/// ```
/// flutter test tool/generate_icon_test.dart
/// ```
///
/// It lives in `tool/` rather than `test/` precisely so that `flutter test`
/// does **not** run it. A suite that rewrites twenty binary files every time
/// anyone checks their work would produce a permanently dirty git status and
/// teach everyone to ignore it.
///
/// WHY A TEST FILE AT ALL
///
/// Painting the mark needs `dart:ui` — real paths, real gradients, real
/// anti-aliasing. A plain `dart run` script has no Flutter engine behind it and
/// cannot rasterise anything, and the alternatives are a design tool (whose
/// output nobody can regenerate) or an image package (a dependency, for an icon).
/// `flutter test` already carries an engine. So the icon is drawn by the same
/// [LampMarkPainter] the app draws on its own lock screen, and the launcher and
/// the app can never show two different marks.
void main() {
  const legacyBase = 48.0; // dp, the classic launcher icon
  const adaptiveBase = 108.0; // dp, Android's adaptive canvas
  const notificationBase = 24.0; // dp, the status bar's one size

  // The five density buckets, and their multipliers.
  const densities = <String, double>{
    'mdpi': 1,
    'hdpi': 1.5,
    'xhdpi': 2,
    'xxhdpi': 3,
    'xxxhdpi': 4,
  };

  // Tokens, not invented values. The icon is the palette's own argument drawn
  // as a picture, so it has to be made of the palette.
  const dark = LamplightColors.dark;
  const light = LamplightColors.light;
  final backdrop = [dark.raised, dark.canvas];
  // The light plate, two stops like the dark one. `surface` above `canvas` is
  // the same one-step lift, so the two icons are the same drawing rather than
  // one drawing and one flat rectangle.
  final lightBackdrop = [light.surface, light.canvas];

  final res = Directory('android/app/src/main/res');

  test('launcher icons', () async {
    for (final entry in densities.entries) {
      final scale = entry.value;
      final dir = Directory('${res.path}/mipmap-${entry.key}');
      await dir.create(recursive: true);

      // ── The legacy icon: mark, backdrop, rounded square ─────────────────────
      // Used below API 26 and by launchers that ignore adaptive icons. 0.22 of
      // the side is the iOS corner proportion, which is what "in the manner of
      // iOS app icons" means in practice.
      await _write(
        File('${dir.path}/ic_launcher.png'),
        LampMarkPainter(
          shade: dark.inkPrimary,
          glow: dark.accent,
          backdrop: backdrop,
          cornerRadiusFraction: 0.22,
          // Slightly inset, so the mark has air inside its own square.
          contentScale: 0.84,
        ),
        (legacyBase * scale).round(),
      );

      // ── Adaptive: background ────────────────────────────────────────────────
      // A full square with no rounding at all. The launcher applies whichever
      // mask it has decided on — circle, squircle, teardrop — and any corner we
      // rounded ourselves would be visible as a notch inside it.
      await _write(
        File('${dir.path}/ic_launcher_background.png'),
        _BackdropOnlyPainter(backdrop),
        (adaptiveBase * scale).round(),
      );

      // ── Adaptive: foreground ────────────────────────────────────────────────
      // 0.667 keeps the mark inside the 72-of-108 safe zone, so no mask can
      // clip it. Transparent everywhere else.
      await _write(
        File('${dir.path}/ic_launcher_foreground.png'),
        LampMarkPainter(
          shade: dark.inkPrimary,
          glow: dark.accent,
          contentScale: 0.667,
        ),
        (adaptiveBase * scale).round(),
      );

      // ── Adaptive: foreground, light ─────────────────────────────────────────
      //
      // ISSUE 6: *"the light-mode app icon is ugly as fuck"*, and he was
      // right — it was a white lamp on a white ground.
      //
      // The cause was one shared file. `ic_launcher_light.xml` swapped the
      // *plate* to warm paper and went on pointing at the **dark** foreground,
      // whose shade is `dark.inkPrimary` — a near-white #F2F0EA. Near-white ink
      // on #FAF9F5 paper is a contrast ratio of about 1.1:1, which is to say
      // there was nothing to see. The dark icon was fine because the same
      // drawing on near-black is 16.8:1.
      //
      // The light icon needs its own foreground, drawn in the light palette's
      // own ink and its own deeper amber — which exist, are verified in
      // `CONTRAST-REPORT.md`, and were simply never used here. Nothing about
      // the mark changes; only which end of the palette draws it.
      await _write(
        File('${dir.path}/ic_launcher_foreground_light.png'),
        LampMarkPainter(
          shade: light.inkPrimary,
          glow: light.accent,
          contentScale: 0.667,
        ),
        (adaptiveBase * scale).round(),
      );

      // ── The legacy light icon ───────────────────────────────────────────────
      // Below API 26 there is no adaptive icon to compose, so the light variant
      // needs a whole tile of its own. It had none at all, so a phone older
      // than Android 8 fell back to the dark one and the alias swap did
      // nothing — quieter than the white-on-white, and just as wrong.
      await _write(
        File('${dir.path}/ic_launcher_light.png'),
        LampMarkPainter(
          shade: light.inkPrimary,
          glow: light.accent,
          backdrop: lightBackdrop,
          cornerRadiusFraction: 0.22,
          contentScale: 0.84,
        ),
        (legacyBase * scale).round(),
      );

      // ── Adaptive: one foreground per accent, per mode. ISSUE 6b ─────────────
      //
      // *"The request is that the icon's light takes the colour of the chosen
      // accent"* — he showed amber against purple.
      //
      // **What that costs, stated plainly, because the shape of the solution is
      // not obvious from the request.** Launcher icons are static: they are
      // manifest attributes read by the launcher and fixed at install time, and
      // there is no runtime tint. So "the icon follows the accent" means one
      // `activity-alias` per accent per mode, each pointing at its own drawable,
      // with exactly one enabled — which is the same mechanism the light/dark
      // swap already uses, twelve ways instead of two.
      //
      // Only the **glow** changes: the bulb and the cone of light, which is
      // precisely "the icon's light takes the colour". The lampshade stays the
      // palette's own ink, because the shade is the object and the light is the
      // accent — and because a shade that changed colour would be six different
      // marks rather than one mark under six lamps.
      //
      // Amber keeps the original filenames, so the default icon's drawables are
      // the ones that were already there and a phone that has never been near
      // this feature is unaffected.
      for (final accent in LampAccent.values) {
        if (accent == LampAccent.amber) continue;
        await _write(
          File('${dir.path}/ic_launcher_fg_${accent.id}.png'),
          LampMarkPainter(
            shade: dark.inkPrimary,
            glow: accent.dark,
            contentScale: 0.667,
          ),
          (adaptiveBase * scale).round(),
        );
        await _write(
          File('${dir.path}/ic_launcher_fg_${accent.id}_light.png'),
          LampMarkPainter(
            shade: light.inkPrimary,
            glow: accent.light,
            contentScale: 0.667,
          ),
          (adaptiveBase * scale).round(),
        );
      }

      // ── The notification icon. ISSUE 24 ─────────────────────────────────────
      //
      // > *"I get notification it shows me default app icon!"*
      //
      // It was `ic_launcher_monochrome` — the adaptive icon's third layer,
      // borrowed. That is a **108dp** canvas with the mark drawn at 0.667 of
      // it, because an adaptive icon has to survive being masked to a circle by
      // a launcher that will not say in advance how big the circle is.
      //
      // A status bar icon is a **24dp** canvas with no mask at all, and the
      // convention every other app on the phone follows is content filling
      // about 20 of those 24. Scaling the adaptive layer down to fit gave a
      // lamp two-thirds the size of everything beside it, in a slot 24 pixels
      // wide — small enough that it read as a placeholder rather than as this
      // app's mark, which is exactly what he said it looked like.
      //
      // So it is drawn for the size it will be shown at. Flat white, because
      // Android throws the colour away and uses only the alpha — a notification
      // icon is a silhouette tinted by the system, not a picture.
      //
      // `1.03` looks wrong and is measured. `contentScale` is the box the mark
      // is laid out in, and the mark does not fill its box — it keeps about a
      // tenth of it as air on each side, which is right for a launcher tile and
      // is a waste of a 24dp slot. 1.03 puts the drawn pixels at exactly 20 of
      // 24, which is the padding every other notification icon on the phone
      // uses. Change it and check the alpha bounding box, not the number.
      //
      // In `drawable-` rather than `mipmap-`, which is the other half of the
      // convention: `mipmap` exists so a launcher can pull a *higher* density
      // than the phone's own for its icon, and nothing but a launcher icon
      // wants that.
      final notificationDir = Directory('${res.path}/drawable-${entry.key}');
      await notificationDir.create(recursive: true);
      await _write(
        File('${notificationDir.path}/ic_notification.png'),
        LampMarkPainter(
          shade: const Color(0xFFFFFFFF),
          glow: const Color(0xFFFFFFFF),
          contentScale: 1.03,
          monochrome: true,
        ),
        (notificationBase * scale).round(),
      );

      // ── Adaptive: monochrome ────────────────────────────────────────────────
      // Android 13+ tints this to the user's wallpaper palette for themed
      // icons. Any colour here is discarded, so the mark is drawn flat.
      await _write(
        File('${dir.path}/ic_launcher_monochrome.png'),
        LampMarkPainter(
          shade: const Color(0xFFFFFFFF),
          glow: const Color(0xFFFFFFFF),
          contentScale: 0.667,
          monochrome: true,
        ),
        (adaptiveBase * scale).round(),
      );
    }

    // ── The master ────────────────────────────────────────────────────────────
    // 1024, for a store listing and for anyone who needs the mark at size.
    // Kept with the design documents rather than in the app, because it is a
    // design artefact and not something the app ships.
    final design = Directory('../08-design');
    if (await design.exists()) {
      await _write(
        File('${design.path}/app-icon-1024.png'),
        LampMarkPainter(
          shade: dark.inkPrimary,
          glow: dark.accent,
          backdrop: backdrop,
          cornerRadiusFraction: 0.22,
          contentScale: 0.84,
        ),
        1024,
      );
      // Both of them, side by side, so the light one can never again be judged
      // only on a phone.
      await _write(
        File('${design.path}/app-icon-1024-light.png'),
        LampMarkPainter(
          shade: light.inkPrimary,
          glow: light.accent,
          backdrop: lightBackdrop,
          cornerRadiusFraction: 0.22,
          contentScale: 0.84,
        ),
        1024,
      );
    }
  });
}

/// Paints one square PNG.
Future<void> _write(File file, CustomPainter painter, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  if (data == null) throw StateError('could not encode ${file.path}');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
}

/// The adaptive background layer: the gradient plate and nothing else.
class _BackdropOnlyPainter extends CustomPainter {
  const _BackdropOnlyPainter(this.colours);

  final List<Color> colours;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
            rect.topCenter, rect.bottomCenter, colours),
    );
  }

  @override
  bool shouldRepaint(_BackdropOnlyPainter old) => old.colours != colours;
}
