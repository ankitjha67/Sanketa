/// Generates a unique self-signed RSA 2048-bit X.509 certificate and private
/// key in PEM format, suitable for ATVRS pairing.
///
/// Each device (app install) should generate its own certificate at first
/// launch. The ATVRS pairing protocol stores the client certificate fingerprint
/// on the TV, so the same cert must be used for both pairing (port 6467) and
/// control (port 6466) sessions.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class GeneratedCert {
  const GeneratedCert({required this.certPem, required this.keyPem});
  final String certPem;
  final String keyPem;
}

GeneratedCert generateSelfSignedCert({String cn = 'Sanketa Remote'}) {
  final keyPair = _generateRsaKeyPair();
  final pub = keyPair.publicKey as RSAPublicKey;
  final priv = keyPair.privateKey as RSAPrivateKey;

  final tbs = _buildTbsCertificate(pub, cn);
  final sig = _sign(tbs, priv);
  final certDer = _wrapCertificate(tbs, sig);

  final privDer = _encodePrivateKeyPkcs8(priv);

  return GeneratedCert(
    certPem: _derToPem(certDer, 'CERTIFICATE'),
    keyPem: _derToPem(privDer, 'PRIVATE KEY'),
  );
}

// -- RSA key generation -------------------------------------------------------

AsymmetricKeyPair<PublicKey, PrivateKey> _generateRsaKeyPair() {
  final secureRandom = FortunaRandom()
    ..seed(KeyParameter(Uint8List.fromList(
        List.generate(32, (_) => Random.secure().nextInt(256)))));
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        secureRandom));
  return keyGen.generateKeyPair();
}

// -- ASN.1 DER encoding helpers -----------------------------------------------

Uint8List _derTag(int tag, Uint8List content) {
  final len = _derLength(content.length);
  final out = BytesBuilder()
    ..addByte(tag)
    ..add(len)
    ..add(content);
  return out.toBytes();
}

Uint8List _derLength(int length) {
  if (length < 0x80) return Uint8List.fromList([length]);
  final bytes = <int>[];
  var l = length;
  while (l > 0) {
    bytes.insert(0, l & 0xff);
    l >>= 8;
  }
  return Uint8List.fromList([0x80 | bytes.length, ...bytes]);
}

Uint8List _derSequence(List<Uint8List> items) {
  final body = BytesBuilder();
  for (final i in items) {
    body.add(i);
  }
  return _derTag(0x30, body.toBytes());
}

Uint8List _derInteger(BigInt value) {
  var bytes = _bigIntToBytes(value);
  if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
    bytes = Uint8List.fromList([0, ...bytes]);
  }
  return _derTag(0x02, bytes);
}

Uint8List _derIntegerSmall(int value) => _derInteger(BigInt.from(value));

Uint8List _derBitString(Uint8List content) {
  final body = Uint8List(content.length + 1);
  body[0] = 0; // unused bits
  body.setRange(1, body.length, content);
  return _derTag(0x03, body);
}

Uint8List _derOctetString(Uint8List content) => _derTag(0x04, content);

Uint8List _derOid(List<int> oid) {
  final bytes = <int>[oid[0] * 40 + oid[1]];
  for (var i = 2; i < oid.length; i++) {
    final parts = <int>[];
    var v = oid[i];
    parts.add(v & 0x7f);
    v >>= 7;
    while (v > 0) {
      parts.add(0x80 | (v & 0x7f));
      v >>= 7;
    }
    bytes.addAll(parts.reversed);
  }
  return _derTag(0x06, Uint8List.fromList(bytes));
}

Uint8List _derUtf8String(String s) =>
    _derTag(0x0c, Uint8List.fromList(utf8.encode(s)));

Uint8List _derUtcTime(DateTime dt) {
  final s = '${_pad(dt.year % 100)}${_pad(dt.month)}${_pad(dt.day)}'
      '${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
  return _derTag(0x17, Uint8List.fromList(ascii.encode(s)));
}

Uint8List _derExplicit(int tagNum, Uint8List content) =>
    _derTag(0xa0 | tagNum, content);

Uint8List _derBoolean(bool value) =>
    _derTag(0x01, Uint8List.fromList([value ? 0xff : 0x00]));

String _pad(int v) => v.toString().padLeft(2, '0');

