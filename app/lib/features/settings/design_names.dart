import '../../core/settings/photo_quality.dart';
import '../../core/settings/video_quality.dart';
import '../../design/accents.dart';
import '../../design/typefaces.dart';
import '../../l10n/generated/app_localizations.dart';

/// The words for the things a person chooses in Appearance, in their language.
///
/// ══ WHY THESE ARE NOT ON THE ENUMS THEMSELVES ═══════════════════════════════
///
/// `LampAccent`, `PageSurface`, `PageRuling` and `WritingFace` live in
/// `design/`, and `PhotoQuality`/`VideoQuality` live in `core/settings/`. Both
/// are below the widget layer on purpose — `app_settings.dart` says so in as
/// many words, because settings are read by tests and by isolates that have no
/// tree — and `L.of(context)` needs a `BuildContext`.
///
/// So the enums keep their `id`, which is what is written to disk and must never
/// change, and lose nothing. The *words* move here, into the feature that shows
/// them, as extensions. Every consumer of `.label` and `.note` was already in
/// `features/`, so nothing had to be plumbed anywhere new.
///
/// ══ WHAT IS DELIBERATELY NOT TRANSLATED ═════════════════════════════════════
///
/// **Twelve of the fourteen typeface names.** *Manrope*, *Fredoka*, *Baloo 2*,
/// *EB Garamond*, *JetBrains Mono* and the rest are the names their designers
/// gave them — proper nouns, exactly like `appName` under ADR-010. A person who
/// has heard of Poppins has heard of *Poppins*; translating it would invent a
/// typeface that does not exist and make the licence list unmatchable.
///
/// The two exceptions are *System* and *System Serif*, which are not names at
/// all — they are descriptions of "whatever your phone uses", and those
/// translate.
///
/// The **notes** under all fourteen do translate. *"Round and cheerful"* is a
/// description of a shape, and it is the sentence somebody actually chooses on.
extension LampAccentNames on LampAccent {
  String labelIn(L l) => switch (this) {
        LampAccent.amber => l.accentAmber,
        LampAccent.rose => l.accentRose,
        LampAccent.sage => l.accentSage,
        LampAccent.slate => l.accentSlate,
        LampAccent.plum => l.accentPlum,
        LampAccent.ember => l.accentEmber,
      };

  String noteIn(L l) => switch (this) {
        LampAccent.amber => l.accentAmberNote,
        LampAccent.rose => l.accentRoseNote,
        LampAccent.sage => l.accentSageNote,
        LampAccent.slate => l.accentSlateNote,
        LampAccent.plum => l.accentPlumNote,
        LampAccent.ember => l.accentEmberNote,
      };
}

extension PageSurfaceNames on PageSurface {
  String labelIn(L l) => switch (this) {
        PageSurface.plain => l.surfacePlain,
        PageSurface.paper => l.surfacePaper,
        PageSurface.lamplit => l.surfaceLamplit,
        PageSurface.starMap => l.surfaceStarMap,
      };

  String noteIn(L l) => switch (this) {
        PageSurface.plain => l.surfacePlainNote,
        PageSurface.paper => l.surfacePaperNote,
        PageSurface.lamplit => l.surfaceLamplitNote,
        PageSurface.starMap => l.surfaceStarMapNote,
      };
}

extension PageRulingNames on PageRuling {
  String labelIn(L l) => switch (this) {
        PageRuling.none => l.rulingNone,
        PageRuling.lines => l.rulingLines,
        PageRuling.isometric => l.rulingIsometric,
        PageRuling.triangle => l.rulingTriangle,
        PageRuling.dots => l.rulingDots,
      };

  String noteIn(L l) => switch (this) {
        PageRuling.none => l.rulingNoneNote,
        PageRuling.lines => l.rulingLinesNote,
        PageRuling.isometric => l.rulingIsometricNote,
        PageRuling.triangle => l.rulingTriangleNote,
        PageRuling.dots => l.rulingDotsNote,
      };
}

extension WritingFaceNames on WritingFace {
  /// The name of the face.
  ///
  /// Falls through to [WritingFace.label] for the eight real typefaces, which
  /// is not a gap — see the note at the top of this file. Only the two that
  /// describe the platform rather than naming a face are translated.
  String labelIn(L l) => switch (this) {
        WritingFace.system => l.faceSystem,
        WritingFace.serif => l.faceSerif,
        _ => label,
      };

  String noteIn(L l) => switch (this) {
        WritingFace.system => l.faceSystemNote,
        WritingFace.serif => l.faceSerifNote,
        WritingFace.calm => l.faceCalmNote,
        WritingFace.modern => l.faceModernNote,
        WritingFace.oldStyle => l.faceOldStyleNote,
        WritingFace.playful => l.facePlayfulNote,
        WritingFace.childlike => l.faceChildlikeNote,
        WritingFace.handwritten => l.faceHandwrittenNote,
        WritingFace.medieval => l.faceMedievalNote,
        WritingFace.mono => l.faceMonoNote,
      };
}

extension PhotoQualityNames on PhotoQuality {
  String labelIn(L l) => switch (this) {
        PhotoQuality.original => l.qualityOriginal,
        PhotoQuality.balanced => l.qualityBalanced,
        PhotoQuality.smaller => l.qualitySmaller,
      };

  /// The three labels are shared with video; the notes are not.
  ///
  /// A photograph's "keep the original" carries a consequence a video's does
  /// not — it keeps the place the picture was taken, which Lamplight otherwise
  /// strips. That sentence has to be under the photograph row and nowhere else.
  String noteIn(L l) => switch (this) {
        PhotoQuality.original => l.photoOriginalNote,
        PhotoQuality.balanced => l.photoBalancedNote,
        PhotoQuality.smaller => l.photoSmallerNote,
      };
}

extension VideoQualityNames on VideoQuality {
  String labelIn(L l) => switch (this) {
        VideoQuality.original => l.qualityOriginal,
        VideoQuality.balanced => l.qualityBalanced,
        VideoQuality.smaller => l.qualitySmaller,
      };

  String noteIn(L l) => switch (this) {
        VideoQuality.original => l.videoOriginalNote,
        VideoQuality.balanced => l.videoBalancedNote,
        VideoQuality.smaller => l.videoSmallerNote,
      };
}
