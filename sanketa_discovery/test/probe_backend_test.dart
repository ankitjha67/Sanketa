import 'dart:io';

import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_discovery/sanketa_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('emits an endpoint for an open port, nothing for a closed one', () async {
    // A real listener on an ephemeral loopback port stands in for a device.
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final openPort = server.port;

    final backend = ProbeBackend(
      [
        ProbeCandidate('127.0.0.1', openPort, searchTarget: 'roku:ecp'),
        const ProbeCandidate('127.0.0.1', 1), // reserved/closed → refused
      ],
      connectTimeout: const Duration(milliseconds: 300),
    );

    final found =
        await backend.search(const Duration(seconds: 2)).toList();

    expect(found, hasLength(1));
    expect(found.single.host, '127.0.0.1');
    expect(found.single.port, openPort);
    expect(found.single.source, DiscoverySource.probe);

    await server.close();
  });

  test('feeding a probe hit through the engine classifies it', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final engine = DiscoveryEngine(backends: [
      ProbeBackend([
        ProbeCandidate('127.0.0.1', server.port, server: 'Roku UPnP/1.0'),
      ]),
    ]);
    final result = await engine.scan(timeout: const Duration(seconds: 2));
    expect(result.devices, hasLength(1));
    expect(result.devices.single.device.brand, BrandFamily.roku);
    await server.close();
  });
}
