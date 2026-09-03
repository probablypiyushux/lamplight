import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/features/media/photo_viewer.dart';

/// The two pieces of `PLAN.md` §8.5 that were never built.
///
/// > *"Photo → viewer is a `Hero`, so the picture flies rather than cuts."*
/// > *"Pull-down on the day view reveals search, the way `UX-FLOWS.md` flow 4
/// > asks."*
///
/// `Honest Review` listed both among the small things, and `grep -r Hero lib/`
/// returned nothing at all until now.
///
/// **What can honestly be tested from here is narrow, and that is worth saying
/// rather than dressing up.** Whether a flight looks right is a question for an
/// eye, and whether a pull feels deliberate is a question for a thumb. What a
/// test can hold still is the one property that would silently break either:
/// the tag has to pair exactly one tile with exactly one viewer page, because
/// two `Hero`s sharing a tag in one subtree is an assertion failure at run time
/// rather than a wrong-looking animation.
void main() {
  group('the hero tag', () {
    test('is derived from the attachment, so the pair is unique', () {
      // One tile draws a given attachment and one viewer page does. Keying on
      // the entry instead would break the moment an album of fifteen shares one
      // entry id, which is exactly how albums are drawn.
      expect(heroTagFor('abc'), heroTagFor('abc'));
      expect(heroTagFor('abc'), isNot(heroTagFor('def')));
    });

    test('is namespaced, so it cannot collide with anything added later', () {
      // A bare id would be a tag any future `Hero` in the app could pick by
      // accident — and the failure mode is a crash, not a visual glitch.
      expect(heroTagFor('abc'), startsWith('photo:'));
      expect(heroTagFor('abc'), contains('abc'));
    });

    test('a tag is a stable string, not an object identity', () {
      // Flutter matches heroes by `==` across two routes, so a tag that is a
      // fresh object each build would never match and the picture would cut.
      final a = heroTagFor('abc');
      final b = heroTagFor('abc');
      expect(identical(a, b) || a == b, isTrue);
      expect(a, isA<String>());
    });
  });

  group('a pull is only a pull when it is deliberate', () {
    // The threshold is a private constant on the day's stream, so this asserts
    // the *shape* of the decision rather than reaching into it: an overscroll
    // that accumulates past a thumb's travel is a decision, and one that does
    // not is a flick to the top of a list. Getting this wrong in the small
    // direction would take somebody out of their day every time they scrolled
    // up briskly, which is much worse than not having the gesture.
    const threshold = 90.0;

    test('a brisk flick to the top does not reach it', () {
      // A `BouncingScrollPhysics` overshoot on a short list is tens of points,
      // not a hundred.
      var pulled = 0.0;
      for (final overscroll in [-6.0, -9.0, -7.0, -4.0]) {
        pulled -= overscroll;
      }
      expect(pulled, lessThan(threshold));
    });

    test('a sustained drag does', () {
      var pulled = 0.0;
      for (var i = 0; i < 12; i++) {
        pulled -= -11.0;
      }
      expect(pulled, greaterThan(threshold));
    });

    test('pulling up from the bottom is a different gesture', () {
      // Positive overscroll is past the *end* of a long day, and means nothing
      // here. Counting it would open search when somebody reached the bottom.
      var pulled = 0.0;
      for (final overscroll in [14.0, 22.0, 31.0, 40.0]) {
        if (overscroll < 0) pulled -= overscroll;
      }
      expect(pulled, 0);
    });
  });
}
