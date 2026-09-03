import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../design/components.dart';
import '../../design/tokens.dart';

/// The typefaces this app carries, and the licence each one travels under.
///
/// ── WHY THIS SCREEN EXISTS AT ALL ────────────────────────────────────────
///
/// The SIL Open Font License permits bundling a face in an application without
/// a fee and without a credit in the interface — but it requires the licence
/// text to travel with the software. Shipping the files and never showing them
/// would meet the letter of that and miss the point: somebody's work is in this
/// app, and a person who wants to know whose can find out.
///
/// It also happens to be the cheapest trust signal in the whole product. An app
/// that says "no account, no server, nothing leaves this phone" is asking to be
/// believed about a lot of things at once. A screen that shows its actual
/// paperwork, in full, is a small piece of evidence that the other claims were
/// written by somebody who checks.
class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final entries = kFontLicences.entries.toList();

    return LampPage(
      title: L.of(context).aboutFonts,
      subtitle: L.of(context).licencesFonts,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.x10),
        children: [
          for (final e in entries)
            LampTile(
              title: e.key,
              subtitle: 'SIL Open Font License 1.1',
              icon: Icons.text_fields,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _LicenceText(name: e.key, asset: e.value),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.x6 + Space.x2, Space.x6, Space.x6 + Space.x2, Space.x6),
            child: Text(
              L.of(context).licencesSource,
              style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenceText extends StatelessWidget {
  const _LicenceText({required this.name, required this.asset});

  final String name;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return LampPage(
      title: name,
      child: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: Space.x6),
              child: Text(L.of(context).licencesUnreadable),
            );
          }
          final text = snap.data;
          if (text == null) {
            return const Padding(
              padding: EdgeInsets.only(top: Space.x10),
              child: Center(child: LampBusy()),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Space.x6, 0, Space.x6, Space.x10),
            children: [
              // A licence is a legal document and it is set as one: monospaced,
              // at the size it was written for, wrapping where it wants to
              // rather than being reflowed into something prettier and less
              // exact.
              SelectableText(
                text,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  height: 1.6,
                  color: c.inkSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
