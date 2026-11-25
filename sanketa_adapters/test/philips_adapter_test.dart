import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/philips/philips_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<String> requests;
  late List<String> bodies;
  late PhilipsAdapter adapter;

  setUp(() async {
    requests = <String>[];
    bodies = <String>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      final body = await utf8.decoder.bind(req).join();
      requests.add('${req.method} ${req.uri.path}');
      bodies.add(body);
      req.response.headers.contentType = ContentType.json;
      if (req.uri.path == '/6/system') {
        req.response
            .write('{"menulanguage":"English","country":"Netherlands"}');
      } else if (req.uri.path == '/6/audio/volume') {
        req.response.write('{"muted":false,"current":25,"min":0,"max":60}');
      } else {
        req.response.write('{}');
      }
      await req.response.close();
    });
    adapter = PhilipsAdapter(
      host: '127.0.0.1',
      port: server.port,
    );
  });

  tearDown(() => server.close(force: true));

  test('id is philips and brand is philips', () {
    expect(adapter.id, 'philips');
    expect(adapter.brandFamily, BrandFamily.philips);
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
    expect(caps.supports(Key.red), isTrue);
  });

  test('heartbeat succeeds against reachable endpoint', () async {
    final ok = await adapter.heartbeat();
    expect(ok, isTrue);
    expect(requests, contains('GET /6/system'));
  });

  test('sendKey(ok) posts Confirm to /6/input/key', () async {
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);
    expect(requests, contains('POST /6/input/key'));
    final sent = jsonDecode(bodies.last) as Map<String, dynamic>;
    expect(sent['key'], 'Confirm');
  });

  test('sendKey(power) sends Standby', () async {
    final res = await adapter.sendKey(Key.power);
    expect(res.ok, isTrue);
    final sent = jsonDecode(bodies.last) as Map<String, dynamic>;
    expect(sent['key'], 'Standby');
  });

  test('sendKey(volumeDown) sends VolumeDown', () async {
    final res = await adapter.sendKey(Key.volumeDown);
    expect(res.ok, isTrue);
    final sent = jsonDecode(bodies.last) as Map<String, dynamic>;
    expect(sent['key'], 'VolumeDown');
  });

  test('launchApp posts to /6/activities/launch', () async {
    final res = await adapter.launchApp(const AppRef(id: 'com.netflix'));
    expect(res.ok, isTrue);
    expect(requests, contains('POST /6/activities/launch'));
    final sent = jsonDecode(bodies.last) as Map<String, dynamic>;
    expect(sent['intent'], isNotNull);
  });

  test('sendText returns failure (no text input)', () async {
    final res = await adapter.sendText(const TextOp.insert('hello'));
    expect(res.ok, isFalse);
  });

  test('unsupported key returns failure', () async {
    final caps = adapter.capabilities();
    final unsupported = Key.values.where((k) => !caps.supports(k)).toList();
    if (unsupported.isNotEmpty) {
      final res = await adapter.sendKey(unsupported.first);
      expect(res.ok, isFalse);
    }
  });

  test('discovery hints include JointSpace ports', () {
    expect(adapter.discoveryHints.probePorts, containsAll([1925, 1926]));
  });
}
