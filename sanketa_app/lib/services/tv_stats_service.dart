import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sanketa_adapters/sanketa_adapters.dart' as adapters;

/// Periodically collects and exposes TV performance stats via ADB.
class TvStatsService extends ChangeNotifier {
  adapters.AdbClient? _adb;
  Timer? _pollTimer;
  bool _disposed = false;

  bool _connected = false;
  bool get isConnected => _connected;
  bool _connecting = false;
  bool get isConnecting => _connecting;
  String? _error;
  String? get error => _error;

  adapters.TvMemoryStats? _memory;
  adapters.TvMemoryStats? get memory => _memory;

  adapters.TvCpuStats? _cpu;
  adapters.TvCpuStats? get cpu => _cpu;

  adapters.TvStorageStats? _storage;
  adapters.TvStorageStats? get storage => _storage;

  List<adapters.TvProcess> _processes = [];
  List<adapters.TvProcess> get processes => _processes;

  Future<void> connectAndPoll(String host, {int port = 5555}) async {
    if (_disposed || _connecting) return;
    _connecting = true;
    _error = null;
    notifyListeners();

    try {
      _adb = adapters.AdbClient(host: host, port: port);
      await _adb!.connect();
      _connected = true;
      await refresh();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
          const Duration(seconds: 5), (_) => _pollIfAlive());
    } on Object catch (e) {
      _connected = false;
      _error = 'Could not connect via ADB. Enable ADB over WiFi on the TV.';
      assert(() { debugPrint('[TvStats] connect error: $e'); return true; }());
    } finally {
      if (!_disposed) {
        _connecting = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    if (_adb == null || !_connected || _disposed) return;
    try {
      final results = await Future.wait([
        _adb!.getMemoryStats(),
        _adb!.getCpuStats(),
        _adb!.getStorageStats(),
        _adb!.getTopProcesses(),
      ]);
      if (_disposed) return;
      _memory = results[0] as adapters.TvMemoryStats;
      _cpu = results[1] as adapters.TvCpuStats;
      _storage = results[2] as adapters.TvStorageStats;
      _processes = results[3] as List<adapters.TvProcess>;
      _error = null;
      notifyListeners();
    } on Object catch (e) {
      assert(() { debugPrint('[TvStats] refresh error: $e'); return true; }());
      if (!_disposed) {
        _error = 'Lost connection to the TV.';
        _connected = false;
        notifyListeners();
      }
    }
  }

  void _pollIfAlive() {
    if (!_disposed && _connected) {
      unawaited(refresh());
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      await _adb?.disconnect();
    } on Object {
      // Best-effort cleanup.
    }
    _adb = null;
    _connected = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    unawaited(disconnect());
    super.dispose();
  }
}
