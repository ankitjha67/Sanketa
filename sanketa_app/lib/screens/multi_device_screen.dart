import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Device {
  _Device({
    required this.name,
    required this.type,
    required this.ip,
    required this.icon,
    this.online = false,
    this.active = false,
  });

  final String name;
  final String type;
  final String ip;
  final IconData icon;
  bool online;
  bool active;
}

class MultiDeviceScreen extends StatefulWidget {
  const MultiDeviceScreen({super.key});

  @override
  State<MultiDeviceScreen> createState() => _MultiDeviceScreenState();
}

class _MultiDeviceScreenState extends State<MultiDeviceScreen> {
  bool _broadcast = false;

  final _devices = [
    _Device(name: 'Living Room TV', type: 'Samsung QN85B', ip: '192.168.1.42', icon: Icons.tv, online: true, active: true),
    _Device(name: 'Bedroom TV', type: 'TCL Roku 55"', ip: '192.168.1.78', icon: Icons.tv, online: true),
    _Device(name: 'Office Shield', type: 'NVIDIA Shield TV', ip: '192.168.1.103', icon: Icons.gamepad, online: true),
    _Device(name: 'Kitchen Display', type: 'Google Nest Hub', ip: '192.168.1.55', icon: Icons.tablet, online: false),
    _Device(name: 'Projector', type: 'Epson LS800', ip: '192.168.1.90', icon: Icons.videocam),
  ];

  int get _onlineCount => _devices.where((d) => d.online).length;
  int get _selectedCount => _devices.where((d) => d.active).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Multi-Device',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _summaryCard(),
          const SizedBox(height: AppSpacing.md),
          _broadcastToggle(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Devices ($_onlineCount online)',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text('Scan',
                    style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600, size: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._devices.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _deviceCard(e.value, e.key),
          )),
          const SizedBox(height: AppSpacing.md),
          _syncActions(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(Icons.devices, size: 24, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_selectedCount of ${_devices.length} Devices Selected',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text(_broadcast
                  ? 'Commands sent to all selected devices'
                  : 'Tap a device to control it individually',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _broadcastToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(_broadcast ? AppColors.alertAmber : AppColors.surfaceContainerLow).withValues(alpha: _broadcast ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(_broadcast ? AppColors.alertAmber : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.broadcast_on_personal, size: 20, color: hex(_broadcast ? AppColors.alertAmber : AppColors.outline)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Broadcast Mode',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Send every command to all selected devices at once',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        Switch(
          value: _broadcast,
          activeTrackColor: hex(AppColors.alertAmber),
          onChanged: (v) => setState(() => _broadcast = v),
        ),
      ],
    ),
  );

  Widget _deviceCard(_Device d, int index) => GestureDetector(
    onTap: d.online ? () => setState(() => d.active = !d.active) : null,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(d.active ? AppColors.primary : AppColors.surfaceContainerLow)
            .withValues(alpha: d.active ? 0.06 : 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(d.active ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: d.active ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(d.online ? AppColors.primary : AppColors.outline).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(d.icon, size: 20,
                color: hex(d.online ? AppColors.primary : AppColors.outline)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
                Row(
                  children: [
                    Text(d.type,
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                    const SizedBox(width: 6),
                    Text(d.ip,
                        style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hex(d.online ? AppColors.signalEmerald : AppColors.outline)
                  .withValues(alpha: d.online ? 1 : 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          if (d.online)
            Icon(
              d.active ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: hex(d.active ? AppColors.primary : AppColors.outline),
            ),
        ],
      ),
    ),
  );

  Widget _syncActions() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sync Actions',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _syncRow(Icons.volume_up, 'Sync Volume', 'Set same volume on all selected TVs'),
        const SizedBox(height: 4),
        _syncRow(Icons.play_arrow, 'Sync Playback', 'Play/pause all selected TVs together'),
        const SizedBox(height: 4),
        _syncRow(Icons.power_settings_new, 'All Power Off', 'Turn off all selected devices'),
      ],
    ),
  );

  Widget _syncRow(IconData icon, String title, String subtitle) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppRadii.sm),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: hex(AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 11)),
              Text(subtitle,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, size: 16, color: hex(AppColors.outline)),
      ],
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
            'Control multiple TVs and devices simultaneously. Enable broadcast mode to send commands to all selected devices at once. All communication stays on your local network.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
