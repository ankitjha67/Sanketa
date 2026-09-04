/// The Android TV transport seam — the one native/socket boundary.
///
/// The adapter and pairing session speak in whole RemoteMessage bodies; the
/// channel owns TLS, the varint framing ([frameMessage]/[MessageDeframer]), and
/// the client certificate. The real implementation (a TLS socket on 6466 for the
/// session, 6467 for pairing) lands with the Flutter app; everything above this
/// interface is pure and tested with a fake channel.
library;

import 'dart:typed_data';

abstract interface class AtvChannel {
  bool get isOpen;

  Future<void> connect();

  Future<void> close();

  /// Send one RemoteMessage body; the channel frames and encrypts it.
  void sendMessage(List<int> body);

  /// Incoming RemoteMessage bodies, already de-framed and decrypted.
  Stream<Uint8List> get messages;
}
