/// BroadLink RM local UDP protocol — discovery, auth, IR send, and IR learn.
///
/// Implements the BroadLink LAN protocol (based on
/// python-broadlink by mjg59). All communication is UDP on port 80 with
/// AES-128-CBC encrypted payloads. Fully local — no cloud dependency (NFR-8).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Known BroadLink RM device type codes.
enum BroadLinkModel {
  rmMini3,
  rmPro,
  rm4Mini,
  rm4Pro,
}

BroadLinkModel? classifyDeviceType(int code) {
  const mini3 = {
    0x2737, 0x278F, 0x27B7, 0x27C2, 0x27C7, 0x27CC, 0x27CD, 0x27D0,
    0x27D1, 0x27D3, 0x27DC, 0x27DE,
  };
  const pro = {
    0x2712, 0x272A, 0x273D, 0x277C, 0x2783, 0x2787, 0x278B, 0x2797,
    0x279D, 0x27A1, 0x27A6, 0x27A9, 0x27C3,
  };
  const mini3b = {0x5F36, 0x6507, 0x6508};
  const rm4mini = {
    0x51DA, 0x5209, 0x520C, 0x520D, 0x5211, 0x5212, 0x5216, 0x521C,
    0x6070, 0x610E, 0x610F, 0x62BC, 0x62BE, 0x6364, 0x648D, 0x6539,
    0x653A,
  };
  const rm4pro = {
    0x520B, 0x5213, 0x5218, 0x6026, 0x6184, 0x61A2, 0x649B, 0x653C,
  };

  if (mini3.contains(code) || mini3b.contains(code)) {
    return BroadLinkModel.rmMini3;
  }
  if (pro.contains(code)) return BroadLinkModel.rmPro;
  if (rm4mini.contains(code)) return BroadLinkModel.rm4Mini;
  if (rm4pro.contains(code)) return BroadLinkModel.rm4Pro;
  return null;
}

bool _isRm4(BroadLinkModel m) =>
    m == BroadLinkModel.rm4Mini || m == BroadLinkModel.rm4Pro;

/// A discovered BroadLink device on the LAN.
class BroadLinkDevice {
  BroadLinkDevice({
    required this.host,
    required this.mac,
    required this.deviceType,
    required this.model,
    this.name,
    this.isLocked = false,
  });

  final String host;
  final Uint8List mac; // 6 bytes
  final int deviceType;
  final BroadLinkModel model;
  final String? name;
  final bool isLocked;
}

/// Session with an authenticated BroadLink device.
class BroadLinkSession {
  BroadLinkSession._({
    required this.device,
    required this.socket,
    required this.key,
    required this.deviceId,
  }) : _counter = 0x8000 + Random().nextInt(0x7FFF);

  final BroadLinkDevice device;
  final RawDatagramSocket socket;
  Uint8List key;
  int deviceId;
  int _counter;

  static const _iv = <int>[
    0x56, 0x2E, 0x17, 0x99, 0x6D, 0x09, 0x3D, 0x28,
    0xDD, 0xB3, 0xBA, 0x69, 0x5A, 0x2E, 0x6F, 0x58,
  ];

  static final _initialKey = Uint8List.fromList([
    0x09, 0x76, 0x28, 0x34, 0x3F, 0xE9, 0x9E, 0x23,
    0x76, 0x5C, 0x15, 0x13, 0xAC, 0xCF, 0x8B, 0x02,
  ]);

