import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _QuickToggle {
  _QuickToggle({
    required this.icon,
    required this.label,
    this.enabled = false,
  });

  final IconData icon;
  final String label;
  bool enabled;
}

class QuickSettingsScreen extends StatefulWidget {
  const QuickSettingsScreen({super.key});

  @override
  State<QuickSettingsScreen> createState() => _QuickSettingsScreenState();
}

class _QuickSettingsScreenState extends State<QuickSettingsScreen> {
  final _toggles = [
    _QuickToggle(icon: Icons.wifi, label: 'WiFi', enabled: true),
    _QuickToggle(icon: Icons.bluetooth, label: 'Bluetooth', enabled: true),
    _QuickToggle(icon: Icons.cast, label: 'Cast', enabled: true),
    _QuickToggle(icon: Icons.hdr_on, label: 'HDR', enabled: false),
    _QuickToggle(icon: Icons.nightlight, label: 'Night Mode'),
    _QuickToggle(icon: Icons.hearing, label: 'Audio Desc'),
    _QuickToggle(icon: Icons.closed_caption, label: 'Subtitles', enabled: true),
    _QuickToggle(icon: Icons.screen_rotation, label: 'Auto Rotate'),
    _QuickToggle(icon: Icons.usb, label: 'USB Debug'),
    _QuickToggle(icon: Icons.developer_mode, label: 'Dev Options'),
    _QuickToggle(icon: Icons.location_off, label: 'Location'),
    _QuickToggle(icon: Icons.do_not_disturb, label: 'DND'),
  ];

  int _brightnessPercent = 70;
  int _volumePercent = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Settings',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _sliderRow(Icons.brightness_6, 'Brightness', _brightnessPercent, AppColors.alertAmber,
              (v) => setState(() => _brightnessPercent = v)),
          const SizedBox(height: 10),
          _sliderRow(Icons.volume_up, 'Volume', _volumePercent, AppColors.primary,
              (v) => setState(() => _volumePercent = v)),
          const SizedBox(height: AppSpacing.md),
          _toggleGrid(),
          const SizedBox(height: AppSpacing.md),
          _quickActions(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _sliderRow(IconData icon, String label, int value, int color, void Function(int) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: hex(color)),
        const SizedBox(width: 10),
        Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 12)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: hex(color),
              inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              thumbColor: hex(color),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text('$value%',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10),
              textAlign: TextAlign.right),
        ),
      ],
    ),
  );

  Widget _toggleGrid() => GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 0.9,
    children: _toggles.map((t) => _toggleTile(t)).toList(),
  );

  Widget _toggleTile(_QuickToggle t) => GestureDetector(
    onTap: () => setState(() => t.enabled = !t.enabled),
    child: Container(
      decoration: BoxDecoration(
        color: hex(t.enabled ? AppColors.primary : AppColors.surfaceContainerLow)
            .withValues(alpha: t.enabled ? 0.12 : 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(t.enabled ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: t.enabled ? 0.4 : 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(t.icon, size: 22,
              color: hex(t.enabled ? AppColors.primary : AppColors.outline)),
          const SizedBox(height: 4),
          Text(t.label,
              textAlign: TextAlign.center,
              style: gfont(AppType.labelMonoSm,
                  color: hex(t.enabled ? AppColors.primary : AppColors.outline),
                  size: 9, weight: t.enabled ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    ),
  );

  Widget _quickActions() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _actionRow(Icons.power_settings_new, 'Restart TV', AppColors.error),
        const SizedBox(height: 6),
        _actionRow(Icons.system_update, 'Check for Updates', AppColors.signalEmerald),
        const SizedBox(height: 6),
        _actionRow(Icons.cleaning_services, 'Clear Cache', AppColors.alertAmber),
        const SizedBox(height: 6),
        _actionRow(Icons.settings_backup_restore, 'Factory Reset', AppColors.error),
      ],
    ),
  );

  Widget _actionRow(IconData icon, String label, int color) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: hex(color)),
          const SizedBox(width: 10),
          Text(label,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 12)),
          const Spacer(),
          Icon(Icons.chevron_right, size: 16, color: hex(AppColors.outline)),
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
            'Control panel for your TV system settings. Toggle features, adjust brightness and volume, and perform quick actions — all from your phone.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
