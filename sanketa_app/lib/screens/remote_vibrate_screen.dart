import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class RemoteVibrateScreen extends StatefulWidget {
  const RemoteVibrateScreen({super.key});

  @override
  State<RemoteVibrateScreen> createState() => _RemoteVibrateScreenState();
}

class _RemoteVibrateScreenState extends State<RemoteVibrateScreen> {
  bool _enabled = true;
  int _patternIndex = 0;
  double _intensity = 0.6;
  bool _loading = true;

  static const _patterns = <(String, IconData, List<int>)>[
    ('Click', Icons.touch_app, [10]),
    ('Double Tap', Icons.ads_click, [10, 40, 10]),
    ('Pulse', Icons.waves, [20, 30, 20, 30, 20]),
    ('Buzz', Icons.vibration, [50]),
    ('Soft', Icons.spa, [5]),
    ('Sharp', Icons.flash_on, [3, 10, 3]),
    ('Heartbeat', Icons.favorite, [15, 60, 15, 200, 15, 60, 15]),
    ('SOS', Icons.sos, [10, 10, 10, 10, 10, 30, 30, 30, 30, 10, 10, 10, 10, 10]),
  ];

  static const _buttonLabels = [
    'Power',
    'Volume Up',
    'Volume Down',
    'Mute',
    'OK',
    'Back',
    'Home',
    'Menu',
  ];

  late List<int> _buttonPatterns;

  @override
  void initState() {
    super.initState();
    _buttonPatterns = List.filled(_buttonLabels.length, 0);
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_vibrate.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = data['enabled'] as bool? ?? true;
        _patternIndex = data['patternIndex'] as int? ?? 0;
        _intensity = (data['intensity'] as num?)?.toDouble() ?? 0.6;
        final bp = data['buttonPatterns'] as List?;
        if (bp != null && bp.length == _buttonLabels.length) {
          _buttonPatterns = bp.cast<int>();
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'patternIndex': _patternIndex,
      'intensity': _intensity,
      'buttonPatterns': _buttonPatterns,
    }));
  }

  void _preview() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Preview: ${_patterns[_patternIndex].$1}'),
        duration: const Duration(seconds: 1),
      ));
  }

  void _cycleButtonPattern(int btnIdx) {
    setState(() {
      _buttonPatterns[btnIdx] =
          (_buttonPatterns[btnIdx] + 1) % _patterns.length;
    });
    HapticFeedback.selectionClick();
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
        title: Text('Remote Vibrate',
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
          _patternSelector(),
          const SizedBox(height: AppSpacing.md),
          _intensitySlider(),
          const SizedBox(height: AppSpacing.md),
          _buttonAssignments(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.vibration, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Haptic Patterns',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Customize vibration feedback for each button press',
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
              Icon(Icons.vibration, size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Haptic Feedback',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Vibrate on button presses',
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
                      color: hex(
                          _enabled ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _patternSelector() => Container(
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
            Text('Default Pattern',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _patterns.asMap().entries.map((e) {
                final active = e.key == _patternIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _patternIndex = e.key);
                    _save();
                    _preview();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.secondary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.secondary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(e.value.$2,
                            size: 14,
                            color: hex(active ? AppColors.secondary : AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(e.value.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.secondary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _intensitySlider() => Container(
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
                Text('Intensity',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text('${(_intensity * 100).round()}%',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.secondary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Slider(
              value: _intensity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _intensity = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _buttonAssignments() => Container(
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
            Text('Button Assignments',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap to cycle pattern',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
            const SizedBox(height: 8),
            ..._buttonLabels.asMap().entries.map((e) {
              final pat = _patterns[_buttonPatterns[e.key]];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _cycleButtonPattern(e.key),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(e.value,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 12)),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hex(AppColors.secondary).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(pat.$2,
                                  size: 12, color: hex(AppColors.secondary)),
                              const SizedBox(width: 4),
                              Text(pat.$1,
                                  style: gfont(AppType.bodySm,
                                      color: hex(AppColors.secondary),
                                      weight: FontWeight.w600,
                                      size: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
                'Customize vibration patterns for each remote button. Choose from 8 patterns and assign different haptics to different buttons.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
