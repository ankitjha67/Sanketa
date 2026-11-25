import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class BackupService extends ChangeNotifier {
  List<BackupEntry> _backups = [];
  bool _busy = false;

  List<BackupEntry> get backups => List.unmodifiable(_backups);
  bool get isBusy => _busy;

  static const _supportFiles = [
    'macros.json',
    'search_shortcuts.json',
    'custom_layouts.json',
    'parental.json',
  ];
  static const _docFiles = [
    'usage.json',
  ];

  Future<void> loadBackupList() async {
    final dir = await _backupDir();
    if (!dir.existsSync()) return;
    _backups = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sanketa'))
        .map((f) => BackupEntry(
              path: f.path,
              name: f.uri.pathSegments.last.replaceAll('.sanketa', ''),
              created: f.statSync().modified,
              sizeBytes: f.lengthSync(),
            ))
        .toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    notifyListeners();
  }

  Future<String> createBackup(String name) async {
    _busy = true;
    notifyListeners();

    try {
      final support = await getApplicationSupportDirectory();
      final docs = await getApplicationDocumentsDirectory();
      final payload = <String, dynamic>{};

      for (final file in _supportFiles) {
        final f = File('${support.path}/$file');
        if (f.existsSync()) {
          payload[file] = await f.readAsString();
        }
      }
      for (final file in _docFiles) {
        final f = File('${docs.path}/$file');
        if (f.existsSync()) {
          payload[file] = await f.readAsString();
        }
      }

      final envelope = {
        'version': 1,
        'created': DateTime.now().toIso8601String(),
        'name': name,
        'data': payload,
      };

      final dir = await _backupDir();
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dest = File('${dir.path}/${name}_$ts.sanketa');
      await dest.writeAsString(jsonEncode(envelope));

      await loadBackupList();
      return dest.path;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<int> restoreBackup(String path) async {
    _busy = true;
    notifyListeners();

    try {
      final f = File(path);
      if (!f.existsSync()) return 0;

      final envelope = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>? ?? {};
      final support = await getApplicationSupportDirectory();
      final docs = await getApplicationDocumentsDirectory();
      var restored = 0;

      for (final entry in data.entries) {
        final dir = _supportFiles.contains(entry.key) ? support : docs;
        if (_supportFiles.contains(entry.key) ||
            _docFiles.contains(entry.key)) {
          final dest = File('${dir.path}/${entry.key}');
          await dest.writeAsString(entry.value as String);
          restored++;
        }
      }

      return restored;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> deleteBackup(String path) async {
    final f = File(path);
    if (f.existsSync()) await f.delete();
    await loadBackupList();
  }

  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/backups');
  }
}

class BackupEntry {
  const BackupEntry({
    required this.path,
    required this.name,
    required this.created,
    required this.sizeBytes,
  });
  final String path;
  final String name;
  final DateTime created;
  final int sizeBytes;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
