import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenDimmerScreen extends StatefulWidget {
  const ScreenDimmerScreen({super.key});

  @override
  State<ScreenDimmerScreen> createState() => _ScreenDimmerScreenState();
}

class _ScreenDimmerScreenState extends State<ScreenDimmerScreen> {
  double _brightness = 50;
  bool _autoDim = false;
  int _scheduleIndex = -1;
  bool _loading = true;

  static const _presets = [
    ('Full', 100.0, Icons.wb_sunny),
    ('Bright', 75.0, Icons.light_mode),
    ('Normal', 50.0, Icons.tonality),
    ('Dim', 25.0, Icons.dark_mode),
    ('Minimal', 10.0, Icons.brightness_3),
  ];

  static const _schedules = [
    ('Evening (6 PM)', '18:00', 40.0),
    ('Night (9 PM)', '21:00', 20.0),
    ('Late Night (11 PM)', '23:00', 10.0),
    ('Morning (7 AM)', '07:00', 75.0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/screen_dimmer.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _brightness = (data['brightness'] as num?)?.toDouble() ?? 50;
        _autoDim = data['autoDim'] as bool? ?? false;
        _scheduleIndex = data['scheduleIndex'] as int? ?? -1;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'brightness': _brightness,
      'autoDim': _autoDim,
      'scheduleIndex': _scheduleIndex,
    }));
  }

  void _applyBrightness() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Brightness set to ${_brightness.round()}%'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _selectPreset(int idx) {
    setState(() => _brightness = _presets[idx].$2);
    _applyBrightness();
  }

  void _selectSchedule(int idx) {
    setState(() {
      _scheduleIndex = idx == _scheduleIndex ? -1 : idx;
      if (_scheduleIndex >= 0) {
        _brightness = _schedules[idx].$3;
        _autoDim = true;
      }
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
        title: Text('Screen Dimmer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _brightnessControl(),
          const SizedBox(height: AppSpacing.md),
          _presetRow(),
          const SizedBox(height: AppSpacing.md),
          _autoDimToggle(),
          const SizedBox(height: AppSpacing.md),
          _scheduleSection(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() {
    final alpha = (_brightness / 100).clamp(0.1, 1.0);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: alpha,
              child: Icon(Icons.tv,
                  size: 56, color: hex(AppColors.primary)),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(AppColors.surface).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('${_brightness.round()}% Brightness',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brightnessControl() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Brightness',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text('${_brightness.round()}%',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.brightness_3, size: 16, color: hex(AppColors.outline)),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: hex(AppColors.alertAmber),
                    inactiveColor:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                    onChanged: (v) => setState(() => _brightness = v),
                  ),
                ),
                Icon(Icons.wb_sunny, size: 16, color: hex(AppColors.alertAmber)),
              ],
            ),
          ],
        ),
      );

  Widget _presetRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final active = (_brightness - _presets[i].$2).abs() < 1;
                return GestureDetector(
                  onTap: () => _selectPreset(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.alertAmber : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.alertAmber : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_presets[i].$3,
                            size: 14,
                            color: hex(active ? AppColors.alertAmber : AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(_presets[i].$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.alertAmber : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _autoDimToggle() => GestureDetector(
        onTap: () {
          setState(() => _autoDim = !_autoDim);
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Dim',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Automatically adjust based on time of day',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_autoDim ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _autoDim ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _autoDim ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(
                          _autoDim ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _scheduleSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dim Schedules',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._schedules.asMap().entries.map((e) {
              final active = e.key == _scheduleIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _selectSchedule(e.key),
                  child: Row(
                    children: [
                      Icon(
                        active ? Icons.check_circle : Icons.radio_button_off,
                        size: 18,
                        color: hex(active
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                size: 12)),
                      ),
                      Text('${e.value.$3.round()}%',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline),
                              weight: FontWeight.w600,
                              size: 10)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyBrightness,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.alertAmber).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.brightness_6,
                  size: 20, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 8),
              Text('Apply Brightness',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.alertAmber),
                      weight: FontWeight.w600)),
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
                'Reduce TV screen brightness for comfortable night viewing. Use quick presets or the slider for precise control. Enable auto-dim for automatic adjustment based on time.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
