import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SleepRoutineScreen extends StatefulWidget {
  const SleepRoutineScreen({super.key});

  @override
  State<SleepRoutineScreen> createState() => _SleepRoutineScreenState();
}

class _SleepRoutineScreenState extends State<SleepRoutineScreen> {
  int _selectedRoutine = 0;
  bool _enabled = false;
  bool _loading = true;

  static const _routines = <(String, IconData, int, String, List<(String, String)>)>[
    ('Wind Down', Icons.nights_stay, AppColors.secondary, 'Gradually prepare for sleep', [
      ('Dim TV to 20%', '0:00'),
      ('Switch to calm channel', '5:00'),
      ('Reduce volume to 15%', '10:00'),
      ('Enable night mode', '15:00'),
      ('Power off TV', '30:00'),
    ]),
    ('Quick Sleep', Icons.bedtime, AppColors.tertiary, 'Fast power-down sequence', [
      ('Mute audio', '0:00'),
      ('Set sleep timer 10m', '0:05'),
      ('Dim to minimum', '0:10'),
      ('Power off TV', '10:00'),
    ]),
    ('Movie Fade', Icons.movie_filter, AppColors.primary, 'Gentle end to movie night', [
      ('Lower volume to 30%', '0:00'),
      ('Enable subtitles', '5:00'),
      ('Dim backlight', '15:00'),
      ('Volume to 10%', '25:00'),
      ('Sleep timer 15m', '30:00'),
      ('Power off TV', '45:00'),
    ]),
    ('Kids Bedtime', Icons.child_care, AppColors.alertAmber, 'Scheduled shutdown for children', [
      ('5-minute warning banner', '0:00'),
      ('Switch to calm content', '5:00'),
      ('Reduce volume', '8:00'),
      ('1-minute countdown', '9:00'),
      ('Power off TV', '10:00'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sleep_routine.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedRoutine = data['selectedRoutine'] as int? ?? 0;
        _enabled = data['enabled'] as bool? ?? false;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'selectedRoutine': _selectedRoutine,
      'enabled': _enabled,
    }));
  }

  void _startRoutine() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _enabled = true);
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_routines[_selectedRoutine].$1} routine started'),
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

    final routine = _routines[_selectedRoutine];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sleep Routine',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(routine),
          const SizedBox(height: AppSpacing.md),
          _routinePicker(),
          const SizedBox(height: AppSpacing.md),
          _stepsTimeline(routine),
          const SizedBox(height: AppSpacing.lg),
          _startButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard(
          (String, IconData, int, String, List<(String, String)>) r) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(r.$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(r.$3).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(r.$2, size: 48, color: hex(r.$3)),
            const SizedBox(height: 8),
            Text(r.$1,
                style: gfont(AppType.bodyMd,
                    color: hex(r.$3), weight: FontWeight.w700, size: 18)),
            const SizedBox(height: 4),
            Text(r.$4,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            if (_enabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Active',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ],
          ],
        ),
      );

  Widget _routinePicker() => Row(
        children: _routines.asMap().entries.map((e) {
          final r = e.value;
          final active = e.key == _selectedRoutine;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRoutine = e.key);
                _save();
              },
              child: Container(
                margin: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(active ? r.$3 : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hex(active ? r.$3 : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(r.$2,
                        size: 20,
                        color: hex(active ? r.$3 : AppColors.outline)),
                    const SizedBox(height: 2),
                    Text(r.$1,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? r.$3 : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 8)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _stepsTimeline(
          (String, IconData, int, String, List<(String, String)>) r) =>
      Container(
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
            Text('Steps',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...r.$5.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: hex(r.$3).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: gfont(AppType.bodySm,
                                  color: hex(r.$3),
                                  weight: FontWeight.w700,
                                  size: 10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(AppColors.outline).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(e.value.$2,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline),
                                weight: FontWeight.w500,
                                size: 9)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _startButton() => GestureDetector(
        onTap: _startRoutine,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime, size: 20, color: hex(AppColors.secondary)),
              const SizedBox(width: 8),
              Text('Start Routine',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.secondary),
                      weight: FontWeight.w600)),
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
                'Sleep routines gradually wind down your TV for better sleep. Choose a routine, start it before bed, and the TV handles the rest. Kids Bedtime enforces screen time limits.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
