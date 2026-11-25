/// Vizio SmartCast adapter — JSON over HTTPS on port 7345/9000.
///
/// SmartCast exposes a REST API: keys travel as PUT /key_command with
/// CODESET/CODE pairs, volume as GET/PUT /menu_native/dynamic/tv_settings/audio,
/// and app launch via PUT /app/launch. Pairing is challenge-based: the TV shows
/// a PIN, the phone sends it with a pairing token request, and the TV returns an
/// auth token used on subsequent requests.
///
/// Reference: Vizio SmartCast API (reverse-engineered, widely documented).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

const Map<Key, (int codeset, int code)> _vizioKeys = {
  Key.power: (11, 0),
  Key.powerOn: (11, 1),
  Key.powerOff: (11, 0),
  Key.volumeUp: (5, 1),
  Key.volumeDown: (5, 0),
  Key.mute: (5, 3),
  Key.up: (3, 8),
  Key.down: (3, 2),
  Key.left: (3, 1),
  Key.right: (3, 7),
  Key.ok: (3, 5),
  Key.back: (4, 0),
  Key.home: (4, 3),
  Key.menu: (4, 8),
  Key.exit: (9, 0),
  Key.channelUp: (8, 1),
  Key.channelDown: (8, 0),
  Key.input: (7, 1),
  Key.play: (2, 3),
  Key.pause: (2, 2),
  Key.fastForward: (2, 0),
  Key.rewind: (2, 1),
  Key.info: (4, 6),
};

class VizioAdapter extends ControlAdapter {
  VizioAdapter({
    required String host,
    int port = 7345,
    String? authToken,
    http.Client? client,
    String? baseUrlOverride,
  })  : _base = baseUrlOverride ?? 'https://$host:$port',
        _token = authToken,
        _client = client ?? http.Client();

  final String _base;
  String? _token;
  final http.Client _client;

  @override
  String get id => 'vizio';

  @override
  BrandFamily get brandFamily => BrandFamily.vizio;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:dial-multiscreen-org:device:dial:1'],
        probePorts: [7345, 9000],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _vizioKeys.keys.toSet(),
        textMode: TextInjectionMode.none,
        wake: false,
        appLaunch: true,
        inputList: true,
        volumeReadback: true,
        stateReadback: true,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      // Step 1: initiate pairing — TV shows a PIN.
      final initRes = await _put('/pairing/start', {
        'DEVICE_ID': 'sanketa_remote',
        'DEVICE_NAME': 'Sanketa',
        'PAIRING_REQ_TOKEN': 0,
      });
      if (initRes.statusCode != 200) {
        return const PairingResult.failed(
            'TV rejected the pairing request. Is SmartCast enabled?');
      }
      final initData = _tryDecode(initRes.body);
      final challenge = initData?['ITEM']?['CHALLENGE_TYPE'] as int?;
      final pairingToken = initData?['ITEM']?['PAIRING_REQ_TOKEN'] as int?;

      if (challenge == null || pairingToken == null) {
        return const PairingResult.failed(
            'Unexpected pairing response from the TV.');
      }

      context.notify?.call('Enter the PIN shown on your TV');

      // Step 2: caller provides PIN via the pairing context.
      final pin = await context.requestPin?.call();
      if (pin == null || pin.isEmpty) {
        return const PairingResult.failed('No PIN entered.');
      }

