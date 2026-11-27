import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenRecordScreen extends StatefulWidget {
  const ScreenRecordScreen({super.key});

  @override
  State<ScreenRecordScreen> createState() => _ScreenRecordScreenState();
}

class _ScreenRecordScreenState extends State<ScreenRecordScreen> {
  bool _recording = false;
  int _quality = 1;
  bool _audioEnabled = true;
  bool _micEnabled = false;
  int _elapsed = 0;

  static const _qualities = <(String, String, int)>[
    ('720p', 'SD', AppColors.outline),
    ('1080p', 'HD', AppColors.primary),
    ('4K', 'Ultra HD', AppColors.signalEmerald),
  ];

  final _recordings = <_Recording>[
    _Recording(name: 'Clip_001.mp4', duration: '2:34', size: '45 MB', date: '2026-11-27'),
    _Recording(name: 'Clip_002.mp4', duration: '5:12', size: '92 MB', date: '2026-11-26'),
    _Recording(name: 'Clip_003.mp4', duration: '0:48', size: '12 MB', date: '2026-11-25'),
  ];

  void _toggleRecording() {
    final rc = RemoteScope.of(context);
    if (_recording) {
      rc.key(core.Key.ok);
      setState(() {
        _recording = false;
        _recordings.insert(
            0,
            _Recording(
              name: 'Clip_${_recordings.length + 1}.mp4',
              duration: _formatTime(_elapsed),
              size: '${(_elapsed * 0.3).ceil()} MB',
              date: '2026-11-27',
            ));
        _elapsed = 0;
      });
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Recording saved'),
          duration: Duration(seconds: 2),
        ));
    } else {
      rc.key(core.Key.ok);
      setState(() => _recording = true);
      HapticFeedback.mediumImpact();
      _tick();
    }
  }

  void _tick() {
    if (!_recording || !mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (_recording && mounted) {
        setState(() => _elapsed++);
        _tick();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Screen Record',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _recordCard(),
          const SizedBox(height: AppSpacing.lg),
          _qualityPicker(),
          const SizedBox(height: AppSpacing.md),
          _audioToggles(),
          const SizedBox(height: AppSpacing.md),
          _recordButton(),
          const SizedBox(height: AppSpacing.lg),
          if (_recordings.isNotEmpty) ...[
            _recordingsLabel(),
            const SizedBox(height: AppSpacing.sm),
            ..._recordings.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _recordingCard(r),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _recordCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 32, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_recording ? AppColors.error : AppColors.error)
              .withValues(alpha: _recording ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.error)
                  .withValues(alpha: _recording ? 0.4 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(
                _recording
                    ? Icons.fiber_manual_record
                    : Icons.videocam,
                size: 56,
                color: hex(AppColors.error)),
            const SizedBox(height: 8),
            if (_recording)
              Text(_formatTime(_elapsed),
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.error),
                      size: 36,
                      weight: FontWeight.w700))
            else
              Text('Ready to Record',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              _recording
                  ? 'Recording in progress...'
                  : 'Capture your TV screen via ADB screenrecord',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _qualityPicker() => Row(
        children: _qualities.asMap().entries.map((e) {
          final active = e.key == _quality;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: _recording
                    ? null
                    : () {
                        setState(() => _quality = e.key);
                        HapticFeedback.selectionClick();
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? e.value.$3
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? e.value.$3
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(e.value.$1,
                          style: gfont(AppType.bodyMd,
                              color: hex(active
                                  ? e.value.$3
                                  : AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 14)),
                      Text(e.value.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _audioToggles() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _recording
                  ? null
                  : () {
                      setState(() => _audioEnabled = !_audioEnabled);
                      HapticFeedback.selectionClick();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(_audioEnabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(_audioEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _audioEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        size: 18,
                        color: hex(_audioEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline)),
                    const SizedBox(width: 6),
                    Text('TV Audio',
                        style: gfont(AppType.bodySm,
                            color: hex(_audioEnabled
                                ? AppColors.signalEmerald
                                : AppColors.outline),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: _recording
                  ? null
                  : () {
                      setState(() => _micEnabled = !_micEnabled);
                      HapticFeedback.selectionClick();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(_micEnabled
                          ? AppColors.secondary
                          : AppColors.outline)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(_micEnabled
                            ? AppColors.secondary
                            : AppColors.outline)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_micEnabled ? Icons.mic : Icons.mic_off,
                        size: 18,
                        color: hex(_micEnabled
                            ? AppColors.secondary
                            : AppColors.outline)),
                    const SizedBox(width: 6),
                    Text('Phone Mic',
                        style: gfont(AppType.bodySm,
                            color: hex(_micEnabled
                                ? AppColors.secondary
                                : AppColors.outline),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _recordButton() => GestureDetector(
        onTap: _toggleRecording,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(_recording ? AppColors.error : AppColors.error)
                .withValues(alpha: _recording ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.error)
                    .withValues(alpha: _recording ? 0.5 : 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  _recording ? Icons.stop : Icons.fiber_manual_record,
                  size: 24,
                  color: hex(AppColors.error)),
              const SizedBox(width: 8),
              Text(_recording ? 'Stop Recording' : 'Start Recording',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w700,
                      size: 15)),
            ],
          ),
        ),
      );

  Widget _recordingsLabel() => Text('Saved Recordings',
      style: gfont(AppType.bodyMd,
          color: hex(AppColors.onSurface),
          weight: FontWeight.w600,
          size: 13));

  Widget _recordingCard(_Recording r) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(Icons.videocam,
                  size: 20, color: hex(AppColors.error)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Row(
                    children: [
                      Text(r.duration,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      const SizedBox(width: 8),
                      Text(r.size,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      const SizedBox(width: 8),
                      Text(r.date,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline,
                size: 24, color: hex(AppColors.primary)),
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
                'Record your TV screen via ADB screenrecord. '
                'Choose quality, toggle audio sources. All files stay local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Recording {
  final String name;
  final String duration;
  final String size;
  final String date;
  _Recording({
    required this.name,
    required this.duration,
    required this.size,
    required this.date,
  });
}
