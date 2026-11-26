import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AmbientSoundsScreen extends StatefulWidget {
  const AmbientSoundsScreen({super.key});

  @override
  State<AmbientSoundsScreen> createState() => _AmbientSoundsScreenState();
}

class _AmbientSoundsScreenState extends State<AmbientSoundsScreen> {
  int _playing = -1;
  double _volume = 0.6;

  static const _sounds = <(String, IconData, int, String)>[
    ('Rain', Icons.water_drop, AppColors.primary, 'Gentle rainfall'),
    ('Ocean Waves', Icons.waves, AppColors.secondary, 'Rolling ocean surf'),
    ('Fireplace', Icons.local_fire_department, AppColors.error, 'Crackling fire'),
    ('Forest', Icons.forest, AppColors.signalEmerald, 'Birds and leaves'),
    ('White Noise', Icons.graphic_eq, AppColors.outline, 'Steady white noise'),
    ('Thunder', Icons.bolt, AppColors.alertAmber, 'Distant thunder'),
    ('Wind', Icons.air, AppColors.tertiary, 'Gentle breeze'),
    ('Stream', Icons.water, AppColors.primary, 'Babbling brook'),
    ('Night', Icons.nightlight, AppColors.secondary, 'Crickets and owls'),
    ('Cafe', Icons.coffee, AppColors.alertAmber, 'Coffee shop ambience'),
  ];

  void _toggleSound(int i) {
    final rc = RemoteScope.of(context);
    if (_playing == i) {
      setState(() => _playing = -1);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Stopped: ${_sounds[i].$1}'),
          duration: const Duration(seconds: 1),
        ));
    } else {
      setState(() => _playing = i);
      rc.launch(_sounds[i].$1);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Playing: ${_sounds[i].$1}'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Ambient Sounds',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (_playing >= 0) ...[
            _nowPlaying(),
            const SizedBox(height: AppSpacing.md),
          ],
          _volumeSlider(),
          const SizedBox(height: AppSpacing.md),
          _soundGrid(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.spa, size: 36, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relax & Sleep',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
                  Text('Play calming sounds through your TV speakers',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _nowPlaying() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(_sounds[_playing].$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(_sounds[_playing].$3).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(_sounds[_playing].$2, size: 24, color: hex(_sounds[_playing].$3)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Now Playing',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                  Text(_sounds[_playing].$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(_sounds[_playing].$3), weight: FontWeight.w600)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleSound(_playing),
              child: Icon(Icons.stop_circle, size: 28, color: hex(_sounds[_playing].$3)),
            ),
          ],
        ),
      );

  Widget _volumeSlider() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.volume_down, size: 18, color: hex(AppColors.outline)),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0,
                max: 1,
                divisions: 20,
                activeColor: hex(AppColors.signalEmerald),
                onChanged: (v) => setState(() => _volume = v),
              ),
            ),
            Icon(Icons.volume_up, size: 18, color: hex(AppColors.outline)),
            const SizedBox(width: 6),
            Text('${(_volume * 100).round()}%',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11, weight: FontWeight.w600)),
          ],
        ),
      );

  Widget _soundGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sounds (${_sounds.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_sounds.length, (i) {
              final s = _sounds[i];
              final active = _playing == i;
              return GestureDetector(
                onTap: () => _toggleSound(i),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: hex(s.$3).withValues(alpha: active ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(s.$3).withValues(alpha: active ? 0.5 : 0.2),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(active ? Icons.stop_circle : s.$2, size: 26, color: hex(s.$3)),
                      const SizedBox(height: 6),
                      Text(s.$1,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: active ? FontWeight.w700 : FontWeight.w500, size: 10)),
                      Text(s.$4,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 8)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
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
                'Play calming ambient sounds through your TV. Great for sleep, relaxation, or focus. Sounds are launched on the TV — no data leaves your network.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
