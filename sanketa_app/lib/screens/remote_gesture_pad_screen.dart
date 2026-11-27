import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteGesturePadScreen extends StatefulWidget {
  const RemoteGesturePadScreen({super.key});

  @override
  State<RemoteGesturePadScreen> createState() => _RemoteGesturePadScreenState();
}

class _RemoteGesturePadScreenState extends State<RemoteGesturePadScreen> {
  String _lastGesture = 'None';
  int _gestureCount = 0;
  bool _haptic = true;
  double _sensitivity = 40;

  static const _gestureMap = <(String, IconData, String)>[
    ('Swipe Up', Icons.arrow_upward, 'Navigate Up'),
    ('Swipe Down', Icons.arrow_downward, 'Navigate Down'),
    ('Swipe Left', Icons.arrow_back, 'Navigate Left'),
    ('Swipe Right', Icons.arrow_forward, 'Navigate Right'),
    ('Tap', Icons.touch_app, 'Select / OK'),
    ('Double Tap', Icons.ads_click, 'Back'),
    ('Long Press', Icons.pan_tool, 'Menu'),
    ('Two-Finger Tap', Icons.pinch, 'Home'),
  ];

  void _handlePanEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    final rc = RemoteScope.of(context);
    String gesture;

    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx.abs() < _sensitivity) return;
      if (v.dx > 0) {
        gesture = 'Swipe Right';
        rc.key(core.Key.right);
      } else {
        gesture = 'Swipe Left';
        rc.key(core.Key.left);
      }
    } else {
      if (v.dy.abs() < _sensitivity) return;
      if (v.dy > 0) {
        gesture = 'Swipe Down';
        rc.key(core.Key.down);
      } else {
        gesture = 'Swipe Up';
        rc.key(core.Key.up);
      }
    }

    if (_haptic) HapticFeedback.lightImpact();
    setState(() {
      _lastGesture = gesture;
      _gestureCount++;
    });
  }

  void _handleTap() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    if (_haptic) HapticFeedback.lightImpact();
    setState(() {
      _lastGesture = 'Tap';
      _gestureCount++;
    });
  }

  void _handleDoubleTap() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.back);
    if (_haptic) HapticFeedback.mediumImpact();
    setState(() {
      _lastGesture = 'Double Tap';
      _gestureCount++;
    });
  }

  void _handleLongPress() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    if (_haptic) HapticFeedback.heavyImpact();
    setState(() {
      _lastGesture = 'Long Press';
      _gestureCount++;
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
        title: Text('Gesture Pad',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _gestureArea(),
          const SizedBox(height: AppSpacing.md),
          _statusRow(),
          const SizedBox(height: AppSpacing.md),
          _sensitivitySlider(),
          const SizedBox(height: AppSpacing.md),
          _hapticToggle(),
          const SizedBox(height: AppSpacing.md),
          _gestureGuide(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _gestureArea() => GestureDetector(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPress: _handleLongPress,
        onPanEnd: _handlePanEnd,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe, size: 48,
                  color: hex(AppColors.primary).withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Gesture Pad',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary), weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Swipe, tap, or long-press here',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      );

  Widget _statusRow() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(_lastGesture,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
                Text('Last Gesture',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Column(
              children: [
                Text('$_gestureCount',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
                Text('Total',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _sensitivitySlider() => Container(
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
                Text('Sensitivity',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text(_sensitivity <= 20
                    ? 'High'
                    : _sensitivity <= 60
                        ? 'Normal'
                        : 'Low',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Slider(
              value: _sensitivity,
              min: 10,
              max: 100,
              divisions: 9,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _sensitivity = v),
            ),
          ],
        ),
      );

  Widget _hapticToggle() => GestureDetector(
        onTap: () => setState(() => _haptic = !_haptic),
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
                child: Text('Haptic Feedback',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_haptic ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _haptic ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _haptic ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(
                          _haptic ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _gestureGuide() => Container(
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
            Text('Gesture Guide',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._gestureMap.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(g.$2, size: 16, color: hex(AppColors.primary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: Text(g.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 11)),
                      ),
                      Expanded(
                        child: Text(g.$3,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 10)),
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
                'Use the gesture pad as a touchpad-style controller. Swipe to navigate, tap to select, double-tap for back, long-press for menu. Adjust sensitivity to match your preference.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
