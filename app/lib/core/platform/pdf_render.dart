import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'document_store.dart';

/// The Dart half of `MemoryPdf.kt`. **ISSUE 4.**
///
/// A PDF in the vault is a pile of encrypted chunks with a random name. This
/// hands the decrypted bytes to Android's own `PdfRenderer` through a proxy
/// file descriptor served from memory, gets back raw pixels, and turns them
/// into a Flutter image. **Nothing is written to disk at any point** — see the
/// long note at the top of `MemoryPdf.kt` for why that needed a proxy
/// descriptor rather than the pipe the audio and video players use.
///
/// One document is open at a time, which matches the native side and matches
/// what a person does. Opening a second replaces the first.
abstract final class PdfRender {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// The largest document opened in place.
  ///
  /// The plaintext sits in RAM for as long as the viewer is up, so this is a
  /// real limit rather than a cautious one. 48 MiB covers a long scanned
  /// document at photographic quality and stops a phone being asked to hold a
  /// 400 MB technical manual. Above it the viewer says so and offers to save a
  /// copy — which is the honest answer, and is not the same as doing nothing.
  static const int maxBytes = 48 * 1024 * 1024;

  /// Opens [bytes] and reports how many pages it has and what shape they are.
  static Future<OpenPdf> open(Uint8List bytes) async {
    try {
      final m = await _channel
          .invokeMapMethod<String, Object?>('openPdf', {'bytes': bytes});
      final pages = (m?['pages'] as int?) ?? 0;
      final shapes = (m?['shapes'] as List?)?.cast<double>() ?? const <double>[];
      return OpenPdf(pages: pages, shapes: shapes);
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'That document could not be opened.');
    }
  }

  // ══ ONE RENDER AT A TIME, AND THE FLICK THAT PROVED IT ══════════════════
  //
  // > *"When scroll down Fastly down to the end it behaves jerky and when
  // > scrolled up Fastly – feels jerky!"*
  //
  // The platform side is a single-threaded executor, so requests were already
  // serialised **over there**. What was not serialised was the asking: a fast
  // fling builds and disposes a page widget every few frames, and every one of
  // them fired a render on the way past. Thirty requests would queue up behind
  // each other for pages that had already gone, and the page you actually
  // stopped on waited for all of them.
  //
  // A queue of one, here, with the newest request winning. Each caller carries
  // a [_generation]; a request whose page is no longer wanted is dropped before
  // it ever reaches the channel rather than after it has cost 40 ms of encode.
  static Future<void> _busy = Future<void>.value();

  /// Runs [work] after whatever is already in flight, and returns its result.
  ///
  /// Not a general-purpose queue: it exists so that the *channel* sees one
  /// render at a time, which is what stops a fling from building a backlog.
  static Future<T> _queued<T>(Future<T> Function() work) {
    final result = _busy.then((_) => work());
    // Swallowed so one failure does not poison the queue for the next caller.
    _busy = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Draws part of page [page] at about [width] device pixels across.
  ///
  /// [region] is a rectangle of the page in normalised coordinates — (0,0) is
  /// the top-left corner of the page and (1,1) the bottom-right. Null asks for
  /// the whole page, which is what the unzoomed list wants.
  ///
  /// **ISSUE 1.** Zoom asks for a smaller [region] at the same [width] rather
  /// than for the whole page at a larger one. That is the difference between a
  /// bitmap that grows with the magnification until the process dies and one
  /// that stays the size of the screen however far in you go. The long version
  /// is in `MemoryPdf.kt`.
  static Future<ui.Image> page(
    int page, {
    required int width,
    Rect? region,

    /// Answered just before the channel call. False means the caller has moved
    /// on — a page flung past, a tile whose zoom has changed — and the request
    /// is dropped rather than costing a render nobody will look at.
    bool Function()? stillWanted,
  }) =>
      _queued(() => _page(page, width: width, region: region, stillWanted: stillWanted));

  static Future<ui.Image> _page(
    int page, {
    required int width,
    Rect? region,
    bool Function()? stillWanted,
  }) async {
    if (stillWanted != null && !stillWanted()) {
      throw const PdfRenderAbandoned();
    }
    final Map<String, Object?>? m;
    try {
      m = await _channel.invokeMapMethod<String, Object?>('renderPdfPage', {
        'page': page,
        'width': width,
        if (region != null)
          'region': <double>[
            region.left,
            region.top,
            region.right,
            region.bottom,
          ],
      });
    } on MissingPluginException {
      throw const DocumentStoreUnavailable();
    } on PlatformException catch (e) {
      throw DocumentStoreError(e.message ?? 'That page could not be drawn.');
    }
    if (m == null) throw const DocumentStoreError('That page could not be drawn.');

    final bytes = m['pixels'] as Uint8List;

    // ══ THE BYTES ARE WEBP NOW, NOT RAW RGBA ═══════════════════════════════
    //
    // This used to be `decodeImageFromPixels`, with a comment saying a codec
    // would be "a second copy for nothing" because the bytes were already raw.
    // The reasoning was sound and the premise was the problem: raw is what made
    // this slow. A page on his tablet is around 1700x2400, which is **16 MB**
    // crossing the method channel for every page of every document, arriving on
    // the platform thread and hopping to the UI thread. logcat showed single
    // frames of 1,824 ms — *"it feels like it has a stroke"*.
    //
    // `MemoryPdf.kt` encodes to WebP on its worker thread instead, so what
    // arrives is a few hundred kilobytes. And `instantiateImageCodec` is the
    // right call for compressed bytes for a second reason beyond size: it
    // decodes on Flutter's own IO thread, so the work that is left does not
    // touch the frame pump at all.
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  /// Lets go of the document and everything behind it.
  ///
  /// Called from the viewer's `dispose`, and again when the vault locks —
  /// somebody's papers must not survive the passcode going away.
  static Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('closePdf');
    } catch (_) {
      // Closing something that is already closed is not a failure.
    }
  }
}

/// What a document turned out to be. **ROUND FIFTEEN, ISSUE 8.**
class OpenPdf {
  const OpenPdf({required this.pages, required this.shapes});

  final int pages;

  /// Height / width for each page, measured at open.
  ///
  /// Shorter than [pages] on a very long document — see `MemoryPdf.pageShapes`
  /// — and empty on a platform that does not measure. [shapeOf] handles both.
  final List<double> shapes;

  /// The shape of page [i], or A4 when it was not measured.
  ///
  /// A4 is what the viewer assumed for every page before this existed, so a
  /// document whose shapes are unavailable behaves exactly as it used to rather
  /// than not at all.
  double shapeOf(int i) =>
      i >= 0 && i < shapes.length && shapes[i] > 0 ? shapes[i] : 1.414;
}

/// A render that was dropped because nobody wanted it any more.
///
/// Thrown rather than returned null so a caller cannot mistake it for a
/// failure worth showing. Nothing was lost and nothing needs saying.
class PdfRenderAbandoned implements Exception {
  const PdfRenderAbandoned();
  @override
  String toString() => 'That page was scrolled past before it was drawn.';
}
