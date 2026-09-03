@Tags(['tool'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/lamp_mark.dart';
import 'package:lamplight/design/star_map.dart';
import 'package:lamplight/design/tokens.dart';

/// The two pictures Google Play asks for. **ROUND FIFTEEN, ISSUE 14.**
///
/// > *"Make it play store ready now dude!"*, and, in the same message, the
/// > list: *"App Icon: 512 x 512 pixels (32-bit PNG, max 1MB). Feature
/// > Graphic: 1024 x 500 pixels."*
///
/// Run it deliberately, like the launcher icons:
///
/// ```
/// flutter test tool/generate_store_assets_test.dart --tags tool
/// ```
///
/// Output lands in `app/store/`, which is gitignored — these are build
/// products, regenerable from source in one command, and a repository is not
/// an asset library.
///
/// ── WHY THESE ARE DRAWN AND NOT DESIGNED ─────────────────────────────────
///
/// The same argument as `generate_icon_test.dart`, and it matters more here
/// rather than less. A store icon made in a design tool is a file nobody can
/// regenerate, that drifts from the app's own mark the first time the palette
/// moves, and that has to be found again in two years by somebody who does not
/// have the tool. Drawn from [LampMarkPainter] and [LamplightColors], the store
/// icon and the icon on the phone **cannot** disagree: they are the same paint
/// calls at a different size.
///
/// The feature graphic is the same principle applied to the thing this app is
/// actually about. It is the night sky the app draws on its own pages —
/// `star_map.dart`, at the real sidereal geometry — with the lamp on the left
/// and nothing else. **No screenshot, no device frame, no slogan set in a
/// typeface nobody has.** A 1024 x 500 banner is 25 mm tall on a phone and any
/// words on it are unreadable; every one that tries anyway is noise.
void main() {
  const dark = LamplightColors.dark;

  final out = Directory('store');

  test('the 512 store icon', () async {
    // ── Square to the edges, and that is the important part ──────────────
    //
    // **Play rounds this itself.** The console masks the icon into its own
    // shape on every surface it appears on, and a corner rounded here as well
    // would arrive as *transparent* — which Play composites onto white, so the
    // icon gets four pale notches inside Play's own rounding. The launcher
    // tile is rounded at 0.22 because Android below API 26 does no masking;
    // this one must not be.
    //
    // No alpha anywhere, for the same reason: the plate runs to all four
    // edges.
    await _square(
      File('${out.path}/icon-512.png'),
      LampMarkPainter(
        shade: dark.inkPrimary,
        glow: dark.accent,
        backdrop: [dark.raised, dark.canvas],
        contentScale: 0.72,
      ),
      512,
    );

    final bytes = await File('${out.path}/icon-512.png').length();
    expect(bytes, lessThan(1024 * 1024),
        reason: 'Play refuses an icon over 1 MB, and this one is a gradient '
            'and a lamp — if it is ever near the limit something has gone '
            'wrong rather than got detailed');
    // ignore: avoid_print
    print('icon-512.png  $bytes bytes');
  });

  test('the 1024 x 500 feature graphic', () async {
    const width = 1024;
    const height = 500;
    final size = Size(width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(Offset.zero & size, Paint()..color = dark.canvas);

    // The app's own sky, at the app's own geometry. `turn` is fixed rather
    // than taken from the clock: a store banner regenerated tomorrow should be
    // the same picture, and the whole argument for the star map turning is
    // about somebody's own page rather than about a shop window.
    StarMap.paint(
      canvas,
      size,
      turn: 1.1,
      dark: true,
      base: dark.canvas,
      ink: dark.inkPrimary,
      glow: dark.accent,
    );

    // The lamp, on the left third, at the size it is on the lock screen. Left
    // rather than centred because Play crops this banner from both sides on
    // some surfaces and the centre is the first thing to survive — but the
    // *mark* is what has to survive, and it is safer near the middle than at
    // an edge. A third in is the compromise every banner guide arrives at.
    const markSize = 260.0;
    canvas.save();
    canvas.translate(width * 0.30 - markSize / 2, (height - markSize) / 2);
    LampMarkPainter(
      shade: dark.inkPrimary,
      glow: dark.accent,
      contentScale: 1.0,
    ).paint(canvas, const Size(markSize, markSize));
    canvas.restore();

    // A soft pool of the lamp's own light falling to the right of it, so the
    // banner has somewhere for the eye to go and the mark is not a sticker on
    // a photograph. The same warm accent at the same low alphas the Lamplit
    // page uses — this is one gradient, not an effect.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(width * 0.30, height / 2),
          width * 0.55,
          [
            dark.accent.withValues(alpha: 0.10),
            dark.accent.withValues(alpha: 0.03),
            dark.accent.withValues(alpha: 0.0),
          ],
          [0.0, 0.45, 1.0],
        ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    if (data == null) throw StateError('could not encode the feature graphic');
    await out.create(recursive: true);
    final file = File('${out.path}/feature-graphic-1024x500.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    // ignore: avoid_print
    print('feature-graphic-1024x500.png  ${await file.length()} bytes');
    expect(await file.length(), greaterThan(1000));
  });

  test('and it says where they went', () async {
    // ignore: avoid_print
    print('wrote into ${out.absolute.path}');
    expect(out.existsSync(), isTrue);
    // Not committed. See the note at the top of this file.
    expect(math.max(0, 1), 1);
  });
}

/// Paints one square PNG at [size].
Future<void> _square(File file, CustomPainter painter, int size) async {
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
