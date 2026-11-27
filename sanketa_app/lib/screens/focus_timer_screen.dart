import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  int _presetIndex = 0;
  int _remainingSec = 25 * 60;
  bool _running = false;
  bool _onBreak = false;
  int _sessionsCompleted = 0;
  int _totalFocusMin = 0;
  Timer? _timer;

  static const _presets = [
    ('Short', 25, Icons.timer, AppColors.primary),
    ('Long', 50, Icons.hourglass_bottom, AppColors.secondary),
    ('Deep', 90, Icons.self_improvement, AppColors.tertiary),
  ];

  static const _breakMin = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/focus_timer.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        setState(() {
          _sessionsCompleted = (data['sessions'] as num?)?.toInt() ?? 0;
          _totalFocusMin = (data['totalMin'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file;
      await f.writeAsString(jsonEncode({
        'sessions': _sessionsCompleted,
        'totalMin': _totalFocusMin,
      }));
    } catch (_) {}
  }

  void _start() {
    setState(() {
      _running = true;
      _onBreak = false;
      _remainingSec = _presets[_presetIndex].$2 * 60;
    });
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSec <= 0) {
        _timer?.cancel();
        if (_onBreak) {
          setState(() {
            _running = false;
            _onBreak = false;
          });
          HapticFeedback.heavyImpact();
        } else {
          setState(() {
            _sessionsCompleted++;
            _totalFocusMin += _presets[_presetIndex].$2;
            _onBreak = true;
            _remainingSec = _breakMin * 60;
          });
          _save();
          HapticFeedback.heavyImpact();
          // Auto-pause TV on break
          final rc = RemoteScope.of(context);
          rc.key(core.Key.ok);
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (_remainingSec <= 0) {
              _timer?.cancel();
              setState(() {
                _running = false;
                _onBreak = false;
              });
              HapticFeedback.heavyImpact();
              return;
            }
            setState(() => _remainingSec--);
          });
        }
        return;
      }
      setState(() => _remainingSec--);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _onBreak = false;
      _remainingSec = _presets[_presetIndex].$2 * 60;
    });
    HapticFeedback.selectionClick();
  }

  void _selectPreset(int idx) {
    if (_running) return;
    setState(() {
      _presetIndex = idx;
      _remainingSec = _presets[idx].$2 * 60;
    });
    HapticFeedback.selectionClick();
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _onBreak ? _breakMin * 60 : _presets[_presetIndex].$2 * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSec / total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Focus Timer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _countdownRing(),
          const SizedBox(height: AppSpacing.md),
          _statusBadge(),
          const SizedBox(height: AppSpacing.lg),
          Text('Duration Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _presetRow(),
          const SizedBox(height: AppSpacing.lg),
          _controlButton(),
          const SizedBox(height: AppSpacing.lg),
          _statsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.self_improvement,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Deep Focus',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Pomodoro-style timer with break reminders and auto-pause TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _countdownRing() => Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _running ? _progress : 0,
                  strokeWidth: 8,
                  backgroundColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(hex(
                      _onBreak ? AppColors.signalEmerald : AppColors.primary)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_fmt(_remainingSec),
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 36,
                          weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    _onBreak
                        ? 'Break'
                        : _running
                            ? 'Focus'
                            : '${_presets[_presetIndex].$2} min',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _statusBadge() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: hex(_onBreak
                    ? AppColors.signalEmerald
                    : _running
                        ? AppColors.primary
                        : AppColors.outline)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Text(
            _onBreak
                ? 'Break Time — TV Paused'
                : _running
                    ? 'Focusing...'
                    : 'Ready',
            style: gfont(AppType.bodySm,
                color: hex(_onBreak
                    ? AppColors.signalEmerald
                    : _running
                        ? AppColors.primary
                        : AppColors.outline),
                weight: FontWeight.w600,
                size: 10),
          ),
        ),
      );

  Widget _presetRow() => Row(
        children: _presets.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _presetIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 4, right: e.key == 2 ? 0 : 4),
              child: GestureDetector(
                onTap: () => _selectPreset(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        hex(active ? p.$4 : AppColors.surfaceContainerLow)
                            .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? p.$4 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$3, size: 20, color: hex(p.$4)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                      Text('${p.$2} min',
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

  Widget _controlButton() => GestureDetector(
        onTap: _running ? _stop : _start,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                hex(_running ? AppColors.alertAmber : AppColors.signalEmerald)
                    .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color:
                  hex(_running ? AppColors.alertAmber : AppColors.signalEmerald)
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_running ? Icons.stop : Icons.play_arrow,
                  size: 20,
                  color: hex(_running
                      ? AppColors.alertAmber
                      : AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text(_running ? 'Stop' : 'Start Focus',
                  style: gfont(AppType.bodyMd,
                      color: hex(_running
                          ? AppColors.alertAmber
                          : AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _statsCard() => Container(
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
            Text('Focus Stats',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                _statTile('Sessions', '$_sessionsCompleted',
                    AppColors.primary),
                const SizedBox(width: 8),
                _statTile(
                    'Total', '${_totalFocusMin}m', AppColors.secondary),
                const SizedBox(width: 8),
                _statTile(
                    'Avg',
                    _sessionsCompleted > 0
                        ? '${(_totalFocusMin / _sessionsCompleted).round()}m'
                        : '0m',
                    AppColors.tertiary),
              ],
            ),
          ],
        ),
      );

  Widget _statTile(String label, String value, int col) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: hex(col).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            children: [
              Text(value,
                  style: gfont(AppType.bodyMd,
                      color: hex(col),
                      weight: FontWeight.w700,
                      size: 16)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
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
                'Pomodoro focus timer with auto-pause TV on breaks. Pick 25, 50, or 90 minute sessions. Stats persist across sessions.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
