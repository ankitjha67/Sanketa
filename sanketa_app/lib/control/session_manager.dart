import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

void _smLog(String msg) {
  assert(() {
    debugPrint('[SessionMgr] $msg');
    return true;
  }());
}

enum ConnectionState { disconnected, connecting, connected, reconnecting }

class SavedDevice {
  const SavedDevice({
    required this.deviceId,
    required this.displayName,
    required this.host,
    this.port,
    required this.brand,
    required this.type,
    required this.transport,
    this.adapterId,
    this.metadata = const {},
  });

  final String deviceId;
  final String displayName;
  final String host;
  final int? port;
  final String brand;
  final String type;
  final String transport;
  final String? adapterId;
  final Map<String, String> metadata;

  factory SavedDevice.fromDevice(core.DiscoveredDevice d) => SavedDevice(
        deviceId: d.device.id,
        displayName: d.device.displayName,
        host: d.device.host ?? '',
        port: d.device.port,
        brand: d.device.brand.name,
        type: d.device.type.name,
        transport: d.device.transport.name,
        adapterId: d.adapterId,
        metadata: d.metadata,
      );

  factory SavedDevice.fromJson(Map<String, dynamic> j) => SavedDevice(
        deviceId: j['deviceId'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        host: j['host'] as String? ?? '',
        port: j['port'] as int?,
        brand: j['brand'] as String? ?? 'other',
        type: j['type'] as String? ?? 'tv',
        transport: j['transport'] as String? ?? 'network',
        adapterId: j['adapterId'] as String?,
        metadata: (j['metadata'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, '$v')) ??
            const {},
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'displayName': displayName,
        'host': host,
        if (port != null) 'port': port,
        'brand': brand,
        'type': type,
        'transport': transport,
        if (adapterId != null) 'adapterId': adapterId,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  core.DiscoveredDevice toDiscoveredDevice() {
    final brandFamily = core.BrandFamily.values.firstWhere(
      (b) => b.name == brand,
      orElse: () => core.BrandFamily.other,
    );
    final deviceType = core.DeviceType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => core.DeviceType.tv,
    );
    final transportEnum = core.Transport.values.firstWhere(
      (t) => t.name == transport,
      orElse: () => core.Transport.network,
    );
    return core.DiscoveredDevice(
      device: core.Device(
        id: deviceId,
        brand: brandFamily,
        type: deviceType,
        transport: transportEnum,
        friendlyName: displayName,
        host: host.isEmpty ? null : host,
        port: port,
      ),
      badges: const {},
      sources: const {core.DiscoverySource.manual},
      adapterId: adapterId,
      metadata: metadata,
    );
  }
}

/// Persists last-connected device and manages auto-reconnect with exponential
/// backoff. Zero network calls on its own — delegates actual connection back to
/// [RemoteController] via [onReconnect].
class SessionManager extends ChangeNotifier {
  static const _fileName = 'session.json';
  static const _initialDelay = Duration(seconds: 1);
  static const _maxDelay = Duration(seconds: 30);

  ConnectionState _state = ConnectionState.disconnected;
  SavedDevice? _lastDevice;
  int _attempt = 0;
  Timer? _backoffTimer;
  bool _disposed = false;

  ConnectionState get connectionState => _state;
  SavedDevice? get lastDevice => _lastDevice;
  int get attempt => _attempt;
  bool get isReconnecting => _state == ConnectionState.reconnecting;

  /// Called by SessionManager when a reconnect attempt should be made.
  /// RemoteController sets this after construction.
  void Function(core.DiscoveredDevice device)? onReconnect;

  // ── Persistence ────────────────────────────────────────────────

  Future<void> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _lastDevice = SavedDevice.fromJson(json);
    } on Object {
      // Corrupt or missing — start fresh.
    }
  }

  Future<void> saveDevice(core.DiscoveredDevice d) async {
    _lastDevice = SavedDevice.fromDevice(d);
    _attempt = 0;
    _setState(ConnectionState.connected);
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(_lastDevice!.toJson()));
    } on Object {
      // Best-effort persistence.
    }
  }

  Future<void> forgetDevice() async {
    cancelReconnect();
    _lastDevice = null;
    _setState(ConnectionState.disconnected);
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } on Object {
      // Best-effort.
    }
  }

  // ── Connection state ───────────────────────────────────────────

  void markConnecting() => _setState(ConnectionState.connecting);

  void markConnected() {
    _attempt = 0;
    cancelReconnect();
    _setState(ConnectionState.connected);
  }

  void markDisconnected() => _setState(ConnectionState.disconnected);

  // ── Exponential backoff reconnect ──────────────────────────────

  void scheduleReconnect() {
    if (_disposed) return;
    final device = _lastDevice;
    if (device == null) return;

    _backoffTimer?.cancel();
    _setState(ConnectionState.reconnecting);

    final delay = _backoffDelay(_attempt);
    _attempt++;
    _smLog('reconnect #$_attempt in ${delay.inSeconds}s');

    _backoffTimer = Timer(delay, () {
      if (_disposed) return;
      final cb = onReconnect;
      if (cb != null) {
        cb(device.toDiscoveredDevice());
      }
    });
  }

  void cancelReconnect() {
    _backoffTimer?.cancel();
    _backoffTimer = null;
    _attempt = 0;
    if (_state == ConnectionState.reconnecting) {
      _setState(ConnectionState.disconnected);
    }
  }

  Duration _backoffDelay(int attempt) {
    final ms = _initialDelay.inMilliseconds * pow(2, min(attempt, 14));
    final clamped = min(ms.toInt(), _maxDelay.inMilliseconds);
    // Add up to 20% jitter to avoid thundering-herd.
    final jitter = Random().nextInt(max(1, clamped ~/ 5));
    return Duration(milliseconds: clamped + jitter);
  }

  // ── Auto-reconnect on startup ──────────────────────────────────

  /// If a saved device exists, trigger a reconnect to it.
  /// Called from RemoteController after the engine has had time to discover.
  void tryResumeSession() {
    if (_disposed || _lastDevice == null) return;
    final cb = onReconnect;
    if (cb != null) {
      _setState(ConnectionState.connecting);
      cb(_lastDevice!.toDiscoveredDevice());
    }
  }

  // ── Internals ──────────────────────────────────────────────────

  void _setState(ConnectionState s) {
    if (_disposed || _state == s) return;
    _state = s;
    notifyListeners();
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  void dispose() {
    _disposed = true;
    _backoffTimer?.cancel();
    super.dispose();
  }
}
