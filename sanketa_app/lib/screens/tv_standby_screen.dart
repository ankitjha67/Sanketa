import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvStandbyScreen extends StatefulWidget {
  const TvStandbyScreen({super.key});

  @override
  State<TvStandbyScreen> createState() => _TvStandbyScreenState();
}

class _TvStandbyScreenState extends State<TvStandbyScreen> {
  bool _standby = false;
  int _mode = 0;

  static const _modes = <(String, IconData, String, int)>[
    ('Quick Start', Icons.flash_on, 'TV wakes instantly, uses more standby power', AppColors.alertAmber),
    ('Eco Standby', Icons.eco, 'Low power standby, slower wake', AppColors.signalEmerald),
    ('Network Standby', Icons.wifi, 'Keeps Wi-Fi alive for WoL/Cast', AppColors.primary),
    ('Deep Sleep', Icons.bedtime, 'Minimal power, full cold boot on wake', AppColors.tertiary),
  ];

  static const _quickActions = <(String, IconData, core.Key, int)>[
    ('Power Off', Icons.power_settings_new, core.Key.power, AppColors.error),
    ('Sleep Timer', Icons.timer, core.Key.menu, AppColors.tertiary),
    ('Mute & Dim', Icons.brightness_low, core.Key.mute, AppColors.secondary),
    ('Screen Off', Icons.tv_off, core.Key.menu, AppColors.primary),
  ];

  void _toggleStandby() {
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.power);
    setState(() => _standby = !_standby);
  }

  void _sendKey(core.Key key) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Standby',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statusCard(),
          const SizedBox(height: AppSpacing.md),
          _standbyModes(),
          const SizedBox(height: AppSpacing.md),
          _quickActionsGrid(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => GestureDetector(
        onTap: _toggleStandby,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(_standby ? AppColors.outlineVariant : AppColors.signalEmerald)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_standby ? AppColors.outlineVariant : AppColors.signalEmerald)
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _standby ? Icons.tv_off : Icons.tv,
                size: 48,
                color: hex(_standby ? AppColors.outline : AppColors.signalEmerald),
              ),
              const SizedBox(height: 8),
              Text(
                _standby ? 'Standby' : 'TV is ON',
                style: gfont(AppType.bodyMd,
                    color: hex(_standby ? AppColors.outline : AppColors.signalEmerald),
                    weight: FontWeight.w700,
                    size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                _standby
                    ? 'Tap to wake TV'
                    : 'Tap to enter standby',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_modes[_mode].$4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_modes[_mode].$1,
                    style: gfont(AppType.bodySm,
                        color: hex(_modes[_mode].$4),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _standbyModes() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Standby Mode',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._modes.asMap().entries.map((e) {
              final m = e.value;
              final active = e.key == _mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _mode = e.key),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hex(active ? m.$4 : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: hex(active ? m.$4 : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(m.$2,
                            size: 20,
                            color: hex(active ? m.$4 : AppColors.outline)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.$1,
                                  style: gfont(AppType.bodySm,
                                      color: hex(active ? m.$4 : AppColors.onSurface),
                                      weight: FontWeight.w600,
                                      size: 11)),
                              Text(m.$3,
                                  style: gfont(AppType.bodySm,
                                      color: hex(AppColors.outline), size: 9)),
                            ],
                          ),
                        ),
                        if (active)
                          Icon(Icons.check_circle,
                              size: 18, color: hex(m.$4)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );

  Widget _quickActionsGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _quickActions.map((a) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _sendKey(a.$3),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: hex(a.$4).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                          color: hex(a.$4).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(a.$2, size: 22, color: hex(a.$4)),
                        const SizedBox(height: 4),
                        Text(a.$1,
                            textAlign: TextAlign.center,
                            style: gfont(AppType.bodySm,
                                color: hex(a.$4),
                                weight: FontWeight.w500,
                                size: 8)),
                      ],
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
                'Manage TV standby behaviour. Choose between Quick Start, Eco, Network, or Deep Sleep modes. Use quick actions for common power tasks. All controls send IR/IP commands locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
