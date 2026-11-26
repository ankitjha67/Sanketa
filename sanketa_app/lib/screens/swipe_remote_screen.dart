import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SwipeRemoteScreen extends StatefulWidget {
  const SwipeRemoteScreen({super.key});

  @override
  State<SwipeRemoteScreen> createState() => _SwipeRemoteScreenState();
}

class _SwipeRemoteScreenState extends State<SwipeRemoteScreen>
    with SingleTickerProviderStateMixin {
  String _lastAction = '';
  Offset _start = Offset.zero;
  bool _swiping = false;
  late AnimationController _pulseCtrl;
  bool _haptic = true;

  static const _swipeThreshold = 40.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    _start = d.localPosition;
    _swiping = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_swiping) return;
    final delta = d.localPosition - _start;
    if (delta.distance < _swipeThreshold) return;

    _swiping = false;
    final rc = RemoteScope.of(context);

    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 0) {
        rc.key(core.Key.right);
        _flash('Right');
      } else {
        rc.key(core.Key.left);
        _flash('Left');
      }
    } else {
      if (delta.dy > 0) {
        rc.key(core.Key.down);
        _flash('Down');
      } else {
        rc.key(core.Key.up);
        _flash('Up');
      }
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _swiping = false;
  }

  void _onTap() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    _flash('OK');
  }

  void _onDoubleTap() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.back);
    _flash('Back');
  }

  void _onLongPress() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    _flash('Menu');
  }

  void _flash(String action) {
    setState(() => _lastAction = action);
    if (_haptic) HapticFeedback.lightImpact();
    _pulseCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _lastAction = '');
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
        title: Text('Swipe Remote',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _haptic = !_haptic),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _haptic ? Icons.vibration : Icons.do_not_disturb,
                size: 20,
                color: hex(_haptic ? AppColors.primary : AppColors.outline),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _swipeSurface()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _swipeSurface() => GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _onTap,
        onDoubleTap: _onDoubleTap,
        onLongPress: _onLongPress,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_lastAction.isNotEmpty
                      ? AppColors.primary
                      : AppColors.outlineVariant)
                  .withValues(alpha: _lastAction.isNotEmpty ? 0.5 : 0.2),
              width: _lastAction.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_lastAction.isNotEmpty)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) => Opacity(
                          opacity: 1 - _pulseCtrl.value,
                          child: Transform.scale(
                            scale: 1 + _pulseCtrl.value * 0.3,
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: hex(AppColors.primary)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(_lastAction,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.primary),
                                    weight: FontWeight.w700,
                                    size: 14)),
                          ),
                        ),
                      )
                    else ...[
                      Icon(Icons.swipe,
                          size: 48,
                          color: hex(AppColors.outline)
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Swipe to navigate',
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.outline),
                              weight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('Tap = OK · Double-tap = Back · Long-press = Menu',
                          textAlign: TextAlign.center,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline)
                                  .withValues(alpha: 0.6),
                              size: 10)),
                    ],
                  ],
                ),
              ),
              // direction hints
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 24,
                      color: hex(AppColors.outline).withValues(alpha: 0.2)),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 24,
                      color: hex(AppColors.outline).withValues(alpha: 0.2)),
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.keyboard_arrow_left,
                      size: 24,
                      color: hex(AppColors.outline).withValues(alpha: 0.2)),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.keyboard_arrow_right,
                      size: 24,
                      color: hex(AppColors.outline).withValues(alpha: 0.2)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _bottomBar() {
    final rc = RemoteScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surface),
        border: Border(
          top: BorderSide(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomBtn(Icons.power_settings_new, 'Power', () {
            rc.key(core.Key.power);
            _flash('Power');
          }),
          _bottomBtn(Icons.home, 'Home', () {
            rc.key(core.Key.home);
            _flash('Home');
          }),
          _bottomBtn(Icons.volume_down, 'Vol-', () {
            rc.key(core.Key.volumeDown);
            _flash('Vol-');
          }),
          _bottomBtn(Icons.volume_up, 'Vol+', () {
            rc.key(core.Key.volumeUp);
            _flash('Vol+');
          }),
          _bottomBtn(Icons.volume_off, 'Mute', () {
            rc.key(core.Key.mute);
            _flash('Mute');
          }),
        ],
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, size: 20, color: hex(AppColors.onSurface)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );
}
