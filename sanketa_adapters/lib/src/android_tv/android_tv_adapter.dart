/// AndroidTvAdapter — Android TV / Google TV remote protocol v2 behind the
/// [ControlAdapter] contract. This is the keyboard-hero platform (live text
/// injection) and, under OD-2 India-first, the dominant one.
///
/// Verified here: capability map, key injection (correct keycode + direction),
/// text/app/power command composition, connection lifecycle — all against a fake
/// channel. Pending Phase 0 on a real device: the wire field numbers (see
/// [RemoteField]), TLS + client-cert handling (the [AtvChannel] impl), and IME
/// batch-edit text. Pairing is the separate [AtvPairingSession].
library;

import 'package:sanketa_core/sanketa_core.dart';

import 'atv_channel.dart';
import 'atv_keymap.dart';
import 'atv_messages.dart';

class AndroidTvAdapter implements ControlAdapter {
  AndroidTvAdapter({required AtvChannel channel}) : _channel = channel;

  final AtvChannel _channel;

  @override
  String get id => 'android_tv';

  @override
  BrandFamily get brandFamily => BrandFamily.androidTv;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        mdnsServiceTypes: ['_androidtvremote2._tcp'],
        probePorts: [6466, 6467],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: androidKeyCodes.keys.toSet(),
        textMode: TextInjectionMode.live, // the hero feature (FR-4.1)
        wake: true, // WoL/WoWLAN
        volumeReadback: false, // state parsing is Phase 0+
        appLaunch: true,
        inputList: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    // By the time we hold a session channel the client cert is already
    // authorized; the one-time code handshake is AtvPairingSession (port 6467).
    try {
      if (!_channel.isOpen) await _channel.connect();
      return _channel.isOpen
          ? const PairingResult.paired('android_tv:session')
          : const PairingResult.failed('could not open session channel');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() => _channel.connect();

  @override
  Future<void> disconnect() => _channel.close();

  @override
  Future<bool> heartbeat() async {
    if (!_channel.isOpen) return false;
    _channel.sendMessage(buildPingResponse(1)); // real impl round-trips a ping
    return true;
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final keyCode = androidKeyCodes[key];
    if (keyCode == null) {
      return Future.value(
          CommandResult.failure('key not supported on android_tv: ${key.name}'));
    }
    return _send(buildKeyInject(keyCode, atvDirectionFor(press)));
  }

  @override
  Future<CommandResult> sendText(TextOp op) {
    switch (op.kind) {
      case TextOpKind.insert:
        return _send(buildImeText(op.text ?? ''));
      case TextOpKind.submit:
        return _send(buildKeyInject(androidKeyCodes[Key.enter]!, AtvDirection.short));
      case TextOpKind.delete:
        return _repeatKey(androidKeyCodes[Key.backspace]!, op.count);
      case TextOpKind.clear:
        return Future.value(const CommandResult.failure(
            'clear over android_tv needs IME batch-edit (Phase 0)'));
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) => _send(buildAppLink(app.id));

  @override
  Future<CommandResult> setInput(InputRef input) async =>
      const CommandResult.failure('input switching not yet supported on android_tv');

  @override
  Future<CommandResult> power({required bool on}) => sendKey(Key.power);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  Future<CommandResult> _send(List<int> body) async {
    if (!_channel.isOpen) {
      return const CommandResult.failure('android_tv channel not connected');
    }
    final sw = Stopwatch()..start();
    try {
      _channel.sendMessage(body);
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  Future<CommandResult> _repeatKey(int keyCode, int count) async {
    for (var i = 0; i < count; i++) {
      final res = await _send(buildKeyInject(keyCode, AtvDirection.short));
      if (!res.ok) return res;
    }
    return const CommandResult.success();
  }
}
