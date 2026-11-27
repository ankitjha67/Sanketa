import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class PipModeScreen extends StatefulWidget {
  const PipModeScreen({super.key});

  @override
  State<PipModeScreen> createState() => _PipModeScreenState();
}

class _PipModeScreenState extends State<PipModeScreen> {
  bool _enabled = false;
  double _size = 30;
  double _opacity = 80;
  int _positionIndex = 0;
  int _sourceIndex = 0;

  static const _positions = [
    ('Top Left', Icons.north_west, Alignment.topLeft),
    ('Top Right', Icons.north_east, Alignment.topRight),
    ('Bottom Left', Icons.south_west, Alignment.bottomLeft),
    ('Bottom Right', Icons.south_east, Alignment.bottomRight),
  ];

  static const _sources = [
    ('HDMI 1', Icons.settings_input_hdmi, AppColors.primary),
    ('HDMI 2', Icons.settings_input_hdmi, AppColors.secondary),
    ('AV', Icons.input, AppColors.tertiary),
    ('USB', Icons.usb, AppColors.alertAmber),
    ('Tuner', Icons.tv, AppColors.signalEmerald),
  ];

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_enabled
            ? 'PIP enabled — ${_positions[_positionIndex].$1}'
            : 'PIP disabled'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('PIP Mode',
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
          _toggleCard(),
          const SizedBox(height: AppSpacing.lg),
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Position',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _positionGrid(),
          const SizedBox(height: AppSpacing.lg),
          Text('Source Input',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _sourceList(),
          const SizedBox(height: AppSpacing.lg),
          _sizeSlider(),
          const SizedBox(height: AppSpacing.md),
          _opacitySlider(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.picture_in_picture_alt,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Picture-in-Picture',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Watch two sources at once — resize, reposition and adjust opacity',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _toggleCard() => GestureDetector(
        onTap: () {
          setState(() => _enabled = !_enabled);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color:
                  hex(_enabled ? AppColors.signalEmerald : AppColors.outline)
                      .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _enabled ? Icons.toggle_on : Icons.toggle_off,
                size: 36,
                color:
                    hex(_enabled ? AppColors.signalEmerald : AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_enabled ? 'PIP Enabled' : 'PIP Disabled',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                      _enabled
                          ? 'Second source visible on screen'
                          : 'Tap to enable picture-in-picture',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _previewCard() => Container(
        height: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Center(
              child: Text('Main Screen',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
            ),
            if (_enabled)
              Align(
                alignment: _positions[_positionIndex].$3,
                child: Container(
                  width: 40 + _size,
                  height: 25 + _size * 0.6,
                  decoration: BoxDecoration(
                    color: hex(_sources[_sourceIndex].$3)
                        .withValues(alpha: _opacity / 100),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                        color: hex(AppColors.primary).withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text('PIP',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 9)),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _positionGrid() => Row(
        children: _positions.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _positionIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key < 3 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _positionIndex = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$2,
                          size: 20,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.outline)),
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

  Widget _sourceList() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sources.asMap().entries.map((e) {
          final s = e.value;
          final active = e.key == _sourceIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _sourceIndex = e.key);
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(active ? s.$3 : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? s.$3 : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.4 : 0.15),
                ),
              ),
              child: Column(
                children: [
                  Icon(s.$2, size: 18, color: hex(s.$3)),
                  const SizedBox(height: 4),
                  Text(s.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _sizeSlider() => Container(
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
                Text('Size',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${_size.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Slider(
              value: _size,
              min: 10,
              max: 60,
              divisions: 50,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _size = v),
            ),
          ],
        ),
      );

  Widget _opacitySlider() => Container(
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
                Text('Opacity',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${_opacity.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Slider(
              value: _opacity,
              min: 20,
              max: 100,
              divisions: 80,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _opacity = v),
            ),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
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
              Icon(Icons.check_circle,
                  size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply PIP Settings',
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
                'Watch two sources at once. Choose a corner position, pick the PIP source, and adjust size and transparency to your preference.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
