import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// FR-1.2: Permission choreography.
///
/// Guides users through platform-specific permission prompts needed for LAN
/// discovery. On iOS, the Local Network prompt is funnel risk R-2 — if the user
/// denies it, discovery fails silently and the app appears broken.
///
/// Zero third-party dependencies (PRD red line #1). Uses the platform channel
/// only for `connectivity_info` → never makes a network call to Sanketa servers.
class PermissionService extends ChangeNotifier {
  static const _channel = MethodChannel('com.sanketa/permissions');

  PermissionState _localNetwork = PermissionState.unknown;
  PermissionState _nearbyDevices = PermissionState.unknown;
  bool _checked = false;

  PermissionState get localNetwork => _localNetwork;
  PermissionState get nearbyDevices => _nearbyDevices;
  bool get allGranted =>
      _localNetwork != PermissionState.denied &&
      _nearbyDevices != PermissionState.denied;
  bool get checked => _checked;

  /// Check all permissions needed for discovery.
  Future<void> check() async {
    if (Platform.isIOS) {
      _localNetwork = await _checkIosLocalNetwork();
    } else {
      _localNetwork = PermissionState.granted;
    }

    if (Platform.isAndroid) {
      _nearbyDevices = await _checkAndroidNearbyDevices();
    } else {
      _nearbyDevices = PermissionState.granted;
    }

    _checked = true;
    notifyListeners();
  }

  /// Request any missing permissions. Returns true if all granted.
  Future<bool> requestAll() async {
    if (Platform.isIOS && _localNetwork != PermissionState.granted) {
      _localNetwork = await _requestIosLocalNetwork();
    }
    if (Platform.isAndroid && _nearbyDevices != PermissionState.granted) {
      _nearbyDevices = await _requestAndroidNearbyDevices();
    }
    notifyListeners();
    return allGranted;
  }

  /// Human-readable explanation for the current state.
  String get statusMessage {
    if (!_checked) return 'Checking permissions…';
    if (allGranted) return 'All permissions granted';

    final issues = <String>[];
    if (_localNetwork == PermissionState.denied) {
      issues.add(
          'Local Network access is required to find your TV. '
          'Open Settings → Sanketa → Local Network and enable it.');
    }
    if (_nearbyDevices == PermissionState.denied) {
      issues.add(
          'Nearby Devices permission is needed to discover TVs on your network. '
          'Tap "Allow" when prompted.');
    }
    return issues.join('\n\n');
  }

  /// Guidance text shown before triggering the iOS prompt.
  static const iosPrePromptTitle = 'Find your TV';
  static const iosPrePromptBody =
      'Sanketa needs to scan your local network to discover TVs. '
      'iOS will ask for permission next — please tap "Allow" so '
      'we can find your TV automatically.';

  // ── iOS Local Network ─────────────────────────────────────────

  Future<PermissionState> _checkIosLocalNetwork() async {
    try {
      final result = await _channel.invokeMethod<String>('checkLocalNetwork');
      return _parseState(result);
    } on MissingPluginException {
      return PermissionState.granted;
    } on Object {
      return PermissionState.unknown;
    }
  }

  Future<PermissionState> _requestIosLocalNetwork() async {
    try {
      final result =
          await _channel.invokeMethod<String>('requestLocalNetwork');
      return _parseState(result);
    } on MissingPluginException {
      return PermissionState.granted;
    } on Object {
      return PermissionState.unknown;
    }
  }

  // ── Android Nearby Devices ────────────────────────────────────

  Future<PermissionState> _checkAndroidNearbyDevices() async {
    try {
      final result =
          await _channel.invokeMethod<String>('checkNearbyDevices');
      return _parseState(result);
    } on MissingPluginException {
      return PermissionState.granted;
    } on Object {
      return PermissionState.unknown;
    }
  }

  Future<PermissionState> _requestAndroidNearbyDevices() async {
    try {
      final result =
          await _channel.invokeMethod<String>('requestNearbyDevices');
      return _parseState(result);
    } on MissingPluginException {
      return PermissionState.granted;
    } on Object {
      return PermissionState.unknown;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  static PermissionState _parseState(String? s) {
    switch (s) {
      case 'granted':
        return PermissionState.granted;
      case 'denied':
        return PermissionState.denied;
      case 'restricted':
        return PermissionState.restricted;
      default:
        return PermissionState.unknown;
    }
  }
}

enum PermissionState { unknown, granted, denied, restricted }
