import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

class TouchpadSurface extends StatefulWidget {
  const TouchpadSurface({super.key});

  @override
  State<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends State<TouchpadSurface> {
  Offset? _start;
  Offset _delta = Offset.zero;
  _SwipeDir? _lastSwipe;
  bool _swiped = false;

  static const _threshold = 40.0;

  void _onPanStart(DragStartDetails d) {
    _start = d.localPosition;
    _delta = Offset.zero;
    _swiped = false;
    _lastSwipe = null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_start == null) return;
    _delta += d.delta;
    setState(() {});

    final dx = _delta.dx;
    final dy = _delta.dy;
    if (dx.abs() < _threshold && dy.abs() < _threshold) return;

    _SwipeDir dir;
    if (dx.abs() > dy.abs()) {
      dir = dx > 0 ? _SwipeDir.right : _SwipeDir.left;
    } else {
      dir = dy > 0 ? _SwipeDir.down : _SwipeDir.up;
    }

    if (dir != _lastSwipe) {
      _lastSwipe = dir;
      _swiped = true;
      _delta = Offset.zero;
      final c = RemoteScope.of(context);
      switch (dir) {
        case _SwipeDir.up:
          c.key(core.Key.up);
        case _SwipeDir.down:
          c.key(core.Key.down);
        case _SwipeDir.left:
          c.key(core.Key.left);
        case _SwipeDir.right:
          c.key(core.Key.right);
      }
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _start = null;
    _delta = Offset.zero;
    _lastSwipe = null;
    setState(() {});
  }

  void _onTap() {
    if (_swiped) return;
    HapticFeedback.lightImpact();
    RemoteScope.of(context).key(core.Key.ok);
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    RemoteScope.of(context).key(core.Key.back);
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    RemoteScope.of(context).key(core.Key.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panel(fill: AppColors.surfaceContainerLow, radius: AppRadii.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, size: 16, color: hex(AppColors.primaryContainer)),
              const SizedBox(width: 6),
              Text('Touchpad Mode',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              const Spacer(),
              Text('Swipe to navigate',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: 'Touchpad. Swipe to navigate, tap for OK, double-tap for Back, long-press for Menu',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _onTap,
                onDoubleTap: _onDoubleTap,
                onLongPress: _onLongPress,
                child: Container(
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLowest),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                        color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(child: _crosshair()),
                      if (_delta != Offset.zero) _indicator(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _hint('Tap = OK'),
                                _hint('2x = Back'),
                                _hint('Hold = Menu'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crosshair() => CustomPaint(
        painter: _CrosshairPainter(hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      );

  Widget _indicator() {
    final dx = _delta.dx.clamp(-60.0, 60.0);
    final dy = _delta.dy.clamp(-60.0, 60.0);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.3),
          border: Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _hint(String text) => Text(text,
      style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9));
}

enum _SwipeDir { up, down, left, right }

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter old) => old.color != color;
}
