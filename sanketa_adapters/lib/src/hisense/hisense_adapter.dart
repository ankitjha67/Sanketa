/// Hisense VIDAA TV adapter over MQTT.
///
/// Hisense VIDAA smart TVs expose an MQTT broker on port 36669 (plain TCP) or
/// 36670 (TLS). Commands travel as JSON payloads published to topic paths
/// rooted at `/remoteapp/tv/remote_service/{mac}/actions/`. Key presses use
/// the `sendkey` action, volume the `volume` action, and app launch the
/// `launchapp` action.
///
/// Most models require no authentication; the phone connects as an MQTT client
/// and begins publishing immediately. Discovery is via SSDP
/// `urn:hisense-com:device:TV:1` or by probing ports 36669/36670.
///
/// This file contains a minimal inline MQTT v3.1.1 frame builder (CONNECT,
/// PUBLISH, SUBSCRIBE, PINGREQ at QoS 0) so we avoid pulling in an external
/// MQTT dependency.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:sanketa_core/sanketa_core.dart';

class HisenseAdapter extends ControlAdapter {
  HisenseAdapter({
    required String host,
    int port = 36669,
    bool tls = false,
    String? macAddress,
  })  : _host = host,
        _port = port,
        _tls = tls,
        _mac = macAddress;

  final String _host;
  final int _port;
  final bool _tls;
  String? _mac;
  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSub;
  bool _connected = false;

  /// Topic root derived from the TV's MAC address. Set during [connect] if
  /// not supplied at construction.
  String get _topicRoot =>
      '/remoteapp/tv/remote_service/${_mac ?? 'default'}/actions';

  // ---------------------------------------------------------------------------
  // Key mapping: Sanketa Key -> Hisense VIDAA keyNum
  // ---------------------------------------------------------------------------

  static const Map<Key, int> _keyMap = {
    Key.power: 0,
    Key.powerOn: 0,
    Key.powerOff: 0,
    Key.up: 1,
    Key.down: 2,
    Key.left: 3,
    Key.right: 4,
    Key.ok: 5,
    Key.back: 6,
    Key.home: 7,
    Key.menu: 8,
    Key.mute: 10,
    Key.channelUp: 11,
    Key.channelDown: 12,
    Key.volumeUp: 15,
    Key.volumeDown: 16,
    Key.play: 20,
    Key.pause: 21,
    Key.playPause: 20,
    Key.stop: 22,
    Key.rewind: 23,
    Key.fastForward: 24,
    Key.info: 25,
    Key.exit: 30,
    Key.source: 31,
    Key.digit0: 50,
    Key.digit1: 51,
    Key.digit2: 52,
    Key.digit3: 53,
    Key.digit4: 54,
    Key.digit5: 55,
    Key.digit6: 56,
    Key.digit7: 57,
    Key.digit8: 58,
    Key.digit9: 59,
    Key.red: 100,
    Key.green: 101,
    Key.yellow: 102,
    Key.blue: 103,
  };

  // ---------------------------------------------------------------------------
  // ControlAdapter metadata
  // ---------------------------------------------------------------------------

  @override
  String get id => 'hisense';

