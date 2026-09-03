import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
// `Locale` only. This file is otherwise free of the widget layer and stays
// that way — settings are read by tests and by isolates that have no tree.
import 'dart:ui' show Locale;
import 'package:flutter/material.dart' show ThemeMode;

import '../../design/accents.dart';
import 'photo_quality.dart';
import 'video_quality.dart';
import '../../design/typefaces.dart';

/// Display preferences, stored unencrypted, and the reasoning for that.
///
/// WHY THIS FILE IS NOT IN THE VAULT
///
/// Everything here has to be readable **before** the vault is unlocked. The
/// lock screen is a screen: it has to be painted in the right theme, at the
/// right text size, at a moment when there is no key in memory and by
/// definition cannot be one. A theme preference locked inside the vault would
/// mean the first screen of the app always guesses.
///
/// That is only acceptable because of what is *not* in here. `CLAUDE.md` rule 2
/// says no plaintext **user content** on disk, ever. A theme choice is not
/// content — it says nothing about what you wrote, when, how much of it there
/// is, or who it concerns. Someone with filesystem access already knows the app
/// is installed; `keyring.json` and `vault.db` are sitting next to this file.
/// Learning that you prefer light mode adds nothing to what they have.
///
/// **The line, stated so a future session does not have to guess where it is:**
/// this file may hold preferences about how the app looks and behaves. It may
/// never hold anything about what is in the vault — no counts, no entry dates,
/// no folder names, no last-opened day, no search history. If a value would let
/// a stranger infer something about the notes, it belongs in the encrypted
/// database instead.
///
/// `lastBackupAt` sits right on that line and is here deliberately. It concerns
/// a file the user has already exported to somewhere outside the vault, it
/// drives the 30-day reminder in `UX-FLOWS.md` flow 5 — which has to work at
/// times the vault is not open — and it reveals only that a backup happened,
/// not its size, its location, or one thing inside it.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._file, this._data);

  final File _file;
  Map<String, Object?> _data;

  /// Reads the settings file, or starts from the defaults if there is not one.
  ///
  /// A damaged or half-written file is treated as absent rather than as fatal.
  /// The worst case is that the app opens in its default theme. An app that
  /// refuses to start because it cannot parse a colour preference would be a
  /// far worse bug than the one that guard is protecting against.
  static Future<AppSettings> load(File file) async {
    Map<String, Object?> data = {};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) data = decoded;
      }
    } catch (_) {
      data = {};
    }
    return AppSettings._(file, data);
  }

  /// In-memory, for tests. Nothing is ever written to disk.
  factory AppSettings.inMemory([Map<String, Object?>? seed]) => AppSettings._(
        File('${Directory.systemTemp.path}/lamplight-settings-test.json'),
        seed ?? {},
      );

  // ── Appearance ─────────────────────────────────────────────────────────────

  /// Dark · Light · Follow system. `DESIGN-SYSTEM.md` specifies all three and
  /// names dark as the default.
  /// Which language the **interface** speaks. Null means follow the phone.
  ///
  /// ══ WHAT THIS DOES NOT DO, AND IT IS THE THING PEOPLE ASSUME ═════════════
  ///
  /// It does not decide what anybody can **write**. Lamplight has always
  /// accepted any script the keyboard can produce, and since 28 August it can
  /// *search* them too — the query splitter was ASCII-only until then, so a
  /// Hindi search returned nothing at all and looked like an empty vault rather
  /// than a broken search.
  ///
  /// So this setting changes the app's own words and nothing about the user's.
  /// `settingsLanguageNote` says exactly that under the row, because it is the
  /// question somebody actually has before they touch it.
  ///
  /// **Stored as a language tag, not an index.** An index would silently mean a
  /// different language the day a locale is added to the list in the middle.
  Locale? get locale {
    final tag = _data['locale'];
    if (tag is! String || tag.isEmpty) return null;
    final parts = tag.split('-');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  set locale(Locale? value) => _write(
        'locale',
        value == null
            ? ''
            : value.countryCode == null || value.countryCode!.isEmpty
                ? value.languageCode
                : '${value.languageCode}-${value.countryCode}',
      );

  ThemeMode get themeMode => switch (_data['themeMode']) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  set themeMode(ThemeMode value) => _write(
      'themeMode',
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      });

  /// The face the user's own writing is set in.
  ///
  /// Replaces the old `serifBody` switch, which was one bit where there should
  /// have been a choice. **A vault that had the serif switched on lands on
  /// [WritingFace.serif]** rather than being reset to the platform default —
  /// the migration is the `?? (serifBody ? …)` below, and it is there because
  /// silently changing how somebody's three months of writing looks is not an
  /// acceptable thing for an update to do.
  WritingFace get writingFace {
    final stored = _data['writingFace'];
    if (stored is String) return WritingFace.fromId(stored);
    // No explicit choice yet: honour the old boolean.
    final legacySerif = _data['serifBody'] as bool? ?? true;
    return legacySerif ? WritingFace.serif : WritingFace.system;
  }

  set writingFace(WritingFace value) => _write('writingFace', value.id);

  /// The accent. Six of them, all measured. See `design/accents.dart`.
  LampAccent get accent => LampAccent.fromId(_data['accent'] as String?);

  set accent(LampAccent value) => _write('accent', value.id);

  /// Plain · Paper · Lamplit. Paper is the default — the grain is what makes
  /// the canvas read as a surface rather than as an absence.
  PageSurface get pageSurface =>
      PageSurface.fromId(_data['pageSurface'] as String?);

  set pageSurface(PageSurface value) => _write('pageSurface', value.id);

  /// How much a video is made smaller on the way in, and whether it is at
  /// all. **ROUND EIGHT, ISSUE 2A.**
  ///
  /// *"Do the user wants it compressed? If he wants then how?"* Until this
  /// existed the answer was "yes, always, and nobody was asked" — and the
  /// original was scrubbed afterwards, so the decision could not be revisited
  /// even in principle. See `VideoQuality` for why the default is unchanged.
  VideoQuality get videoQuality =>
      VideoQuality.fromId(_data['videoQuality'] as String?);

  set videoQuality(VideoQuality value) => _write('videoQuality', value.id);

  /// The same question about a photograph. **ROUND NINE, ISSUE 6.**
  ///
  /// *"Photos and videos sizes — ask when uploading! The setting just has video
  /// size."* He is right that it was half a feature: a picture was re-encoded
  /// and its original scrubbed with no way to say otherwise, which is the exact
  /// thing the video setting exists to stop. See `PhotoQuality`.
  PhotoQuality get photoQuality =>
      PhotoQuality.fromId(_data['photoQuality'] as String?);

  set photoQuality(PhotoQuality value) => _write('photoQuality', value.id);

  /// Whether to ask, at the moment something is added, rather than just obeying
  /// the two settings above. **ROUND NINE, ISSUE 6.**
  ///
  /// ── WHY THIS DEFAULTS TO ON, AND WHY IT IS PER BATCH ────────────────────
  ///
  /// *"**Ask when uploading**"* is the request, in those words, so the default
  /// is to ask.
  ///
  /// But `ETHICAL-DESIGN.md` is right that a question asked on every single
  /// import becomes a nag, and a nag is answered without being read — at which
  /// point it is worse than no question, because it has the appearance of
  /// consent and none of the substance. Two things keep it honest: it is asked
  /// **once per batch** rather than once per file, and the sheet carries *"Do
  /// not ask again"*, which turns this off and means it.
  ///
  /// It is also not asked at all when the batch contains nothing that could be
  /// made smaller — a PDF and a text file are stored exactly as they arrived,
  /// and asking how to compress them would be a question with no answer.
  bool get askAboutMediaSize => _data['askAboutMediaSize'] as bool? ?? true;

  set askAboutMediaSize(bool value) => _write('askAboutMediaSize', value);

  // ── Writing down what was said. ISSUE 15 ─────────────────────────────────

  /// Whether the one sentence that teaches what a folder *is* has been shown.
  ///
  /// ── `PLAN.md` §9.1, AND WHY IT IS A PREFERENCE AND NOT A VAULT ROW ──────
  ///
  /// > *The one-time sentence that teaches the whole model: "Still on 4 March.
  /// > Also in Kavya." Shown once, never again.*
  ///
  /// The whole idea of folders in this app is that an entry is **linked, never
  /// moved** — it stays on its day and also appears in a folder. That is not
  /// what "add to a folder" means anywhere else on a phone, where it means
  /// *move*, so somebody's first use of it carries a reasonable fear that their
  /// note has left 4 March. One concrete sentence at the moment it happens
  /// settles that for ever; the same sentence on the fortieth use is furniture.
  ///
  /// It lives in the plaintext settings file with the theme, and that is a
  /// deliberate line rather than laziness: it records that a person has read a
  /// sentence, and says nothing whatever about what is in the vault. The long
  /// note at the top of this file is where that line is drawn.
  bool get folderLessonSeen => _data['folderLessonSeen'] as bool? ?? false;

  set folderLessonSeen(bool value) => _write('folderLessonSeen', value);

  /// Whether voice notes get a transcript. **On by default since 28 August
  /// 2026, at his explicit request, and the trade is written out here.**
  ///
  /// > *"Make the option turned on! phone's own model for voice transcription
  /// > from default!"*
  ///
  /// ══ WHAT THIS DEFAULT GIVES AWAY, STATED PLAINLY ═════════════════════════
  ///
  /// It used to be off, and the argument for that was not timidity:
  /// transcribing hands the **decrypted audio** to Android's recognition
  /// service. That service is on-device — guaranteed by which constructor
  /// `Transcribe.kt` uses rather than by hoping, and there is a test that reads
  /// the Kotlin and fails if a networked fallback is ever added — but it is
  /// still somebody's diary crossing out of this process into another one.
  /// `ETHICAL-DESIGN.md` is short with defaults that give away more than was
  /// asked for.
  ///
  /// **He asked for it on anyway, knowing that**, and the counter-argument is
  /// real: a voice note nobody can search is a voice note nobody finds again,
  /// so the feature that makes speaking as good as writing was switched off for
  /// everybody who never opened Settings. The audio never leaves the phone
  /// either way. This is the one default in the app that trades a little
  /// exposure for a lot of usefulness, and it is his to make.
  ///
  /// **It is one tap to turn off**, first row of Voice and transcripts, and the
  /// subtitle says what it does rather than that it is "recommended".
  ///
  /// The switch does not appear at all on a phone with no on-device recogniser
  /// — see `Transcription.available`. A permanently dead switch is a daily
  /// reminder of something the user cannot fix.
  bool get transcribeVoice => _data['transcribeVoice'] as bool? ?? true;

  set transcribeVoice(bool value) => _write('transcribeVoice', value);

  /// Whether to fall back to Android's own recogniser when there is no
  /// language model. **ROUND TEN — "make the whisper the base".**
  ///
  /// ══ WHY THIS DEFAULTS TO OFF ═══════════════════════════════════════════
  ///
  /// > *"Remove whatever standard you had! And make the whisper the base!"*
  /// > *"I want this to be purely based upon multilingual! English Hindi!"*
  ///
  /// Android's `SpeechRecognizer` takes **one** BCP-47 tag per session. There
  /// is no multilingual mode to ask it for, and running the same audio through
  /// two models and picking a winner produces confident nonsense from whichever
  /// one lost. A sentence like *"kal main office nahi gaya, I was completely
  /// wiped out"* comes back mangled every time.
  ///
  /// So it was the wrong thing to be doing silently. A fallback that half-works
  /// is worse than none: it makes the app look like it is transcribing while
  /// producing something nobody would keep, and the person is left thinking
  /// the feature is bad rather than that it is off.
  ///
  /// It is not deleted, because for somebody writing in one language it is
  /// genuinely useful and costs no download. It is a deliberate choice now,
  /// made after being told what it cannot do.
  /// Which language the recogniser is told to expect, as a BCP-47 tag.
  ///
  /// ── ON "MULTILINGUAL", AND WHAT THE PHONE ACTUALLY DOES ──────────────────
  ///
  /// > *"Supports multilingual languages … remember people 99% of the time will
  /// > speak multilingually — not just one language!"*
  ///
  /// He is right about people and the phone cannot do it. Android's on-device
  /// recogniser takes **one** BCP-47 tag per session; there is no multilingual
  /// mode to ask for, and running the same audio through two models and picking
  /// a winner would produce confident nonsense from whichever one lost.
  ///
  /// So: one language, chosen by him, defaulting to the phone's own, and the
  /// settings screen says so in a sentence instead of implying otherwise. That
  /// is the honest version of this feature and it is worth more than a version
  /// that claims to handle code-switching and does not.
  ///
  /// Empty means "the phone's own", resolved at the time rather than stored, so
  /// that changing the phone's language changes this too until he picks one.
  String get transcriptionLanguage =>
      (_data['transcriptionLanguage'] as String?) ?? _phoneLanguage;

  set transcriptionLanguage(String value) =>
      _write('transcriptionLanguage', value);

  /// Filled in once at startup by [rememberPhoneLanguage], so the getter above
  /// can stay synchronous — every settings getter in this file is, and a single
  /// asynchronous one would spread through every widget that reads it.
  static String _phoneLanguage = 'en-US';

  static void rememberPhoneLanguage(String tag) => _phoneLanguage = tag;

  /// What is printed on the page. **ISSUE 6.**
  ///
  /// Separate from [pageSurface] because they are separate questions: the
  /// surface is what the sheet is made of, the ruling is what was printed on it
  /// before anybody wrote. Ruled tracing paper and a plain notebook page are
  /// both real things, and folding the two into one list of six would have made
  /// most of the combinations unreachable.
  ///
  /// Defaults to [PageRuling.none] — see the enum for why "remove those lines"
  /// and "give the user choices" are both honoured by that.
  PageRuling get pageRuling => PageRuling.fromId(_data['pageRuling'] as String?);

  set pageRuling(PageRuling value) => _write('pageRuling', value.id);

  /// What to call the person using the app.
  ///
  /// **Local, optional, and not an account.** `UX-FLOWS.md` flow 1 screen 4
  /// specified a skippable profile and it was never built. It exists for one
  /// reason: an app that knows your name feels like it belongs to you, and this
  /// one is meant to. It is one string in a preferences file on one phone. It
  /// is not sent anywhere, because there is nowhere to send it.
  ///
  /// Empty means they skipped it, and every screen that uses it has to work
  /// without it. Nothing is ever gated on knowing the name.
  String get displayName => (_data['displayName'] as String?)?.trim() ?? '';

  set displayName(String value) => _write('displayName', value.trim());

  bool get hasName => displayName.isNotEmpty;

  /// A text-size nudge, on top of whatever the phone is already set to.
  ///
  /// **This multiplies the OS setting rather than replacing it.** Someone who
  /// has already turned their system text up to 130% because they need it does
  /// not want an app that resets them to 100% and offers its own slider — they
  /// want the app to respect that and then let them go further. So the value
  /// here is a factor applied to `MediaQuery`'s existing scaler, and 1.0 means
  /// "exactly what the phone says".
  ///
  /// `ACCESSIBILITY.md` requires every screen to survive 200% without clipping,
  /// and `test/widget/screens_test.dart` proves it does. That is what makes it
  /// safe to offer this at all: an app that breaks at large text should not be
  /// handing out a control that makes text large.
  ///
  /// ── WHY THIS IS A SLIDER NOW AND NOT FOUR NAMED STEPS ─────────────────
  ///
  /// It was Smaller / Normal / Larger / Largest. Four steps is enough when
  /// there is one typeface; with fourteen it is not, because **the same
  /// nominal size reads differently in every face**. Caveat at "Normal" is
  /// smaller than Poppins at "Smaller", and no amount of per-face metric
  /// correction fixes that entirely — it is a matter of taste, not geometry,
  /// and taste needs a dial rather than four presets.
  ///
  /// So: a dial in twentieths, and the sample paragraph above the slider is set
  /// in the face and size actually chosen. You stop moving it when it looks
  /// right, which is the only test there is.
  ///
  /// ── ROUND NINE, ISSUE 7 — THE FLOOR IS 0.75 NOW, AND HE WORKED IT OUT ────
  ///
  /// He photographed the same paragraph in two faces at the same 80%: one
  /// filled a single page, the other needed two. Then, in red:
  ///
  /// > *"Same amount of texts → different amount of space → **no issues** → I
  /// > understand Font Dynamics. So I came up on a solution: make it possible
  /// > for users to go even more down on the size Bar. Right now the minimum is
  /// > 80% — make it 75% → the new minimum."*
  ///
  /// That is a better answer than the one this file would have reached for.
  /// The tempting fix is per-face metric correction — a multiplier on Caveat so
  /// that "80%" means the same physical size in every face. It is wrong for the
  /// reason written four paragraphs above: which size *looks* right in a given
  /// face is taste, not geometry, and normalising it would take away the very
  /// dial that lets taste settle it. He is not asking to be protected from font
  /// dynamics. He says he understands them and wants more room at the bottom.
  ///
  /// So the floor moved and nothing else did. Five percent is one more stop on
  /// a slider that already had seventeen, it costs nothing to anyone who never
  /// touches it, and `ACCESSIBILITY.md`'s requirement is about the ceiling —
  /// every screen surviving 200% — which is untouched.
  static const double minTextScale = 0.75;
  static const double maxTextScale = 1.6;

  /// ── ROUND FIFTEEN, ISSUE 3 — THE STOPS LAND ON FIVES NOW ─────────────────
  ///
  /// He read the percentage off the slider all the way up and wrote the whole
  /// sequence out:
  ///
  /// > *"75 - 80 - 86 - 91 - 96 - 102 - 107 - 112 - 118 - 123 - 128 - 133 -
  /// > 139 - 144 - 149 - 155 – 160!! WHY SO WORSE? WHY NOT SIMPLY? 5?"*
  ///
  /// He is right and the cause is arithmetic rather than taste. The floor moved
  /// from 0.80 to 0.75 in round nine and the **number of divisions did not**,
  /// so seventeen stops were spread over a range of 0.85 and each one became
  /// 0.053125. That is invisible in the code and unmissable on the screen: the
  /// label rounds to a whole percent, so the stops drift — 80, 86, 91 — and
  /// two of them (102, 107) are not even multiples of anything.
  ///
  /// [textScaleStep] is the fix, and it is expressed as a step rather than as a
  /// count of divisions **on purpose**. A count has to be recomputed by hand
  /// every time either end of the range moves, which is exactly the mistake
  /// that produced the sequence above. A step cannot go stale: the slider asks
  /// for [textScaleDivisions], and if the floor or the ceiling ever changes
  /// again the stops stay on fives by themselves.
  ///
  /// 0.75 → 1.60 in steps of 0.05 is 18 stops: 75, 80, 85 … 155, 160.
  static const double textScaleStep = 0.05;

  /// The number of gaps between slider stops. Derived, never written down.
  static int get textScaleDivisions =>
      ((maxTextScale - minTextScale) / textScaleStep).round();

  /// The nearest stop to [value], as a percentage that ends in 0 or 5.
  ///
  /// Applied on the way **in** as well as on the way out, so a setting written
  /// by an older build — 0.853125, say — reads back as 0.85 rather than
  /// sitting a hair off the grid forever and putting a 85% label on a thumb
  /// that is not quite on the 85% notch.
  static double snapTextScale(double value) {
    final steps = ((value - minTextScale) / textScaleStep).round();
    final snapped = minTextScale + steps * textScaleStep;
    // Multiplying a step by a count reintroduces the float error it was there
    // to remove — 0.75 + 2 * 0.05 is 0.8500000000000001 — and that shows up as
    // a slider that will not sit exactly on its own division. Round to the
    // fourth place, which is three more than a percentage label can show.
    return (snapped * 10000).roundToDouble() / 10000;
  }

  /// **Round five, ISSUE 7 — this is 0.9 and not 1.0, deliberately.**
  ///
  /// He put the two side by side and wrote it plainly: at 100% *"this looks
  /// like it's an app for old age people, looks worst"*, and at 85%
  /// *"this maintains aesthetics, looks perfect"*. He asked for the middle:
  /// **"Default sizing is 100% → make it 90%."**
  ///
  /// It is worth being clear about what this does, because the number is not
  /// as innocent as it looks. [textScale] *multiplies* the phone's own text
  /// setting, so this ships the app at nine-tenths of whatever the person has
  /// already chosen system-wide — including someone who turned their system
  /// text **up** because they need it.
  ///
  /// That is a real cost and it is accepted with open eyes, for two reasons.
  /// The slider is one screen away, starts at 75% and reaches 160%, so nobody
  /// is stuck; and `ACCESSIBILITY.md`'s actual requirement is that every screen
  /// survives 200% without clipping, which is a statement about the *ceiling*
  /// and is unaffected by where the default sits. What is **not** acceptable is
  /// making this conditional — "0.9 unless the OS is above 1.0" would mean the
  /// same app shows a different default on two phones for reasons nobody can
  /// see, and the next document would say so.
  static const double defaultTextScale = 0.9;

  double get textScale {
    final v = _data['textScale'];
    if (v is num && v >= minTextScale && v <= maxTextScale) {
      return snapTextScale(v.toDouble());
    }
    return defaultTextScale;
  }

  set textScale(double value) => _write(
      'textScale', snapTextScale(value.clamp(minTextScale, maxTextScale)));

  // ── Locking ────────────────────────────────────────────────────────────────

  /// Idle auto-lock. [Duration.zero] means never.
  ///
  /// `UX-FLOWS.md` flow 7 sets the default at one minute and the range at 15
  /// seconds to never. "Never" is not a loophole — `ACCESSIBILITY.md` points
  /// out that a short timeout is a genuine barrier for someone who types
  /// slowly, and an app that locks mid-sentence is one you stop using. Locking
  /// on backgrounding is a separate rule, always on, and not configurable.
  /// **Default raised from one minute to five, 19 August 2026.** One minute is
  /// aggressive enough that the app locks while you are reading something you
  /// wrote, and the person it inconveniences is always the owner — the threat
  /// it defends against (somebody picking up the unlocked phone) is already
  /// covered by locking on background, which is not configurable and never
  /// will be. Fifteen seconds is still there for anybody who wants it.
  Duration get autoLock {
    final seconds = _data['autoLockSeconds'];
    if (seconds is int && seconds >= 0) return Duration(seconds: seconds);
    return const Duration(minutes: 5);
  }

  set autoLock(Duration value) => _write('autoLockSeconds', value.inSeconds);

  /// Whether the fingerprint prompt opens by itself. **ISSUE 19.**
  ///
  /// ── WHAT THIS REPLACED, AND WHY ────────────────────────────────────────────
  ///
  /// There used to be a *duration* here called `unlockGrace`, shown on the
  /// settings screen as **"Coming straight back — Skip for 300 seconds"**. He
  /// filed it twice in one paragraph:
  ///
  /// > *"Locking and security — coming straight back — doesn't works whatever
  /// > time is set it doesn't works! … if I choose 5 minutes — it shows me 300
  /// > seconds — IK they all are logically correct — but why create a
  /// > confusion?"*
  ///
  /// Both halves were true. The number was read back in seconds, which reads as
  /// the app correcting your choice rather than confirming it — that half is
  /// [humanDuration] now. And it genuinely did nothing he could observe, for
  /// two compounding reasons: everything it controlled was about the
  /// *fingerprint* prompt, so on a vault with no fingerprint it had no effect
  /// whatsoever; and its sense was **inverted** against its own label. "Coming
  /// straight back, skip for five minutes" reads as *get me in faster*. What it
  /// did was suppress the automatic prompt when you came back quickly — so
  /// coming straight back cost you an extra tap.
  ///
  /// The original reasoning was sound and it was an argument for a different
  /// label: a system dialog appearing because you glanced at a notification is
  /// the app being needy. So that behaviour is still available. It is a switch,
  /// the switch says exactly what it does, and it lives under the fingerprint
  /// toggle it depends on rather than in a group of its own.
  ///
  /// **Nothing here touches the vault.** It still locks the instant the app
  /// goes into the background and the keys are still destroyed, whichever way
  /// this is set. All that changes is whether Android's prompt opens on its own
  /// or waits to be asked.
  bool get promptForFingerprint =>
      _data['promptForFingerprint'] as bool? ?? true;

  set promptForFingerprint(bool value) =>
      _write('promptForFingerprint', value);

  // ── Reminders ──────────────────────────────────────────────────────────────

  /// A daily nudge to write. **Off unless it is switched on.**
  ///
  /// THIS ONE NEEDED AN ARGUMENT, SO HERE IT IS
  ///
  /// `PLAN.md` §10 strikes through "notifications that create a reason to
  /// open", and `ETHICAL-DESIGN.md` §1 bans manufactured guilt. Both are right
  /// about what they are banning, which is the *retention* notification: the
  /// one with a streak in it, or a count of days missed, or a red dot, whose
  /// job is to make not-opening uncomfortable.
  ///
  /// This is not that, and the difference is not a technicality:
  ///
  ///   * **Off by default.** Nobody is opted in. It exists because the owner
  ///     asked for it, and it arrives only for people who go and ask for it too.
  ///   * **It never mentions the vault.** No counts, no "you haven't written in
  ///     5 days", no streak, nothing that could shame. It cannot: the notifier
  ///     runs with the vault sealed and has no way to know what is in there.
  ///     That is an architectural guarantee, not a promise.
  ///   * **A hundred different lines, chosen at random.** A reminder that says
  ///     the same eleven words every evening is wallpaper within a week, and
  ///     wallpaper you dismiss without reading is worse than nothing.
  ///   * **One a day at most, at an hour the user picked.** Never a second.
  ///
  /// The one-line test in `PLAN.md` §3 is "does this make the user glad they
  /// came back, or anxious about not having". An opt-in nudge that says
  /// *"There is a page here with today's date on it"* is the first. If it ever
  /// starts saying the second thing, delete it.
  bool get remindersEnabled => _data['remindersEnabled'] as bool? ?? false;

  set remindersEnabled(bool value) => _write('remindersEnabled', value);

  /// Minutes after midnight. Defaults to nine in the evening — after dinner,
  /// before bed, which is when a person has a day to look back on.
  int get reminderMinuteOfDay {
    final v = _data['reminderMinuteOfDay'];
    if (v is int && v >= 0 && v < 24 * 60) return v;
    return 21 * 60;
  }

  set reminderMinuteOfDay(int value) =>
      _write('reminderMinuteOfDay', value.clamp(0, 24 * 60 - 1));

  // ── Screenshots ────────────────────────────────────────────────────────────

  /// Whether the phone is allowed to capture this app's screen.
  ///
  /// **Off by default, and off is the secure state.** `FLAG_SECURE` is on from
  /// the first frame of every launch; turning this on clears it.
  ///
  /// ── WHY THIS IS A SETTING AND NOT A BUILD FLAG ───────────────────────────
  ///
  /// It used to be `SCREENSHOT_HOLE`: the flag was skipped in **debug** builds
  /// so Piyush could photograph the interface and show it to me. That had a
  /// cost nobody had priced. A debug build runs Dart under the JIT with every
  /// assertion on, so it is meaningfully slower than the real thing — which
  /// means the only build he could screenshot was never the build he was
  /// actually judging, and several rounds of "it feels slow" were collected
  /// against it.
  ///
  /// He asked for screenshots on the release build on 22 August. A setting is
  /// both more useful and more honest than a build flag: the capability is
  /// visible in the interface, he can turn it off again, and what he
  /// photographs is the app as it really runs.
  ///
  /// ── WHAT IT ACTUALLY COSTS, WHICH THE SWITCH SAYS OUT LOUD ───────────────
  ///
  /// `FLAG_SECURE` is one flag doing three jobs and Android does not let them
  /// be separated:
  ///
  ///   * the recent-apps switcher shows a blank rectangle rather than the page
  ///   * screenshots and screen recording are refused, by this app and others
  ///   * the window will not mirror to a non-secure external display
  ///
  /// `THREAT-MODEL.md` ranks "the person who picks up the unlocked phone" as
  /// the most likely adversary by a wide margin, and the **recents thumbnail**
  /// is the cheapest way that person reads a note without ever unlocking the
  /// vault. That is the real thing being given up here, and it is why this is
  /// off unless somebody deliberately turns it on.
  ///
  /// Signal ships exactly this switch, under "Screen security", for exactly
  /// these reasons. `PLAN.md` §11 test 5: where the reference apps have
  /// converged, do it their way.
  bool get allowScreenshots => _data['allowScreenshots'] as bool? ?? false;

  set allowScreenshots(bool value) => _write('allowScreenshots', value);

  // ── Backup ─────────────────────────────────────────────────────────────────

  /// Whether Lamplight backs itself up without being asked.
  ///
  /// Off until someone turns it on, and turning it on means choosing a folder.
  /// Not defaulted to on: an automatic backup writes the user's entire life to
  /// a location on a schedule they did not set, and `ETHICAL-DESIGN.md` would
  /// have something to say about deciding that for them.
  bool get silentBackupEnabled =>
      (_data['silentBackupEnabled'] as bool? ?? false) &&
      (useDefaultBackupFolder || backupFolderUri != null);

  set silentBackupEnabled(bool value) =>
      _write('silentBackupEnabled', value);

  /// Whether backups go to `Documents/Lamplight` rather than to a folder the
  /// user picked out of the system picker.
  ///
  /// ══ "CHOOSE FOLDER DOESN'T WORK MAN!" 2 SEPTEMBER 2026 ═════════════════
  ///
  /// **Default on**, and that is the whole repair. Turning automatic backup on
  /// used to mean getting through `ACTION_OPEN_DOCUMENT_TREE` first — and
  /// Android is entitled to refuse that for the root of internal storage, an
  /// SD card root, and Downloads, *inside its own picker*, with a message we
  /// did not write and cannot suppress. He hit it three rounds running and
  /// sent a photograph of it on a build that already had the last fix in.
  ///
  /// There is nothing left to fix on that path, because the restriction is the
  /// point of it: a tree grant hands an app a whole folder for ever. So the
  /// feature stopped needing one. `Documents/Lamplight` is writable on Android
  /// 10 and later with **no permission and no picker**, and files put there
  /// outlive the app — which was the entire requirement, `allowBackup` being
  /// false. Nothing is granted, so nothing can be refused.
  ///
  /// Set to false the moment somebody picks a folder by hand, because doing so
  /// is an explicit statement about where their backups should go and it must
  /// outrank a default. Set back to true if they clear that folder.
  ///
  /// On Android 9 and below there is no such place — writing outside the
  /// sandbox there needs `WRITE_EXTERNAL_STORAGE`, which grants the whole of
  /// shared storage and is not a permission this app will ever add. Those
  /// devices keep the picker, and the settings screen says which one they are
  /// getting rather than showing a switch that cannot work.
  bool get useDefaultBackupFolder =>
      _data['useDefaultBackupFolder'] as bool? ?? true;

  set useDefaultBackupFolder(bool value) =>
      _write('useDefaultBackupFolder', value);

  /// The folder the user picked, as an opaque Android tree URI.
  ///
  /// **This is a URI, not a path, and it is not a secret.** It names a folder —
  /// `content://com.android.externalstorage.../Documents/Lamplight` — and says
  /// nothing about what is in it. It lives in this plaintext file for the same
  /// reason the theme does: the alternative is asking again after every reboot,
  /// which is not automatic. The grant it refers to is held by Android, not by
  /// us, and the user can revoke it from their own system settings.
  String? get backupFolderUri => _data['backupFolderUri'] as String?;

  set backupFolderUri(String? value) => _write('backupFolderUri', value);

  /// A name for the folder that a person can recognise.
  ///
  /// The raw tree URI is unreadable — a percent-encoded content path. Settings
  /// shows this instead, because "Documents/Lamplight" answers "where are my
  /// backups going" and the URI does not.
  String? get backupFolderLabel => _data['backupFolderLabel'] as String?;

  set backupFolderLabel(String? value) => _write('backupFolderLabel', value);

  DateTime? get lastBackupAt {
    final ms = _data['lastBackupAt'];
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  set lastBackupAt(DateTime? value) =>
      _write('lastBackupAt', value?.millisecondsSinceEpoch);

  /// Whether the backup on disk is sealed under a passcode that is no longer
  /// the user's. **ROUND NINE, ISSUE 20.**
  ///
  /// ══ WHY THIS IS A SETTING AND NOT A FLAG IN MEMORY ═══════════════════════
  ///
  /// > *"As the passcode is done — do a backup, so whatever the backup file had
  /// > old password changes to new one!"*
  ///
  /// The automatic backup runs when the **vault** has been written to. Changing
  /// a passcode rewraps thirty-two bytes in the keyring and writes nothing
  /// anybody would call a change — so on its own it never triggers a run, and
  /// somebody with automatic backups switched on would go on holding a file
  /// that needs a passcode they have deliberately forgotten, and would never be
  /// told.
  ///
  /// `SilentBackup._dirty` would be the natural home for this and it is the
  /// wrong one: it lives in memory and dies with the process, and this problem
  /// does not. Somebody who changes their passcode and closes the app has the
  /// same stale file tomorrow. So it is written down, and cleared by the next
  /// backup that actually finishes — by hand or on its own.
  bool get backupOutOfDate => _data['backupOutOfDate'] as bool? ?? false;

  set backupOutOfDate(bool value) => _write('backupOutOfDate', value);

  /// Whether the vault has been written to since the last backup that finished.
  ///
  /// ══ THIS USED TO LIVE IN MEMORY, AND THAT WAS THE BUG ════════════════════
  ///
  /// `SilentBackup._dirty` was a plain `bool` field. The comment on
  /// [backupOutOfDate] directly above already worked out why that is the wrong
  /// home for anything of this shape — *"it lives in memory and dies with the
  /// process, and this problem does not"* — and then the main dirty flag was
  /// left in memory anyway.
  ///
  /// What that cost: the automatic backup was triggered on
  /// `AppLifecycleState.inactive`, which is the frame or two before the vault
  /// locks. A backup is a second Argon2id at 256 MiB, a copy of the whole
  /// database, a verify pass and a write through the Storage Access Framework.
  /// It cannot finish in that window, so it was **killed by the lock on
  /// essentially every real exit** — and the run that had already set
  /// `_lastAttempt` then blocked the next attempt for ten minutes.
  ///
  /// It only appeared to work when `inactive` did *not* mean leaving — a
  /// notification shade pulled down, an incoming call — because then the app
  /// came back and the work finished. So it succeeded exactly when it was least
  /// needed and failed exactly when it mattered, which is why the settings
  /// screen so often said *"the last automatic backup did not finish"*.
  ///
  /// Written down, the flag survives the process, so the backup can happen at
  /// the one moment it can actually complete: **the next unlock**, in the
  /// foreground, with the app staying open. Cleared by any backup that finishes,
  /// by hand or on its own.
  bool get vaultChangedSinceBackup =>
      _data['vaultChangedSinceBackup'] as bool? ?? false;

  /// Cheap to set repeatedly, which matters: this is written on every entry,
  /// every edit and every attachment, so the common case by far is setting
  /// `true` when it is already `true`. [_write] returns without touching the
  /// disk when the value is unchanged, so that costs a comparison.
  set vaultChangedSinceBackup(bool value) =>
      _write('vaultChangedSinceBackup', value);

  /// Whether the quiet backup reminder should be showing.
  ///
  /// Flow 5: a single quiet banner, never a modal and never a red badge.
  /// Dismissing it buys 7 days. The wording escalates gently; the intrusiveness
  /// never does.
  ///
  /// ══ THE FORTNIGHT WAS WRONG, AND IT COST A VAULT ═════════════════════════
  ///
  /// This used to say nothing at all for **fourteen days** when no backup had
  /// ever been made, and the reasoning written here was:
  ///
  /// > *"A reminder on day one is nagging someone about losing a vault with
  /// > three sentences in it."*
  ///
  /// That is right about day one and wrong about what to count. On 28 August
  /// 2026 a three-day-old vault on the Redmi Pad was destroyed — a development
  /// build's install was refused by the device, and the tooling's cleanup
  /// uninstalled the real app, which with `allowBackup="false"` takes
  /// `/data/data` with it. **The one feature designed to prevent exactly that
  /// had not spoken yet, and would not have for another eleven days.**
  ///
  /// It was a test vault and nothing irreplaceable went. The next one will not
  /// be a test vault.
  ///
  /// **What to count is not days, it is what would be lost.** A vault with
  /// three sentences in it genuinely does not need a banner; a vault somebody
  /// has written in on four separate days is a habit, and losing a habit's
  /// worth of writing is the thing this app exists to prevent. Nobody can tell
  /// in advance which of those they are about to become, which is precisely why
  /// the app should ask at the moment it can tell.
  ///
  /// So the never-backed-up case now takes the size of the vault, and the
  /// fortnight stays only as a backstop for somebody who writes rarely.
  /// [entries] and [days] come from `EntryRepository.stats`.
  ///
  /// `ETHICAL-DESIGN.md` is not bent by this. It is still one dismissible line,
  /// still no modal, still no count of what you have not done — and it is now
  /// *more* honest, because it arrives when the sentence on it is true.
  bool backupReminderDueFor({int entries = 0, int days = 0}) {
    final snoozed = _data['backupNagSnoozedUntil'];
    if (snoozed is int && DateTime.now().millisecondsSinceEpoch < snoozed) {
      return false;
    }
    final last = lastBackupAt;
    if (last == null) {
      // Enough that losing it would hurt: writing on more than one day, and
      // more than a handful of things. Both, not either — five entries in one
      // afternoon is somebody trying the app out, and two entries a fortnight
      // apart is not yet a journal.
      if (entries >= _worthBackingUpEntries && days >= _worthBackingUpDays) {
        return true;
      }
      // The backstop, for somebody who writes rarely enough never to trip the
      // rule above. Unchanged, and it is no longer the only thing.
      final first = _data['firstRunAt'];
      if (first is! int) return false;
      return DateTime.now().millisecondsSinceEpoch - first >
          const Duration(days: 14).inMilliseconds;
    }
    return DateTime.now().difference(last) > const Duration(days: 30);
  }

  /// A vault worth protecting: this many entries, across this many days.
  ///
  /// Deliberately small. The cost of asking a little early is one dismissible
  /// line; the cost of asking late is somebody's writing.
  static const int _worthBackingUpEntries = 5;
  static const int _worthBackingUpDays = 2;

  /// The old shape, for callers that have no idea how big the vault is.
  ///
  /// Kept so that nothing has to pretend to know. It answers the same question
  /// with less information, which means it can only ever be *later* than
  /// [backupReminderDueFor] — never a false alarm.
  bool get backupReminderDue => backupReminderDueFor();

  void snoozeBackupReminder() => _write(
        'backupNagSnoozedUntil',
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
      );

  /// Stamped once, on the first run that ever reads this file, so the reminder
  /// above has something to count from.
  void markFirstRun() {
    if (_data['firstRunAt'] is int) return;
    _write('firstRunAt', DateTime.now().millisecondsSinceEpoch);
  }

  // ───────────────────────────────────────────────────────────────────────────

  void _write(String key, Object? value) {
    if (_data[key] == value) return;
    _data = {..._data, key: value};
    notifyListeners();
    // Fire and forget. A failed preference write is not worth blocking a tap
    // for, and the in-memory value is already correct.
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      await _file.parent.create(recursive: true);
      // Write beside, then rename. A rename is atomic on every filesystem this
      // app will ever meet, so being killed mid-write leaves the old file
      // intact rather than a truncated one that fails to parse on next launch.
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(jsonEncode(_data), flush: true);
      await tmp.rename(_file.path);
    } catch (_) {
      // Nothing sensible to do, and nothing lost but a preference.
    }
  }
}
