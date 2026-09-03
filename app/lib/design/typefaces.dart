import 'package:flutter/material.dart';

/// The faces a person can set their own writing in.
///
/// WHY THERE ARE TWELVE OF THESE WHEN THE DESIGN SYSTEM ASKED FOR ONE
///
/// `DESIGN-SYSTEM.md` chose the platform's own face and a generic serif, and
/// the reasoning was good: nothing bundled, nothing to licence, and the app
/// looks like part of the phone. That reasoning still holds for the
/// **interface** and the interface has not changed.
///
/// It does not hold for the part of the screen that is the user's own writing.
/// A journal is a private object and people have taste about the object. Some
/// want it to look like a legal pad, some want it to look like a letter, some
/// want it to look like a child's exercise book, and none of them are wrong.
/// One face for everybody is the right call for a bank and the wrong call here.
///
/// WHERE THE CHOSEN FACE IS AND IS NOT USED
///
/// **The writing and the headings.** Entries, the composer, the big date at
/// the top of the day, the title of every screen. That is where personality
/// belongs and where the reader's eye rests longest.
///
/// **Never the controls.** Buttons, switch rows, timestamps and error messages
/// stay in the platform's own face at every setting. Setting a delete
/// confirmation in a blackletter is not expression, it is a legibility bug —
/// and a control the reader cannot parse in a hurry is a control that will be
/// mis-tapped. `ACCESSIBILITY.md` outranks taste and this is the line.
///
/// LICENSING, BECAUSE BUNDLING A FONT IS TAKING SOMEBODY'S WORK
///
/// Every face here is under the SIL Open Font License 1.1, which permits
/// bundling in an application without a fee and without attribution in the
/// interface — but requires the licence text to travel with the software. It
/// does: `assets/licenses/`, and Settings → About → Fonts and licences shows
/// all twelve in full. No face is included that we do not have the right to
/// include, and there is no web request at any point — the files are in the
/// APK. That last part matters more here than anywhere: a font loaded from a
/// CDN is a network call, and this app has no network.
enum WritingFace {
  /// The phone's own face. Roboto on Android, SF on iOS.
  system(
    id: 'system',
    label: 'System',
    note: 'Whatever the rest of your phone uses.',
    family: null,
  ),

  /// A serif, from the platform. Kept because it was the old default and
  /// somebody's vault has been set in it for months.
  serif(
    id: 'serif',
    label: 'System Serif',
    note: 'Your phone’s own serif.',
    family: 'serif',
    fallback: <String>['Noto Serif', 'Georgia', 'Times New Roman'],
  ),

  calm(
    id: 'calm',
    label: 'Nunito Sans',
    note: 'Soft edges, wide letters.',
    family: 'NunitoSans',
  ),

  modern(
    id: 'modern',
    label: 'Manrope',
    note: 'Tight and current.',
    family: 'Manrope',
  ),

  oldStyle(
    id: 'old-style',
    label: 'EB Garamond',
    note: 'A book face from the 1500s.',
    family: 'EBGaramond',
    sizeAdjust: 1.06,
  ),

  playful(
    id: 'playful',
    label: 'Fredoka',
    note: 'Round and cheerful.',
    family: 'Fredoka',
  ),

  childlike(
    id: 'childlike',
    label: 'Comic Neue',
    note: 'An exercise book.',
    family: 'ComicNeue',
    /// Comic Neue ships 400 and 700 and nothing between.
    boldWeight: FontWeight.w700,
  ),

  handwritten(
    id: 'handwritten',
    label: 'Caveat',
    note: 'Handwriting, still readable at length.',
    family: 'Caveat',
    /// Caveat's x-height is tiny. Without this it is genuinely hard to read
    /// at 17px, which is the size everything else in the app is set at.
    sizeAdjust: 1.28,
    heightAdjust: 0.94,
  ),

  medieval(
    id: 'medieval',
    label: 'MedievalSharp',
    note: 'A scribe’s hand. One weight only.',
    family: 'MedievalSharp',
    sizeAdjust: 1.08,
    /// There is no bold cut. Asking for one makes the renderer smear the
    /// regular, which looks like a rendering fault rather than emphasis.
    boldWeight: FontWeight.w400,
  ),

