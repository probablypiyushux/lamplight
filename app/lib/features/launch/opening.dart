import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../design/lamp_mark.dart';
import '../../design/tokens.dart';

/// The lamp being switched on, once, when the app opens.
///
/// WHY THIS EXISTS AT ALL, GIVEN THE DESIGN SYSTEM SAYS NOT TO
///
/// `08-design/DESIGN-SYSTEM.md` is explicit: nothing longer than 300ms, "motion
/// only to explain a spatial relationship — never decorative". This is 1.1
/// seconds and it explains nothing. On the face of it it is exactly what that
/// rule forbids, and it was built anyway, deliberately, on the owner's
/// instruction. That is written down rather than smoothed over, because a
/// design system whose exceptions are undocumented stops being a system.
///
/// The case for it: the same document allows **one signature moment**, and for
/// an app called Lamplight there is only one candidate. A lamp coming on is not
/// decoration in the sense the rule means — it is the app's own metaphor,
/// performed once, on the only screen where nothing else is happening. The rule
/// exists to stop motion being sprinkled over working surfaces, and this is not
/// on a working surface.
///
/// WHAT KEEPS IT HONEST
///
/// - **It happens once per cold start**, never on unlock, never on navigation.
/// - **It is skippable.** One tap anywhere ends it. Nobody is ever made to
///   watch a lamp turn on when they came to write something down.
/// - **`prefers-reduced-motion` skips it entirely** — not shortened, skipped.
///   `ACCESSIBILITY.md` requires the flag be honoured, and for someone with a
///   vestibular disorder a slow bloom is precisely the wrong thing.
/// - **The geometry is the launcher icon's**, drawn by the same painter. The
///   app appears to grow out of the icon that was tapped rather than cutting to
///   an unrelated screen.
/// - **It never delays anything.** The vault is already initialised by the time
///   this is on screen; this plays over the top and gets out of the way.
class Opening extends StatefulWidget {
  const Opening({super.key, required this.onDone});

  final VoidCallback onDone;

  /// The whole thing.
  ///
  /// **Cut from 1150ms to 700ms**, because 1150 was wrong. It was chosen by
  /// looking at the animation and asking whether it read well, which is the
  /// wrong question — the right one is what it feels like on the fortieth
  /// launch of the day, on top of the engine starting and libsodium
  /// initialising. Reported, accurately, as "the app has become a lot slower,
  /// it seems to stuck".
  ///
  /// An intro is a cost paid by every launch forever to make an impression
  /// once. 700ms is about as long as that cost can be worth paying, and it is
  /// still skippable with a tap.
  static const Duration duration = Duration(milliseconds: 700);

  @override
  State<Opening> createState() => _OpeningState();
}

class _OpeningState extends State<Opening> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Opening.duration,
  );

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    // Started in the first frame rather than here, so the reduced-motion check
    // below has a MediaQuery to read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _finish();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.canvas,
      body: GestureDetector(
        // Skippable, and the whole screen is the target. Someone who opens this
        // app forty times a day should be able to get past it without aiming.
        onTap: _finish,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          label: L.of(context).openingLabel,
          excludeSemantics: true,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final p = Curves.easeOutCubic.transform(_controller.value);
                // The wordmark arrives last, once there is light to read it by.
                final word = ((_controller.value - 0.62) / 0.38).clamp(0.0, 1.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: LampMarkPainter(
                          shade: c.inkPrimary,
                          glow: c.accent,
                          progress: p,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.x5),
                    Opacity(
                      opacity: Curves.easeOut.transform(word),
                      child: Text(L.of(context).appName, style: t.displaySmall),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
