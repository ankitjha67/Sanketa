/// IrControlAdapter — puts infrared behind the same [ControlAdapter] contract as
/// every network brand. To the rest of the app, an IR TV is just another target
/// with a capability map; the only differences it sees are `Transport.infrared`,
/// `textMode: none` (→ D-pad assist, FR-4.4), and no state readback (IR is
/// one-way).
///
/// Hold-to-repeat is handled here: IR has no device-side auto-repeat, so a held
/// key resends the protocol's repeat frame on an interval until release
/// (FR-2.4). Emission itself goes through the injected [IrTransmitter] seam.
library;

import 'dart:async';

import 'package:sanketa_core/sanketa_core.dart';

import 'ir_codec.dart';
import 'ir_codeset.dart';
import 'ir_signal.dart';
import 'ir_transmitter.dart';

class IrControlAdapter implements ControlAdapter {
  IrControlAdapter({
    required IrCodeset codeset,
    required IrTransmitter transmitter,
    IrCodec codec = const IrCodec(),
    Duration repeatInterval = const Duration(milliseconds: 110),
  })  : _codeset = codeset,
        _tx = transmitter,
        _codec = codec,
        _repeatInterval = repeatInterval;

  final IrCodeset _codeset;
  final IrTransmitter _tx;
  final IrCodec _codec;
  final Duration _repeatInterval;

  final Map<Key, Timer> _holds = {};

  @override
  String get id => 'ir:${_codeset.id}';

  @override
  BrandFamily get brandFamily => _codeset.brand;

  @override
  Transport get transport => Transport.infrared;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(); // not networked

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _codeset.supportedKeys,
        textMode: TextInjectionMode.none, // → D-pad assist mode (FR-4.4)
        wake: _codeset.supports(Key.powerOn) || _codeset.supports(Key.power),
        volumeReadback: false,
        appLaunch: false,
        inputList: false,
        stateReadback: false, // IR is one-way
      );

  @override
  Future<PairingResult> pair(PairingContext context) async =>
      // IR "pairing" is codeset selection, done by the matching wizard (FR-2.3).
      const PairingResult.paired('ir:codeset-selected');

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async => _cancelAllHolds();

  @override
  Future<bool> heartbeat() async => _tx.available;

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) async {
    final command = _codeset.keys[key];
    if (command == null) {
      return CommandResult.failure('key not in codeset: ${key.name}');
    }
    final signal = _codec.encode(command);

    switch (press) {
      case PressType.tap:
        return _emit(signal);
      case PressType.holdStart:
        final first = await _emit(signal);
        if (!first.ok) return first;
        _holds[key]?.cancel();
        _holds[key] = Timer.periodic(_repeatInterval, (_) {
          // Fire-and-forget repeat frames; a failed repeat just stops the hold.
          unawaited(_tx
              .transmit(IrSignal(
                carrierHz: signal.carrierHz,
                pattern: signal.repeatFrame,
              ))
              .catchError((Object _) => _cancelHold(key)));
        });
        return first;
      case PressType.holdEnd:
        _cancelHold(key);
        return const CommandResult.success();
    }
  }

  @override
  Future<CommandResult> sendText(TextOp op) async => const CommandResult.failure(
      'IR has no text injection; use D-pad assist (FR-4.4)');

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.failure('app launch is not available over IR');

  @override
  Future<CommandResult> setInput(InputRef input) async {
    // IR usually exposes only a single discrete "source" toggle, not addressable
    // inputs. Use it if the codeset has one.
    if (_codeset.supports(Key.input)) return sendKey(Key.input);
    return const CommandResult.failure(
        'input switching not available in this codeset');
  }

  @override
  Future<CommandResult> power({required bool on}) {
    final key = on
        ? (_codeset.supports(Key.powerOn) ? Key.powerOn : Key.power)
        : (_codeset.supports(Key.powerOff) ? Key.powerOff : Key.power);
    return sendKey(key);
  }

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  /// Cancel any in-flight held keys. Call when the device is deselected.
  void dispose() => _cancelAllHolds();

  Future<CommandResult> _emit(IrSignal signal) async {
    if (!_tx.available) {
      return const CommandResult.failure('no IR emitter on this device');
    }
    final sw = Stopwatch()..start();
    try {
      await _tx.transmit(signal);
      sw.stop();
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  void _cancelHold(Key key) {
    _holds.remove(key)?.cancel();
  }

  void _cancelAllHolds() {
    for (final t in _holds.values) {
      t.cancel();
    }
    _holds.clear();
  }
}
