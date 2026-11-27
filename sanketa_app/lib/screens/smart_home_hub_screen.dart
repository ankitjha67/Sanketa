import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class SmartHomeHubScreen extends StatefulWidget {
  const SmartHomeHubScreen({super.key});

  @override
  State<SmartHomeHubScreen> createState() => _SmartHomeHubScreenState();
}

class _SmartHomeHubScreenState extends State<SmartHomeHubScreen> {
  bool _loading = true;

  static final _devices = <_SmartDevice>[
    _SmartDevice(name: 'Living Room Light', icon: Icons.lightbulb, type: 'Light', on: true, color: AppColors.alertAmber),
    _SmartDevice(name: 'TV Backlight', icon: Icons.light, type: 'Light', on: false, color: AppColors.secondary),
    _SmartDevice(name: 'Ceiling Fan', icon: Icons.air, type: 'Fan', on: false, color: AppColors.primary),
    _SmartDevice(name: 'AC', icon: Icons.ac_unit, type: 'Climate', on: true, color: AppColors.signalEmerald),
    _SmartDevice(name: 'Smart Plug', icon: Icons.power, type: 'Plug', on: false, color: AppColors.error),
    _SmartDevice(name: 'Bedroom Light', icon: Icons.lightbulb_outline, type: 'Light', on: false, color: AppColors.tertiary),
    _SmartDevice(name: 'Heater', icon: Icons.thermostat, type: 'Climate', on: false, color: AppColors.alertAmber),
    _SmartDevice(name: 'Desk Lamp', icon: Icons.table_bar, type: 'Light', on: true, color: AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/smart_home_hub.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        for (var i = 0; i < data.length && i < _devices.length; i++) {
          _devices[i].on = data[i] as bool? ?? false;
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_devices.map((d) => d.on).toList()));
  }

  void _toggle(int i) {
    HapticFeedback.lightImpact();
    setState(() => _devices[i].on = !_devices[i].on);
    _save();
  }

  int get _onCount => _devices.where((d) => d.on).length;

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
        title: Text('Smart Home Hub',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _deviceGrid(),
          const SizedBox(height: AppSpacing.md),
          _quickScenes(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statsRow() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('$_onCount', 'Active'),
            _stat('${_devices.length - _onCount}', 'Off'),
            _stat('${_devices.length}', 'Total'),
          ],
        ),
      );

  Widget _stat(String val, String label) => Column(
        children: [
          Text(val,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.primary),
                  weight: FontWeight.w700,
                  size: 16)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _deviceGrid() => GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _devices.asMap().entries.map((e) {
          final d = e.value;
          return GestureDetector(
            onTap: () => _toggle(e.key),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hex(d.on ? d.color : AppColors.surfaceContainerLow)
                    .withValues(alpha: d.on ? 0.1 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(d.on ? d.color : AppColors.outlineVariant)
                      .withValues(alpha: d.on ? 0.4 : 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(d.icon,
                          size: 24,
                          color: hex(d.on ? d.color : AppColors.outline)),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: hex(d.on
                              ? AppColors.signalEmerald
                              : AppColors.outlineVariant),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 11)),
                      Text(d.on ? 'On' : 'Off',
                          style: gfont(AppType.bodySm,
                              color: hex(d.on ? d.color : AppColors.outline),
                              size: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _quickScenes() => Container(
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
            Text('Quick Scenes',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _sceneChip('All Off', Icons.power_settings_new, () {
                  for (final d in _devices) {
                    d.on = false;
                  }
                  setState(() {});
                  _save();
                }),
                _sceneChip('Movie Night', Icons.movie, () {
                  for (final d in _devices) {
                    d.on = d.name.contains('Backlight') || d.name == 'AC';
                  }
                  setState(() {});
                  _save();
                }),
                _sceneChip('All On', Icons.wb_sunny, () {
                  for (final d in _devices) {
                    d.on = true;
                  }
                  setState(() {});
                  _save();
                }),
                _sceneChip('Lights Only', Icons.lightbulb, () {
                  for (final d in _devices) {
                    d.on = d.type == 'Light';
                  }
                  setState(() {});
                  _save();
                }),
              ],
            ),
          ],
        ),
      );

  Widget _sceneChip(String label, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: hex(AppColors.primary)),
              const SizedBox(width: 6),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w500,
                      size: 10)),
            ],
          ),
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
                'Control smart home devices alongside your TV. Toggle lights, fans, and plugs. Use quick scenes for one-tap automation. All commands stay on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _SmartDevice {
  String name;
  IconData icon;
  String type;
  bool on;
  int color;

  _SmartDevice({
    required this.name,
    required this.icon,
    required this.type,
    required this.on,
    required this.color,
  });
}
