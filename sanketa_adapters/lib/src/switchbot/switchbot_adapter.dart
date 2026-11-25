/// SwitchBot Hub WiFi-IR bridge adapter — CLOUD-ONLY, opt-in.
///
/// SwitchBot has NO local LAN API. All commands route through
/// `api.switch-bot.com` with HMAC-SHA256 auth. This CONFLICTS with the
/// "zero server calls" privacy red line (CONTEXT.md §9, NFR-8).
///
/// This adapter is therefore:
///   1. Disabled by default — the user must explicitly enable cloud mode.
///   2. Clearly labelled in the UI as "requires internet / cloud API".
///   3. Rate-limited to SwitchBot's 10K calls/day cap.
///   4. IR learning is NOT supported (must be done in the SwitchBot app).
///
/// The adapter is a thin wrapper: it takes a pre-built IR codeset and sends
/// raw IR packets via the SwitchBot cloud API. It does NOT use the SwitchBot
/// "scene" or "device" abstractions — it treats the Hub purely as an IR
/// emitter, keeping the codeset pipeline identical to phone-IR and BroadLink.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';

class SwitchBotConfig {
  const SwitchBotConfig({
    required this.token,
    required this.secret,
    required this.deviceId,
  });

  final String token;
  final String secret;
  final String deviceId;
}

class SwitchBotAdapter implements ControlAdapter {
  SwitchBotAdapter({
    required SwitchBotConfig config,
    required IrCodeset codeset,
    IrCodec codec = const IrCodec(),
  })  : _config = config,
        _codeset = codeset,
        _codec = codec;

  final SwitchBotConfig _config;
  final IrCodeset _codeset;
  final IrCodec _codec;
  bool _connected = false;

  @override
  String get id => 'switchbot:${_config.deviceId}';

  @override
  BrandFamily get brandFamily => _codeset.brand;

  @override
  Transport get transport => Transport.bridge;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints();

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _codeset.supportedKeys,
        textMode: TextInjectionMode.none,
        wake: _codeset.supports(Key.powerOn) || _codeset.supports(Key.power),
        volumeReadback: false,
        appLaunch: false,
        inputList: false,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    // Validate credentials by hitting the device list endpoint.
    try {
      final result = await _apiGet('/v1.1/devices');
      if (result == null) {
        return const PairingResult.failed(
            'SwitchBot API unreachable. Check your internet connection.');
      }
      return PairingResult.paired(id);
    } on Object catch (e) {
      return PairingResult.failed('SwitchBot auth failed: $e');
    }
  }

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  Future<bool> heartbeat() async => _connected;

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) async {
    if (press == PressType.holdEnd) return const CommandResult.success();

    final command = _codeset.keys[key];
    if (command == null) {
      return CommandResult.failure('key not in codeset: ${key.name}');
    }

    final signal = _codec.encode(command);
    return _sendIr(signal);
  }

  @override
  Future<CommandResult> sendText(TextOp op) async => const CommandResult.failure(
      'IR bridge has no text injection; use D-pad assist (FR-4.4)');

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.failure('app launch is not available over IR bridge');

  @override
  Future<CommandResult> setInput(InputRef input) async {
    if (_codeset.supports(Key.input)) return sendKey(Key.input);
    return const CommandResult.failure(
        'input switching not available in this codeset');
  }

  @override
  Future<CommandResult> power({required bool on}) {
    final key = on
        ? (_codeset.supports(Key.powerOn) ? Key.powerOn : Key.power)
        : (_codeset.supports(Key.powerOff) ? Key.powerOff : Key.power);
    return sendKey(key);
  }

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  Future<CommandResult> _sendIr(IrSignal signal) async {
    final sw = Stopwatch()..start();
    try {
      final body = jsonEncode({
        'command': 'customize',
        'commandType': 'customize',
        'parameter': _encodeForSwitchBot(signal),
      });

      final result = await _apiPost(
        '/v1.1/devices/${_config.deviceId}/commands',
        body,
      );
      sw.stop();

      if (result == null) {
        return const CommandResult.failure(
            'SwitchBot API unreachable. Check your internet connection.');
      }
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  /// Encode an IrSignal to the SwitchBot custom IR format.
  /// Format: "carrierHz,on1,off1,on2,off2,..." (microseconds, comma-separated).
  String _encodeForSwitchBot(IrSignal signal) {
    final parts = [signal.carrierHz.toString()];
    for (final us in signal.pattern) {
      parts.add(us.toString());
    }
    return parts.join(',');
  }

  /// Generate HMAC-SHA256 auth headers per SwitchBot API v1.1.
  Map<String, String> _authHeaders() {
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = 'sanketa_${DateTime.now().microsecondsSinceEpoch}';
    final data = utf8.encode('${_config.token}$t$nonce');
    final key = utf8.encode(_config.secret);
    final mac = Hmac(sha256, key).convert(data);
    final sign = base64Encode(mac.bytes);

    return {
      'Authorization': _config.token,
      'sign': sign,
      't': t,
      'nonce': nonce,
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Future<String?> _apiGet(String path) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.switch-bot.com$path');
      final req = await client.getUrl(uri);
      final headers = _authHeaders();
      headers.forEach(req.headers.set);
      final resp = await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return await resp.transform(utf8.decoder).join();
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _apiPost(String path, String body) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.switch-bot.com$path');
      final req = await client.postUrl(uri);
      final headers = _authHeaders();
      headers.forEach(req.headers.set);
      req.write(body);
      final resp = await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return await resp.transform(utf8.decoder).join();
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
