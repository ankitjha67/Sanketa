import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  String _soundMode = 'Standard';
  int _bass = 50;
  int _treble = 50;
  int _balance = 50;
  String _output = 'tv_speakers';
  bool _nightListening = false;
  bool _dialogEnhance = false;
  bool _surroundSound = false;
  bool _loading = true;

  static const _soundModes = <(String, IconData)>[
    ('Standard', Icons.graphic_eq),
    ('Music', Icons.music_note),
    ('Cinema', Icons.movie),
    ('Voice', Icons.record_voice_over),
    ('Sports', Icons.sports),
    ('Game', Icons.sports_esports),
  ];

  static const _outputs = <(String, String, IconData)>[
    ('tv_speakers', 'TV Speakers', Icons.tv),
    ('soundbar', 'Soundbar', Icons.speaker),
    ('bluetooth', 'Bluetooth', Icons.bluetooth_audio),
    ('hdmi_arc', 'HDMI ARC', Icons.settings_input_hdmi),
    ('optical', 'Optical', Icons.fiber_manual_record),
    ('headphones', 'Headphones', Icons.headphones),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sound_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _soundMode = j['soundMode'] as String? ?? 'Standard';
        _bass = j['bass'] as int? ?? 50;
        _treble = j['treble'] as int? ?? 50;
        _balance = j['balance'] as int? ?? 50;
        _output = j['output'] as String? ?? 'tv_speakers';
        _nightListening = j['nightListening'] as bool? ?? false;
        _dialogEnhance = j['dialogEnhance'] as bool? ?? false;
        _surroundSound = j['surroundSound'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'soundMode': _soundMode,
      'bass': _bass,
      'treble': _treble,
      'balance': _balance,
      'output': _output,
      'nightListening': _nightListening,
      'dialogEnhance': _dialogEnhance,
      'surroundSound': _surroundSound,
    }));
  }

  void _selectMode(String mode) {
    setState(() {
      _soundMode = mode;
      switch (mode) {
        case 'Standard':
          _bass = 50;
          _treble = 50;
        case 'Music':
          _bass = 65;
          _treble = 60;
        case 'Cinema':
          _bass = 60;
          _treble = 45;
        case 'Voice':
          _bass = 35;
          _treble = 65;
        case 'Sports':
          _bass = 55;
          _treble = 55;
        case 'Game':
          _bass = 55;
          _treble = 50;
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
          content: Text('Opening TV sound settings menu'),
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
        title: Text('Sound Settings',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _modeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _eqSection(),
          const SizedBox(height: AppSpacing.lg),
          _outputSection(),
          const SizedBox(height: AppSpacing.lg),
          _featuresSection(),
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
      Text('Sound Mode',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
        children: _soundModes.map((m) {
          final active = _soundMode == m.$1;
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

  Widget _eqSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equalizer',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _slider(Icons.graphic_eq, 'Bass', _bass, (v) {
          setState(() => _bass = v);
          _save();
        }),
        _slider(Icons.graphic_eq, 'Treble', _treble, (v) {
          setState(() => _treble = v);
          _save();
        }),
        _slider(Icons.swap_horiz, 'Balance', _balance, (v) {
          setState(() => _balance = v);
          _save();
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('  L',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            Text('R  ',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
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
              width: 56,
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

  Widget _outputSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audio Output',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._outputs.map((o) {
          final active = _output == o.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () {
                setState(() => _output = o.$1);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: active
                      ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(o.$3, size: 16,
                        color: hex(active ? AppColors.primary : AppColors.outline)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(o.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400)),
                    ),
                    if (active) Icon(Icons.check, size: 16, color: hex(AppColors.primary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );

  Widget _featuresSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.nightlight, 'Night Listening', _nightListening, (v) {
          setState(() => _nightListening = v);
          _save();
        }),
        const SizedBox(height: 6),
        _toggleRow(Icons.record_voice_over, 'Dialog Enhancement', _dialogEnhance, (v) {
          setState(() => _dialogEnhance = v);
          _save();
        }),
        const SizedBox(height: 6),
        _toggleRow(Icons.surround_sound, 'Virtual Surround', _surroundSound, (v) {
          setState(() => _surroundSound = v);
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
          Icon(Icons.speaker, size: 16, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Open TV Sound Menu',
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
            'Sound presets are saved locally for quick recall. Use "Open TV Sound Menu" to navigate your TV\'s native audio settings.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
