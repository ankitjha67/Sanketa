/// Hand-coded CastMessage protobuf codec for the Google Cast V2 protocol.
///
/// CastV2 frames are: 4-byte big-endian length + CastMessage protobuf.
/// Only the fields needed for media casting are implemented — no protoc
/// dependency.
library;

import 'dart:convert';
import 'dart:typed_data';

class CastMessage {
  CastMessage({
    required this.sourceId,
    required this.destinationId,
    required this.namespace,
    required this.payloadUtf8,
  });

  final String sourceId;
  final String destinationId;
  final String namespace;
  final String payloadUtf8;

  Uint8List encode() {
    final buf = BytesBuilder(copy: false);
    _writeVarint(buf, 1, 0); // protocol_version = CASTV2_1_0
    _writeString(buf, 2, sourceId);
    _writeString(buf, 3, destinationId);
    _writeString(buf, 4, namespace);
    _writeVarint(buf, 5, 0); // payload_type = STRING
    _writeString(buf, 6, payloadUtf8);
    return buf.toBytes();
  }

  static CastMessage decode(Uint8List data) {
    String sourceId = '';
    String destinationId = '';
    String namespace = '';
    String payloadUtf8 = '';

    int pos = 0;
    while (pos < data.length) {
      final (tag, newPos) = _readVarint(data, pos);
      pos = newPos;
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      if (wireType == 0) {
        // varint — skip it
        final (_, p) = _readVarint(data, pos);
        pos = p;
      } else if (wireType == 2) {
        final (len, p1) = _readVarint(data, pos);
        pos = p1;
        final bytes = data.sublist(pos, pos + len);
        pos += len;
        switch (fieldNumber) {
          case 2:
            sourceId = utf8.decode(bytes);
          case 3:
            destinationId = utf8.decode(bytes);
          case 4:
            namespace = utf8.decode(bytes);
          case 6:
            payloadUtf8 = utf8.decode(bytes);
        }
      }
    }

    return CastMessage(
      sourceId: sourceId,
      destinationId: destinationId,
      namespace: namespace,
      payloadUtf8: payloadUtf8,
    );
  }

  static void _writeVarint(BytesBuilder buf, int fieldNumber, int value) {
    final tag = (fieldNumber << 3) | 0;
    buf.add(_encodeVarint(tag));
    buf.add(_encodeVarint(value));
  }

  static void _writeString(BytesBuilder buf, int fieldNumber, String value) {
    final bytes = utf8.encode(value);
    final tag = (fieldNumber << 3) | 2;
    buf.add(_encodeVarint(tag));
    buf.add(_encodeVarint(bytes.length));
    buf.add(bytes);
  }

  static Uint8List _encodeVarint(int value) {
    final result = <int>[];
    var v = value;
    while (v > 0x7F) {
      result.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    result.add(v & 0x7F);
    return Uint8List.fromList(result);
  }

  static (int value, int newPos) _readVarint(Uint8List data, int pos) {
    int value = 0;
    int shift = 0;
    while (pos < data.length) {
      final byte = data[pos++];
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return (value, pos);
  }
}

/// Frame a CastMessage with the 4-byte big-endian length prefix.
Uint8List frameCastMessage(CastMessage msg) {
  final payload = msg.encode();
  final frame = Uint8List(4 + payload.length);
  final view = ByteData.sublistView(frame);
  view.setUint32(0, payload.length, Endian.big);
  frame.setRange(4, frame.length, payload);
  return frame;
}

/// Read one framed CastMessage from a buffer. Returns the message and the
/// number of bytes consumed, or null if the buffer is incomplete.
(CastMessage msg, int consumed)? readFramedMessage(Uint8List buffer) {
  if (buffer.length < 4) return null;
  final view = ByteData.sublistView(buffer);
  final len = view.getUint32(0, Endian.big);
  if (buffer.length < 4 + len) return null;
  final payload = buffer.sublist(4, 4 + len);
  return (CastMessage.decode(payload), 4 + len);
}
