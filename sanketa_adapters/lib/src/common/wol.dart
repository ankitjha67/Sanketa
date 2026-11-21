/// Wake-on-LAN magic packet builder (FR-3.3).
///
/// Constructs the 102-byte magic packet (6 × 0xFF header + 16 × MAC) that
/// wakes a network device from standby. The caller is responsible for sending
/// the bytes as a UDP broadcast on port 9 — this layer does not hold a socket
/// reference so it stays testable without network access.
library;

import 'dart:typed_data';

class WolPacket {
  /// Build a magic packet for [macAddress] (colon- or hyphen-separated hex).
  WolPacket(this.macAddress) : bytes = _build(macAddress);

  final String macAddress;

  /// The raw 102-byte magic packet, ready to broadcast on UDP port 9.
  final Uint8List bytes;

  /// Parse `AA:BB:CC:DD:EE:FF` or `AA-BB-CC-DD-EE-FF` into 6 bytes.
  static Uint8List parseMac(String mac) {
    final parts = mac.split(RegExp(r'[:\-]'));
    if (parts.length != 6) {
      throw FormatException('Invalid MAC address (expected 6 octets)', mac);
    }
    return Uint8List.fromList(
      parts.map((p) => int.parse(p, radix: 16)).toList(),
    );
  }

  static Uint8List _build(String mac) {
    final macBytes = parseMac(mac);
    final packet = Uint8List(102);
    for (var i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    for (var rep = 0; rep < 16; rep++) {
      packet.setRange(6 + rep * 6, 12 + rep * 6, macBytes);
    }
    return packet;
  }
}
