/// Sony BRAVIA Simple IP Control adapter — TCP text protocol on port 20060.
///
/// Used by newer BRAVIA models (2024+ Google TV era, e.g. BRAVIA 2 II / BF1)
/// that dropped the classic IRCC-IP/REST API (port 80) in favour of Simple IP.
/// The TV must have Simple IP Control enabled in
/// Settings → Network → IP Control → Simple IP Control.
///
/// Protocol: `*SCXXXX<16-digit-param>\n` (set), `*SEXXXX################\n`
/// (enquiry), response `*SAXXXX<16-digit-param>` (answer), unsolicited
/// `*SNXXXX<16-digit-param>` (notification).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sanketa_core/sanketa_core.dart';

import '../dial/dial_client.dart';
import 'bravia_atvrs.dart';

/// IR command codes from Sony's official Simple IP Control specification
/// (pro-bravia.sony.net). These are the numeric parameters for the IRCC
/// setIrccCode command, NOT the IRCC-IP base64 payloads.
const Map<Key, int> _irccCodes = {
  // Navigation
  Key.up: 9,
  Key.down: 10,
  Key.right: 11,
  Key.left: 12,
  Key.ok: 13,
  Key.back: 8,
  Key.home: 6,
  Key.info: 5,
  Key.options: 7,
  // Volume & mute
  Key.volumeUp: 30,
  Key.volumeDown: 31,
  Key.mute: 32,
  // Channel
  Key.channelUp: 33,
  Key.channelDown: 34,
  // Digits
  Key.digit1: 18,
  Key.digit2: 19,
  Key.digit3: 20,
  Key.digit4: 21,
  Key.digit5: 22,
  Key.digit6: 23,
  Key.digit7: 24,
  Key.digit8: 25,
  Key.digit9: 26,
  Key.digit0: 27,
  // Colour keys
  Key.red: 14,
  Key.green: 15,
  Key.yellow: 16,
  Key.blue: 17,
  // Media transport
  Key.play: 78,
  Key.pause: 84,
  Key.stop: 81,
  Key.fastForward: 77,
  Key.rewind: 79,
  Key.previous: 80,
  Key.next: 82,
  // Power & input
  Key.power: 98,
  Key.input: 101,
  Key.subtitle: 35,
  Key.audioTrack: 99,
};

class SimpleIpAdapter implements ControlAdapter {
  SimpleIpAdapter({
    required this.host,
    this.port = 20060,
    BraviaAtvrs? atvrs,
    DialClient? dial,
  })  : _atvrs = atvrs,
        _dial = dial;

  final String host;
  final int port;
  final BraviaAtvrs? _atvrs;
  final DialClient? _dial;

  @override
  String get id => 'bravia_simple_ip';

