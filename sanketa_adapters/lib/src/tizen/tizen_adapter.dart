/// Samsung Tizen adapter (2016+) — JSON over WebSocket on 8001/8002.
///
/// Keys travel as `ms.remote.control` / `SendRemoteKey` frames; live text as
/// `SendInputString` (base64). Pairing is token-based: the TV shows an allow
/// prompt and returns a token in the `ms.channel.connect` event, which we
/// persist as the credential. Verified here against a fake WsChannel; the live
/// TLS socket + exact token lifecycle are Phase 0.
library;

import 'dart:convert';

import 'package:async/async.dart';
import 'package:sanketa_core/sanketa_core.dart';

import '../common/ws_channel.dart';

const Map<Key, String> _tizenKeys = {
  Key.power: 'KEY_POWER',
  Key.powerOff: 'KEY_POWEROFF',
  Key.powerOn: 'KEY_POWERON',
  Key.volumeUp: 'KEY_VOLUP',
  Key.volumeDown: 'KEY_VOLDOWN',
  Key.mute: 'KEY_MUTE',
  Key.up: 'KEY_UP',
  Key.down: 'KEY_DOWN',
  Key.left: 'KEY_LEFT',
  Key.right: 'KEY_RIGHT',
  Key.ok: 'KEY_ENTER',
  Key.back: 'KEY_RETURN',
  Key.home: 'KEY_HOME',
  Key.menu: 'KEY_MENU',
  Key.exit: 'KEY_EXIT',
  Key.channelUp: 'KEY_CHUP',
  Key.channelDown: 'KEY_CHDOWN',
  Key.input: 'KEY_SOURCE',
  Key.play: 'KEY_PLAY',
  Key.pause: 'KEY_PAUSE',
  Key.stop: 'KEY_STOP',
  Key.rewind: 'KEY_REWIND',
  Key.fastForward: 'KEY_FF',
  Key.digit0: 'KEY_0',
  Key.digit1: 'KEY_1',
  Key.digit2: 'KEY_2',
  Key.digit3: 'KEY_3',
  Key.digit4: 'KEY_4',
  Key.digit5: 'KEY_5',
  Key.digit6: 'KEY_6',
  Key.digit7: 'KEY_7',
  Key.digit8: 'KEY_8',
  Key.digit9: 'KEY_9',
};

class TizenAdapter implements ControlAdapter {
  TizenAdapter({required WsChannel channel}) : _ch = channel;

  final WsChannel _ch;

  @override
  String get id => 'tizen';

  @override
  BrandFamily get brandFamily => BrandFamily.tizen;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:samsung.com:device:RemoteControlReceiver:1'],
        probePorts: [8001, 8002],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _tizenKeys.keys.toSet(),
        textMode: TextInjectionMode.live, // SendInputString
        wake: true, // WoWLAN (native)
        appLaunch: false,
        inputList: false,
        volumeReadback: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      if (!_ch.isOpen) await _ch.connect();
      final q = StreamQueue<String>(_ch.messages);
      try {
        while (true) {
          final raw = await q.next.timeout(const Duration(seconds: 10));
          final data = jsonDecode(raw);
          if (data is Map && data['event'] == 'ms.channel.connect') {
            final token = (data['data'] as Map?)?['token']?.toString();
            return PairingResult.paired(token ?? 'tizen:no-token');
          }
        }
      } finally {
        await q.cancel(immediate: true);
      }
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() => _ch.connect();

  @override
  Future<void> disconnect() => _ch.close();

  @override
  Future<bool> heartbeat() async => _ch.isOpen;

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final name = _tizenKeys[key];
    if (name == null) {
      return Future.value(
          CommandResult.failure('key not supported on tizen: ${key.name}'));
    }
    final cmd = switch (press) {
      PressType.tap => 'Click',
      PressType.holdStart => 'Press',
      PressType.holdEnd => 'Release',
    };
    return _send(_keyFrame(name, cmd));
  }

  @override
  Future<CommandResult> sendText(TextOp op) {
    switch (op.kind) {
      case TextOpKind.insert:
        return _send(_textFrame(op.text ?? ''));
      case TextOpKind.submit:
        return sendKey(Key.ok);
      case TextOpKind.delete:
      case TextOpKind.clear:
        return Future.value(const CommandResult.failure(
            'field delete/clear not exposed by the Tizen remote API'));
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.failure('app launch not implemented for tizen yet');

  @override
  Future<CommandResult> setInput(InputRef input) => sendKey(Key.input);

  @override
  Future<CommandResult> power({required bool on}) =>
      sendKey(on ? Key.power : Key.powerOff);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  String _keyFrame(String keyName, String cmd) => jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': cmd,
          'DataOfCmd': keyName,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      });

  String _textFrame(String text) => jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': base64.encode(utf8.encode(text)),
          'DataOfCmd': 'base64',
          'TypeOfRemote': 'SendInputString',
        },
      });

  Future<CommandResult> _send(String frame) async {
    if (!_ch.isOpen) {
      return const CommandResult.failure('tizen channel not connected');
    }
    final sw = Stopwatch()..start();
    try {
      _ch.send(frame);
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }
}
