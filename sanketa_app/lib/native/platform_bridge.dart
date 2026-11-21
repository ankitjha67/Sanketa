/// Abstract interfaces for native platform capabilities.
///
/// Each capability (IR, TLS, keystore, WoL, speech, haptics) gets an abstract
/// class here. The Flutter app injects the real implementation via platform
/// channels on Android/iOS, or a no-op stub on web/test. This seam lets the
/// entire control-layer and UI be developed and tested without hardware.
///
/// Privacy: keystore operations are opaque handles — the bridge never surfaces
/// secret material to Dart (PRD NFR-10, CONTEXT.md §9.10). Speech data stays
/// on-device and is never logged (PRD §14.3).
library;

import 'dart:typed_data';

/// IR blaster hardware access (Android ConsumerIrManager, FR-2.1).
abstract class IrBridge {
  /// Whether the device has an IR transmitter.
  Future<bool> get hasIrEmitter;

  /// Carrier frequencies the hardware supports.
  Future<List<int>> get carrierFrequencies;

  /// Emit a raw IR pattern at [frequencyHz]. [pattern] alternates on/off
  /// durations in microseconds, starting with an on-period.
  Future<void> transmit(int frequencyHz, List<int> pattern);
}

/// TLS socket factory for protocols requiring raw TLS (Android TV protobuf).
abstract class TlsBridge {
  /// Open a TLS socket to [host]:[port] using the platform's TLS stack, which
  /// handles certificate pinning and system trust stores.
  Future<TlsSocket> connect(String host, int port);
}

/// A platform-provided TLS socket. Bytes flow through [input]/[output]; the
/// Dart adapter frames messages on top.
abstract class TlsSocket {
  Stream<Uint8List> get input;
  void add(Uint8List data);
  Future<void> close();
}

/// Secure credential storage (Keystore on Android, Keychain on iOS).
/// Handles are opaque — the bridge never exposes raw secrets to Dart.
abstract class KeystoreBridge {
  Future<void> store(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

/// Wake-on-LAN raw socket access. Some platforms need a native UDP broadcast
/// socket that the Dart VM cannot create directly.
abstract class WolBridge {
  /// Broadcast [packetBytes] as a UDP datagram to 255.255.255.255:9.
  Future<void> sendMagicPacket(Uint8List packetBytes);
}

/// Speech recognition (FR-4.2 voice-to-TV). Audio stays on-device; recognised
/// text is forwarded to the TV via the ControlAdapter — never logged, never
/// sent to SANKETA servers (PRD §14.3).
abstract class SpeechBridge {
  /// Whether speech recognition is available on this platform.
  Future<bool> get isAvailable;

  /// Start listening. Returns a stream of partial and final transcriptions.
  Stream<SpeechResult> listen({String? localeId});

  /// Stop an active recognition session.
  Future<void> stop();
}

class SpeechResult {
  const SpeechResult({required this.text, required this.isFinal});
  final String text;
  final bool isFinal;
}

/// Haptic feedback (FR-5). Provides tactile response for button presses.
abstract class HapticsBridge {
  Future<void> lightTap();
  Future<void> mediumTap();
  Future<void> heavyTap();
  Future<void> selectionClick();
}
