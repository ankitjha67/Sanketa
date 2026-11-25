import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _LogEntry {
  _LogEntry({required this.timestamp, required this.level, required this.message});

  factory _LogEntry.fromJson(Map<String, dynamic> j) => _LogEntry(
    timestamp: DateTime.tryParse(j['ts'] as String? ?? '') ?? DateTime.now(),
    level: j['level'] as String? ?? 'info',
    message: j['msg'] as String? ?? '',
  );

  final DateTime timestamp;
  final String level;
  final String message;

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'level': level,
    'msg': message,
  };
}

class DiagnosticLogScreen extends StatefulWidget {
  const DiagnosticLogScreen({super.key});

  @override
  State<DiagnosticLogScreen> createState() => _DiagnosticLogScreenState();
}

class _DiagnosticLogScreenState extends State<DiagnosticLogScreen> {
  List<_LogEntry> _logs = [];
  String _filter = 'all';
  bool _loading = true;

  static const _levels = ['all', 'info', 'warn', 'error', 'debug'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/diagnostic_log.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _logs = list.map((j) => _LogEntry.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (_logs.isEmpty) {
      _logs = _sampleLogs();
      _saveLogs();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_LogEntry> _sampleLogs() {
    final now = DateTime.now();
    return [
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 30)), level: 'info', message: 'App started'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 28)), level: 'info', message: 'Discovery: scanning local network'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 27)), level: 'info', message: 'Found device: Samsung TV at 192.168.1.42'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 26)), level: 'debug', message: 'WebSocket handshake initiated'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 25)), level: 'info', message: 'Connected to Samsung TV (Tizen 7.0)'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 15)), level: 'warn', message: 'Network latency: 180ms (threshold: 100ms)'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 10)), level: 'info', message: 'Key sent: power'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 8)), level: 'info', message: 'Key sent: volumeUp'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 5)), level: 'error', message: 'Connection lost: timeout after 5000ms'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 4)), level: 'info', message: 'Reconnecting...'),
      _LogEntry(timestamp: now.subtract(const Duration(minutes: 3)), level: 'info', message: 'Reconnected to Samsung TV'),
    ];
  }

  Future<void> _saveLogs() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_logs.map((l) => l.toJson()).toList()));
  }

  List<_LogEntry> get _filtered => _filter == 'all'
      ? _logs
      : _logs.where((l) => l.level == _filter).toList();

  void _clearLogs() {
    setState(() => _logs.clear());
    _saveLogs();
  }

  void _copyLogs() {
    final text = _filtered.map((l) =>
      '[${l.timestamp.toIso8601String()}] [${l.level.toUpperCase()}] ${l.message}',
    ).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_filtered.length} log entries copied')),
    );
  }

  int _countLevel(String level) => _logs.where((l) => l.level == level).length;

  Color _levelColor(String level) {
    switch (level) {
      case 'error': return hex(AppColors.error);
      case 'warn': return hex(AppColors.alertAmber);
      case 'debug': return hex(AppColors.outline);
      default: return hex(AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Diagnostics',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _copyLogs,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.copy, size: 18, color: hex(AppColors.primary)),
            ),
          ),
          GestureDetector(
            onTap: _clearLogs,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.delete_sweep, size: 20, color: hex(AppColors.error)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _statsRow(),
          _filterChips(),
          Expanded(child: _logList()),
        ],
      ),
    );
  }

  Widget _statsRow() => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
    child: Row(
      children: [
        _stat('Total', _logs.length, AppColors.onSurface),
        const SizedBox(width: 8),
        _stat('Errors', _countLevel('error'), AppColors.error),
        const SizedBox(width: 8),
        _stat('Warnings', _countLevel('warn'), AppColors.alertAmber),
      ],
    ),
  );

  Widget _stat(String label, int count, int color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        children: [
          Text('$count', style: gfont(AppType.bodyMd, color: hex(color), weight: FontWeight.w700)),
          Text(label, style: gfont(AppType.bodySm, color: hex(color), size: 9)),
        ],
      ),
    ),
  );

  Widget _filterChips() => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _levels.map((l) {
          final active = _filter == l;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = l),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.6 : 0.2),
                  ),
                ),
                child: Text(l == 'all' ? 'All' : l[0].toUpperCase() + l.substring(1),
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 11)),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _logList() {
    final logs = _filtered.reversed.toList();
    if (logs.isEmpty) {
      return Center(
        child: Text('No log entries',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (_, i) => _logRow(logs[i]),
    );
  }

  Widget _logRow(_LogEntry log) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.sm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: _levelColor(log.level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.message,
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11)),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
