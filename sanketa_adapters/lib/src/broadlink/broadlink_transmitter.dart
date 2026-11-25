/// BroadLink bridge IR transmitter — sends IR signals over WiFi to a BroadLink
/// RM device, which re-emits them as infrared. Implements [IrTransmitter] so it
/// slots into the existing IR adapter stack identically to a phone's built-in
/// blaster. The same [IrCodeset] + [IrCodec] pipeline produces the signal; only
/// the last mile changes from hardware to network.
library;

import 'dart:typed_data';

import 'package:sanketa_ir/sanketa_ir.dart';

import 'broadlink_protocol.dart';

class BroadLinkTransmitter implements IrTransmitter {
  BroadLinkTransmitter({required BroadLinkSession session}) : _session = session;

  BroadLinkSession? _session;

  void updateSession(BroadLinkSession session) => _session = session;

  @override
  bool get available => _session != null;

  @override
  Future<void> transmit(IrSignal signal) async {
    final session = _session;
    if (session == null) {
      throw StateError('BroadLink bridge not connected');
    }
    await session.sendIrSignal(signal.carrierHz, signal.pattern);
  }

  /// Learn an IR signal from a physical remote pointed at the bridge device.
  /// Returns the decoded carrier + pattern, or null on timeout.
  Future<(int carrierHz, List<int> pattern)?> learn({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final session = _session;
    if (session == null) return null;

    final data = await session.learnIr(timeout: timeout);
    if (data == null) return null;

    final (carrierHz, pattern) = decodeBroadLink(Uint8List.fromList(data));
    if (pattern.isEmpty) return null;
    return (carrierHz, pattern);
  }

  void close() {
    _session?.close();
    _session = null;
  }
}
