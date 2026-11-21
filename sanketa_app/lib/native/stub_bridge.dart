/// No-op implementations of every platform bridge, used on web and in tests.
///
/// Every method returns a safe default (false / empty / no-op). This lets the
/// full UI run without native hardware — the demo adapter already does this for
/// the ControlAdapter contract; these stubs extend the same pattern to platform
/// capabilities below the adapter layer.
library;

import 'dart:typed_data';

import 'platform_bridge.dart';

class StubIrBridge implements IrBridge {
  @override
  Future<bool> get hasIrEmitter async => false;

  @override
  Future<List<int>> get carrierFrequencies async => const [];

  @override
  Future<void> transmit(int frequencyHz, List<int> pattern) async {}
}

class StubTlsBridge implements TlsBridge {
  @override
  Future<TlsSocket> connect(String host, int port) async =>
      throw UnsupportedError('TLS sockets not available on this platform');
}

class StubKeystoreBridge implements KeystoreBridge {
  final _store = <String, String>{};

  @override
  Future<void> store(String key, String value) async => _store[key] = value;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> delete(String key) async => _store.remove(key);
}

class StubWolBridge implements WolBridge {
  @override
  Future<void> sendMagicPacket(Uint8List packetBytes) async {}
}

class StubSpeechBridge implements SpeechBridge {
  @override
  Future<bool> get isAvailable async => false;

  @override
  Stream<SpeechResult> listen({String? localeId}) => const Stream.empty();

  @override
  Future<void> stop() async {}
}

class StubHapticsBridge implements HapticsBridge {
  @override
  Future<void> lightTap() async {}

  @override
  Future<void> mediumTap() async {}

  @override
  Future<void> heavyTap() async {}

  @override
  Future<void> selectionClick() async {}
}
