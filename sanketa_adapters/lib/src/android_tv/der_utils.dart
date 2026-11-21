/// Minimal ASN.1/DER utilities for extracting RSA public keys from X.509
/// certificates.
///
/// The ATVRS pairing secret requires the modulus and exponent from both the
/// client and server TLS certificates. This parser extracts just those two
/// fields from a DER-encoded X.509 cert, without pulling in a full ASN.1
/// library.
library;

import 'dart:convert';
import 'dart:typed_data';

class RsaPublicKey {
  const RsaPublicKey({required this.modulus, required this.exponent});
  final Uint8List modulus;
  final Uint8List exponent;
}

/// Extract the RSA public key from a DER-encoded X.509 certificate.
RsaPublicKey rsaPublicKeyFromDer(Uint8List der) {
  final r = _DerReader(der);
  // Certificate ::= SEQUENCE { tbsCert, sigAlg, sig }
  final cert = _DerReader(r.enterSequence());
  // TBSCertificate ::= SEQUENCE { version, serial, sigAlg, issuer,
  //   validity, subject, subjectPublicKeyInfo, [extensions] }
  final tbs = _DerReader(cert.enterSequence());

  if (tbs.peekTag() == 0xa0) tbs.skipTlv(); // version [0] EXPLICIT
  for (var i = 0; i < 5; i++)
    tbs.skipTlv(); // serial, sigAlg, issuer, validity, subject
  // subjectPublicKeyInfo ::= SEQUENCE { algorithm, subjectPublicKey }
  final spki = _DerReader(tbs.enterSequence());
  spki.skipTlv(); // algorithm
  final bits = spki.readBitString();

  // RSAPublicKey ::= SEQUENCE { modulus INTEGER, exponent INTEGER }
  final rsa = _DerReader(_DerReader(bits).enterSequence());
  return RsaPublicKey(
    modulus: rsa.readInteger(),
    exponent: rsa.readInteger(),
  );
}

/// Decode a PEM-encoded certificate or key to its raw DER bytes.
Uint8List pemToDer(String pem) {
  final b64 = pem
      .split('\n')
      .where((l) => !l.startsWith('-----'))
      .join()
      .replaceAll('\r', '');
  return base64.decode(b64);
}

// -- minimal DER reader ------------------------------------------------------

class _DerReader {
  _DerReader(this._bytes);
  final List<int> _bytes;
  int _pos = 0;

  int peekTag() {
    _require(1);
    return _bytes[_pos];
  }

  int _readTag() {
    _require(1);
    return _bytes[_pos++];
  }

  int _readLength() {
    _require(1);
    final first = _bytes[_pos++];
    if (first < 0x80) return first;
    final n = first & 0x7f;
    if (n == 0) {
      throw const FormatException('indefinite DER length is not allowed');
    }
    if (n > 4) throw const FormatException('DER length is too large');
    _require(n);
    var len = 0;
    for (var i = 0; i < n; i++) {
      len = (len << 8) | _bytes[_pos++];
    }
    return len;
  }

  Uint8List _readValue(int length) {
    _require(length);
    final v = Uint8List.fromList(_bytes.sublist(_pos, _pos + length));
    _pos += length;
    return v;
  }

  Uint8List enterSequence() {
    final tag = _readTag();
    if (tag != 0x30) {
      throw FormatException(
          'expected SEQUENCE (0x30), got 0x${tag.toRadixString(16)}');
    }
    return _readValue(_readLength());
  }

  Uint8List readBitString() {
    final tag = _readTag();
    if (tag != 0x03) {
      throw FormatException(
          'expected BIT STRING (0x03), got 0x${tag.toRadixString(16)}');
    }
    final len = _readLength();
    if (len < 1) throw const FormatException('empty DER BIT STRING');
    _require(len);
    final unusedBits = _bytes[_pos++];
    if (unusedBits != 0) {
      throw const FormatException('RSA key BIT STRING has unused bits');
    }
    return _readValue(len - 1);
  }

  /// Read an INTEGER, stripping the leading 0x00 sign byte that DER adds when
  /// the MSB of the value is set. The ATVRS pairing hash needs the raw numeric
  /// bytes, matching what OpenSSL/Python's `public_numbers().n` produce.
  Uint8List readInteger() {
    final tag = _readTag();
    if (tag != 0x02) {
      throw FormatException(
          'expected INTEGER (0x02), got 0x${tag.toRadixString(16)}');
    }
    var bytes = _readValue(_readLength());
    if (bytes.length > 1 && bytes[0] == 0) bytes = bytes.sublist(1);
    return Uint8List.fromList(bytes);
  }

  void skipTlv() {
    _readTag();
    final len = _readLength();
    _require(len);
    _pos += len;
  }

  void _require(int count) {
    if (count < 0 || _pos + count > _bytes.length) {
      throw const FormatException('truncated DER value');
    }
  }
}
