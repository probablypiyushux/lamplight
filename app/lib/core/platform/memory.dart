import 'package:flutter/painting.dart';

/// What Lamplight gives back, and when.
///
/// ══ THE REPORT, AND THE NUMBERS UNDERNEATH IT ═══════════════════════════
///
/// > *"THE APP IDK SUDDENLY CLOSES"* — round fifteen, ISSUE 4.
///
/// It was diagnosed then as the low-memory killer rather than a crash, and
/// that was right and incomplete. `dumpsys activity exit-info` on his phone,
/// read on 23 September 2026:
///
/// ```
/// timestamp=2026-09-06 03:08:48  reason=3 (LOW_MEMORY)
/// pss=257MB  rss=338MB  importance=400  state=empty
/// ```
///
/// **`state=empty` is the whole finding.** The app was not killed while he was
/// using it. It was killed as a *cached* process — nothing on screen, nothing
/// running — and Android's LMK takes the **largest** cached process first. A
/// backgrounded Lamplight was sitting on a quarter of a gigabyte and was
/// therefore the most attractive thing on the phone to reclaim.
///
/// So the symptom is not "the app crashes". It is "the app is not where I left
/// it", every time something else needs room. Which is worse, because it looks
/// like forgetfulness rather than a fault, and because it gets more common the
/// cheaper the phone.
///
/// ── WHAT WAS ACTUALLY MISSING ───────────────────────────────────────────
///
/// Two things, and the first is the one that matters:
///
///   1. **Nothing in this app had ever responded to memory pressure.** Android
///      calls `onTrimMemory`, the engine forwards it to
///      `WidgetsBindingObserver.didHaveMemoryPressure`, and nothing
///      implemented it. The system asked, every time, and was never answered.
///   2. `ImageCache` was left at its default **100 MB** of decoded bitmaps, in
///      an app whose whole content is photographs.
///
/// Neither is a leak, which is why nothing looked wrong: every byte was
/// reachable, wanted, and would have been used again. It was simply never
/// given back at the one moment giving it back is free.
///
/// ── WHY THIS IS NOT THE SAME THING AS LOCKING ───────────────────────────
///
/// `app.dart` already clears the image cache when the vault locks, and that is
/// a **security** measure — decoded photographs must not outlive the keys. It
/// happens to free memory, and it cannot be relied on to: a vault that is
/// *already* locked when the app is backgrounded changes no state, so nothing
/// fires, and the process stays fat for as long as it is cached. That is
/// exactly the state the kill above was recorded in.
///
/// Trimming is the opposite trade and has to be reasoned about separately:
/// nothing here is destroyed, only dropped. Every byte released can be rebuilt
/// from the vault on demand, so the cost is a decode — and on the path this
/// app takes, a decrypt before it. That is why [trim] is called when the app is
/// **not on screen** and when the system asks, and never while somebody is
/// looking at a page.
abstract final class LampMemory {
  /// The decoded-image budget.
  ///
  /// Flutter's default is 100 MB and 1,000 images. Both are generous for a
  /// phone and neither was chosen for this app.
  ///
  /// 48 MB is roughly four full-screen photographs at the size the viewer
  /// actually asks for — `memory_ceiling_test.dart` holds that arithmetic —
  /// which is enough to swipe an album back and forth without re-reading, and
  /// not enough to hold a gallery nobody is looking at any more.
  ///
  /// **Deliberately not smaller.** A miss here is not a decode, it is a
  /// *decrypt* and then a decode, on a file that may be four megabytes. Being
  /// mean with this cache would trade a memory number the user cannot see for
  /// a stutter they can.
  static const int imageCacheBytes = 48 << 20;

  /// The count bound, which catches what the byte bound cannot: a few hundred
  /// thumbnails are individually tiny and collectively a live set that never
  /// shrinks.
  static const int imageCacheCount = 150;

  /// Applied once, from `main`, before the first frame.
  static void configure() {
    PaintingBinding.instance.imageCache
      ..maximumSizeBytes = imageCacheBytes
      ..maximumSize = imageCacheCount;
  }

  /// Give back everything that can be rebuilt.
  ///
  /// Called when the app leaves the screen and when Android asks. Safe to call
  /// repeatedly and safe to call when there is nothing to release.
  ///
  /// `clearLiveImages` as well as `clear`, and the difference matters: `clear`
  /// empties the cache but leaves the *live* set — images still referenced by
  /// a widget — pinned. A backgrounded day screen holds references to every
  /// photograph on it, so without the second call the tiles he was looking at
  /// before pressing home stay in memory for as long as the process is cached,
  /// which is precisely the population that made it the biggest one.
  static void trim() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  /// The whole-binding version, for when the system says it is urgent.
  ///
  /// Goes further than [trim]: the engine drops its own raster and shader
  /// caches too, which Dart cannot reach directly. Separate because it throws
  /// away work that a plain backgrounding has no reason to.
  ///
  /// **No forced frame afterwards, deliberately.** The obvious next line is to
  /// schedule one so the screen is correct again — and it is exactly wrong
  /// here. This runs when the system is short of memory and usually when the
  /// app is not on screen at all; repainting everything is the one thing
  /// guaranteed to allocate again immediately. Flutter re-decodes what it
  /// needs on the next real frame, which is the frame after the user comes
  /// back, which is the correct moment.
  static void trimHard() {
    trim();
    PaintingBinding.instance.handleMemoryPressure();
  }
}
