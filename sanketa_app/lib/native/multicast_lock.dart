import 'package:flutter/services.dart';

const _channel = MethodChannel('com.sanketa/multicast');

Future<void> acquireMulticastLock() async {
  try {
    await _channel.invokeMethod<bool>('acquire');
  } on MissingPluginException {
    // Not on Android (web/test/desktop) — multicast works without a lock.
  }
}

Future<void> releaseMulticastLock() async {
  try {
    await _channel.invokeMethod<bool>('release');
  } on MissingPluginException {
    // Not on Android.
  }
}
