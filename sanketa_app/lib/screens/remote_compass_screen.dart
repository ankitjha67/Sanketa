import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteCompassScreen extends StatefulWidget {
  const RemoteCompassScreen({super.key});

  @override
  State<RemoteCompassScreen> createState() => _RemoteCompassScreenState();
}

class _RemoteCompassScreenState extends State<RemoteCompassScreen> {
  int _heading = 0;
  bool _lockEnabled = false;

  static const _directions = <(String, int, core.Key)>[
    ('Up', 0, core.Key.up),
    ('Right', 90, core.Key.right),
    ('Down', 180, core.Key.down),
    ('Left', 270, core.Key.left),
  ];

  static const _diagonals = <(String, int, List<core.Key>)>[
    ('Up-Right', 45, [core.Key.up, core.Key.right]),
    ('Down-Right', 135, [core.Key.down, core.Key.right]),
    ('Down-Left', 225, [core.Key.down, core.Key.left]),
    ('Up-Left', 315, [core.Key.up, core.Key.left]),
  ];

  void _sendDirection(core.Key key) {
    final rc = RemoteScope.of(context);
    rc.key(key);
    HapticFeedback.mediumImpact();
  }

  void _sendDiagonal(List<core.Key> keys) {
    final rc = RemoteScope.of(context);
    for (final k in keys) {
      rc.key(k);
    }
    HapticFeedback.mediumImpact();
  }

  void _rotateHeading(int degrees) {
    if (_lockEnabled) return;
    setState(() => _heading = (_heading + degrees) % 360);
    HapticFeedback.selectionClick();
  }

  void _sendOk() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    HapticFeedback.heavyImpact();
  }

  String _headingLabel() {
    if (_heading == 0) return 'N (Up)';
    if (_heading == 90) return 'E (Right)';
    if (_heading == 180) return 'S (Down)';
    if (_heading == 270) return 'W (Left)';
    if (_heading == 45) return 'NE';
    if (_heading == 135) return 'SE';
    if (_heading == 225) return 'SW';
    if (_heading == 315) return 'NW';
    return '$_heading°';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Compass',
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
          _compassRose(),
          const SizedBox(height: AppSpacing.lg),
          _headingRow(),
          const SizedBox(height: AppSpacing.md),
          _lockToggle(),
          const SizedBox(height: AppSpacing.md),
          _rotateButtons(),
          const SizedBox(height: AppSpacing.lg),
          _quickDirections(),
          const SizedBox(height: AppSpacing.lg),
          _diagonalButtons(),
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
            Icon(Icons.explore, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('D-Pad Compass',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Visual compass for directional navigation on your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _compassRose() => Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hex(AppColors.surfaceContainerLow),
                  border: Border.all(
                      color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                      width: 2),
                ),
              ),
              ..._directions.map((d) {
                final isActive = _heading == d.$2;
                final dx = d.$2 == 90
                    ? 70.0
                    : d.$2 == 270
                        ? -70.0
                        : 0.0;
                final dy = d.$2 == 0
                    ? -70.0
                    : d.$2 == 180
                        ? 70.0
                        : 0.0;
                return Positioned(
                  left: 110 + dx - 24,
                  top: 110 + dy - 24,
                  child: GestureDetector(
                    onTap: () => _sendDirection(d.$3),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hex(isActive
                                ? AppColors.primary
                                : AppColors.surfaceContainerLow)
                            .withValues(alpha: isActive ? 0.2 : 1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hex(isActive
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: isActive ? 0.5 : 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(d.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(isActive
                                    ? AppColors.primary
                                    : AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 10)),
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: _sendOk,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: hex(AppColors.primary).withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: Center(
                    child: Text('OK',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w700,
                            size: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _headingRow() => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation, size: 18, color: hex(AppColors.primary)),
            const SizedBox(width: 8),
            Text('Heading: $_heading°',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(_headingLabel(),
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600,
                      size: 10)),
            ),
          ],
        ),
      );

  Widget _lockToggle() => GestureDetector(
        onTap: () {
          setState(() => _lockEnabled = !_lockEnabled);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_lockEnabled
                    ? AppColors.alertAmber
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _lockEnabled ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_lockEnabled
                      ? AppColors.alertAmber
                      : AppColors.outlineVariant)
                  .withValues(alpha: _lockEnabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(_lockEnabled ? Icons.lock : Icons.lock_open,
                  size: 20,
                  color: hex(
                      _lockEnabled ? AppColors.alertAmber : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lock Rotation',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(_lockEnabled ? 'Heading locked' : 'Tap to lock',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hex(_lockEnabled
                          ? AppColors.alertAmber
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_lockEnabled ? 'LOCKED' : 'FREE',
                    style: gfont(AppType.bodySm,
                        color: hex(_lockEnabled
                            ? AppColors.alertAmber
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ],
          ),
        ),
      );

  Widget _rotateButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _rotateHeading(-45),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.secondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.secondary).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rotate_left,
                        size: 18, color: hex(AppColors.secondary)),
                    const SizedBox(width: 4),
                    Text('-45°',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.secondary),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _heading = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.outline).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.outline).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text('Reset N',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline),
                          weight: FontWeight.w600,
                          size: 11)),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => _rotateHeading(45),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.secondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.secondary).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('+45°',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.secondary),
                            weight: FontWeight.w600,
                            size: 11)),
                    const SizedBox(width: 4),
                    Icon(Icons.rotate_right,
                        size: 18, color: hex(AppColors.secondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _quickDirections() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Directions',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _directions.map((d) {
              final isActive = _heading == d.$2;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _sendDirection(d.$3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: hex(isActive
                                ? AppColors.primary
                                : AppColors.surfaceContainerLow)
                            .withValues(alpha: isActive ? 0.12 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: hex(isActive
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: isActive ? 0.4 : 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                              d.$2 == 0
                                  ? Icons.arrow_upward
                                  : d.$2 == 90
                                      ? Icons.arrow_forward
                                      : d.$2 == 180
                                          ? Icons.arrow_downward
                                          : Icons.arrow_back,
                              size: 20,
                              color: hex(isActive
                                  ? AppColors.primary
                                  : AppColors.outline)),
                          const SizedBox(height: 2),
                          Text(d.$1,
                              style: gfont(AppType.bodySm,
                                  color: hex(isActive
                                      ? AppColors.primary
                                      : AppColors.outline),
                                  size: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _diagonalButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagonal Nav',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _diagonals.map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _sendDiagonal(d.$3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(AppColors.tertiary).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                            color: hex(AppColors.tertiary)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(d.$1,
                            textAlign: TextAlign.center,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.tertiary),
                                weight: FontWeight.w500,
                                size: 9)),
                      ),
                    ),
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
                'Visual compass for TV D-pad navigation. Tap directions to send keys. '
                'Rotate the heading or lock it for consistent orientation.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
