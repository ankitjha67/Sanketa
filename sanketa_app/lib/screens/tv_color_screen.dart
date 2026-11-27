import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvColorScreen extends StatefulWidget {
  const TvColorScreen({super.key});

  @override
  State<TvColorScreen> createState() => _TvColorScreenState();
}

class _TvColorScreenState extends State<TvColorScreen> {
  double _temperature = 50;
  double _saturation = 50;
  double _tint = 50;
  int _presetIndex = 0;
  bool _eyeComfort = false;
  double _blueLight = 30;
  bool _applied = false;

  static const _presets = [
    ('Standard', 50.0, 50.0, 50.0, Icons.tv, AppColors.primary),
    ('Warm', 70.0, 55.0, 55.0, Icons.wb_sunny, AppColors.alertAmber),
    ('Cool', 30.0, 45.0, 45.0, Icons.ac_unit, AppColors.tertiary),
    ('Vivid', 50.0, 80.0, 50.0, Icons.palette, AppColors.secondary),
    ('Cinema', 55.0, 40.0, 48.0, Icons.movie, AppColors.error),
  ];

  void _selectPreset(int idx) {
    final p = _presets[idx];
    setState(() {
      _presetIndex = idx;
      _temperature = p.$2;
      _saturation = p.$3;
      _tint = p.$4;
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
      ..showSnackBar(const SnackBar(
        content: Text('Color settings applied'),
        duration: Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Color',
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
          _previewBar(),
          const SizedBox(height: AppSpacing.lg),
          Text('Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _presetRow(),
          const SizedBox(height: AppSpacing.lg),
          _sliderCard('Temperature', Icons.thermostat, _temperature,
              (v) => setState(() { _temperature = v; _presetIndex = -1; })),
          const SizedBox(height: AppSpacing.sm),
          _sliderCard('Saturation', Icons.color_lens, _saturation,
              (v) => setState(() { _saturation = v; _presetIndex = -1; })),
          const SizedBox(height: AppSpacing.sm),
          _sliderCard('Tint', Icons.tune, _tint,
              (v) => setState(() { _tint = v; _presetIndex = -1; })),
          const SizedBox(height: AppSpacing.lg),
          _eyeComfortSection(),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.color_lens, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Color Controls',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Fine-tune color temperature, saturation, and tint',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewBar() => Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          gradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(1, _temperature * 3.6, _saturation / 100, 0.3)
                  .toColor(),
              HSLColor.fromAHSL(1, _temperature * 3.6, _saturation / 100, 0.5)
                  .toColor(),
              HSLColor.fromAHSL(
                      1, (_temperature * 3.6 + _tint) % 360, _saturation / 100, 0.7)
                  .toColor(),
            ],
          ),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text('Color Preview',
              style: gfont(AppType.bodySm,
                  color: Colors.white,
                  weight: FontWeight.w600,
                  size: 11)),
        ),
      );

  Widget _presetRow() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _presets.asMap().entries.map((e) {
            final p = e.value;
            final active = e.key == _presetIndex;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _selectPreset(e.key),
                child: Container(
                  width: 80,
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
                      Icon(p.$5, size: 20, color: hex(p.$6)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
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

  Widget _sliderCard(
      String label, IconData icon, double value, ValueChanged<double> onChanged) {
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
              Icon(icon, size: 16, color: hex(AppColors.outline)),
              const SizedBox(width: 8),
              Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 12)),
              const Spacer(),
              Text('${value.round()}%',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600,
                      size: 11)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: hex(AppColors.primary),
            inactiveColor:
                hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _eyeComfortSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.visibility, size: 18, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Eye Comfort Mode',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                ),
                Switch(
                  value: _eyeComfort,
                  onChanged: (v) {
                    setState(() => _eyeComfort = v);
                    HapticFeedback.selectionClick();
                  },
                  activeColor: hex(AppColors.alertAmber),
                ),
              ],
            ),
            if (_eyeComfort) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.filter_vintage,
                      size: 14, color: hex(AppColors.alertAmber)),
                  const SizedBox(width: 6),
                  Text('Blue Light Filter',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface), size: 11)),
                  const Spacer(),
                  Text('${_blueLight.round()}%',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.alertAmber),
                          weight: FontWeight.w600,
                          size: 10)),
                ],
              ),
              Slider(
                value: _blueLight,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: hex(AppColors.alertAmber),
                inactiveColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                onChanged: (v) => setState(() => _blueLight = v),
              ),
            ],
          ],
        ),
      );

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
              Text(_applied ? 'Applied!' : 'Apply Colors',
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
          border:
              Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Adjust color temperature, saturation, and tint for your TV. Enable Eye Comfort to reduce blue light for night viewing.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
