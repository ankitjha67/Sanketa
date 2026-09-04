/// Length-delimited message framing for the Android TV remote stream.
///
/// Messages on the wire are each prefixed with a varint length (protobuf
/// "delimited" convention). [frameMessage] adds the prefix; [MessageDeframer]
/// reassembles messages from arbitrary TCP chunk boundaries. Both are pure and
/// fully tested; if Phase 0 shows the real prefix differs (e.g. a fixed byte),
/// only this file changes.
library;

import 'dart:typed_data';

/// Prefix [body] with its varint length.
Uint8List frameMessage(List<int> body) {
  final b = BytesBuilder();
  _writeVarint(b, body.length);
  b.add(body);
  return b.toBytes();
}

void _writeVarint(BytesBuilder b, int value) {
  var v = value;
  while (true) {
    final byte = v & 0x7f;
    v >>= 7;
    if (v != 0) {
      b.addByte(byte | 0x80);
    } else {
      b.addByte(byte);
      break;
    }
  }
}

/// Accumulates TCP bytes and yields complete message bodies as they arrive.
class MessageDeframer {
  final List<int> _buf = [];

  void addChunk(List<int> chunk) => _buf.addAll(chunk);

  /// Return every complete message currently buffered, consuming them.
  List<Uint8List> drain() {
    final out = <Uint8List>[];
    while (true) {
      final header = _tryReadVarint(_buf);
      if (header == null) break; // length prefix not fully arrived
      final (length, headerLen) = header;
      if (_buf.length < headerLen + length) break; // body not fully arrived
      out.add(Uint8List.fromList(_buf.sublist(headerLen, headerLen + length)));
      _buf.removeRange(0, headerLen + length);
    }
    return out;
  }
}

/// Try to read a varint from the front of [buf]; returns (value, bytesConsumed)
/// or null if the varint is not yet complete.
(int, int)? _tryReadVarint(List<int> buf) {
  var shift = 0;
  var result = 0;
  var i = 0;
  while (i < buf.length) {
    final b = buf[i];
    result |= (b & 0x7f) << shift;
    i++;
    if ((b & 0x80) == 0) return (result, i);
    shift += 7;
    if (shift > 63) throw const FormatException('varint too long');
  }
  return null;
}