  /// Discover BroadLink devices on the LAN.
  static Stream<BroadLinkDevice> discover(Duration timeout) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final seen = <String>{};
    final controller = StreamController<BroadLinkDevice>();

    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null || dg.data.length < 0x40) return;
      try {
        final data = Uint8List.fromList(dg.data);
        final devType = data[0x34] | (data[0x35] << 8);
        final model = classifyDeviceType(devType);
        if (model == null) return;

        final mac = Uint8List(6);
        for (var i = 0; i < 6; i++) {
          mac[i] = data[0x3F - i];
        }
        final macStr = mac.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        if (!seen.add(macStr)) return;

        final nameEnd = data.indexOf(0, 0x40);
        final name = nameEnd > 0x40
            ? utf8.decode(data.sublist(0x40, nameEnd), allowMalformed: true)
            : null;

        if (!controller.isClosed) {
          controller.add(BroadLinkDevice(
            host: dg.address.address,
            mac: mac,
            deviceType: devType,
            model: model,
            name: name,
            isLocked: data[0x7F] != 0,
          ));
        }
      } on Object {
        // Skip malformed responses.
      }
    });

    // Build discovery packet.
    final packet = _buildDiscoveryPacket(socket.port);
    socket.send(packet, InternetAddress('255.255.255.255'), 80);

    final timer = Timer(timeout, () {
      if (!controller.isClosed) controller.close();
    });

    try {
      await for (final dev in controller.stream) {
        yield dev;
      }
    } finally {
      timer.cancel();
      await sub.cancel();
      socket.close();
    }
  }

  /// Authenticate with a device and get a session.
  static Future<BroadLinkSession> authenticate(BroadLinkDevice device) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final session = BroadLinkSession._(
      device: device,
      socket: socket,
      key: _initialKey,
      deviceId: 0,
    );

    // Build auth payload (0x50 bytes).
    final payload = Uint8List(0x50);
    for (var i = 0x04; i <= 0x12; i++) {
      payload[i] = 0x31;
    }
    payload[0x1E] = 0x01;
    payload[0x2D] = 0x01;
    final devName = utf8.encode('Sanketa');
    for (var i = 0; i < devName.length && i < 6; i++) {
      payload[0x30 + i] = devName[i];
    }

    final response = await session._sendCommand(0x0065, payload);
    if (response == null || response.length < 0x14) {
      throw StateError('BroadLink auth failed: no response');
    }

    final decrypted = session._decrypt(response);
    session.deviceId =
        decrypted[0] | (decrypted[1] << 8) | (decrypted[2] << 16) | (decrypted[3] << 24);
    session.key = Uint8List.fromList(decrypted.sublist(0x04, 0x14));

    return session;
  }

  /// Send an IR signal (raw pulse data in BroadLink format).
  Future<void> sendIr(List<int> irPacket) async {
    final isRm4 = _isRm4(device.model);
    Uint8List payload;

    if (isRm4) {
      final dataLen = irPacket.length + 4;
      payload = Uint8List(2 + 4 + irPacket.length);
      payload[0] = dataLen & 0xFF;
      payload[1] = (dataLen >> 8) & 0xFF;
      // Sub-command 0x02 = send
      payload[2] = 0x02;
      payload.setRange(6, 6 + irPacket.length, irPacket);
    } else {
      payload = Uint8List(4 + irPacket.length);
      payload[0] = 0x02; // Sub-command: send
      payload.setRange(4, 4 + irPacket.length, irPacket);
    }

    await _sendCommand(0x006A, payload);
  }

  /// Send an IrSignal by converting it to BroadLink format first.
  Future<void> sendIrSignal(int carrierHz, List<int> pattern) async {
    final packet = encodeToBroadLink(carrierHz, pattern);
    await sendIr(packet);
  }

  /// Enter IR learning mode. The device will listen for an IR signal from
  /// a physical remote pointed at it.
  Future<void> enterLearningMode() async {
    final isRm4 = _isRm4(device.model);
    Uint8List payload;

    if (isRm4) {
      payload = Uint8List(6);
      payload[0] = 4; // length = sub-command size
      payload[2] = 0x03; // Sub-command: enter learning
    } else {
      payload = Uint8List(4);
      payload[0] = 0x03; // Sub-command: enter learning
    }

    await _sendCommand(0x006A, payload);
  }

  /// Check if a learned IR code is available. Returns the raw BroadLink IR
  /// packet, or null if no code has been captured yet.
  Future<Uint8List?> checkLearnedData() async {
    final isRm4 = _isRm4(device.model);
    Uint8List payload;

    if (isRm4) {
      payload = Uint8List(6);
      payload[0] = 4;
      payload[2] = 0x04; // Sub-command: check data
    } else {
      payload = Uint8List(4);
      payload[0] = 0x04;
    }

    final response = await _sendCommand(0x006A, payload);
    if (response == null) return null;

    final decrypted = _decrypt(response);
    final errCode = decrypted.length > 2 ? (decrypted[0] | (decrypted[1] << 8)) : 0xFFFF;
    if (errCode != 0) return null;

    final dataStart = isRm4 ? 6 : 4;
    if (decrypted.length <= dataStart) return null;
    return Uint8List.fromList(decrypted.sublist(dataStart));
  }

  /// Poll for learned data with timeout.
  Future<Uint8List?> learnIr({Duration timeout = const Duration(seconds: 15)}) async {
    await enterLearningMode();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final data = await checkLearnedData();
      if (data != null) return data;
    }
    return null;
  }

  void close() => socket.close();

  // --- Packet construction ---

  Future<Uint8List?> _sendCommand(int command, Uint8List payload) async {
    final header = Uint8List(0x38);
    // Magic
    header[0] = 0x5A;
    header[1] = 0xA5;
    header[2] = 0xAA;
    header[3] = 0x55;
    header[4] = 0x5A;
    header[5] = 0xA5;
    header[6] = 0xAA;
    header[7] = 0x55;

    // Device type
    header[0x24] = device.deviceType & 0xFF;
    header[0x25] = (device.deviceType >> 8) & 0xFF;

    // Command
    header[0x26] = command & 0xFF;
    header[0x27] = (command >> 8) & 0xFF;

    // Counter
    _counter = (_counter + 1) & 0xFFFF;
    header[0x28] = _counter & 0xFF;
    header[0x29] = (_counter >> 8) & 0xFF;

    // MAC (reversed)
    for (var i = 0; i < 6; i++) {
      header[0x2A + i] = device.mac[5 - i];
    }

    // Device ID
    header[0x30] = deviceId & 0xFF;
    header[0x31] = (deviceId >> 8) & 0xFF;
    header[0x32] = (deviceId >> 16) & 0xFF;
    header[0x33] = (deviceId >> 24) & 0xFF;

    // Payload checksum
    final payloadChecksum = _checksum(payload);
    header[0x34] = payloadChecksum & 0xFF;
    header[0x35] = (payloadChecksum >> 8) & 0xFF;

    // Encrypt and append payload
    final encrypted = _encrypt(payload);
    final packet = Uint8List(header.length + encrypted.length);
    packet.setRange(0, header.length, header);
    packet.setRange(header.length, packet.length, encrypted);

    // Full packet checksum
    final fullChecksum = _checksum(packet);
    packet[0x20] = fullChecksum & 0xFF;
    packet[0x21] = (fullChecksum >> 8) & 0xFF;

    // Send and wait for response
    final target = InternetAddress(device.host);
    socket.send(packet, target, 80);

    return _waitForResponse(timeout: const Duration(seconds: 5));
  }

  Future<Uint8List?> _waitForResponse({required Duration timeout}) async {
    final completer = Completer<Uint8List?>();
    Timer? timer;
    StreamSubscription<RawSocketEvent>? sub;

    timer = Timer(timeout, () {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null || dg.data.length < 0x38) return;
      timer?.cancel();
      sub?.cancel();
      if (!completer.isCompleted) {
        completer.complete(Uint8List.fromList(dg.data.sublist(0x38)));
      }
    });

    return completer.future;
  }

  Uint8List _encrypt(Uint8List data) {
    final padded = _pad16(data);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), Uint8List.fromList(_iv)));
    final out = Uint8List(padded.length);
    for (var i = 0; i < padded.length; i += 16) {
      cipher.processBlock(padded, i, out, i);
    }
    return out;
  }

  Uint8List _decrypt(Uint8List data) {
    if (data.isEmpty) return data;
    final padded = _pad16(data);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), Uint8List.fromList(_iv)));
    final out = Uint8List(padded.length);
    for (var i = 0; i < padded.length; i += 16) {
      cipher.processBlock(padded, i, out, i);
    }
    return out;
  }

  static int _checksum(List<int> data) {
    var sum = 0xBEAF;
    for (final b in data) {
      sum = (sum + b) & 0xFFFF;
    }
    return sum;
  }

  static Uint8List _pad16(Uint8List data) {
    final rem = data.length % 16;
    if (rem == 0) return data;
    final padded = Uint8List(data.length + 16 - rem);
    padded.setRange(0, data.length, data);
    return padded;
  }

  static Uint8List _buildDiscoveryPacket(int sourcePort) {
    final now = DateTime.now();
    final packet = Uint8List(0x30);

    // Timezone offset in seconds
    final offset = now.timeZoneOffset.inSeconds;
    packet[0x08] = offset & 0xFF;
    packet[0x09] = (offset >> 8) & 0xFF;
    packet[0x0A] = (offset >> 16) & 0xFF;
    packet[0x0B] = (offset >> 24) & 0xFF;

    // Date/time
    packet[0x0C] = now.year & 0xFF;
    packet[0x0D] = (now.year >> 8) & 0xFF;
    packet[0x0E] = now.second;
    packet[0x0F] = now.minute;
    packet[0x10] = now.hour;
    packet[0x11] = now.weekday % 7;
    packet[0x12] = now.day;
    packet[0x13] = now.month;

    // Source port
    packet[0x1C] = sourcePort & 0xFF;
    packet[0x1D] = (sourcePort >> 8) & 0xFF;

    // Message type: discovery
    packet[0x26] = 0x06;

    // Checksum
    final cs = _checksum(packet);
    packet[0x20] = cs & 0xFF;
    packet[0x21] = (cs >> 8) & 0xFF;

    return packet;
  }
}

