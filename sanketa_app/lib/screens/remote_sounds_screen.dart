import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class RemoteSoundsScreen extends StatefulWidget {
  const RemoteSoundsScreen({super.key});

  @override
  State<RemoteSoundsScreen> createState() => _RemoteSoundsScreenState();
}

class _RemoteSoundsScreenState extends State<RemoteSoundsScreen> {
  bool _masterEnabled = true;
  double _volume = 70;

  static const _sounds = [
    ('Click', Icons.touch_app),
    ('Pop', Icons.bubble_chart),
    ('Beep', Icons.notifications_active),
    ('Whoosh', Icons.air),
    ('Ding', Icons.campaign),
    ('Tap', Icons.ads_click),
    ('Chirp', Icons.music_note),
    ('Blip', Icons.radio_button_checked),
    ('Snap', Icons.snooze),
    ('Thud', Icons.square),
  ];

  static const _buttons = [
    'Power',
    'Volume Up',
    'Volume Down',
    'Mute',
    'OK',
    'Back',
    'Home',
    'Menu',
  ];

  final Map<String, int> _assignments = {};

  @override
  void initState() {
    super.initState();
    for (final b in _buttons) {
      _assignments[b] = 0;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/remote_sounds.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        setState(() {
          _masterEnabled = data['enabled'] as bool? ?? true;
          _volume = (data['volume'] as num?)?.toDouble() ?? 70;
          final a = data['assignments'] as Map<String, dynamic>?;
          if (a != null) {
            for (final e in a.entries) {
              if (_assignments.containsKey(e.key)) {
                _assignments[e.key] = e.value as int;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/remote_sounds.json');
      await f.writeAsString(jsonEncode({
        'enabled': _masterEnabled,
        'volume': _volume,
        'assignments': _assignments,
      }));
    } catch (_) {}
  }

  void _preview(int soundIndex) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Preview: ${_sounds[soundIndex].$1}'),
        duration: const Duration(seconds: 1),
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
        title: Text('Remote Sounds',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _masterToggle(),
          const SizedBox(height: AppSpacing.md),
          _volumeSlider(),
          const SizedBox(height: AppSpacing.lg),
          Text('Sound Library',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _soundGrid(),
          const SizedBox(height: AppSpacing.lg),
          Text('Button Assignments',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._buttons.map(_assignmentRow),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.music_note, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Custom Button Sounds',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Assign unique sound effects to each remote button press',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => GestureDetector(
        onTap: () {
          setState(() => _masterEnabled = !_masterEnabled);
          HapticFeedback.selectionClick();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(
                    _masterEnabled ? AppColors.signalEmerald : AppColors.outline)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_masterEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outline)
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _masterEnabled ? Icons.volume_up : Icons.volume_off,
                size: 28,
                color: hex(_masterEnabled
                    ? AppColors.signalEmerald
                    : AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _masterEnabled ? 'Sounds Enabled' : 'Sounds Disabled',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                      _masterEnabled
                          ? 'Button presses play sound effects'
                          : 'All button sounds are muted',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _volumeSlider() => Container(
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
                Text('Volume',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${_volume.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _volume = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _soundGrid() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _sounds.asMap().entries.map((e) {
          final s = e.value;
          return GestureDetector(
            onTap: () => _preview(e.key),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Icon(s.$2, size: 20, color: hex(AppColors.secondary)),
                  const SizedBox(height: 4),
                  Text(s.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface), size: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _assignmentRow(String button) {
    final idx = _assignments[button] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(button,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 12)),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _assignments[button] = (idx + 1) % _sounds.length;
                });
                HapticFeedback.selectionClick();
                _save();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.secondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_sounds[idx].$2,
                        size: 14, color: hex(AppColors.secondary)),
                    const SizedBox(width: 4),
                    Text(_sounds[idx].$1,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.secondary),
                            weight: FontWeight.w600,
                            size: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                'Assign custom sound effects to remote button presses. Tap a sound to preview it with haptic feedback. Sounds play locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
