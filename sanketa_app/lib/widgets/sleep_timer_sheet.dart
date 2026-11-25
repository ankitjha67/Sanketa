import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

void showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: hex(AppColors.surfaceContainerLow),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (_) => RemoteScope(
      controller: RemoteScope.of(context),
      child: const _SleepTimerContent(),
    ),
  );
}

class _SleepTimerContent extends StatelessWidget {
  const _SleepTimerContent();

  static const _presets = [
    (label: '15m', duration: Duration(minutes: 15)),
    (label: '30m', duration: Duration(minutes: 30)),
    (label: '45m', duration: Duration(minutes: 45)),
    (label: '1h', duration: Duration(hours: 1)),
    (label: '1.5h', duration: Duration(minutes: 90)),
    (label: '2h', duration: Duration(hours: 2)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final timer = c.sleepTimer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: hex(AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.nightlight_round,
                  size: 22, color: hex(AppColors.tertiary)),
              const SizedBox(width: AppSpacing.sm),
              Text('Sleep Timer',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 18,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (timer.isActive) _activeView(context, c) else _presetsGrid(context, c),
        ],
      ),
    );
  }

  Widget _presetsGrid(BuildContext context, RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auto-off after',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurfaceVariant))),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in _presets)
              GestureDetector(
                onTap: () {
                  c.sleepTimer.start(p.duration);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 88,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: panel(
                    fill: AppColors.surfaceContainer,
                    radius: AppRadii.md,
                  ),
                  child: Text(p.label,
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.tertiary),
                          size: 16,
                          weight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _activeView(BuildContext context, RemoteController c) {
    final timer = c.sleepTimer;
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 1.0 - timer.progress,
                  strokeWidth: 6,
                  backgroundColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(hex(AppColors.tertiary)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nightlight_round,
                      size: 20, color: hex(AppColors.tertiary)),
                  const SizedBox(height: 4),
                  Text(timer.label,
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 22,
                          weight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                timer.cancel();
                Navigator.of(context).pop();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  border: Border.all(
                      color: hex(AppColors.error).withValues(alpha: 0.3)),
                ),
                child: Text('Cancel',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: () => timer.addTime(const Duration(minutes: 15)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.tertiary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.base),
                  border: Border.all(
                      color: hex(AppColors.tertiary).withValues(alpha: 0.3)),
                ),
                child: Text('+15m',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.tertiary),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
