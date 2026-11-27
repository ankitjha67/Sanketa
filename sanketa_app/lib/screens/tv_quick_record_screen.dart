import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvQuickRecordScreen extends StatefulWidget {
  const TvQuickRecordScreen({super.key});

  @override
  State<TvQuickRecordScreen> createState() => _TvQuickRecordScreenState();
}

class _TvQuickRecordScreenState extends State<TvQuickRecordScreen> {
  bool _recording = false;
  final String _currentChannel = '203';
  final List<_Recording> _recordings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_quick_records.json');
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _recordings.clear();
          for (final r in list) {
            final m = r as Map<String, dynamic>;
            _recordings.add(_Recording(
              m['channel'] as String? ?? '',
              m['name'] as String? ?? '',
              m['duration'] as String? ?? '',
              m['status'] as String? ?? 'completed',
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_quick_records.json');
      await f.writeAsString(jsonEncode(_recordings
          .map((r) => {
                'channel': r.channel,
                'name': r.name,
                'duration': r.duration,
                'status': r.status,
              })
          .toList()));
    } catch (_) {}
  }

  void _toggleRecording() {
    if (_recording) {
      setState(() {
        _recording = false;
        _recordings.insert(
            0,
            _Recording(
              _currentChannel,
              'CH $_currentChannel Recording',
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              'completed',
            ));
      });
      _save();
      RemoteScope.of(context).launch('record:stop');
    } else {
      setState(() => _recording = true);
      RemoteScope.of(context).launch('record:start:$_currentChannel');
    }
    HapticFeedback.heavyImpact();
  }

  void _deleteRecording(int idx) {
    setState(() => _recordings.removeAt(idx));
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Record',
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
          _recordButton(),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          Text('Recordings',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          if (_recordings.isEmpty)
            _emptyState()
          else
            ..._recordings.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _recordingTile(e.key, e.value),
                )),
          const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.fiber_manual_record,
                size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('Quick Record',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'One-tap recording of the current channel to TV storage',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _recordButton() => GestureDetector(
        onTap: _toggleRecording,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(_recording ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color:
                    hex(_recording ? AppColors.error : AppColors.signalEmerald)
                        .withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _recording ? Icons.stop : Icons.fiber_manual_record,
                size: 28,
                color:
                    hex(_recording ? AppColors.error : AppColors.signalEmerald),
              ),
              const SizedBox(width: 10),
              Text(
                _recording ? 'Stop Recording' : 'Record Now',
                style: gfont(AppType.bodyMd,
                    color: hex(
                        _recording ? AppColors.error : AppColors.signalEmerald),
                    weight: FontWeight.w700,
                    size: 16),
              ),
            ],
          ),
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _stat('Recordings', '${_recordings.length}', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat(
              'Status',
              _recording ? 'REC' : 'Idle',
              _recording ? AppColors.error : AppColors.signalEmerald),
        ],
      );

  Widget _stat(String label, String val, int c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(c).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Text(val,
                  style: gfont(AppType.bodyMd,
                      color: hex(c), size: 14, weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _recordingTile(int idx, _Recording r) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.videocam,
                size: 22, color: hex(AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text('CH ${r.channel} at ${r.duration}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(r.status,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600,
                      size: 9)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteRecording(idx),
              child:
                  Icon(Icons.close, size: 16, color: hex(AppColors.error)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.videocam_off,
                size: 48, color: hex(AppColors.outlineVariant)),
            const SizedBox(height: 8),
            Text('No recordings yet',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline), size: 13)),
            Text('Tap Record Now to start',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
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
                'One-tap recording of live TV. Recordings saved to TV storage. '
                'Manage and delete from here. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Recording {
  String channel;
  String name;
  String duration;
  String status;
  _Recording(this.channel, this.name, this.duration, this.status);
}