  mono(
    id: 'mono',
    label: 'JetBrains Mono',
    note: 'Every letter the same width.',
    family: 'JetBrainsMono',
    /// A mono at the same nominal size sets wider and reads larger.
    sizeAdjust: 0.94,
  );

  const WritingFace({
    required this.id,
    required this.label,
    required this.note,
    required this.family,
    this.fallback = const <String>[],
    this.sizeAdjust = 1.0,
    this.heightAdjust = 1.0,
    this.boldWeight = FontWeight.w600,
  });

  /// Stored in preferences. **Permanent.** Renaming one silently resets
  /// somebody's choice on update, which is a small betrayal for no gain.
  final String id;

  /// The typeface's actual name.
  ///
  /// **These used to be personality labels** — Business, Calm, Playful,
  /// Sophisticated, Geometric. The idea was that most people do not know what
  /// Manrope is and everybody knows what "Modern" means. It was wrong twice:
  /// the words are subjective to the point of meaningless (what is the
  /// difference between Calm and Sophisticated?), and they read as *categories
  /// of person*, which is nobody's idea of a font menu. The list is now what
  /// every font menu on earth is — the names — with the specimen doing the
  /// explaining, because the specimen is what you are actually choosing.
  final String label;

  final String note;

  /// The family as declared in `pubspec.yaml`. `null` means the platform's.
  final String? family;

  final List<String> fallback;

  /// Multiplies the nominal size so every face reads at the same *apparent*
  /// size. Type designers do not agree on how much of the em to spend on the
  /// x-height, so 17px of Caveat and 17px of IBM Plex are not the same
  /// physical size at all — and a setting that changes how big the text is
  /// when the user only asked to change its shape is a bug.
  final double sizeAdjust;

  /// Multiplies line height, for faces whose ascenders or descenders need it.
  final double heightAdjust;

  /// What "bold" means for this family. Most ship a 600; a few do not.
  final FontWeight boldWeight;

  /// Faces that used to exist, and the nearest one that still does.
  ///
  /// ══ WHY A RETIRED FACE IS NOT JUST DROPPED ═══════════════════════════════
  ///
  /// > *"there are alots of fonts option given by us! reduce them! keep the
  /// > ones which are better and would loved — actually keep all categories
  /// > still reduce some fonts."* — 29 August 2026
  ///
  /// Fourteen faces were 4.3 MB of the APK, and four of them were a second
  /// version of a neighbour: two Garamonds, two rounded warm faces, and two
  /// more neutral sans on top of the two kept. Every *category* survives —
  /// system, neutral, book serif, rounded, exercise book, handwriting,
  /// medieval, mono — which is the part he was explicit about.
  ///
  /// The trap is what happens to somebody who had already chosen one. [id] is
  /// stored in preferences and the lookup below used to fall through to
  /// `system` for anything it did not recognise, so retiring Baloo 2 would have
  /// silently moved that person to their phone's default font on update — a
  /// change to how their whole journal looks, that they did not ask for and
  /// would have no way to explain.
  ///
  /// So each retired face names its nearest survivor: the closest thing in the
  /// same category, chosen by what the person was evidently reaching for.
  /// Cormorant and EB Garamond are both Garamonds; Baloo and Fredoka are both
  /// round and warm; Poppins and Nunito Sans are both soft geometric sans; IBM
  /// Plex and Manrope are both plain neutrals. Nobody wakes up to Roboto.
  ///
  /// **These entries are permanent**, exactly as [id] is. They cost four map
  /// lines and they are the difference between a tidy-up and a small betrayal.
  static const Map<String, String> _retired = <String, String>{
    'business': 'modern', // IBM Plex Sans   → Manrope
    'geometric': 'calm', // Poppins         → Nunito Sans
    'sophisticated': 'old-style', // Cormorant Garamond → EB Garamond
    'cute': 'playful', // Baloo 2         → Fredoka
  };

