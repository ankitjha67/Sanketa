import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import '../widgets/connection_bar.dart';
import '../widgets/remote_pad.dart';
import '../widgets/tv_keyboard_sheet.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                  child: Column(
                    children: const [
                      ConnectionBar(),
                      SizedBox(height: AppSpacing.md),
                      TvKeyboardSheet(),
                      SizedBox(height: AppSpacing.md),
                      RemotePad(),
                      SizedBox(height: AppSpacing.md),
                      _SentReadout(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _bottomNav(c),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(bottom: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.settings_remote, size: 20, color: hex(AppColors.primaryContainer)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text('SANKETA',
                          style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(AppColors.surfaceContainerHighest),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text('Smart IR', style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurfaceVariant), size: 10)),
                      ),
                    ]),
                    Text('Samsung Neo QLED 65"', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
                  ],
                ),
              ),
              _pill(Icons.keyboard, 'TV Keyboard'),
              const SizedBox(width: 4),
              Icon(Icons.tune, size: 20, color: hex(AppColors.onSurfaceVariant)),
            ]),
          ),
        ),
      );

  Widget _pill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: hex(AppColors.primaryContainer)),
          const SizedBox(width: 6),
          Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w500)),
        ]),
      );

  Widget _bottomNav(RemoteController c) => Container(
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLowest),
          border: Border(top: BorderSide(color: hex(AppColors.outlineVariant))),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Row(
                children: [
                  Expanded(child: _navItem(Icons.settings_remote, 'Remote', active: true)),
                  Expanded(child: _navItem(Icons.search, 'Search')),
                  Expanded(child: _navItem(Icons.cast, 'Cast')),
                  Expanded(child: _navItem(Icons.devices, 'Devices')),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _navItem(IconData icon, String label, {bool active = false}) {
    final color = active ? hex(AppColors.primaryContainer) : hex(AppColors.onSurfaceVariant);
    return SizedBox(
      height: AppSpacing.touchTargetMin,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 2),
        Text(label, style: gfont(AppType.labelMonoSm, color: color)),
      ]),
    );
  }
}

/// A live mono readout of the last commands the UI sent through the contract —
/// visible proof the whole screen is wired to a real [ControlAdapter].
class _SentReadout extends StatelessWidget {
  const _SentReadout();

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final last = c.actionLog.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(fill: AppColors.surfaceContainerLowest, radius: AppRadii.md, borderOpacity: 0.25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SENT TO TV (via ControlAdapter)',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
        const SizedBox(height: 4),
        if (last.isEmpty)
          Text('— press any control —', style: gfont(AppType.labelMonoSm, color: hex(AppColors.outlineVariant)))
        else
          for (final a in last)
            Text(a, style: gfont(AppType.labelMonoSm, color: hex(AppColors.tertiary))),
      ]),
    );
  }
}
