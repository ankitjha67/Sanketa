import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteMacroRecordScreen extends StatefulWidget {
  const RemoteMacroRecordScreen({super.key});

  @override
  State<RemoteMacroRecordScreen> createState() =>
      _RemoteMacroRecordScreenState();
}

class _RemoteMacroRecordScreenState extends State<RemoteMacroRecordScreen> {
  final List<_Macro> _macros = [];
  bool _recording = false;
  List<String> _currentSteps = [];
  String _currentName = '';

  static const _keyMap = <String, core.Key>{
    'power': core.Key.power,
    'mute': core.Key.mute,
    'home': core.Key.home,
    'back': core.Key.back,
    'menu': core.Key.menu,
    'ok': core.Key.ok,
    'up': core.Key.up,
    'down': core.Key.down,
    'left': core.Key.left,
    'right': core.Key.right,
    'volumeUp': core.Key.volumeUp,
    'volumeDown': core.Key.volumeDown,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/macro_recordings.json');
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _macros.clear();
          for (final m in list) {
            final map = m as Map<String, dynamic>;
            _macros.add(_Macro(
              map['name'] as String? ?? '',
              (map['steps'] as List<dynamic>?)
                      ?.map((s) => s as String)
                      .toList() ??
                  [],
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/macro_recordings.json');
      await f.writeAsString(jsonEncode(_macros
          .map((m) => {'name': m.name, 'steps': m.steps})
          .toList()));
    } catch (_) {}
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _currentSteps = [];
      _currentName = 'Macro ${_macros.length + 1}';
    });
    HapticFeedback.heavyImpact();
  }

  void _stopRecording() {
    if (_currentSteps.isNotEmpty) {
      setState(() {
        _macros.insert(0, _Macro(_currentName, List.from(_currentSteps)));
        _recording = false;
        _currentSteps = [];
      });
      _save();
    } else {
      setState(() {
        _recording = false;
        _currentSteps = [];
      });
    }
    HapticFeedback.heavyImpact();
  }

  void _recordKey(String keyName) {
    if (!_recording) return;
    final k = _keyMap[keyName];
    if (k != null) {
      RemoteScope.of(context).key(k);
      setState(() => _currentSteps.add(keyName));
      HapticFeedback.lightImpact();
    }
  }

  void _playMacro(int idx) {
    final rc = RemoteScope.of(context);
    for (final step in _macros[idx].steps) {
      final k = _keyMap[step];
      if (k != null) rc.key(k);
    }
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Playing "${_macros[idx].name}" (${_macros[idx].steps.length} steps)'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _deleteMacro(int idx) {
    setState(() => _macros.removeAt(idx));
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
        title: Text('Macro Recorder',
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
          if (_recording) ...[
            const SizedBox(height: AppSpacing.md),
            _recordingPanel(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          if (_macros.isEmpty)
            _emptyState()
          else
            ..._macros.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _macroCard(e.key, e.value),
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
            Text('Macro Recorder',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Record key sequences and replay them with one tap',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _recordButton() => GestureDetector(
        onTap: _recording ? _stopRecording : _startRecording,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                size: 24,
                color:
                    hex(_recording ? AppColors.error : AppColors.signalEmerald),
              ),
              const SizedBox(width: 8),
              Text(
                _recording ? 'Stop Recording' : 'Start Recording',
                style: gfont(AppType.bodyMd,
                    color: hex(
                        _recording ? AppColors.error : AppColors.signalEmerald),
                    weight: FontWeight.w600,
                    size: 14),
              ),
            ],
          ),
        ),
      );

  Widget _recordingPanel() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border:
              Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fiber_manual_record,
                    size: 12, color: hex(AppColors.error)),
                const SizedBox(width: 6),
                Text('Recording... ${_currentSteps.length} steps',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _keyMap.keys.map((k) {
                return GestureDetector(
                  onTap: () => _recordKey(k),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color:
                              hex(AppColors.primary).withValues(alpha: 0.2)),
                    ),
                    child: Text(k,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w500,
                            size: 10)),
                  ),
                );
              }).toList(),
            ),
            if (_currentSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_currentSteps.join(' > '),
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _stat('Macros', '${_macros.length}', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat(
              'Total Steps',
              '${_macros.fold(0, (s, m) => s + m.steps.length)}',
              AppColors.signalEmerald),
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
                  style: gfont(AppType.headlineMd,
                      color: hex(c), size: 18, weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _macroCard(int idx, _Macro m) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border:
              Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _playMacro(idx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                ),
                child: Icon(Icons.play_arrow,
                    size: 20, color: hex(AppColors.signalEmerald)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text('${m.steps.length} steps: ${m.steps.take(5).join(', ')}${m.steps.length > 5 ? '...' : ''}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteMacro(idx),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.error)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.fiber_manual_record,
                size: 48, color: hex(AppColors.outlineVariant)),
            const SizedBox(height: 8),
            Text('No macros recorded',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline), size: 13)),
            Text('Tap Start Recording to begin',
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
                'Record key sequences and replay them with one tap. '
                'Great for routine actions. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Macro {
  String name;
  List<String> steps;
  _Macro(this.name, this.steps);
}
