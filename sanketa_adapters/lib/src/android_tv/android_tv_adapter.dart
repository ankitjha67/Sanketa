/// AndroidTvAdapter — Android TV / Google TV remote protocol v2 behind the
/// [ControlAdapter] contract. This is the keyboard-hero platform (live text
/// injection) and, under OD-2 India-first, the dominant one.
///
/// Verified here: capability map, key injection (correct keycode + direction),
/// text/app/power command composition, connection lifecycle — all against a fake
/// channel. Pending Phase 0 on a real device: the wire field numbers (see
/// [RemoteField]), TLS + client-cert handling (the [AtvChannel] impl), and IME
/// batch-edit text. Pairing is the separate [AtvPairingSession].
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:sanketa_core/sanketa_core.dart';

import '../dial/dial_client.dart' show appDeepLink;
import 'atv_channel.dart';
import 'atv_keymap.dart';
import 'atv_messages.dart';
import 'protobuf_codec.dart';

class AndroidTvAdapter extends ControlAdapter {
  AndroidTvAdapter({required AtvChannel channel}) : _channel = channel;

  final AtvChannel _channel;
  StreamSubscription<Uint8List>? _messageSub;
  String _imeText = '';
  int _imeCounter = 1;
  int _fieldCounter = 1;

  @override
  String get id => 'android_tv';

