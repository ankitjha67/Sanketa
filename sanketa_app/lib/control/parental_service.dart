import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

class ParentalService extends ChangeNotifier {
  String? _pin;
  Set<String> _lockedKeys = {};
  Set<String> _lockedApps = {};
  bool _enabled = false;

  bool get enabled => _enabled;
  String? get pin => _pin;
  Set<String> get lockedKeys => _lockedKeys;
  Set<String> get lockedApps => _lockedApps;

  bool isKeyLocked(core.Key key) => _enabled && _lockedKeys.contains(key.name);
  bool isAppLocked(String app) => _enabled && _lockedApps.contains(app);

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/parental.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = await f.readAsString();
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _pin = j['pin'] as String?;
        _enabled = j['enabled'] as bool? ?? false;
        _lockedKeys = (j['lockedKeys'] as List?)
                ?.cast<String>()
                .toSet() ??
            {};
        _lockedApps = (j['lockedApps'] as List?)
                ?.cast<String>()
                .toSet() ??
            {};
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
      'enabled': _enabled,
      'lockedKeys': _lockedKeys.toList(),
      'lockedApps': _lockedApps.toList(),
    }));
  }

  void setPin(String newPin) {
    _pin = newPin;
    _save();
    notifyListeners();
  }

  void setEnabled(bool v) {
    _enabled = v;
    _save();
    notifyListeners();
  }

  void toggleKeyLock(core.Key key) {
    final name = key.name;
    if (_lockedKeys.contains(name)) {
      _lockedKeys.remove(name);
    } else {
      _lockedKeys.add(name);
    }
    _save();
    notifyListeners();
  }

  void toggleAppLock(String app) {
    if (_lockedApps.contains(app)) {
      _lockedApps.remove(app);
    } else {
      _lockedApps.add(app);
    }
    _save();
    notifyListeners();
  }

  bool verifyPin(String attempt) => attempt == _pin;

  void clearAll() {
    _pin = null;
    _enabled = false;
    _lockedKeys = {};
    _lockedApps = {};
    _save();
    notifyListeners();
  }
}
