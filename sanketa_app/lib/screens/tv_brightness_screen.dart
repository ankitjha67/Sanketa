import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvBrightnessScreen extends StatefulWidget {
  const TvBrightnessScreen({super.key});

  @override
  State<TvBrightnessScreen> createState() => _TvBrightnessScreenState();
}

class _TvBrightnessScreenState extends State<TvBrightnessScreen> {
  double _brightness = 50;
  double _contrast = 50;
  double _gamma = 50;
  int _presetIndex = -1;
  bool _applied = false;

  static const _presets = [
    ('Day', Icons.wb_sunny, 70.0, 55.0, 45.0, AppColors.alertAmber),
    ('Night', Icons.nightlight, 25.0, 40.0, 55.0, AppColors.tertiary),
    ('Movie', Icons.movie, 40.0, 60.0, 50.0, AppColors.primary),
    ('Game', Icons.sports_esports, 55.0, 65.0, 48.0, AppColors.signalEmerald),
    ('Custom', Icons.tune, -1.0, -1.0, -1.0, AppColors.secondary),
  ];

  void _selectPreset(int idx) {
    final p = _presets[idx];
    setState(() {
      _presetIndex = idx;
      if (p.$3 >= 0) {
        _brightness = p.$3;
        _contrast = p.$4;
        _gamma = p.$5;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            'Applied — Brightness ${_brightness.round()} / Contrast ${_contrast.round()} / Gamma ${_gamma.round()}'),
        duration: const Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  void _reset() {
    setState(() {
      _brightness = 50;
      _contrast = 50;
      _gamma = 50;
      _presetIndex = -1;
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
        title: Text('TV Brightness',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _reset,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.restart_alt,
                  size: 22, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _previewBar(),
          const SizedBox(height: AppSpacing.lg),
          Text('Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _presetRow(),
          const SizedBox(height: AppSpacing.lg),
          _sliderCard('Brightness', Icons.brightness_6, _brightness,
              AppColors.alertAmber, (v) => setState(() => _brightness = v)),
          const SizedBox(height: AppSpacing.md),
          _sliderCard('Contrast', Icons.contrast, _contrast,
              AppColors.primary, (v) => setState(() => _contrast = v)),
          const SizedBox(height: AppSpacing.md),
          _sliderCard('Gamma', Icons.tonality, _gamma,
              AppColors.tertiary, (v) => setState(() => _gamma = v)),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.brightness_6,
                size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Display Controls',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Fine-tune brightness, contrast and gamma for the perfect picture',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewBar() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('Live Preview',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w600,
                    size: 10)),
            const SizedBox(height: 8),
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: LinearGradient(
                  colors: [
                    Colors.black
                        .withValues(alpha: 1 - (_brightness / 100) * 0.8),
                    hex(AppColors.primary)
                        .withValues(alpha: _contrast / 100),
                    Colors.white
                        .withValues(alpha: (_gamma / 100) * 0.9),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statLabel('Bright', '${_brightness.round()}'),
                _statLabel('Contrast', '${_contrast.round()}'),
                _statLabel('Gamma', '${_gamma.round()}'),
              ],
            ),
          ],
        ),
      );

  Widget _statLabel(String label, String value) => Column(
        children: [
          Text(value,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w700,
                  size: 16)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _presetRow() => Row(
        children: _presets.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _presetIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < 4 ? 6 : 0),
              child: GestureDetector(
                onTap: () => _selectPreset(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active ? p.$6 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? p.$6 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$2, size: 18, color: hex(p.$6)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 9)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _sliderCard(String label, IconData icon, double value,
      int colorToken, ValueChanged<double> onChanged) {
    return Container(
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
            children: [
              Icon(icon, size: 16, color: hex(colorToken)),
              const SizedBox(width: 6),
              Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 12)),
              const Spacer(),
              Text('${value.round()}',
                  style: gfont(AppType.bodySm,
                      color: hex(colorToken),
                      weight: FontWeight.w600,
                      size: 12)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: hex(colorToken),
            inactiveColor:
                hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            onChanged: (v) {
              onChanged(v);
              _presetIndex = -1;
            },
          ),
        ],
      ),
    );
  }

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
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
                  color: hex(
                      _applied ? AppColors.signalEmerald : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_applied ? 'Applied!' : 'Apply Settings',
                  style: gfont(AppType.bodyMd,
                      color: hex(_applied
                          ? AppColors.signalEmerald
                          : AppColors.primary),
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
                'Adjust brightness, contrast and gamma for optimal viewing. Use presets for common scenarios or fine-tune each slider manually.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
