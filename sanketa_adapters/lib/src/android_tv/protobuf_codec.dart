/// A minimal, correct protobuf wire codec.
///
/// The Android TV remote protocol v2 speaks length-delimited protobuf over TLS.
/// Rather than pull in a full protobuf toolchain (protoc codegen), this hand-
/// rolls just the wire primitives the adapter needs. The wire format is a stable
/// spec, so this layer is provably correct — the tests assert protobuf's own
/// canonical byte vectors (field 1 = 150 → `08 96 01`, etc.). The *schema*
/// (which field number means what) lives one layer up and is validated on a real
/// device in Phase 0; this codec is agnostic to it.
///
/// Only unsigned varints, length-delimited fields, and nested messages are
/// implemented — that is all the protocol's key/text/pairing messages use.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Protobuf wire types.
class WireType {
  static const int varint = 0;
  static const int lengthDelimited = 2;
  static const int fixed64 = 1;
  static const int fixed32 = 5;
}

/// Builds a protobuf message body.
class ProtoWriter {
  final BytesBuilder _b = BytesBuilder();

  void _varint(int value) {
    assert(value >= 0, 'only unsigned varints are supported');
    var v = value;
    while (true) {
      final byte = v & 0x7f;
      v >>= 7;
      if (v != 0) {
        _b.addByte(byte | 0x80);
      } else {
        _b.addByte(byte);
        break;
      }
    }
  }

  void _tag(int field, int wire) => _varint((field << 3) | wire);

  /// A varint field (int/uint/enum/bool).
  void writeUint(int field, int value) {
    _tag(field, WireType.varint);
    _varint(value);
  }

  void writeBool(int field, {required bool value}) =>
      writeUint(field, value ? 1 : 0);

  /// A length-delimited bytes field.
  void writeBytes(int field, List<int> value) {
    _tag(field, WireType.lengthDelimited);
    _varint(value.length);
    _b.add(value);
  }

  /// A length-delimited UTF-8 string field.
  void writeString(int field, String value) =>
      writeBytes(field, utf8.encode(value));

  /// A nested message field.
  void writeMessage(int field, ProtoWriter message) =>
      writeBytes(field, message.toBytes());

  Uint8List toBytes() => _b.toBytes();
}

/// A single decoded field header.
class ProtoField {
  const ProtoField(this.number, this.wireType);
  final int number;
  final int wireType;
}

/// Reads a protobuf message body.
class ProtoReader {
  ProtoReader(this._bytes);
  final List<int> _bytes;
  int _pos = 0;

  bool get hasMore => _pos < _bytes.length;

  int _varint() {
    var shift = 0;
    var result = 0;
    while (_pos < _bytes.length) {
      final b = _bytes[_pos++];
      result |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) return result;
      shift += 7;
      if (shift > 63) throw const FormatException('varint too long');
    }
    throw const FormatException('truncated varint');
  }

  ProtoField readTag() {
    final t = _varint();
    return ProtoField(t >> 3, t & 0x7);
  }

  int readVarint() => _varint();

  Uint8List readLengthDelimited() {
    final len = _varint();
    if (_pos + len > _bytes.length) {
      throw const FormatException('truncated length-delimited field');
    }
    final out = Uint8List.fromList(_bytes.sublist(_pos, _pos + len));
    _pos += len;
    return out;
  }

  String readString() => utf8.decode(readLengthDelimited());

  /// Skip a field whose value we do not care about.
  void skip(int wireType) {
    switch (wireType) {
      case WireType.varint:
        _varint();
      case WireType.lengthDelimited:
        final len = _varint();
        _pos += len;
      case WireType.fixed64:
        _pos += 8;
      case WireType.fixed32:
        _pos += 4;
      default:
        throw FormatException('unknown wire type $wireType');
    }
  }
}
