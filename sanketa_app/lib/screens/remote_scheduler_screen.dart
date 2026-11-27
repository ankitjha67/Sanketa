import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class RemoteSchedulerScreen extends StatefulWidget {
  const RemoteSchedulerScreen({super.key});

  @override
  State<RemoteSchedulerScreen> createState() => _RemoteSchedulerScreenState();
}

class _RemoteSchedulerScreenState extends State<RemoteSchedulerScreen> {
  bool _loading = true;
  final _tasks = <_ScheduledTask>[];

  static const _actions = <(String, IconData)>[
    ('Power On', Icons.power_settings_new),
    ('Power Off', Icons.power_off),
    ('Switch to HDMI 1', Icons.settings_input_hdmi),
    ('Launch Netflix', Icons.movie),
    ('Launch YouTube', Icons.play_circle),
    ('Mute', Icons.volume_off),
    ('Set Volume 50%', Icons.volume_up),
    ('Open Home', Icons.home),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_scheduler.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        for (final item in data) {
          final m = item as Map<String, dynamic>;
          _tasks.add(_ScheduledTask(
            action: m['action'] as String? ?? '',
            time: m['time'] as String? ?? '12:00',
            enabled: m['enabled'] as bool? ?? true,
            repeat: m['repeat'] as String? ?? 'Once',
          ));
        }
      }
    } on Object { /* defaults */ }
    if (_tasks.isEmpty) {
      _tasks.addAll([
        _ScheduledTask(action: 'Power On', time: '07:00', enabled: true, repeat: 'Daily'),
        _ScheduledTask(action: 'Power Off', time: '23:00', enabled: true, repeat: 'Daily'),
        _ScheduledTask(action: 'Launch Netflix', time: '19:00', enabled: false, repeat: 'Weekdays'),
      ]);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_tasks
        .map((t) => {
              'action': t.action,
              'time': t.time,
              'enabled': t.enabled,
              'repeat': t.repeat,
            })
        .toList()));
  }

  void _toggleTask(int i) {
    HapticFeedback.lightImpact();
    setState(() => _tasks[i].enabled = !_tasks[i].enabled);
    _save();
  }

  void _deleteTask(int i) {
    HapticFeedback.lightImpact();
    setState(() => _tasks.removeAt(i));
    _save();
  }

  void _addTask() {
    HapticFeedback.lightImpact();
    setState(() {
      _tasks.add(_ScheduledTask(
        action: 'Power On',
        time: '12:00',
        enabled: true,
        repeat: 'Once',
      ));
    });
    _save();
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
        title: Text('Remote Scheduler',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _addTask,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          ..._tasks.asMap().entries.map((e) => _taskCard(e.key, e.value)),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statsRow() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${_tasks.length}', 'Total'),
            _stat('${_tasks.where((t) => t.enabled).length}', 'Active'),
            _stat('${_tasks.where((t) => !t.enabled).length}', 'Paused'),
          ],
        ),
      );

  Widget _stat(String val, String label) => Column(
        children: [
          Text(val,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.primary),
                  weight: FontWeight.w700,
                  size: 16)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _taskCard(int index, _ScheduledTask task) {
    final actionIcon = _actions.firstWhere(
      (a) => a.$1 == task.action,
      orElse: () => ('Unknown', Icons.help),
    ).$2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hex(task.enabled ? AppColors.primary : AppColors.surfaceContainerLow)
              .withValues(alpha: task.enabled ? 0.06 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(task.enabled ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: task.enabled ? 0.2 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(actionIcon, size: 20, color: hex(AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.action,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 11)),
                  Text('${task.time}  •  ${task.repeat}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleTask(index),
              child: Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(task.enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: task.enabled ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: task.enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(task.enabled ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteTask(index),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      ),
    );
  }

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
                'Schedule remote actions to run at specific times. Set power on/off, app launches, and volume changes on a schedule. Supports once, daily, weekday, and weekend repeats.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _ScheduledTask {
  String action;
  String time;
  bool enabled;
  String repeat;

  _ScheduledTask({
    required this.action,
    required this.time,
    required this.enabled,
    required this.repeat,
  });
}
