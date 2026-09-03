import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/mnemonic.dart';
import 'package:lamplight/core/crypto/wordlist_english.dart';

/// The official BIP-39 English test vectors, from the specification's own
/// `vectors.json`. Asserting against these is the entire justification for
/// implementing BIP-39 ourselves instead of taking a dependency: correctness
/// here is checkable against an external authority rather than against our own
/// opinion of our own code.
///
/// The all-zeroes and all-ones entropies matter most. Those are the cases where
/// a bit-shifting or padding mistake is invisible in the middle of the range
/// and obvious at the edges.
void main() {
  Uint8List hex(String s) => Uint8List.fromList([
        for (var i = 0; i < s.length; i += 2)
          int.parse(s.substring(i, i + 2), radix: 16),
      ]);

  group('the wordlist itself', () {
    test('is exactly 2048 words', () {
      // 11 bits per word indexes 2048 entries exactly. Any other length and
      // the encoding is silently wrong for every phrase ever issued.
      expect(bip39EnglishWordlist, hasLength(2048));
    });

    test('has no duplicates and is in the published order', () {
      expect(bip39EnglishWordlist.toSet(), hasLength(2048));
      expect(bip39EnglishWordlist.first, 'abandon');
      expect(bip39EnglishWordlist.last, 'zoo');
      // Order is data, not presentation: sorted order IS the published order.
      final sorted = [...bip39EnglishWordlist]..sort();
      expect(bip39EnglishWordlist, equals(sorted));
    });

    test('four letters are enough to identify any word', () {
      // The property that makes a phrase survive bad handwriting: nobody has
      // to read past the fourth letter. Words shorter than four letters
      // identify themselves, so the prefix is min(4, length) — taking a fixed
      // four would crash on 'act', 'zoo' and the other three-letter words.
      final prefixes = bip39EnglishWordlist
          .map((w) => w.length <= 4 ? w : w.substring(0, 4))
          .toSet();
      expect(prefixes, hasLength(2048));
    });
  });

  group('official BIP-39 vectors — 128 bits, 12 words', () {
    const vectors = <String, String>{
      '00000000000000000000000000000000':
          'abandon abandon abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon about',
      '7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f':
          'legal winner thank year wave sausage worth useful legal winner '
              'thank yellow',
      '80808080808080808080808080808080':
          'letter advice cage absurd amount doctor acoustic avoid letter '
              'advice cage above',
      'ffffffffffffffffffffffffffffffff':
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong',
      '9e885d952ad362caeb4efe34a8e91bd2':
          'ozone drill grab fiber curtain grace pudding thank cruise elder '
              'eight picnic',
      '77c2b00716cec7213839159e404db50d':
          'jelly better achieve collect unaware mountain thought cargo oxygen '
              'act hood bridge',
      'c0ba5a8e914111210f2bd131f3d5e08d':
          'scheme spot photo card baby mountain device kick cradle pact join '
              'borrow',
    };

    vectors.forEach((entropyHex, phrase) {
      test('$entropyHex encodes correctly', () {
        expect(Mnemonic.fromEntropy(hex(entropyHex)).join(' '), phrase);
      });

      test('$entropyHex decodes back', () {
        expect(Mnemonic.toEntropy(phrase.split(' ')), equals(hex(entropyHex)));
      });
    });
  });

  group('official BIP-39 vectors — 256 bits, 24 words', () {
    const vectors = <String, String>{
      '0000000000000000000000000000000000000000000000000000000000000000':
          'abandon abandon abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon abandon abandon abandon abandon art',
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff':
          'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo '
              'zoo zoo zoo zoo zoo zoo vote',
    };

    vectors.forEach((entropyHex, phrase) {
      test('${entropyHex.substring(0, 8)}… round-trips', () {
        expect(Mnemonic.fromEntropy(hex(entropyHex)).join(' '), phrase);
        expect(Mnemonic.toEntropy(phrase.split(' ')), equals(hex(entropyHex)));
      });
    });
  });

  group('rejecting bad input', () {
    const good = 'ozone drill grab fiber curtain grace pudding thank cruise '
        'elder eight picnic';

    test('a swapped word is caught by the checksum', () {
      // The realistic failure: someone reads their own handwriting back wrong.
      // Swapping two words keeps every word valid but breaks the checksum.
      final words = good.split(' ');
      final swapped = [...words];
      swapped[0] = words[1];
      swapped[1] = words[0];
      expect(() => Mnemonic.toEntropy(swapped), throwsA(isA<MnemonicException>()));
      expect(Mnemonic.isValid(swapped), isFalse);
    });

    test('a word not in the list is rejected by name', () {
      final words = good.split(' ')..[3] = 'lamplight';
      expect(
        () => Mnemonic.toEntropy(words),
        throwsA(
          isA<MnemonicException>().having(
            (e) => e.message,
            'message',
            contains('lamplight'),
          ),
        ),
      );
    });

    test('the wrong number of words is rejected', () {
      expect(
        () => Mnemonic.toEntropy(good.split(' ').take(11).toList()),
        throwsA(isA<MnemonicException>()),
      );
    });

    test('case and stray whitespace are tolerated', () {
      // People write on paper and type it back. Being strict about capitals
      // would lock someone out of their own vault over a shift key.
      final messy = good.split(' ').map((w) => '  ${w.toUpperCase()} ').toList();
      expect(Mnemonic.toEntropy(messy), equals(Mnemonic.toEntropy(good.split(' '))));
    });

    test('entropy of the wrong size is refused', () {
      expect(() => Mnemonic.fromEntropy(Uint8List(15)), throwsArgumentError);
      expect(() => Mnemonic.fromEntropy(Uint8List(0)), throwsArgumentError);
    });
  });

  test('a valid phrase round-trips for every byte value', () {
    // Sweep each byte position through 0..255 rather than trusting the fixed
    // vectors to have covered the arithmetic.
    for (var value = 0; value < 256; value++) {
      final entropy = Uint8List(16)..fillRange(0, 16, value);
      final words = Mnemonic.fromEntropy(entropy);
      expect(words, hasLength(12));
      expect(Mnemonic.toEntropy(words), equals(entropy), reason: 'byte $value');
    }
  });
}
