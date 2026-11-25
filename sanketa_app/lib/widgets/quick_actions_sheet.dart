import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';
import 'sleep_timer_sheet.dart';

void showQuickActionsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: hex(AppColors.surfaceContainerLow),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (_) => RemoteScope(
      controller: RemoteScope.of(context),
      child: const _QuickActionsContent(),
    ),
  );
}

class _ActionDef {
  const _ActionDef(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final int color;
}

class _QuickActionsContent extends StatefulWidget {
  const _QuickActionsContent();

  @override
  State<_QuickActionsContent> createState() => _QuickActionsContentState();
}

class _QuickActionsContentState extends State<_QuickActionsContent> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final actions = _buildActions(c);
    final filtered = _filter.isEmpty
        ? actions
        : actions
            .where((a) =>
                a.$1.label.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.flash_on_rounded,
                    size: 22, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Text('Quick Actions',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 18,
                        weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 40,
              decoration: panel(
                  fill: AppColors.surfaceContainer,
                  radius: AppRadii.md,
                  borderOpacity: 0.2),
              child: TextField(
                onChanged: (v) => setState(() => _filter = v),
                style:
                    gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Filter actions...',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                  prefixIcon: Icon(Icons.search,
                      size: 18, color: hex(AppColors.outlineVariant)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                controller: scroll,
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.15,
                children: [
                  for (final (def, onTap) in filtered) _chip(def, onTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(_ActionDef, VoidCallback)> _buildActions(RemoteController c) {
    final list = <(_ActionDef, VoidCallback)>[
      (
        const _ActionDef(
            Icons.power_settings_new, 'Power Off', AppColors.error),
        () {
          c.power(false);
          Navigator.of(context).pop();
        },
      ),
      (
        const _ActionDef(Icons.power, 'Power On', AppColors.signalEmerald),
        () {
          c.power(true);
          Navigator.of(context).pop();
        },
      ),
      (
        _ActionDef(c.isMuted ? Icons.volume_off : Icons.volume_up,
            c.isMuted ? 'Unmute' : 'Mute', AppColors.secondary),
        () {
          c.key(core.Key.mute);
          Navigator.of(context).pop();
        },
      ),
      (
        const _ActionDef(Icons.volume_up, 'Vol +', AppColors.secondary),
        () => c.key(core.Key.volumeUp),
      ),
      (
        const _ActionDef(Icons.volume_down, 'Vol -', AppColors.secondary),
        () => c.key(core.Key.volumeDown),
      ),
      (
        const _ActionDef(
            Icons.home, 'Home', AppColors.primaryContainer),
        () {
          c.key(core.Key.home);
          Navigator.of(context).pop();
        },
      ),
      (
        const _ActionDef(
            Icons.arrow_back, 'Back', AppColors.primaryContainer),
        () {
          c.key(core.Key.back);
          Navigator.of(context).pop();
        },
      ),
      (
        const _ActionDef(
            Icons.nightlight_round, 'Sleep Timer', AppColors.tertiary),
        () {
          Navigator.of(context).pop();
          showSleepTimerSheet(context);
        },
      ),
      (
        const _ActionDef(
            Icons.input, 'HDMI 1', AppColors.onSurfaceVariant),
        () {
          c.setSource('HDMI 1');
          Navigator.of(context).pop();
        },
      ),
      (
        const _ActionDef(
            Icons.input, 'HDMI 2', AppColors.onSurfaceVariant),
        () {
          c.setSource('HDMI 2');
          Navigator.of(context).pop();
        },
      ),
    ];

    if (c.caps.appLaunch) {
      list.addAll([
        (
          const _ActionDef(
              Icons.play_arrow, 'Netflix', AppColors.netflix),
          () {
            c.launch('NETFLIX');
            Navigator.of(context).pop();
          },
        ),
        (
          const _ActionDef(
              Icons.play_arrow, 'YouTube', AppColors.youTube),
          () {
            c.launch('YouTube');
            Navigator.of(context).pop();
          },
        ),
        (
          const _ActionDef(Icons.play_arrow, 'Prime', AppColors.prime),
          () {
            c.launch('prime');
            Navigator.of(context).pop();
          },
        ),
        (
          const _ActionDef(
              Icons.play_arrow, 'Disney+', AppColors.disney),
          () {
            c.launch('Disney+');
            Navigator.of(context).pop();
          },
        ),
      ]);
    }

    return list;
  }

  Widget _chip(_ActionDef def, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration:
            panel(fill: AppColors.surfaceContainer, radius: AppRadii.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(def.color).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(def.icon, size: 18, color: hex(def.color)),
            ),
            const SizedBox(height: 6),
            Text(def.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    size: 11,
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
