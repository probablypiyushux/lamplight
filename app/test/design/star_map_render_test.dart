@Tags(['render'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/star_map.dart';
import 'package:lamplight/design/tokens.dart';

/// Renders the sky to PNGs so a person can look at it. **ISSUE 7C.**
///
/// Not an assertion about anything, and tagged `render` so `flutter test` skips
/// it: a star map is a thing you judge by looking, and the app itself refuses
/// screenshots on every build — `FLAG_SECURE` is on from the first frame, and
/// only Piyush can turn it off, from inside the vault. This is the only way
/// anybody working on this file can see what they have changed.
///
/// ```
/// flutter test test/design/star_map_render_test.dart --tags render
/// ```
///
/// It writes into `TEMP/lamplight_sky/`, which is outside the repo. Nothing it
/// produces is user content and nothing is committed.
void main() {
  test('draw a sky at several hours', () async {
    // A real face, or every glyph is a filled rectangle and the one question
    // this file exists to answer — can you read the words — cannot be asked.
    // EB Garamond is the app's serif and is what the day screen is set in.
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('EBGaramond')
      ..addFont(File('assets/fonts/EBGaramond-400.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(b.buffer)));
    await loader.load();

    final out = Directory('${Directory.systemTemp.path}/lamplight_sky');
    out.createSync(recursive: true);

    // The Redmi Pad, halved so the files are quick to look at. PLAN.md §0.
    const size = Size(686, 1143);

    Future<void> shot(String name, double turn, bool dark) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final base = dark ? const Color(0xFF0B0B0C) : const Color(0xFFF6F1E7);
      canvas.drawRect(Offset.zero & size, Paint()..color = base);
      StarMap.paint(
        canvas,
        size,
        turn: turn,
        dark: dark,
        base: base,
        ink: dark ? const Color(0xFFF2EDE4) : const Color(0xFF1A1714),
        glow: const Color(0xFFE0A458),
      );
      final image = await recorder
          .endRecording()
          .toImage(size.width.round(), size.height.round());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(
          bytes!.buffer.asUint8List(), flush: true);
    }

    // The question that actually decides whether this can ship: a page is
    // something somebody writes on, so the sky has to be behind the words
    // without being underneath them.
    //
    // **ISSUE 9 — the halo, with and without.** The colours below are the real
    // palette rather than approximations of it, because the whole question is
    // whether the writing survives the chart and a lighter page would answer
    // it too kindly. `halo: true` is what the app now ships on this surface;
    // `halo: false` is the screenshot he sent.
    Future<void> withWriting(String name, double turn, bool dark,
        {bool halo = false}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final colours = dark ? LamplightColors.dark : LamplightColors.light;
      final base = colours.canvas;
      final ink = colours.inkPrimary;
      canvas.drawRect(Offset.zero & size, Paint()..color = base);
      StarMap.paint(canvas, size,
          turn: turn,
          dark: dark,
          base: base,
          ink: ink,
          glow: colours.accent);

      final shadows = halo ? pageHalo(base) : null;

      void write(String text, double y, double fontSize, Color colour) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: fontSize,
                color: colour,
                height: 1.5,
                fontFamily: 'EBGaramond',
                shadows: shadows),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 6,
        )..layout(maxWidth: size.width - 48);
        tp.paint(canvas, Offset(24, y));
      }

      write('26 August', 60, 34, ink);
      write('WEDNESDAY', 108, 12, colours.inkSecondary);
      write(
          'Rained all afternoon so we stayed in. She fell asleep against the '
          'window and I did not want to move.',
          160,
          17,
          ink);
      write('22:02', 300, 13, colours.inkSecondary);
      write('Anything you want to keep?', 330, 17, colours.inkMuted);

      final image = await recorder
          .endRecording()
          .toImage(size.width.round(), size.height.round());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List(), flush: true);
    }

    await withWriting('writing_dark', 0, true);
    await withWriting('writing_light', 0, false);
    await withWriting('writing_dark_halo', 0, true, halo: true);
    await withWriting('writing_light_halo', 0, false, halo: true);

    for (var hour = 0; hour < 24; hour += 6) {
      await shot('dark_${hour.toString().padLeft(2, '0')}h',
          hour * 15.04 * math.pi / 180, true);
    }
    await shot('light_00h', 0, false);
    // The Appearance preview tile, at the size it is actually drawn.
    // ignore: avoid_print
    print('wrote ${out.path}');
  });
}
