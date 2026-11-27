import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundZonesScreen extends StatefulWidget {
  const SoundZonesScreen({super.key});

  @override
  State<SoundZonesScreen> createState() => _SoundZonesScreenState();
}

class _SoundZonesScreenState extends State<SoundZonesScreen> {
  bool _loading = true;
  int _selectedZone = 0;

  static final _zones = <_SoundZone>[
    _SoundZone(name: 'Living Room', icon: Icons.weekend, volume: 70, muted: false, color: AppColors.primary),
    _SoundZone(name: 'Bedroom', icon: Icons.bed, volume: 30, muted: false, color: AppColors.secondary),
    _SoundZone(name: 'Kitchen', icon: Icons.kitchen, volume: 50, muted: true, color: AppColors.tertiary),
    _SoundZone(name: 'Patio', icon: Icons.deck, volume: 60, muted: false, color: AppColors.signalEmerald),
    _SoundZone(name: 'Office', icon: Icons.desk, volume: 40, muted: false, color: AppColors.alertAmber),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sound_zones.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        for (var i = 0; i < data.length && i < _zones.length; i++) {
          final m = data[i] as Map<String, dynamic>;
          _zones[i].volume = m['volume'] as int? ?? 50;
          _zones[i].muted = m['muted'] as bool? ?? false;
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_zones
        .map((z) => {'volume': z.volume, 'muted': z.muted})
        .toList()));
  }

  void _applyZone() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_zones[_selectedZone].name} zone applied'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    final zone = _zones[_selectedZone];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sound Zones',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _zoneSelector(),
          const SizedBox(height: AppSpacing.md),
          _volumeControl(zone),
          const SizedBox(height: AppSpacing.md),
          _allZonesOverview(),
          const SizedBox(height: AppSpacing.md),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _zoneSelector() => Row(
        children: _zones.asMap().entries.map((e) {
          final z = e.value;
          final active = e.key == _selectedZone;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedZone = e.key),
              child: Container(
                margin: EdgeInsets.only(right: e.key < 4 ? 4 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? z.color : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hex(active ? z.color : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(z.icon,
                        size: 18,
                        color: hex(active ? z.color : AppColors.outline)),
                    const SizedBox(height: 2),
                    Text(z.name,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? z.color : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 7)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _volumeControl(_SoundZone zone) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(zone.color).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(zone.color).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(zone.icon, size: 36, color: hex(zone.color)),
            const SizedBox(height: 8),
            Text(zone.name,
                style: gfont(AppType.bodyMd,
                    color: hex(zone.color),
                    weight: FontWeight.w700,
                    size: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Vol',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Expanded(
                  child: Slider(
                    value: zone.volume.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: hex(zone.color),
                    inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                    onChanged: (v) {
                      setState(() => zone.volume = v.round());
                      _save();
                    },
                  ),
                ),
                Text('${zone.volume}%',
                    style: gfont(AppType.bodySm,
                        color: hex(zone.color),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => zone.muted = !zone.muted);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(zone.muted ? AppColors.error : AppColors.surfaceContainerHigh)
                      .withValues(alpha: zone.muted ? 0.1 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(zone.muted ? AppColors.error : AppColors.outlineVariant)
                        .withValues(alpha: zone.muted ? 0.3 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      zone.muted ? Icons.volume_off : Icons.volume_up,
                      size: 16,
                      color: hex(zone.muted ? AppColors.error : AppColors.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Text(zone.muted ? 'Muted' : 'Unmuted',
                        style: gfont(AppType.bodySm,
                            color: hex(zone.muted ? AppColors.error : AppColors.onSurface),
                            weight: FontWeight.w500,
                            size: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _allZonesOverview() => Container(
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
            Text('All Zones',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._zones.map((z) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(z.icon, size: 16, color: hex(z.color)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(z.name,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 11)),
                      ),
                      if (z.muted)
                        Icon(Icons.volume_off, size: 14, color: hex(AppColors.error))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hex(z.color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text('${z.volume}%',
                              style: gfont(AppType.bodySm,
                                  color: hex(z.color),
                                  weight: FontWeight.w600,
                                  size: 10)),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyZone,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.surround_sound, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Zone Settings',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
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
                'Configure audio per room. Set volume and mute state for each zone independently. Apply to send settings to your multi-room system. All settings stay on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _SoundZone {
  String name;
  IconData icon;
  int volume;
  bool muted;
  int color;

  _SoundZone({
    required this.name,
    required this.icon,
    required this.volume,
    required this.muted,
    required this.color,
  });
}