// OIDs
final _oidSha256Rsa = [1, 2, 840, 113549, 1, 1, 11]; // sha256WithRSAEncryption
final _oidRsaEncryption = [1, 2, 840, 113549, 1, 1, 1]; // rsaEncryption
final _oidCommonName = [2, 5, 4, 3]; // CN
final _oidBasicConstraints = [2, 5, 29, 19];

// -- certificate construction -------------------------------------------------

Uint8List _buildTbsCertificate(RSAPublicKey pub, String cn) {
  final now = DateTime.now().toUtc();
  final notAfter = now.add(const Duration(days: 730));
  final serial = _randomSerial();
  final name = _buildName(cn);

  return _derSequence([
    _derExplicit(0, _derIntegerSmall(2)), // version v3
    _derInteger(serial),
    _sigAlgId(),
    name, // issuer
    _derSequence([_derUtcTime(now), _derUtcTime(notAfter)]), // validity
    name, // subject (same = self-signed)
    _subjectPublicKeyInfo(pub),
    _derExplicit(3, _derSequence([
      _derSequence([
        _derOid(_oidBasicConstraints),
        _derBoolean(true), // critical
        _derOctetString(_derSequence([])), // cA=FALSE for a client certificate
      ]),
    ])),
  ]);
}

Uint8List _sigAlgId() => _derSequence([
      _derOid(_oidSha256Rsa),
      _derTag(0x05, Uint8List(0)), // NULL
    ]);

Uint8List _buildName(String cn) => _derSequence([
      _derTag(0x31, _derSequence([_derOid(_oidCommonName), _derUtf8String(cn)])),
    ]);

Uint8List _subjectPublicKeyInfo(RSAPublicKey pub) {
  final rsaPubKey = _derSequence([
    _derInteger(pub.modulus!),
    _derInteger(pub.exponent!),
  ]);
  return _derSequence([
    _derSequence([
      _derOid(_oidRsaEncryption),
      _derTag(0x05, Uint8List(0)),
    ]),
    _derBitString(rsaPubKey),
  ]);
}

BigInt _randomSerial() {
  final rng = Random.secure();
  final bytes = List.generate(16, (_) => rng.nextInt(256));
  bytes[0] &= 0x7f; // ensure positive
  return _bytesToBigInt(Uint8List.fromList(bytes));
}

// -- signing ------------------------------------------------------------------

Uint8List _sign(Uint8List tbsDer, RSAPrivateKey priv) {
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(priv));
  final sig = signer.generateSignature(tbsDer);
  return sig.bytes;
}

Uint8List _wrapCertificate(Uint8List tbsDer, Uint8List signature) =>
    _derSequence([
      tbsDer,
      _sigAlgId(),
      _derBitString(signature),
    ]);

// -- PKCS#8 private key encoding ----------------------------------------------

Uint8List _encodePrivateKeyPkcs8(RSAPrivateKey priv) {
  final rsaPrivKey = _derSequence([
    _derIntegerSmall(0), // version
    _derInteger(priv.modulus!),
    _derInteger(priv.publicExponent!),
    _derInteger(priv.privateExponent!),
    _derInteger(priv.p!),
    _derInteger(priv.q!),
    _derInteger(priv.privateExponent! % (priv.p! - BigInt.one)), // d mod (p-1)
    _derInteger(priv.privateExponent! % (priv.q! - BigInt.one)), // d mod (q-1)
    _derInteger(priv.q!.modInverse(priv.p!)), // q^-1 mod p
  ]);

  return _derSequence([
    _derIntegerSmall(0), // version
    _derSequence([
      _derOid(_oidRsaEncryption),
      _derTag(0x05, Uint8List(0)),
    ]),
    _derOctetString(rsaPrivKey),
  ]);
}

// -- PEM encoding -------------------------------------------------------------

String _derToPem(Uint8List der, String label) {
  final b64 = base64.encode(der);
  final lines = <String>['-----BEGIN $label-----'];
  for (var i = 0; i < b64.length; i += 64) {
    lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
  }
  lines.add('-----END $label-----');
  return lines.join('\n');
}

// -- BigInt <-> bytes ---------------------------------------------------------

Uint8List _bigIntToBytes(BigInt n) {
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

BigInt _bytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (final b in bytes) {
    result = (result << 8) | BigInt.from(b);
  }
  return result;
}
