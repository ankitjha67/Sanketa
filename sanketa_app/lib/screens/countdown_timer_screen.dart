import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class CountdownTimerScreen extends StatefulWidget {
  const CountdownTimerScreen({super.key});

  @override
  State<CountdownTimerScreen> createState() => _CountdownTimerScreenState();
}

class _CountdownTimerScreenState extends State<CountdownTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Duration _total = Duration.zero;
  bool _running = false;
  bool _stopwatchMode = false;
  Duration _stopwatchElapsed = Duration.zero;
  final List<Duration> _laps = [];
  int _presetIndex = -1;
  bool _autoPowerOff = false;

  static const _presets = [
    ('1 min', Duration(minutes: 1)),
    ('5 min', Duration(minutes: 5)),
    ('10 min', Duration(minutes: 10)),
    ('15 min', Duration(minutes: 15)),
    ('30 min', Duration(minutes: 30)),
    ('60 min', Duration(minutes: 60)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addListener(_tick);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_stopwatchMode) {
        _onCountdownFinished();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (_stopwatchMode) {
      setState(() {
        _stopwatchElapsed =
            Duration(milliseconds: (_ctrl.value * 3600000).round());
      });
    } else {
      setState(() {});
    }
  }

  Duration get _remaining {
    if (_total == Duration.zero) return Duration.zero;
    final fraction = 1.0 - _ctrl.value;
    return Duration(
        milliseconds: (fraction * _total.inMilliseconds).round());
  }

  void _selectPreset(int i) {
    if (_running) return;
    setState(() {
      _presetIndex = i;
      _total = _presets[i].$2;
      _stopwatchMode = false;
    });
  }

  void _startCountdown() {
    if (_total == Duration.zero && !_stopwatchMode) return;
    setState(() => _running = true);
    if (_stopwatchMode) {
      _ctrl.duration = const Duration(hours: 1);
      _ctrl.forward(from: _stopwatchElapsed.inMilliseconds / 3600000);
    } else {
      _ctrl.duration = _total;
      _ctrl.forward(from: _ctrl.value);
    }
  }

  void _pause() {
    _ctrl.stop();
    setState(() => _running = false);
  }

  void _reset() {
    _ctrl.stop();
    _ctrl.reset();
    setState(() {
      _running = false;
      _stopwatchElapsed = Duration.zero;
      _laps.clear();
    });
  }

  void _toggleMode() {
    if (_running) return;
    _reset();
    setState(() {
      _stopwatchMode = !_stopwatchMode;
      _presetIndex = -1;
      _total = Duration.zero;
    });
  }

  void _lap() {
    if (!_stopwatchMode || !_running) return;
    setState(() => _laps.insert(0, _stopwatchElapsed));
  }

  void _onCountdownFinished() {
    setState(() => _running = false);
    if (_autoPowerOff) {
      final rc = RemoteScope.of(context);
      rc.key(core.Key.power);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_autoPowerOff ? 'Timer done — TV powered off' : 'Timer done!'),
        duration: const Duration(seconds: 3),
      ));
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Countdown Timer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _toggleMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _stopwatchMode ? Icons.timer : Icons.timer_outlined,
                size: 20,
                color: hex(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _timerDisplay(),
          const SizedBox(height: AppSpacing.md),
          _controls(),
          const SizedBox(height: AppSpacing.md),
          if (!_stopwatchMode) ...[
            _presetsGrid(),
            const SizedBox(height: AppSpacing.md),
            _autoPowerOffToggle(),
          ],
          if (_stopwatchMode && _laps.isNotEmpty) ...[
            _lapsList(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _timerDisplay() {
    final display =
        _stopwatchMode ? _fmtDuration(_stopwatchElapsed) : _fmtDuration(_remaining);
    final progress = _stopwatchMode
        ? (_stopwatchElapsed.inSeconds / 3600).clamp(0.0, 1.0)
        : (_total == Duration.zero ? 0.0 : _ctrl.value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(_stopwatchMode ? 'Stopwatch' : 'Countdown',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline),
                  size: 11,
                  weight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                    color: hex(_running
                        ? AppColors.primary
                        : AppColors.outline),
                  ),
                ),
                Text(display,
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 36,
                        weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlBtn(Icons.replay, 'Reset', _reset),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _running ? _pause : _startCountdown,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hex(_running ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _running ? Icons.pause : Icons.play_arrow,
                size: 28,
                color: hex(_running ? AppColors.error : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (_stopwatchMode)
            _ctrlBtn(Icons.flag, 'Lap', _lap)
          else
            const SizedBox(width: 48),
        ],
      );

  Widget _ctrlBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: hex(AppColors.onSurface)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _presetsGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presets.length, (i) {
              final active = i == _presetIndex;
              return GestureDetector(
                onTap: () => _selectPreset(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.5 : 0.2),
                    ),
                  ),
                  child: Text(_presets[i].$1,
                      style: gfont(AppType.bodySm,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              );
            }),
          ),
        ],
      );

  Widget _autoPowerOffToggle() => GestureDetector(
        onTap: () => setState(() => _autoPowerOff = !_autoPowerOff),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.power_settings_new,
                  size: 18,
                  color: hex(
                      _autoPowerOff ? AppColors.primary : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto Power Off',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Turn off TV when timer ends',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Switch(
                value: _autoPowerOff,
                activeTrackColor: hex(AppColors.primary),
                onChanged: (v) => setState(() => _autoPowerOff = v),
              ),
            ],
          ),
        ),
      );

  Widget _lapsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Laps (${_laps.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._laps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      Text('Lap ${_laps.length - e.key}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline),
                              size: 11,
                              weight: FontWeight.w600)),
                      const Spacer(),
                      Text(_fmtDuration(e.value),
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 13)),
                    ],
                  ),
                ),
              )),
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
                'Countdown timer with optional auto power-off. Use stopwatch mode (tap clock icon) for lap tracking. All timing runs locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
