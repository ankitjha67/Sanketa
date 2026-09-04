/// IrAcController — a stateful AC remote (PRD FR-2.5).
///
/// Not a TV [ControlAdapter]: an AC has its own layout (power, temp ±, mode,
/// fan, swing), and every action re-emits the *full* state frame. State is
/// mirrored best-effort; since IR is one-way the UI shows a "state may drift"
/// note. Emission goes through the same injected [IrTransmitter] seam as the TV
/// IR path.
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_transmitter.dart';
import 'ac_encoder.dart';
import 'ac_state.dart';

class IrAcController {
  IrAcController({
    required AcEncoder encoder,
    required IrTransmitter transmitter,
    AcState initial = const AcState(),
  })  : _encoder = encoder,
        _tx = transmitter,
        _state = initial;

  final AcEncoder _encoder;
  final IrTransmitter _tx;
  AcState _state;

  AcState get state => _state;

  Future<CommandResult> setPower({required bool on}) =>
      _apply(_state.copyWith(power: on));

  Future<CommandResult> tempUp() => _apply(
      _state.copyWith(tempC: (_state.tempC + 1).clamp(_encoder.minTempC, _encoder.maxTempC)));

  Future<CommandResult> tempDown() => _apply(
      _state.copyWith(tempC: (_state.tempC - 1).clamp(_encoder.minTempC, _encoder.maxTempC)));

  Future<CommandResult> setMode(AcMode mode) =>
      _apply(_state.copyWith(mode: mode));

  Future<CommandResult> setFan(AcFan fan) => _apply(_state.copyWith(fan: fan));

  Future<CommandResult> setSwing({required bool on}) =>
      _apply(_state.copyWith(swing: on));

  Future<CommandResult> _apply(AcState next) async {
    if (!_tx.available) {
      return const CommandResult.failure('no IR emitter on this device');
    }
    final sw = Stopwatch()..start();
    try {
      await _tx.transmit(_encoder.encode(next));
      _state = next; // mirror only after a successful emit
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }
}
