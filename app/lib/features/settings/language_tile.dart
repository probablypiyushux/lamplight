import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Choosing which language the app speaks.
///
/// ══ THE ONE THING THIS ROW HAS TO GET ACROSS ══════════════════════════════
///
/// Not the list — the list is obvious. It is that **this setting does not
/// decide what you can write.**
///
/// That is the question somebody actually has when they see "Language" in a
/// journal, and getting it wrong in either direction is bad: a person who
/// thinks the app only accepts English will not write in Hindi, and a person
/// who switches to Japanese expecting their existing entries to change will be
/// confused when they do not. So the subtitle says it plainly, in the language
/// they are currently reading, before they tap anything.
///
/// Lamplight has always accepted any script a keyboard can produce. Since 28
/// August it can also *search* them — the query splitter was ASCII-only until
/// then, which made a Hindi search return nothing and look like an empty vault
/// rather than a broken search.
///
/// ── WHY EVERY LANGUAGE IS NAMED IN ITSELF ────────────────────────────────
///
/// `Español`, not `Spanish`. `العربية`, not `Arabic`. Somebody looking for
/// their own language is scanning for the shape of their own word, and they may
/// well not read the language the app is currently in — which is precisely why
/// they are on this screen. A list written in English is a list that is hardest
/// to use for exactly the people who need it.
///
/// This is also why the names are **hard-coded here and not translated**. There
/// is no ARB entry for them, deliberately: `Deutsch` is `Deutsch` on every
/// screen in every locale, and a translated language list would be a list that
/// changes under somebody depending on where they came from.
class LanguageTile extends StatefulWidget {
  const LanguageTile({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<LanguageTile> createState() => _LanguageTileState();
}

/// The languages the app speaks, each in its own words.
///
/// The order is the order they were added, which is roughly by number of
/// speakers, and it is not sorted alphabetically — an alphabetical list is
/// alphabetical in *one* script and arbitrary in the other nine.
const List<({Locale? locale, String name, String english})> kLanguages = [
  (locale: null, name: '', english: ''), // the system row; labelled from ARB
  (locale: Locale('en'), name: 'English', english: 'English'),
  (locale: Locale('es'), name: 'Español', english: 'Spanish'),
  (locale: Locale('zh'), name: '简体中文', english: 'Chinese (Simplified)'),
  (locale: Locale('hi'), name: 'हिन्दी', english: 'Hindi'),
  (locale: Locale('ar'), name: 'العربية', english: 'Arabic'),
  (locale: Locale('pt'), name: 'Português (Brasil)', english: 'Portuguese'),
  (locale: Locale('de'), name: 'Deutsch', english: 'German'),
  (locale: Locale('fr'), name: 'Français', english: 'French'),
  (locale: Locale('ja'), name: '日本語', english: 'Japanese'),
  (locale: Locale('ko'), name: '한국어', english: 'Korean'),
];

class _LanguageTileState extends State<LanguageTile> {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final current = widget.settings.locale;
    final chosen = kLanguages.firstWhere(
      (e) => e.locale?.languageCode == current?.languageCode,
      orElse: () => kLanguages.first,
    );

    return LampTile(
      title: l.settingsLanguage,
      subtitle: l.settingsLanguageNote,
      icon: Icons.translate,
      value: current == null ? l.settingsLanguageSystem : chosen.name,
      onTap: () => _choose(context),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final l = L.of(context);
    final picked = await showLampSheet<Object>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x5, Space.x6, Space.x2),
              child: Text(l.settingsLanguage,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final entry in kLanguages)
              LampTile(
                // The system row is the only one whose label comes from the
                // ARB, because it is a sentence rather than a name.
                title: entry.locale == null
                    ? l.settingsLanguageSystem
                    : entry.name,
                // The English name underneath, and only where it differs.
                // It is a bridge for somebody who arrived in a language they
                // cannot read and is looking for a word they can.
                subtitle: entry.locale == null ||
                        entry.name == entry.english
                    ? null
                    : entry.english,
                icon: _isCurrent(entry.locale)
                    ? Icons.check
                    : Icons.circle_outlined,
                onTap: () => Navigator.of(sheet)
                    .pop<Object>(entry.locale ?? _followThePhone),
              ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      widget.settings.locale = picked == _followThePhone ? null : picked as Locale;
    });
  }

  bool _isCurrent(Locale? locale) =>
      widget.settings.locale?.languageCode == locale?.languageCode;

  /// A sentinel, because `pop(null)` is indistinguishable from dismissing the
  /// sheet — and "follow the phone" is a choice somebody makes on purpose.
  static const Object _followThePhone = Object();
}
