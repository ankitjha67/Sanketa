import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class CinemaModeScreen extends StatefulWidget {
  const CinemaModeScreen({super.key});

  @override
  State<CinemaModeScreen> createState() => _CinemaModeScreenState();
}

class _CinemaModeScreenState extends State<CinemaModeScreen> {
  bool _loading = true;
  bool _active = false;
  int _preset = 0;

  static const _presets = <(String, IconData, String, int)>[
    ('Movie Night', Icons.movie, 'Dim lights, warm tones, surround on', AppColors.primary),
    ('Sports Bar', Icons.sports_soccer, 'Vivid colours, speech boost', AppColors.signalEmerald),
    ('Concert', Icons.music_note, 'Deep bass, full range, ambient off', AppColors.secondary),
    ('Documentary', Icons.auto_stories, 'Natural tones, dialogue clarity', AppColors.tertiary),
    ('Gaming', Icons.sports_esports, 'Low latency, vivid, game EQ', AppColors.alertAmber),
    ('Night Owl', Icons.nightlight, 'Blue filter, low brightness, quiet', AppColors.error),
  ];

  int _brightness = 40;
  int _colorTemp = 65;
  bool _surroundOn = true;
  bool _dimLights = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cinema_mode.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final d = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _preset = d['preset'] as int? ?? 0;
        _brightness = d['brightness'] as int? ?? 40;
        _colorTemp = d['colorTemp'] as int? ?? 65;
        _surroundOn = d['surround'] as bool? ?? true;
        _dimLights = d['dimLights'] as bool? ?? true;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'preset': _preset,
      'brightness': _brightness,
      'colorTemp': _colorTemp,
      'surround': _surroundOn,
      'dimLights': _dimLights,
    }));
  }

  void _activate() {
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _active = !_active);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_active ? 'Cinema Mode ON' : 'Cinema Mode OFF'),
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

    final p = _presets[_preset];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Cinema Mode',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(p),
          const SizedBox(height: AppSpacing.md),
          _presetGrid(),
          const SizedBox(height: AppSpacing.md),
          _settingsSection(),
          const SizedBox(height: AppSpacing.md),
          _activateButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, IconData, String, int) p) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(p.$4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(p.$4).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(p.$2, size: 44, color: hex(p.$4)),
            const SizedBox(height: 8),
            Text(p.$1,
                style: gfont(AppType.bodyMd,
                    color: hex(p.$4), weight: FontWeight.w700, size: 16)),
            const SizedBox(height: 4),
            Text(p.$3,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            if (_active)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('ACTIVE',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.signalEmerald),
                          weight: FontWeight.w700,
                          size: 9)),
                ),
              ),
          ],
        ),
      );

  Widget _presetGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.3,
        children: _presets.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _preset;
          return GestureDetector(
            onTap: () {
              setState(() => _preset = e.key);
              _save();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hex(active ? p.$4 : AppColors.surfaceContainerHigh)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: hex(active ? p.$4 : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.4 : 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(p.$2,
                      size: 18, color: hex(active ? p.$4 : AppColors.outline)),
                  const SizedBox(height: 4),
                  Text(p.$1,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? p.$4 : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 8)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _settingsSection() => Container(
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
            Text('Settings',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            _sliderRow('Brightness', Icons.brightness_6, _brightness, (v) {
              setState(() => _brightness = v);
              _save();
            }),
            _sliderRow('Color Temp', Icons.thermostat, _colorTemp, (v) {
              setState(() => _colorTemp = v);
              _save();
            }),
            _toggleRow('Surround Sound', Icons.surround_sound, _surroundOn, (v) {
              setState(() => _surroundOn = v);
              _save();
            }),
            _toggleRow('Dim Smart Lights', Icons.lightbulb, _dimLights, (v) {
              setState(() => _dimLights = v);
              _save();
            }),
          ],
        ),
      );

  Widget _sliderRow(String label, IconData icon, int value, ValueChanged<int> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 10)),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: hex(AppColors.primary),
                inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 30,
              child: Text('$value%',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600,
                      size: 10)),
            ),
          ],
        ),
      );

  Widget _toggleRow(String label, IconData icon, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              Icon(icon, size: 16, color: hex(AppColors.outline)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 11)),
              ),
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(value ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: value ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(value ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _activateButton() => GestureDetector(
        onTap: _activate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_active ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_active ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_active ? Icons.stop : Icons.play_arrow,
                  size: 20,
                  color: hex(_active ? AppColors.error : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_active ? 'Deactivate Cinema Mode' : 'Activate Cinema Mode',
                  style: gfont(AppType.bodyMd,
                      color: hex(_active ? AppColors.error : AppColors.primary),
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
                'Transform your living room into a cinema. Pick a preset, fine-tune brightness and color, enable surround sound, and dim smart lights — all in one tap. Settings stay on your device.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
