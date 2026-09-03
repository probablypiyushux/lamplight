import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'wordlist_english.dart';
import '../../l10n/generated/app_localizations.dart';
import '../plain_words.dart';

/// The twelve-word recovery phrase — BIP-39 encoding, English wordlist.
///
/// WHAT THIS IS FOR
///
/// `01-decisions/DECISIONS.md` ADR-003 makes this the *only* way back into a
/// vault when the passcode is forgotten. There is no server reset, no email
/// link, no support backdoor. That is the whole point: the escape hatch is a
/// secret only the user holds, so it cannot be subpoenaed from us, phished
/// from a support inbox, or leaked in a breach — because it does not exist in
/// our world.
///
/// WHY WE IMPLEMENT THIS RATHER THAN USING A PACKAGE
///
/// The obvious package, `bip39`, has not been published since 2021 and pulls
/// in `pointycastle`, `hex` and `crypto` — four dependencies in the most
/// security-critical path in the app, one of them unmaintained.
/// `04-technical/TECH-STACK.md` treats a short dependency list as a security
/// property, and this is where that rule earns its keep.
///
/// The trade is acceptable because **BIP-39 is an encoding, not a cipher**.
/// There is no secret here and no cleverness available — it is a fixed
/// mapping from bits to words plus a four-bit checksum. It is also a frozen
/// specification with published test vectors, so "did we get it right" has an
/// objective answer rather than an opinion. Those vectors are asserted in
/// `test/crypto/mnemonic_test.dart`, including the all-zeroes and all-ones
/// edge cases.
///
/// WHAT THIS IS NOT
///
/// This is not a Bitcoin wallet seed. We never run BIP-39's PBKDF2 seed
/// derivation, and there is no passphrase ("25th word"). The raw entropy is
/// what wraps the vault key, exactly as `02-security/SECURITY-ARCHITECTURE.md`
/// §3 step 4 specifies. Using the standard wordlist and checksum only means a
/// phrase can be sanity-checked against any BIP-39 tool, which is a nice
/// property for something a person may need to read off paper in fifteen years.
class Mnemonic {
  Mnemonic._();

  /// 128 bits of entropy → 12 words. The size ADR-003 specifies.
  static const int entropyBytes = 16;

  /// How many words the user writes down.
  static const int wordCount = 12;

  /// Encodes raw entropy as a recovery phrase.
  ///
  /// The entropy must come from the OS CSPRNG. Never `Random()`, never a
  /// seeded PRNG — `02-security/SECURITY-ARCHITECTURE.md` §2 calls that the
  /// single most common fatal mistake in amateur cryptography, and here it
  /// would make every recovery phrase we ever issue guessable.
  static List<String> fromEntropy(Uint8List entropy) {
    if (entropy.length != 16 && entropy.length != 32) {
      throw ArgumentError.value(
        entropy.length,
        'entropy.length',
        'must be 16 bytes (12 words) or 32 bytes (24 words)',
      );
    }

    // BIP-39: append the first (bits/32) bits of SHA-256(entropy) as a
    // checksum, then read the result 11 bits at a time. 11 bits indexes a
    // 2048-word list exactly, which is why the list is that length.
    final checksumBitCount = (entropy.length * 8) ~/ 32;
    final digest = sha256.convert(entropy).bytes;

    final bits = StringBuffer();
    for (final byte in entropy) {
      bits.write(byte.toRadixString(2).padLeft(8, '0'));
    }
    bits.write(
      digest[0].toRadixString(2).padLeft(8, '0').substring(0, checksumBitCount),
    );

    final allBits = bits.toString();
    final words = <String>[];
    for (var i = 0; i < allBits.length; i += 11) {
      words.add(bip39EnglishWordlist[int.parse(allBits.substring(i, i + 11), radix: 2)]);
    }
    return words;
  }

