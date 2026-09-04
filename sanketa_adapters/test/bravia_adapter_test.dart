import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/bravia/bravia_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<({String path, String body, String? psk, String? soapAction})> reqs;
  late BraviaAdapter adapter;

  setUp(() async {
    reqs = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      reqs.add((
        path: req.uri.path,
        body: body,
        psk: req.headers.value('x-auth-psk'),
        soapAction: req.headers.value('soapaction'),
      ));
      req.response.statusCode = 200;
      await req.response.close();
    });
    adapter = BraviaAdapter(host: '127.0.0.1', port: server.port, psk: '1234');
  });

  tearDown(() => server.close(force: true));

  test('pair queries system info with the PSK header', () async {
    final res = await adapter.pair(const PairingContext());
    expect(res.isPaired, isTrue);
    expect(reqs.single.path, '/sony/system');
    expect(reqs.single.psk, '1234');
  });

  test('sendKey(ok) POSTs the OK IRCC code to /sony/IRCC', () async {
    await adapter.sendKey(Key.ok);
    final r = reqs.single;
    expect(r.path, '/sony/IRCC');
    expect(r.soapAction, contains('X_SendIRCC'));
    expect(r.body, contains('AAAAAQAAAAEAAABlAw==')); // documented OK code
    expect(r.psk, '1234');
  });

  test('power on/off use the PowerOn/PowerOff IRCC codes', () async {
    await adapter.power(on: true);
    await adapter.power(on: false);
    expect(reqs[0].body, contains('AAAAAQAAAAEAAAAuAw==')); // PowerOn
    expect(reqs[1].body, contains('AAAAAQAAAAEAAAAvAw==')); // PowerOff
  });

  test('text insert posts setTextForm to /sony/appControl', () async {
    await adapter.sendText(const TextOp.insert('hello'));
    final r = reqs.single;
    expect(r.path, '/sony/appControl');
    expect(r.body, contains('setTextForm'));
    expect(r.body, contains('"text":"hello"'));
  });

  test('unsupported key fails with nothing sent', () async {
    final res = await adapter.sendKey(Key.assistant);
    expect(res.ok, isFalse);
    expect(reqs, isEmpty);
  });

  test('capabilities: live text, network transport', () {
    final caps = adapter.capabilities();
    expect(caps.textMode, TextInjectionMode.live);
    expect(caps.supports(Key.up), isTrue);
  });
}
