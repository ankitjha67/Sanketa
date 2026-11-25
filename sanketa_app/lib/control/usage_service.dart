import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class UsageService extends ChangeNotifier {
  final List<UsageSession> _sessions = [];
  DateTime? _currentStart;
  bool _tracking = false;

  List<UsageSession> get sessions => List.unmodifiable(_sessions);
  bool get isTracking => _tracking;

  int get todayMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) => s.start.isAfter(today))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  Map<int, int> get weeklyMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final map = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    for (final s in _sessions) {
      if (s.start.isAfter(start)) {
        map[s.start.weekday] = (map[s.start.weekday] ?? 0) + s.durationMinutes;
      }
    }
    return map;
  }

  Map<int, int> get hourlyDistribution {
    final map = <int, int>{for (var i = 0; i < 24; i++) i: 0};
    for (final s in _sessions) {
      map[s.start.hour] = (map[s.start.hour] ?? 0) + s.durationMinutes;
    }
    return map;
  }

  void startSession() {
    if (_tracking) return;
    _currentStart = DateTime.now();
    _tracking = true;
    notifyListeners();
  }

  void endSession() {
    if (!_tracking || _currentStart == null) return;
    final end = DateTime.now();
    final dur = end.difference(_currentStart!).inMinutes;
    if (dur > 0) {
      _sessions.add(UsageSession(start: _currentStart!, durationMinutes: dur));
    }
    _currentStart = null;
    _tracking = false;
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/usage.json');
      if (!f.existsSync()) return;
      final list = jsonDecode(await f.readAsString()) as List;
      _sessions.clear();
      for (final e in list) {
        _sessions.add(UsageSession(
          start: DateTime.parse(e['start'] as String),
          durationMinutes: e['minutes'] as int,
        ));
      }
      notifyListeners();
    } on Object {
      // first launch or corrupt file
    }
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/usage.json');
      final list = _sessions
          .map((s) => {'start': s.start.toIso8601String(), 'minutes': s.durationMinutes})
          .toList();
      await f.writeAsString(jsonEncode(list));
    } on Object {
      // non-critical
    }
  }

  Future<void> clearHistory() async {
    _sessions.clear();
    notifyListeners();
    _save();
  }

  @override
  void dispose() {
    if (_tracking) endSession();
    super.dispose();
  }
}

class UsageSession {
  const UsageSession({required this.start, required this.durationMinutes});
  final DateTime start;
  final int durationMinutes;
}
