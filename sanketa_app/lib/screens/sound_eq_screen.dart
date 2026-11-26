import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundEqScreen extends StatefulWidget {
  const SoundEqScreen({super.key});

  @override
  State<SoundEqScreen> createState() => _SoundEqScreenState();
}

class _SoundEqScreenState extends State<SoundEqScreen> {
  int _presetIndex = 0;
  List<double> _bands = [0, 0, 0, 0, 0];
  bool _loading = true;
  bool _bassBoost = false;
  bool _nightMode = false;
  bool _dialogEnhance = false;

  static const _bandLabels = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];

  static const _presets = <(String, IconData, List<double>)>[
    ('Flat', Icons.horizontal_rule, [0, 0, 0, 0, 0]),
    ('Movie', Icons.movie, [3, 1, 0, 2, 4]),
    ('Music', Icons.music_note, [4, 2, 0, 2, 3]),
    ('Voice', Icons.record_voice_over, [-2, 0, 4, 3, 0]),
    ('Bass', Icons.speaker, [6, 4, 0, -1, -2]),
    ('Treble', Icons.graphic_eq, [-2, -1, 0, 3, 5]),
    ('Night', Icons.nightlight, [-3, 0, 2, 1, -2]),
    ('Custom', Icons.tune, [0, 0, 0, 0, 0]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sound_eq.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _presetIndex = data['preset'] as int? ?? 0;
        _bands = (data['bands'] as List?)?.cast<double>() ?? [0, 0, 0, 0, 0];
        _bassBoost = data['bassBoost'] as bool? ?? false;
        _nightMode = data['nightMode'] as bool? ?? false;
        _dialogEnhance = data['dialogEnhance'] as bool? ?? false;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'preset': _presetIndex,
      'bands': _bands,
      'bassBoost': _bassBoost,
      'nightMode': _nightMode,
      'dialogEnhance': _dialogEnhance,
    }));
  }

  void _selectPreset(int i) {
    setState(() {
      _presetIndex = i;
      if (i < _presets.length - 1) {
        _bands = List.from(_presets[i].$3);
      }
    });
    _save();
  }

  void _updateBand(int i, double v) {
    setState(() {
      _bands[i] = v.roundToDouble();
      _presetIndex = _presets.length - 1;
    });
    _save();
  }

  void _applyToTv() {
    final rc = RemoteScope.of(context);
    rc.launch('Sound Settings');
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Opening TV sound settings — apply "${_presets[_presetIndex].$1}" preset'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sound EQ',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _presetSelector(),
          const SizedBox(height: AppSpacing.md),
          _eqSliders(),
          const SizedBox(height: AppSpacing.md),
          _togglesSection(),
          const SizedBox(height: AppSpacing.md),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.equalizer,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Audio Equalizer',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Tune your TV audio with presets or custom 5-band EQ adjustments',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _presetSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presets.length, (i) {
              final p = _presets[i];
              final active = i == _presetIndex;
              return GestureDetector(
                onTap: () => _selectPreset(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.5 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(p.$2,
                          size: 14,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.outline)),
                      const SizedBox(width: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.primary
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 11)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      );

  Widget _eqSliders() => Container(
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
            Text('Equalizer',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                return Expanded(
                  child: Column(
                    children: [
                      Text('${_bands[i].round()}dB',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.primary),
                              size: 9,
                              weight: FontWeight.w600)),
                      SizedBox(
                        height: 120,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: hex(AppColors.primary),
                              inactiveTrackColor: hex(AppColors.outlineVariant)
                                  .withValues(alpha: 0.2),
                              thumbColor: hex(AppColors.primary),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: _bands[i],
                              min: -6,
                              max: 6,
                              divisions: 12,
                              onChanged: (v) => _updateBand(i, v),
                            ),
                          ),
                        ),
                      ),
                      Text(_bandLabels[i],
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _togglesSection() => Column(
        children: [
          _toggle('Bass Boost', Icons.speaker, _bassBoost, (v) {
            setState(() => _bassBoost = v);
            _save();
          }),
          const SizedBox(height: 6),
          _toggle('Night Mode', Icons.nightlight, _nightMode, (v) {
            setState(() => _nightMode = v);
            _save();
          }),
          const SizedBox(height: 6),
          _toggle('Dialog Enhance', Icons.record_voice_over, _dialogEnhance,
              (v) {
            setState(() => _dialogEnhance = v);
            _save();
          }),
        ],
      );

  Widget _toggle(
          String label, IconData icon, bool value, ValueChanged<bool> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 12)),
            ),
            Switch(
              value: value,
              activeTrackColor: hex(AppColors.primary),
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyToTv,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cast, size: 18, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Open TV Sound Settings',
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
                'Configure audio equalizer presets for your TV. Adjust 5 frequency bands or use built-in presets. Settings are saved locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
