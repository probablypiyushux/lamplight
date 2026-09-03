import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/design/tokens.dart';

/// **ROUND EIGHT, ISSUE 2B — the video player's controls.**
///
/// *"Video player aesthetics lacks! I want you to keep it up! Make it better!"*
///
/// The panel is glass now instead of a 94%-opaque slab parked on the film, and
/// that change is only safe because of a scrim underneath it. This file is the
/// arithmetic for that claim, because "it looks fine" is not something to leave
/// unstated about a control panel laid over arbitrary video.
///
/// ── WHY THIS IS SUMS RATHER THAN A WIDGET TEST ───────────────────────────
///
/// The player needs a platform texture and a real decoder; it cannot be pumped.
/// What can be checked is the thing that would actually be wrong — whether the
/// numbers chosen for the scrim and the panel keep the labels readable over the
/// worst frame a video can produce, which is a pure function of four constants.
void main() {
  double contrast(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  Color over(Color top, double alpha, Color bottom) => Color.fromARGB(
        255,
        ((top.r * alpha + bottom.r * (1 - alpha)) * 255).round(),
        ((top.g * alpha + bottom.g * (1 - alpha)) * 255).round(),
        ((top.b * alpha + bottom.b * (1 - alpha)) * 255).round(),
      );

  // The four numbers the player is built from. Changing any of them here
  // without changing them there — or the other way round — is what this file
  // is for.
  const scrimAlpha = 0.78; // black, at the bottom edge
  const panelAlpha = 0.84; // surface, over the scrim

  /// The worst case: a completely white frame under the controls.
  Color panelOverWhite(LamplightColors c) {
    const film = Color(0xFFFFFFFF);
    final scrimmed = over(const Color(0xFF000000), scrimAlpha, film);
    return over(c.surface, panelAlpha, scrimmed);
  }

  /// And the other worst case, for the light palette: a black frame.
  Color panelOverBlack(LamplightColors c) {
    const film = Color(0xFF000000);
    final scrimmed = over(const Color(0xFF000000), scrimAlpha, film);
    return over(c.surface, panelAlpha, scrimmed);
  }

  group('the labels survive the worst frame a video can show', () {
    for (final entry in {
      'dark': LamplightColors.dark,
      'light': LamplightColors.light,
    }.entries) {
      final c = entry.value;

      test('${entry.key}: the elapsed time over a white frame', () {
        expect(contrast(c.inkPrimary, panelOverWhite(c)),
            greaterThanOrEqualTo(4.5),
            reason: 'a snowfield is a real video and the clock has to be '
                'readable over it');
      });

      test('${entry.key}: the time remaining over a white frame', () {
        // The quietest ink actually used on the panel, which makes it the
        // binding case. It was `inkMuted` until this test measured it at 4.28
        // on the dark palette and worse on the light one — the quietest ink in
        // the system is for a label on a known surface, and this is glass over
        // arbitrary film.
        expect(contrast(c.inkSecondary, panelOverWhite(c)),
            greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: and over a black frame', () {
        expect(contrast(c.inkSecondary, panelOverBlack(c)),
            greaterThanOrEqualTo(4.5));
      });
    }
  });

  test('the scrim is what makes the glass legal', () {
    // Stated as a comparison rather than as a claim: without the scrim, a
    // 78%-opaque panel over a white frame fails, and that is exactly the
    // mistake this arrangement exists to avoid. If somebody removes the scrim
    // and keeps the transparency, this is the test that says why not.
    const film = Color(0xFFFFFFFF);
    final c = LamplightColors.dark;

    final withoutScrim = over(c.surface, panelAlpha, film);
    expect(contrast(c.inkSecondary, withoutScrim), lessThan(4.5),
        reason: 'glass over bare film is unreadable — the scrim is not '
            'decoration');

    expect(contrast(c.inkSecondary, panelOverWhite(c)),
        greaterThanOrEqualTo(4.5),
        reason: 'and with the scrim it is fine');
  });

  test('the panel is close enough to opaque that nothing else moved', () {
    // The old panel was `surface` at 94% with a hairline. Over the scrim, the
    // new one lands within a few points of that — so this is a change in what
    // you can see *through* it, not a change in what the controls look like.
    final c = LamplightColors.dark;
    final oldPanel = over(c.surface, 0.94, const Color(0xFF808080));
    expect(contrast(oldPanel, panelOverWhite(c)), lessThan(1.6));
  });
}
