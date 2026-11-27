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
  String _lastGesture = '--';
  int _gestures = 0;

  static const _gestureDefs = <(String, String, IconData, int)>[
    ('Swipe Up', 'Volume Up', Icons.arrow_upward, AppColors.signalEmerald),
    ('Swipe Down', 'Volume Down', Icons.arrow_downward, AppColors.error),
    ('Swipe Left', 'Previous Channel', Icons.arrow_back, AppColors.primary),
    ('Swipe Right', 'Next Channel', Icons.arrow_forward, AppColors.secondary),
    ('Two-Finger Tap', 'Mute', Icons.volume_off, AppColors.alertAmber),
    ('Pinch In', 'Zoom Out / Back', Icons.zoom_out, AppColors.tertiary),
    ('Pinch Out', 'Zoom In / Menu', Icons.zoom_in, AppColors.primary),
    ('Circle CW', 'Volume Up (smooth)', Icons.rotate_right, AppColors.signalEmerald),
  ];

  Offset _panDelta = Offset.zero;

  void _onPanStart(DragStartDetails d) {
    _panDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _panDelta += d.delta;
  }

  void _onPanEnd(DragEndDetails d) {
    final dx = _panDelta.dx;
    final dy = _panDelta.dy;
    if (dx.abs() < 30 && dy.abs() < 30) return;

    final rc = RemoteScope.of(context);
    String gesture;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        gesture = 'Swipe Right';
        rc.key(core.Key.right);
      } else {
        gesture = 'Swipe Left';
        rc.key(core.Key.left);
      }
    } else {
      if (dy > 0) {
        gesture = 'Swipe Down';
        rc.key(core.Key.volumeDown);
      } else {
        gesture = 'Swipe Up';
        rc.key(core.Key.volumeUp);
      }
    }

    setState(() {
      _lastGesture = gesture;
      _gestures++;
    });
    HapticFeedback.mediumImpact();
  }

  void _onTap() {
    RemoteScope.of(context).key(core.Key.ok);
    setState(() {
      _lastGesture = 'Tap';
      _gestures++;
    });
    HapticFeedback.lightImpact();
  }

  void _onDoubleTap() {
    RemoteScope.of(context).key(core.Key.mute);
    setState(() {
      _lastGesture = 'Double Tap';
      _gestures++;
    });
    HapticFeedback.mediumImpact();
  }

  void _onLongPress() {
    RemoteScope.of(context).key(core.Key.menu);
    setState(() {
      _lastGesture = 'Long Press';
      _gestures++;
    });
    HapticFeedback.heavyImpact();
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
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          _gestureArea(),
          const SizedBox(height: AppSpacing.lg),
          _gestureGuide(),
          const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.gesture,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Gesture Pad',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Control your TV with intuitive gestures on the pad below',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _stat('Last', _lastGesture, AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat('Count', '$_gestures', AppColors.signalEmerald),
        ],
      );

  Widget _stat(String label, String val, int c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(c).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Text(val,
                  style: gfont(AppType.bodyMd,
                      color: hex(c), size: 14, weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _gestureArea() => GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _onTap,
        onDoubleTap: _onDoubleTap,
        onLongPress: _onLongPress,
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app,
                    size: 40,
                    color: hex(AppColors.outlineVariant)),
                const SizedBox(height: 8),
                Text('Gesture Area',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.outline),
                        weight: FontWeight.w600,
                        size: 14)),
                const SizedBox(height: 4),
                Text(
                  'Swipe, tap, double-tap, or long-press',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _gestureGuide() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gesture Guide',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: 8),
            ..._gestureDefs.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(g.$3, size: 18, color: hex(g.$4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.$1,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 11)),
                            Text(g.$2,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline), size: 10)),
                          ],
                        ),
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
                'Multi-gesture control pad with swipe, tap, double-tap, and '
                'long-press. All commands sent to connected TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
