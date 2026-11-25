import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sanketa_adapters/src/hisense/hisense_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late ServerSocket mqttServer;
  late List<Uint8List> received;
  late HisenseAdapter adapter;
  StreamSubscription<Socket>? serverSub;

  setUp(() async {
    received = <Uint8List>[];
    mqttServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    serverSub = mqttServer.listen((socket) {
      socket.listen((data) {
        received.add(Uint8List.fromList(data));
        // Reply CONNACK to any CONNECT (0x10).
        if (data.isNotEmpty && (data[0] & 0xF0) == 0x10) {
          socket.add(Uint8List.fromList([0x20, 0x02, 0x00, 0x00]));
        }
      });
    });
    adapter = HisenseAdapter(
      host: '127.0.0.1',
      port: mqttServer.port,
      macAddress: 'AA:BB:CC:DD:EE:FF',
    );
  });

  tearDown(() async {
    try {
      await adapter.disconnect();
    } on Object {
      // ignore
    }
    await serverSub?.cancel();
    await mqttServer.close();
  });

  test('id is hisense and brand is hisense', () {
    expect(adapter.id, 'hisense');
    expect(adapter.brandFamily, BrandFamily.hisense);
    expect(adapter.transport, Transport.network);
  });

  test('capabilities: app launch, no text, no volume readback', () {
    final caps = adapter.capabilities();
    expect(caps.appLaunch, isTrue);
    expect(caps.textMode, TextInjectionMode.none);
    expect(caps.volumeReadback, isFalse);
    expect(caps.supports(Key.power), isTrue);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.volumeUp), isTrue);
  });

  test('connect sends MQTT CONNECT and receives CONNACK', () async {
    await adapter.connect();
    expect(received, isNotEmpty);
    // First received packet should be CONNECT (0x10).
    expect(received.first[0] & 0xF0, 0x10);
  });

  test('sendKey publishes correct MQTT topic with keyNum', () async {
    await adapter.connect();
    received.clear();

    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);

    // Wait for the data to arrive.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Find the PUBLISH packet (0x30).
    final publishes = received.where((p) => p.isNotEmpty && (p[0] & 0xF0) == 0x30);
    expect(publishes, isNotEmpty);

    // The PUBLISH payload should contain the topic and JSON body.
    final allBytes = publishes.expand((p) => p).toList();
    final asString = String.fromCharCodes(allBytes);
    expect(asString, contains('sendkey'));
    expect(asString, contains('"keyNum":5')); // ok = 5
  });

  test('launchApp publishes correct MQTT topic', () async {
    await adapter.connect();
    received.clear();

    final res = await adapter.launchApp(const AppRef(id: 'netflix'));
    expect(res.ok, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final publishes = received.where((p) => p.isNotEmpty && (p[0] & 0xF0) == 0x30);
    expect(publishes, isNotEmpty);

    final asString = String.fromCharCodes(
        publishes.expand((p) => p).toList());
    expect(asString, contains('launchapp'));
    expect(asString, contains('netflix'));
  });

  test('heartbeat sends PINGREQ', () async {
    await adapter.connect();
    received.clear();

    final ok = await adapter.heartbeat();
    expect(ok, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // PINGREQ = 0xC0 0x00
    final pings = received.where(
        (p) => p.length >= 2 && p[0] == 0xC0 && p[1] == 0x00);
    expect(pings, isNotEmpty);
  });

  test('sendText returns failure', () async {
    await adapter.connect();
    final res = await adapter.sendText(const TextOp.insert('hello'));
    expect(res.ok, isFalse);
  });

  test('disconnect clears connection state', () async {
    await adapter.connect();
    await adapter.disconnect();
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isFalse);
  });

  test('discovery hints include VIDAA MQTT ports', () {
    expect(adapter.discoveryHints.probePorts, containsAll([36669, 36670]));
  });
}
