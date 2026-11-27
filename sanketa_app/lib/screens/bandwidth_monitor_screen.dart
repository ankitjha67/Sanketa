import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class BandwidthMonitorScreen extends StatefulWidget {
  const BandwidthMonitorScreen({super.key});

  @override
  State<BandwidthMonitorScreen> createState() => _BandwidthMonitorScreenState();
}

class _BandwidthMonitorScreenState extends State<BandwidthMonitorScreen> {
  bool _monitoring = false;
  final double _download = 42.5;
  final double _upload = 8.3;
  final int _ping = 12;

  static const _devices = <(String, double, IconData, int)>[
    ('Smart TV', 15.2, Icons.tv, AppColors.primary),
    ('Phone', 8.4, Icons.phone_android, AppColors.signalEmerald),
    ('Laptop', 12.1, Icons.laptop, AppColors.secondary),
    ('Tablet', 4.3, Icons.tablet, AppColors.tertiary),
    ('Gaming Console', 2.5, Icons.sports_esports, AppColors.alertAmber),
  ];

  void _toggleMonitoring() {
    HapticFeedback.mediumImpact();
    setState(() => _monitoring = !_monitoring);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Bandwidth Monitor',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _speedCard(),
          const SizedBox(height: AppSpacing.md),
          _monitorToggle(),
          const SizedBox(height: AppSpacing.md),
          _deviceBreakdown(),
          const SizedBox(height: AppSpacing.md),
          _usageStats(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _speedCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.speed, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _speedStat('$_download', 'Mbps', 'Download', AppColors.signalEmerald),
                Container(
                  width: 1,
                  height: 40,
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                ),
                _speedStat('$_upload', 'Mbps', 'Upload', AppColors.secondary),
                Container(
                  width: 1,
                  height: 40,
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                ),
                _speedStat('$_ping', 'ms', 'Ping', AppColors.alertAmber),
              ],
            ),
          ],
        ),
      );

  Widget _speedStat(String val, String unit, String label, int color) =>
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val,
                  style: gfont(AppType.bodyMd,
                      color: hex(color),
                      weight: FontWeight.w700,
                      size: 18)),
              const SizedBox(width: 2),
              Text(unit,
                  style: gfont(AppType.bodySm,
                      color: hex(color), size: 10)),
            ],
          ),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _monitorToggle() => GestureDetector(
        onTap: _toggleMonitoring,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_heart,
                  size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Monitoring',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text(_monitoring ? 'Tracking network usage' : 'Start to track bandwidth',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_monitoring ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _monitoring ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _monitoring ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_monitoring ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _deviceBreakdown() => Container(
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
            Text('Device Breakdown',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._devices.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(d.$3, size: 18, color: hex(d.$4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(d.$4).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text('${d.$2} Mbps',
                            style: gfont(AppType.bodySm,
                                color: hex(d.$4),
                                weight: FontWeight.w600,
                                size: 10)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _usageStats() => Container(
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
            Text('Today\'s Usage',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _usageTile('Downloaded', '3.2 GB', AppColors.signalEmerald),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _usageTile('Uploaded', '480 MB', AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _usageTile(String label, String value, int color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: hex(color).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(color),
                    weight: FontWeight.w700,
                    size: 14)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
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
                'Monitor network bandwidth usage across devices. See download and upload speeds, per-device breakdown, and daily usage stats. All measurements stay on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
