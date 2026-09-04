/// The IR emit boundary — the one seam between pure Dart and native hardware.
///
/// The real implementation wraps Android `ConsumerIrManager` via a platform
/// channel (in the Flutter app); iOS has no phone IR and uses the bridge (FR-8).
/// Everything above this interface — encoding, codesets, the adapter — is pure
/// and testable with a fake transmitter.
library;

import 'ir_signal.dart';

abstract interface class IrTransmitter {
  /// Whether IR hardware is present and usable on this device
  /// (`ConsumerIrManager.hasIrEmitter()`), FR-2.1.
  bool get available;

  /// Emit one signal at its carrier frequency. Should resolve when the pattern
  /// has been handed to the hardware.
  Future<void> transmit(IrSignal signal);
}
