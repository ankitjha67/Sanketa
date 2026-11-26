import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Step {
  _Step({required this.action, this.delayMs = 500});

  factory _Step.fromJson(Map<String, dynamic> j) => _Step(
        action: j['action'] as String,
        delayMs: j['delayMs'] as int? ?? 500,
      );

  final String action;
  final int delayMs;

  Map<String, dynamic> toJson() => {'action': action, 'delayMs': delayMs};
}

class _Routine {
  _Routine({required this.name, required this.icon, List<_Step>? steps})
      : steps = steps ?? [];

  factory _Routine.fromJson(Map<String, dynamic> j) => _Routine(
        name: j['name'] as String,
        icon: j['icon'] as String? ?? 'play_arrow',
        steps: (j['steps'] as List?)
                ?.map((s) => _Step.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  final String name;
  final String icon;
  final List<_Step> steps;

  Map<String, dynamic> toJson() => {
        'name': name,
        'icon': icon,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  List<_Routine> _routines = [];
  bool _loading = true;
  bool _running = false;

  static const _presets = [
    ('Movie Night', 'movie', ['Power On', 'HDMI 1', 'Volume 25', 'Dim Lights']),
    ('Morning News', 'wb_sunny', ['Power On', 'Ch 7', 'Volume 15']),
    ('Gaming', 'sports_esports', ['Power On', 'HDMI 2', 'Game Mode', 'Volume 20']),
    ('Bedtime', 'bedtime', ['Volume 5', 'Sleep Timer 30m', 'Power Off']),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/routines.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _routines =
            list.map((j) => _Routine.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_routines.map((r) => r.toJson()).toList()));
  }

  void _addPreset(int idx) {
    final p = _presets[idx];
    final routine = _Routine(
      name: p.$1,
      icon: p.$2,
      steps: p.$3.map((a) => _Step(action: a)).toList(),
    );
    setState(() => _routines.add(routine));
    _save();
  }

  void _deleteRoutine(int idx) {
    setState(() => _routines.removeAt(idx));
    _save();
  }

  Future<void> _runRoutine(int idx) async {
    if (_running) return;
    setState(() => _running = true);
    HapticFeedback.mediumImpact();

    final routine = _routines[idx];
    final rc = RemoteScope.of(context);

    for (final step in routine.steps) {
      if (!mounted) break;
      _executeAction(rc, step.action);
      await Future.delayed(Duration(milliseconds: step.delayMs));
    }

    if (mounted) {
      setState(() => _running = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Routine "${routine.name}" completed'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  void _executeAction(RemoteController rc, String action) {
    switch (action) {
      case 'Power On':
      case 'Power Off':
        rc.key(core.Key.power);
      case 'Volume Up':
        rc.key(core.Key.volumeUp);
      case 'Volume Down':
        rc.key(core.Key.volumeDown);
      case 'Mute':
        rc.key(core.Key.mute);
      case 'Home':
        rc.key(core.Key.home);
      case 'Back':
        rc.key(core.Key.back);
      case 'OK':
        rc.key(core.Key.ok);
      case 'Menu':
        rc.key(core.Key.menu);
      case 'Ch Up':
        rc.key(core.Key.up);
      case 'Ch Down':
        rc.key(core.Key.down);
      default:
        if (action.startsWith('HDMI')) {
          rc.launch(action);
        } else if (action.startsWith('Volume')) {
          rc.key(core.Key.volumeUp);
        }
    }
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'movie':
        return Icons.movie;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'bedtime':
        return Icons.bedtime;
      default:
        return Icons.play_arrow;
    }
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
        title: Text('Routine Builder',
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
          if (_routines.isEmpty) ...[
            _emptyState(),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Text('My Routines (${_routines.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._routines.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _routineCard(e.value, e.key),
                )),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Quick Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._presets.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _presetCard(e.value, e.key),
              )),
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
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.auto_fix_high, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Automate Your TV',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Chain remote actions into one-tap routines for movie night, gaming, or bedtime',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.playlist_add, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No routines yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add a preset below to get started',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _routineCard(_Routine routine, int idx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(_iconFor(routine.icon),
                      size: 16, color: hex(AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 13)),
                      Text('${routine.steps.length} steps',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _runRoutine(idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        Text(_running ? 'Running' : 'Run',
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
                  onTap: () => _deleteRoutine(idx),
                  child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: routine.steps.map((s) => Container(
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
        ),
      );

  Widget _presetCard((String, String, List<String>) preset, int idx) =>
      GestureDetector(
        onTap: () => _addPreset(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(_iconFor(preset.$2), size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preset.$1,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text(preset.$3.join(' → '),
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline,
                  size: 20, color: hex(AppColors.primary)),
            ],
          ),
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
                'Build multi-step routines that chain remote actions together. Tap Run to execute all steps automatically with a short delay between each.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
