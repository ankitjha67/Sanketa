import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenPipControlScreen extends StatefulWidget {
  const ScreenPipControlScreen({super.key});

  @override
  State<ScreenPipControlScreen> createState() => _ScreenPipControlScreenState();
}

class _ScreenPipControlScreenState extends State<ScreenPipControlScreen> {
  bool _pipActive = false;
  int _pipPosition = 3;
  int _pipSize = 1;
  int _mainSource = 0;
  int _pipSource = 1;

  static const _positions = [
    'Top Left',
    'Top Right',
    'Bottom Left',
    'Bottom Right',
  ];

  static const _sizes = ['Small', 'Medium', 'Large'];

  static const _sources = [
    ('HDMI 1', Icons.settings_input_hdmi, AppColors.primary),
    ('HDMI 2', Icons.settings_input_hdmi, AppColors.signalEmerald),
    ('HDMI 3', Icons.settings_input_hdmi, AppColors.secondary),
    ('Antenna', Icons.settings_input_antenna, AppColors.alertAmber),
    ('USB', Icons.usb, AppColors.tertiary),
  ];

  void _togglePip() {
    final rc = RemoteScope.of(context);
    rc.launch('pip:${_pipActive ? 'off' : 'on'}');
    setState(() => _pipActive = !_pipActive);
    HapticFeedback.heavyImpact();
  }

  void _swapSources() {
    final rc = RemoteScope.of(context);
    rc.launch('pip:swap');
    setState(() {
      final tmp = _mainSource;
      _mainSource = _pipSource;
      _pipSource = tmp;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('PiP Control',
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
          _pipToggle(),
          const SizedBox(height: AppSpacing.lg),
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _positionSelector(),
          const SizedBox(height: AppSpacing.md),
          _sizeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _sourceSection('Main Source', _mainSource, (idx) {
            setState(() => _mainSource = idx);
            RemoteScope.of(context).launch('pip:main:${_sources[idx].$1}');
            HapticFeedback.selectionClick();
          }),
          const SizedBox(height: AppSpacing.md),
          _sourceSection('PiP Source', _pipSource, (idx) {
            setState(() => _pipSource = idx);
            RemoteScope.of(context).launch('pip:sub:${_sources[idx].$1}');
            HapticFeedback.selectionClick();
          }),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.picture_in_picture,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Picture-in-Picture',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Watch two sources at once. Position, size, and swap.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _pipToggle() => GestureDetector(
        onTap: _togglePip,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 14),
          decoration: BoxDecoration(
            color: hex(_pipActive
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _pipActive ? 0.12 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(_pipActive
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant)
                    .withValues(alpha: _pipActive ? 0.4 : 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _pipActive ? Icons.stop_circle : Icons.picture_in_picture,
                size: 24,
                color: hex(
                    _pipActive ? AppColors.signalEmerald : AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                _pipActive ? 'PiP Active — Tap to Stop' : 'Start PiP',
                style: gfont(AppType.bodyMd,
                    color: hex(_pipActive
                        ? AppColors.signalEmerald
                        : AppColors.primary),
                    weight: FontWeight.w600,
                    size: 14),
              ),
            ],
          ),
        ),
      );

  Widget _previewCard() => Container(
        height: 160,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_sources[_mainSource].$2,
                      size: 28, color: hex(_sources[_mainSource].$3)),
                  const SizedBox(height: 4),
                  Text(_sources[_mainSource].$1,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 11)),
                  Text('Main',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
            if (_pipActive)
              Positioned(
                right: _pipPosition % 2 == 0 ? null : 12,
                left: _pipPosition % 2 == 0 ? 12 : null,
                top: _pipPosition < 2 ? 12 : null,
                bottom: _pipPosition >= 2 ? 12 : null,
                child: GestureDetector(
                  onTap: _swapSources,
                  child: Container(
                    width: _pipSize == 0
                        ? 50
                        : _pipSize == 1
                            ? 65
                            : 80,
                    height: _pipSize == 0
                        ? 35
                        : _pipSize == 1
                            ? 45
                            : 55,
                    decoration: BoxDecoration(
                      color: hex(_sources[_pipSource].$3)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                          color: hex(_sources[_pipSource].$3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_sources[_pipSource].$2,
                            size: 14, color: hex(_sources[_pipSource].$3)),
                        Text('PiP',
                            style: gfont(AppType.bodySm,
                                color: hex(_sources[_pipSource].$3),
                                size: 7,
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _positionSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PiP Position',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _positions.asMap().entries.map((e) {
              final active = e.key == _pipPosition;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _pipPosition = e.key);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text(e.value,
                          textAlign: TextAlign.center,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.primary
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 9)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _sizeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PiP Size',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _sizes.asMap().entries.map((e) {
              final active = e.key == _pipSize;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _pipSize = e.key);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.secondary
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.secondary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text(e.value,
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
              );
            }).toList(),
          ),
        ],
      );

  Widget _sourceSection(
          String title, int selected, ValueChanged<int> onSelect) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _sources.asMap().entries.map((e) {
              final active = e.key == selected;
              return GestureDetector(
                onTap: () => onSelect(e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active ? e.value.$3 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(active
                                ? e.value.$3
                                : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2, size: 16, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
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
                'Picture-in-Picture control. Choose position, size, and sources. '
                'Tap PiP preview to swap sources. All local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
