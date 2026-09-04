/// Android TV pairing-secret computation (FR-1.4).
///
/// After the user types the 6-hex-digit code shown on the TV, the client proves
/// it by hashing both certificates' public keys together with the code's nonce:
///
///   hash = SHA-256( clientModulus ‖ clientExponent ‖
///                   serverModulus ‖ serverExponent ‖ nonce )
///
/// where the code's first byte is a checksum that must equal `hash[0]`, and the
/// remaining bytes are the nonce. The hashing is pure and unit-tested here; the
/// RSA public-key extraction from the TLS certificates is the native/on-device
/// piece wired in Phase 1 and validated in Phase 0.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The 6-hex-digit code from the TV, as raw bytes (e.g. "4A5B6C" → [0x4A,…]).
List<int> decodeHexCode(String code) {
  final clean = code.trim();
  if (clean.length.isOdd) {
    throw FormatException('pairing code must be an even number of hex digits: $code');
  }
  final out = <int>[];
  for (var i = 0; i < clean.length; i += 2) {
    out.add(int.parse(clean.substring(i, i + 2), radix: 16));
  }
  return out;
}

/// Compute the pairing hash over both public keys and the code's nonce.
Uint8List computePairingHash({
  required List<int> clientModulus,
  required List<int> clientExponent,
  required List<int> serverModulus,
  required List<int> serverExponent,
  required List<int> nonce,
}) {
  final input = <int>[
    ...clientModulus,
    ...clientExponent,
    ...serverModulus,
    ...serverExponent,
    ...nonce,
  ];
  return Uint8List.fromList(sha256.convert(input).bytes);
}

/// The nonce is the code minus its leading checksum byte.
List<int> nonceFromCode(List<int> codeBytes) =>
    codeBytes.length <= 1 ? const [] : codeBytes.sublist(1);

/// The client verifies the code by checking its first byte equals `hash[0]`.
bool pairingChecksumMatches({
  required List<int> codeBytes,
  required Uint8List hash,
}) =>
    codeBytes.isNotEmpty && hash.isNotEmpty && codeBytes[0] == hash[0];
