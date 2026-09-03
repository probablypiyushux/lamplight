import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../db/database.dart' show Attachment;
import '../storage/attachment_store.dart';

/// A photograph in the vault, as something Flutter can draw.
///
/// ── WHY THIS REPLACED `Image.memory` IN A `FutureBuilder` ─────────────────
///
/// The old code was four lines and every one of them was a performance bug:
///
/// ```dart
/// FutureBuilder(
///   future: importer.bytesOf(attachment),   // re-runs on EVERY rebuild
///   builder: (_, snap) => Image.memory(snap.data!),  // decodes at full size
/// )
/// ```
///
/// Three separate problems, and together they are the reported one — *"when I
/// am scrolling and it has two images then it just hangs"*.
///
///  1. **The future is created inside `build`.** Every rebuild — a keystroke,
///     a scroll that changes nothing, a theme tick — starts a *fresh* decrypt
///     of the whole photograph. Scrolling past two photos could easily mean
///     twenty decrypts.
///  2. **It decoded at full resolution.** A 12 MP photograph is 48 MB once
///     decoded, because a decoded image is four bytes per pixel regardless of
///     how well it compressed. Twenty of them on one day is a gigabyte, and
///     what actually happens long before that is the app is killed.
///  3. **All of it on the UI isolate**, so none of it could be overlapped with
///     drawing. See `AttachmentStore.readAllBytesOffThread`.
///
/// An `ImageProvider` fixes all three at once, and it does it by joining
/// Flutter's own machinery rather than by working around it:
///
///  * `ImageCache` keys on this object's `==`, so the *same photo at the same
///    target size* is decoded once and then handed out. Rebuilds are free.
///  * The decode happens through `getTargetSize`, which resizes **inside the
///    codec** — the full-size bitmap is never allocated at all, rather than
///    being allocated and then thrown away.
///  * The bytes arrive from a worker isolate, so the decrypt does not block a
///    frame.
///  * Flutter evicts it under memory pressure, without us writing an LRU.
///
/// ── AND THE FORMATS SKIA CANNOT READ ──────────────────────────────────────
///
/// Skia handles JPEG, PNG, GIF, WebP, BMP and ICO. It does not handle **HEIC**,
/// which is what every recent iPhone and a lot of Android phones save
/// photographs as. A photo imported straight from the camera roll would store
/// perfectly and then fail to display, which to the person looking at it is
/// indistinguishable from having lost it.
///
/// So a decode failure falls through to Android's own `ImageDecoder`, which
/// reads HEIC, HEIF and AVIF, and hands back raw pixels. It is a fallback and
/// not the main path: an ordinary JPEG never touches it.
@immutable
class EncryptedImage extends ImageProvider<EncryptedImage> {
  const EncryptedImage(
    this.attachment, {
    required this.store,
    this.maxWidth,
    this.maxPixels,
    this.scale = 1.0,
  });

  final Attachment attachment;
  final AttachmentStore store;

  /// Decode no wider than this, in physical pixels.
  ///
  /// **Set it.** Leaving it null decodes at native resolution, which is right
  /// for the full-screen viewer and wrong everywhere else. The day view passes
  /// the width of the column it is drawing into, times the device pixel ratio,
  /// and nothing more.
  final int? maxWidth;

  /// Decode no more than this many pixels in total. **Width × height.**
  ///
  /// ── WHY A WIDTH CAP WAS NOT ENOUGH, AND WHAT IT COST ──────────────────────
  ///
  /// *"When I zoom photos sometimes the app closes."* — round nine, filed
  /// without a number under **ISSUE IMPORTANT**, which is how he marks the ones
  /// that are not cosmetic.
  ///
  /// A decoded image is four bytes a pixel whatever it compressed to, and
  /// [maxWidth] bounds one side of that rectangle. It says nothing about the
  /// other. Feed it a photograph of a laptop screen — and his album is full of
  /// them; three of the screenshots in this round's own document are photos of
  /// a monitor — or any long screenshot, and the height is whatever the height
  /// was:
  ///
  /// | picture | at maxWidth 2520 | decoded |
  /// |---|---|---|
  /// | ordinary 4:3 | 2520 × 1890 | 19 MB |
  /// | portrait 3:4 | 2520 × 3360 | 34 MB |
  /// | a long screenshot, 1:6 | 2520 × 15120 | **152 MB** |
  ///
  /// The pager keeps the pages either side alive, so multiply by three. There
  /// is no arithmetic there that ends well, and the way Android ends it is by
  /// killing the process — which from the outside is the app closing while you
  /// are pinching, with no message, which is exactly what he described.
  ///
  /// **A budget is bounded by construction.** It cannot be defeated by an
  /// aspect ratio, by a device this was never measured on, or by a photograph
  /// somebody imports in 2028 from a camera that does not exist yet. That is
  /// the property worth having, and it is why this is here rather than a
  /// slightly smaller [maxWidth].
  ///
  /// Both caps apply when both are set; the smaller wins. `maxWidth` is still
  /// the right thing for a thumbnail, where the *column* is what matters and no
  /// thumbnail is ever big enough for the budget to bite.
  final int? maxPixels;

