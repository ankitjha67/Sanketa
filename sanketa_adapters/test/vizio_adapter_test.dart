import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/vizio/vizio_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<String> requests;
  late VizioAdapter adapter;

  setUp(() async {
    requests = <String>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      await utf8.decoder.bind(req).join();
      requests.add('${req.method} ${req.uri.path}');
      req.response.headers.contentType = ContentType.json;
      if (req.uri.path == '/state/device/power_mode') {
        req.response.write(
            '{"STATUS":{"RESULT":"SUCCESS"},"ITEMS":[{"VALUE":1}]}');
      } else if (req.uri.path == '/key_command/') {
        req.response.write('{"STATUS":{"RESULT":"SUCCESS"}}');
      } else if (req.uri.path == '/app/launch') {
        req.response.write('{"STATUS":{"RESULT":"SUCCESS"}}');
      } else {
        req.response.statusCode = 200;
        req.response.write('{"STATUS":{"RESULT":"SUCCESS"}}');
      }
      await req.response.close();
    });
    adapter = VizioAdapter(
      host: '127.0.0.1',
      authToken: 'test-token',
      baseUrlOverride: 'http://127.0.0.1:${server.port}',
    );
  });

  tearDown(() => server.close(force: true));

  test('id is vizio and brand is vizio', () {
    expect(adapter.id, 'vizio');
    expect(adapter.brandFamily, BrandFamily.vizio);
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

  test('heartbeat succeeds against reachable endpoint', () async {
    final ok = await adapter.heartbeat();
    expect(ok, isTrue);
    expect(requests, contains('GET /state/device/power_mode'));
  });

  test('sendKey(ok) posts to /key_command/', () async {
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);
    expect(requests, contains('PUT /key_command/'));
  });

  test('sendKey(power) posts to /key_command/', () async {
    final res = await adapter.sendKey(Key.power);
    expect(res.ok, isTrue);
    expect(requests, contains('PUT /key_command/'));
  });

  test('launchApp posts to /app/launch', () async {
    final res = await adapter.launchApp(const AppRef(id: 'netflix'));
    expect(res.ok, isTrue);
    expect(requests, contains('PUT /app/launch'));
  });

  test('sendText always fails (no text input)', () async {
    final res = await adapter.sendText(const TextOp.insert('hi'));
    expect(res.ok, isFalse);
  });

  test('unsupported key fails', () async {
    final res = await adapter.sendKey(Key.assistant);
    expect(res.ok, isFalse);
  });

  test('discoveryHints include SmartCast ports', () {
    expect(adapter.discoveryHints.probePorts, contains(7345));
    expect(adapter.discoveryHints.probePorts, contains(9000));
  });
}
