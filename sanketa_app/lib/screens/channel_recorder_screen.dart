import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Recording {
  _Recording({
    required this.channel,
    required this.name,
    required this.date,
    required this.startTime,
    required this.duration,
    this.repeat = 'Once',
    this.enabled = true,
  });

  factory _Recording.fromJson(Map<String, dynamic> j) => _Recording(
        channel: j['channel'] as String,
        name: j['name'] as String,
        date: j['date'] as String,
        startTime: j['startTime'] as String,
        duration: j['duration'] as int,
        repeat: j['repeat'] as String? ?? 'Once',
        enabled: j['enabled'] as bool? ?? true,
      );

  final String channel;
  final String name;
  final String date;
  final String startTime;
  final int duration;
  final String repeat;
  bool enabled;

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'name': name,
        'date': date,
        'startTime': startTime,
        'duration': duration,
        'repeat': repeat,
        'enabled': enabled,
      };
}

class ChannelRecorderScreen extends StatefulWidget {
  const ChannelRecorderScreen({super.key});

  @override
  State<ChannelRecorderScreen> createState() => _ChannelRecorderScreenState();
}

class _ChannelRecorderScreenState extends State<ChannelRecorderScreen> {
  List<_Recording> _recordings = [];
  bool _loading = true;

  final _channelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  int _durationMin = 30;
  String _repeat = 'Once';

  static const _durations = [15, 30, 60, 90, 120, 180];
  static const _repeats = ['Once', 'Daily', 'Weekly', 'Weekdays'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _channelCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_recordings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _recordings = list.map((j) => _Recording.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_recordings.map((r) => r.toJson()).toList()));
  }

  void _addRecording() {
    if (_channelCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;
    if (_recordings.length >= 20) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Maximum 20 recordings')));
      return;
    }
    final now = DateTime.now();
    setState(() {
      _recordings.insert(
        0,
        _Recording(
          channel: _channelCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          startTime: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          duration: _durationMin,
          repeat: _repeat,
        ),
      );
    });
    _channelCtrl.clear();
    _nameCtrl.clear();
    _save();
  }

  void _delete(int i) {
    setState(() => _recordings.removeAt(i));
    _save();
  }

  void _toggleEnabled(int i) {
    setState(() => _recordings[i].enabled = !_recordings[i].enabled);
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
        title: Text('Recorder',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _addForm(),
          const SizedBox(height: AppSpacing.md),
          if (_recordings.isEmpty)
            _emptyState()
          else ...[
            Text('Scheduled (${_recordings.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._recordings.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _recordingRow(e.key, e.value),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, size: 32, color: hex(AppColors.error)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Channel Recorder',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.error), weight: FontWeight.w600)),
                  Text('Schedule recordings for TV channels',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _addForm() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Recording',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _channelCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Channel #',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Programme name',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration',
                          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _durations.map((d) {
                          final active = d == _durationMin;
                          return GestureDetector(
                            onTap: () => setState(() => _durationMin = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                                    .withValues(alpha: active ? 0.15 : 1),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Text('${d}m',
                                  style: gfont(AppType.bodySm,
                                      color: hex(active ? AppColors.primary : AppColors.onSurface),
                                      size: 9, weight: active ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Repeat: ', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                ..._repeats.map((r) {
                  final active = r == _repeat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _repeat = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                              .withValues(alpha: active ? 0.15 : 1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(r,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.onSurface),
                                size: 9, weight: active ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addRecording,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 14, color: hex(AppColors.error)),
                    const SizedBox(width: 6),
                    Text('Schedule Recording',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.error), weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _recordingRow(int i, _Recording r) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(r.enabled ? AppColors.error : AppColors.outlineVariant)
                .withValues(alpha: r.enabled ? 0.3 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record,
                size: 14, color: hex(r.enabled ? AppColors.error : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ch ${r.channel} · ${r.name}',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600, size: 11)),
                  Text('${r.date} ${r.startTime} · ${r.duration}min · ${r.repeat}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleEnabled(i),
              child: Icon(
                r.enabled ? Icons.pause_circle : Icons.play_circle,
                size: 20,
                color: hex(r.enabled ? AppColors.alertAmber : AppColors.signalEmerald),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _delete(i),
              child: Icon(Icons.delete_outline, size: 18, color: hex(AppColors.error)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.fiber_manual_record, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No recordings scheduled',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add a channel and programme to get started.',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
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
                'Schedule recordings for your TV channels. Set duration, repeat options, and enable/disable individual recordings. All schedules saved locally on your phone.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
