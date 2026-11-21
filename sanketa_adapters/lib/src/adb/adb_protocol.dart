/// ADB wire protocol over TCP.
///
/// Each ADB message is a 24-byte header followed by an optional payload.
/// Header: command(4 LE) + arg0(4 LE) + arg1(4 LE) +
///         data_length(4 LE) + data_checksum(4 LE) + magic(4 LE)
///
/// The "checksum" is NOT CRC-32 — it is the sum of all payload bytes.
/// The "magic" field is command XOR 0xFFFFFFFF.
library;

import 'dart:convert';
import 'dart:typed_data';

// ADB command constants (little-endian encoded ASCII).
const int adbCnxn = 0x4e584e43; // CNXN
const int adbAuth = 0x48545541; // AUTH
const int adbOpen = 0x4e45504f; // OPEN
const int adbOkay = 0x59414b4f; // OKAY
const int adbClse = 0x45534c43; // CLSE
const int adbWrte = 0x45545257; // WRTE

// AUTH sub-types.
const int authToken = 1;
const int authSignature = 2;
const int authRsaPublicKey = 3;

// Protocol version and limits.
const int adbProtocolVersion = 0x01000000;
const int adbMaxData = 256 * 1024; // 256 KiB for modern ADB
const int adbHeaderSize = 24;

class AdbMessage {
  const AdbMessage({
    required this.command,
    required this.arg0,
    required this.arg1,
    required this.data,
  });

  final int command;
  final int arg0;
  final int arg1;
  final Uint8List data;

  String get commandName {
    switch (command) {
      case adbCnxn:
        return 'CNXN';
      case adbAuth:
        return 'AUTH';
      case adbOpen:
        return 'OPEN';
      case adbOkay:
        return 'OKAY';
      case adbClse:
        return 'CLSE';
      case adbWrte:
        return 'WRTE';
      default:
        return '0x${command.toRadixString(16)}';
    }
  }

  String get dataAsString => utf8.decode(data, allowMalformed: true);

  Uint8List encode() {
    final header = ByteData(adbHeaderSize);
    final checksum = _checksum(data);
    header.setUint32(0, command, Endian.little);
    header.setUint32(4, arg0, Endian.little);
    header.setUint32(8, arg1, Endian.little);
    header.setUint32(12, data.length, Endian.little);
    header.setUint32(16, checksum, Endian.little);
    header.setUint32(20, command ^ 0xFFFFFFFF, Endian.little);
    if (data.isEmpty) return header.buffer.asUint8List();
    final out = Uint8List(adbHeaderSize + data.length);
    out.setRange(0, adbHeaderSize, header.buffer.asUint8List());
    out.setRange(adbHeaderSize, out.length, data);
    return out;
  }

  static AdbMessage? decodeHeader(Uint8List headerBytes) {
    if (headerBytes.length < adbHeaderSize) return null;
    final bd = ByteData.sublistView(headerBytes);
    final cmd = bd.getUint32(0, Endian.little);
    final a0 = bd.getUint32(4, Endian.little);
    final a1 = bd.getUint32(8, Endian.little);
    final dataLen = bd.getUint32(12, Endian.little);
    final magic = bd.getUint32(20, Endian.little);
    if (cmd ^ magic != 0xFFFFFFFF) return null;
    if (dataLen > adbMaxData) return null;
    return AdbMessage(
      command: cmd,
      arg0: a0,
      arg1: a1,
      data: Uint8List(dataLen),
    );
  }

  static int _checksum(Uint8List data) {
    var sum = 0;
    for (final b in data) {
      sum += b;
    }
    return sum & 0xFFFFFFFF;
  }
}

AdbMessage buildCnxn({String systemId = 'host::sanketa\x00'}) {
  return AdbMessage(
    command: adbCnxn,
    arg0: adbProtocolVersion,
    arg1: adbMaxData,
    data: Uint8List.fromList(utf8.encode(systemId)),
  );
}

AdbMessage buildOpen(int localId, String destination) {
  return AdbMessage(
    command: adbOpen,
    arg0: localId,
    arg1: 0,
    data: Uint8List.fromList(utf8.encode('$destination\x00')),
  );
}

AdbMessage buildWrite(int localId, int remoteId, Uint8List payload) {
  return AdbMessage(
    command: adbWrte,
    arg0: localId,
    arg1: remoteId,
    data: payload,
  );
}

AdbMessage buildOkay(int localId, int remoteId) {
  return AdbMessage(
    command: adbOkay,
    arg0: localId,
    arg1: remoteId,
    data: Uint8List(0),
  );
}

AdbMessage buildClose(int localId, int remoteId) {
  return AdbMessage(
    command: adbClse,
    arg0: localId,
    arg1: remoteId,
    data: Uint8List(0),
  );
}

AdbMessage buildAuthSignature(Uint8List signature) {
  return AdbMessage(
    command: adbAuth,
    arg0: authSignature,
    arg1: 0,
    data: signature,
  );
}

AdbMessage buildAuthPublicKey(Uint8List publicKeyData) {
  return AdbMessage(
    command: adbAuth,
    arg0: authRsaPublicKey,
    arg1: 0,
    data: publicKeyData,
  );
}
