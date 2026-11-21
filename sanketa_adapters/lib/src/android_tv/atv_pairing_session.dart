/// The one-time Android TV pairing handshake (FR-1.4), run over the 6467 channel.
///
/// Sequence (each step awaits the TV's acknowledgement):
///   PairingRequest → PairingOption → PairingConfiguration
///   → [TV shows a 6-digit code] → user types it → PairingSecret → done.
///
/// The message *sequence and secret computation* are implemented and tested with
/// a scripted fake channel here. The exact ack contents and the RSA public-key
/// extraction from the TLS certs are the on-device pieces confirmed in Phase 0.
library;

import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:sanketa_core/sanketa_core.dart';

import 'atv_channel.dart';
import 'atv_messages.dart';
import 'atv_pairing.dart';

/// An RSA public key as the two byte-strings the pairing hash needs.
class AtvPublicKey {
  const AtvPublicKey({required this.modulus, required this.exponent});
  final List<int> modulus;
  final List<int> exponent;
}

class AtvPairingSession {
  AtvPairingSession({
    required this.channel,
    required this.clientKey,
    required this.serverKey,
    this.serviceName = 'com.sanketa/remote',
    this.clientName = 'Sanketa',
    this.ackTimeout = const Duration(seconds: 10),
  });

  final AtvChannel channel;
  final AtvPublicKey clientKey;
  final AtvPublicKey serverKey;
  final String serviceName;
  final String clientName;
  final Duration ackTimeout;

  /// Drive the handshake to completion, prompting for the on-screen code via
  /// [PairingContext.requestPin].
  Future<PairingResult> run(PairingContext context) async {
    final requestPin = context.requestPin;
    if (requestPin == null) {
      return const PairingResult.failed('no PIN provider supplied for pairing');
    }

    final acks = StreamQueue<Uint8List>(channel.messages);
    try {
      context.notify?.call('Starting pairing…');
      channel.sendMessage(buildPairingRequest(serviceName, clientName));
      await acks.next.timeout(ackTimeout);

      channel.sendMessage(buildPairingOption());
      await acks.next.timeout(ackTimeout);

      channel.sendMessage(buildPairingConfiguration());
      await acks.next.timeout(ackTimeout); // TV now displays the code

      context.notify?.call('Enter the code shown on your TV');
      final code = decodeHexCode(await requestPin());

      final hash = computePairingHash(
        clientModulus: clientKey.modulus,
        clientExponent: clientKey.exponent,
        serverModulus: serverKey.modulus,
        serverExponent: serverKey.exponent,
        nonce: nonceFromCode(code),
      );
      if (!pairingChecksumMatches(codeBytes: code, hash: hash)) {
        return const PairingResult.failed('pairing code checksum mismatch');
      }

      channel.sendMessage(buildPairingSecret(hash));
      await acks.next.timeout(ackTimeout); // secret accepted

      return const PairingResult.paired('android_tv:client-cert');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    } finally {
      await acks.cancel(immediate: true);
    }
  }
}
