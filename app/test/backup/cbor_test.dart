import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/cbor.dart';

/// The CBOR codec, against RFC 8949's own examples.
///
/// This is the same argument `mnemonic_test.dart` makes for BIP-39: a small
/// implementation of a frozen standard is only worth having if it is proved
/// against the standard's vectors rather than against itself. A codec tested
/// only by round-tripping its own output will happily agree with itself while
/// producing bytes nobody else can read — which would quietly break the promise
/// that someone can write their own decryptor in 2040.
void main() {
  Uint8List hex(String s) => Uint8List.fromList([
        for (var i = 0; i < s.length; i += 2)
          int.parse(s.substring(i, i + 2), radix: 16),
      ]);

  group('RFC 8949 appendix A vectors', () {
    // value → the exact bytes the specification says it encodes to.
    final vectors = <Object?, String>{
      0: '00',
      1: '01',
      10: '0a',
      23: '17',
      24: '1818',
      25: '1819',
      100: '1864',
      1000: '1903e8',
      1000000: '1a000f4240',
      1000000000000: '1b000000e8d4a51000',
      false: 'f4',
      true: 'f5',
      null: 'f6',
      '': '60',
      'a': '6161',
      'IETF': '6449455446',
      '"\\': '62225c',
      <Object?>[]: '80',
      <Object?>[1, 2, 3]: '83010203',
      <String, Object?>{}: 'a0',
    };

    vectors.forEach((value, expected) {
      test('$value encodes to $expected', () {
        expect(Cbor.encode(value), equals(hex(expected)));
      });

      test('$expected decodes back to $value', () {
        expect(Cbor.decode(hex(expected)), equals(value));
      });
    });

    test('byte strings carry their length', () {
      // 0x44 = major 2, length 4.
      expect(
        Cbor.encode(Uint8List.fromList([1, 2, 3, 4])),
        equals(hex('4401020304')),
      );
    });

    test('a nested map matches the specification example', () {
      // {"a": 1, "b": [2, 3]}
      expect(
        Cbor.encode(<String, Object?>{
          'a': 1,
          'b': <Object?>[2, 3],
        }),
        equals(hex('a26161016162820203')),
      );
    });
  });

  group('deterministic encoding', () {
    test('map keys are sorted, whatever order they were inserted in', () {
      // Not cosmetic. The header bytes are the authenticated associated data on
      // the wrapped key, so the same header has to encode to the same bytes
      // every time or the file cannot be opened by the app that wrote it.
      final a = Cbor.encode(<String, Object?>{'z': 1, 'a': 2, 'm': 3});
      final b = Cbor.encode(<String, Object?>{'a': 2, 'm': 3, 'z': 1});
      expect(a, equals(b));
      expect(Cbor.decode(a), equals({'a': 2, 'm': 3, 'z': 1}));
    });

    test('integers use the shortest form that fits', () {
      expect(Cbor.encode(23), hasLength(1));
      expect(Cbor.encode(24), hasLength(2));
      expect(Cbor.encode(256), hasLength(3));
      expect(Cbor.encode(65536), hasLength(5));
      expect(Cbor.encode(0x100000000), hasLength(9));
    });
  });

  group('round trips', () {
    test('a realistic backup header survives intact', () {
      final header = <String, Object?>{
        'format_version': 1,
        'kdf': 'argon2id',
        'kdf_salt': Uint8List.fromList(List.generate(16, (i) => i * 7 % 256)),
        'kdf_memory_kib': 262144,
        'kdf_iterations': 4,
        'kdf_parallelism': 1,
        'cipher': 'xchacha20poly1305',
        'chunk_size': 65536,
        'compression': 'gzip',
        'created_at': '2026-08-18T19:00:00.000Z',
        'app_version': '0.1.0',
        'backup_id': 'f81d4fae-7dec-41d0-a765-00a0c91e6bf6',
      };
      final decoded = Cbor.decode(Cbor.encode(header))! as Map<String, Object?>;
      expect(decoded['format_version'], 1);
      expect(decoded['kdf_salt'], equals(header['kdf_salt']));
      expect(decoded['chunk_size'], 65536);
      expect(decoded['backup_id'], header['backup_id']);
    });

    test('a manifest with per-member hashes survives intact', () {
      final manifest = <String, Object?>{
        'entry_count': 3847,
        'day_count': 892,
        'members': <Object?>[
          <String, Object?>{
            'name': 'vault.db',
            'size': 1234567,
            'hash': Uint8List.fromList(List.filled(32, 0xAB)),
          },
        ],
      };
      final decoded =
          Cbor.decode(Cbor.encode(manifest))! as Map<String, Object?>;
      final members = (decoded['members']! as List).cast<Map<String, Object?>>();
      expect(members.single['name'], 'vault.db');
      expect(members.single['hash'], hasLength(32));
    });

    test('text survives characters outside ASCII', () {
      const name = 'Dr. Mehta — therapy · ২০২৬';
      expect(Cbor.decode(Cbor.encode(name)), name);
      expect(Cbor.encode(name), hasLength(1 + utf8.encode(name).length + 1));
    });
  });

  group('what it refuses', () {
    test('trailing bytes are an error, not something to ignore', () {
      // In a file format, bytes after the item you expected are either
      // corruption or someone hiding something.
      expect(
        () => Cbor.decode(Uint8List.fromList([0x01, 0xFF])),
        throwsA(isA<CborError>()),
      );
    });

    test('a truncated item is an error rather than a partial value', () {
      expect(
        () => Cbor.decode(hex('6449455446'.substring(0, 6))),
        throwsA(isA<CborError>()),
      );
    });

    test('indefinite-length items are refused', () {
      // 0x5F starts an indefinite-length byte string. Supported by CBOR,
      // deliberately not by us — a decoder that accepts less has less to get
      // wrong, and nothing this format writes uses them.
      expect(
        () => Cbor.decode(hex('5f42010243030405ff')),
        throwsA(isA<CborError>()),
      );
    });

    test('non-text map keys are refused', () {
      // {1: 2} — legal CBOR, never produced here.
      expect(
        () => Cbor.decode(hex('a10102')),
        throwsA(isA<CborError>()),
      );
    });

    test('negative integers are refused on the way in', () {
      expect(() => Cbor.encode(-1), throwsA(isA<CborError>()));
    });

    test('a type it cannot encode throws rather than guessing', () {
      expect(() => Cbor.encode(DateTime.now()), throwsA(isA<CborError>()));
      expect(() => Cbor.encode(1.5), throwsA(isA<CborError>()));
    });
  });
}
