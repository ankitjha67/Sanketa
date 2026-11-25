import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesService extends ChangeNotifier {
  bool _simpleMode = false;

  bool get isSimpleMode => _simpleMode;

  Future<void> load() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _simpleMode = json['simpleMode'] as bool? ?? false;
      }
    } on Object {
      // Best-effort.
    }
    notifyListeners();
  }

  void toggleSimpleMode() {
    _simpleMode = !_simpleMode;
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({'simpleMode': _simpleMode}));
    } on Object {
      // Best-effort.
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/preferences.json');
  }
}
