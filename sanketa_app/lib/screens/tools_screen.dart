import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import 'app_launcher_screen.dart';
import 'debloat_screen.dart';
import 'tv_stats_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(AppSpacing.lg),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
                children: [
                  _ToolCard(
                    icon: Icons.cleaning_services_rounded,
                    title: 'TV Debloat',
                    subtitle: 'Remove ads & bloatware',
                    color: AppColors.error,
                    onTap: () => _push(context, const DebloatScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.analytics_rounded,
                    title: 'TV Stats',
                    subtitle: 'Performance dashboard',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TvStatsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.apps_rounded,
                    title: 'App Launcher',
                    subtitle: 'Launch & manage TV apps',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const AppLauncherScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                Icon(Icons.build_rounded,
                    size: 20, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Text('Tools',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 16,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: panel(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: hex(color), size: 22),
            ),
            const Spacer(),
            Text(title,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
          ],
        ),
      ),
    );
  }
}
