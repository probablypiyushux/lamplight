import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A ratchet against the thing that made every date in the app English.
///
/// ══ WHY A TEST AND NOT A NOTE ═══════════════════════════════════════════════
///
/// The twelve month names were written out as a `static const` list in **eight
/// separate files**, and nobody noticed, because each one on its own looks
/// completely reasonable. That is what makes it worth a test rather than a
/// comment: the failure mode is not somebody ignoring a rule, it is somebody
/// solving a small local problem the obvious way for the ninth time.
///
/// `lib/l10n/dates.dart` is the one place now. Anything that needs a month
/// name, a weekday, a time or a whole date asks it, and gets the reader's
/// language *and their ordering* — which a translated list of month names glued
/// to `'${date.day} $month'` cannot give, because Japanese and Chinese put the
/// day last.
void main() {
  test('no screen writes out its own month or weekday names', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Generated code is not written by anybody, and `intl`'s own tables are
      // exactly what this test wants the app to be using.
      if (entity.path.contains('generated')) continue;
      // The one file allowed to name a month: the importer, which has to
      // *recognise* English month names in a filename from another app. That is
      // reading somebody else's format rather than writing our own.
      if (entity.path.endsWith('journal_import.dart')) continue;

      final source = entity.readAsStringSync();
      final code = source
          .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
          .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

      // Two month names next to each other is a list. One on its own is prose.
      if (RegExp("'January'").hasMatch(code) &&
          RegExp("'February'").hasMatch(code)) {
        offenders.add('${entity.path} — month names');
      }
      if (RegExp("'Monday'").hasMatch(code) &&
          RegExp("'Tuesday'").hasMatch(code)) {
        offenders.add('${entity.path} — weekday names');
      }
    }

    expect(offenders, isEmpty,
        reason: 'These files write out English date words of their own. Use '
            '`LampDates` in lib/l10n/dates.dart — it gives the reader their '
            'language AND their ordering, which a translated list cannot: '
            'Japanese and Chinese put the day after the month. Offenders:\n'
            '${offenders.join('\n')}');
  });

  test('and nothing pads an hour by hand', () {
    // `'${at.hour}'.padLeft(2, '0')` is a 24-hour clock for everybody, which is
    // wrong for roughly half the languages here. It reads as a formatting
    // detail and is a localisation bug.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('generated')) continue;
      final code = entity
          .readAsStringSync()
          .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
          .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
      if (RegExp(r'\.hour\b[^\n]*padLeft').hasMatch(code)) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'Use `LampDates.time`, which asks intl whether this reader '
            'uses a 12- or 24-hour clock. Offenders:\n${offenders.join('\n')}');
  });
}
