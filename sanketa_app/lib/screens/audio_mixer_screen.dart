import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AudioMixerScreen extends StatefulWidget {
  const AudioMixerScreen({super.key});

  @override
  State<AudioMixerScreen> createState() => _AudioMixerScreenState();
}

class _AudioMixerScreenState extends State<AudioMixerScreen> {
  bool _loading = true;

  static final _channels = <_AudioChannel>[
    _AudioChannel(name: 'Master', icon: Icons.volume_up, volume: 80, muted: false, color: AppColors.primary),
    _AudioChannel(name: 'Dialogue', icon: Icons.record_voice_over, volume: 90, muted: false, color: AppColors.signalEmerald),
    _AudioChannel(name: 'Music', icon: Icons.music_note, volume: 60, muted: false, color: AppColors.secondary),
    _AudioChannel(name: 'Effects', icon: Icons.graphic_eq, volume: 70, muted: false, color: AppColors.alertAmber),
    _AudioChannel(name: 'Bass', icon: Icons.speaker, volume: 55, muted: false, color: AppColors.tertiary),
    _AudioChannel(name: 'Surround', icon: Icons.surround_sound, volume: 50, muted: true, color: AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/audio_mixer.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        for (var i = 0; i < data.length && i < _channels.length; i++) {
          final m = data[i] as Map<String, dynamic>;
          _channels[i].volume = m['volume'] as int? ?? 50;
          _channels[i].muted = m['muted'] as bool? ?? false;
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_channels
        .map((c) => {'volume': c.volume, 'muted': c.muted})
        .toList()));
  }

  void _apply() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Audio mix applied'),
        duration: Duration(seconds: 1),
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

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Audio Mixer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _levelBars(),
          const SizedBox(height: AppSpacing.md),
          ..._channels.map(_channelStrip),
          const SizedBox(height: AppSpacing.md),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _levelBars() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _channels.map((c) {
            return Column(
              children: [
                SizedBox(
                  width: 12,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 12,
                        height: 60,
                        decoration: BoxDecoration(
                          color: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 12,
                        height: c.muted ? 0 : 60 * c.volume / 100,
                        decoration: BoxDecoration(
                          color: hex(c.color).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(c.name.substring(0, 3),
                    style: gfont(AppType.bodySm,
                        color: hex(c.muted ? AppColors.outline : c.color),
                        weight: FontWeight.w600,
                        size: 7)),
              ],
            );
          }).toList(),
        ),
      );

  Widget _channelStrip(_AudioChannel ch) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => ch.muted = !ch.muted);
                  _save();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hex(ch.muted ? AppColors.error : ch.color)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    ch.muted ? Icons.volume_off : ch.icon,
                    size: 18,
                    color: hex(ch.muted ? AppColors.error : ch.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 55,
                child: Text(ch.name,
                    style: gfont(AppType.bodySm,
                        color: hex(ch.muted ? AppColors.outline : AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
              Expanded(
                child: Slider(
                  value: ch.volume.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: hex(ch.muted ? AppColors.outline : ch.color),
                  inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                  onChanged: ch.muted
                      ? null
                      : (v) {
                          setState(() => ch.volume = v.round());
                          _save();
                        },
                ),
              ),
              SizedBox(
                width: 30,
                child: Text('${ch.volume}',
                    textAlign: TextAlign.right,
                    style: gfont(AppType.bodySm,
                        color: hex(ch.muted ? AppColors.outline : ch.color),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ],
          ),
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
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
              Icon(Icons.equalizer, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Mix',
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
                'Fine-tune individual audio channels: Master, Dialogue, Music, Effects, Bass, and Surround. Tap the icon to mute a channel. Slide to adjust volume. All settings stay on your device.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _AudioChannel {
  String name;
  IconData icon;
  int volume;
  bool muted;
  int color;

  _AudioChannel({
    required this.name,
    required this.icon,
    required this.volume,
    required this.muted,
    required this.color,
  });
}
