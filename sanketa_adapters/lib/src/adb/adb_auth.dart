/// ADB RSA key persistence — load/save RSA 2048 key pairs to the app's
/// support directory so the TV doesn't re-prompt on every app restart.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class AdbKeyStore {
  AdbKeyStore({required this.keyDir});

  final Directory keyDir;

  Future<bool> get hasKeys async {
    final f = File('${keyDir.path}/adb_key');
    return f.existsSync();
  }

  Future<void> saveKeys(RSAPublicKey pub, RSAPrivateKey priv) async {
    await keyDir.create(recursive: true);
    final privDer = _encodePrivateKeyDer(priv);
    final pubDer = _encodePublicKeyDer(pub);
    await File('${keyDir.path}/adb_key')
        .writeAsString(_derToPem(privDer, 'RSA PRIVATE KEY'));
    await File('${keyDir.path}/adb_key.pub')
        .writeAsString(_derToPem(pubDer, 'PUBLIC KEY'));
  }

  Future<(RSAPublicKey, RSAPrivateKey)?> loadKeys() async {
    final privFile = File('${keyDir.path}/adb_key');
    final pubFile = File('${keyDir.path}/adb_key.pub');
    if (!privFile.existsSync() || !pubFile.existsSync()) return null;

    try {
      final privDer = _pemToDer(await privFile.readAsString());
      final pubDer = _pemToDer(await pubFile.readAsString());
      return (_decodePublicKey(pubDer), _decodePrivateKey(privDer));
    } on Object {
      return null;
    }
  }

  // -- DER encoding (PKCS#1) --------------------------------------------------

  static Uint8List _encodePublicKeyDer(RSAPublicKey pub) => _derSequence([
        _derInteger(pub.modulus!),
        _derInteger(pub.exponent!),
      ]);

  static Uint8List _encodePrivateKeyDer(RSAPrivateKey priv) => _derSequence([
        _derIntegerSmall(0),
        _derInteger(priv.modulus!),
        _derInteger(priv.publicExponent!),
        _derInteger(priv.privateExponent!),
        _derInteger(priv.p!),
        _derInteger(priv.q!),
        _derInteger(priv.privateExponent! % (priv.p! - BigInt.one)),
        _derInteger(priv.privateExponent! % (priv.q! - BigInt.one)),
        _derInteger(priv.q!.modInverse(priv.p!)),
      ]);

  // -- DER decoding -----------------------------------------------------------

  static RSAPublicKey _decodePublicKey(Uint8List der) {
    final parsed = _parseDerSequence(der);
    return RSAPublicKey(
      _parseDerInteger(parsed[0]),
      _parseDerInteger(parsed[1]),
    );
  }

  static RSAPrivateKey _decodePrivateKey(Uint8List der) {
    final parsed = _parseDerSequence(der);
    return RSAPrivateKey(
      _parseDerInteger(parsed[1]),
      _parseDerInteger(parsed[3]),
      _parseDerInteger(parsed[4]),
      _parseDerInteger(parsed[5]),
    );
  }

  static List<Uint8List> _parseDerSequence(Uint8List data) {
    if (data[0] != 0x30) throw const FormatException('Not a SEQUENCE');
    final (_, hdrEnd) = _readLen(data, 1);
    final items = <Uint8List>[];
    var offset = hdrEnd;
    while (offset < data.length) {
      final (len, contentStart) = _readLen(data, offset + 1);
      final end = contentStart + len;
      items.add(Uint8List.sublistView(data, offset, end));
      offset = end;
    }
    return items;
  }

  static BigInt _parseDerInteger(Uint8List data) {
    if (data[0] != 0x02) throw const FormatException('Not an INTEGER');
    final (len, start) = _readLen(data, 1);
    final bytes = Uint8List.sublistView(data, start, start + len);
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  static (int, int) _readLen(Uint8List data, int offset) {
    final first = data[offset];
    if (first < 0x80) return (first, offset + 1);
    final numBytes = first & 0x7f;
    var length = 0;
    for (var i = 0; i < numBytes; i++) {
      length = (length << 8) | data[offset + 1 + i];
    }
    return (length, offset + 1 + numBytes);
  }

  // -- ASN.1 DER primitives ---------------------------------------------------

  static Uint8List _derTag(int tag, Uint8List content) {
    final len = _derLenBytes(content.length);
    return (BytesBuilder()
          ..addByte(tag)
          ..add(len)
          ..add(content))
        .toBytes();
  }

  static Uint8List _derLenBytes(int length) {
    if (length < 0x80) return Uint8List.fromList([length]);
    final bytes = <int>[];
    var l = length;
    while (l > 0) {
      bytes.insert(0, l & 0xff);
      l >>= 8;
    }
    return Uint8List.fromList([0x80 | bytes.length, ...bytes]);
  }

  static Uint8List _derSequence(List<Uint8List> items) {
    final body = BytesBuilder();
    for (final i in items) {
      body.add(i);
    }
    return _derTag(0x30, body.toBytes());
  }

  static Uint8List _derInteger(BigInt value) {
    var bytes = _bigIntToBytes(value);
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
      bytes = Uint8List.fromList([0, ...bytes]);
    }
    return _derTag(0x02, bytes);
  }

  static Uint8List _derIntegerSmall(int value) =>
      _derInteger(BigInt.from(value));

  // -- PEM <-> DER ------------------------------------------------------------

  static Uint8List _pemToDer(String pem) {
    final lines =
        pem.split('\n').where((l) => !l.startsWith('-----')).join();
    return base64.decode(lines);
  }

  static String _derToPem(Uint8List der, String label) {
    final b64 = base64.encode(der);
    final lines = <String>['-----BEGIN $label-----'];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    lines.add('-----END $label-----');
    return lines.join('\n');
  }

  static Uint8List _bigIntToBytes(BigInt n) {
    if (n == BigInt.zero) return Uint8List.fromList([0]);
    final byteLen = (n.bitLength + 7) >> 3;
    final result = Uint8List(byteLen);
    var temp = n;
    for (var i = byteLen - 1; i >= 0; i--) {
      result[i] = (temp & BigInt.from(0xff)).toInt();
      temp >>= 8;
    }
    return result;
  }
}
