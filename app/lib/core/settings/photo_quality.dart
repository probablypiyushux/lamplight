/// How much a photograph is made smaller on the way in — **and whether it is
/// at all.** ROUND NINE, ISSUE 6.
///
/// ══ WHAT HE ASKED, AND WHY IT REVERSES A DECISION ══════════════════════════
///
/// > *"Photos and videos sizes — ask when uploading! The setting just has video
/// > size."*
///
/// Two halves, and this is the first. Round five decided *"store compressed
/// only, no setting"* for both pictures and video; round eight reversed it for
/// video after he asked; this reverses it for pictures after he asked again,
/// having noticed that only half the job was done.
///
/// The thing being reversed is worth naming plainly, because it is the same
/// thing every time and it is the reason `ETHICAL-DESIGN.md` exists: a
/// photograph is re-encoded the moment it is imported and the original is
/// scrubbed, **irreversibly**, because the original no longer exists to go back
/// to. That is a permanent decision about somebody's own picture of their own
/// life, taken on their behalf, without asking.
///
/// ══ WHY THE DEFAULT DOES NOT CHANGE ════════════════════════════════════════
///
/// [balanced] is exactly what every existing vault has been doing — 3000 pixels
/// on the long edge at JPEG quality 88 — and it stays the default. Changing the
/// default would silently alter what happens to the next photograph imported by
/// somebody who never opens this setting, which is the same fault as never
/// having offered the choice, in the other direction.
///
/// ══ AND WHY THE IDS MATCH `VideoQuality`'S ═════════════════════════════════
///
/// Deliberately, and it is load-bearing rather than tidy. The sheet at import
/// time asks **one** question — *keep the original, balanced, or smaller* — and
/// applies the answer to whatever is in the batch, because a person choosing
/// how to handle the fourteen things they have just picked is not thinking
/// about which of them are photographs. One id, both enums,
/// `PhotoQuality.fromId` and `VideoQuality.fromId`.
enum PhotoQuality {
  /// Store exactly what the camera produced.
  ///
  /// The honest option and the expensive one. A modern phone photograph is
  /// eight to fifteen megabytes; the balanced one lands nearer one and a half.
  ///
  /// **It costs more than space, and the row says so.** Nothing is re-encoded,
  /// so the file keeps its metadata — including, on most phone photographs,
  /// **the GPS coordinates of where it was taken**. Everywhere else in this app
  /// that is stripped as a side effect of re-encoding and
  /// `02-security/THREAT-MODEL.md` counts it as a feature. Somebody who asks
  /// for the original is asking for all of it, and should be told what all of
  /// it includes rather than discovering it in an export years later.
  original(
    id: 'original',
    label: 'Keep the original',
    note: 'Kept exactly as your camera made it. The largest files — and they '
        'keep the place the photo was taken, which Lamplight otherwise '
        'removes.',
  ),

  /// What Lamplight has always done. 3000px on the long edge, quality 88.
  ///
  /// Larger than any phone screen and enough to crop into, at a quality above
  /// the point where artefacts show on photographic content.
  balanced(
    id: 'balanced',
    label: 'Balanced',
    note: 'Much smaller, and hard to tell apart from the original. '
        'The default.',
  ),

  /// 2000px on the long edge, quality 78.
  ///
  /// Still comfortably larger than a phone screen. Visible if you crop hard
  /// into it or open it on a desktop monitor, and the row says so.
  smaller(
    id: 'smaller',
    label: 'Smaller',
    note: 'Half the size again. You may notice it if you crop right in.',
  );

  const PhotoQuality({
    required this.id,
    required this.label,
    required this.note,
  });

  final String id;
  final String label;
  final String note;

  /// Whether a picture is left exactly as it arrived.
  ///
  /// Checked in Dart rather than in Kotlin, for the same reason `VideoQuality`
  /// is: "keep the original" should cost no channel call, no decoder, and no
  /// chance of a re-encoding bug touching a file the user asked us not to
  /// touch.
  bool get keepsOriginal => this == PhotoQuality.original;

  static PhotoQuality fromId(String? id) {
    for (final q in values) {
      if (q.id == id) return q;
    }
    // Everybody upgrading, and everybody who never opens the setting, keeps
    // doing exactly what they were doing.
    return PhotoQuality.balanced;
  }
}
