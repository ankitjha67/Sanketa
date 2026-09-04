/// Shared WebSocket transport seam for the JSON-over-WebSocket adapters
/// (Samsung Tizen, LG webOS). The real implementation wraps a `WebSocket` with
/// TLS on the platform's control port; everything above it is pure and tested
/// with a fake. Same pattern as the Android TV [AtvChannel] and IR
/// `IrTransmitter` seams.
library;

abstract interface class WsChannel {
  bool get isOpen;

  Future<void> connect();

  Future<void> close();

  /// Send one text frame (a JSON string for these platforms).
  void send(String message);

  /// Incoming text frames.
  Stream<String> get messages;
}
