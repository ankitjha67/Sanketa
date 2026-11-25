/// Conformance suite — the identical script runs against every adapter
/// (PRD FR-3.1 AC: >= 95% of declared command set before an adapter ships).
///
/// Each adapter provides a factory that returns a connected adapter backed by a
/// fake server. The suite exercises the full ControlAdapter contract without
/// knowing anything about the brand underneath.
import 'dart:async';
import 'dart:io';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fake server factories — one per adapter
// ---------------------------------------------------------------------------

typedef AdapterFactory = Future<(ControlAdapter, Future<void> Function())>
    Function();

Future<(ControlAdapter, Future<void> Function())> _rokuFactory() async {
  final requests = <String>[];
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
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
  final adapter = RokuAdapter(host: '127.0.0.1', port: server.port);
  return (adapter as ControlAdapter, () async {
    await adapter.disconnect();
    await server.close(force: true);
  });
}

Future<(ControlAdapter, Future<void> Function())> _vizioFactory() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.json;
    req.response.write('{"STATUS":{"RESULT":"SUCCESS"}}');
    await req.response.close();
  });
  final adapter = VizioAdapter(
    host: '127.0.0.1',
    port: server.port,
    authToken: 'test',
    baseUrlOverride: 'http://127.0.0.1:${server.port}',
  );
  return (adapter as ControlAdapter, () async {
    await adapter.disconnect();
    await server.close(force: true);
  });
}

Future<(ControlAdapter, Future<void> Function())>
    _panasonicFactory() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.parse('text/xml');
    req.response.write(
      '<?xml version="1.0"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
      '<s:Body><u:X_SendKeyResponse xmlns:u="urn:panasonic-com:service:p00NetworkControl:1"/>'
      '</s:Body></s:Envelope>',
    );
    await req.response.close();
  });
  final adapter =
      PanasonicAdapter(host: '127.0.0.1', port: server.port);
  return (adapter as ControlAdapter, () async {
    await adapter.disconnect();
    await server.close(force: true);
  });
}

Future<(ControlAdapter, Future<void> Function())> _philipsFactory() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.json;
    req.response.write('{}');
    await req.response.close();
  });
  final adapter =
      PhilipsAdapter(host: '127.0.0.1', port: server.port);
  return (adapter as ControlAdapter, () async {
    await adapter.disconnect();
    await server.close(force: true);
  });
}

// ---------------------------------------------------------------------------
// Conformance runner
// ---------------------------------------------------------------------------

void runConformanceSuite(String name, AdapterFactory factory) {
  group('Conformance: $name', () {
    late ControlAdapter adapter;
    late Future<void> Function() cleanup;

    setUp(() async {
      final result = await factory();
      adapter = result.$1;
      cleanup = result.$2;
    });

    tearDown(() => cleanup());

    // -- Metadata --

    test('id is non-empty', () {
      expect(adapter.id, isNotEmpty);
    });

    test('brandFamily is a valid value', () {
      expect(BrandFamily.values, contains(adapter.brandFamily));
    });

    test('transport is a valid value', () {
      expect(Transport.values, contains(adapter.transport));
    });

    test('discoveryHints is populated', () {
      final h = adapter.discoveryHints;
      final hasAnything = h.mdnsServiceTypes.isNotEmpty ||
          h.ssdpTargets.isNotEmpty ||
          h.probePorts.isNotEmpty;
      expect(hasAnything, isTrue,
          reason: 'Adapter must declare at least one discovery hint');
    });

    // -- Capabilities --

    test('capabilities returns a valid map', () {
      final caps = adapter.capabilities();
      expect(caps.keys, isNotEmpty,
          reason: 'Adapter must support at least one key');
    });

    test('core navigation keys are declared', () {
      final caps = adapter.capabilities();
      final coreKeys = {Key.up, Key.down, Key.left, Key.right, Key.ok};
      final supported = coreKeys.intersection(caps.keys);
      expect(supported.length, greaterThanOrEqualTo(4),
          reason: 'Adapter should support at least 4 of 5 D-pad keys');
    });

    // -- Pairing --

    test('pair returns a valid result', () async {
      final result = await adapter.pair(const PairingContext());
      expect(result.status, isNotNull);
    });

    // -- Key dispatch coverage --

    test('>= 95% of declared keys dispatch without error', () async {
      final caps = adapter.capabilities();
      var passed = 0;
      var failed = 0;

      for (final key in caps.keys) {
        try {
          final result = await adapter.sendKey(key);
          if (result.ok) {
            passed++;
          } else {
            failed++;
          }
        } on Object {
          failed++;
        }
      }

      final total = passed + failed;
      final rate = total == 0 ? 0.0 : passed / total;
      expect(rate, greaterThanOrEqualTo(0.95),
          reason:
              'Key dispatch pass rate $passed/$total (${(rate * 100).toStringAsFixed(1)}%) '
              'must be >= 95%');
    });

    // -- Power --

    test('power on/off dispatches', () async {
      final caps = adapter.capabilities();
      if (caps.keys.contains(Key.power) ||
          caps.keys.contains(Key.powerOn) ||
          caps.keys.contains(Key.powerOff)) {
        final r1 = await adapter.power(on: true);
        expect(r1, isNotNull);
        final r2 = await adapter.power(on: false);
        expect(r2, isNotNull);
      }
    });

    // -- App launch --

    test('launchApp dispatches when appLaunch is true', () async {
      final caps = adapter.capabilities();
      if (caps.appLaunch) {
        final r = await adapter.launchApp(
            const AppRef(id: 'com.test.app', name: 'Test'));
        expect(r, isNotNull);
      }
    });

    // -- Text --

    test('sendText dispatches when canType is true', () async {
      final caps = adapter.capabilities();
      if (caps.canType) {
        final r = await adapter.sendText(const TextOp.insert('hello'));
        expect(r, isNotNull);
      }
    });

    // -- State stream --

    test('readState returns a stream', () {
      final stream = adapter.readState();
      expect(stream, isA<Stream<StateDelta>>());
    });

    // -- Heartbeat --

    test('heartbeat returns a boolean', () async {
      final alive = await adapter.heartbeat();
      expect(alive, isA<bool>());
    });
  });
}

// ---------------------------------------------------------------------------
// Run all adapters through the conformance suite
// ---------------------------------------------------------------------------

void main() {
  runConformanceSuite('Roku', _rokuFactory);
  runConformanceSuite('Vizio', _vizioFactory);
  runConformanceSuite('Panasonic', _panasonicFactory);
  runConformanceSuite('Philips', _philipsFactory);
}
