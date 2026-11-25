import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

class ParentalControlService extends ChangeNotifier {
  String? _pin;
  bool _locked = false;
  Set<core.Key> _blockedKeys = {};
  int _maxDailyMinutes = 0;
  int _usedMinutes = 0;
  Timer? _usageTick;

  bool get isEnabled => _pin != null;
  bool get isLocked => _locked;
  Set<core.Key> get blockedKeys => _blockedKeys;
  int get maxDailyMinutes => _maxDailyMinutes;
  int get usedMinutes => _usedMinutes;
  bool get timeLimitExceeded =>
      _maxDailyMinutes > 0 && _usedMinutes >= _maxDailyMinutes;

  static const _defaultBlocked = {
    core.Key.power,
    core.Key.powerOn,
    core.Key.powerOff,
  };

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/parental.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _pin = j['pin'] as String?;
        _locked = j['locked'] as bool? ?? false;
        _maxDailyMinutes = (j['maxDailyMinutes'] as num?)?.toInt() ?? 0;
        _usedMinutes = (j['usedMinutes'] as num?)?.toInt() ?? 0;
        final keys = (j['blockedKeys'] as List?)?.cast<String>() ?? [];
        _blockedKeys = keys
            .map((n) => core.Key.values.where((k) => k.name == n).firstOrNull)
            .whereType<core.Key>()
            .toSet();
        notifyListeners();
      }
    } on Object {
      // best-effort
    }
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'pin': _pin,
      'locked': _locked,
      'maxDailyMinutes': _maxDailyMinutes,
      'usedMinutes': _usedMinutes,
      'blockedKeys': _blockedKeys.map((k) => k.name).toList(),
    }));
  }

  bool verifyPin(String pin) => _pin != null && _pin == pin;

  void setPin(String pin) {
    _pin = pin;
    _locked = true;
    if (_blockedKeys.isEmpty) _blockedKeys = Set.of(_defaultBlocked);
    unawaited(_save());
    notifyListeners();
  }

  void clearPin(String pin) {
    if (!verifyPin(pin)) return;
    _pin = null;
    _locked = false;
    _blockedKeys = {};
    _maxDailyMinutes = 0;
    _usedMinutes = 0;
    _usageTick?.cancel();
    unawaited(_save());
    notifyListeners();
  }

  void unlock(String pin) {
    if (!verifyPin(pin)) return;
    _locked = false;
    unawaited(_save());
    notifyListeners();
  }

  void lock() {
    if (_pin == null) return;
    _locked = true;
    unawaited(_save());
    notifyListeners();
  }

  void setBlockedKeys(Set<core.Key> keys) {
    _blockedKeys = keys;
    unawaited(_save());
    notifyListeners();
  }

  void setMaxDailyMinutes(int minutes) {
    _maxDailyMinutes = minutes;
    unawaited(_save());
    notifyListeners();
  }

  bool isKeyBlocked(core.Key key) => _locked && _blockedKeys.contains(key);

  void startUsageTracking() {
    _usageTick?.cancel();
    _usageTick = Timer.periodic(const Duration(minutes: 1), (_) {
      _usedMinutes++;
      if (timeLimitExceeded) lock();
      unawaited(_save());
      notifyListeners();
    });
  }

  void stopUsageTracking() => _usageTick?.cancel();

  void resetDailyUsage() {
    _usedMinutes = 0;
    unawaited(_save());
    notifyListeners();
  }

  @override
  void dispose() {
    _usageTick?.cancel();
    super.dispose();
  }
}