  @override
  BrandFamily get brandFamily => BrandFamily.hisense;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:hisense-com:device:TV:1'],
        probePorts: [36669, 36670],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _keyMap.keys.toSet(),
        textMode: TextInjectionMode.none,
        wake: false,
        volumeReadback: false,
        appLaunch: true,
        inputList: false,
        stateReadback: false,
      );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<PairingResult> pair(PairingContext context) async {
    // Most Hisense VIDAA models need no pairing. Verify by attempting a
    // connection; if the MQTT broker accepts us, we're good.
    try {
      await connect();
      await disconnect();
      return const PairingResult.paired('hisense:no-auth');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() async {
    if (_connected) return;

    final socket = _tls
        ? await SecureSocket.connect(_host, _port,
            timeout: const Duration(seconds: 5),
            onBadCertificate: (_) => true)
        : await Socket.connect(_host, _port,
            timeout: const Duration(seconds: 5));

    _socket = socket;

    // Listen for incoming data (CONNACK, SUBACK, PINGRESP, etc.).
    final connackCompleter = Completer<void>();
    _socketSub = socket.listen(
      (data) {
        // CONNACK is packet type 0x20; we just need the first two bytes.
        if (!connackCompleter.isCompleted && data.isNotEmpty) {
          final type = data[0] & 0xF0;
          if (type == 0x20) {
            // CONNACK received.
            if (data.length >= 4 && data[3] != 0) {
              connackCompleter.completeError(
                  StateError('MQTT CONNACK refused: code ${data[3]}'));
            } else {
              connackCompleter.complete();
            }
          }
        }
      },
      onError: (Object e) {
        if (!connackCompleter.isCompleted) {
          connackCompleter.completeError(e);
        }
        _connected = false;
      },
      onDone: () {
        if (!connackCompleter.isCompleted) {
          connackCompleter
              .completeError(StateError('Socket closed before CONNACK'));
        }
        _connected = false;
      },
    );

    // Send MQTT CONNECT.
    socket.add(_buildConnect('sanketa_${_randomId()}'));

    await connackCompleter.future.timeout(const Duration(seconds: 5));
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    if (!_connected && _socket == null) return;
    try {
      // Send MQTT DISCONNECT (0xE0 0x00).
      _socket?.add(Uint8List.fromList([0xE0, 0x00]));
      await _socket?.flush();
    } on Object {
      // Best-effort.
    }
    await _socketSub?.cancel();
    _socketSub = null;
    _socket?.destroy();
    _socket = null;
    _connected = false;
  }

  @override
  Future<bool> heartbeat() async {
    if (!_connected || _socket == null) return false;
    try {
      // PINGREQ: 0xC0 0x00
      _socket!.add(Uint8List.fromList([0xC0, 0x00]));
      await _socket!.flush();
      return true;
    } on Object {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final code = _keyMap[key];
    if (code == null) {
      return Future.value(
          CommandResult.failure('key not supported on Hisense: ${key.name}'));
    }
    return _publish(
      '$_topicRoot/sendkey',
      jsonEncode({'keyNum': code}),
    );
  }

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.failure('Hisense VIDAA has no text input');

  @override
  Future<CommandResult> launchApp(AppRef app) => _publish(
        '$_topicRoot/launchapp',
        jsonEncode({'appId': app.id}),
      );

  @override
  Future<CommandResult> setInput(InputRef input) => sendKey(Key.source);

  @override
  Future<CommandResult> power({required bool on}) => sendKey(Key.power);

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  @override
  Future<int?> getVolume() async => null;
  @override
  Future<bool?> getMuted() async => null;
  @override
  Future<PowerState?> getPowerState() async => null;
  @override
  Future<AppRef?> getCurrentApp() async => null;

  void close() {
    _socketSub?.cancel();
    _socket?.destroy();
    _socket = null;
    _connected = false;
  }

  // ---------------------------------------------------------------------------
  // Volume helpers (not part of the ControlAdapter contract, but useful for
  // future expansion).
  // ---------------------------------------------------------------------------

  /// Set absolute volume (0-100). volumeType 0 = set, 1 = relative.
  Future<CommandResult> setVolume(int value) => _publish(
        '$_topicRoot/volume',
        jsonEncode({'volumeType': 0, 'volumeValue': value.clamp(0, 100)}),
      );

  // ---------------------------------------------------------------------------
  // MQTT helpers
  // ---------------------------------------------------------------------------

  Future<CommandResult> _publish(String topic, String payload) async {
    if (!_connected || _socket == null) {
      return const CommandResult.failure('Not connected to Hisense TV');
    }
    try {
      _socket!.add(_buildPublish(topic, payload));
      await _socket!.flush();
      return const CommandResult.success();
    } on Object catch (e) {
      _connected = false;
      return CommandResult.failure('$e');
    }
  }

  // ---------------------------------------------------------------------------
  // Minimal MQTT v3.1.1 frame builders (QoS 0, no packet-ID)
  // ---------------------------------------------------------------------------

  /// CONNECT packet with clean-session, 60s keep-alive.
  static Uint8List _buildConnect(String clientId) {
    final clientIdBytes = utf8.encode(clientId);
    // Variable header: protocol name "MQTT" + level 4 + flags + keep-alive
    final variableHeader = <int>[
      0x00, 0x04, // protocol name length
      ...utf8.encode('MQTT'),
      0x04, // protocol level (3.1.1)
      0x02, // connect flags: clean session
      0x00, 0x3C, // keep-alive 60s
    ];
    // Payload: client-id
    final payload = <int>[
      (clientIdBytes.length >> 8) & 0xFF,
      clientIdBytes.length & 0xFF,
      ...clientIdBytes,
    ];

    final remainingLength = variableHeader.length + payload.length;
    return _buildPacket(0x10, remainingLength, [...variableHeader, ...payload]);
  }

  /// PUBLISH packet (QoS 0, no retain, no packet-ID).
  static Uint8List _buildPublish(String topic, String payload) {
    final topicBytes = utf8.encode(topic);
    final payloadBytes = utf8.encode(payload);
    final body = <int>[
      (topicBytes.length >> 8) & 0xFF,
      topicBytes.length & 0xFF,
      ...topicBytes,
      ...payloadBytes,
    ];
    return _buildPacket(0x30, body.length, body);
  }

  /// Encodes a fixed header with remaining-length using MQTT variable-length
  /// encoding, then appends the body.
  static Uint8List _buildPacket(int firstByte, int remainingLength, List<int> body) {
    final header = <int>[firstByte];
    var rl = remainingLength;
    do {
      var encodedByte = rl % 128;
      rl = rl ~/ 128;
      if (rl > 0) encodedByte |= 0x80;
      header.add(encodedByte);
    } while (rl > 0);
    return Uint8List.fromList([...header, ...body]);
  }

  static String _randomId() {
    final r = Random();
    return List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}
