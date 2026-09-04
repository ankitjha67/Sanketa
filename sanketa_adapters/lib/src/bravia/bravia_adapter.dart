/// Sony BRAVIA (classic IP-control era) adapter — IRCC-IP over SOAP plus a REST
/// text form, authenticated with a pre-shared key (PSK). Modern Android-TV-era
/// BRAVIA sets route through the Android TV adapter instead (per §11).
///
/// Keys are documented IRCC base64 codes POSTed to `/sony/IRCC`; live text goes
/// to `/sony/appControl` `setTextForm`. Verified against a mock HTTP server; PSK
/// vs. PIN registration and the newer text-encryption path are Phase 0.
library;

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

const Map<Key, String> _ircc = {
  Key.power: 'AAAAAQAAAAEAAAAVAw==',
  Key.powerOn: 'AAAAAQAAAAEAAAAuAw==',
  Key.powerOff: 'AAAAAQAAAAEAAAAvAw==',
  Key.volumeUp: 'AAAAAQAAAAEAAAASAw==',
  Key.volumeDown: 'AAAAAQAAAAEAAAATAw==',
  Key.mute: 'AAAAAQAAAAEAAAAUAw==',
  Key.up: 'AAAAAQAAAAEAAAB0Aw==',
  Key.down: 'AAAAAQAAAAEAAAB1Aw==',
  Key.left: 'AAAAAQAAAAEAAAA0Aw==',
  Key.right: 'AAAAAQAAAAEAAAAzAw==',
  Key.ok: 'AAAAAQAAAAEAAABlAw==',
  Key.back: 'AAAAAgAAAJcAAAAjAw==',
  Key.home: 'AAAAAQAAAAEAAABgAw==',
  Key.channelUp: 'AAAAAQAAAAEAAAAQAw==',
  Key.channelDown: 'AAAAAQAAAAEAAAARAw==',
  Key.input: 'AAAAAQAAAAEAAAAlAw==',
  Key.play: 'AAAAAgAAAJcAAAAaAw==',
  Key.pause: 'AAAAAgAAAJcAAAAZAw==',
  Key.stop: 'AAAAAgAAAJcAAAAYAw==',
  Key.digit1: 'AAAAAQAAAAEAAAAAAw==',
  Key.digit2: 'AAAAAQAAAAEAAAABAw==',
  Key.digit3: 'AAAAAQAAAAEAAAACAw==',
  Key.digit4: 'AAAAAQAAAAEAAAADAw==',
  Key.digit5: 'AAAAAQAAAAEAAAAEAw==',
  Key.digit6: 'AAAAAQAAAAEAAAAFAw==',
  Key.digit7: 'AAAAAQAAAAEAAAAGAw==',
  Key.digit8: 'AAAAAQAAAAEAAAAHAw==',
  Key.digit9: 'AAAAAQAAAAEAAAAIAw==',
  Key.digit0: 'AAAAAQAAAAEAAAAJAw==',
};

class BraviaAdapter implements ControlAdapter {
  BraviaAdapter({
    required String host,
    int port = 80,
    required String psk,
    http.Client? client,
  })  : _base = 'http://$host:$port',
        _psk = psk,
        _client = client ?? http.Client();

  final String _base;
  final String _psk;
  final http.Client _client;

  @override
  String get id => 'bravia';

  @override
  BrandFamily get brandFamily => BrandFamily.bravia;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:schemas-sony-com:service:IRCC:1'],
        probePorts: [80, 20060],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _ircc.keys.toSet(),
        textMode: TextInjectionMode.live, // setTextForm
        wake: true, // WoL
        appLaunch: false,
        inputList: false,
        volumeReadback: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      final res = await _client.post(
        Uri.parse('$_base/sony/system'),
        headers: {'X-Auth-PSK': _psk, 'Content-Type': 'application/json'},
        body:
            '{"method":"getSystemInformation","version":"1.0","id":1,"params":[]}',
      );
      return res.statusCode == 200
          ? const PairingResult.paired('bravia:psk')
          : PairingResult.failed('system query returned ${res.statusCode}');
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
      final res = await _client.post(
        Uri.parse('$_base/sony/system'),
        headers: {'X-Auth-PSK': _psk, 'Content-Type': 'application/json'},
        body:
            '{"method":"getPowerStatus","version":"1.0","id":1,"params":[]}',
      );
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) async {
    final code = _ircc[key];
    if (code == null) {
      return CommandResult.failure('key not in BRAVIA IRCC set: ${key.name}');
    }
    final envelope = '<?xml version="1.0"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
        '<u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">'
        '<IRCCCode>$code</IRCCCode></u:X_SendIRCC></s:Body></s:Envelope>';
    final sw = Stopwatch()..start();
    try {
      final res = await _client.post(
        Uri.parse('$_base/sony/IRCC'),
        headers: {
          'X-Auth-PSK': _psk,
          'Content-Type': 'text/xml; charset=UTF-8',
          'SOAPACTION': '"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"',
        },
        body: envelope,
      );
      return res.statusCode >= 200 && res.statusCode < 300
          ? CommandResult.success(latency: sw.elapsed)
          : CommandResult.failure('http ${res.statusCode}');
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  @override
  Future<CommandResult> sendText(TextOp op) async {
    if (op.kind != TextOpKind.insert) {
      if (op.kind == TextOpKind.submit) return sendKey(Key.ok);
      return const CommandResult.failure('only insert/submit supported on BRAVIA text');
    }
    final body = '{"method":"setTextForm","version":"1.0","id":1,"params":'
        '[{"text":${_jsonString(op.text ?? '')}}]}';
    try {
      final res = await _client.post(
        Uri.parse('$_base/sony/appControl'),
        headers: {'X-Auth-PSK': _psk, 'Content-Type': 'application/json'},
        body: body,
      );
      return res.statusCode == 200
          ? const CommandResult.success()
          : CommandResult.failure('http ${res.statusCode}');
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.failure('app launch not implemented for BRAVIA yet');

  @override
  Future<CommandResult> setInput(InputRef input) => sendKey(Key.input);

  @override
  Future<CommandResult> power({required bool on}) =>
      sendKey(on ? Key.powerOn : Key.powerOff);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  // Minimal JSON string escaper for the text payload (never logged elsewhere).
  String _jsonString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n');
    return '"$escaped"';
  }
}
