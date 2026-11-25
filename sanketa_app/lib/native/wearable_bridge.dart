import 'dart:async';

import 'package:flutter/services.dart';

enum WearableStatus { disconnected, connecting, connected }

class WearableBridge {
  static const _channel = MethodChannel('com.sanketa/wearable');

  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<WearableStatus> getStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getStatus');
      switch (result) {
        case 'connected':
          return WearableStatus.connected;
        case 'connecting':
          return WearableStatus.connecting;
        default:
          return WearableStatus.disconnected;
      }
    } on MissingPluginException {
      return WearableStatus.disconnected;
    }
  }

  static Future<bool> startPairing() async {
    try {
      final result = await _channel.invokeMethod<bool>('startPairing');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<void>('disconnect');
    } on MissingPluginException {
      // Platform not available.
    }
  }

  static Future<void> sendCommand(String command) async {
    try {
      await _channel.invokeMethod<void>('sendCommand', {'command': command});
    } on MissingPluginException {
      // Platform not available.
    }
  }

  static Future<String?> getWearableName() async {
    try {
      return await _channel.invokeMethod<String>('getWearableName');
    } on MissingPluginException {
      return null;
    }
  }
}
