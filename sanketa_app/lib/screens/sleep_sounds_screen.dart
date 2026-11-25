import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _SoundPreset {
  const _SoundPreset(this.id, this.name, this.icon, this.color);
  final String id;
  final String name;
  final IconData icon;
  final int color;
}

class SleepSoundsScreen extends StatefulWidget {
  const SleepSoundsScreen({super.key});

  @override
  State<SleepSoundsScreen> createState() => _SleepSoundsScreenState();
}

class _SleepSoundsScreenState extends State<SleepSoundsScreen> {
  String? _activeSound;
  int _timerMinutes = 30;
  int _remainingSeconds = 0;
  double _volume = 50;
  bool _loading = true;
  Timer? _timer;

  static const _sounds = <_SoundPreset>[
    _SoundPreset('white_noise', 'White Noise', Icons.graphic_eq, AppColors.outline),
    _SoundPreset('rain', 'Rain', Icons.water_drop, AppColors.primary),
    _SoundPreset('ocean', 'Ocean Waves', Icons.waves, AppColors.tertiary),
    _SoundPreset('forest', 'Forest', Icons.forest, AppColors.signalEmerald),
    _SoundPreset('fireplace', 'Fireplace', Icons.local_fire_department, AppColors.error),
    _SoundPreset('wind', 'Wind', Icons.air, AppColors.secondary),
    _SoundPreset('thunder', 'Thunderstorm', Icons.thunderstorm, AppColors.alertAmber),
    _SoundPreset('birds', 'Birdsong', Icons.emoji_nature, AppColors.signalEmerald),
  ];

  static const _timerPresets = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sleep_sounds.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _timerMinutes = j['timerMinutes'] as int? ?? 30;
        _volume = (j['volume'] as num?)?.toDouble() ?? 50;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'timerMinutes': _timerMinutes,
      'volume': _volume,
    }));
  }

  void _play(String id) {
    _timer?.cancel();
    setState(() {
      _activeSound = id;
      _remainingSeconds = _timerMinutes * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _stop();
        RemoteScope.of(context).key(core.Key.power);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _activeSound = null;
      _remainingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        title: Text('Sleep Sounds',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_activeSound != null)
            GestureDetector(
              onTap: _stop,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.stop_circle, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_activeSound != null) _nowPlaying(),
          if (_activeSound != null) const SizedBox(height: AppSpacing.lg),
          _soundGrid(),
          const SizedBox(height: AppSpacing.lg),
          _timerSection(),
          const SizedBox(height: AppSpacing.lg),
          _volumeSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _nowPlaying() {
    final sound = _sounds.firstWhere((s) => s.id == _activeSound);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(sound.color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(sound.color).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(sound.icon, size: 40, color: hex(sound.color)),
          const SizedBox(height: 8),
          Text(sound.name,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_formatTime(_remainingSeconds),
              style: gfont(AppType.headlineMd, color: hex(sound.color), size: 32, weight: FontWeight.w200)),
          const SizedBox(height: 4),
          Text('TV powers off when timer ends',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
        ],
      ),
    );
  }

  Widget _soundGrid() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sounds',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: _sounds.map((s) {
            final active = _activeSound == s.id;
            return GestureDetector(
              onTap: () => active ? _stop() : _play(s.id),
              child: Container(
                decoration: BoxDecoration(
                  color: hex(active ? s.color : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: active
                      ? Border.all(color: hex(s.color).withValues(alpha: 0.4))
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s.icon, size: 22, color: hex(active ? s.color : AppColors.outline)),
                    const SizedBox(height: 4),
                    Text(s.name,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? s.color : AppColors.onSurface),
                            size: 9,
                            weight: active ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _timerSection() => Container(
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
            Text('Sleep Timer',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('$_timerMinutes min',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _timerPresets.map((t) {
            final active = _timerMinutes == t;
            return GestureDetector(
              onTap: () { setState(() => _timerMinutes = t); _save(); },
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
                child: Text('$t min',
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 11)),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _volumeSection() => Container(
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
            Text('Volume',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_volume.round()}%',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.primary),
            inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
            thumbColor: hex(AppColors.primary),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: _volume,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) { setState(() => _volume = v); _save(); },
          ),
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
            'Play ambient sounds while falling asleep. When the timer ends, the TV powers off automatically. Audio plays through the TV speakers.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
