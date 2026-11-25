import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenTimeoutScreen extends StatefulWidget {
  const ScreenTimeoutScreen({super.key});

  @override
  State<ScreenTimeoutScreen> createState() => _ScreenTimeoutScreenState();
}

class _ScreenTimeoutScreenState extends State<ScreenTimeoutScreen> {
  bool _screenSaverEnabled = true;
  int _screenSaverMinutes = 5;
  String _screenSaverType = 'Colour';
  bool _autoPowerOff = false;
  int _autoPowerMinutes = 240;
  bool _noSignalOff = true;
  int _noSignalMinutes = 15;
  bool _loading = true;

  static const _saverDelays = [1, 2, 3, 5, 10, 15, 30];
  static const _saverTypes = ['Colour', 'Slide Show', 'Clock', 'Blank', 'Art'];
  static const _powerDelays = [60, 120, 180, 240, 360, 480];
  static const _noSignalDelays = [5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/screen_timeout.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _screenSaverEnabled = j['screenSaverEnabled'] as bool? ?? true;
        _screenSaverMinutes = j['screenSaverMinutes'] as int? ?? 5;
        _screenSaverType = j['screenSaverType'] as String? ?? 'Colour';
        _autoPowerOff = j['autoPowerOff'] as bool? ?? false;
        _autoPowerMinutes = j['autoPowerMinutes'] as int? ?? 240;
        _noSignalOff = j['noSignalOff'] as bool? ?? true;
        _noSignalMinutes = j['noSignalMinutes'] as int? ?? 15;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'screenSaverEnabled': _screenSaverEnabled,
      'screenSaverMinutes': _screenSaverMinutes,
      'screenSaverType': _screenSaverType,
      'autoPowerOff': _autoPowerOff,
      'autoPowerMinutes': _autoPowerMinutes,
      'noSignalOff': _noSignalOff,
      'noSignalMinutes': _noSignalMinutes,
    }));
  }

  String _formatMinutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h hr' : '$h hr $r min';
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
        title: Text('Screen & Power',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _screenSaverSection(),
          const SizedBox(height: AppSpacing.lg),
          _autoPowerSection(),
          const SizedBox(height: AppSpacing.lg),
          _noSignalSection(),
          const SizedBox(height: AppSpacing.lg),
          _openTvSettings(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _screenSaverSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toggleHeader(Icons.wallpaper, 'Screen Saver', _screenSaverEnabled, (v) {
          setState(() => _screenSaverEnabled = v);
          _save();
        }),
        if (_screenSaverEnabled) ...[
          const SizedBox(height: 12),
          Text('Activate after',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _saverDelays.map((d) => _chip(
              _formatMinutes(d),
              _screenSaverMinutes == d,
              () { setState(() => _screenSaverMinutes = d); _save(); },
            )).toList(),
          ),
          const SizedBox(height: 12),
          Text('Type',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _saverTypes.map((t) => _chip(
              t,
              _screenSaverType == t,
              () { setState(() => _screenSaverType = t); _save(); },
            )).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _autoPowerSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toggleHeader(Icons.power_settings_new, 'Auto Power Off', _autoPowerOff, (v) {
          setState(() => _autoPowerOff = v);
          _save();
        }),
        if (_autoPowerOff) ...[
          const SizedBox(height: 12),
          Text('Turn off after inactivity',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _powerDelays.map((d) => _chip(
              _formatMinutes(d),
              _autoPowerMinutes == d,
              () { setState(() => _autoPowerMinutes = d); _save(); },
            )).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _noSignalSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toggleHeader(Icons.signal_cellular_off, 'No Signal Auto-Off', _noSignalOff, (v) {
          setState(() => _noSignalOff = v);
          _save();
        }),
        if (_noSignalOff) ...[
          const SizedBox(height: 12),
          Text('Turn off after no signal',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _noSignalDelays.map((d) => _chip(
              _formatMinutes(d),
              _noSignalMinutes == d,
              () { setState(() => _noSignalMinutes = d); _save(); },
            )).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _toggleHeader(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            ),
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: hex(value ? AppColors.primary : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hex(value ? AppColors.onPrimary : AppColors.outline),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _chip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
            .withValues(alpha: active ? 0.25 : 1),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: hex(active ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: active ? 0.6 : 0.2),
        ),
      ),
      child: Text(label,
          style: gfont(AppType.bodySm,
              color: hex(active ? AppColors.primary : AppColors.onSurface),
              weight: active ? FontWeight.w600 : FontWeight.w400,
              size: 11)),
    ),
  );

  Widget _openTvSettings() => GestureDetector(
    onTap: () => RemoteScope.of(context).key(core.Key.menu),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 16, color: hex(AppColors.onSurface)),
          const SizedBox(width: 8),
          Text('Open TV Screen Settings',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
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
            'Configure screen saver, auto power-off, and no-signal behaviour. These are reference settings — use "Open TV Screen Settings" to apply changes on the TV itself.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