  @override
  BrandFamily get brandFamily => BrandFamily.bravia;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        ssdpTargets: ['urn:schemas-sony-com:service:IRCC:1'],
        probePorts: [20060],
      );

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _irccCodes.keys.toSet(),
        textMode:
            _atvrs != null ? TextInjectionMode.live : TextInjectionMode.none,
        wake: false,
        appLaunch: _dial != null || _atvrs != null,
        inputList: false,
        volumeReadback: true,
        stateReadback: true,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async {
    try {
      await connect();
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }

    // ATVRS pairing for text injection (port 6467 → 6466)
    final atvrs = _atvrs;
    if (atvrs != null && context.requestPin != null) {
      context.notify?.call('Pair to enable keyboard on this TV');
      final ok = await atvrs.pair(context.requestPin!);
      if (ok) {
        try {
          await atvrs.connect();
        } on Object {
          // Pairing succeeded but session connect failed; keyboard unavailable.
        }
      }
    }

    return const PairingResult.paired('simple_ip:open');
  }

  @override
  Future<void> connect() async {
    final response = await _exchange('*SEPOWR################\n');
    if (response == null) throw StateError('unreachable');
  }

  @override
  Future<void> disconnect() async {
    await _atvrs?.disconnect();
  }

  @override
  Future<bool> heartbeat() async {
    final response = await _exchange('*SEPOWR################\n');
    return response != null;
  }

  @override
  Future<CommandResult> sendKey(Key key,
      {PressType press = PressType.tap}) async {
    if (key == Key.powerOn) return power(on: true);
    if (key == Key.powerOff) return power(on: false);
    final code = _irccCodes[key];
    if (code == null) {
      return CommandResult.failure(
          'key not in Simple IP IRCC set: ${key.name}');
    }
    final param = code.toString().padLeft(16, '0');
    return _set('IRCC', param);
  }

  @override
  Future<CommandResult> sendText(TextOp op) async {
    if (op.kind == TextOpKind.submit) {
      // KEYCODE_ENTER (66) via ATVRS submits the text field. Simple IP's
      // Key.ok maps to DPAD_CENTER / IRCC 13, which navigates the on-screen
      // keyboard cursor and types the highlighted letter instead of
      // submitting — never fall back to it.
      final atvrs = _atvrs;
      if (atvrs == null) {
        return const CommandResult.failure(
            'Text submit requires ATVRS — pair in Settings to enable keyboard');
      }
      if (!await atvrs.ensureConnected()) {
        return const CommandResult.failure(
            'ATVRS sidecar not connected — re-pair required');
      }
      try {
        atvrs.submitText();
        return const CommandResult.success();
      } on StateError {
        return const CommandResult.failure(
            'ATVRS connection lost during submit');
      }
    }

    final atvrs = _atvrs;
    if (atvrs == null) {
      return const CommandResult.failure(
          'text injection not supported via Simple IP');
    }

    if (!await atvrs.ensureConnected()) {
      return const CommandResult.failure(
          'ATVRS not paired — pair in Settings to enable keyboard');
    }

    try {
      switch (op.kind) {
        case TextOpKind.insert:
          atvrs.sendText(op.text ?? '');
        case TextOpKind.delete:
          atvrs.sendDelete(op.count);
        case TextOpKind.clear:
          atvrs.sendClear();
        case TextOpKind.submit:
          break; // handled above
      }
      return const CommandResult.success();
    } on StateError {
      if (!await atvrs.ensureConnected()) {
        return const CommandResult.failure('ATVRS connection lost');
      }
      try {
        switch (op.kind) {
          case TextOpKind.insert:
            atvrs.sendText(op.text ?? '');
          case TextOpKind.delete:
            atvrs.sendDelete(op.count);
          case TextOpKind.clear:
            atvrs.sendClear();
          case TextOpKind.submit:
            break;
        }
        return const CommandResult.success();
      } on Object catch (e) {
        return CommandResult.failure('ATVRS text send failed: $e');
      }
    } on Object catch (e) {
      return CommandResult.failure('ATVRS text send failed: $e');
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) async {
    final name = app.name ?? app.id;
    String? dialError;

    // Try DIAL first (works for Netflix on most BRAVIAs).
    final dial = _dial;
    if (dial != null) {
      final appName = dialAppName(name);
      final result = await dial.launch(appName);
      if (result.ok) return const CommandResult.success();
      dialError = result.error;
    }

    // Fall back to ATVRS deep-link launch (Google TV intent mechanism).
    final atvrs = _atvrs;
    if (atvrs != null) {
      final uri = appDeepLink(name);
      if (uri != null) {
        if (!await atvrs.ensureConnected()) {
          final hint = dialError != null
              ? ' (DIAL also failed: $dialError)'
              : '';
          return CommandResult.failure(
              'Could not launch $name — pair the TV first.$hint');
        }
        try {
          atvrs.launchApp(uri);
          return const CommandResult.success();
        } on StateError {
          if (!await atvrs.ensureConnected()) {
            return CommandResult.failure(
                'Lost connection to TV while launching $name.');
          }
          atvrs.launchApp(uri);
          return const CommandResult.success();
        }
      }
    }

    return CommandResult.failure(
        'Could not launch $name.${dialError != null ? ' ($dialError)' : ''}');
  }

  @override
  Future<CommandResult> setInput(InputRef input) {
    final id = input.id.toLowerCase();
    if (id.startsWith('hdmi')) {
      final n = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      return _set('INPT', '000000010000${n.toString().padLeft(4, '0')}');
    }
    return sendKey(Key.input);
  }

  @override
  Future<CommandResult> power({required bool on}) =>
      _set('POWR', (on ? 1 : 0).toString().padLeft(16, '0'));

  @override
  Stream<StateDelta> readState() async* {
    int? lastVol;
    bool? lastMuted;
    PowerState? lastPower;

    while (true) {
      try {
        final vol = await _enquiry('VOLU');
        final mute = await _enquiry('AMUT');
        final powr = await _enquiry('POWR');

        final curMuted = mute == null ? null : mute != 0;
        final curPower = powr == null
            ? null
            : powr == 1
                ? PowerState.on
                : PowerState.standby;

        if (vol != lastVol || curMuted != lastMuted || curPower != lastPower) {
          yield StateDelta(
            volume: vol,
            muted: curMuted,
            power: curPower,
          );
          lastVol = vol;
          lastMuted = curMuted;
          lastPower = curPower;
        }
      } on Object {
        // Poll failures are transient; skip and retry next cycle.
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  // ---------------------------------------------------------------------------

  /// Send an enquiry command and parse the integer parameter from the answer.
  Future<int?> _enquiry(String cmd) async {
    final frame = '*SE$cmd################\n';
    final response = await _exchange(frame);
    if (response == null) return null;
    final re = RegExp(r'\*SA' + cmd + r'(\d{16})');
    final match = re.firstMatch(response);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<CommandResult> _set(String cmd, String param) async {
    final frame = '*SC$cmd$param\n';
    final sw = Stopwatch()..start();
    final response = await _exchange(frame);
    if (response == null) {
      return const CommandResult.failure('no response from TV');
    }
    return CommandResult.success(latency: sw.elapsed);
  }

  /// Open a TCP connection, send [frame], read the first response, close.
  Future<String?> _exchange(String frame) async {
    Socket? socket;
    try {
      socket =
          await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      socket.write(frame);
      await socket.flush();

      final completer = Completer<String>();
      final buffer = StringBuffer();

      socket.listen(
        (data) {
          buffer.write(utf8.decode(data));
          final content = buffer.toString();
          if (content.contains('*SA') && !completer.isCompleted) {
            completer.complete(content.trim());
          }
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) {
            final s = buffer.toString().trim();
            completer.complete(s.isEmpty ? '' : s);
          }
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          final s = buffer.toString().trim();
          return s.isEmpty ? '' : s;
        },
      );
      return result.isEmpty ? null : result;
    } on Object {
      return null;
    } finally {
      socket?.destroy();
    }
  }
}