  @override
  BrandFamily get brandFamily => BrandFamily.androidTv;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        mdnsServiceTypes: ['_androidtvremote2._tcp'],
        probePorts: [6466, 6467],
      );

  @override
  CapabilityMap capabilities() {
    final f = _channel.negotiatedFeatures;
    if (f == 0) {
      // Not yet connected — return the full static set so the UI doesn't
      // flash empty capabilities before the handshake completes.
      return CapabilityMap(
        keys: androidKeyCodes.keys.toSet(),
        textMode: TextInjectionMode.live,
        wake: false,
        volumeReadback: false,
        appLaunch: true,
        inputList: false,
        stateReadback: false,
      );
    }
    // Build capability map from what the TV actually reported.
    final keys = <Key>{};
    if (f & AtvrsFeatures.key != 0) keys.addAll(androidKeyCodes.keys);
    if (f & AtvrsFeatures.volume != 0) {
      keys.addAll(const [Key.volumeUp, Key.volumeDown, Key.mute]);
    }
    if (f & AtvrsFeatures.power != 0) keys.add(Key.power);
    return CapabilityMap(
      keys: keys,
      textMode: (f & AtvrsFeatures.ime != 0)
          ? TextInjectionMode.live
          : TextInjectionMode.none,
      wake: false,
      volumeReadback: false,
      appLaunch: (f & AtvrsFeatures.appLink != 0),
      inputList: false,
      stateReadback: false,
    );
  }

  @override
  Future<PairingResult> pair(PairingContext context) async {
    // By the time we hold a session channel the client cert is already
    // authorized; the one-time code handshake is AtvPairingSession (port 6467).
    try {
      if (!_channel.isOpen) await _channel.connect();
      return _channel.isOpen
          ? const PairingResult.paired('android_tv:session')
          : const PairingResult.failed('could not open session channel');
    } on Object catch (e) {
      return PairingResult.failed('$e');
    }
  }

  @override
  Future<void> connect() async {
    await _channel.connect();
    _subscribeToMessages();
  }

  @override
  Future<void> disconnect() async {
    await _messageSub?.cancel();
    _messageSub = null;
    await _channel.close();
  }

  @override
  Future<bool> heartbeat() async {
    if (!_channel.isOpen) return false;
    try {
      _channel.sendMessage(buildPingResponse(1));
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) {
    final keyCode = androidKeyCodes[key];
    if (keyCode == null) {
      return Future.value(CommandResult.failure(
          'key not supported on android_tv: ${key.name}'));
    }
    return _send(buildKeyInject(keyCode, atvDirectionFor(press)));
  }

  @override
  Future<CommandResult> sendText(TextOp op) async {
    switch (op.kind) {
      case TextOpKind.insert:
        _imeText += op.text ?? '';
        return _send(buildImeText(_imeText,
            imeCounter: _imeCounter, fieldCounter: _fieldCounter));
      case TextOpKind.submit:
        if (_imeText.isNotEmpty) {
          // Commit the composition: send the text as the `committed` string
          // field (not composing) so the TV finalizes the IME input. Without
          // this, KEYCODE_ENTER is consumed by the on-screen keyboard.
          await _send(buildImeCommit(_imeText,
              imeCounter: _imeCounter, fieldCounter: _fieldCounter));
        }
        _imeText = '';
        return _send(
            buildKeyInject(androidKeyCodes[Key.enter]!, AtvDirection.short));
      case TextOpKind.delete:
        if (_imeText.isEmpty) {
          return _repeatKey(androidKeyCodes[Key.backspace]!, op.count);
        }
        _imeText = _imeText.substring(0,
            (_imeText.length - op.count).clamp(0, _imeText.length));
        return _send(buildImeText(_imeText,
            imeCounter: _imeCounter, fieldCounter: _fieldCounter,
            start: _imeText.length, end: _imeText.length));
      case TextOpKind.clear:
        final oldLength = _imeText.length;
        _imeText = '';
        return _send(buildImeText('', imeCounter: _imeCounter,
            fieldCounter: _fieldCounter, start: 0, end: oldLength));
    }
  }

  @override
  Future<CommandResult> launchApp(AppRef app) {
    final uri = appDeepLink(app.name ?? app.id) ?? app.id;
    return _send(buildAppLink(uri));
  }

  @override
  Future<CommandResult> setInput(InputRef input) async =>
      const CommandResult.failure(
          'input switching not yet supported on android_tv');

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

  @override
  Future<CommandResult> setAudioDevice(String deviceId) =>
      _send(buildSetAudioDevice(deviceId));

  @override
  Future<CommandResult> resetAudioDevice() => _send(buildResetAudioDevice());

  void _subscribeToMessages() {
    _messageSub?.cancel();
    _messageSub = _channel.messages.listen((msg) {
      try {
        final r = ProtoReader(msg);
        if (!r.hasMore) return;
        final tag = r.readTag();
        if (tag.number == RemoteField.imeKeyInject &&
            tag.wireType == WireType.lengthDelimited) {
          _parseImeKeyInject(r.readLengthDelimited());
        } else if (tag.number == RemoteField.imeShowRequest &&
            tag.wireType == WireType.lengthDelimited) {
          _parseImeShowRequest(r.readLengthDelimited());
        }
      } on Object {
        // Best-effort parse — malformed frames are ignored.
      }
    });
  }

  void _parseImeKeyInject(Uint8List data) {
    final r = ProtoReader(data);
    final oldField = _fieldCounter;
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag.number == 1 && tag.wireType == WireType.lengthDelimited) {
        final appInfo = ProtoReader(r.readLengthDelimited());
        while (appInfo.hasMore) {
          final at = appInfo.readTag();
          if (at.number == 1 && at.wireType == WireType.varint) {
            _imeCounter = appInfo.readVarint();
          } else {
            appInfo.skip(at.wireType);
          }
        }
      } else if (tag.number == 2 && tag.wireType == WireType.lengthDelimited) {
        final tfs = ProtoReader(r.readLengthDelimited());
        while (tfs.hasMore) {
          final tt = tfs.readTag();
          if (tt.number == 1 && tt.wireType == WireType.varint) {
            _fieldCounter = tfs.readVarint();
          } else {
            tfs.skip(tt.wireType);
          }
        }
      } else {
        r.skip(tag.wireType);
      }
    }
    if (_fieldCounter != oldField) _imeText = '';
  }

  void _parseImeShowRequest(Uint8List data) {
    final r = ProtoReader(data);
    final oldField = _fieldCounter;
    while (r.hasMore) {
      final tag = r.readTag();
      if (tag.number == 2 && tag.wireType == WireType.lengthDelimited) {
        final tfs = ProtoReader(r.readLengthDelimited());
        while (tfs.hasMore) {
          final tt = tfs.readTag();
          if (tt.number == 1 && tt.wireType == WireType.varint) {
            _fieldCounter = tfs.readVarint();
          } else {
            tfs.skip(tt.wireType);
          }
        }
      } else {
        r.skip(tag.wireType);
      }
    }
    if (_fieldCounter != oldField) _imeText = '';
  }

  Future<CommandResult> _send(List<int> body) async {
    if (!_channel.isOpen) {
      return const CommandResult.failure('android_tv channel not connected');
    }
    if (_channel.gotError) {
      return const CommandResult.failure('not_paired');
    }
    final sw = Stopwatch()..start();
    try {
      _channel.sendMessage(body);
      return CommandResult.success(latency: sw.elapsed);
    } on Object catch (e) {
      return CommandResult.failure('$e');
    }
  }

  Future<CommandResult> _repeatKey(int keyCode, int count) async {
    for (var i = 0; i < count; i++) {
      final res = await _send(buildKeyInject(keyCode, AtvDirection.short));
      if (!res.ok) return res;
    }
    return const CommandResult.success();
  }
}
