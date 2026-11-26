import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ScreenSaverScreen extends StatefulWidget {
  const ScreenSaverScreen({super.key});

  @override
  State<ScreenSaverScreen> createState() => _ScreenSaverScreenState();
}

class _ScreenSaverScreenState extends State<ScreenSaverScreen> {
  int _selectedType = 0;
  int _timeoutIndex = 2;
  double _brightness = 0.5;
  bool _showClock = true;

  static const _types = [
    ('Ambient Art', Icons.palette, 'Slowly shifting colour gradients'),
    ('Photo Frame', Icons.photo_library, 'Slideshow from your photos'),
    ('Clock', Icons.access_time, 'Large digital/analogue clock'),
    ('Blank Screen', Icons.brightness_1, 'Screen goes dark to save energy'),
    ('Fireplace', Icons.local_fire_department, 'Cozy animated fireplace'),
    ('Aquarium', Icons.water, 'Tropical fish aquarium loop'),
  ];

  static const _timeouts = ['1 min', '2 min', '5 min', '10 min', '30 min', 'Never'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/screensaver_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedType = j['type'] as int? ?? 0;
        _timeoutIndex = j['timeout'] as int? ?? 2;
        _brightness = (j['brightness'] as num?)?.toDouble() ?? 0.5;
        _showClock = j['showClock'] as bool? ?? true;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'type': _selectedType,
      'timeout': _timeoutIndex,
      'brightness': _brightness,
      'showClock': _showClock,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Screen Saver',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          Text('Style',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_types.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _typeCard(i),
          )),
          const SizedBox(height: AppSpacing.md),
          _timeoutSelector(),
          const SizedBox(height: AppSpacing.md),
          _brightnessControl(),
          const SizedBox(height: AppSpacing.md),
          _clockToggle(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
    height: 160,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          hex(AppColors.primary).withValues(alpha: 0.15),
          hex(AppColors.tertiary).withValues(alpha: 0.1),
          hex(AppColors.secondary).withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_types[_selectedType].$2, size: 40, color: hex(AppColors.primary)),
          const SizedBox(height: 8),
          Text(_types[_selectedType].$1,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          Text('Preview',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
        ],
      ),
    ),
  );

  Widget _typeCard(int index) {
    final t = _types[index];
    final active = index == _selectedType;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = index);
        _save();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: active ? 0.4 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(active ? AppColors.primary : AppColors.outline).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(t.$2, size: 18, color: hex(active ? AppColors.primary : AppColors.outline)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400, size: 12)),
                  Text(t.$3,
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            if (active) Icon(Icons.check_circle, size: 18, color: hex(AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _timeoutSelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start After', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(_timeouts.length, (i) {
            final active = i == _timeoutIndex;
            return GestureDetector(
              onTap: () {
                setState(() => _timeoutIndex = i);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Text(_timeouts[i],
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _brightnessControl() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.brightness_6, size: 16, color: hex(AppColors.alertAmber)),
            const SizedBox(width: 8),
            Text('Screen Brightness',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${(_brightness * 100).round()}%',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.alertAmber),
            inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            thumbColor: hex(AppColors.alertAmber),
            trackHeight: 4,
          ),
          child: Slider(
            value: _brightness,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => setState(() => _brightness = v),
            onChangeEnd: (_) => _save(),
          ),
        ),
      ],
    ),
  );

  Widget _clockToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.access_time, size: 20, color: hex(AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Show Clock Overlay',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Display time over the screen saver',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        Switch(
          value: _showClock,
          activeTrackColor: hex(AppColors.primary),
          onChanged: (v) {
            setState(() => _showClock = v);
            _save();
          },
        ),
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
            'Configure your TV screen saver style and timing. Settings are sent directly to your TV over the local network. Protects OLED panels from burn-in.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
