import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenZoomScreen extends StatefulWidget {
  const ScreenZoomScreen({super.key});

  @override
  State<ScreenZoomScreen> createState() => _ScreenZoomScreenState();
}

class _ScreenZoomScreenState extends State<ScreenZoomScreen> {
  double _zoomLevel = 1.0;
  int _panX = 0;
  int _panY = 0;
  bool _zoomActive = false;

  static const _presets = <(String, double)>[
    ('1x', 1.0),
    ('1.5x', 1.5),
    ('2x', 2.0),
    ('2.5x', 2.5),
    ('3x', 3.0),
  ];

  void _applyZoom() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _zoomActive = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Zoom ${_zoomLevel.toStringAsFixed(1)}x applied'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _panX = 0;
      _panY = 0;
      _zoomActive = false;
    });
  }

  void _pan(int dx, int dy) {
    final rc = RemoteScope.of(context);
    if (dx < 0) rc.key(core.Key.left);
    if (dx > 0) rc.key(core.Key.right);
    if (dy < 0) rc.key(core.Key.up);
    if (dy > 0) rc.key(core.Key.down);
    setState(() {
      _panX = (_panX + dx).clamp(-5, 5);
      _panY = (_panY + dy).clamp(-5, 5);
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
        title: Text('Screen Zoom',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_zoomActive)
            GestureDetector(
              onTap: _resetZoom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.zoom_out_map, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _zoomSlider(),
          const SizedBox(height: AppSpacing.md),
          _presetButtons(),
          const SizedBox(height: AppSpacing.md),
          _panControl(),
          const SizedBox(height: AppSpacing.md),
          _actionButtons(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(_zoomActive ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: _zoomActive ? 0.4 : 0.15)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.tv, size: 60, color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          Positioned(
            left: 80 + _panX * 8.0,
            top: 50 + _panY * 8.0,
            child: Container(
              width: 60 / _zoomLevel,
              height: 40 / _zoomLevel,
              decoration: BoxDecoration(
                border: Border.all(color: hex(AppColors.primary), width: 2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('${_zoomLevel.toStringAsFixed(1)}x · Pan ($_panX, $_panY)',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
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
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Zoom Level',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                const Spacer(),
                Text('${_zoomLevel.toStringAsFixed(1)}x',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary), weight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                thumbColor: hex(AppColors.primary),
                trackHeight: 4,
              ),
              child: Slider(
                value: _zoomLevel,
                min: 1.0,
                max: 4.0,
                divisions: 30,
                onChanged: (v) => setState(() => _zoomLevel = double.parse(v.toStringAsFixed(1))),
              ),
            ),
          ],
        ),
      );

  Widget _presetButtons() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _presets.map((p) {
          final active = _zoomLevel == p.$2;
          return GestureDetector(
            onTap: () => setState(() => _zoomLevel = p.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                    .withValues(alpha: active ? 0.15 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.5 : 0.2),
                ),
              ),
              child: Text(p.$1,
                  style: gfont(AppType.bodyMd,
                      color: hex(active ? AppColors.primary : AppColors.onSurface),
                      weight: active ? FontWeight.w600 : FontWeight.w400, size: 12)),
            ),
          );
        }).toList(),
      );

  Widget _panControl() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pan Position',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(top: 0, child: _panBtn(Icons.keyboard_arrow_up, () => _pan(0, -1))),
                    Positioned(bottom: 0, child: _panBtn(Icons.keyboard_arrow_down, () => _pan(0, 1))),
                    Positioned(left: 0, child: _panBtn(Icons.keyboard_arrow_left, () => _pan(-1, 0))),
                    Positioned(right: 0, child: _panBtn(Icons.keyboard_arrow_right, () => _pan(1, 0))),
                    GestureDetector(
                      onTap: () => setState(() { _panX = 0; _panY = 0; }),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: hex(AppColors.primary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.center_focus_strong, size: 16, color: hex(AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _panBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            shape: BoxShape.circle,
            border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 18, color: hex(AppColors.onSurface)),
        ),
      );

  Widget _actionButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _applyZoom,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text('Apply Zoom',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary), weight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _resetZoom,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text('Reset',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface), weight: FontWeight.w600)),
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
          border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Zoom into specific areas of the TV screen for better visibility. Use the pan controls to navigate while zoomed in. Great for small text or distant viewing.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
