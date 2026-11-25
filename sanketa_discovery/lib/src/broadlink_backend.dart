/// BroadLink device discovery backend.
///
/// Discovers BroadLink RM WiFi-IR bridges on the LAN via their proprietary UDP
/// broadcast protocol (port 80). Self-contained: inlines the discovery packet
/// format and response parsing so this package has no dependency on
/// sanketa_adapters (avoiding a circular dep).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sanketa_core/sanketa_core.dart';

class BroadLinkBackend implements DiscoveryBackend {
  const BroadLinkBackend();

  @override
  DiscoverySource get source => DiscoverySource.probe;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final seen = <String>{};
    final controller = StreamController<DiscoveredEndpoint>();

    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null || dg.data.length < 0x40) return;
      try {
        final data = Uint8List.fromList(dg.data);
        final devType = data[0x34] | (data[0x35] << 8);
        final modelName = _classifyModel(devType);
        if (modelName == null) return;

        final mac = Uint8List(6);
        for (var i = 0; i < 6; i++) {
          mac[i] = data[0x3F - i];
        }
        final macStr =
            mac.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        if (!seen.add(macStr)) return;

        final nameEnd = data.indexOf(0, 0x40);
        final name = nameEnd > 0x40
            ? utf8.decode(data.sublist(0x40, nameEnd), allowMalformed: true)
            : null;

        if (!controller.isClosed) {
          controller.add(DiscoveredEndpoint(
            source: DiscoverySource.probe,
            host: dg.address.address,
            port: 80,
            friendlyName: name ?? modelName,
            attributes: {
              'broadlink': 'true',
              'broadlink_type': '0x${devType.toRadixString(16)}',
              'broadlink_model': modelName,
              'mac': macStr,
            },
          ));
        }
      } on Object {
        // Skip malformed responses.
      }
    });

    socket.send(_buildDiscoveryPacket(socket.port),
        InternetAddress('255.255.255.255'), 80);

    final timer = Timer(timeout, () {
      if (!controller.isClosed) controller.close();
    });

    try {
      await for (final e in controller.stream) {
        yield e;
      }
    } finally {
      timer.cancel();
      await sub.cancel();
      socket.close();
    }
  }
}

/// Build the BroadLink LAN discovery broadcast packet.
Uint8List _buildDiscoveryPacket(int sourcePort) {
  final now = DateTime.now();
  final packet = Uint8List(0x30);

  final offset = now.timeZoneOffset.inSeconds;
  packet[0x08] = offset & 0xFF;
  packet[0x09] = (offset >> 8) & 0xFF;
  packet[0x0A] = (offset >> 16) & 0xFF;
  packet[0x0B] = (offset >> 24) & 0xFF;

  packet[0x0C] = now.year & 0xFF;
  packet[0x0D] = (now.year >> 8) & 0xFF;
  packet[0x0E] = now.second;
  packet[0x0F] = now.minute;
  packet[0x10] = now.hour;
  packet[0x11] = now.weekday % 7;
  packet[0x12] = now.day;
  packet[0x13] = now.month;

  packet[0x1C] = sourcePort & 0xFF;
  packet[0x1D] = (sourcePort >> 8) & 0xFF;

  packet[0x26] = 0x06;

  var cs = 0xBEAF;
  for (final b in packet) {
    cs = (cs + b) & 0xFFFF;
  }
  packet[0x20] = cs & 0xFF;
  packet[0x21] = (cs >> 8) & 0xFF;

  return packet;
}

/// Classify a BroadLink device type code into a human-readable model name.
/// Returns null for non-RM devices (we only care about IR bridges).
String? _classifyModel(int code) {
  const mini3 = {
    0x2737, 0x278F, 0x27B7, 0x27C2, 0x27C7, 0x27CC, 0x27CD, 0x27D0,
    0x27D1, 0x27D3, 0x27DC, 0x27DE,
  };
  const mini3b = {0x5F36, 0x6507, 0x6508};
  const pro = {
    0x2712, 0x272A, 0x273D, 0x277C, 0x2783, 0x2787, 0x278B, 0x2797,
    0x279D, 0x27A1, 0x27A6, 0x27A9, 0x27C3,
  };
  const rm4mini = {
    0x51DA, 0x5209, 0x520C, 0x520D, 0x5211, 0x5212, 0x5216, 0x521C,
    0x6070, 0x610E, 0x610F, 0x62BC, 0x62BE, 0x6364, 0x648D, 0x6539,
    0x653A,
  };
  const rm4pro = {
    0x520B, 0x5213, 0x5218, 0x6026, 0x6184, 0x61A2, 0x649B, 0x653C,
  };

  if (mini3.contains(code) || mini3b.contains(code)) {
    return 'BroadLink RM Mini 3';
  }
  if (pro.contains(code)) return 'BroadLink RM Pro';
  if (rm4mini.contains(code)) return 'BroadLink RM4 Mini';
  if (rm4pro.contains(code)) return 'BroadLink RM4 Pro';
  return null;
}
