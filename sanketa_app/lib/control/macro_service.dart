import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class MacroStep {
  MacroStep({required this.action, this.argument, this.delayMs = 300});
  final String action;
  final String? argument;
  final int delayMs;

  Map<String, dynamic> toJson() => {
        'action': action,
        if (argument != null) 'argument': argument,
        'delayMs': delayMs,
      };

  factory MacroStep.fromJson(Map<String, dynamic> j) => MacroStep(
        action: j['action'] as String,
        argument: j['argument'] as String?,
        delayMs: (j['delayMs'] as num?)?.toInt() ?? 300,
      );
}

class Macro {
  Macro({String? id, required this.name, this.icon, required this.steps})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  final String id;
  final String name;
  final String? icon;
  final List<MacroStep> steps;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory Macro.fromJson(Map<String, dynamic> j) => Macro(
        id: j['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: j['name'] as String,
        steps: (j['steps'] as List)
            .cast<Map<String, dynamic>>()
            .map(MacroStep.fromJson)
            .toList(),
      );
}

class MacroService extends ChangeNotifier {
  List<Macro> macros = [];
  bool _isRecording = false;
  List<MacroStep> _recorded = [];
  String? _playingId;

  bool get isRecording => _isRecording;
  int get recordedStepCount => _recorded.length;
  String? get playingMacroId => _playingId;
  bool get isRunning => _playingId != null;
  String? get runningMacroName =>
      _playingId == null ? null : macros.where((m) => m.id == _playingId).firstOrNull?.name;

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/macros.json');
  }

  Future<void> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = await f.readAsString();
        macros = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(Macro.fromJson)
            .toList();
        notifyListeners();
      }
    } on Object {
      // Best-effort.
    }
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(macros.map((m) => m.toJson()).toList()));
  }

  void startRecording() {
    _isRecording = true;
    _recorded = [];
    notifyListeners();
  }

  void recordStep(String action, {String? argument}) {
    if (!_isRecording) return;
    _recorded.add(MacroStep(action: action, argument: argument));
    notifyListeners();
  }

  void cancelRecording() {
    _isRecording = false;
    _recorded = [];
    notifyListeners();
  }

  void stopRecording(String name) {
    if (!_isRecording || _recorded.isEmpty) {
      cancelRecording();
      return;
    }
    final macro = Macro(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      steps: List.of(_recorded),
    );
    macros.add(macro);
    _isRecording = false;
    _recorded = [];
    unawaited(_save());
    notifyListeners();
  }

  void addMacro(Macro macro) {
    macros.add(macro);
    unawaited(_save());
    notifyListeners();
  }

  void deleteMacro(String id) {
    macros.removeWhere((m) => m.id == id);
    unawaited(_save());
    notifyListeners();
  }

  void removeMacro(int index) {
    if (index >= 0 && index < macros.length) {
      macros.removeAt(index);
      unawaited(_save());
      notifyListeners();
    }
  }

  void recordAction(String action) => recordStep(action);

  bool _stopRequested = false;

  Future<void> play(
    Macro macro,
    Future<void> Function(MacroStep step) executor,
  ) async {
    if (_playingId != null) return;
    _playingId = macro.id;
    _stopRequested = false;
    notifyListeners();

    for (final step in macro.steps) {
      if (_stopRequested) break;
      await executor(step);
      await Future<void>.delayed(Duration(milliseconds: step.delayMs));
    }

    _playingId = null;
    _stopRequested = false;
    notifyListeners();
  }

  void stopPlayback() {
    _stopRequested = true;
    _playingId = null;
    notifyListeners();
  }

  Future<void> run(
    Macro macro,
    Future<void> Function(MacroStep step) executor,
  ) =>
      play(macro, executor);

  void stop() => stopPlayback();
}
