import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class PicturePreset {
  PicturePreset({
    required this.name,
    required this.icon,
    this.brightness = 50,
    this.contrast = 50,
    this.color = 50,
    this.sharpness = 50,
    this.backlight = 70,
  });

  final String name;
  final IconData icon;
  int brightness;
  int contrast;
  int color;
  int sharpness;
  int backlight;

  Map<String, dynamic> toJson() => {
    'name': name,
    'brightness': brightness,
    'contrast': contrast,
    'color': color,
    'sharpness': sharpness,
    'backlight': backlight,
  };
}

class PictureSettingsScreen extends StatefulWidget {
  const PictureSettingsScreen({super.key});

  @override
  State<PictureSettingsScreen> createState() => _PictureSettingsScreenState();
}

class _PictureSettingsScreenState extends State<PictureSettingsScreen> {
  String _activeMode = 'Standard';
  int _brightness = 50;
  int _contrast = 50;
  int _color = 50;
  int _sharpness = 50;
  int _backlight = 70;
  bool _hdrMode = false;
  bool _eyeComfort = false;
  bool _loading = true;

  static const _modes = <(String, IconData)>[
    ('Vivid', Icons.wb_sunny),
    ('Standard', Icons.tune),
    ('Cinema', Icons.movie),
    ('Game', Icons.sports_esports),
    ('Sports', Icons.sports),
    ('Custom', Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/picture_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _activeMode = j['mode'] as String? ?? 'Standard';
        _brightness = j['brightness'] as int? ?? 50;
        _contrast = j['contrast'] as int? ?? 50;
        _color = j['color'] as int? ?? 50;
        _sharpness = j['sharpness'] as int? ?? 50;
        _backlight = j['backlight'] as int? ?? 70;
        _hdrMode = j['hdrMode'] as bool? ?? false;
        _eyeComfort = j['eyeComfort'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'mode': _activeMode,
      'brightness': _brightness,
      'contrast': _contrast,
      'color': _color,
      'sharpness': _sharpness,
      'backlight': _backlight,
      'hdrMode': _hdrMode,
      'eyeComfort': _eyeComfort,
    }));
  }

  void _selectMode(String mode) {
    setState(() {
      _activeMode = mode;
      switch (mode) {
        case 'Vivid':
          _brightness = 70;
          _contrast = 60;
          _color = 65;
          _sharpness = 55;
          _backlight = 85;
        case 'Standard':
          _brightness = 50;
          _contrast = 50;
          _color = 50;
          _sharpness = 50;
          _backlight = 70;
        case 'Cinema':
          _brightness = 45;
          _contrast = 55;
          _color = 48;
          _sharpness = 30;
          _backlight = 55;
        case 'Game':
          _brightness = 55;
          _contrast = 50;
          _color = 50;
          _sharpness = 60;
          _backlight = 75;
        case 'Sports':
          _brightness = 60;
          _contrast = 55;
          _color = 55;
          _sharpness = 50;
          _backlight = 80;
      }
    });
    _save();
  }

  void _applySettings() {
    final c = RemoteScope.of(context);
    c.key(core.Key.menu);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Opening TV picture settings menu'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
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
        title: Text('Picture Settings',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _modeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _sliderSection(),
          const SizedBox(height: AppSpacing.lg),
          _togglesSection(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _modeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Picture Mode',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
        children: _modes.map((m) {
          final active = _activeMode == m.$1;
          return GestureDetector(
            onTap: () => _selectMode(m.$1),
            child: Container(
              decoration: BoxDecoration(
                color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.25 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.6 : 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(m.$2, size: 20,
                      color: hex(active ? AppColors.primary : AppColors.outline)),
                  const SizedBox(height: 4),
                  Text(m.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _sliderSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adjustments',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _slider(Icons.brightness_6, 'Brightness', _brightness, (v) {
          setState(() => _brightness = v);
          _save();
        }),
        _slider(Icons.contrast, 'Contrast', _contrast, (v) {
          setState(() => _contrast = v);
          _save();
        }),
        _slider(Icons.palette, 'Color', _color, (v) {
          setState(() => _color = v);
          _save();
        }),
        _slider(Icons.deblur, 'Sharpness', _sharpness, (v) {
          setState(() => _sharpness = v);
          _save();
        }),
        _slider(Icons.light_mode, 'Backlight', _backlight, (v) {
          setState(() => _backlight = v);
          _save();
        }),
      ],
    ),
  );

  Widget _slider(IconData icon, String label, int value, ValueChanged<int> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Text(label,
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11)),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: hex(AppColors.primary),
                  inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                  thumbColor: hex(AppColors.primary),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11)),
            ),
          ],
        ),
      );

  Widget _togglesSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.hdr_on, 'HDR Mode', _hdrMode, (v) {
          setState(() => _hdrMode = v);
          _save();
        }),
        const SizedBox(height: 6),
        _toggleRow(Icons.remove_red_eye, 'Eye Comfort Mode', _eyeComfort, (v) {
          setState(() => _eyeComfort = v);
          _save();
        }),
      ],
    ),
  );

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)))),
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

  Widget _applyButton() => GestureDetector(
    onTap: _applySettings,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 16, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Open TV Picture Menu',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
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
            'Presets are saved locally. Use "Open TV Picture Menu" to navigate your TV\'s native picture settings.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
