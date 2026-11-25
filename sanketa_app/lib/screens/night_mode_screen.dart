import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class NightModeConfig {
  NightModeConfig({
    this.enabled = false,
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 7,
    this.endMinute = 0,
    this.maxVolume = 15,
    this.autoMute = false,
    this.dimBacklight = true,
    this.reduceBrightness = true,
    this.sleepTimerMinutes = 0,
  });

  bool enabled;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  int maxVolume;
  bool autoMute;
  bool dimBacklight;
  bool reduceBrightness;
  int sleepTimerMinutes;

  String get startLabel =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  bool get isActiveNow {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'maxVolume': maxVolume,
    'autoMute': autoMute,
    'dimBacklight': dimBacklight,
    'reduceBrightness': reduceBrightness,
    'sleepTimerMinutes': sleepTimerMinutes,
  };

  factory NightModeConfig.fromJson(Map<String, dynamic> j) => NightModeConfig(
    enabled: j['enabled'] as bool? ?? false,
    startHour: j['startHour'] as int? ?? 22,
    startMinute: j['startMinute'] as int? ?? 0,
    endHour: j['endHour'] as int? ?? 7,
    endMinute: j['endMinute'] as int? ?? 0,
    maxVolume: j['maxVolume'] as int? ?? 15,
    autoMute: j['autoMute'] as bool? ?? false,
    dimBacklight: j['dimBacklight'] as bool? ?? true,
    reduceBrightness: j['reduceBrightness'] as bool? ?? true,
    sleepTimerMinutes: j['sleepTimerMinutes'] as int? ?? 0,
  );
}

class NightModeScreen extends StatefulWidget {
  const NightModeScreen({super.key});

  @override
  State<NightModeScreen> createState() => _NightModeScreenState();
}

class _NightModeScreenState extends State<NightModeScreen> {
  late NightModeConfig _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/night_mode.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        _config = NightModeConfig.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } else {
        _config = NightModeConfig();
      }
    } on Object {
      _config = NightModeConfig();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_config.toJson()));
  }

  void _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _config.startHour, minute: _config.startMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: hex(AppColors.primaryContainer),
            surface: hex(AppColors.surfaceContainerLowest),
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        _config.startHour = time.hour;
        _config.startMinute = time.minute;
      });
      _save();
    }
  }

  void _pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _config.endHour, minute: _config.endMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: hex(AppColors.primaryContainer),
            surface: hex(AppColors.surfaceContainerLowest),
          ),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        _config.endHour = time.hour;
        _config.endMinute = time.minute;
      });
      _save();
    }
  }

  void _applyNow() {
    final c = RemoteScope.of(context);
    if (_config.autoMute) {
      c.key(core.Key.mute);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Night mode applied'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
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
        title: Text('Night Mode',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _masterToggle(),
          const SizedBox(height: AppSpacing.lg),
          _scheduleSection(),
          const SizedBox(height: AppSpacing.lg),
          _volumeSection(),
          const SizedBox(height: AppSpacing.lg),
          _displaySection(),
          const SizedBox(height: AppSpacing.lg),
          _sleepTimerSection(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _masterToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: panel(
      fill: _config.enabled ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
      radius: AppRadii.lg,
      borderOpacity: _config.enabled ? 0.4 : 0.15,
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(_config.enabled ? AppColors.tertiary : AppColors.outlineVariant)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Icon(
            _config.enabled ? Icons.bedtime : Icons.bedtime_outlined,
            size: 24,
            color: hex(_config.enabled ? AppColors.tertiary : AppColors.outline),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Night Mode',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
              Text(
                _config.enabled
                    ? (_config.isActiveNow ? 'Active now' : 'Scheduled ${_config.startLabel} – ${_config.endLabel}')
                    : 'Disabled',
                style: gfont(AppType.bodySm,
                    color: hex(_config.enabled && _config.isActiveNow
                        ? AppColors.tertiary
                        : AppColors.outline),
                    size: 11),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _config.enabled = !_config.enabled);
            _save();
          },
          child: Container(
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              color: hex(_config.enabled ? AppColors.tertiary : AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: _config.enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hex(_config.enabled ? AppColors.onPrimary : AppColors.outline),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _scheduleSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _timeButton('Start', _config.startLabel, _pickStartTime)),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward, size: 14, color: hex(AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(child: _timeButton('End', _config.endLabel, _pickEndTime)),
          ],
        ),
      ],
    ),
  );

  Widget _timeButton(String label, String time, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        children: [
          Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 2),
          Text(time,
              style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 20, weight: FontWeight.w700)),
        ],
      ),
    ),
  );

  Widget _volumeSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volume',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.volume_off, 'Auto-mute when active', _config.autoMute, (v) {
          setState(() => _config.autoMute = v);
          _save();
        }),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.volume_down, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: hex(AppColors.tertiary),
                  inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                  thumbColor: hex(AppColors.tertiary),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _config.maxVolume.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) {
                    setState(() => _config.maxVolume = v.round());
                  },
                  onChangeEnd: (_) => _save(),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text('${_config.maxVolume}',
                  textAlign: TextAlign.center,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 12)),
            ),
          ],
        ),
        Text('  Max volume during night mode',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
      ],
    ),
  );

  Widget _displaySection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.brightness_low, 'Reduce brightness', _config.reduceBrightness, (v) {
          setState(() => _config.reduceBrightness = v);
          _save();
        }),
        const SizedBox(height: 6),
        _toggleRow(Icons.settings_brightness, 'Dim backlight', _config.dimBacklight, (v) {
          setState(() => _config.dimBacklight = v);
          _save();
        }),
      ],
    ),
  );

  Widget _sleepTimerSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auto Sleep Timer',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [0, 15, 30, 60, 90, 120].map((m) {
            final active = _config.sleepTimerMinutes == m;
            return GestureDetector(
              onTap: () {
                setState(() => _config.sleepTimerMinutes = m);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.tertiaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.3 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.tertiary : AppColors.outlineVariant)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  m == 0 ? 'Off' : '${m}m',
                  style: gfont(AppType.bodySm,
                      color: hex(active ? AppColors.tertiary : AppColors.onSurface),
                      weight: active ? FontWeight.w700 : FontWeight.w400,
                      size: 12),
                ),
              ),
            );
          }).toList(),
        ),
        if (_config.sleepTimerMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'TV will power off ${_config.sleepTimerMinutes} minutes after night mode activates.',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10),
            ),
          ),
      ],
    ),
  );

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.tertiary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)))),
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: hex(value ? AppColors.tertiary : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hex(value ? AppColors.onPrimary : AppColors.outline),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
    onTap: _applyNow,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bedtime, size: 16, color: hex(AppColors.tertiary)),
          const SizedBox(width: 8),
          Text('Apply Night Mode Now',
              style: gfont(AppType.bodyMd, color: hex(AppColors.tertiary), weight: FontWeight.w600)),
        ],
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
            'Night mode adjusts volume and display settings during evening hours. The app must be running for automatic activation.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
