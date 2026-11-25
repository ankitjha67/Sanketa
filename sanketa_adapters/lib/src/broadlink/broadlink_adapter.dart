/// BroadLink WiFi-IR bridge adapter — puts a BroadLink RM behind the same
/// [ControlAdapter] contract as every other brand. Transport is [Transport.bridge].
///
/// The adapter composes [IrControlAdapter] for the actual command logic (codeset
/// lookup, hold-to-repeat, encoding) and swaps the transmitter from the phone's
/// hardware blaster to the network bridge. Discovery finds the bridge; pairing
/// is the BroadLink auth handshake.
library;

import 'dart:async';

import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';

import 'broadlink_protocol.dart';
import 'broadlink_transmitter.dart';

class BroadLinkAdapter implements ControlAdapter {
  BroadLinkAdapter({
    required BroadLinkDevice device,
    required IrCodeset codeset,
    IrCodec codec = const IrCodec(),
  })  : _device = device,
        _codeset = codeset,
        _codec = codec;

  final BroadLinkDevice _device;
  final IrCodeset _codeset;
  final IrCodec _codec;

  BroadLinkTransmitter? _tx;
  BroadLinkSession? _session;
  IrControlAdapter? _ir;
  bool _connected = false;

  @override
  String get id => 'broadlink:${_device.mac.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

  @override
  BrandFamily get brandFamily => _codeset.brand;

  @override
  Transport get transport => Transport.bridge;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        probePorts: [80],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _codeset.supportedKeys,
        textMode: TextInjectionMode.none,
        wake: _codeset.supports(Key.powerOn) || _codeset.supports(Key.power),
        volumeReadback: false,
        appLaunch: false,
        inputList: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      _session = await BroadLinkSession.authenticate(_device);
      _tx = BroadLinkTransmitter(session: _session!);
      return PairingResult.paired(id);
    } on Object catch (e) {
      return PairingResult.failed('BroadLink auth failed: $e');
    }
  }

  @override
  Future<void> connect() async {
    if (_session == null) {
      _session = await BroadLinkSession.authenticate(_device);
    }
    _tx ??= BroadLinkTransmitter(session: _session!);
    _tx!.updateSession(_session!);
    _ir = IrControlAdapter(
      codeset: _codeset,
      transmitter: _tx!,
      codec: _codec,
    );
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _tx?.close();
    _tx = null;
    _session = null;
  }

  @override
  Future<bool> heartbeat() async => _connected && (_tx?.available ?? false);

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final ir = _ir;
    if (ir == null) return Future.value(const CommandResult.failure('not connected'));
    return ir.sendKey(key, press: press);
  }

  @override
  Future<CommandResult> sendText(TextOp op) {
    final ir = _ir;
    if (ir == null) return Future.value(const CommandResult.failure('not connected'));
    return ir.sendText(op);
  }

  @override
  Future<CommandResult> launchApp(AppRef app) {
    final ir = _ir;
    if (ir == null) return Future.value(const CommandResult.failure('not connected'));
    return ir.launchApp(app);
  }

  @override
  Future<CommandResult> setInput(InputRef input) {
    final ir = _ir;
    if (ir == null) return Future.value(const CommandResult.failure('not connected'));
    return ir.setInput(input);
  }

  @override
  Future<CommandResult> power({required bool on}) {
    final ir = _ir;
    if (ir == null) return Future.value(const CommandResult.failure('not connected'));
    return ir.power(on: on);
  }

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  /// Access the bridge transmitter for IR learning flows.
  BroadLinkTransmitter? get bridgeTransmitter => _tx;
}
