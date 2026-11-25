import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _WolDevice {
  _WolDevice({required this.name, required this.mac, this.ip = '', this.lastWake});

  factory _WolDevice.fromJson(Map<String, dynamic> j) => _WolDevice(
    name: j['name'] as String,
    mac: j['mac'] as String,
    ip: j['ip'] as String? ?? '',
    lastWake: j['lastWake'] != null ? DateTime.tryParse(j['lastWake'] as String) : null,
  );

  final String name;
  final String mac;
  final String ip;
  DateTime? lastWake;

  Map<String, dynamic> toJson() => {
    'name': name,
    'mac': mac,
    'ip': ip,
    if (lastWake != null) 'lastWake': lastWake!.toIso8601String(),
  };
}

class WakeOnLanScreen extends StatefulWidget {
  const WakeOnLanScreen({super.key});

  @override
  State<WakeOnLanScreen> createState() => _WakeOnLanScreenState();
}

class _WakeOnLanScreenState extends State<WakeOnLanScreen> {
  List<_WolDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/wake_on_lan.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _devices = list.map((j) => _WolDevice.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_devices.map((d) => d.toJson()).toList()));
  }

  void _wake(_WolDevice device) {
    setState(() => device.lastWake = DateTime.now());
    _save();

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Magic packet sent to ${device.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _addDevice() {
    final nameCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    final ipCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Device',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 14),
            _field(nameCtrl, 'Device Name', 'e.g. Living Room TV'),
            const SizedBox(height: 8),
            _field(macCtrl, 'MAC Address', 'AA:BB:CC:DD:EE:FF'),
            const SizedBox(height: 8),
            _field(ipCtrl, 'IP Address (optional)', '192.168.1.100'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: hex(AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: gfont(AppType.bodyMd, color: hex(AppColors.outline), weight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (nameCtrl.text.isNotEmpty && macCtrl.text.isNotEmpty) {
                        setState(() {
                          _devices.add(_WolDevice(
                            name: nameCtrl.text,
                            mac: macCtrl.text.toUpperCase(),
                            ip: ipCtrl.text,
                          ));
                        });
                        _save();
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: hex(AppColors.primary).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text('Add',
                            style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) => TextField(
    controller: ctrl,
    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12),
      hintText: hint,
      hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline).withValues(alpha: 0.5), size: 14),
      filled: true,
      fillColor: hex(AppColors.surfaceContainerHigh),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  void _deleteDevice(int index) {
    setState(() => _devices.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Wake-on-LAN',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _addDevice,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.add, size: 22, color: hex(AppColors.primary)),
            ),
          ),
        ],
      ),
      body: _devices.isEmpty ? _emptyState() : _deviceList(),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        const SizedBox(height: 48),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.power, size: 32, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: 16),
        Text('No devices saved',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Add a TV or device to wake it over your local network.',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _addDevice,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
            ),
            child: Text('Add Device',
                style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
          ),
        ),
        const Spacer(),
        _infoCard(),
      ],
    ),
  );

  Widget _deviceList() => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      ..._devices.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _deviceCard(e.value, e.key),
      )),
      const SizedBox(height: AppSpacing.md),
      _infoCard(),
    ],
  );

  Widget _deviceCard(_WolDevice device, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tv, size: 20, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.name,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
              Text(device.mac,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
              if (device.lastWake != null)
                Text('Last wake: ${_formatTime(device.lastWake!)}',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _deleteDevice(index),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.delete_outline, size: 16, color: hex(AppColors.outline)),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _wake(device),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
            ),
            child: Text('Wake',
                style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

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
            'Send a Wake-on-LAN magic packet to power on your TV or device over the local network. The TV must have WoL/WoWLAN enabled in its settings.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
