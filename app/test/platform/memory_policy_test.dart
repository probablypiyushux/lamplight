import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/memory.dart';

/// **ROUND TWENTY — "THE APP IDK SUDDENLY CLOSES", measured.**
///
/// Round fifteen diagnosed this as the low-memory killer rather than a crash
/// and said, honestly, *"nothing in this project measures memory"*. This is the
/// measurement, and it is a policy test rather than a benchmark: what can be
/// pinned in a unit test is the **decision**, not the megabytes.
///
/// The evidence it was written against, from his phone on 23 September 2026:
///
/// ```
/// reason=3 (LOW_MEMORY)  pss=257MB  rss=338MB  importance=400  state=empty
/// ```
///
/// `state=empty` is the finding. The app was killed as a *cached* process,
/// and Android's LMK takes the largest cached process first — so the number
/// that mattered was never the peak while he was writing, it was the floor
/// while he was not.
void main() {
  group('the decoded-image budget is a decision, not a default', () {
    test('it is smaller than Flutter s 100 MB', () {
      const flutterDefault = 100 << 20;
      expect(LampMemory.imageCacheBytes, lessThan(flutterDefault));
    });

    // The other half, and the one that keeps somebody from "fixing" the memory
    // report by setting this to four megabytes. A miss on this cache is not a
    // decode — it is a **decrypt** and then a decode, on a file that may be
    // four megabytes. Too small trades a number nobody can see for a stutter
    // everybody can.
    test('and big enough to swipe an album without re-reading it', () {
      // A full-screen photograph at the size the viewer asks for, RGBA.
      const fullScreenPhoto = 1080 * 2400 * 4;
      expect(LampMemory.imageCacheBytes,
          greaterThan(fullScreenPhoto * 3),
          reason: 'fewer than about four full-screen pictures and swiping an '
              'album re-decrypts the one you just came from');
    });

    test('the count is bounded too, for the thumbnails', () {
      // A few hundred thumbnails are individually tiny and collectively a live
      // set that never shrinks, which the byte bound alone does not catch.
      expect(LampMemory.imageCacheCount, lessThan(1000));
      expect(LampMemory.imageCacheCount, greaterThan(50));
    });

    testWidgets('and it is actually applied to the binding', (tester) async {
      LampMemory.configure();
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes,
          LampMemory.imageCacheBytes);
      expect(PaintingBinding.instance.imageCache.maximumSize,
          LampMemory.imageCacheCount);
    });

    testWidgets('trim empties the cache and does not throw when empty',
        (tester) async {
      LampMemory.configure();
      LampMemory.trim();
      expect(PaintingBinding.instance.imageCache.currentSizeBytes, 0);
      // Idempotent: it runs on every backgrounding, including ones where
      // nothing has been drawn since the last.
      LampMemory.trim();
      LampMemory.trimHard();
      expect(PaintingBinding.instance.imageCache.currentSizeBytes, 0);
    });
  });

  // ── The two wirings, read from the source ────────────────────────────────
  //
  // Both are one line and both are invisible when absent, which is exactly how
  // they came to be absent for twenty rounds. A behavioural test would need a
  // real engine and a real Android; reading the source states the requirement
  // where the next person will find it.
  group('the app answers when the system asks', () {
    late String app;
    setUpAll(() => app = File('lib/app.dart').readAsStringSync());

    test('didHaveMemoryPressure is implemented', () {
      expect(app, contains('void didHaveMemoryPressure()'),
          reason: 'Android calls onTrimMemory, the engine forwards it here, '
              'and for twenty rounds nothing implemented this — so every '
              'request was dropped and the system took the memory by killing '
              'the process instead');
      expect(app, contains('LampMemory.trimHard()'));
    });

    test('and sheds what it can when it leaves the screen', () {
      expect(app, contains('LampMemory.trim()'),
          reason: 'the lock path clears the cache for security, but only on a '
              'CHANGE of state — an already-locked vault backgrounded fires '
              'nothing, and state=empty is where the kill was recorded');
    });

    test('the budget is set before the first frame', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('LampMemory.configure()'));
      expect(main.indexOf('LampMemory.configure()'),
          lessThan(main.indexOf('runApp(')));
    });
  });
}
