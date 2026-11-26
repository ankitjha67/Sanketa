import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _LogEntry {
  _LogEntry({required this.command, required this.timestamp, this.target = ''});

  factory _LogEntry.fromJson(Map<String, dynamic> j) => _LogEntry(
        command: j['command'] as String,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
        target: j['target'] as String? ?? '',
      );

  final String command;
  final DateTime timestamp;
  final String target;

  Map<String, dynamic> toJson() => {
        'command': command,
        'timestamp': timestamp.toIso8601String(),
        'target': target,
      };
}

class RemoteLogScreen extends StatefulWidget {
  const RemoteLogScreen({super.key});

  @override
  State<RemoteLogScreen> createState() => _RemoteLogScreenState();
}

class _RemoteLogScreenState extends State<RemoteLogScreen> {
  List<_LogEntry> _logs = [];
  bool _loading = true;
  int _filterIndex = 0;

  static const _filters = ['All', 'Keys', 'Launch', 'Text', 'Power'];
  static const _sampleLogs = <(String, String)>[
    ('Key: OK', 'Samsung TV'),
    ('Key: Volume Up', 'Samsung TV'),
    ('Key: Volume Up', 'Samsung TV'),
    ('Launch: YouTube', 'Samsung TV'),
    ('Key: Home', 'Samsung TV'),
    ('Key: Power', 'Samsung TV'),
    ('Text: hello', 'Samsung TV'),
    ('Key: Back', 'Samsung TV'),
    ('Launch: Netflix', 'Samsung TV'),
    ('Key: Mute', 'Samsung TV'),
    ('Key: Down', 'Samsung TV'),
    ('Key: OK', 'Samsung TV'),
    ('Key: Power', 'Samsung TV'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_log.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _logs = list
            .map((j) => _LogEntry.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } on Object {/* defaults */}
    if (_logs.isEmpty) _generateSample();
    if (mounted) setState(() => _loading = false);
  }

  void _generateSample() {
    final now = DateTime.now();
    _logs = _sampleLogs.asMap().entries.map((e) {
      return _LogEntry(
        command: e.value.$1,
        timestamp: now.subtract(Duration(minutes: e.key * 2)),
        target: e.value.$2,
      );
    }).toList();
    _save();
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(
        jsonEncode(_logs.map((l) => l.toJson()).toList()));
  }

  void _clearLog() {
    setState(() => _logs.clear());
    _save();
  }

  void _copyAll() {
    final text = _logs
        .map((l) => '${_fmtTime(l.timestamp)} | ${l.command} | ${l.target}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(seconds: 1),
      ));
  }

  List<_LogEntry> get _filtered {
    if (_filterIndex == 0) return _logs;
    final filter = _filters[_filterIndex];
    return _logs.where((l) {
      switch (filter) {
        case 'Keys':
          return l.command.startsWith('Key:');
        case 'Launch':
          return l.command.startsWith('Launch:');
        case 'Text':
          return l.command.startsWith('Text:');
        case 'Power':
          return l.command.contains('Power');
        default:
          return true;
      }
    }).toList();
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} $ampm';
  }

  IconData _iconFor(String cmd) {
    if (cmd.contains('Power')) return Icons.power_settings_new;
    if (cmd.contains('Volume')) return Icons.volume_up;
    if (cmd.contains('Mute')) return Icons.volume_off;
    if (cmd.startsWith('Launch')) return Icons.launch;
    if (cmd.startsWith('Text')) return Icons.keyboard;
    if (cmd.contains('Home')) return Icons.home;
    if (cmd.contains('Back')) return Icons.arrow_back;
    return Icons.touch_app;
  }

  int _colorFor(String cmd) {
    if (cmd.contains('Power')) return AppColors.error;
    if (cmd.contains('Volume') || cmd.contains('Mute')) return AppColors.alertAmber;
    if (cmd.startsWith('Launch')) return AppColors.signalEmerald;
    if (cmd.startsWith('Text')) return AppColors.tertiary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Log',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_logs.isNotEmpty) ...[
            GestureDetector(
              onTap: _copyAll,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.copy, size: 18, color: hex(AppColors.primary)),
              ),
            ),
            GestureDetector(
              onTap: _clearLog,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.delete_sweep, size: 20, color: hex(AppColors.error)),
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statsCard(),
          const SizedBox(height: AppSpacing.md),
          _filterBar(),
          const SizedBox(height: AppSpacing.md),
          if (_filtered.isEmpty)
            _emptyState()
          else ...[
            Text('${_filtered.length} Entries',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._filtered.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _logRow(l),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statsCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('Total', '${_logs.length}'),
            _stat('Keys', '${_logs.where((l) => l.command.startsWith('Key:')).length}'),
            _stat('Launch', '${_logs.where((l) => l.command.startsWith('Launch:')).length}'),
            _stat('Power', '${_logs.where((l) => l.command.contains('Power')).length}'),
          ],
        ),
      );

  Widget _stat(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.primary),
                  size: 18,
                  weight: FontWeight.w700)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _filterBar() => SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _filterIndex;
            return GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Center(
                  child: Text(_filters[i],
                      style: gfont(AppType.bodySm,
                          color: hex(
                              active ? AppColors.primary : AppColors.outline),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              ),
            );
          },
        ),
      );

  Widget _logRow(_LogEntry l) {
    final color = _colorFor(l.command);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(l.command), size: 16, color: hex(color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.command,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 11)),
                Text('${l.target} · ${_fmtTime(l.timestamp)}',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.history, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No log entries',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Commands you send will appear here.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View history of all remote commands sent to your TV. Filter by type, copy the full log, or clear it. All logs are stored locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
