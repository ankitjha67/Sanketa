import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class MultiAudioScreen extends StatefulWidget {
  const MultiAudioScreen({super.key});

  @override
  State<MultiAudioScreen> createState() => _MultiAudioScreenState();
}

class _MultiAudioScreenState extends State<MultiAudioScreen> {
  int _selectedTrack = 0;
  int _selectedOutput = 0;
  bool _loading = true;
  bool _descriptiveAudio = false;

  static const _tracks = <(String, String, String)>[
    ('English', '5.1 Surround', 'AAC'),
    ('English', 'Stereo', 'AAC'),
    ('Spanish', '5.1 Surround', 'AC3'),
    ('French', 'Stereo', 'AAC'),
    ('German', 'Stereo', 'AAC'),
    ('Japanese', '5.1 Surround', 'EAC3'),
    ('Korean', 'Stereo', 'AAC'),
    ('Portuguese', 'Stereo', 'AAC'),
  ];

  static const _outputs = ['TV Speakers', 'Soundbar', 'Bluetooth', 'HDMI ARC'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/multi_audio.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedTrack = data['track'] as int? ?? 0;
        _selectedOutput = data['output'] as int? ?? 0;
        _descriptiveAudio = data['descriptive'] as bool? ?? false;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'track': _selectedTrack,
      'output': _selectedOutput,
      'descriptive': _descriptiveAudio,
    }));
  }

  void _applyTrack(int i) {
    setState(() => _selectedTrack = i);
    _save();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switching to ${_tracks[i].$1} ${_tracks[i].$2}'),
        duration: const Duration(seconds: 2),
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
        title: Text('Multi Audio',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _tracksSection(),
          const SizedBox(height: AppSpacing.md),
          _outputSection(),
          const SizedBox(height: AppSpacing.md),
          _accessibilityToggle(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.surround_sound, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Audio Tracks',
                style: gfont(AppType.bodyMd, color: hex(AppColors.secondary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Switch between audio languages and formats on your TV',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _tracksSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio Tracks (${_tracks.length})',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_tracks.length, (i) {
            final t = _tracks[i];
            final active = i == _selectedTrack;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _applyTrack(i),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.primary : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack,
                          size: 18, color: hex(active ? AppColors.primary : AppColors.outline)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
                            Text('${t.$2} · ${t.$3}',
                                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                          ],
                        ),
                      ),
                      Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18, color: hex(active ? AppColors.primary : AppColors.outline)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _outputSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio Output',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_outputs.length, (i) {
              final active = i == _selectedOutput;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedOutput = i);
                  _save();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.5 : 0.2),
                    ),
                  ),
                  child: Text(_outputs[i],
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
                ),
              );
            }),
          ),
        ],
      );

  Widget _accessibilityToggle() => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.hearing, size: 18, color: hex(_descriptiveAudio ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audio Description',
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 12)),
                  Text('Narrated descriptions of visual elements',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Switch(
              value: _descriptiveAudio,
              activeTrackColor: hex(AppColors.primary),
              onChanged: (v) {
                setState(() => _descriptiveAudio = v);
                _save();
              },
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
                'Switch between audio languages and formats. Select an output device and enable audio descriptions for accessibility. Settings saved locally.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
