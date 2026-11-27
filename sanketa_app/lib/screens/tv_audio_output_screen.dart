import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvAudioOutputScreen extends StatefulWidget {
  const TvAudioOutputScreen({super.key});

  @override
  State<TvAudioOutputScreen> createState() => _TvAudioOutputScreenState();
}

class _TvAudioOutputScreenState extends State<TvAudioOutputScreen> {
  int _activeOutput = 0;
  double _volume = 50;
  bool _bassBoost = false;
  bool _nightMode = false;

  static const _outputs = <(String, IconData, String, int)>[
    ('TV Speakers', Icons.tv, 'Built-in stereo', AppColors.primary),
    ('Soundbar', Icons.speaker, 'HDMI ARC / eARC', AppColors.signalEmerald),
    ('Bluetooth', Icons.bluetooth_audio, 'Wireless audio', AppColors.secondary),
    ('Headphones', Icons.headphones, '3.5mm jack', AppColors.alertAmber),
    ('Optical', Icons.settings_input_svideo, 'S/PDIF out', AppColors.tertiary),
  ];

  void _selectOutput(int idx) {
    final rc = RemoteScope.of(context);
    rc.launch('audio:${_outputs[idx].$1}');
    setState(() => _activeOutput = idx);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Audio output: ${_outputs[idx].$1}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cur = _outputs[_activeOutput];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Audio Output',
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
          _activeCard(cur),
          const SizedBox(height: AppSpacing.lg),
          _volumeSlider(),
          const SizedBox(height: AppSpacing.lg),
          Text('Output Devices',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          ..._outputs.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _outputTile(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.lg),
          _optionsRow(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.speaker_group,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Audio Output',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Switch audio output, adjust volume, toggle sound modes',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _activeCard((String, IconData, String, int) out) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(out.$4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(out.$4).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(out.$2, size: 32, color: hex(out.$4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(out.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(out.$4),
                          weight: FontWeight.w600,
                          size: 15)),
                  Text(out.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            Icon(Icons.check_circle, size: 24, color: hex(out.$4)),
          ],
        ),
      );

  Widget _volumeSlider() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up,
                    size: 18, color: hex(AppColors.primary)),
                const SizedBox(width: 8),
                Text('Volume',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const Spacer(),
                Text('${_volume.round()}%',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                thumbColor: hex(AppColors.primary),
                overlayColor: hex(AppColors.primary).withValues(alpha: 0.1),
              ),
              child: Slider(
                value: _volume,
                min: 0,
                max: 100,
                onChanged: (v) {
                  setState(() => _volume = v);
                },
                onChangeEnd: (v) {
                  RemoteScope.of(context).launch('volume:${v.round()}');
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ],
        ),
      );

  Widget _outputTile(int idx, (String, IconData, String, int) out) {
    final active = idx == _activeOutput;
    return GestureDetector(
      onTap: () => _selectOutput(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? out.$4 : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(active ? out.$4 : AppColors.outlineVariant)
                  .withValues(alpha: active ? 0.4 : 0.2)),
        ),
        child: Row(
          children: [
            Icon(out.$2, size: 24, color: hex(out.$4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(out.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(out.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, size: 20, color: hex(out.$4)),
          ],
        ),
      ),
    );
  }

  Widget _optionsRow() => Column(
        children: [
          _toggleOption('Bass Boost', Icons.equalizer, _bassBoost, (v) {
            setState(() => _bassBoost = v);
            HapticFeedback.selectionClick();
          }),
          const SizedBox(height: 6),
          _toggleOption('Night Mode', Icons.nightlight, _nightMode, (v) {
            setState(() => _nightMode = v);
            HapticFeedback.selectionClick();
          }),
        ],
      );

  Widget _toggleOption(
          String label, IconData icon, bool value, ValueChanged<bool> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(value ? AppColors.signalEmerald : AppColors.surfaceContainerLow)
              .withValues(alpha: value ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(value
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    hex(value ? AppColors.signalEmerald : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 13)),
            ),
            GestureDetector(
              onTap: () => onChanged(!value),
              child: Icon(
                value ? Icons.toggle_on : Icons.toggle_off,
                size: 32,
                color: hex(value
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant),
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
                'Switch between audio outputs (TV speakers, soundbar, Bluetooth, '
                'headphones, optical). Adjust volume and sound modes. All local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
