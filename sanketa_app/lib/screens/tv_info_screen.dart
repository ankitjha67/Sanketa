import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class TvInfoScreen extends StatefulWidget {
  const TvInfoScreen({super.key});

  @override
  State<TvInfoScreen> createState() => _TvInfoScreenState();
}

class _TvInfoScreenState extends State<TvInfoScreen>
    with SingleTickerProviderStateMixin {
  bool _refreshing = false;
  late AnimationController _spinCtrl;

  static const _infoSections = [
    (
      'Device',
      [
        ('Model', 'Samsung QN90C 65"', Icons.tv),
        ('Manufacturer', 'Samsung Electronics', Icons.business),
        ('Serial Number', 'SN-4829-KX-7731', Icons.tag),
        ('Year', '2024', Icons.calendar_today),
      ],
    ),
    (
      'Software',
      [
        ('Firmware', 'v3.2.1 (Build 2847)', Icons.system_update),
        ('OS', 'Tizen 7.0', Icons.computer),
        ('Last Update', '2024-11-15', Icons.update),
        ('Security Patch', 'Nov 2024', Icons.security),
      ],
    ),
    (
      'Display',
      [
        ('Resolution', '3840 x 2160 (4K UHD)', Icons.aspect_ratio),
        ('Panel Type', 'Neo QLED', Icons.gradient),
        ('Refresh Rate', '120 Hz', Icons.speed),
        ('HDR Support', 'HDR10+, Dolby Vision', Icons.hdr_on),
      ],
    ),
    (
      'Storage',
      [
        ('Total', '8 GB', Icons.storage),
        ('Used', '5.2 GB (65%)', Icons.pie_chart),
        ('Available', '2.8 GB', Icons.sd_storage),
        ('Cache', '412 MB', Icons.cached),
      ],
    ),
    (
      'Network',
      [
        ('Connection', 'Wi-Fi 6 (802.11ax)', Icons.wifi),
        ('IP Address', '192.168.1.42', Icons.language),
        ('MAC Address', 'A4:7E:33:8B:1C:F2', Icons.router),
        ('Signal', 'Excellent (-38 dBm)', Icons.signal_wifi_4_bar),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _spinCtrl.repeat();
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _spinCtrl.stop();
        setState(() => _refreshing = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('System info refreshed'),
            duration: Duration(seconds: 2),
          ));
      }
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
        title: Text('TV Info',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          RotationTransition(
            turns: _spinCtrl,
            child: IconButton(
              icon: Icon(Icons.refresh,
                  color: _refreshing
                      ? hex(AppColors.primary)
                      : hex(AppColors.outline),
                  size: 22),
              onPressed: _refresh,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _quickStats(),
          const SizedBox(height: AppSpacing.lg),
          ..._infoSections.expand((section) => [
                _sectionHeader(section.$1),
                const SizedBox(height: AppSpacing.sm),
                ...section.$2.map((item) => _infoRow(item)),
                const SizedBox(height: AppSpacing.md),
              ]),
          _disclaimerCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline,
                size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('System Information',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'View your TV model, firmware, display, storage, and network details',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _quickStats() => Row(
        children: [
          Expanded(child: _statChip('4K UHD', 'Resolution', AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('v3.2.1', 'Firmware', AppColors.signalEmerald)),
          const SizedBox(width: 8),
          Expanded(child: _statChip('2.8 GB', 'Free Space', AppColors.alertAmber)),
        ],
      );

  Widget _statChip(String value, String label, int color) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(color),
                    weight: FontWeight.w700,
                    size: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _sectionHeader(String title) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: hex(AppColors.alertAmber),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
        ],
      );

  Widget _infoRow((String, String, IconData) item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
                color:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(item.$3,
                  size: 18,
                  color: hex(AppColors.outline).withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.$1,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11)),
              ),
              Flexible(
                child: Text(item.$2,
                    textAlign: TextAlign.end,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _disclaimerCard() => Container(
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
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: hex(AppColors.outline)),
                const SizedBox(width: 6),
                Text('Note',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Some information may differ from actual TV values. '
              'Use the refresh button to fetch the latest data from your TV.',
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );
}
