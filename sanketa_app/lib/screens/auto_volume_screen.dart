import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AutoVolumeScreen extends StatefulWidget {
  const AutoVolumeScreen({super.key});

  @override
  State<AutoVolumeScreen> createState() => _AutoVolumeScreenState();
}

class _AutoVolumeScreenState extends State<AutoVolumeScreen> {
  bool _enabled = false;
  double _targetLevel = 50;
  int _modeIndex = 0;
  bool _nightBoost = false;
  bool _loading = true;

  static const _modes = <(String, IconData, int, String)>[
    ('Gentle', Icons.volume_down, AppColors.signalEmerald, 'Subtle adjustments'),
    ('Normal', Icons.volume_up, AppColors.primary, 'Balanced leveling'),
    ('Aggressive', Icons.surround_sound, AppColors.error, 'Maximum leveling'),
  ];

  static const _presets = <(String, double, int)>[
    ('Quiet', 25, AppColors.signalEmerald),
    ('Normal', 50, AppColors.primary),
    ('Loud', 75, AppColors.alertAmber),
    ('Max', 100, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/auto_volume.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = data['enabled'] as bool? ?? false;
        _targetLevel = (data['targetLevel'] as num?)?.toDouble() ?? 50;
        _modeIndex = data['modeIndex'] as int? ?? 0;
        _nightBoost = data['nightBoost'] as bool? ?? false;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'targetLevel': _targetLevel,
      'modeIndex': _modeIndex,
      'nightBoost': _nightBoost,
    }));
  }

  void _apply() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Auto volume ${_enabled ? "enabled" : "disabled"} at ${_targetLevel.round()}%'),
        duration: const Duration(seconds: 2),
      ));
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
        title: Text('Auto Volume',
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
          _enableToggle(),
          const SizedBox(height: AppSpacing.md),
          _targetSlider(),
          const SizedBox(height: AppSpacing.md),
          _quickPresets(),
          const SizedBox(height: AppSpacing.md),
          _modePicker(),
          const SizedBox(height: AppSpacing.md),
          _nightBoostToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
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
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.graphic_eq, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Auto Volume Leveling',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Automatically level volume across channels and content',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _enableToggle() => GestureDetector(
        onTap: () {
          setState(() => _enabled = !_enabled);
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
              Icon(Icons.volume_up, size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto Volume',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Level volume automatically',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_enabled ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _enabled ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _targetSlider() => Container(
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
                Text('Target Level',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text('${_targetLevel.round()}%',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Slider(
              value: _targetLevel,
              min: 10,
              max: 100,
              divisions: 18,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _targetLevel = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _quickPresets() => Row(
        children: _presets.map((p) {
          final active = (_targetLevel - p.$2).abs() < 1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _targetLevel = p.$2);
                _save();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? p.$3 : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hex(active ? p.$3 : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Center(
                  child: Text(p.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? p.$3 : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _modePicker() => Container(
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
            Text('Leveling Mode',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._modes.asMap().entries.map((e) {
              final m = e.value;
              final active = e.key == _modeIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _modeIndex = e.key);
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hex(active ? m.$3 : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: hex(active ? m.$3 : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(m.$2,
                            size: 20,
                            color: hex(active ? m.$3 : AppColors.outline)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.$1,
                                  style: gfont(AppType.bodyMd,
                                      color: hex(active
                                          ? m.$3
                                          : AppColors.onSurface),
                                      weight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      size: 12)),
                              Text(m.$4,
                                  style: gfont(AppType.bodySm,
                                      color: hex(AppColors.outline),
                                      size: 10)),
                            ],
                          ),
                        ),
                        if (active)
                          Icon(Icons.check_circle,
                              size: 18, color: hex(m.$3)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );

  Widget _nightBoostToggle() => GestureDetector(
        onTap: () {
          setState(() => _nightBoost = !_nightBoost);
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
              Icon(Icons.nightlight_round,
                  size: 20, color: hex(AppColors.secondary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Night Dialog Boost',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Boost dialog volume at low levels',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_nightBoost
                          ? AppColors.secondary
                          : AppColors.outlineVariant)
                      .withValues(alpha: _nightBoost ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _nightBoost
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(
                          _nightBoost ? AppColors.secondary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Settings',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
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
                'Auto volume prevents loud commercials and evens out volume differences between channels. Night dialog boost makes speech clearer at low volumes.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
