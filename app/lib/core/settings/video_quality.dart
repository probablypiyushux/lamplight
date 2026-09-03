/// How much a video is made smaller on the way in — **and whether it is at
/// all.** ROUND EIGHT, ISSUE 2A.
///
/// ══ WHAT HE ASKED, AND WHY IT IS THREE QUESTIONS ═══════════════════════════
///
/// *"Give the user an option on how the video is compressed? How much it is
/// compressed? Do the user wants it compressed? If he wants then how?"*
///
/// Four question marks in two lines, and they are not the same question asked
/// four ways. They are three, in order of how much they matter:
///
///   1. **Does the user want it compressed at all?** Until now the answer was
///      "yes, always, and nobody was asked". A phone video is re-encoded the
///      moment it is imported and the original is scrubbed — irreversibly,
///      because the original no longer exists to go back to. That is a
///      decision about somebody's own recording of their own life, taken on
///      their behalf, once, permanently. `ETHICAL-DESIGN.md` is about not
///      doing that.
///   2. **How much?** A number he can see rather than a policy he has to trust.
///   3. **How?** Which is the part he does not actually need to know, and
///      ISSUE 10 says so in as many words. So it is three named choices with
///      what each one costs, not a bitrate slider.
///
/// ══ WHY THE DEFAULT DOES NOT CHANGE ═══════════════════════════════════════
///
/// [balanced] is what every existing vault has been doing and it stays the
/// default. Changing the default would silently alter what happens to the next
/// video imported by somebody who never opens this setting, which is the same
/// fault as never having offered the choice — just in the other direction.
///
/// The setting is a **choice made visible**, not a new behaviour.
enum VideoQuality {
  /// Store exactly what the camera produced.
  ///
  /// The honest option, and the expensive one. His own number: *"one minute
  /// video can be of 100 mbs or more"* — that was round five's complaint and it
  /// is still true, which is why this is not the default. But a person keeping
  /// a record of their life is allowed to decide that the recording matters
  /// more than the space, and before this they could not.
  ///
  /// Note what it costs beyond size: nothing is re-encoded, so a clip in a
  /// container Android can produce but not always play is kept as it arrived.
  /// The trade is stated on the row rather than discovered later.
  original(
    id: 'original',
    label: 'Keep the original',
    note: 'Kept exactly as your camera recorded it. The largest files by '
        'a long way.',
  ),

  /// What Lamplight has always done.
  ///
  /// H.264 at the bitrate streaming services use for the same resolution —
  /// chosen to be visually transparent on real footage rather than
  /// mathematically lossless. A phone recording at 1080p lands between twelve
  /// and twenty megabits; this asks for eight.
  balanced(
    id: 'balanced',
    label: 'Balanced',
    note: 'Much smaller, and hard to tell apart from the original. '
        'The default.',
  ),

  /// For somebody who would rather keep more of them.
  ///
  /// Half the bitrate again, and long edges above 1080p are brought down to
  /// it — which is where most of the saving on a 4K clip actually is. Visible
  /// on a large screen, and the row says so.
  smaller(
    id: 'smaller',
    label: 'Smaller',
    note: 'Half the size again. You may notice it on a big screen.',
  );

  const VideoQuality({
    required this.id,
    required this.label,
    required this.note,
  });

  final String id;
  final String label;
  final String note;

  /// Whether a clip is left exactly as it arrived.
  bool get keepsOriginal => this == VideoQuality.original;

  static VideoQuality fromId(String? id) {
    for (final q in values) {
      if (q.id == id) return q;
    }
    // Everybody upgrading, and everybody who has never opened the setting,
    // keeps doing exactly what they were doing.
    return VideoQuality.balanced;
  }
}
