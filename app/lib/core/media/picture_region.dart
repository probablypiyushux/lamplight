import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Reading one rectangle of a picture, at the size it will be drawn.
///
/// ── WHY ────────────────────────────────────────────────────────────────────
///
/// Round nine, **ISSUE IMPORTANT**: *"When I zoom photos sometimes the app
/// closes."* And then, before the first fix was finished, the correction that
/// decided the design: *"nah I want you to make it possible to view tall
/// screenshots too!"*
///
/// Both halves of that are right and they pull in opposite directions if you
/// only have one dial. A decoded picture costs four bytes a pixel, so the whole
/// of a very tall screenshot at full detail is hundreds of megabytes and the
/// process is killed. Decode it smaller and it is safe and unreadable — which,
/// for a screenshot, is the entire reason it was kept.
///
/// The way out is not a better number. It is to stop decoding the whole
/// picture. **What costs memory is what is on the screen, and the screen is
/// always the same size.** Ask for the visible rectangle at the resolution it
/// is actually being shown, and a 60,000-pixel-tall screenshot costs exactly
/// what a small photograph costs — and every pixel of it can be read.
///
/// This app already had that idea. `MemoryPdf.kt` has rendered PDF tiles rather
/// than whole pages since round six, and `zoom_tile.dart` is the arithmetic,
/// shared now rather than written twice.
///
/// ── HOW ────────────────────────────────────────────────────────────────────
///
/// Android's `BitmapRegionDecoder`, which has existed since API 10 and is what
/// every gallery on the phone uses. Flutter's own decoder cannot do this —
/// `getTargetSize` scales the whole image and has no notion of a crop — so this
/// is one of the few places where going to the platform is the *simple* option
/// rather than the clever one.
///
/// ── WHAT IT IS NOT ─────────────────────────────────────────────────────────
///
/// It is not the path an ordinary photograph takes when you open it. The base
/// image is still decoded by Flutter, still cached by `ImageCache`, still
/// budgeted by [EncryptedImage.maxPixels]. This is only ever asked for **once
/// somebody has zoomed in**, which is the only time the extra detail exists to
/// be seen. A person who never pinches never spends a byte on any of it.
abstract final class PictureRegion {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// The picture's size in pixels, read from its header.
  ///
  /// No pixels are decoded. This is what lets the viewer know it is holding
  /// something enormous before it tries to draw it.
  static Future<ui.Size> measure(Uint8List bytes) async {
    final m = await _channel
        .invokeMapMethod<String, Object?>('measureImage', {'bytes': bytes});
    final width = m?['width'];
    final height = m?['height'];
    if (width is! int || height is! int || width <= 0 || height <= 0) {
      throw const PictureUnreadable();
    }
    return ui.Size(width.toDouble(), height.toDouble());
  }

  /// Decodes [region] — in source pixels — to an image no wider than
  /// [targetWidth] device pixels.
  ///
  /// [targetWidth] is a ceiling and not a promise: subsampling is by powers of
  /// two, which is the only thing a region decoder offers and the only thing
  /// that avoids allocating the full crop first. The result is therefore
  /// between [targetWidth] and twice it, never more, and drawn into whatever
  /// box the widget gives it.
  static Future<ui.Image> decode({
    required Uint8List bytes,
    required ui.Rect region,
    required int targetWidth,
  }) async {
    final left = region.left.floor();
    final top = region.top.floor();
    final right = region.right.ceil();
    final bottom = region.bottom.ceil();
    final width = right - left;
    if (width <= 0 || bottom - top <= 0) throw const PictureUnreadable();

    final m = await _channel.invokeMapMethod<String, Object?>(
      'decodeImageRegion',
      {
        'bytes': bytes,
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
        'sample': sampleFor(sourceWidth: width, targetWidth: targetWidth),
      },
    );

    final pixels = m?['pixels'];
    final w = m?['width'];
    final h = m?['height'];
    if (pixels is! Uint8List || w is! int || h is! int) {
      throw const PictureUnreadable();
    }

    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(pixels),
      width: w,
      height: h,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
      descriptor.dispose();
    }
  }

  /// The power-of-two subsampling that brings [sourceWidth] down to about
  /// [targetWidth] without going under it.
  ///
  /// Halving stops one step early on purpose. A region decoder can only divide
  /// by powers of two, so the choice at every step is between slightly more
  /// pixels than the screen can show and slightly fewer — and slightly fewer is
  /// a visibly soft picture, which is the thing being fixed. The overshoot is
  /// at most 2× in each direction, so at most four times the screen's pixels,
  /// and that is a fixed cost that does not grow with the picture.
  ///
  /// Public and pure so `zoom_tile_test.dart` can check it with numbers.
  static int sampleFor({required int sourceWidth, required int targetWidth}) {
    if (targetWidth <= 0 || sourceWidth <= targetWidth) return 1;
    var sample = 1;
    while (sourceWidth ~/ (sample * 2) >= targetWidth) {
      sample *= 2;
      // Android ignores anything past this and it is far past any real screen.
      if (sample >= 32) break;
    }
    return sample;
  }
}

/// The picture could not be read at all.
///
/// Never reaches the viewer as a failure: the base image is already on screen
/// by the time any of this runs, so the worst case is that zooming shows the
/// softer version, which is what it did before any of this existed.
class PictureUnreadable implements Exception {
  const PictureUnreadable();

  @override
  String toString() => 'That picture could not be read.';
}
