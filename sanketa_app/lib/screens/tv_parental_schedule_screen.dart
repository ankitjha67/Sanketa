import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class TvParentalScheduleScreen extends StatefulWidget {
  const TvParentalScheduleScreen({super.key});

  @override
  State<TvParentalScheduleScreen> createState() =>
      _TvParentalScheduleScreenState();
}

class _TvParentalScheduleScreenState extends State<TvParentalScheduleScreen> {
  bool _enabled = true;
  final List<_Schedule> _schedules = [
    _Schedule('School Nights', TimeOfDay(hour: 20, minute: 0),
        TimeOfDay(hour: 7, minute: 0), {0, 1, 2, 3, 4}, true),
    _Schedule('Weekends', TimeOfDay(hour: 22, minute: 0),
        TimeOfDay(hour: 8, minute: 0), {5, 6}, true),
  ];

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/parental_schedule.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        setState(() {
          _enabled = data['enabled'] as bool? ?? true;
          final list = data['schedules'] as List<dynamic>? ?? [];
          _schedules.clear();
          for (final s in list) {
            final m = s as Map<String, dynamic>;
            _schedules.add(_Schedule(
              m['name'] as String? ?? 'Block',
              _parseTime(m['from'] as String? ?? '20:00'),
              _parseTime(m['to'] as String? ?? '07:00'),
              (m['days'] as List<dynamic>? ?? [])
                  .map((e) => e as int)
                  .toSet(),
              m['active'] as bool? ?? true,
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/parental_schedule.json');
      await f.writeAsString(jsonEncode({
        'enabled': _enabled,
        'schedules': _schedules
            .map((s) => {
                  'name': s.name,
                  'from': _fmtTime(s.from),
                  'to': _fmtTime(s.to),
                  'days': s.days.toList(),
                  'active': s.active,
                })
            .toList(),
      }));
    } catch (_) {}
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtTimeDisplay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  void _addSchedule() {
    setState(() {
      _schedules.add(_Schedule(
        'Block ${_schedules.length + 1}',
        const TimeOfDay(hour: 21, minute: 0),
        const TimeOfDay(hour: 6, minute: 0),
        {0, 1, 2, 3, 4, 5, 6},
        true,
      ));
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  void _removeSchedule(int idx) {
    setState(() => _schedules.removeAt(idx));
    _save();
    HapticFeedback.mediumImpact();
  }

  void _toggleSchedule(int idx) {
    setState(() => _schedules[idx].active = !_schedules[idx].active);
    _save();
    HapticFeedback.selectionClick();
  }

  void _toggleDay(int sIdx, int day) {
    setState(() {
      final s = _schedules[sIdx];
      if (s.days.contains(day)) {
        s.days.remove(day);
      } else {
        s.days.add(day);
      }
    });
    _save();
    HapticFeedback.selectionClick();
  }

  Future<void> _pickTime(int sIdx, bool isFrom) async {
    final cur = isFrom ? _schedules[sIdx].from : _schedules[sIdx].to;
    final picked = await showTimePicker(context: context, initialTime: cur);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _schedules[sIdx].from = picked;
        } else {
          _schedules[sIdx].to = picked;
        }
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Parental Schedule',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _addSchedule,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _masterToggle(),
          const SizedBox(height: AppSpacing.lg),
          ..._schedules.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _scheduleCard(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Parental Schedules',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Block TV access during certain hours by day of week',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(_enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(_enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
                  .withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.shield,
                size: 20,
                color: hex(
                    _enabled ? AppColors.signalEmerald : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Parental Controls',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
            ),
            Switch(
              value: _enabled,
              activeThumbColor: hex(AppColors.signalEmerald),
              onChanged: (v) {
                setState(() => _enabled = v);
                _save();
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
      );

  Widget _scheduleCard(int idx, _Schedule s) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(s.active ? AppColors.primary : AppColors.surfaceContainerLow)
              .withValues(alpha: s.active ? 0.06 : 1),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(s.active ? AppColors.primary : AppColors.outlineVariant)
                  .withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block,
                    size: 18,
                    color: hex(s.active ? AppColors.primary : AppColors.outline)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 14)),
                ),
                GestureDetector(
                  onTap: () => _toggleSchedule(idx),
                  child: Icon(
                    s.active ? Icons.toggle_on : Icons.toggle_off,
                    size: 32,
                    color: hex(s.active
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeSchedule(idx),
                  child: Icon(Icons.close, size: 18, color: hex(AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _timePill('From', _fmtTimeDisplay(s.from), () => _pickTime(idx, true)),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward, size: 14, color: hex(AppColors.outline)),
                const SizedBox(width: 10),
                _timePill('To', _fmtTimeDisplay(s.to), () => _pickTime(idx, false)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(7, (d) {
                final active = s.days.contains(d);
                return GestureDetector(
                  onTap: () => _toggleDay(idx, d),
                  child: Container(
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text(_days[d],
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outline),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 9)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _timePill(String label, String time, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
              Text(time,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 12)),
            ],
          ),
        ),
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
                'Schedule TV access blocks by time and day of week. '
                'When active, TV commands are disabled during blocked hours. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Schedule {
  String name;
  TimeOfDay from;
  TimeOfDay to;
  Set<int> days;
  bool active;
  _Schedule(this.name, this.from, this.to, this.days, this.active);
}
