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

  /// True when the TV has sent a RemoteError (field 3), meaning our cert is
  /// not authorized or the session was rejected.
  bool get gotError;

  /// ATVRS feature bitmask negotiated during the handshake. Zero before the
  /// Configure exchange completes. The adapter reads this to build a dynamic
  /// [CapabilityMap] that reflects what the TV actually supports.
  int get negotiatedFeatures;

  Future<void> connect();

  Future<void> close();

  /// Send one RemoteMessage body; the channel frames and encrypts it.
  void sendMessage(List<int> body);

  /// Incoming RemoteMessage bodies, already de-framed and decoded.
  Stream<Uint8List> get messages;
}

/// Well-known ATVRS v2 feature bitmask values, shared between the channel
/// (which negotiates them) and the adapter (which interprets them).
abstract final class AtvrsFeatures {
  static const int ping = 1;
  static const int key = 2;
  static const int ime = 4;
  static const int voice = 8;
  static const int power = 32;
  static const int volume = 64;
  static const int appLink = 512;
}
