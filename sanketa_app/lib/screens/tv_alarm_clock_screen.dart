import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvAlarmClockScreen extends StatefulWidget {
  const TvAlarmClockScreen({super.key});

  @override
  State<TvAlarmClockScreen> createState() => _TvAlarmClockScreenState();
}

class _TvAlarmClockScreenState extends State<TvAlarmClockScreen> {
  int _hour = 7;
  int _minute = 0;
  int _soundIdx = 0;
  int _volumePercent = 50;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _activeDays = <int>{0, 1, 2, 3, 4};

  static const _sounds = <(String, IconData, int)>[
    ('Gentle Chime', Icons.notifications, AppColors.primary),
    ('Morning Bird', Icons.spa, AppColors.signalEmerald),
    ('Classic Buzz', Icons.alarm, AppColors.alertAmber),
    ('News Jingle', Icons.newspaper, AppColors.secondary),
    ('Nature Stream', Icons.water, AppColors.tertiary),
  ];

  final _alarms = <_Alarm>[
    _Alarm(hour: 7, minute: 0, label: 'Weekday Wake', enabled: true,
        days: {0, 1, 2, 3, 4}),
    _Alarm(hour: 9, minute: 30, label: 'Weekend Brunch', enabled: false,
        days: {5, 6}),
    _Alarm(hour: 6, minute: 15, label: 'Gym Morning', enabled: false,
        days: {0, 2, 4}),
  ];

  String _fmtTime(int h, int m) {
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }

  void _setAlarm() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.home);
    setState(() {
      _alarms.insert(0, _Alarm(
        hour: _hour,
        minute: _minute,
        label: 'New Alarm',
        enabled: true,
        days: Set.of(_activeDays),
      ));
    });
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Alarm set for ${_fmtTime(_hour, _minute)}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _toggleAlarm(int idx) {
    setState(() => _alarms[idx].enabled = !_alarms[idx].enabled);
    HapticFeedback.selectionClick();
  }

  void _removeAlarm(int idx) {
    setState(() => _alarms.removeAt(idx));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _timePicker(),
          const SizedBox(height: AppSpacing.md),
          _dayPicker(),
          const SizedBox(height: AppSpacing.md),
          _soundPicker(),
          const SizedBox(height: AppSpacing.md),
          _volumeSlider(),
          const SizedBox(height: AppSpacing.md),
          _setButton(),
          const SizedBox(height: AppSpacing.lg),
          if (_alarms.isNotEmpty) ...[
            Text('Saved Alarms',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: AppSpacing.sm),
            ..._alarms.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _alarmCard(e.key, e.value),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
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
            Icon(Icons.alarm, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Wake Up with TV',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Set alarms that turn on your TV at the right time',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _timePicker() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _spinnerColumn('Hour', _hour, 0, 23, (v) => setState(() => _hour = v)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(':',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 36,
                      weight: FontWeight.w700)),
            ),
            _spinnerColumn('Min', _minute, 0, 59, (v) => setState(() => _minute = v)),
            const SizedBox(width: 20),
            Text(_fmtTime(_hour, _minute),
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600,
                    size: 14)),
          ],
        ),
      );

  Widget _spinnerColumn(
      String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            onChanged(value >= max ? min : value + 1);
            HapticFeedback.selectionClick();
          },
          child: Icon(Icons.arrow_drop_up,
              size: 32, color: hex(AppColors.primary)),
        ),
        Text(value.toString().padLeft(2, '0'),
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 36,
                weight: FontWeight.w700)),
        GestureDetector(
          onTap: () {
            onChanged(value <= min ? max : value - 1);
            HapticFeedback.selectionClick();
          },
          child: Icon(Icons.arrow_drop_down,
              size: 32, color: hex(AppColors.primary)),
        ),
        Text(label,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.outline), size: 10)),
      ],
    );
  }

  Widget _dayPicker() => Row(
        children: _days.asMap().entries.map((e) {
          final active = _activeDays.contains(e.key);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (active) {
                      _activeDays.remove(e.key);
                    } else {
                      _activeDays.add(e.key);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(e.value,
                        style: gfont(AppType.bodySm,
                            color: hex(active
                                ? AppColors.primary
                                : AppColors.outline),
                            weight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            size: 10)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _soundPicker() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _sounds.asMap().entries.map((e) {
            final active = e.key == _soundIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _soundIdx = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2,
                          size: 14, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _volumeSlider() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Wake Volume',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('$_volumePercent%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _volumePercent.toDouble(),
              min: 10,
              max: 100,
              activeColor: hex(AppColors.alertAmber),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) => setState(() => _volumePercent = v.round()),
            ),
          ],
        ),
      );

  Widget _setButton() => GestureDetector(
        onTap: _setAlarm,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(AppColors.alertAmber).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.alertAmber).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm_add,
                  size: 22, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 8),
              Text('Set Alarm',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.alertAmber),
                      weight: FontWeight.w700,
                      size: 15)),
            ],
          ),
        ),
      );

  Widget _alarmCard(int idx, _Alarm alarm) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(alarm.enabled
                  ? AppColors.alertAmber
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: alarm.enabled ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(alarm.enabled
                    ? AppColors.alertAmber
                    : AppColors.outlineVariant)
                .withValues(alpha: alarm.enabled ? 0.25 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fmtTime(alarm.hour, alarm.minute),
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 20,
                          weight: FontWeight.w700)),
                  Text(alarm.label,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                  const SizedBox(height: 2),
                  Text(
                    alarm.days
                        .map((d) => _days[d])
                        .join(', '),
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleAlarm(idx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(alarm.enabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(alarm.enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(alarm.enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 10)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeAlarm(idx),
              child: Icon(Icons.close,
                  size: 18, color: hex(AppColors.outline)),
            ),
          ],
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
                'Set alarms to wake up with your TV. '
                'Choose days, sound, and volume. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Alarm {
  int hour;
  int minute;
  String label;
  bool enabled;
  Set<int> days;
  _Alarm({
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    required this.days,
  });
}
