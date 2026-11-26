import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  static const _sections = [
    (
      'TV Hardware',
      Icons.tv,
      [
        ('Model', 'Samsung QN85B 55"'),
        ('Manufacturer', 'Samsung Electronics'),
        ('Android Version', '12 (API 31)'),
        ('Build Number', 'TP1A.220624.014'),
        ('Kernel', '5.4.170-android12-0'),
        ('Architecture', 'ARM64 (aarch64)'),
        ('RAM', '3 GB'),
        ('Internal Storage', '16 GB (8.2 GB free)'),
        ('Display Resolution', '3840 x 2160 (4K UHD)'),
        ('HDR Support', 'Dolby Vision, HDR10+, HLG'),
      ],
    ),
    (
      'Network',
      Icons.wifi,
      [
        ('Connection', 'WiFi 802.11ac'),
        ('IP Address', '192.168.1.42'),
        ('MAC Address', 'AA:BB:CC:DD:EE:FF'),
        ('Signal Strength', '-42 dBm (Excellent)'),
        ('Frequency', '5 GHz'),
        ('Router', 'ASUS RT-AX86U'),
        ('DNS', '1.1.1.1, 1.0.0.1'),
        ('Gateway', '192.168.1.1'),
      ],
    ),
    (
      'Software',
      Icons.system_update,
      [
        ('TV OS', 'Tizen 7.0 / Android TV 12'),
        ('Security Patch', '2024-10-05'),
        ('Google Play Services', '24.42.14'),
        ('WebView Version', '120.0.6099.230'),
        ('Cast Version', '1.56.313396'),
        ('Last Updated', '2024-11-15'),
      ],
    ),
    (
      'Capabilities',
      Icons.settings_applications,
      [
        ('CEC', 'Supported (Anynet+)'),
        ('ARC / eARC', 'eARC Supported'),
        ('Bluetooth', '5.0 (LE Audio)'),
        ('USB Ports', '3 (2x USB 2.0, 1x USB 3.0)'),
        ('HDMI Ports', '4 (2x HDMI 2.1)'),
        ('Optical Out', 'Yes'),
        ('Voice Assistant', 'Bixby, Google Assistant'),
        ('ADB', 'Enabled'),
      ],
    ),
  ];

  void _copyAll(BuildContext context) {
    final buf = StringBuffer();
    for (final section in _sections) {
      buf.writeln('--- ${section.$1} ---');
      for (final row in section.$3) {
        buf.writeln('${row.$1}: ${row.$2}');
      }
      buf.writeln();
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Device info copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Device Info',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.copy, size: 20, color: hex(AppColors.primary)),
            onPressed: () => _copyAll(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(context),
          const SizedBox(height: AppSpacing.md),
          ..._sections.expand((s) => [
            _sectionHeader(s.$1, s.$2),
            const SizedBox(height: 6),
            ...s.$3.map((r) => _row(r.$1, r.$2, context)),
            const SizedBox(height: AppSpacing.md),
          ]),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Icon(Icons.tv, size: 28, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Samsung QN85B',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 14)),
              Text('Android TV 12 · 4K UHD · WiFi Connected',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Online',
                    style: gfont(AppType.labelMonoSm, color: hex(AppColors.signalEmerald), size: 9, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 16, color: hex(AppColors.primary)),
      const SizedBox(width: 8),
      Text(title,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
    ],
  );

  Widget _row(String label, String value, BuildContext context) => GestureDetector(
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Copied: $value')));
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ),
          Expanded(
            child: Text(value,
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 11, weight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Hardware and software details queried from your TV over the local network. Long-press any value to copy it.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
