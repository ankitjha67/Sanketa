/// Panasonic Viera adapter over the SOAP / HTTP control protocol.
///
/// Viera TVs (2012+) expose a SOAP endpoint on port 55000. Key presses
/// travel as X_SendKey commands, volume as X_GetVolume/X_SetVolume, and app
/// launch via X_LaunchApp. No authentication on most models; some 2019+
/// models use a PIN-based pairing flow over the same SOAP interface.
library;

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

class PanasonicAdapter implements ControlAdapter {
  PanasonicAdapter({
    required String host,
    int port = 55000,
    http.Client? client,
  })  : _host = host,
        _port = port,
        _client = client ?? http.Client();

  final String _host;
  final int _port;
  final http.Client _client;

  static const Map<Key, String> _keyMap = {
    Key.power: 'NRC_POWER-ONOFF',
    Key.powerOn: 'NRC_POWER-ONOFF',
    Key.powerOff: 'NRC_POWER-ONOFF',
    Key.volumeUp: 'NRC_VOLUP-ONOFF',
    Key.volumeDown: 'NRC_VOLDOWN-ONOFF',
    Key.mute: 'NRC_MUTE-ONOFF',
    Key.up: 'NRC_UP-ONOFF',
    Key.down: 'NRC_DOWN-ONOFF',
    Key.left: 'NRC_LEFT-ONOFF',
    Key.right: 'NRC_RIGHT-ONOFF',
    Key.ok: 'NRC_ENTER-ONOFF',
    Key.back: 'NRC_RETURN-ONOFF',
    Key.home: 'NRC_HOME-ONOFF',
    Key.menu: 'NRC_MENU-ONOFF',
    Key.play: 'NRC_PLAY-ONOFF',
    Key.pause: 'NRC_PAUSE-ONOFF',
    Key.playPause: 'NRC_PLAY-ONOFF',
    Key.rewind: 'NRC_REW-ONOFF',
    Key.fastForward: 'NRC_FF-ONOFF',
    Key.stop: 'NRC_STOP-ONOFF',
    Key.channelUp: 'NRC_CH_UP-ONOFF',
    Key.channelDown: 'NRC_CH_DOWN-ONOFF',
    Key.info: 'NRC_INFO-ONOFF',
    Key.exit: 'NRC_CANCEL-ONOFF',
    Key.guide: 'NRC_EPG-ONOFF',
    Key.red: 'NRC_RED-ONOFF',
    Key.green: 'NRC_GREEN-ONOFF',
    Key.yellow: 'NRC_YELLOW-ONOFF',
    Key.blue: 'NRC_BLUE-ONOFF',
    Key.digit0: 'NRC_D0-ONOFF',
    Key.digit1: 'NRC_D1-ONOFF',
    Key.digit2: 'NRC_D2-ONOFF',
    Key.digit3: 'NRC_D3-ONOFF',
    Key.digit4: 'NRC_D4-ONOFF',
    Key.digit5: 'NRC_D5-ONOFF',
    Key.digit6: 'NRC_D6-ONOFF',
    Key.digit7: 'NRC_D7-ONOFF',
    Key.digit8: 'NRC_D8-ONOFF',
    Key.digit9: 'NRC_D9-ONOFF',
    Key.input: 'NRC_CHG_INPUT-ONOFF',
    Key.subtitle: 'NRC_STTL-ONOFF',
    Key.teletext: 'NRC_TEXT-ONOFF',
  };

  @override
  String get id => 'panasonic';

  @override
  BrandFamily get brandFamily => BrandFamily.panasonic;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:panasonic-com:device:p00RemoteController:1'],
        probePorts: [55000],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _keyMap.keys.toSet(),
        textMode: TextInjectionMode.none,
        wake: false,
        volumeReadback: true,
        appLaunch: true,
        inputList: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      // Most Viera TVs accept commands without auth. Try a volume query.
      final res = await _soapAction('Get', 'X_GetVolume', '');
      if (res.statusCode == 200) {
        return const PairingResult.paired('panasonic:no-auth');
      }

      // 2019+ models need PIN pairing.
      context.notify?.call('Enter the PIN shown on your TV');

      final reqRes = await _soapAction(
        'Post',
        'X_DisplayPinCode',
        '<X_DeviceName>Sanketa</X_DeviceName>',
      );
      if (reqRes.statusCode != 200) {
        return const PairingResult.failed(
            'TV did not show a PIN. Ensure network control is enabled in the TV settings.');
      }

      final pin = await context.requestPin?.call();
      if (pin == null || pin.isEmpty) {
        return const PairingResult.failed('No PIN entered.');
      }

      final authRes = await _soapAction(
        'Post',
        'X_RequestAuth',
        '<X_PinCode>$pin</X_PinCode>',
      );
      if (authRes.statusCode != 200) {
        return const PairingResult.failed(
            'Wrong PIN or pairing timed out. Try again.');
      }
      return const PairingResult.paired('panasonic:paired');
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
      final res = await _soapAction('Get', 'X_GetVolume', '');
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
          CommandResult.failure('key not supported on Panasonic: ${key.name}'));
    }
    return _soapAction(
      'Post',
      'X_SendKey',
      '<X_KeyEvent>$name</X_KeyEvent>',
    ).then(_toResult);
  }

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.failure('Panasonic Viera has no text input');

  @override
  Future<CommandResult> launchApp(AppRef app) => _soapAction(
        'Post',
        'X_LaunchApp',
        '<X_AppType>vc_app</X_AppType>'
        '<X_LaunchKeyword>product_id=${app.id}</X_LaunchKeyword>',
      ).then(_toResult);

  @override
  Future<CommandResult> setInput(InputRef input) =>
      sendKey(Key.input);

  @override
  Future<CommandResult> power({required bool on}) =>
      sendKey(Key.power);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  void close() => _client.close();

  // --- SOAP helpers ---

  static const _urnNrc = 'urn:panasonic-com:service:p00NetworkControl:1';

  Future<http.Response> _soapAction(
    String method,
    String action,
    String body,
  ) {
    final envelope = '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"'
        ' s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:$action xmlns:u="$_urnNrc">$body</u:$action>'
        '</s:Body></s:Envelope>';

    return _client.post(
      Uri.parse('http://$_host:$_port/nrc/control_0'),
      headers: {
        'Content-Type': 'text/xml; charset="utf-8"',
        'SOAPAction': '"$_urnNrc#$action"',
      },
      body: envelope,
    );
  }

  CommandResult _toResult(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return const CommandResult.success();
    }
    if (res.statusCode == 403) {
      return const CommandResult.failure(
          'Not authorized. Re-pair with the TV from the Devices screen.');
    }
    return const CommandResult.failure(
        'The TV returned an error. It may be powered off or unreachable.');
  }
}
