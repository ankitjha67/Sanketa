import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _AudioOutput {
  _AudioOutput({
    required this.name,
    required this.icon,
    required this.format,
    required this.connected,
    this.delayMs = 0,
  });

  final String name;
  final IconData icon;
  final String format;
  final bool connected;
  int delayMs;
  int volume = 50;
}

class AudioOutputScreen extends StatefulWidget {
  const AudioOutputScreen({super.key});

  @override
  State<AudioOutputScreen> createState() => _AudioOutputScreenState();
}

class _AudioOutputScreenState extends State<AudioOutputScreen> {
  int _selectedIndex = 0;
  bool _testing = false;

  final _outputs = [
    _AudioOutput(name: 'TV Speakers', icon: Icons.tv, format: 'Stereo PCM', connected: true),
    _AudioOutput(name: 'Soundbar (HDMI ARC)', icon: Icons.speaker_group, format: 'Dolby Digital 5.1', connected: true, delayMs: 15),
    _AudioOutput(name: 'Bluetooth Headphones', icon: Icons.headphones, format: 'AAC Stereo', connected: false),
    _AudioOutput(name: 'HDMI eARC', icon: Icons.settings_input_hdmi, format: 'Dolby Atmos / DTS:X', connected: true, delayMs: 5),
    _AudioOutput(name: 'Optical / TOSLINK', icon: Icons.fiber_smart_record, format: 'Dolby Digital 5.1', connected: true, delayMs: 20),
  ];

  Future<void> _testSound() async {
    setState(() => _testing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Audio Output',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _currentOutput(),
          const SizedBox(height: AppSpacing.md),
          Text('Available Outputs',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_outputs.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _outputCard(i),
          )),
          const SizedBox(height: AppSpacing.md),
          if (_outputs[_selectedIndex].connected) ...[
            _volumeControl(),
            const SizedBox(height: AppSpacing.md),
            _lipSyncControl(),
            const SizedBox(height: AppSpacing.md),
            _testButton(),
            const SizedBox(height: AppSpacing.md),
          ],
          _infoCard(),
        ],
      ),
    );
  }

  Widget _currentOutput() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(_outputs[_selectedIndex].icon, size: 24, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Output',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              Text(_outputs[_selectedIndex].name,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text(_outputs[_selectedIndex].format,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 10)),
            ],
          ),
        ),
        Icon(Icons.volume_up, size: 20, color: hex(AppColors.primary)),
      ],
    ),
  );

  Widget _outputCard(int index) {
    final o = _outputs[index];
    final active = index == _selectedIndex;
    return GestureDetector(
      onTap: o.connected ? () => setState(() => _selectedIndex = index) : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerLow).withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: active ? 0.4 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(o.icon, size: 20, color: hex(active ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.name,
                      style: gfont(AppType.bodyMd, color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400, size: 12)),
                  Text(o.format,
                      style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
            if (!o.connected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.outline).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Disconnected',
                    style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 8)),
              )
            else if (active)
              Icon(Icons.check_circle, size: 18, color: hex(AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _volumeControl() => Container(
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
            Icon(Icons.volume_up, size: 16, color: hex(AppColors.primary)),
            const SizedBox(width: 8),
            Text('Volume', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_outputs[_selectedIndex].volume}%',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.primary),
            inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            thumbColor: hex(AppColors.primary),
            trackHeight: 4,
          ),
          child: Slider(
            value: _outputs[_selectedIndex].volume.toDouble(),
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _outputs[_selectedIndex].volume = v.round()),
          ),
        ),
      ],
    ),
  );

  Widget _lipSyncControl() => Container(
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
            Icon(Icons.sync, size: 16, color: hex(AppColors.alertAmber)),
            const SizedBox(width: 8),
            Text('Lip Sync Delay', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_outputs[_selectedIndex].delayMs} ms',
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
            value: _outputs[_selectedIndex].delayMs.toDouble(),
            min: 0,
            max: 200,
            divisions: 40,
            onChanged: (v) => setState(() => _outputs[_selectedIndex].delayMs = v.round()),
          ),
        ),
        Text('Adjust if audio is out of sync with video',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
      ],
    ),
  );

  Widget _testButton() => GestureDetector(
    onTap: _testing ? null : _testSound,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(_testing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(_testing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _testing ? Icons.graphic_eq : Icons.play_circle_outline,
            size: 18,
            color: hex(_testing ? AppColors.outline : AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            _testing ? 'Playing test tone...' : 'Test Sound',
            style: gfont(AppType.bodyMd,
                color: hex(_testing ? AppColors.outline : AppColors.primary), weight: FontWeight.w600, size: 13),
          ),
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
            'Route your TV audio to different outputs. Changes are sent directly to your TV over the local network.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
