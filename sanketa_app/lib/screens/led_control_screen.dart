import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class LedControlScreen extends StatefulWidget {
  const LedControlScreen({super.key});

  @override
  State<LedControlScreen> createState() => _LedControlScreenState();
}

class _LedControlScreenState extends State<LedControlScreen> {
  double _brightness = 0.6;
  int _colorIndex = 0;
  bool _ambientMode = false;
  bool _syncContent = false;
  bool _applied = false;

  static const _colors = <(String, Color, int)>[
    ('Off', Color(0xFF555555), AppColors.outline),
    ('White', Color(0xFFFFFFFF), AppColors.onSurface),
    ('Blue', Color(0xFF4488FF), AppColors.primary),
    ('Red', Color(0xFFFF4444), AppColors.error),
    ('Green', Color(0xFF44CC66), AppColors.signalEmerald),
  ];

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('LED settings applied'),
        duration: Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  void _selectColor(int idx) {
    setState(() => _colorIndex = idx);
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
        title: Text('LED Control',
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
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _brightnessControl(),
          const SizedBox(height: AppSpacing.lg),
          Text('LED Color',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _colorPicker(),
          const SizedBox(height: AppSpacing.lg),
          _ambientToggle(),
          const SizedBox(height: AppSpacing.sm),
          _syncToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.light_mode, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('LED & Ambient',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Control TV standby LED and ambient lighting',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() => Container(
        height: 100,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _colorIndex == 0
                  ? Colors.transparent
                  : _colors[_colorIndex].$2.withValues(alpha: _brightness),
              shape: BoxShape.circle,
              border: Border.all(
                color: _colors[_colorIndex].$2.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: _colorIndex == 0
                  ? null
                  : [
                      BoxShadow(
                        color: _colors[_colorIndex]
                            .$2
                            .withValues(alpha: _brightness * 0.4),
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
            ),
          ),
        ),
      );

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
                        size: 12)),
                Text('${(_brightness * 100).round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _brightness,
              min: 0,
              max: 1,
              divisions: 20,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _brightness = v),
            ),
          ],
        ),
      );

  Widget _colorPicker() => Row(
        children: _colors.asMap().entries.map((e) {
          final c = e.value;
          final active = e.key == _colorIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < _colors.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => _selectColor(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(c.$3).withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(c.$3).withValues(alpha: active ? 0.5 : 0.15),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(c.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 9)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _ambientToggle() => GestureDetector(
        onTap: () {
          setState(() => _ambientMode = !_ambientMode);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.blur_on,
                  size: 20,
                  color: hex(_ambientMode
                      ? AppColors.signalEmerald
                      : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambient Mode',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text('LED strip reacts to on-screen colours',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_ambientMode
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_ambientMode ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_ambientMode
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _syncToggle() => GestureDetector(
        onTap: () {
          setState(() => _syncContent = !_syncContent);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.sync,
                  size: 20,
                  color: hex(_syncContent
                      ? AppColors.primary
                      : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync with Content',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text('LED colour adapts to what is playing',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_syncContent
                          ? AppColors.primary
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_syncContent ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_syncContent
                            ? AppColors.primary
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
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
                'Control the standby LED indicator and ambient lighting on your TV. '
                'Enable Sync with Content for a dynamic backlight experience.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
