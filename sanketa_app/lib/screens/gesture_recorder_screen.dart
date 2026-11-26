import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _GestureStep {
  _GestureStep({required this.action, this.delayMs = 300});

  factory _GestureStep.fromJson(Map<String, dynamic> j) => _GestureStep(
        action: j['action'] as String,
        delayMs: j['delayMs'] as int? ?? 300,
      );

  final String action;
  final int delayMs;

  Map<String, dynamic> toJson() => {'action': action, 'delayMs': delayMs};
}

class _Recording {
  _Recording({required this.name, required this.steps});

  factory _Recording.fromJson(Map<String, dynamic> j) => _Recording(
        name: j['name'] as String,
        steps: (j['steps'] as List?)
                ?.map((s) => _GestureStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  final String name;
  final List<_GestureStep> steps;

  Map<String, dynamic> toJson() => {
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class GestureRecorderScreen extends StatefulWidget {
  const GestureRecorderScreen({super.key});

  @override
  State<GestureRecorderScreen> createState() => _GestureRecorderScreenState();
}

class _GestureRecorderScreenState extends State<GestureRecorderScreen> {
  List<_Recording> _recordings = [];
  bool _loading = true;
  bool _recording = false;
  bool _playing = false;
  List<_GestureStep> _currentSteps = [];
  final _nameCtrl = TextEditingController();

  static const _actions = [
    ('Up', Icons.arrow_upward, core.Key.up),
    ('Down', Icons.arrow_downward, core.Key.down),
    ('Left', Icons.arrow_back, core.Key.left),
    ('Right', Icons.arrow_forward, core.Key.right),
    ('OK', Icons.check_circle, core.Key.ok),
    ('Back', Icons.arrow_circle_left, core.Key.back),
    ('Home', Icons.home, core.Key.home),
    ('Menu', Icons.menu, core.Key.menu),
    ('Vol+', Icons.volume_up, core.Key.volumeUp),
    ('Vol-', Icons.volume_down, core.Key.volumeDown),
    ('Mute', Icons.volume_off, core.Key.mute),
    ('Power', Icons.power_settings_new, core.Key.power),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/gesture_recordings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _recordings =
            list.map((j) => _Recording.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_recordings.map((r) => r.toJson()).toList()));
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _currentSteps = [];
    });
    HapticFeedback.mediumImpact();
  }

  void _addStep(String action) {
    if (!_recording) return;
    final rc = RemoteScope.of(context);
    final match = _actions.firstWhere((a) => a.$1 == action);
    rc.key(match.$3);
    setState(() => _currentSteps.add(_GestureStep(action: action)));
    HapticFeedback.selectionClick();
  }

  void _stopRecording() {
    if (_currentSteps.isEmpty) {
      setState(() => _recording = false);
      return;
    }
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Recording ${_recordings.length + 1}'
        : _nameCtrl.text.trim();
    setState(() {
      _recording = false;
      _recordings.add(_Recording(name: name, steps: List.of(_currentSteps)));
      _currentSteps = [];
    });
    _nameCtrl.clear();
    _save();
  }

  Future<void> _playRecording(int idx) async {
    if (_playing) return;
    setState(() => _playing = true);
    HapticFeedback.mediumImpact();

    final rc = RemoteScope.of(context);
    for (final step in _recordings[idx].steps) {
      if (!mounted) break;
      final match = _actions.firstWhere((a) => a.$1 == step.action);
      rc.key(match.$3);
      await Future.delayed(Duration(milliseconds: step.delayMs));
    }

    if (mounted) {
      setState(() => _playing = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Played "${_recordings[idx].name}"'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  void _deleteRecording(int idx) {
    setState(() => _recordings.removeAt(idx));
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
        title: Text('Gesture Recorder',
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
          if (_recording) ...[
            _recordingPanel(),
            const SizedBox(height: AppSpacing.md),
            _actionGrid(),
            const SizedBox(height: AppSpacing.md),
            _stopButton(),
          ] else ...[
            _startButton(),
          ],
          const SizedBox(height: AppSpacing.md),
          if (_recordings.isNotEmpty) ...[
            Text('Saved Recordings (${_recordings.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._recordings.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _recordingCard(e.value, e.key),
                )),
          ] else
            _emptyState(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.fiber_manual_record, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Record & Replay',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Record custom gesture sequences and replay them with one tap',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _recordingPanel() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fiber_manual_record,
                    size: 14, color: hex(AppColors.error)),
                const SizedBox(width: 6),
                Text('Recording... (${_currentSteps.length} steps)',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600,
                        size: 13)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Recording name (optional)',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline).withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
            if (_currentSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _currentSteps.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hex(AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(s.action,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 9)),
                    )).toList(),
              ),
            ],
          ],
        ),
      );

  Widget _actionGrid() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _actions.map((a) => GestureDetector(
              onTap: () => _addStep(a.$1),
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(a.$2, size: 20, color: hex(AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(a.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface), size: 9)),
                  ],
                ),
              ),
            )).toList(),
      );

  Widget _startButton() => GestureDetector(
        onTap: _startRecording,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.error).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fiber_manual_record,
                  size: 20, color: hex(AppColors.error)),
              const SizedBox(width: 8),
              Text('Start Recording',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _stopButton() => GestureDetector(
        onTap: _stopRecording,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop, size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Stop & Save',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _recordingCard(_Recording rec, int idx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hex(AppColors.tertiary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.playlist_play,
                  size: 16, color: hex(AppColors.tertiary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rec.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 12)),
                  Text('${rec.steps.length} steps',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _playRecording(idx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow,
                        size: 14, color: hex(AppColors.signalEmerald)),
                    const SizedBox(width: 4),
                    Text(_playing ? 'Playing' : 'Play',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.signalEmerald),
                            weight: FontWeight.w600,
                            size: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteRecording(idx),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.fiber_manual_record, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No recordings yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap Start Recording, press remote buttons, then save',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
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
                'Record a sequence of button presses and save it as a gesture macro. Replay any recording with one tap to automate repetitive navigation.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
