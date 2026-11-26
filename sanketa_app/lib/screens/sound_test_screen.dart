import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundTestScreen extends StatefulWidget {
  const SoundTestScreen({super.key});

  @override
  State<SoundTestScreen> createState() => _SoundTestScreenState();
}

class _SoundTestScreenState extends State<SoundTestScreen> {
  int _playingChannel = -1;
  int _selectedTest = 0;

  static const _channels = <(String, IconData, int)>[
    ('Front Left', Icons.speaker, AppColors.primary),
    ('Front Right', Icons.speaker, AppColors.secondary),
    ('Center', Icons.speaker_group, AppColors.alertAmber),
    ('Subwoofer', Icons.graphic_eq, AppColors.error),
    ('Surround L', Icons.surround_sound, AppColors.tertiary),
    ('Surround R', Icons.surround_sound, AppColors.signalEmerald),
  ];

  static const _tests = <(String, String, IconData)>[
    ('Individual', 'Test one speaker at a time', Icons.speaker),
    ('Sweep', 'Auto-cycle through all speakers', Icons.autorenew),
    ('Pink Noise', 'Calibration noise on all channels', Icons.waves),
    ('Bass Test', 'Low frequency subwoofer check', Icons.graphic_eq),
  ];

  void _playChannel(int i) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _playingChannel = _playingChannel == i ? -1 : i);
    if (_playingChannel >= 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Testing: ${_channels[i].$1}'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  void _runTest(int i) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _selectedTest = i);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Running: ${_tests[i].$1} test'),
        duration: const Duration(seconds: 2),
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
        title: Text('Sound Test',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _testModes(),
          const SizedBox(height: AppSpacing.md),
          _speakerLayout(),
          const SizedBox(height: AppSpacing.md),
          _channelList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.surround_sound, size: 36, color: hex(AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Speaker Test',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.secondary), weight: FontWeight.w600)),
                  Text('Test each speaker channel individually',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _testModes() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test Mode',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_tests.length, (i) {
              final t = _tests[i];
              final active = i == _selectedTest;
              return GestureDetector(
                onTap: () => _runTest(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.secondary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? AppColors.secondary : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.5 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$3, size: 14,
                          color: hex(active ? AppColors.secondary : AppColors.outline)),
                      const SizedBox(width: 6),
                      Text(t.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.secondary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      );

  Widget _speakerLayout() => Container(
        height: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Stack(
          children: [
            Positioned(top: 10, left: 20, child: _dot('FL', 0)),
            Positioned(top: 10, right: 20, child: _dot('FR', 1)),
            Positioned(top: 10, left: 0, right: 0, child: Center(child: _dot('C', 2))),
            Positioned(bottom: 10, left: 0, right: 0, child: Center(child: _dot('SUB', 3))),
            Positioned(bottom: 30, left: 20, child: _dot('SL', 4)),
            Positioned(bottom: 30, right: 20, child: _dot('SR', 5)),
            Positioned(
              top: 55,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(Icons.tv, size: 40,
                    color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      );

  Widget _dot(String label, int idx) {
    final playing = _playingChannel == idx;
    return GestureDetector(
      onTap: () => _playChannel(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: hex(_channels[idx].$3).withValues(alpha: playing ? 0.3 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: hex(_channels[idx].$3).withValues(alpha: playing ? 0.8 : 0.3),
                width: playing ? 2 : 1,
              ),
            ),
            child: Center(
              child: playing
                  ? Icon(Icons.volume_up, size: 12, color: hex(_channels[idx].$3))
                  : Text(label,
                      style: gfont(AppType.bodySm,
                          color: hex(_channels[idx].$3), size: 7, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_channels.length, (i) {
            final c = _channels[i];
            final playing = _playingChannel == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _playChannel(i),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(playing ? c.$3 : AppColors.surfaceContainerLow)
                        .withValues(alpha: playing ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(playing ? c.$3 : AppColors.outlineVariant)
                          .withValues(alpha: playing ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(c.$2, size: 20, color: hex(c.$3)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600, size: 12)),
                      ),
                      Icon(playing ? Icons.stop_circle : Icons.play_circle,
                          size: 22, color: hex(c.$3)),
                    ],
                  ),
                ),
              ),
            );
          }),
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
                'Test each speaker in your surround sound setup. Tap a channel to send a test tone. Use the speaker diagram to visualize your setup.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
