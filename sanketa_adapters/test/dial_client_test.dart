import 'dart:io';

import 'package:sanketa_adapters/src/dial/dial_client.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<({String method, String path})> reqs;
  late DialClient dial;

  setUp(() async {
    reqs = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      reqs.add((method: req.method, path: req.uri.path));
      if (req.method == 'POST') {
        req.response.statusCode = 201;
        req.response.headers.add(
            'Location', 'http://127.0.0.1:${server.port}/apps/YouTube/run');
      } else if (req.method == 'GET') {
        req.response.statusCode = 200;
      } else {
        req.response.statusCode = 200;
      }
      await req.response.close();
    });
    dial = DialClient(
        appsBaseUrl: Uri.parse('http://127.0.0.1:${server.port}/apps'));
  });

  tearDown(() => server.close(force: true));

  test('launch POSTs to /apps/<app> and returns the instance URL', () async {
    final res = await dial.launch('YouTube', body: 'v=dQw4w9WgXcQ');
    expect(res.ok, isTrue);
    expect(res.instanceUrl, endsWith('/apps/YouTube/run'));
    expect(reqs.single.method, 'POST');
    expect(reqs.single.path, '/apps/YouTube');
  });

  test('isAvailable GETs the app resource', () async {
    expect(await dial.isAvailable('Netflix'), isTrue);
    expect(reqs.single.method, 'GET');
    expect(reqs.single.path, '/apps/Netflix');
  });

  test('stop DELETEs the instance URL', () async {
    final res = await dial.stop('YouTube',
        instanceUrl: 'http://127.0.0.1:${server.port}/apps/YouTube/run');
    expect(res.ok, isTrue);
    expect(reqs.single.method, 'DELETE');
  });
}
