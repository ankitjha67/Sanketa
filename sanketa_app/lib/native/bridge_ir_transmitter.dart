/// Adapts [IrBridge] (native platform channel) to [IrTransmitter] (sanketa_ir
/// contract). This is the one line where native hardware meets pure-Dart IR.
library;

import 'package:sanketa_ir/sanketa_ir.dart';

import 'platform_bridge.dart';

class BridgeIrTransmitter implements IrTransmitter {
  BridgeIrTransmitter(this._bridge);

  final IrBridge _bridge;
  bool _available = false;

  Future<void> init() async {
    try {
      _available = await _bridge.hasIrEmitter;
    } on Object {
      _available = false;
    }
  }

  @override
  bool get available => _available;

  @override
  Future<void> transmit(IrSignal signal) =>
      _bridge.transmit(signal.carrierHz, signal.pattern);
}
