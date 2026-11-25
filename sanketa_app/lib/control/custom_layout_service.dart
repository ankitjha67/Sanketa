import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class RemoteButton {
  RemoteButton({required this.label, required this.action, this.argument, this.icon});
  final String label;
  final String action;
  final String? argument;
  final String? icon;

  Map<String, dynamic> toJson() => {
        'label': label,
        'action': action,
        if (argument != null) 'argument': argument,
        if (icon != null) 'icon': icon,
      };

  factory RemoteButton.fromJson(Map<String, dynamic> j) => RemoteButton(
        label: j['label'] as String,
        action: j['action'] as String,
        argument: j['argument'] as String?,
        icon: j['icon'] as String?,
      );
}

class RemoteLayout {
  RemoteLayout({required this.name, required this.buttons, this.columns = 3});
  final String name;
  final List<RemoteButton> buttons;
  final int columns;

  Map<String, dynamic> toJson() => {
        'name': name,
        'columns': columns,
        'buttons': buttons.map((b) => b.toJson()).toList(),
      };

  factory RemoteLayout.fromJson(Map<String, dynamic> j) => RemoteLayout(
        name: j['name'] as String,
        columns: (j['columns'] as num?)?.toInt() ?? 3,
        buttons: (j['buttons'] as List)
            .cast<Map<String, dynamic>>()
            .map(RemoteButton.fromJson)
            .toList(),
      );
}

class CustomLayoutService extends ChangeNotifier {
  List<RemoteLayout> layouts = [];
  int activeIndex = -1;

  RemoteLayout? get activeLayout =>
      activeIndex >= 0 && activeIndex < layouts.length
          ? layouts[activeIndex]
          : null;

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/custom_layouts.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = await f.readAsString();
        layouts = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(RemoteLayout.fromJson)
            .toList();
        notifyListeners();
      }
    } on Object {
      // Best-effort.
    }
  }

  Future<void> save() async {
    final f = await _file;
    await f.writeAsString(
        jsonEncode(layouts.map((l) => l.toJson()).toList()));
  }

  void addLayout(RemoteLayout l) {
    layouts.add(l);
    save();
    notifyListeners();
  }

  void removeLayout(int i) {
    layouts.removeAt(i);
    if (activeIndex >= layouts.length) activeIndex = -1;
    save();
    notifyListeners();
  }

  void setActive(int i) {
    activeIndex = i;
    notifyListeners();
  }

  void clearActive() {
    activeIndex = -1;
    notifyListeners();
  }
}
