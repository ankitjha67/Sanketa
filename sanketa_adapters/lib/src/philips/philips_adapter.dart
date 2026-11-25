/// Philips TV adapter over JointSpace REST API.
///
/// JointSpace is a REST surface on port 1925 (HTTP, API v5/v6) or 1926
/// (HTTPS with digest auth on 2016+ models). Key presses travel as POST to
/// /input/key, volume as GET/PUT on /audio/volume, and app launch via
/// POST /activities/launch.
///
/// Pairing on 2016+ models uses a Philips-proprietary digest challenge: the
/// TV displays a PIN, the phone sends it with a device_id+device_name pair.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

class PhilipsAdapter extends ControlAdapter {
  PhilipsAdapter({
    required String host,
    int port = 1925,
    bool https = false,
    String? authToken,
    http.Client? client,
  })  : _base = '${https ? 'https' : 'http'}://$host:$port/6',
        _token = authToken,
        _client = client ?? http.Client();

  final String _base;
  String? _token;
  final http.Client _client;

  static const Map<Key, String> _keyMap = {
    Key.power: 'Standby',
    Key.powerOn: 'Standby',
    Key.powerOff: 'Standby',
    Key.volumeUp: 'VolumeUp',
    Key.volumeDown: 'VolumeDown',
    Key.mute: 'Mute',
    Key.up: 'CursorUp',
    Key.down: 'CursorDown',
    Key.left: 'CursorLeft',
    Key.right: 'CursorRight',
    Key.ok: 'Confirm',
    Key.back: 'Back',
    Key.home: 'Home',
    Key.menu: 'Options',
    Key.play: 'Play',
    Key.pause: 'Pause',
    Key.playPause: 'PlayPause',
    Key.rewind: 'Rewind',
    Key.fastForward: 'FastForward',
    Key.stop: 'Stop',
    Key.channelUp: 'ChannelStepUp',
    Key.channelDown: 'ChannelStepDown',
    Key.info: 'Info',
    Key.exit: 'Exit',
    Key.red: 'RedColour',
    Key.green: 'GreenColour',
    Key.yellow: 'YellowColour',
    Key.blue: 'BlueColour',
    Key.digit0: 'Digit0',
    Key.digit1: 'Digit1',
    Key.digit2: 'Digit2',
    Key.digit3: 'Digit3',
    Key.digit4: 'Digit4',
    Key.digit5: 'Digit5',
    Key.digit6: 'Digit6',
    Key.digit7: 'Digit7',
    Key.digit8: 'Digit8',
    Key.digit9: 'Digit9',
    Key.source: 'Source',
    Key.subtitle: 'SubtitlesOSD',
    Key.teletext: 'Teletext',
  };

  @override
  String get id => 'philips';

  @override
  BrandFamily get brandFamily => BrandFamily.philips;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:schemas-upnp-org:device:Basic:1'],
        probePorts: [1925, 1926],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _keyMap.keys.toSet(),
        textMode: TextInjectionMode.none,
        wake: false,
        volumeReadback: true,
        appLaunch: true,
        inputList: false,
        stateReadback: true,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      // JointSpace v5 (pre-2016) has no auth — a 200 from /system confirms.
      final res = await _client.get(_uri('/system'));
      if (res.statusCode == 200) {
        return const PairingResult.paired('philips:no-auth');
      }

      // 2016+ models need digest auth. Start pairing.
      context.notify?.call('Enter the PIN shown on your TV');
      final initRes = await _post('/pair/request', {
        'scope': ['read', 'write', 'control'],
        'device': {
          'device_name': 'Sanketa',
          'device_os': 'Android',
          'app_id': 'com.sanketa.remote',
          'app_name': 'Sanketa',
          'type': 'native',
          'id': 'sanketa_remote',
        },
      });
      if (initRes.statusCode != 200) {
        return const PairingResult.failed(
            'TV rejected the pairing request. Is JointSpace enabled?');
      }

      final pin = await context.requestPin?.call();
      if (pin == null || pin.isEmpty) {
        return const PairingResult.failed('No PIN entered.');
      }

      final grantRes = await _post('/pair/grant', {
        'auth': {
          'auth_AppId': '1',
          'pin': pin,
          'auth_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'auth_signature': 'default',
        },
        'device': {
          'device_name': 'Sanketa',
          'device_os': 'Android',
          'app_id': 'com.sanketa.remote',
          'app_name': 'Sanketa',
          'type': 'native',
          'id': 'sanketa_remote',
        },
      });
      if (grantRes.statusCode != 200) {
        return const PairingResult.failed(
            'Wrong PIN or pairing timed out. Try again.');
      }
      final body = _tryDecode(grantRes.body);
      final token = body?['auth_token'] as String?;
      if (token != null) _token = token;
      return PairingResult.paired(token ?? 'philips:paired');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> heartbeat() async {
    try {
      final res = await _client.get(_uri('/system'));
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final name = _keyMap[key];
    if (name == null) {
      return Future.value(
          CommandResult.failure('key not supported on Philips: ${key.name}'));
    }
    return _post('/input/key', {'key': name}).then(_toResult);
  }

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.failure('Philips JointSpace has no text input');

  @override
  Future<CommandResult> launchApp(AppRef app) =>
      _post('/activities/launch', {
        'intent': {
          'component': {
            'packageName': app.id,
            'className': app.id,
          },
          'action': 'Intent',
        },
      }).then(_toResult);

  @override
  Future<CommandResult> setInput(InputRef input) =>
      sendKey(Key.source);

  @override
  Future<CommandResult> power({required bool on}) =>
      sendKey(Key.power);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  @override
  Future<int?> getVolume() async {
    try {
      final res = await _client.get(_uri('/audio/volume'), headers: _headers);
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      return (json?['current'] as num?)?.toInt();
    } on Object {
      return null;
    }
  }

  @override
  Future<bool?> getMuted() async {
    try {
      final res = await _client.get(_uri('/audio/volume'), headers: _headers);
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      return json?['muted'] as bool?;
    } on Object {
      return null;
    }
  }

  @override
  Future<PowerState?> getPowerState() async {
    try {
      final res = await _client.get(_uri('/powerstate'), headers: _headers);
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      final state = json?['powerstate'] as String?;
      return state == 'On' ? PowerState.on : PowerState.standby;
    } on Object {
      return null;
    }
  }

  void close() => _client.close();

  // --- Internals ---

  Uri _uri(String path) => Uri.parse('$_base$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Basic $_token',
      };

  Future<http.Response> _post(String path, Map<String, Object?> body) =>
      _client.post(_uri(path), headers: _headers, body: jsonEncode(body));

  CommandResult _toResult(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return const CommandResult.success();
    }
    if (res.statusCode == 401) {
      return const CommandResult.failure(
          'Not authorized. Re-pair with the TV from the Devices screen.');
    }
    return CommandResult.failure('http ${res.statusCode}');
  }

  static Map<String, dynamic>? _tryDecode(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>?;
    } on Object {
      return null;
    }
  }
}