  /// Decodes a recovery phrase back to the entropy it carries.
  ///
  /// Throws [MnemonicException] if the phrase is not valid. Callers must treat
  /// that as "this phrase is wrong", never as "try it anyway" — a phrase that
  /// fails its checksum is a mistyped or misremembered phrase, and proceeding
  /// with the wrong entropy would produce a wrong key and a confusing failure
  /// several layers away from the real cause.
  static Uint8List toEntropy(List<String> words) {
    if (words.length != 12 && words.length != 24) {
      throw MnemonicException(
        'A recovery phrase is 12 words. This one has ${words.length}.',
          problem: MnemonicProblem.wrongLength,
          detail: '${words.length}',
      );
    }

    final bits = StringBuffer();
    for (final raw in words) {
      final word = raw.trim().toLowerCase();
      final index = bip39EnglishWordlist.indexOf(word);
      if (index == -1) {
        throw MnemonicException('"$raw" is not one of the recovery words.',
            problem: MnemonicProblem.notARecoveryWord,
            detail: raw);
      }
      bits.write(index.toRadixString(2).padLeft(11, '0'));
    }

    final allBits = bits.toString();
    final checksumBitCount = allBits.length ~/ 33;
    final entropyBitCount = allBits.length - checksumBitCount;

    final entropy = Uint8List(entropyBitCount ~/ 8);
    for (var i = 0; i < entropy.length; i++) {
      entropy[i] = int.parse(allBits.substring(i * 8, i * 8 + 8), radix: 2);
    }

    // Recompute the checksum. This is what catches a single mistyped or
    // swapped word, which is the realistic failure when someone is reading
    // their own handwriting back years later.
    final expected = sha256
        .convert(entropy)
        .bytes[0]
        .toRadixString(2)
        .padLeft(8, '0')
        .substring(0, checksumBitCount);
    if (allBits.substring(entropyBitCount) != expected) {
      throw MnemonicException(
        'Those words are not a valid recovery phrase. Check for a mistyped or '
        'swapped word.',
        problem: MnemonicProblem.doesNotCheckOut,
      );
    }

    return entropy;
  }

  /// Whether a phrase is valid, without throwing. For live UI feedback.
  static bool isValid(List<String> words) {
    try {
      toEntropy(words);
      return true;
    } on MnemonicException {
      return false;
    }
  }
}

/// Why a recovery phrase could not be read. **ROUND FIFTEEN.**
///
/// Same argument as `BackupProblem` in `core/backup/vault_file.dart`: this is
/// thrown from `core/`, where there is no `BuildContext`, and it is read by
/// somebody trying to get back into their own journal.
enum MnemonicProblem {
  /// [MnemonicException.detail] is how many words were given.
  wrongLength,

  /// [MnemonicException.detail] is the word that is not in the list.
  notARecoveryWord,

  /// Twelve real words, in an order that does not check out.
  doesNotCheckOut,
}

/// A recovery phrase that could not be decoded.
///
/// The message is written to be shown to a person: `08-design/ACCESSIBILITY.md`
/// requires errors that say what happened and what to do next, in plain words —
/// "Those words are not a valid recovery phrase", never "checksum mismatch".
///
/// **Round fifteen** gave it a key as well, so that sentence can be said in the
/// reader's language rather than only in English. See [MnemonicProblem].
class MnemonicException implements Exception, PlainlySaid, Localisable {
  const MnemonicException(this.message, {this.problem, this.detail});

  final String message;

  /// What went wrong, for a screen that can translate it.
  final MnemonicProblem? problem;

  /// A count, or the offending word. Never translated.
  final String? detail;

  @override
  String get plainMessage => message;

  @override
  String describeIn(L l) => switch (problem) {
        null => message,
        MnemonicProblem.wrongLength => l.phraseWrongLength(detail ?? ''),
        MnemonicProblem.notARecoveryWord =>
          l.phraseNotARecoveryWord(detail ?? ''),
        MnemonicProblem.doesNotCheckOut => l.phraseDoesNotCheckOut,
      };

  @override
  String toString() => message;
}
