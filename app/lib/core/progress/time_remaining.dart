import 'dart:math' as math;

/// How much longer a long job has to run, estimated honestly.
///
/// ── WHAT HE ASKED FOR ────────────────────────────────────────────────────
///
/// > *"On the place where the loading happens before uploading use - Time
/// > Remaining on long jobs"*
///
/// Five screens in this app run something long enough to watch: the backup,
/// the restore, the readable copy, bringing in an old journal, and sealing a
/// large attachment. Every one of them already reports a fraction, and every
/// one of them showed a percentage and nothing else — which tells you where
/// you are and not the one thing you actually want to know, which is whether
/// there is time to put the phone down.
///
/// ── THE PART THAT IS EASY TO GET WRONG ───────────────────────────────────
///
/// A remaining-time estimate is trivial arithmetic and almost always a lie,
/// and the lie has a shape: it is enormous and wrong at the start, because a
/// couple of hundred milliseconds of the first chunk get extrapolated across
/// the whole job. Everyone has seen "27 minutes remaining" become "3 seconds"
/// and stopped believing any of them. Once a progress estimate has lied to
/// somebody twice, it is worse than the percentage it replaced, because now
/// the screen is confidently telling them something they know is false.
///
/// So this deliberately says **nothing** until it can say something true:
///
///   * not before [_minimumElapsed] has passed, and
///   * not before [_minimumFraction] of the work is done, and
///   * not at all if the whole job looks like finishing inside
///     [_notWorthSaying] — a number that appears and vanishes is noise.
///
/// [remaining] returns null in every one of those cases and the caller shows
/// the percentage alone, exactly as before. **Saying nothing is a supported
/// answer, and it is the default.**
///
/// ── WHY THE RATE IS SMOOTHED, AND WHY IT ONLY EVER FALLS ─────────────────
///
/// Work does not arrive evenly. A backup seals a 40 MB video and then twelve
/// notes; the instantaneous rate swings by two orders of magnitude and an
/// estimate built on it flickers between "8 minutes" and "12 seconds" while
/// somebody watches. The rate is therefore an exponential moving average
/// ([_smoothing]).
///
/// And the answer is **ratcheted downwards**: a new estimate is only shown if
/// it is lower than the one already on screen, or if it is enough higher to be
/// a genuine change of circumstance rather than jitter. A countdown that goes
/// up is the single most irritating thing a progress screen can do, and the
/// honest cases where it truly should — the phone throttling, a much larger
/// file arriving — are slow, so they survive the ratchet anyway.
class TimeRemaining {
  TimeRemaining({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Injected so the tests do not have to sleep. Nothing else uses it.
  final DateTime Function() _clock;

  /// Nothing is claimed before this much has actually happened. Both of these
  /// are floors on *evidence*, not on taste.
  static const Duration _minimumElapsed = Duration(seconds: 2);
  static const double _minimumFraction = 0.04;

  /// A job that will be over this soon does not need a countdown on it.
  static const Duration _notWorthSaying = Duration(seconds: 5);

  /// Weight of the newest sample in the moving average. Low, because the
  /// point is to survive one enormous chunk without being redrawn by it.
  static const double _smoothing = 0.2;

  DateTime? _startedAt;
  DateTime? _lastAt;
  double _lastFraction = 0;

  /// Fractions of the job per second, smoothed. Null until two samples.
  double? _rate;

  Duration? _shown;

  /// Feeds in the latest progress fraction, 0..1.
  ///
  /// Safe to call as often as the job reports; out-of-order and repeated
  /// fractions are ignored rather than treated as zero elapsed work.
  void update(double fraction) {
    final now = _clock();
    final f = fraction.clamp(0.0, 1.0);
    _startedAt ??= now;

    final last = _lastAt;
    if (last == null) {
      _lastAt = now;
      _lastFraction = f;
      return;
    }

    final dt = now.difference(last).inMicroseconds / 1e6;
    final df = f - _lastFraction;
    // A repeat, a rewind, or two samples inside the same microsecond. None of
    // those is evidence about the rate, and dividing by any of them is how an
    // estimator produces infinity.
    if (dt <= 0 || df <= 0) return;

    _lastAt = now;
    _lastFraction = f;

    final sample = df / dt;
    _rate = _rate == null ? sample : (_smoothing * sample) + ((1 - _smoothing) * _rate!);
  }

  /// The best honest answer right now, or null if there is not one.
  ///
  /// Null is not a failure and callers must render it as *no line at all*
  /// rather than as "unknown" — a screen that says "time remaining: unknown"
  /// has spent a row of space to say nothing.
  Duration? get remaining {
    final started = _startedAt;
    final rate = _rate;
    if (started == null || rate == null || rate <= 0) return null;
    if (_lastFraction >= 1) return null;
    if (_lastFraction < _minimumFraction) return null;
    if (_clock().difference(started) < _minimumElapsed) return null;

    final seconds = (1 - _lastFraction) / rate;
    // Guards against a rate so small it produces a duration that overflows
    // when rendered. Anything over an hour is not a number worth showing on a
    // phone; it is a sign the job is not going to finish while they watch.
    if (!seconds.isFinite || seconds > 3600) return null;

    final estimate = Duration(milliseconds: (seconds * 1000).round());
    if (estimate < _notWorthSaying && _shown == null) return null;

    final shown = _shown;
    if (shown == null) {
      _shown = estimate;
      return estimate;
    }
    // The ratchet. Down freely; up only past a margin that jitter cannot
    // reach, so a genuine slowdown still gets through.
    if (estimate <= shown || estimate > shown * 1.5) {
      _shown = estimate;
      return estimate;
    }
    return shown;
  }

  /// Back to knowing nothing. Call between runs on a screen that is reused.
  void reset() {
    _startedAt = null;
    _lastAt = null;
    _lastFraction = 0;
    _rate = null;
    _shown = null;
  }

  /// Rounds [d] to the unit a person would use out loud.
  ///
  /// Nobody says "one minute and seventeen seconds left". They say "about a
  /// minute". The rounding is deliberately coarse **and gets coarser as the
  /// number gets bigger**, because precision the estimate does not have is
  /// precision it should not display.
  static Duration humanise(Duration d) {
    final s = d.inSeconds;
    if (s <= 10) return const Duration(seconds: 10);
    if (s < 60) return Duration(seconds: (s / 10).ceil() * 10);
    if (s < 600) return Duration(minutes: math.max(1, (s / 60).round()));
    return Duration(minutes: (s / 300).ceil() * 5);
  }
}
