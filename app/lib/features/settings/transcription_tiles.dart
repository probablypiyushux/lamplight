import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/platform/transcription.dart';
import '../../core/settings/app_settings.dart';
import '../../design/components.dart';
import 'settings_screen.dart' show showLampChoiceSheet;

/// The switch and the language, for **ISSUE 15**.
///
/// ── WHY THIS IS A WIDGET THAT CAN HIDE ITSELF ───────────────────────────────
///
/// On-device speech recognition needs Android 13 and a phone whose maker
/// actually shipped a service behind the API. Plenty did not. So the rows are
/// **absent** rather than greyed out on a phone that cannot do it — the same
/// decision the fingerprint group makes, for the same reason written there: a
/// permanently dead switch is a small daily reminder of something the user
/// cannot fix.
class TranscriptionTiles extends StatefulWidget {
  const TranscriptionTiles({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<TranscriptionTiles> createState() => _TranscriptionTilesState();
}

class _TranscriptionTilesState extends State<TranscriptionTiles> {
  bool? _available;
  TranscriptionLanguages _languages =
      const TranscriptionLanguages(installed: [], supported: []);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _look();
  }

  Future<void> _look() async {
    final available = await Transcription.available;
    if (!mounted) return;
    setState(() => _available = available);
    if (!available) return;
    final languages = await Transcription.languages();
    if (!mounted) return;
    setState(() => _languages = languages);
  }

  /// A tag like `en-IN` as *English (India)*, in the phone's own words.
  ///
  /// `Locale.fromSubtags` plus the framework's own display names would be one
  /// line and is not available for arbitrary tags without `intl`, which
  /// `CLAUDE.md` rule 4 would want an argument for. This is enough: the
  /// language name in its own script where the system knows it, and the tag
  /// itself where it does not, which is honest and never wrong.
  String _describe(String tag) {
    final parts = tag.split(RegExp('[-_]'));
    final language = parts.first;
    final region = parts.length > 1 ? parts.last : null;
    final name = _languageNames[language.toLowerCase()];
    if (name == null) return tag;
    return region == null || region.length != 2 ? name : '$name ($region)';
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) return const SizedBox.shrink();

    final settings = widget.settings;
    final chosen = settings.transcriptionLanguage;
    final installed = _languages.installed.contains(chosen);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LampSwitchTile(
          title: L.of(context).transcribeTitle,
          // The whole promise, in one line, at the point of decision — rather
          // than in a footer somebody reads after switching it on.
          subtitle: settings.transcribeVoice
              ? L.of(context).transcribeOn
              : L.of(context).transcribeOff,
          value: settings.transcribeVoice,
          onChanged: (v) {
            setState(() => settings.transcribeVoice = v);
            _look();
          },
        ),

        // ── ONE ENGINE, AND THE LANGUAGE IS NO LONGER OPTIONAL ────────────
        //
        // There were three rows here: a Whisper model importer, a switch to
        // *"use this phone's own instead"*, and a language picker that only
        // appeared when that switch was on. Whisper was removed on 28 August
        // 2026 — *"remove this whisper option please ... cause it's trash"* —
        // and with one engine left the switch had nothing to choose between,
        // so it is gone too. A control with one option is furniture.
        //
        // The language therefore stops being a sub-setting of a toggle nobody
        // sees and becomes **the** setting for this feature, which is what it
        // always actually was: Android's recogniser takes one BCP-47 tag per
        // session and everything about the quality of a transcript follows
        // from getting that tag right.
        if (settings.transcribeVoice)
          LampTile(
            title: L.of(context).transcribeLanguage,
            // ── "Two languages are disturbing" ────────────────────────────
            //
            // His words, about this row and the interface-language row being
            // impossible to tell apart. They are on different screens now, and
            // this one is named for what it describes — the language you
            // *speak into it* — rather than the bare word "Language", which
            // was the whole of the confusion.
            subtitle: installed
                ? L.of(context).transcribeLanguageNote: L.of(context).transcribeNotDownloaded,
            value: _describe(chosen),
            icon: Icons.record_voice_over_outlined,
            onTap: _busy ? null : () => _pick(context),
          ),

        // ── THE UPGRADE, WHICH IS A DOWNLOAD AND NOT A PURCHASE ───────────
        //
        // > *"give an option to upgrade that model with it's superior one?
        // > that would be the choice of user! make that choice easier"*
        //
        // What "superior" means for Android's recogniser is concrete rather
        // than marketing: a language can be **supported** (it will try, using
        // whatever small general model is resident) or **installed** (its own
        // downloaded acoustic model is on the phone). The second is markedly
        // better and it is a free one-tap download from Google.
        //
        // It used to be reachable only by opening the language picker and
        // noticing a grey "Needs downloading" label beside your own language —
        // which is not a choice anybody was being offered, it is one they had
        // to go looking for. So when the better model is missing for the
        // language already chosen, the offer is its own row, in words, with
        // the reason.
        if (settings.transcribeVoice && !installed)
          LampTile(
            title: L.of(context).transcribeGetBetter(_describe(chosen)),
            subtitle: L.of(context).transcribeGetBetterNote,
            icon: Icons.download_outlined,
            onTap: _busy ? null : () => _fetch(chosen),
          ),

      ],
    );
  }

  /// Asks the phone to download the better model for [tag].
  ///
  /// Android's download, of an acoustic model. Nothing the user wrote or said
  /// goes anywhere — see `Transcription.fetchLanguage`.
  Future<void> _fetch(String tag) async {
    setState(() => _busy = true);
    try {
      await Transcription.fetchLanguage(tag);
      await _look();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(BuildContext context) async {
    final all = <String>{
      ..._languages.installed,
      ..._languages.supported,
    }.toList()
      ..sort();

    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.of(context).transcribeNoLanguages),
      ));
      return;
    }

    await showLampChoiceSheet<String>(
      context: context,
      title: L.of(context).transcribeLanguage,
      current: widget.settings.transcriptionLanguage,
      options: [
        for (final tag in all)
          (
            tag,
            _describe(tag),
            // Says which ones are ready now. The difference matters: a
            // language that is supported but not downloaded produces an empty
            // transcript rather than an error, which looks exactly like a
            // recording with nothing in it.
            _languages.installed.contains(tag) ? 'Ready' : L.of(context).transcribeNeedsDownloading,
          ),
      ],
      onChanged: (tag) async {
        setState(() {
          widget.settings.transcriptionLanguage = tag;
          _busy = true;
        });
        if (!_languages.installed.contains(tag)) {
          // Android's download, of a language model — not of anything the user
          // wrote or said. See `Transcription.fetchLanguage`.
          await Transcription.fetchLanguage(tag);
          await _look();
        }
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}

/// Enough language names to cover what an on-device recogniser actually
/// offers, in English.
///
/// Deliberately not a package. `CLAUDE.md` rule 4 asks what a dependency is
/// worth against the fact that every package can read all of the user's notes,
/// and `intl`'s locale display names are not worth that for one settings row.
/// An unlisted tag falls back to the tag itself, which is ugly and never wrong.
const Map<String, String> _languageNames = <String, String>{
  'ar': 'Arabic',
  'bn': 'Bengali',
  'cs': 'Czech',
  'da': 'Danish',
  'de': 'German',
  'el': 'Greek',
  'en': 'English',
  'es': 'Spanish',
  'fa': 'Persian',
  'fi': 'Finnish',
  'fr': 'French',
  'gu': 'Gujarati',
  'he': 'Hebrew',
  'hi': 'Hindi',
  'hu': 'Hungarian',
  'id': 'Indonesian',
  'it': 'Italian',
  'ja': 'Japanese',
  'kn': 'Kannada',
  'ko': 'Korean',
  'ml': 'Malayalam',
  'mr': 'Marathi',
  'ms': 'Malay',
  'nb': 'Norwegian',
  'nl': 'Dutch',
  'pa': 'Punjabi',
  'pl': 'Polish',
  'pt': 'Portuguese',
  'ro': 'Romanian',
  'ru': 'Russian',
  'sk': 'Slovak',
  'sv': 'Swedish',
  'ta': 'Tamil',
  'te': 'Telugu',
  'th': 'Thai',
  'tr': 'Turkish',
  'uk': 'Ukrainian',
  'ur': 'Urdu',
  'vi': 'Vietnamese',
  'zh': 'Chinese',
};
