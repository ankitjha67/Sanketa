/// Android ConsumerIrManager access through the app's platform channel.
///
/// On platforms without the channel (iOS, web, desktop, and widget tests),
/// capability queries return safe defaults. Transmit failures remain visible
/// to the caller so the setup wizard can explain that the test did not run.
library;

import 'package:flutter/services.dart';

import 'platform_bridge.dart';

class MethodChannelIrBridge implements IrBridge {
  const MethodChannelIrBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.sanketa/ir');

  final MethodChannel _channel;

  @override
  Future<bool> get hasIrEmitter async {
    try {
      return await _channel.invokeMethod<bool>('hasIrEmitter') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<int>> get carrierFrequencies async {
    try {
      final values = await _channel.invokeListMethod<int>('carrierFrequencies');
      return values ?? const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  @override
  Future<void> transmit(int frequencyHz, List<int> pattern) =>
      _channel.invokeMethod<void>('transmit', <String, Object>{
        'frequencyHz': frequencyHz,
        'pattern': pattern,
      });
}
