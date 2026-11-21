/// Roku control adapter over ECP (External Control Protocol).
///
/// ECP is a stateless REST surface on port 8060 with no authentication (a
/// device-side setting can restrict it; we confirm reachability at pair time).
/// It is the simplest real target in the matrix, which is why it is the first
/// adapter built to prove the [ControlAdapter] contract end-to-end.
///
/// Protocol reference (PRD Appendix A / §11 Roku row):
///   POST /keypress/<Key>       tap
///   POST /keydown/<Key>        hold start (repeat frames until keyup)
///   POST /keyup/<Key>          hold end
///   POST /keypress/Lit_<char>  literal character  → live text injection (FR-4.1)
///   POST /launch/<appId>       foreground an app   (FR-6)
///   GET  /query/device-info    identity + power-mode (used for pair/heartbeat)
///
/// Everything Roku-specific lives here; nothing above the contract knows Roku
/// exists.
library;

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

class RokuAdapter implements ControlAdapter {
  RokuAdapter({required String host, int port = 8060, http.Client? client})
      : _base = 'http://$host:$port',
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;

  /// Best-effort field clear: ECP has no select-all, so [TextOp.clear] issues
  /// this many Backspace presses. Enough to empty a typical search box; the
  /// limitation is documented rather than hidden (PRD FR-4.5 field honesty).
  static const int clearBackspaceCap = 64;

  /// Canonical [Key] → ECP key-name mapping. The key set an adapter exposes is
  /// exactly this map's keys, so the UI renders only supported buttons (FR-3.5).
  static const Map<Key, String> _keyMap = {
    Key.power: 'Power',
    Key.powerOn: 'PowerOn',
    Key.powerOff: 'PowerOff',
    Key.volumeUp: 'VolumeUp',
    Key.volumeDown: 'VolumeDown',
    Key.mute: 'VolumeMute',
    Key.up: 'Up',
    Key.down: 'Down',
    Key.left: 'Left',
    Key.right: 'Right',
    Key.ok: 'Select',
    Key.back: 'Back',
    Key.home: 'Home',
    Key.play: 'Play',
    Key.playPause: 'Play',
    Key.rewind: 'Rev',
    Key.fastForward: 'Fwd',
    Key.instantReplay: 'InstantReplay',
    Key.star: 'Info', // Roku's * (Options) button
    Key.backspace: 'Backspace',
    Key.enter: 'Enter',
    Key.search: 'Search',
    Key.channelUp: 'ChannelUp',
    Key.channelDown: 'ChannelDown',
  };

  /// Logical input id → ECP input key (Roku TVs). Sticks have no inputs.
  static const Map<String, String> _inputMap = {
    'hdmi1': 'InputHDMI1',
    'hdmi2': 'InputHDMI2',
    'hdmi3': 'InputHDMI3',
    'hdmi4': 'InputHDMI4',
    'av': 'InputAV1',
    'av1': 'InputAV1',
    'tuner': 'InputTuner',
    'antenna': 'InputTuner',
  };

  // --- Metadata --------------------------------------------------------------

  @override
  String get id => 'roku';

  @override
  BrandFamily get brandFamily => BrandFamily.roku;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints =>
      const DiscoveryHints(ssdpTargets: ['roku:ecp'], probePorts: [8060]);

  // --- Capability ------------------------------------------------------------

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: _keyMap.keys.toSet(),
        textMode: TextInjectionMode.live, // Lit_ literal keys
        wake: false, // WoL not yet implemented
        volumeReadback: false, // ECP does not report volume level
        appLaunch: true,
        inputList: false, // not enumerable via ECP; UI uses a static list
        stateReadback: false, // no push channel
      );

  // --- Lifecycle -------------------------------------------------------------

  @override
  Future<PairingResult> pair(PairingContext context) async {
    // No auth on ECP; a 200 from device-info confirms the target is reachable
    // and ECP is enabled.
    try {
      final res = await _client.get(_uri('/query/device-info'));
      if (res.statusCode == 200) {
        return const PairingResult.paired('roku:no-auth');
      }
      return PairingResult.failed('device-info returned ${res.statusCode}');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() async {
    // ECP is stateless REST — no persistent session to open.
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> heartbeat() async {
    try {
      final res = await _client.get(_uri('/query/device-info'));
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  // --- Commands --------------------------------------------------------------

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final name = _keyMap[key];
    if (name == null) {
      return Future.value(
          CommandResult.failure('unsupported key on Roku: ${key.name}'));
    }
    final verb = switch (press) {
      PressType.tap => 'keypress',
      PressType.holdStart => 'keydown',
      PressType.holdEnd => 'keyup',
    };
    return _post('/$verb/$name');
  }

  @override
  Future<CommandResult> sendText(TextOp op) async {
    switch (op.kind) {
      case TextOpKind.insert:
        final text = op.text ?? '';
        final sw = Stopwatch()..start();
        for (final rune in text.runes) {
          final ch = String.fromCharCode(rune);
          final res = await _post('/keypress/Lit_${Uri.encodeComponent(ch)}');
          if (!res.ok) return res; // stop on first failure, no reordering
        }
        sw.stop();
        return CommandResult.success(latency: sw.elapsed);
      case TextOpKind.delete:
        return _repeat('/keypress/Backspace', op.count);
      case TextOpKind.clear:
        return _repeat('/keypress/Backspace', clearBackspaceCap);
      case TextOpKind.submit:
        return _post('/keypress/Enter');
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) =>
      _post('/launch/${Uri.encodeComponent(app.id)}');

  @override
  Future<CommandResult> setInput(InputRef input) {
    final mapped = _inputMap[input.id.toLowerCase()];
    if (mapped == null) {
      return Future.value(CommandResult.failure('unknown input: ${input.id}'));
    }
    return _post('/keypress/$mapped');
  }

  @override
  Future<CommandResult> power({required bool on}) =>
      _post('/keypress/${on ? 'PowerOn' : 'PowerOff'}');

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();

  /// Release the underlying HTTP client. Call when the device is forgotten.
  void close() => _client.close();

  // --- Internals -------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<CommandResult> _post(String path) async {
    final sw = Stopwatch()..start();
    try {
      final res = await _client.post(_uri(path));
      sw.stop();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return CommandResult.success(latency: sw.elapsed);
      }
      return CommandResult.failure('http ${res.statusCode}');
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  Future<CommandResult> _repeat(String path, int count) async {
    final sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      final res = await _post(path);
      if (!res.ok) return res;
    }
    sw.stop();
    return CommandResult.success(latency: sw.elapsed);
  }
}
