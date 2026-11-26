import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AudioDelayScreen extends StatefulWidget {
  const AudioDelayScreen({super.key});

  @override
  State<AudioDelayScreen> createState() => _AudioDelayScreenState();
}

class _AudioDelayScreenState extends State<AudioDelayScreen> {
  double _delayMs = 0;
  int _presetIndex = -1;
  bool _applied = false;

  static const _presets = [
    ('Bluetooth', 150.0, Icons.bluetooth, AppColors.primary),
    ('Soundbar', 80.0, Icons.speaker, AppColors.secondary),
    ('HDMI ARC', 30.0, Icons.settings_input_hdmi, AppColors.tertiary),
    ('Wireless', 200.0, Icons.wifi, AppColors.alertAmber),
    ('Reset', 0.0, Icons.restart_alt, AppColors.outline),
  ];

  void _applyDelay() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Audio delay set to ${_delayMs.round()}ms'),
        duration: const Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  void _selectPreset(int idx) {
    setState(() {
      _presetIndex = idx;
      _delayMs = _presets[idx].$2;
    });
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
        title: Text('Audio Delay',
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
          _delayDisplay(),
          const SizedBox(height: AppSpacing.md),
          _slider(),
          const SizedBox(height: AppSpacing.md),
          _fineControls(),
          const SizedBox(height: AppSpacing.lg),
          Text('Quick Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _presetGrid(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _helpCard(),
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
            Text('Fix Lip Sync',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Adjust audio delay to perfectly sync sound with video on your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _delayDisplay() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('${_delayMs.round()}',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 48,
                    weight: FontWeight.w700)),
            Text('milliseconds',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hex(_delayMs == 0
                        ? AppColors.signalEmerald
                        : _delayMs <= 100
                            ? AppColors.primary
                            : AppColors.alertAmber)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                _delayMs == 0
                    ? 'No delay'
                    : _delayMs <= 50
                        ? 'Minimal'
                        : _delayMs <= 100
                            ? 'Moderate'
                            : _delayMs <= 200
                                ? 'Significant'
                                : 'High',
                style: gfont(AppType.bodySm,
                    color: hex(_delayMs == 0
                        ? AppColors.signalEmerald
                        : _delayMs <= 100
                            ? AppColors.primary
                            : AppColors.alertAmber),
                    weight: FontWeight.w600,
                    size: 10),
              ),
            ),
          ],
        ),
      );

  Widget _slider() => Container(
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
                Text('Delay',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('0ms — 500ms',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Slider(
              value: _delayMs,
              min: 0,
              max: 500,
              divisions: 100,
              activeColor: hex(AppColors.primary),
              inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() {
                _delayMs = v;
                _presetIndex = -1;
              }),
            ),
          ],
        ),
      );

  Widget _fineControls() => Row(
        children: [
          Expanded(child: _fineBtn('-10ms', -10)),
          const SizedBox(width: 6),
          Expanded(child: _fineBtn('-1ms', -1)),
          const SizedBox(width: 6),
          Expanded(child: _fineBtn('+1ms', 1)),
          const SizedBox(width: 6),
          Expanded(child: _fineBtn('+10ms', 10)),
        ],
      );

  Widget _fineBtn(String label, int delta) => GestureDetector(
        onTap: () {
          setState(() {
            _delayMs = (_delayMs + delta).clamp(0, 500);
            _presetIndex = -1;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 11)),
          ),
        ),
      );

  Widget _presetGrid() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _presets.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _presetIndex;
          return GestureDetector(
            onTap: () => _selectPreset(e.key),
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(active ? p.$4 : AppColors.surfaceContainerLow)
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
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                  Text('${p.$2.round()}ms',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyDelay,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_applied ? AppColors.signalEmerald : AppColors.primary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_applied ? AppColors.signalEmerald : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_applied ? Icons.check : Icons.check_circle,
                  size: 20,
                  color: hex(_applied ? AppColors.signalEmerald : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_applied ? 'Applied!' : 'Apply Delay',
                  style: gfont(AppType.bodyMd,
                      color: hex(_applied ? AppColors.signalEmerald : AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _helpCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Text('How to Test',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ...[
              'Watch a person speaking on screen',
              'If audio comes before the lips move: increase delay',
              'If audio comes after the lips move: decrease delay',
              'Adjust by 10ms at a time until speech looks natural',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('  •  ',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      Expanded(
                        child: Text(tip,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 10)),
                      ),
                    ],
                  ),
                )),
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
                'Fix audio/video lip-sync issues by adjusting the audio delay. Use presets for common setups or fine-tune manually with 1ms precision.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
