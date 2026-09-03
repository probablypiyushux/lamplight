import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/keyring.dart';
import 'package:lamplight/core/crypto/mnemonic.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/plain_words.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';

/// **ROUND FIFTEEN — the last English a person could read, and the worst place
/// for it.**
///
/// > *"MOST IMPORTANT ISSUE - LOCALISATION I WANT YOU TO AIM FOR 100%
/// > LOCALISATION, don't even leave a tiny bits now bro! keep it all patched
/// > up!"*
///
/// Everything drawn on a screen was translated first. What was left were the
/// sentences thrown from `core/`: **what the app says when a backup fails, when
/// a restore fails, or when a recovery phrase will not open a vault.** Somebody
/// reading Lamplight in Hindi does not switch to English at the moment their
/// notes are at stake — that is the moment they need it least.
///
/// They could not become `L.of(context).…` like every other string, because
/// `core/` has no `BuildContext` and must not grow one: `vault_file.dart` runs
/// inside isolates, from background paths, and from tests with no widget tree.
/// So the exception carries a **key** and the screen, which has a context,
/// decides how to say it. `Localisable` in `plain_words.dart` is the contract.
///
/// This file is the proof that the key actually arrives, in all ten languages,
/// for every case — and that the English fallback still works for the callers
/// that have no `L` to give.
void main() {
  late Map<Locale, L> languages;

  setUpAll(() async {
    languages = {
      for (final locale in L.supportedLocales)
        locale: await L.delegate.load(locale),
    };
  });

  /// One [BackupError] per [BackupProblem], with a detail where the sentence
  /// names something.
  Map<BackupProblem, BackupError> everyBackupProblem() => {
        for (final p in BackupProblem.values)
          p: BackupError('the English one', problem: p, detail: 'vault.db'),
      };

  group('a backup that fails says so in the reader language', () {
    test('every problem has a sentence in every language', () {
      final errors = everyBackupProblem();
      for (final entry in languages.entries) {
        for (final e in errors.entries) {
          final said = e.value.describeIn(entry.value);
          expect(said, isNotEmpty,
              reason: '${e.key} in ${entry.key.languageCode}');
          expect(said, isNot('the English one'),
              reason: '${e.key} in ${entry.key.languageCode} fell through to '
                  'the English message, which means the key is missing');
        }
      }
    });

    test('and no two problems say the same thing in English', () {
      // Not a style rule. Two failures with one sentence means somebody
      // reading the message cannot tell which of them happened, and the
      // *point* of `UX-FLOWS.md` flow 6 is a distinct message per case
      // somebody can act on.
      //
      // `damaged` is deliberately shared by seven throw sites — a person
      // cannot act on which header field failed to parse — but it is one
      // enum case, so it appears here once.
      final english = languages[const Locale('en')]!;
      final said = <String, BackupProblem>{};
      for (final entry in everyBackupProblem().entries) {
        final text = entry.value.describeIn(english);
        expect(said.containsKey(text), isFalse,
            reason: '${entry.key} and ${said[text]} say the same thing');
        said[text] = entry.key;
      }
    });

    test('a detail is passed through untranslated', () {
      // A filename is a filename in every language. Passing it as a
      // placeholder keeps it out of the translated text, where a translator
      // would have no way to know it was not a word.
      for (final entry in languages.entries) {
        final e = const BackupError('x',
            problem: BackupProblem.missingPart, detail: 'media/a1b2.enc');
        expect(e.describeIn(entry.value), contains('media/a1b2.enc'),
            reason: entry.key.languageCode);
      }
    });

    test('an error with no key still says its English sentence', () {
      // Every `throw` in vault_file.dart carries a key, but the constructor
      // does not require one — and a caller that builds a BackupError without
      // one must get the message rather than an empty string.
      const bare = BackupError('Something went wrong.');
      expect(bare.describeIn(languages[const Locale('hi')]!),
          'Something went wrong.');
    });
  });

  group('so does a vault that will not open', () {
    test('the keyring, in every language', () {
      for (final entry in languages.entries) {
        for (final p in KeyringProblem.values) {
          final said =
              KeyringException('english', problem: p).describeIn(entry.value);
          expect(said, isNotEmpty, reason: '$p in ${entry.key.languageCode}');
          expect(said, isNot('english'), reason: '$p');
        }
      }
    });

    test('a database written by a newer Lamplight, in every language', () {
      for (final entry in languages.entries) {
        expect(const VaultTooNew(9, 5).describeIn(entry.value), isNotEmpty,
            reason: entry.key.languageCode);
      }
    });
  });

  group('and a recovery phrase that will not decode', () {
    test('every problem, in every language', () {
      for (final entry in languages.entries) {
        for (final p in MnemonicProblem.values) {
          final said = MnemonicException('english', problem: p, detail: '7')
              .describeIn(entry.value);
          expect(said, isNotEmpty, reason: '$p in ${entry.key.languageCode}');
          expect(said, isNot('english'), reason: '$p');
        }
      }
    });

    test('the word that was not recognised comes back verbatim', () {
      // Round twelve's lesson, applied here: a recovery word is Latin and the
      // reader may not be. Quoting it back is the only way they can find it.
      final said = const MnemonicException('english',
              problem: MnemonicProblem.notARecoveryWord, detail: 'giraffee')
          .describeIn(languages[const Locale('ja')]!);
      expect(said, contains('giraffee'));
    });
  });

  group('plainFailure prefers the reader language when it is given one', () {
    test('with an L, the localised sentence wins', () {
      final hindi = languages[const Locale('hi')]!;
      final said = plainFailure(
        const BackupError('the English one',
            problem: BackupProblem.notALamplightFile),
        fallback: 'unused',
        words: hindi,
      );
      expect(said, hindi.vaultNotALamplightFile);
    });

    test('without one, English — which is not a bug', () {
      // `SilentBackup` and `TranscriptionQueue` run on background paths and are
      // handed their words by the first screen that has a context. Until then
      // it is null, and English is the right answer — the same rule the ARB
      // files follow, where a missing key falls back rather than failing.
      final said = plainFailure(
        const BackupError('This is not a Lamplight backup file.',
            problem: BackupProblem.notALamplightFile),
        fallback: 'unused',
      );
      expect(said, 'This is not a Lamplight backup file.');
    });

    test('and something that is not ours still gets the plain fallback', () {
      final said = plainFailure(
        StateError('Instance of _SomeInternalThing#a1b2'),
        fallback: 'That did not work.',
        andThen: 'Nothing was lost.',
        words: languages[const Locale('en')],
      );
      expect(said, 'That did not work. Nothing was lost.');
    });
  });
}
