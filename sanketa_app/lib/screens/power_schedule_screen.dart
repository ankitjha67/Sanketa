import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _PowerEvent {
  _PowerEvent({required this.time, required this.action, this.days = const [1, 2, 3, 4, 5, 6, 7], this.enabled = true});

  factory _PowerEvent.fromJson(Map<String, dynamic> j) => _PowerEvent(
    time: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
    action: j['action'] as String,
    days: (j['days'] as List).cast<int>(),
    enabled: j['enabled'] as bool? ?? true,
  );

  TimeOfDay time;
  String action;
  List<int> days;
  bool enabled;

  Map<String, dynamic> toJson() => {
    'hour': time.hour,
    'minute': time.minute,
    'action': action,
    'days': days,
    'enabled': enabled,
  };
}

class PowerScheduleScreen extends StatefulWidget {
  const PowerScheduleScreen({super.key});

  @override
  State<PowerScheduleScreen> createState() => _PowerScheduleScreenState();
}

class _PowerScheduleScreenState extends State<PowerScheduleScreen> {
  List<_PowerEvent> _events = [];
  bool _loading = true;

  static const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/power_schedule.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _events = list.map((j) => _PowerEvent.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_events.map((e) => e.toJson()).toList()));
  }

  Future<void> _addEvent() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() {
      _events.add(_PowerEvent(time: time, action: 'Power Off'));
    });
    _save();
  }

  void _delete(int index) {
    setState(() => _events.removeAt(index));
    _save();
  }

  void _runNow(_PowerEvent event) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.power);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  String _daysLabel(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.toSet().containsAll({1, 2, 3, 4, 5}) && days.length == 5) return 'Weekdays';
    if (days.toSet().containsAll({6, 7}) && days.length == 2) return 'Weekends';
    return days.map((d) => _dayNames[d]).join(', ');
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
        title: Text('Power Schedule',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        backgroundColor: hex(AppColors.primary),
        child: Icon(Icons.add, color: hex(AppColors.onPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          if (_events.isEmpty)
            _emptyState()
          else ...[
            Text('Schedules (${_events.length})',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._events.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _eventCard(e.value, e.key),
            )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(Icons.schedule, size: 40, color: hex(AppColors.primary)),
        const SizedBox(height: 8),
        Text('Power Scheduler',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Auto power on/off at scheduled times',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      ],
    ),
  );

  Widget _emptyState() => Column(
    children: [
      const SizedBox(height: 24),
      Icon(Icons.schedule, size: 40, color: hex(AppColors.outline)),
      const SizedBox(height: 8),
      Text('No power schedules',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Tap + to schedule auto power on or off.',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
    ],
  );

  Widget _eventCard(_PowerEvent event, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTime(event.time),
                style: gfont(AppType.headlineMd, color: hex(event.enabled ? AppColors.onSurface : AppColors.outline), size: 20, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(event.action,
                style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w600)),
            Text(_daysLabel(event.days),
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _runNow(event),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text('Run', style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 9, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() => event.enabled = !event.enabled);
            _save();
          },
          child: _toggle(event.enabled),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _delete(index),
          child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
        ),
      ],
    ),
  );

  Widget _toggle(bool value) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 36,
    height: 20,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: hex(value ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: value ? 1 : 0.3),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hex(value ? AppColors.onPrimary : AppColors.outline),
        ),
      ),
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Schedule automatic power on/off for your TV. The phone must be on the same network at the scheduled time for the command to reach the TV.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
