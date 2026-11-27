import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class NoiseGateScreen extends StatefulWidget {
  const NoiseGateScreen({super.key});

  @override
  State<NoiseGateScreen> createState() => _NoiseGateScreenState();
}

class _NoiseGateScreenState extends State<NoiseGateScreen> {
  double _threshold = 70;
  int _sensitivityIndex = 1;
  bool _autoMute = true;
  bool _muted = false;
  int _unmuteDelaySec = 3;
  bool _monitoring = false;
  double _currentLevel = 0;
  Timer? _timer;
  final _rng = Random();

  static const _sensitivities = [
    ('Low', 85.0, Icons.volume_mute, AppColors.signalEmerald),
    ('Med', 70.0, Icons.volume_down, AppColors.alertAmber),
    ('High', 50.0, Icons.volume_up, AppColors.primary),
  ];

  static const _delays = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/noise_gate.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        setState(() {
          _threshold = (data['threshold'] as num?)?.toDouble() ?? 70;
          _sensitivityIndex =
              (data['sensitivity'] as num?)?.toInt() ?? 1;
          _autoMute = data['autoMute'] as bool? ?? true;
          _unmuteDelaySec = (data['unmuteSec'] as num?)?.toInt() ?? 3;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file;
      await f.writeAsString(jsonEncode({
        'threshold': _threshold,
        'sensitivity': _sensitivityIndex,
        'autoMute': _autoMute,
        'unmuteSec': _unmuteDelaySec,
      }));
    } catch (_) {}
  }

  void _toggleMonitoring() {
    setState(() => _monitoring = !_monitoring);
    HapticFeedback.mediumImpact();
    if (_monitoring) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        setState(() {
          _currentLevel =
              (_currentLevel + (_rng.nextDouble() * 20 - 10)).clamp(0, 100);
        });
        if (_autoMute && _currentLevel > _threshold && !_muted) {
          _triggerMute();
        }
      });
    } else {
      _timer?.cancel();
      setState(() => _currentLevel = 0);
    }
  }

  void _triggerMute() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.mute);
    setState(() => _muted = true);
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(seconds: _unmuteDelaySec), () {
      if (mounted && _muted) {
        rc.key(core.Key.mute);
        setState(() => _muted = false);
      }
    });
  }

  void _manualToggleMute() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.mute);
    setState(() => _muted = !_muted);
    HapticFeedback.mediumImpact();
  }

  void _selectSensitivity(int idx) {
    setState(() {
      _sensitivityIndex = idx;
      _threshold = _sensitivities[idx].$2;
    });
    _save();
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
        title: Text('Noise Gate',
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
          _levelMeter(),
          const SizedBox(height: AppSpacing.md),
          _thresholdSlider(),
          const SizedBox(height: AppSpacing.lg),
          Text('Sensitivity Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _sensitivityRow(),
          const SizedBox(height: AppSpacing.lg),
          _toggleRow(),
          const SizedBox(height: AppSpacing.md),
          _unmuteDelayPicker(),
          const SizedBox(height: AppSpacing.lg),
          _controlButtons(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.noise_aware,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Auto-Mute Loud Scenes',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Automatically mutes TV when volume exceeds threshold, with delayed unmute',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _levelMeter() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hex(_muted
                            ? AppColors.alertAmber
                            : _monitoring
                                ? AppColors.signalEmerald
                                : AppColors.outline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    _muted
                        ? 'MUTED'
                        : _monitoring
                            ? 'MONITORING'
                            : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_muted
                            ? AppColors.alertAmber
                            : _monitoring
                                ? AppColors.signalEmerald
                                : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: SizedBox(
                height: 24,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (_currentLevel / 100).clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hex(_currentLevel > _threshold
                              ? AppColors.alertAmber
                              : AppColors.signalEmerald),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                      ),
                    ),
                    Positioned(
                      left: null,
                      right: null,
                      child: Center(
                        child: Text('${_currentLevel.round()}%',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w700,
                                size: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Threshold: ${_threshold.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                const Spacer(),
                Icon(
                  _currentLevel > _threshold
                      ? Icons.warning_amber
                      : Icons.check_circle,
                  size: 14,
                  color: hex(_currentLevel > _threshold
                      ? AppColors.alertAmber
                      : AppColors.signalEmerald),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _thresholdSlider() => Container(
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
                Text('Threshold',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('0 — 100',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Slider(
              value: _threshold,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() {
                  _threshold = v;
                  _sensitivityIndex = -1;
                });
              },
              onChangeEnd: (_) => _save(),
            ),
          ],
        ),
      );

  Widget _sensitivityRow() => Row(
        children: _sensitivities.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _sensitivityIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 4, right: e.key == 2 ? 0 : 4),
              child: GestureDetector(
                onTap: () => _selectSensitivity(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        hex(active ? p.$4 : AppColors.surfaceContainerLow)
                            .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? p.$4 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$3, size: 20, color: hex(p.$4)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                      Text('${p.$2.round()}%',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _toggleRow() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_fix_high,
                size: 18, color: hex(AppColors.secondary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Auto-Mute',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 13)),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _autoMute = !_autoMute);
                _save();
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_autoMute
                          ? AppColors.signalEmerald
                          : AppColors.outlineVariant)
                      .withValues(alpha: _autoMute ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _autoMute
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_autoMute
                          ? AppColors.signalEmerald
                          : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _unmuteDelayPicker() => Container(
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
            Text('Unmute Delay',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 8),
            Row(
              children: _delays.map((d) {
                final active = d == _unmuteDelaySec;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _unmuteDelaySec = d);
                        _save();
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: hex(active
                                  ? AppColors.secondary
                                  : AppColors.surfaceContainerHigh)
                              .withValues(alpha: active ? 0.15 : 1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: hex(active
                                    ? AppColors.secondary
                                    : AppColors.outlineVariant)
                                .withValues(alpha: active ? 0.4 : 0.15),
                          ),
                        ),
                        child: Center(
                          child: Text('${d}s',
                              style: gfont(AppType.bodySm,
                                  color: hex(active
                                      ? AppColors.secondary
                                      : AppColors.onSurface),
                                  weight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  size: 11)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _controlButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleMonitoring,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: hex(_monitoring
                          ? AppColors.alertAmber
                          : AppColors.signalEmerald)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(_monitoring
                            ? AppColors.alertAmber
                            : AppColors.signalEmerald)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _monitoring
                            ? Icons.stop
                            : Icons.hearing,
                        size: 18,
                        color: hex(_monitoring
                            ? AppColors.alertAmber
                            : AppColors.signalEmerald)),
                    const SizedBox(width: 6),
                    Text(_monitoring ? 'Stop' : 'Monitor',
                        style: gfont(AppType.bodyMd,
                            color: hex(_monitoring
                                ? AppColors.alertAmber
                                : AppColors.signalEmerald),
                            weight: FontWeight.w600,
                            size: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _manualToggleMute,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(AppColors.primary).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _muted ? Icons.volume_up : Icons.volume_off,
                        size: 18,
                        color: hex(AppColors.primary)),
                    const SizedBox(width: 6),
                    Text(_muted ? 'Unmute' : 'Mute',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600,
                            size: 13)),
                  ],
                ),
              ),
            ),
          ),
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
                'Auto-mutes TV when volume spikes past your threshold. Adjustable sensitivity, delayed unmute, and manual override. All processing local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
