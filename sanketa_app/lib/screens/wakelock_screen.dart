import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../theme/tokens_x.dart';

class WakelockScreen extends StatefulWidget {
  const WakelockScreen({super.key});

  @override
  State<WakelockScreen> createState() => _WakelockScreenState();
}

class _WakelockScreenState extends State<WakelockScreen> {
  bool _enabled = false;
  int _timeoutIndex = 0;
  double _brightness = 0.7;

  static const _timeouts = [
    ('Always On', 0, '~120 mA/h'),
    ('5 minutes', 5, '~10 mA'),
    ('10 minutes', 10, '~20 mA'),
    ('30 minutes', 30, '~60 mA'),
    ('1 hour', 60, '~120 mA'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/wakelock_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? false;
        _timeoutIndex = j['timeoutIndex'] as int? ?? 0;
        _brightness = (j['brightness'] as num?)?.toDouble() ?? 0.7;
      }
    } on Object { /* defaults */ }
    if (_enabled) WakelockPlus.enable();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'timeoutIndex': _timeoutIndex,
      'brightness': _brightness,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Screen Wakelock',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statusCard(),
          const SizedBox(height: AppSpacing.md),
          _masterToggle(),
          const SizedBox(height: AppSpacing.md),
          if (_enabled) ...[
            _timeoutSelector(),
            const SizedBox(height: AppSpacing.md),
            _brightnessControl(),
            const SizedBox(height: AppSpacing.md),
            _batteryEstimate(),
            const SizedBox(height: AppSpacing.md),
          ],
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_enabled ? AppColors.primary : AppColors.surfaceContainerLow).withValues(alpha: _enabled ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_enabled ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(
          _enabled ? Icons.visibility : Icons.visibility_off,
          size: 48,
          color: hex(_enabled ? AppColors.primary : AppColors.outline),
        ),
        const SizedBox(height: 8),
        Text(
          _enabled ? 'Screen Will Stay On' : 'Normal Screen Timeout',
          style: gfont(AppType.bodyMd, color: hex(_enabled ? AppColors.primary : AppColors.onSurface), weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _enabled
              ? _timeouts[_timeoutIndex].$1 == 'Always On'
                  ? 'Screen stays on while Sanketa is active'
                  : 'Screen stays on for ${_timeouts[_timeoutIndex].$1} of inactivity'
              : 'Phone follows system screen timeout setting',
          textAlign: TextAlign.center,
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
        ),
      ],
    ),
  );

  Widget _masterToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.screen_lock_portrait, size: 20, color: hex(AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keep Screen On', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Prevent screen from turning off',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        Switch(
          value: _enabled,
          activeTrackColor: hex(AppColors.primary),
          onChanged: (v) {
            setState(() => _enabled = v);
            if (v) {
              WakelockPlus.enable();
            } else {
              WakelockPlus.disable();
            }
            _save();
          },
        ),
      ],
    ),
  );

  Widget _timeoutSelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeout Duration', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(_timeouts.length, (i) {
            final active = i == _timeoutIndex;
            return GestureDetector(
              onTap: () {
                setState(() => _timeoutIndex = i);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh).withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Text(_timeouts[i].$1,
                    style: gfont(AppType.bodySm, color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _brightnessControl() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.brightness_6, size: 16, color: hex(AppColors.alertAmber)),
            const SizedBox(width: 8),
            Text('Screen Brightness', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${(_brightness * 100).round()}%',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.alertAmber),
            inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            thumbColor: hex(AppColors.alertAmber),
            trackHeight: 4,
          ),
          child: Slider(
            value: _brightness,
            min: 0.1,
            max: 1.0,
            onChanged: (v) => setState(() => _brightness = v),
            onChangeEnd: (_) => _save(),
          ),
        ),
        Text('Lower brightness saves battery during long remote sessions',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
      ],
    ),
  );

  Widget _batteryEstimate() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.battery_charging_full, size: 20, color: hex(AppColors.signalEmerald)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimated Battery Usage',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.signalEmerald), weight: FontWeight.w600, size: 12)),
              Text('${_timeouts[_timeoutIndex].$3} extra drain per session',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11)),
            ],
          ),
        ),
      ],
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
            'Keeps your phone screen on while controlling the TV so you don\'t have to keep unlocking it. Automatically reverts when you leave Sanketa.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
