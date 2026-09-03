import 'dart:convert';
import 'dart:typed_data';

/// The small piece of CBOR (RFC 8949) that the backup format needs.
///
/// WHY THIS IS HERE AND NOT A PACKAGE
///
/// `BACKUP-FILE-FORMAT.md` specifies a CBOR header and a CBOR manifest, and it
/// is right to: CBOR is a frozen IETF standard with implementations in every
/// language, which is what makes the promise "someone can write their own
/// decryptor in 2040" true rather than aspirational.
///
/// But `CLAUDE.md` rule 4 says no package without a written justification, and
/// counts a short dependency list as a security property — every package in
/// this app can read all of the user's notes. The parts of CBOR this format
/// uses are five type tags and a length prefix. That is not worth a dependency,
/// and it is the same call the project already made for BIP-39 in
/// `mnemonic.dart`, for the same reason and with the same shape of answer: a
/// small implementation, in the open, tested against the specification's own
/// vectors.
///
/// WHAT IS DELIBERATELY MISSING
///
/// Negative integers, floats, tags, indefinite-length items, and non-text map
/// keys. None appear in this format and none ever will — a decoder that accepts
/// less is a decoder with less to get wrong. Anything unsupported throws
/// [CborError] rather than being skipped, because a backup file containing
/// something we do not understand is a file we must not claim to have read.
///
/// THE ENCODER IS DETERMINISTIC
///
/// Map keys are sorted and every integer uses its shortest form (§4.2.1). That
/// matters here beyond tidiness: the header bytes are the authenticated
/// associated data for the wrapped key, so encoding the same header twice has
/// to produce the same bytes or the file cannot be verified.
abstract final class Cbor {
  // ── Encoding ───────────────────────────────────────────────────────────────

  static Uint8List encode(Object? value) {
    final out = BytesBuilder(copy: false);
    _write(out, value);
    return out.takeBytes();
  }

  static void _write(BytesBuilder out, Object? value) {
    switch (value) {
      case null:
        out.addByte(0xF6); // major 7, simple value 22 = null
      case bool b:
        out.addByte(b ? 0xF5 : 0xF4);
      case int i:
        if (i < 0) {
          throw CborError('negative integers are not used by this format');
        }
        _head(out, 0, i);
      case Uint8List b:
        _head(out, 2, b.length);
        out.add(b);
      case String s:
        final bytes = utf8.encode(s);
        _head(out, 3, bytes.length);
        out.add(bytes);
      case List<Object?> list:
        _head(out, 4, list.length);
        for (final item in list) {
          _write(out, item);
        }
      case Map<String, Object?> map:
        _head(out, 5, map.length);
        // Sorted, so the same map always encodes to the same bytes. Without
        // this the header's authentication tag would depend on the order a
        // Dart map happened to iterate in.
        final keys = map.keys.toList()..sort();
        for (final k in keys) {
          _write(out, k);
          _write(out, map[k]);
        }
      default:
        throw CborError('cannot encode ${value.runtimeType}');
    }
  }

  /// The type byte and its length or value, in the shortest form that fits.
  static void _head(BytesBuilder out, int major, int value) {
    final m = major << 5;
    if (value < 24) {
      out.addByte(m | value);
    } else if (value < 0x100) {
      out..addByte(m | 24)..addByte(value);
    } else if (value < 0x10000) {
      out
        ..addByte(m | 25)
        ..addByte((value >> 8) & 0xFF)
        ..addByte(value & 0xFF);
    } else if (value < 0x100000000) {
      out
        ..addByte(m | 26)
        ..addByte((value >> 24) & 0xFF)
        ..addByte((value >> 16) & 0xFF)
        ..addByte((value >> 8) & 0xFF)
        ..addByte(value & 0xFF);
    } else {
      out.addByte(m | 27);
      for (var shift = 56; shift >= 0; shift -= 8) {
        out.addByte((value >> shift) & 0xFF);
      }
    }
  }

  // ── Decoding ───────────────────────────────────────────────────────────────

  /// Decodes one item and insists it was the whole input.
  ///
  /// Trailing bytes are an error rather than something to ignore. In a file
  /// format, bytes after the item you expected are either corruption or someone
  /// hiding something, and neither should decode quietly.
  static Object? decode(Uint8List bytes) {
    final reader = _Reader(bytes);
    final value = reader.read();
    if (reader.offset != bytes.length) {
      throw CborError('${bytes.length - reader.offset} unexpected trailing bytes');
    }
    return value;
  }
}

class _Reader {
  _Reader(this.bytes);

  final Uint8List bytes;
  int offset = 0;

  int _byte() {
    if (offset >= bytes.length) throw CborError('ran off the end');
    return bytes[offset++];
  }

  Object? read() {
    final initial = _byte();
    final major = initial >> 5;
    final minor = initial & 0x1F;

    if (major == 7) {
      return switch (minor) {
        20 => false,
        21 => true,
        22 => null,
        _ => throw CborError('unsupported simple value $minor'),
      };
    }

    final length = _length(minor);
    switch (major) {
      case 0:
        return length;
      case 2:
        return _take(length);
      case 3:
        return utf8.decode(_take(length));
      case 4:
        return [for (var i = 0; i < length; i++) read()];
      case 5:
        final map = <String, Object?>{};
        for (var i = 0; i < length; i++) {
          final key = read();
          if (key is! String) {
            throw CborError('map keys must be text, got ${key.runtimeType}');
          }
          map[key] = read();
        }
        return map;
      default:
        throw CborError('unsupported major type $major');
    }
  }

  int _length(int minor) {
    if (minor < 24) return minor;
    switch (minor) {
      case 24:
        return _byte();
      case 25:
        return (_byte() << 8) | _byte();
      case 26:
        var v = 0;
        for (var i = 0; i < 4; i++) {
          v = (v << 8) | _byte();
        }
        return v;
      case 27:
        var v = 0;
        for (var i = 0; i < 8; i++) {
          v = (v << 8) | _byte();
        }
        // Dart ints are 64-bit and signed. A length that came back negative
        // means the file claims something longer than 2^63 bytes, which is a
        // corrupt or hostile file rather than a large one.
        if (v < 0) throw CborError('length out of range');
        return v;
      case 31:
        throw CborError('indefinite-length items are not supported');
      default:
        throw CborError('reserved length encoding $minor');
    }
  }

  Uint8List _take(int n) {
    if (offset + n > bytes.length) throw CborError('ran off the end');
    final view = Uint8List.sublistView(bytes, offset, offset + n);
    offset += n;
    // A copy, so the result does not keep the whole input buffer alive and
    // cannot be changed under the caller.
    return Uint8List.fromList(view);
  }
}

class CborError implements Exception {
  const CborError(this.message);

  final String message;

  @override
  String toString() => 'CborError: $message';
}
