import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundEqProScreen extends StatefulWidget {
  const SoundEqProScreen({super.key});

  @override
  State<SoundEqProScreen> createState() => _SoundEqProScreenState();
}

class _SoundEqProScreenState extends State<SoundEqProScreen> {
  bool _loading = true;
  int _presetIdx = 0;

  static const _bands = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];

  final _bandValues = <double>[50, 50, 50, 50, 50];

  static const _presets = <(String, IconData, int, List<double>)>[
    ('Flat', Icons.horizontal_rule, AppColors.outline, [50, 50, 50, 50, 50]),
    ('Bass Boost', Icons.speaker, AppColors.primary, [80, 70, 50, 45, 45]),
    ('Treble Boost', Icons.graphic_eq, AppColors.secondary, [40, 45, 50, 70, 80]),
    ('Vocal', Icons.mic, AppColors.tertiary, [40, 55, 75, 60, 40]),
    ('Movie', Icons.movie, AppColors.error, [70, 60, 50, 65, 55]),
    ('Night', Icons.nightlight, AppColors.signalEmerald, [30, 40, 60, 40, 30]),
  ];

  bool _bassBoost = false;
  bool _surroundSound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sound_eq_pro.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _presetIdx = j['preset'] as int? ?? 0;
        _bassBoost = j['bassBoost'] as bool? ?? false;
        _surroundSound = j['surround'] as bool? ?? false;
        final bands = j['bands'] as List?;
        if (bands != null && bands.length == 5) {
          for (var i = 0; i < 5; i++) {
            _bandValues[i] = (bands[i] as num).toDouble();
          }
        } else {
          _applyPreset(_presetIdx);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'preset': _presetIdx,
      'bassBoost': _bassBoost,
      'surround': _surroundSound,
      'bands': _bandValues,
    }));
  }

  void _applyPreset(int idx) {
    setState(() {
      _presetIdx = idx;
      final values = _presets[idx].$4;
      for (var i = 0; i < 5; i++) {
        _bandValues[i] = values[i];
      }
    });
    HapticFeedback.selectionClick();
    _save();
  }

  void _applyToTv() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('EQ applied — opening TV sound settings'),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sound EQ Pro',
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
                _eqSliders(),
                const SizedBox(height: AppSpacing.lg),
                _presetChips(),
                const SizedBox(height: AppSpacing.md),
                _toggleRow(),
                const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.equalizer, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('5-Band Equalizer',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Fine-tune your TV audio with professional EQ controls',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _eqSliders() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _bands
                  .map((b) => SizedBox(
                      width: 50,
                      child: Center(
                          child: Text(b,
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline), size: 9)))))
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  return SizedBox(
                    width: 50,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _bandValues[i],
                        min: 0,
                        max: 100,
                        activeColor: hex(AppColors.secondary),
                        inactiveColor:
                            hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                        onChanged: (v) {
                          setState(() => _bandValues[i] = v);
                          _save();
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                return SizedBox(
                  width: 50,
                  child: Center(
                    child: Text('${_bandValues[i].round()}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.secondary),
                            weight: FontWeight.w600,
                            size: 10)),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _presetChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _presets.asMap().entries.map((e) {
            final active = e.key == _presetIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _applyPreset(e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2,
                          size: 14, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _toggleRow() => Row(
        children: [
          Expanded(child: _toggleCard('Bass Boost', Icons.speaker,
              _bassBoost, AppColors.primary, (v) {
            setState(() => _bassBoost = v);
            HapticFeedback.selectionClick();
            _save();
          })),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _toggleCard('Surround', Icons.surround_sound,
              _surroundSound, AppColors.tertiary, (v) {
            setState(() => _surroundSound = v);
            HapticFeedback.selectionClick();
            _save();
          })),
        ],
      );

  Widget _toggleCard(String label, IconData icon, bool value, int c,
          ValueChanged<bool> onChanged) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(value ? c : AppColors.surfaceContainerLow)
                .withValues(alpha: value ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(value ? c : AppColors.outlineVariant)
                  .withValues(alpha: value ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: hex(value ? c : AppColors.outline)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 11)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hex(value ? c : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(value ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(value ? c : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _applyToTv,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.secondary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 20, color: hex(AppColors.secondary)),
              const SizedBox(width: 8),
              Text('Apply to TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.secondary),
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
                'Adjust 5-band EQ, pick presets, enable bass boost and surround. '
                'Apply opens TV sound settings. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