  static WritingFace fromId(String? id) {
    final wanted = _retired[id] ?? id;
    for (final f in values) {
      if (f.id == wanted) return f;
    }
    return WritingFace.system;
  }

  /// Applies this face to [base], keeping everything else about the style.
  TextStyle apply(TextStyle base) {
    final size = (base.fontSize ?? 17) * sizeAdjust;
    // The base style states line height as a multiplier already; scale it
    // rather than replacing it, so a heading's tighter leading stays tighter.
    final height = base.height == null ? null : base.height! * heightAdjust;
    if (family == null) {
      // The system face already resolves every script the phone can draw.
      return base.copyWith(fontSize: size, height: height);
    }
    return base.copyWith(
      fontFamily: family,
      // The face's own fallbacks first, then every script none of the bundled
      // faces can draw. See [kScriptFallback].
      fontFamilyFallback: [...fallback, ...kScriptFallback],
      fontSize: size,
      height: height,
    );
  }
}

/// The scripts none of the bundled faces can draw, named explicitly.
///
/// ══ WHY THIS IS NOT LEFT TO THE ENGINE ════════════════════════════════════
///
/// Every one of the fourteen faces in this file is a Latin face. IBM Plex Sans
/// reaches Cyrillic and Greek; Baloo 2 and Fredoka happen to carry Devanagari.
/// **Not one of them has a single CJK or Arabic glyph.**
///
/// So somebody who sets the writing face to Manrope and then writes a sentence
/// in Chinese, Japanese, Korean or Arabic is asking for characters the chosen
/// font does not contain. Flutter's engine *does* fall through to the platform's
/// own fonts for a missing glyph, and on Android that usually finds Noto and
/// draws the text correctly — which is why this has never been reported.
///
/// **"Usually" is the problem.** That fallback is engine behaviour rather than
/// anything this app asked for: it is not specified, it differs between Skia and
/// Impeller, and the failure mode when it does not happen is **tofu** — a row of
/// empty rectangles where somebody's diary entry was. For an app whose whole
/// promise is that it holds a life, a sentence that renders as boxes is not a
/// cosmetic defect.
///
/// Naming the families makes it a request rather than a hope. These are the
/// families Android ships as part of AOSP, so they are present on every device
/// this app targets; on a device that lacks one, the list simply moves on and
/// the engine's own fallback still applies underneath. **It can only help.**
///
/// ── WHY THE CJK ORDER IS WHAT IT IS ──────────────────────────────────────
///
/// Han characters are shared between Chinese, Japanese and Korean, and the same
/// codepoint is drawn differently in each — 直, 骨 and 令 are the usual
/// examples. A font chosen for one language renders the others in a way a native
/// reader finds wrong rather than unreadable.
///
/// There is no ordering that is correct for everybody, because the codepoint
/// does not say which language it is. Simplified Chinese is first because it has
/// by far the most speakers, and **the honest fix is not reordering this list**:
/// it is that `MaterialApp`'s locale drives font selection, which it does once
/// the app is localised. Somebody reading Japanese with the app set to Japanese
/// gets the Japanese forms from the system's own locale-aware fallback before
/// this list is ever consulted.
const List<String> kScriptFallback = <String>[
  // Chinese, Japanese, Korean. See the note above about the order.
  'Noto Sans CJK SC',
  'Noto Sans CJK TC',
  'Noto Sans CJK JP',
  'Noto Sans CJK KR',
  // Arabic — and this one also carries the right-to-left shaping.
  'Noto Sans Arabic',
  'Noto Naskh Arabic',
  // Devanagari, for Hindi. Two of the bundled faces have it; the other twelve
  // do not, and Hindi is the second language this app was ever written for.
  'Noto Sans Devanagari',
  // The catch-all Android resolves for anything still unmatched.
  'Noto Sans',
];