// --- IR data conversion ---

const double _broadlinkTick = 32.84; // microseconds per unit

/// Convert microsecond pulse timings to BroadLink IR packet format.
Uint8List encodeToBroadLink(int carrierHz, List<int> pattern) {
  final pulses = <int>[];
  for (final us in pattern) {
    pulses.add((us / _broadlinkTick).round());
  }

  final bytes = <int>[];
  for (final p in pulses) {
    if (p > 255) {
      bytes.add(0x00);
      bytes.add((p >> 8) & 0xFF);
      bytes.add(p & 0xFF);
    } else {
      bytes.add(p);
    }
  }

  final packet = Uint8List(4 + bytes.length);
  packet[0] = 0x26; // IR signal type
  packet[1] = 0x00; // Repeat: send once
  final dataLen = bytes.length;
  packet[2] = dataLen & 0xFF;
  packet[3] = (dataLen >> 8) & 0xFF;
  packet.setRange(4, 4 + bytes.length, bytes);

  return packet;
}

/// Parse BroadLink IR packet back to microsecond pulse timings.
/// Returns (carrierHz, pattern) — carrier is assumed 38000 since
/// BroadLink doesn't report it.
(int carrierHz, List<int> pattern) decodeBroadLink(Uint8List data) {
  if (data.isEmpty || data[0] != 0x26) {
    return (38000, <int>[]);
  }

  final dataLen = data[2] | (data[3] << 8);
  final pattern = <int>[];
  var i = 4;
  final end = 4 + dataLen;

  while (i < end && i < data.length) {
    if (data[i] == 0x00 && i + 2 < data.length) {
      final value = (data[i + 1] << 8) | data[i + 2];
      pattern.add((value * _broadlinkTick).round());
      i += 3;
    } else {
      pattern.add((data[i] * _broadlinkTick).round());
      i += 1;
    }
  }

  return (38000, pattern);
}
