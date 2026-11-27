import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteGestureProScreen extends StatefulWidget {
  const RemoteGestureProScreen({super.key});

  @override
  State<RemoteGestureProScreen> createState() => _RemoteGestureProScreenState();
}

class _RemoteGestureProScreenState extends State<RemoteGestureProScreen> {
  bool _enabled = true;
  int _sensitivity = 50;
  int _gestureCount = 0;
  String _lastGesture = 'None';
  int _modeIdx = 0;

  static const _modes = <(String, IconData, int, String)>[
    ('D-Pad', Icons.gamepad, AppColors.primary, 'Swipe to navigate'),
    ('Volume', Icons.volume_up, AppColors.signalEmerald, 'Swipe up/down for volume'),
    ('Channel', Icons.tv, AppColors.alertAmber, 'Swipe left/right for channels'),
  ];

  static const _gestureMap = <(String, IconData, String, int)>[
    ('Swipe Up', Icons.arrow_upward, 'Up / Vol+ / Ch+', AppColors.primary),
    ('Swipe Down', Icons.arrow_downward, 'Down / Vol- / Ch-', AppColors.secondary),
    ('Swipe Left', Icons.arrow_back, 'Left / Vol- / Ch-', AppColors.tertiary),
    ('Swipe Right', Icons.arrow_forward, 'Right / Vol+ / Ch+', AppColors.signalEmerald),
    ('Single Tap', Icons.touch_app, 'OK / Select', AppColors.alertAmber),
    ('Double Tap', Icons.ads_click, 'Back', AppColors.error),
    ('Long Press', Icons.pan_tool, 'Home', AppColors.outline),
    ('Two-Finger Tap', Icons.swipe, 'Menu', AppColors.primary),
  ];

  void _handleGesture(String name, core.Key key) {
    if (!_enabled) return;
    final rc = RemoteScope.of(context);
    rc.key(key);
    setState(() {
      _gestureCount++;
      _lastGesture = name;
    });
    HapticFeedback.mediumImpact();
  }

  core.Key _keyForSwipe(String direction) {
    switch (_modeIdx) {
      case 0:
        return direction == 'Up'
            ? core.Key.up
            : direction == 'Down'
                ? core.Key.down
                : direction == 'Left'
                    ? core.Key.left
                    : core.Key.right;
      case 1:
        return direction == 'Up' || direction == 'Right'
            ? core.Key.volumeUp
            : core.Key.volumeDown;
      case 2:
        return direction == 'Up' || direction == 'Right'
            ? core.Key.up
            : core.Key.down;
      default:
        return core.Key.ok;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Gesture Pro',
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
          _enableToggle(),
          const SizedBox(height: AppSpacing.md),
          _modeSelector(),
          const SizedBox(height: AppSpacing.md),
          _touchPad(),
          const SizedBox(height: AppSpacing.md),
          _sensitivitySlider(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          Text('Gesture Guide',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: AppSpacing.sm),
          ..._gestureMap.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _guideCard(g),
              )),
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
            Icon(Icons.swipe, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Advanced Gestures',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Swipe, tap, and long-press on the pad below to control your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _enableToggle() => GestureDetector(
        onTap: () {
          setState(() => _enabled = !_enabled);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_enabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app,
                  size: 22,
                  color: hex(
                      _enabled ? AppColors.signalEmerald : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gesture Control',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_enabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _modeSelector() => Row(
        children: _modes.asMap().entries.map((e) {
          final active = e.key == _modeIdx;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _modeIdx = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value.$2,
                          size: 20, color: hex(e.value.$3)),
                      const SizedBox(height: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _touchPad() => GestureDetector(
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          if (d.primaryVelocity! < -100) {
            _handleGesture('Swipe Up', _keyForSwipe('Up'));
          } else if (d.primaryVelocity! > 100) {
            _handleGesture('Swipe Down', _keyForSwipe('Down'));
          }
        },
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          if (d.primaryVelocity! < -100) {
            _handleGesture('Swipe Left', _keyForSwipe('Left'));
          } else if (d.primaryVelocity! > 100) {
            _handleGesture('Swipe Right', _keyForSwipe('Right'));
          }
        },
        onTap: () => _handleGesture('Tap', core.Key.ok),
        onDoubleTap: () => _handleGesture('Double Tap', core.Key.back),
        onLongPress: () => _handleGesture('Long Press', core.Key.home),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.06 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_enabled ? AppColors.primary : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.2 : 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app,
                  size: 36,
                  color: hex(_enabled ? AppColors.primary : AppColors.outline)),
              const SizedBox(height: 8),
              Text(_enabled ? 'Touch Pad Active' : 'Disabled',
                  style: gfont(AppType.bodyMd,
                      color: hex(
                          _enabled ? AppColors.primary : AppColors.outline),
                      weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Last: $_lastGesture',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      );

  Widget _sensitivitySlider() => Container(
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
            Row(
              children: [
                Text('Sensitivity',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('$_sensitivity%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _sensitivity.toDouble(),
              min: 10,
              max: 100,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) => setState(() => _sensitivity = v.round()),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Gestures', '$_gestureCount', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Mode', _modes[_modeIdx].$1, AppColors.secondary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 18, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _guideCard((String, IconData, String, int) g) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(g.$4).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(g.$4).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(g.$2, size: 20, color: hex(g.$4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(g.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
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
                'Swipe, tap, double-tap, or long-press the pad to control your TV. '
                'Switch modes to change gesture mapping.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
