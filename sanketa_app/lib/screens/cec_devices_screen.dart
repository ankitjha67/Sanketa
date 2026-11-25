import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class CecDevice {
  CecDevice({
    required this.name,
    required this.type,
    required this.address,
    this.vendor = 'Unknown',
    this.active = false,
  });

  final String name;
  final String type;
  final String address;
  final String vendor;
  bool active;

  IconData get icon {
    switch (type) {
      case 'tv': return Icons.tv;
      case 'player': return Icons.play_circle;
      case 'recorder': return Icons.fiber_dvr;
      case 'tuner': return Icons.settings_input_antenna;
      case 'audio': return Icons.speaker;
      case 'game': return Icons.sports_esports;
      default: return Icons.devices_other;
    }
  }
}

class CecDevicesScreen extends StatefulWidget {
  const CecDevicesScreen({super.key});

  @override
  State<CecDevicesScreen> createState() => _CecDevicesScreenState();
}

class _CecDevicesScreenState extends State<CecDevicesScreen> {
  List<CecDevice> _devices = [];
  bool _scanning = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  void _scanDevices() {
    setState(() => _scanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _devices = [
          CecDevice(name: 'TV', type: 'tv', address: '0.0.0.0', vendor: 'Samsung', active: true),
          CecDevice(name: 'Playback 1', type: 'player', address: '4.0.0.0', vendor: 'Sony'),
          CecDevice(name: 'Audio System', type: 'audio', address: '5.0.0.0', vendor: 'Sonos'),
        ];
        _scanning = false;
        _loaded = true;
      });
    });
  }

  void _sendCecCommand(CecDevice device, String command) {
    final c = RemoteScope.of(context);
    switch (command) {
      case 'powerOn':
        c.key(core.Key.power);
      case 'standby':
        c.key(core.Key.power);
      case 'activeSource':
        c.key(core.Key.input);
      case 'volumeUp':
        c.key(core.Key.volumeUp);
      case 'volumeDown':
        c.key(core.Key.volumeDown);
      case 'mute':
        c.key(core.Key.mute);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Sent $command to ${device.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('CEC Devices',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.primaryContainer)),
            onPressed: _scanning ? null : _scanDevices,
          ),
        ],
      ),
      body: _scanning
          ? _scanningState()
          : !_loaded || _devices.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _devices.length + 2,
                  itemBuilder: (ctx, i) {
                    if (i == 0) return _cecHeader();
                    if (i == _devices.length + 1) return _infoCard();
                    return _deviceTile(_devices[i - 1]);
                  },
                ),
    );
  }

  Widget _scanningState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: hex(AppColors.primary)),
        const SizedBox(height: AppSpacing.lg),
        Text('Scanning CEC bus...',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Text('Discovering HDMI-CEC devices',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
      ],
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_input_hdmi, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No CEC devices found',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Make sure HDMI-CEC is enabled on your TV and connected devices.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _scanDevices,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Scan Again',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _cecHeader() => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('${_devices.length} devices on CEC bus',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.signalEmerald), size: 10)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _deviceTile(CecDevice device) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(
        fill: device.active ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
        radius: AppRadii.md,
        borderOpacity: device.active ? 0.3 : 0.15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hex(device.active ? AppColors.primaryContainer : AppColors.outlineVariant)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(device.icon, size: 20,
                    color: hex(device.active ? AppColors.primary : AppColors.outline)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(device.name,
                            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                        if (device.active) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text('ACTIVE',
                                style: gfont(AppType.labelMonoSm,
                                    color: hex(AppColors.signalEmerald), size: 8)),
                          ),
                        ],
                      ],
                    ),
                    Text('${device.vendor} · ${device.type} · ${device.address}',
                        style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _cecButton('Power On', () => _sendCecCommand(device, 'powerOn')),
              _cecButton('Standby', () => _sendCecCommand(device, 'standby')),
              if (device.type == 'player' || device.type == 'game')
                _cecButton('Activate', () => _sendCecCommand(device, 'activeSource')),
              if (device.type == 'audio') ...[
                _cecButton('Vol +', () => _sendCecCommand(device, 'volumeUp')),
                _cecButton('Vol -', () => _sendCecCommand(device, 'volumeDown')),
                _cecButton('Mute', () => _sendCecCommand(device, 'mute')),
              ],
            ],
          ),
        ],
      ),
    ),
  );

  Widget _cecButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 11)),
    ),
  );

  Widget _infoCard() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
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
              'HDMI-CEC lets you control all connected devices from one remote. Enable CEC in your TV settings (called Anynet+, Bravia Sync, SimpLink, etc.).',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