/// The fallback list, reordered so the reader's own language comes first.
///
/// ══ THE FIX THE NOTE ABOVE SAID WAS THE HONEST ONE ═══════════════════════════
///
/// [kScriptFallback] has to pick an order for the CJK families, and the comment
/// on it explains why any fixed order is wrong for somebody: Han characters are
/// shared between Chinese, Japanese and Korean, the same codepoint is drawn
/// differently in each, and **the codepoint does not say which language it is**.
/// 直, 骨 and 令 are the usual examples. A Japanese reader given the Simplified
/// Chinese forms does not see tofu — they see their own language set in a way
/// that is subtly, persistently wrong.
///
/// That note ended by saying the real answer is for the app's locale to drive
/// font selection. It is localised now, so this is that.
///
/// > *"as the language is changed! i want you to use the best font for them
/// > too! the change should be subtle! unnoticed! par it improves the overall
/// > feel to 200%"* — 28 August 2026
///
/// Subtle and unnoticed is exactly right, and is the whole design brief: done
/// well nobody can say what changed, and done badly a native reader can tell
/// instantly and cannot explain why the app feels foreign.
///
/// **This only reorders.** Every family stays in the list, so a Japanese entry
/// written while the app is in English still renders — it just renders with the
/// Chinese forms preferred, which is the same as before. Nothing can become
/// unrenderable by choosing a language.
List<String> scriptFallbackFor(Locale? locale) {
  final code = locale?.languageCode;
  if (code == null) return kScriptFallback;

  // The family this reader's script wants at the front. Only the languages
  // where the choice is actually visible are listed: for a Latin-script locale
  // the order of the CJK families changes nothing anybody can see, so it is
  // left alone rather than shuffled for the sake of it.
  final preferred = switch (code) {
    'ja' => 'Noto Sans CJK JP',
    'ko' => 'Noto Sans CJK KR',
    'zh' => locale?.countryCode == 'TW' || locale?.countryCode == 'HK'
        ? 'Noto Sans CJK TC'
        : 'Noto Sans CJK SC',
    'ar' => 'Noto Sans Arabic',
    'hi' => 'Noto Sans Devanagari',
    _ => null,
  };
  if (preferred == null) return kScriptFallback;

  return <String>[
    preferred,
    for (final f in kScriptFallback)
      if (f != preferred) f,
  ];
}

/// Extra line height for scripts that need more room than Latin.
///
/// ══ WHY A NUMBER AND NOT A FONT ══════════════════════════════════════════════
///
/// Latin type sits almost entirely between the baseline and the cap height.
/// Devanagari hangs matras above the shirorekha and below the baseline; Arabic
/// stacks dots and marks well above and below; CJK fills the full em square with
/// no descender room to borrow.
///
/// Set at Latin's leading, all three crowd: in Hindi the matras of one line
/// touch the shirorekha of the next, which a Devanagari reader registers as the
/// text being cramped long before they would call it broken. This is the other
/// half of "subtle, unnoticed" — the reason a well-set page in your own script
/// feels calm and a badly-set one feels tiring without ever looking wrong.
///
/// Small numbers on purpose. `DESIGN-SYSTEM.md` sets the rhythm and this bends
/// it rather than replacing it; anything larger would be visible as a layout
/// change when somebody switches language, which is exactly what he asked for
/// this **not** to be.
double lineHeightScaleFor(Locale? locale) => switch (locale?.languageCode) {
      'hi' => 1.12,
      'ar' => 1.10,
      'ja' || 'ko' || 'zh' => 1.06,
      _ => 1.0,
    };

/// The one place the licence texts are named, so the About screen and the
/// asset folder cannot drift apart.
const Map<String, String> kFontLicences = <String, String>{
  'Nunito Sans': 'assets/licenses/nunitosans-OFL.txt',
  'Manrope': 'assets/licenses/manrope-OFL.txt',
  'EB Garamond': 'assets/licenses/ebgaramond-OFL.txt',
  'Fredoka': 'assets/licenses/fredoka-OFL.txt',
  'Comic Neue': 'assets/licenses/comicneue-OFL.txt',
  'Caveat': 'assets/licenses/caveat-OFL.txt',
  'MedievalSharp': 'assets/licenses/medievalsharp-OFL.txt',
  'JetBrains Mono': 'assets/licenses/jetbrainsmono-OFL.txt',
};
