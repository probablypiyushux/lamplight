/// How long somebody actually spent writing the thing they just wrote.
///
/// > *"Time Spent writing? a small text which says that! it would be good!
/// > encouraging people!"*
///
/// ── WHAT THIS IS ALLOWED TO BE, AND WHAT IT IS NOT ───────────────────────
///
/// `08-design/ETHICAL-DESIGN.md` opens with *"Never manufacture guilt — no
/// streaks, no 'you broke a 47-day run', no red badges counting missed days"*,
/// and names the year grid as the most likely place for streaks to sneak in.
/// A stopwatch on somebody's journal is the **second** most likely place, so
/// the boundary is worth stating before the code rather than after a
/// screenshot.
///
/// This measures **one entry, once**. It is reported at the moment that entry
/// is saved and then forgotten:
///
///   * nothing is stored, on disk or in the database. There is no history to
///     compare against, so there is nothing to fall behind.
///   * there is no total, no average, no "this week", no personal best.
///   * it never appears for a short entry — see [worthMentioning] — because
///     telling somebody they wrote for eleven seconds is a judgement wearing
///     the clothes of a fact.
///   * it is an observation about effort already spent. It cannot be a target,
///     because it is only ever shown *afterwards*.
///
/// If a future session is asked to add "you wrote for 4 hours this month",
/// that is a different feature, it is the thing this file was written to
/// refuse, and ETHICAL-DESIGN.md is the argument.
///
/// ── WHY IT IS NOT SIMPLY end − start ─────────────────────────────────────
///
/// Because that measures the app being open, not a person writing. Somebody
/// starts a sentence, puts the phone down, cooks dinner, comes back and
/// finishes it: wall-clock says two hours, and two hours is a lie that would
/// be shown to them in a sentence meant to be encouraging.
///
/// So time accrues only across gaps shorter than [_pause]. A gap longer than
/// that is somebody who stopped, and it contributes nothing — the next
/// keystroke simply starts the clock again. This under-counts a little, since
/// a long thoughtful pause mid-sentence is real writing time, and under-counting
/// is the right direction to be wrong in.
class WritingSession {
  WritingSession({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Longer than this between keystrokes and the person had stopped.
  ///
  /// Two minutes rather than a few seconds: staring at a page is writing, and
  /// this is meant to be generous about thinking and strict about absence.
  static const Duration _pause = Duration(minutes: 2);

  /// Below this, nothing is said at all.
  static const Duration worthMentioning = Duration(minutes: 1);

  Duration _accumulated = Duration.zero;
  DateTime? _lastKeystroke;

  /// Call on every keystroke in the composer.
  void typed() {
    final now = _clock();
    final last = _lastKeystroke;
    _lastKeystroke = now;
    if (last == null) return;
    final gap = now.difference(last);
    if (gap <= Duration.zero || gap > _pause) return;
    _accumulated += gap;
  }

  /// What has accrued so far.
  Duration get spent => _accumulated;

  /// The total for the entry just saved, and a clean slate for the next one.
  ///
  /// Returns null when it is not worth saying, so the caller has one thing to
  /// check rather than two.
  Duration? finish() {
    final total = _accumulated;
    reset();
    return total >= worthMentioning ? total : null;
  }

  void reset() {
    _accumulated = Duration.zero;
    _lastKeystroke = null;
  }
}
