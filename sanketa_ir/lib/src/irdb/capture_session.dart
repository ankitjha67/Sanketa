/// Community capture framework — lets users record IR codes from physical
/// remotes and contribute them back.
///
/// The flow:
/// 1. User selects device type and brand
/// 2. App presents a list of canonical keys to capture
/// 3. For each key, user points their physical remote at the phone and presses
/// 4. Phone's IR receiver (if available) or ConsumerIrManager.learn() captures
///    the raw timing pattern
/// 5. Protocol decoder identifies protocol/address/command
/// 6. Captured codes are assembled into an [IrCodeset]
///
/// Captured codesets are stored locally and can optionally be submitted for
/// inclusion in the community database (with user consent, PRD §14).
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import 'codeset_builder.dart';
import 'flipper_ir_parser.dart';
import 'irdb_catalog.dart';
import 'protocol_decoder.dart';

/// Tracks the state of an IR capture session.
class CaptureSession {
  CaptureSession({
    required this.deviceName,
    required this.brandName,
    required this.deviceType,
    List<Key>? keysToCapture,
  }) : _keysToCapture = keysToCapture ?? _defaultKeys(deviceType);

  final String deviceName;
  final String brandName;
  final DeviceType deviceType;
  final List<Key> _keysToCapture;

  final Map<Key, ParsedSignal> _captured = {};

  /// Keys still awaiting capture.
  List<Key> get remaining =>
      _keysToCapture.where((k) => !_captured.containsKey(k)).toList();

  /// Keys already captured.
  Map<Key, ParsedSignal> get captured => Map.unmodifiable(_captured);

  /// How far along we are (0.0–1.0).
  double get progress =>
      _keysToCapture.isEmpty ? 1.0 : _captured.length / _keysToCapture.length;

  /// Whether all requested keys have been captured.
  bool get isComplete => remaining.isEmpty;

  /// The next key to prompt the user to capture, or `null` if done.
  Key? get nextKey => remaining.isEmpty ? null : remaining.first;

  /// Record a captured signal for a key.
  ///
  /// [carrierHz] and [pattern] come from the IR receiver. The decoder
  /// identifies the protocol automatically.
  void recordCapture(Key key, {required int carrierHz, required List<int> pattern}) {
    final decoded = decodeRawPattern(
      name: key.name,
      carrierHz: carrierHz,
      pattern: pattern,
    );
    _captured[key] = decoded;
  }

  /// Record a pre-decoded signal directly (for manual entry or import).
  void recordSignal(Key key, ParsedSignal signal) {
    _captured[key] = signal;
  }

  /// Skip a key the user's remote doesn't have.
  void skip(Key key) {
    _keysToCapture.remove(key);
  }

  /// Build the final [IrCodeset] from all captured signals.
  IrCodeset buildCodeset() => CodesetBuilder.fromCapture(
        deviceName: deviceName,
        brandName: brandName,
        deviceType: deviceType,
        capturedKeys: _captured,
      );

  /// Serialize the capture for local storage or submission.
  SerializedCodeset serialize() {
    final codeset = buildCodeset();
    return IrdbCatalog.serializeCodeset(codeset, IrdbSource.communityCapture);
  }
}

List<Key> _defaultKeys(DeviceType type) => switch (type) {
      DeviceType.tv || DeviceType.streamingStick || DeviceType.setTopBox => [
          Key.power,
          Key.volumeUp,
          Key.volumeDown,
          Key.mute,
          Key.channelUp,
          Key.channelDown,
          Key.up,
          Key.down,
          Key.left,
          Key.right,
          Key.ok,
          Key.back,
          Key.home,
          Key.menu,
          Key.input,
          Key.digit0,
          Key.digit1,
          Key.digit2,
          Key.digit3,
          Key.digit4,
          Key.digit5,
          Key.digit6,
          Key.digit7,
          Key.digit8,
          Key.digit9,
          Key.guide,
          Key.info,
        ],
      DeviceType.soundbar => [
          Key.power,
          Key.volumeUp,
          Key.volumeDown,
          Key.mute,
          Key.input,
        ],
      DeviceType.airConditioner => [
          Key.power,
          Key.powerOn,
          Key.powerOff,
        ],
      DeviceType.projector => [
          Key.power,
          Key.volumeUp,
          Key.volumeDown,
          Key.mute,
          Key.input,
          Key.menu,
          Key.up,
          Key.down,
          Key.left,
          Key.right,
          Key.ok,
          Key.back,
        ],
      DeviceType.mediaRenderer => [
          Key.power,
          Key.play,
          Key.pause,
          Key.stop,
          Key.rewind,
          Key.fastForward,
          Key.previous,
          Key.next,
          Key.menu,
          Key.up,
          Key.down,
          Key.left,
          Key.right,
          Key.ok,
          Key.back,
        ],
    };
