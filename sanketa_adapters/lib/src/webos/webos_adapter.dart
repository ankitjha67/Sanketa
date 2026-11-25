/// LG webOS adapter — SSAP JSON over WebSocket on 3000/3001.
///
/// Two message shapes: SSAP `request` frames (volume, mute, power-off, IME text,
/// app launch) and pointer-socket `button` frames (D-pad, OK, Back, Home, media).
/// Pairing registers a client-key via the on-TV prompt. The button frames really
/// travel over a secondary pointer-input socket obtained from
/// `getPointerInputSocket`; that indirection and the live TLS sockets are Phase 0.
library;

import 'dart:convert';

import 'package:async/async.dart';
import 'package:sanketa_core/sanketa_core.dart';

import '../common/ws_channel.dart';

/// Keys delivered as pointer-socket button events.
const Map<Key, String> _webosButtons = {
  Key.up: 'UP',
  Key.down: 'DOWN',
  Key.left: 'LEFT',
  Key.right: 'RIGHT',
  Key.ok: 'ENTER',
  Key.back: 'BACK',
  Key.home: 'HOME',
  Key.menu: 'MENU',
  Key.info: 'INFO',
  Key.play: 'PLAY',
  Key.pause: 'PAUSE',
  Key.stop: 'STOP',
  Key.channelUp: 'CHANNELUP',
  Key.channelDown: 'CHANNELDOWN',
  Key.digit0: '0',
  Key.digit1: '1',
  Key.digit2: '2',
  Key.digit3: '3',
  Key.digit4: '4',
  Key.digit5: '5',
  Key.digit6: '6',
  Key.digit7: '7',
  Key.digit8: '8',
  Key.digit9: '9',
};

/// Keys delivered as SSAP requests.
const Map<Key, String> _webosSsapKeys = {
  Key.volumeUp: 'ssap://audio/volumeUp',
  Key.volumeDown: 'ssap://audio/volumeDown',
};

class WebosAdapter extends ControlAdapter {
  WebosAdapter({required WsChannel channel}) : _ch = channel;

  final WsChannel _ch;
  int _id = 0;

  @override
  String get id => 'webos';

  @override
  BrandFamily get brandFamily => BrandFamily.webOs;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:lge-com:service:webos-second-screen:1'],
        probePorts: [3000, 3001],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: {
          ..._webosButtons.keys,
          ..._webosSsapKeys.keys,
          Key.mute,
          Key.powerOff
        },
        textMode: TextInjectionMode.live, // IME insertText
        wake: false, // WoL not yet implemented
        appLaunch: true,
        inputList: false,
        volumeReadback: true,
        stateReadback: true,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      if (!_ch.isOpen) await _ch.connect();
      final q = StreamQueue<String>(_ch.messages);
      try {
        _ch.send(jsonEncode({
          'type': 'register',
          'id': 'register_${_id++}',
          'payload': {
            'pairingType': 'PROMPT',
            'manifest': {
              'appId': 'com.sanketa.remote',
              'permissions': ['CONTROL_AUDIO', 'CONTROL_INPUT_TEXT', 'LAUNCH'],
            },
          },
        }));
        context.notify?.call('Approve Sanketa on your TV');
        while (true) {
          final raw = await q.next.timeout(const Duration(seconds: 30));
          final data = jsonDecode(raw);
          if (data is Map && data['type'] == 'registered') {
            final key = (data['payload'] as Map?)?['client-key']?.toString();
            return PairingResult.paired(key ?? 'webos:registered');
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
    final button = _webosButtons[key];
    if (button != null) return _send(_buttonFrame(button));
    final uri = _webosSsapKeys[key];
    if (uri != null) return _send(_ssapFrame(uri));
    if (key == Key.mute) {
      return _send(_ssapFrame('ssap://audio/setMute', {'mute': true}));
    }
    if (key == Key.powerOff || key == Key.power) {
      return _send(_ssapFrame('ssap://system/turnOff'));
    }
    return Future.value(
        CommandResult.failure('key not supported on webos: ${key.name}'));
  }

  @override
  Future<CommandResult> sendText(TextOp op) {
    switch (op.kind) {
      case TextOpKind.insert:
        return _send(_ssapFrame('ssap://com.webos.service.ime/insertText',
            {'text': op.text ?? '', 'replace': 0}));
      case TextOpKind.submit:
        return _send(_ssapFrame('ssap://com.webos.service.ime/sendEnterKey'));
      case TextOpKind.delete:
        return _send(_ssapFrame('ssap://com.webos.service.ime/deleteCharacters',
            {'count': op.count}));
      case TextOpKind.clear:
        return _send(_ssapFrame(
            'ssap://com.webos.service.ime/deleteCharacters', {'count': 255}));
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) =>
      _send(_ssapFrame('ssap://system.launcher/launch', {'id': app.id}));

  @override
  Future<CommandResult> setInput(InputRef input) =>
      _send(_ssapFrame('ssap://tv/switchInput', {'inputId': input.id}));

  @override
  Future<CommandResult> power({required bool on}) => on
      ? Future.value(
          const CommandResult.failure('power-on is Wake-on-LAN (native layer)'))
      : _send(_ssapFrame('ssap://system/turnOff'));

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  @override
  Future<int?> getVolume() async {
    try {
      final resp = await _ssapRequest('ssap://audio/getVolume');
      return resp?['volume'] as int?;
    } on Object {
      return null;
    }
  }

  @override
  Future<bool?> getMuted() async {
    try {
      final resp = await _ssapRequest('ssap://audio/getVolume');
      return resp?['muted'] as bool?;
    } on Object {
      return null;
    }
  }

  @override
  Future<PowerState?> getPowerState() async =>
      _ch.isOpen ? PowerState.on : PowerState.standby;

  @override
  Future<AppRef?> getCurrentApp() async {
    try {
      final resp = await _ssapRequest(
          'ssap://com.webos.applicationManager/getForegroundAppInfo');
      final appId = resp?['appId'] as String?;
      if (appId == null || appId.isEmpty) return null;
      return AppRef(id: appId, name: resp?['appName'] as String? ?? appId);
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _ssapRequest(String uri) async {
    if (!_ch.isOpen) return null;
    final reqId = 'query_${_id++}';
    _ch.send(jsonEncode({'type': 'request', 'id': reqId, 'uri': uri}));
    await for (final raw in _ch.messages) {
      final data = jsonDecode(raw) as Map<String, dynamic>?;
      if (data == null) continue;
      if (data['id'] == reqId) {
        return data['payload'] as Map<String, dynamic>?;
      }
    }
    return null;
  }

  String _ssapFrame(String uri, [Map<String, Object?>? payload]) => jsonEncode({
        'type': 'request',
        'id': 'req_${_id++}',
        'uri': uri,
        if (payload != null) 'payload': payload,
      });

  // Pointer-socket button event (real transport is the getPointerInputSocket
  // channel; flagged for Phase 0).
  String _buttonFrame(String name) => 'type:button\nname:$name\n\n';

  Future<CommandResult> _send(String frame) async {
    if (!_ch.isOpen) {
      return const CommandResult.failure('webos channel not connected');
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
