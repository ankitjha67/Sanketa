import 'dart:io';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

/// Spins up a loopback HTTP server that mimics Roku ECP: records every request
/// line and returns device-info XML for /query/device-info, 200 for everything
/// else. This lets the adapter be verified end-to-end with no physical Roku.
void main() {
  late HttpServer server;
  late List<String> requests; // e.g. "POST /keypress/Select"
  late RokuAdapter adapter;

  setUp(() async {
    requests = <String>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest req) async {
      requests.add('${req.method} ${req.uri.path}');
      if (req.uri.path == '/query/device-info') {
        req.response.headers.contentType = ContentType.parse('text/xml');
        req.response.write(
          '<device-info><power-mode>PowerOn</power-mode>'
          '<model-name>Roku Ultra</model-name></device-info>',
        );
      } else {
        req.response.statusCode = 200;
      }
      await req.response.close();
    });
    adapter = RokuAdapter(host: '127.0.0.1', port: server.port);
  });

  tearDown(() async {
    adapter.close();
    await server.close(force: true);
  });

  test('pair succeeds against a reachable ECP endpoint', () async {
    final res = await adapter.pair(const PairingContext());
    expect(res.isPaired, isTrue);
    expect(res.credential, 'roku:no-auth');
    expect(requests, contains('GET /query/device-info'));
  });

  test('heartbeat is true when device-info answers 200', () async {
    expect(await adapter.heartbeat(), isTrue);
  });

  test('sendKey(ok) maps to POST /keypress/Select', () async {
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);
    expect(res.latency, isNotNull); // latency instrumented (NFR-1/2)
    expect(requests, contains('POST /keypress/Select'));
  });

  test('hold maps to keydown then keyup', () async {
    await adapter.sendKey(Key.volumeUp, press: PressType.holdStart);
    await adapter.sendKey(Key.volumeUp, press: PressType.holdEnd);
    expect(
      requests,
      containsAll(<String>['POST /keydown/VolumeUp', 'POST /keyup/VolumeUp']),
    );
  });

  test('unsupported key fails gracefully and sends nothing', () async {
    final res = await adapter.sendKey(Key.digit5);
    expect(res.ok, isFalse);
    expect(res.error, contains('unsupported'));
    expect(requests, isEmpty);
  });

  test('live text injection sends one Lit_ per character, in order', () async {
    final res = await adapter.sendText(const TextOp.insert('Hi!'));
    expect(res.ok, isTrue);
    // Server decodes %21 back to '!', so the recorded path is Lit_!
    expect(
      requests,
      containsAllInOrder(<String>[
        'POST /keypress/Lit_H',
        'POST /keypress/Lit_i',
        'POST /keypress/Lit_!',
      ]),
    );
  });

  test('delete issues N backspaces', () async {
    await adapter.sendText(const TextOp.delete(3));
    final backspaces =
        requests.where((r) => r == 'POST /keypress/Backspace').length;
    expect(backspaces, 3);
  });

  test('submit sends Enter', () async {
    await adapter.sendText(const TextOp.submit());
    expect(requests, contains('POST /keypress/Enter'));
  });

  test('launchApp posts to /launch/<id>', () async {
    await adapter.launchApp(const AppRef(id: '837', name: 'YouTube'));
    expect(requests, contains('POST /launch/837'));
  });

  test('setInput maps hdmi1 -> InputHDMI1 (case-insensitive)', () async {
    await adapter.setInput(const InputRef(id: 'HDMI1'));
    expect(requests, contains('POST /keypress/InputHDMI1'));
  });

  test('unknown input fails without sending', () async {
    final res = await adapter.setInput(const InputRef(id: 'scart'));
    expect(res.ok, isFalse);
    expect(requests, isEmpty);
  });

  test('power on/off map to PowerOn/PowerOff keypresses', () async {
    await adapter.power(on: true);
    await adapter.power(on: false);
    expect(
      requests,
      containsAll(
          <String>['POST /keypress/PowerOn', 'POST /keypress/PowerOff']),
    );
  });

  test('capabilities: live text, app launch, no volume readback', () {
    final caps = adapter.capabilities();
    expect(caps.textMode, TextInjectionMode.live);
    expect(caps.canType, isTrue);
    expect(caps.appLaunch, isTrue);
    expect(caps.volumeReadback, isFalse);
    expect(caps.stateReadback, isTrue);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.digit5), isFalse);
  });

  test('readState is an empty stream for a write-only target', () async {
    expect(await adapter.readState().toList(), isEmpty);
  });

  test('failure surfaces as CommandResult, not an exception', () async {
    // Point at a dead port to force a connection error.
    final dead = RokuAdapter(host: '127.0.0.1', port: 1);
    final res = await dead.sendKey(Key.home);
    expect(res.ok, isFalse);
    expect(res.error, isNotNull);
    dead.close();
  });
}
