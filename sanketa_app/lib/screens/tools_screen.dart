import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import 'app_launcher_screen.dart';
import 'connection_doctor_screen.dart';
import 'custom_layout_screen.dart';
import 'debloat_screen.dart';
import 'macro_screen.dart';
import 'backup_screen.dart';
import 'multi_room_screen.dart';
import 'network_diagnostics_screen.dart';
import 'parental_controls_screen.dart';
import 'screen_mirror_screen.dart';
import 'search_shortcuts_screen.dart';
import 'touchpad_screen.dart';
import 'tv_stats_screen.dart';
import 'usage_analytics_screen.dart';
import 'voice_screen.dart';
import 'widget_config_screen.dart';

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
                childAspectRatio: 1.1,
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
                  _ToolCard(
                    icon: Icons.healing_rounded,
                    title: 'Doctor',
                    subtitle: 'Diagnose connections',
                    color: AppColors.primary,
                    onTap: () => _push(context, const ConnectionDoctorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Macros',
                    subtitle: 'Automate TV routines',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const MacroScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bookmark_rounded,
                    title: 'Shortcuts',
                    subtitle: 'Saved search queries',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const SearchShortcutsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Layouts',
                    subtitle: 'Custom remote grids',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const CustomLayoutScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.shield_rounded,
                    title: 'Parental',
                    subtitle: 'PIN lock & key blocking',
                    color: AppColors.error,
                    onTap: () => _push(context, const ParentalControlsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.devices_rounded,
                    title: 'Multi-Room',
                    subtitle: 'Control all TVs',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const MultiRoomScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.mic_rounded,
                    title: 'Voice',
                    subtitle: 'Speak to type on TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VoiceScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.touch_app_rounded,
                    title: 'Touchpad',
                    subtitle: 'Full-screen touchpad',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TouchpadScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wifi_find_rounded,
                    title: 'Network',
                    subtitle: 'Diagnose connectivity',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const NetworkDiagnosticsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Usage',
                    subtitle: 'TV usage analytics',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const UsageAnalyticsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.cast_connected_rounded,
                    title: 'Mirror',
                    subtitle: 'Cast phone screen',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ScreenMirrorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.backup_rounded,
                    title: 'Backup',
                    subtitle: 'Save & restore data',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const BackupScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.widgets_rounded,
                    title: 'Widgets',
                    subtitle: 'Home screen controls',
                    color: AppColors.primary,
                    onTap: () => _push(context, const WidgetConfigScreen()),
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
    final c = RemoteScope.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RemoteScope(controller: c, child: screen),
    ));
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
