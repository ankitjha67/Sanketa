import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Alarm {
  _Alarm({
    required this.hour,
    required this.minute,
    required this.label,
    required this.action,
    this.enabled = true,
    this.days = const [true, true, true, true, true, true, true],
  });

  factory _Alarm.fromJson(Map<String, dynamic> j) => _Alarm(
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        label: j['label'] as String,
        action: j['action'] as String,
        enabled: j['enabled'] as bool? ?? true,
        days: (j['days'] as List?)?.cast<bool>() ??
            const [true, true, true, true, true, true, true],
      );

  int hour;
  int minute;
  String label;
  String action;
  bool enabled;
  List<bool> days;

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
        'label': label,
        'action': action,
        'enabled': enabled,
        'days': days,
      };

  String get timeStr {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  String get daysStr {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.every((d) => d)) return 'Every day';
    if (days[0] && days[1] && days[2] && days[3] && days[4] && !days[5] && !days[6]) return 'Weekdays';
    if (!days[0] && !days[1] && !days[2] && !days[3] && !days[4] && days[5] && days[6]) return 'Weekends';
    return days.asMap().entries.where((e) => e.value).map((e) => names[e.key]).join(', ');
  }
}

class TvAlarmScreen extends StatefulWidget {
  const TvAlarmScreen({super.key});

  @override
  State<TvAlarmScreen> createState() => _TvAlarmScreenState();
}

class _TvAlarmScreenState extends State<TvAlarmScreen> {
  List<_Alarm> _alarms = [];
  bool _loading = true;

  static const _actions = [
    ('Power On', Icons.power_settings_new),
    ('YouTube', Icons.play_circle),
    ('Netflix', Icons.movie),
    ('News Channel', Icons.newspaper),
    ('Music', Icons.music_note),
    ('Weather', Icons.cloud),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_alarms.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _alarms = list.map((j) => _Alarm.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_alarms.map((a) => a.toJson()).toList()));
  }

  void _addAlarm() {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    ).then((time) {
      if (time == null || !mounted) return;
      _showActionPicker(time);
    });
  }

  void _showActionPicker(TimeOfDay time) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wake Up To...',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 16,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(_actions.length, (i) {
              final action = _actions[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _alarms.add(_Alarm(
                        hour: time.hour,
                        minute: time.minute,
                        label: action.$1,
                        action: action.$1,
                      ));
                    });
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      children: [
                        Icon(action.$2, size: 20, color: hex(AppColors.primary)),
                        const SizedBox(width: 12),
                        Text(action.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _triggerAlarm(_Alarm alarm) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.power);
    if (alarm.action != 'Power On') {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) rc.launch(alarm.action);
      });
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Triggered: ${alarm.label}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _delete(int index) {
    setState(() => _alarms.removeAt(index));
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
        title: Text('TV Alarm',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hex(AppColors.primary),
        onPressed: _addAlarm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (_alarms.isEmpty)
            _emptyState()
          else ...[
            Text('Alarms (${_alarms.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._alarms.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _alarmCard(e.value, e.key),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.alarm, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('TV Alarm Clock',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Wake up to your TV turning on to your favourite app or channel',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _alarmCard(_Alarm alarm, int index) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alarm.timeStr,
                      style: gfont(AppType.headlineMd,
                          color: hex(alarm.enabled
                              ? AppColors.onSurface
                              : AppColors.outline),
                          size: 22,
                          weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${alarm.label} · ${alarm.daysStr}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _triggerAlarm(alarm),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(Icons.play_arrow,
                    size: 16, color: hex(AppColors.primary)),
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: alarm.enabled,
              activeTrackColor: hex(AppColors.primary),
              onChanged: (v) {
                setState(() => alarm.enabled = v);
                _save();
              },
            ),
            GestureDetector(
              onTap: () => _delete(index),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.alarm_off, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No alarms set',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap + to create a TV alarm.',
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
                'TV alarms turn on your TV and launch an app at the scheduled time. Your phone must be on the same network as the TV. Alarms are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