      // Step 3: complete pairing with PIN.
      final finishRes = await _put('/pairing/pair', {
        'DEVICE_ID': 'sanketa_remote',
        'CHALLENGE_TYPE': challenge,
        'RESPONSE_VALUE': pin,
        'PAIRING_REQ_TOKEN': pairingToken,
      });
      if (finishRes.statusCode != 200) {
        return const PairingResult.failed(
            'Wrong PIN or pairing timed out. Try again.');
      }
      final finishData = _tryDecode(finishRes.body);
      final token = finishData?['ITEM']?['AUTH_TOKEN'] as String?;
      if (token == null) {
        return const PairingResult.failed(
            'Pairing succeeded but no token returned.');
      }
      _token = token;
      return PairingResult.paired(token);
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
      final res = await _get('/state/device/power_mode');
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final mapped = _vizioKeys[key];
    if (mapped == null) {
      return Future.value(
          CommandResult.failure('key not supported on vizio: ${key.name}'));
    }
    final (codeset, code) = mapped;
    return _keyCommand(codeset, code);
  }

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.failure('Vizio SmartCast has no text input');

  @override
  Future<CommandResult> launchApp(AppRef app) async {
    final sw = Stopwatch()..start();
    try {
      final res = await _put('/app/launch', {
        'VALUE': {
          'MESSAGE': null,
          'NAME_SPACE': app.id.contains('.') ? 4 : 3,
          'APP_ID': app.id,
        },
      });
      return _result(res, sw);
    } on Object {
      return const CommandResult.failure(
          'Could not reach the TV. Check that it is powered on.');
    }
  }

  @override
  Future<CommandResult> setInput(InputRef input) async {
    final sw = Stopwatch()..start();
    try {
      final res = await _put(
        '/menu_native/dynamic/tv_settings/devices/current_input',
        {'REQUEST': 'MODIFY', 'VALUE': input.id, 'HASHVAL': 0},
      );
      return _result(res, sw);
    } on Object {
      return const CommandResult.failure(
          'Could not reach the TV. Check that it is powered on.');
    }
  }

  @override
  Future<CommandResult> power({required bool on}) =>
      sendKey(on ? Key.powerOn : Key.powerOff);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  @override
  Future<int?> getVolume() async {
    try {
      final res =
          await _get('/menu_native/dynamic/tv_settings/audio/volume');
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      final items = json?['ITEMS'] as List?;
      if (items == null || items.isEmpty) return null;
      return ((items.first as Map)['VALUE'] as num?)?.toInt();
    } on Object {
      return null;
    }
  }

  @override
  Future<bool?> getMuted() async {
    try {
      final res =
          await _get('/menu_native/dynamic/tv_settings/audio/mute');
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      final items = json?['ITEMS'] as List?;
      if (items == null || items.isEmpty) return null;
      final val = (items.first as Map)['VALUE'] as String?;
      return val == 'On';
    } on Object {
      return null;
    }
  }

  @override
  Future<PowerState?> getPowerState() async {
    try {
      final res = await _get('/state/device/power_mode');
      if (res.statusCode != 200) return null;
      final json = _tryDecode(res.body);
      final items = json?['ITEMS'] as List?;
      if (items == null || items.isEmpty) return null;
      final val = ((items.first as Map)['VALUE'] as num?)?.toInt();
      return val == 1 ? PowerState.on : PowerState.standby;
    } on Object {
      return null;
    }
  }

  Future<CommandResult> _keyCommand(int codeset, int code) async {
    final sw = Stopwatch()..start();
    try {
      final res = await _put('/key_command/', {
        'KEYLIST': [
          {'CODESET': codeset, 'CODE': code, 'ACTION': 'KEYPRESS'},
        ],
      });
      return _result(res, sw);
    } on Object {
      return const CommandResult.failure(
          'Could not reach the TV. Check that it is powered on and connected to WiFi.');
    }
  }

  CommandResult _result(http.Response res, Stopwatch sw) {
    sw.stop();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CommandResult.success(latency: sw.elapsed);
    }
    if (res.statusCode == 403) {
      return const CommandResult.failure(
          'Not authorized. Re-pair with the TV from the Devices screen.');
    }
    return const CommandResult.failure(
        'The TV returned an error. It may not support this action.');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'AUTH': _token!,
      };

  Future<http.Response> _put(String path, Map<String, Object?> body) =>
      _client.put(
        Uri.parse('$_base$path'),
        headers: _headers,
        body: jsonEncode(body),
      );

  Future<http.Response> _get(String path) =>
      _client.get(Uri.parse('$_base$path'), headers: _headers);

  static Map<String, dynamic>? _tryDecode(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>?;
    } on Object {
      return null;
    }
  }
}
