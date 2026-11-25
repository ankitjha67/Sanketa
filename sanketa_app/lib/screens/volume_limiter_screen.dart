import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VolumeLimiterScreen extends StatefulWidget {
  const VolumeLimiterScreen({super.key});

  @override
  State<VolumeLimiterScreen> createState() => _VolumeLimiterScreenState();
}

class _VolumeLimiterScreenState extends State<VolumeLimiterScreen> {
  bool _limiterEnabled = false;
  int _maxVolume = 60;
  int _currentVolume = 30;
  String _activePreset = 'normal';
  bool _loading = true;

  static const _presets = <(String, String, IconData, int)>[
    ('whisper', 'Whisper', Icons.hearing, 15),
    ('quiet', 'Quiet', Icons.volume_down, 30),
    ('normal', 'Normal', Icons.volume_up, 50),
    ('loud', 'Loud', Icons.surround_sound, 75),
    ('max', 'Maximum', Icons.speaker, 100),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/volume_limiter.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _limiterEnabled = j['limiterEnabled'] as bool? ?? false;
        _maxVolume = j['maxVolume'] as int? ?? 60;
        _currentVolume = j['currentVolume'] as int? ?? 30;
        _activePreset = j['activePreset'] as String? ?? 'normal';
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'limiterEnabled': _limiterEnabled,
      'maxVolume': _maxVolume,
      'currentVolume': _currentVolume,
      'activePreset': _activePreset,
    }));
  }

  void _setVolume(int level) {
    final c = RemoteScope.of(context);
    if (_limiterEnabled && level > _maxVolume) {
      level = _maxVolume;
    }
    setState(() => _currentVolume = level);
    _save();
    if (level == 0) {
      c.key(core.Key.mute);
    }
  }

  void _volumeUp() {
    if (_currentVolume < (_limiterEnabled ? _maxVolume : 100)) {
      _setVolume(_currentVolume + 1);
      RemoteScope.of(context).key(core.Key.volumeUp);
    }
  }

  void _volumeDown() {
    if (_currentVolume > 0) {
      _setVolume(_currentVolume - 1);
      RemoteScope.of(context).key(core.Key.volumeDown);
    }
  }

  void _applyPreset(String id, int level) {
    setState(() {
      _activePreset = id;
      _currentVolume = _limiterEnabled && level > _maxVolume ? _maxVolume : level;
    });
    _save();
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
        title: Text('Volume',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _volumeDisplay(),
          const SizedBox(height: AppSpacing.lg),
          _volumeControls(),
          const SizedBox(height: AppSpacing.lg),
          _presetSection(),
          const SizedBox(height: AppSpacing.lg),
          _limiterSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _volumeDisplay() => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentVolume == 0 ? Icons.volume_off : (_currentVolume < 50 ? Icons.volume_down : Icons.volume_up),
              size: 28,
              color: hex(_currentVolume == 0 ? AppColors.outline : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text('$_currentVolume',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 48, weight: FontWeight.w200)),
            Text(' %',
                style: gfont(AppType.bodyMd, color: hex(AppColors.outline), size: 16)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 8,
                color: hex(AppColors.surfaceContainerHigh),
              ),
              FractionallySizedBox(
                widthFactor: _currentVolume / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentVolume > 80
                        ? hex(AppColors.error)
                        : hex(AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                ),
              ),
              if (_limiterEnabled)
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.75 * _maxVolume / 100,
                  child: Container(
                    width: 2,
                    height: 8,
                    color: hex(AppColors.error),
                  ),
                ),
            ],
          ),
        ),
        if (_limiterEnabled) ...[
          const SizedBox(height: 6),
          Text('Limit: $_maxVolume%',
              style: gfont(AppType.bodySm, color: hex(AppColors.error), size: 10, weight: FontWeight.w500)),
        ],
      ],
    ),
  );

  Widget _volumeControls() => Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: _volumeDown,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(Icons.remove, size: 24, color: hex(AppColors.onSurface)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          _setVolume(0);
          RemoteScope.of(context).key(core.Key.mute);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: hex(_currentVolume == 0 ? AppColors.error : AppColors.surfaceContainerHigh)
                .withValues(alpha: _currentVolume == 0 ? 0.15 : 1),
            shape: BoxShape.circle,
            border: _currentVolume == 0
                ? Border.all(color: hex(AppColors.error).withValues(alpha: 0.3))
                : null,
          ),
          child: Icon(Icons.volume_off, size: 20,
              color: hex(_currentVolume == 0 ? AppColors.error : AppColors.onSurface)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: _volumeUp,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(Icons.add, size: 24, color: hex(AppColors.onSurface)),
          ),
        ),
      ),
    ],
  );

  Widget _presetSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volume Presets',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: _presets.map((p) {
            final active = _activePreset == p.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () => _applyPreset(p.$1, p.$4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.25 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: active
                          ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p.$3, size: 16,
                            color: hex(active ? AppColors.primary : AppColors.outline)),
                        const SizedBox(height: 2),
                        Text(p.$2,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 9)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _limiterSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _limiterEnabled = !_limiterEnabled);
            _save();
          },
          child: Row(
            children: [
              Icon(Icons.block, size: 16,
                  color: hex(_limiterEnabled ? AppColors.error : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume Limiter',
                        style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                    Text('Cap maximum volume',
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(_limiterEnabled ? AppColors.error : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: _limiterEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hex(_limiterEnabled ? AppColors.onPrimary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_limiterEnabled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('$_maxVolume%',
                    textAlign: TextAlign.center,
                    style: gfont(AppType.labelMonoSm, color: hex(AppColors.error), size: 11, weight: FontWeight.w700)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: hex(AppColors.error),
                    inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                    thumbColor: hex(AppColors.error),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _maxVolume.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 18,
                    onChanged: (v) {
                      setState(() {
                        _maxVolume = v.round();
                        if (_currentVolume > _maxVolume) {
                          _currentVolume = _maxVolume;
                        }
                      });
                      _save();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
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
            'Control volume with presets and set a maximum limit. Useful for night-time listening or keeping volume safe for children.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