  final double scale;

  @override
  Future<EncryptedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<EncryptedImage>(this);

  @override
  ImageStreamCompleter loadImage(EncryptedImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: key.scale,
      debugLabel: 'lamplight:${key.attachment.id}@${key.maxWidth ?? "full"}',
      informationCollector: () => <DiagnosticsNode>[
        // Never the filename and never the content. A crash report or a debug
        // console is somewhere the user's own material must not appear, and
        // "attachment 3f2a…" is enough to debug with.
        DiagnosticsProperty<String>('attachment', key.attachment.id),
      ],
    );
  }

  Future<ui.Codec> _load(EncryptedImage key, ImageDecoderCallback decode) async {
    final bytes =
        await store.readAllBytesOffThread(key.attachment.id, key.attachment.fileKey);

    ui.TargetImageSize sizer(int intrinsicWidth, int intrinsicHeight) =>
        targetSizeFor(
          intrinsicWidth: intrinsicWidth,
          intrinsicHeight: intrinsicHeight,
          maxWidth: key.maxWidth,
          maxPixels: key.maxPixels,
        );

    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer, getTargetSize: sizer);
    } catch (_) {
      // Skia refused it. Ask Android.
      final decoded = await _PlatformImageDecoder.decode(
        bytes,
        maxDimension: key.maxWidth ?? 4096,
      );
      final descriptor = ui.ImageDescriptor.raw(
        await ui.ImmutableBuffer.fromUint8List(decoded.pixels),
        width: decoded.width,
        height: decoded.height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      return descriptor.instantiateCodec();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is EncryptedImage &&
      other.attachment.id == attachment.id &&
      other.maxWidth == maxWidth &&
      other.maxPixels == maxPixels &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(attachment.id, maxWidth, maxPixels, scale);

  @override
  String toString() => 'EncryptedImage(${attachment.id}, maxWidth: $maxWidth)';
}

/// The decode size a picture is allowed, given a width cap and a pixel budget.
///
/// Pulled out of the codec callback so it can be tested with numbers rather
/// than with images. The arithmetic is the whole of the ISSUE IMPORTANT fix —
/// see [EncryptedImage.maxPixels] — and arithmetic is worth a test, because a
/// picture big enough to prove this one would be a picture too big to keep in a
/// repository.
///
/// Aspect ratio is preserved and both sides are at least 1. Shrinking only:
/// a picture smaller than the budget is decoded as it is, never enlarged.
ui.TargetImageSize targetSizeFor({
  required int intrinsicWidth,
  required int intrinsicHeight,
  int? maxWidth,
  int? maxPixels,
}) {
  if (intrinsicWidth <= 0 || intrinsicHeight <= 0) {
    return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
  }

  // How much each cap says the picture must shrink by, as a linear factor.
  // The most demanding one wins, and 1.0 means "do not touch it".
  var factor = 1.0;

  if (maxWidth != null && intrinsicWidth > maxWidth) {
    factor = maxWidth / intrinsicWidth;
  }

  if (maxPixels != null) {
    final pixels = intrinsicWidth.toDouble() * intrinsicHeight;
    if (pixels > maxPixels) {
      // Area scales with the square of the linear factor, so the linear factor
      // that fits an area budget is the square root of the ratio.
      final byArea = math.sqrt(maxPixels / pixels);
      if (byArea < factor) factor = byArea;
    }
  }

  if (factor >= 1.0) {
    return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
  }

  // Floor rather than round, so rounding can never push the result back over a
  // budget it was just brought under. One pixel matters here only because a
  // test that asserts "at or under" should not fail on a rounding artefact.
  final width = (intrinsicWidth * factor).floor().clamp(1, intrinsicWidth);
  final height = (intrinsicHeight * factor).floor().clamp(1, intrinsicHeight);
  return ui.TargetImageSize(width: width, height: height);
}

class _RawImage {
  const _RawImage(this.width, this.height, this.pixels);

  final int width;
  final int height;
  final Uint8List pixels;
}

/// The HEIC/AVIF fallback. See the class comment above.
abstract final class _PlatformImageDecoder {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  static Future<_RawImage> decode(
    Uint8List bytes, {
    required int maxDimension,
  }) async {
    final m = await _channel.invokeMapMethod<String, Object?>(
      'decodeImage',
      {'bytes': bytes, 'maxDimension': maxDimension},
    );
    if (m == null) throw const UnreadableImage();
    final pixels = m['pixels'];
    final width = m['width'];
    final height = m['height'];
    if (pixels is! Uint8List || width is! int || height is! int) {
      throw const UnreadableImage();
    }
    return _RawImage(width, height, pixels);
  }
}

/// Every decoder on the phone refused it.
///
/// Said plainly, and it says what is still possible — because a photograph you
/// cannot see but can still get out of the app is a much smaller loss than one
/// you believe is gone.
class UnreadableImage implements Exception {
  const UnreadableImage();

  @override
  String toString() =>
      'This phone cannot open that picture. It is still here, and Save a copy '
      'will get it out.';
}
