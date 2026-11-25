import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sanketa_adapters/sanketa_adapters.dart' as adapters;
import 'package:sanketa_core/sanketa_core.dart' as core;

/// Connects to a TV via ADB and manages bloatware disable/enable operations.
class DebloatService extends ChangeNotifier {
  adapters.AdbClient? _adb;
  bool _disposed = false;

  // Connection state
  bool _connected = false;
  bool get isConnected => _connected;
  bool _connecting = false;
  bool get isConnecting => _connecting;
  String? _connectionError;
  String? get connectionError => _connectionError;

  // Bloatware database
  List<core.BloatwareEntry> _allEntries = [];
  List<core.BloatwareEntry> get allEntries => _allEntries;

  // Detected state on TV
  final Map<String, bool> _packageStates = {};
  Map<String, bool> get packageStates => _packageStates;

  // Operation tracking
  final Set<String> _pendingOps = {};
  bool isOperating(String pkg) => _pendingOps.contains(pkg);

  String? _operationError;
  String? get operationError => _operationError;

  int _disabledCount = 0;
  int get disabledCount => _disabledCount;

  Future<void> loadDatabase() async {
    try {
      final json = await rootBundle.loadString('assets/debloat/bloatware_db.json');
      final list = jsonDecode(json) as List;
      _allEntries = list
          .map((e) => core.BloatwareEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!_disposed) notifyListeners();
    } on Object catch (e) {
      assert(() { debugPrint('[Debloat] Failed to load database: $e'); return true; }());
    }
  }

  List<core.BloatwareEntry> entriesForBrand(String brand) {
    final b = brand.toLowerCase();
    return _allEntries.where((e) {
      return e.brands.any((eb) =>
          eb.toLowerCase() == b || eb.toLowerCase() == 'all_android_tv');
    }).toList()
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
  }

  List<core.BloatwareEntry> get safeEntries =>
      _allEntries.where((e) => e.safeToDisable).toList();

  Map<core.BloatCategory, List<core.BloatwareEntry>> groupByCategory(
      List<core.BloatwareEntry> entries) {
    final map = <core.BloatCategory, List<core.BloatwareEntry>>{};
    for (final e in entries) {
      (map[e.category] ??= []).add(e);
    }
    return map;
  }

  Future<void> connectToTv(String host, {int port = 5555}) async {
    if (_disposed || _connecting) return;
    _connecting = true;
    _connectionError = null;
    notifyListeners();

    try {
      // Disconnect the previous client to destroy its socket before
      // opening a new one (prevents orphaned-socket auth storms).
      if (_adb != null) {
        await _adb!.disconnect();
        _adb = null;
      }
      _adb = adapters.AdbClient(host: host, port: port);
      final ok = await _adb!.connect();
      _connected = ok;
      if (!ok) {
        _connectionError =
            'TV did not respond on ADB port. Make sure ADB over WiFi is enabled.';
        return;
      }
      await _scanPackageStates();
    } on Object catch (e) {
      _connected = false;
      _connectionError =
          'Could not connect via ADB. Make sure ADB over WiFi is enabled on the TV.\n'
          'On Android TV: Settings > Device Preferences > About > Build (tap 7 times) > '
          'Developer Options > ADB Debugging > ON > ADB over Network.';
      assert(() { debugPrint('[Debloat] ADB connect error: $e'); return true; }());
    } finally {
      if (!_disposed) {
        _connecting = false;
        notifyListeners();
      }
    }
  }

  Future<void> _scanPackageStates() async {
    if (_adb == null || !_connected) return;
    try {
      final packages = await _adb!.listPackages();
      final disabled = await _adb!.listPackages(disabledOnly: true);
      _packageStates.clear();
      final disabledNames = disabled.toSet();
      for (final p in packages) {
        _packageStates[p] = !disabledNames.contains(p);
      }
      _disabledCount = disabledNames
          .where((d) => _allEntries.any((e) => e.package == d))
          .length;
      if (!_disposed) notifyListeners();
    } on Object catch (e) {
      assert(() { debugPrint('[Debloat] Package scan error: $e'); return true; }());
    }
  }

  bool isPackageEnabled(String packageName) =>
      _packageStates[packageName] ?? true;

  bool isPackageInstalled(String packageName) =>
      _packageStates.containsKey(packageName);

  Future<bool> disablePackage(core.BloatwareEntry entry) async {
    if (_adb == null || !_connected || !entry.safeToDisable) return false;
    _pendingOps.add(entry.package);
    _operationError = null;
    notifyListeners();

    try {
      final ok = await _adb!.disablePackage(entry.package);
      if (ok) {
        _packageStates[entry.package] = false;
        _disabledCount++;
      } else {
        _operationError = 'Failed to disable ${entry.name}. The TV may not allow it.';
      }
      return ok;
    } on Object catch (e) {
      _operationError = 'Error disabling ${entry.name}: check ADB connection.';
      assert(() { debugPrint('[Debloat] disable error: $e'); return true; }());
      return false;
    } finally {
      _pendingOps.remove(entry.package);
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> enablePackage(core.BloatwareEntry entry) async {
    if (_adb == null || !_connected) return false;
    _pendingOps.add(entry.package);
    _operationError = null;
    notifyListeners();

    try {
      final ok = await _adb!.enablePackage(entry.package);
      if (ok) {
        _packageStates[entry.package] = true;
        _disabledCount = (_disabledCount - 1).clamp(0, 9999);
      }
      return ok;
    } on Object catch (e) {
      _operationError = 'Error re-enabling ${entry.name}.';
      assert(() { debugPrint('[Debloat] enable error: $e'); return true; }());
      return false;
    } finally {
      _pendingOps.remove(entry.package);
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> disableAllSafe(List<core.BloatwareEntry> entries) async {
    for (final e in entries) {
      if (e.safeToDisable && isPackageEnabled(e.package) && isPackageInstalled(e.package)) {
        await disablePackage(e);
        if (!_connected) break;
      }
    }
  }

  Future<void> restoreAll(List<core.BloatwareEntry> entries) async {
    for (final e in entries) {
      if (!isPackageEnabled(e.package) && isPackageInstalled(e.package)) {
        await enablePackage(e);
        if (!_connected) break;
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _adb?.disconnect();
    } on Object {
      // Best-effort cleanup.
    }
    _adb = null;
    _connected = false;
    _packageStates.clear();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
