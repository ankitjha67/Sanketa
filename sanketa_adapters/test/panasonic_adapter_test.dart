import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/panasonic/panasonic_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<String> requests;
  late List<String> bodies;
  late PanasonicAdapter adapter;

  setUp(() async {
    requests = <String>[];
    bodies = <String>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      final body = await utf8.decoder.bind(req).join();
      requests.add('${req.method} ${req.uri.path}');
      bodies.add(body);
      req.response.statusCode = 200;
      req.response.write('<?xml version="1.0"?><s:Envelope/>');
      await req.response.close();
    });
    adapter = PanasonicAdapter(
      host: '127.0.0.1',
      port: server.port,
    );
  });

  tearDown(() => server.close(force: true));

  test('id is panasonic and brand is panasonic', () {
    expect(adapter.id, 'panasonic');
    expect(adapter.brandFamily, BrandFamily.panasonic);
    expect(adapter.transport, Transport.network);
  });

  test('capabilities: volume readback, app launch, no text', () {
    final caps = adapter.capabilities();
    expect(caps.volumeReadback, isTrue);
    expect(caps.appLaunch, isTrue);
    expect(caps.textMode, TextInjectionMode.none);
    expect(caps.supports(Key.power), isTrue);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.volumeUp), isTrue);
  });

  test('heartbeat succeeds against reachable SOAP endpoint', () async {
    final ok = await adapter.heartbeat();
    expect(ok, isTrue);
    expect(requests, contains('POST /nrc/control_0'));
    expect(bodies.last, contains('X_GetVolume'));
  });

  test('sendKey(ok) posts SOAP with NRC_ENTER-ONOFF', () async {
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);
    expect(requests, contains('POST /nrc/control_0'));
    expect(bodies.last, contains('NRC_ENTER-ONOFF'));
    expect(bodies.last, contains('X_SendKey'));
  });

  test('sendKey(power) posts SOAP with NRC_POWER-ONOFF', () async {
    final res = await adapter.sendKey(Key.power);
    expect(res.ok, isTrue);
    expect(bodies.last, contains('NRC_POWER-ONOFF'));
  });

  test('sendKey(volumeUp) posts SOAP with NRC_VOLUP-ONOFF', () async {
    final res = await adapter.sendKey(Key.volumeUp);
    expect(res.ok, isTrue);
    expect(bodies.last, contains('NRC_VOLUP-ONOFF'));
  });

  test('launchApp posts SOAP with X_LaunchApp and product_id', () async {
    final res = await adapter.launchApp(const AppRef(id: 'netflix'));
    expect(res.ok, isTrue);
    expect(bodies.last, contains('X_LaunchApp'));
    expect(bodies.last, contains('product_id=netflix'));
  });

  test('sendText returns failure (no text input)', () async {
    final res = await adapter.sendText(const TextOp.insert('hello'));
    expect(res.ok, isFalse);
  });

  test('unsupported key returns failure', () async {
    final caps = adapter.capabilities();
    // Find a key NOT in the key map.
    final unsupported = Key.values.where((k) => !caps.supports(k)).toList();
    if (unsupported.isNotEmpty) {
      final res = await adapter.sendKey(unsupported.first);
      expect(res.ok, isFalse);
    }
  });

  test('SOAP envelope contains correct URN namespace', () async {
    await adapter.sendKey(Key.home);
    expect(bodies.last,
        contains('urn:panasonic-com:service:p00NetworkControl:1'));
  });

  test('discovery hints include port 55000', () {
    expect(adapter.discoveryHints.probePorts, contains(55000));
    expect(adapter.discoveryHints.ssdpTargets,
        contains('urn:panasonic-com:device:p00RemoteController:1'));
  });
}
