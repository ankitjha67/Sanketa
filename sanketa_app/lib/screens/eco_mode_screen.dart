import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class EcoModeScreen extends StatefulWidget {
  const EcoModeScreen({super.key});

  @override
  State<EcoModeScreen> createState() => _EcoModeScreenState();
}

class _EcoModeScreenState extends State<EcoModeScreen> {
  bool _loading = true;
  bool _ecoEnabled = false;
  double _brightness = 0.4;
  bool _autoOff = true;
  int _autoOffMinutes = 120;
  bool _ledOff = true;
  bool _wifiPowerSave = false;
  bool _applied = false;

  static const _autoOffOptions = [30, 60, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/eco_mode.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _ecoEnabled = j['ecoEnabled'] as bool? ?? false;
        _brightness = (j['brightness'] as num?)?.toDouble() ?? 0.4;
        _autoOff = j['autoOff'] as bool? ?? true;
        _autoOffMinutes = j['autoOffMinutes'] as int? ?? 120;
        _ledOff = j['ledOff'] as bool? ?? true;
        _wifiPowerSave = j['wifiPowerSave'] as bool? ?? false;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'ecoEnabled': _ecoEnabled,
      'brightness': _brightness,
      'autoOff': _autoOff,
      'autoOffMinutes': _autoOffMinutes,
      'ledOff': _ledOff,
      'wifiPowerSave': _wifiPowerSave,
    }));
  }

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Eco mode settings applied'),
        duration: Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  String _formatMinutes(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }

  int _estimatedSavings() {
    var pct = 0;
    if (_ecoEnabled) {
      pct += ((1.0 - _brightness) * 20).round();
      if (_autoOff) pct += 10;
      if (_ledOff) pct += 5;
      if (_wifiPowerSave) pct += 5;
    }
    return pct.clamp(0, 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Eco Mode',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.lg),
                _masterToggle(),
                const SizedBox(height: AppSpacing.lg),
                _savingsCard(),
                const SizedBox(height: AppSpacing.lg),
                _brightnessControl(),
                const SizedBox(height: AppSpacing.md),
                _toggleRow('Auto Power Off', 'Turn off TV after inactivity',
                    Icons.timer, _autoOff, (v) {
                  setState(() => _autoOff = v);
                  _save();
                }),
                if (_autoOff) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _autoOffSelector(),
                ],
                const SizedBox(height: AppSpacing.sm),
                _toggleRow('LED Off', 'Disable standby LED indicator',
                    Icons.light_mode, _ledOff, (v) {
                  setState(() => _ledOff = v);
                  _save();
                }),
                const SizedBox(height: AppSpacing.sm),
                _toggleRow('Wi-Fi Power Save', 'Reduce Wi-Fi radio power',
                    Icons.wifi, _wifiPowerSave, (v) {
                  setState(() => _wifiPowerSave = v);
                  _save();
                }),
                const SizedBox(height: AppSpacing.lg),
                _applyButton(),
                const SizedBox(height: AppSpacing.lg),
                _infoCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.eco, size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Energy Saver',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Reduce your TV\'s energy consumption',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => GestureDetector(
        onTap: () {
          setState(() => _ecoEnabled = !_ecoEnabled);
          HapticFeedback.mediumImpact();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_ecoEnabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _ecoEnabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_ecoEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _ecoEnabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.power_settings_new,
                  size: 24,
                  color: hex(_ecoEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco Mode',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                        _ecoEnabled
                            ? 'Active — saving energy'
                            : 'Off — normal power usage',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(_ecoEnabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_ecoEnabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_ecoEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _savingsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('~${_estimatedSavings()}%',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.signalEmerald),
                          size: 28,
                          weight: FontWeight.w700)),
                  Text('Est. savings',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    _ecoEnabled ? Icons.bolt : Icons.bolt_outlined,
                    size: 28,
                    color: hex(_ecoEnabled
                        ? AppColors.signalEmerald
                        : AppColors.outline),
                  ),
                  Text(_ecoEnabled ? 'Saving' : 'Normal',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _brightnessControl() => Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Max Brightness',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${(_brightness * 100).round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _brightness,
              min: 0.1,
              max: 1,
              divisions: 18,
              activeColor: hex(AppColors.signalEmerald),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _brightness = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _toggleRow(String title, String subtitle, IconData icon, bool value,
          ValueChanged<bool> onChanged) =>
      GestureDetector(
        onTap: () {
          onChanged(!value);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: hex(
                      value ? AppColors.signalEmerald : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text(subtitle,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(value
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(value ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(value
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _autoOffSelector() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: _autoOffOptions.map((m) {
            final active = m == _autoOffMinutes;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _autoOffMinutes = m);
                  HapticFeedback.selectionClick();
                  _save();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.signalEmerald
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.signalEmerald
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Text(_formatMinutes(m),
                      style: gfont(AppType.bodySm,
                          color: hex(active
                              ? AppColors.signalEmerald
                              : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_applied ? AppColors.signalEmerald : AppColors.primary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_applied ? AppColors.signalEmerald : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_applied ? Icons.check : Icons.check_circle,
                  size: 20,
                  color: hex(
                      _applied ? AppColors.signalEmerald : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_applied ? 'Applied!' : 'Apply Eco Settings',
                  style: gfont(AppType.bodyMd,
                      color: hex(_applied
                          ? AppColors.signalEmerald
                          : AppColors.primary),
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
                'Eco Mode reduces energy usage by limiting brightness, '
                'disabling LEDs, and auto-powering off after inactivity. '
                'All settings are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
