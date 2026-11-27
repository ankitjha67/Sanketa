import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvMagnifierScreen extends StatefulWidget {
  const TvMagnifierScreen({super.key});

  @override
  State<TvMagnifierScreen> createState() => _TvMagnifierScreenState();
}

class _TvMagnifierScreenState extends State<TvMagnifierScreen> {
  double _zoom = 2.0;
  double _panX = 0;
  double _panY = 0;
  bool _active = false;
  int _presetIndex = -1;

  static const _presets = [
    ('Top-Left', -1.0, -1.0),
    ('Top-Right', 1.0, -1.0),
    ('Center', 0.0, 0.0),
    ('Bottom-Left', -1.0, 1.0),
    ('Bottom-Right', 1.0, 1.0),
  ];

  void _applyZoom() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _active = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Magnifier at ${_zoom.toStringAsFixed(1)}x applied'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _resetZoom() {
    setState(() {
      _zoom = 2.0;
      _panX = 0;
      _panY = 0;
      _active = false;
      _presetIndex = -1;
    });
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
  }

  void _selectPreset(int i) {
    setState(() {
      _presetIndex = i;
      _panX = _presets[i].$2;
      _panY = _presets[i].$3;
    });
  }

  void _nudge(double dx, double dy) {
    setState(() {
      _panX = (_panX + dx).clamp(-1.0, 1.0);
      _panY = (_panY + dy).clamp(-1.0, 1.0);
      _presetIndex = -1;
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
        title: Text('TV Magnifier',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_active)
            GestureDetector(
              onTap: _resetZoom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _zoomSlider(),
          const SizedBox(height: AppSpacing.md),
          _panControls(),
          const SizedBox(height: AppSpacing.md),
          _presetChips(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.zoom_in, size: 44, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Screen Magnifier',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Zoom into any area of the TV screen for easier reading',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() {
    final viewW = 1.0 / _zoom;
    final left = ((_panX + 1) / 2 * (1 - viewW)).clamp(0.0, 1.0 - viewW);
    final top = ((_panY + 1) / 2 * (1 - viewW)).clamp(0.0, 1.0 - viewW);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(_active ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: _active ? 0.5 : 0.2),
            width: _active ? 2 : 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.tv,
                size: 80,
                color: hex(AppColors.outline).withValues(alpha: 0.15)),
          ),
          Positioned.fill(
            child: LayoutBuilder(builder: (_, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    left: left * w,
                    top: top * h,
                    width: viewW * w,
                    height: viewW * h,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: hex(AppColors.primary), width: 2),
                        borderRadius: BorderRadius.circular(4),
                        color: hex(AppColors.primary).withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Text('${_zoom.toStringAsFixed(1)}x',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.primary),
                                weight: FontWeight.w700,
                                size: 10)),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hex(_active ? AppColors.signalEmerald : AppColors.outline)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(_active ? 'Active' : 'Preview',
                  style: gfont(AppType.bodySm,
                      color: hex(_active ? AppColors.signalEmerald : AppColors.outline),
                      weight: FontWeight.w600,
                      size: 9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomSlider() => Container(
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
                Text('Zoom Level',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text('${_zoom.toStringAsFixed(1)}x',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Slider(
              value: _zoom,
              min: 1.5,
              max: 5.0,
              divisions: 14,
              activeColor: hex(AppColors.primary),
              inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _zoom = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1.5x',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Text('5.0x',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _panControls() => Container(
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
            Text('Pan Position',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _panBtn(Icons.arrow_upward, () => _nudge(0, -0.2)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _panBtn(Icons.arrow_back, () => _nudge(-0.2, 0)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _panX = 0;
                    _panY = 0;
                    _presetIndex = 2;
                  }),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(Icons.center_focus_strong,
                        size: 18, color: hex(AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                _panBtn(Icons.arrow_forward, () => _nudge(0.2, 0)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _panBtn(Icons.arrow_downward, () => _nudge(0, 0.2)),
              ],
            ),
          ],
        ),
      );

  Widget _panBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 18, color: hex(AppColors.onSurface)),
        ),
      );

  Widget _presetChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Positions',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final active = i == _presetIndex;
                return GestureDetector(
                  onTap: () => _selectPreset(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(_presets[i].$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              size: 11)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyZoom,
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
              Icon(Icons.zoom_in, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Magnifier',
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
                'Magnify any area of the TV screen for easier reading. Great for small text, subtitles, or fine details. Use pan controls to move the magnified area.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
