import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class CastTimerScreen extends StatefulWidget {
  const CastTimerScreen({super.key});

  @override
  State<CastTimerScreen> createState() => _CastTimerScreenState();
}

class _CastTimerScreenState extends State<CastTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _presetIndex = -1;
  bool _running = false;
  int _actionIndex = 0;

  static const _presets = [
    ('15 min', Duration(minutes: 15)),
    ('30 min', Duration(minutes: 30)),
    ('45 min', Duration(minutes: 45)),
    ('1 hr', Duration(hours: 1)),
    ('1.5 hr', Duration(minutes: 90)),
    ('2 hr', Duration(hours: 2)),
  ];

  static const _actions = [
    ('Stop Cast', Icons.stop, 'Stops casting and returns to TV'),
    ('Power Off', Icons.power_settings_new, 'Turns off the TV'),
    ('Mute', Icons.volume_off, 'Mutes the TV audio'),
    ('Home', Icons.home, 'Returns to home screen'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onTimerDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Duration get _remaining {
    if (_presetIndex < 0) return Duration.zero;
    final total = _presets[_presetIndex].$2;
    final fraction = 1.0 - _ctrl.value;
    return Duration(
        milliseconds: (fraction * total.inMilliseconds).round());
  }

  void _selectPreset(int i) {
    if (_running) return;
    setState(() => _presetIndex = i);
  }

  void _start() {
    if (_presetIndex < 0) return;
    final duration = _presets[_presetIndex].$2;
    _ctrl.duration = duration;
    _ctrl.forward(from: 0);
    setState(() => _running = true);
  }

  void _cancel() {
    _ctrl.stop();
    _ctrl.reset();
    setState(() => _running = false);
  }

  void _onTimerDone() {
    setState(() => _running = false);
    final rc = RemoteScope.of(context);
    switch (_actionIndex) {
      case 0:
        rc.key(core.Key.back);
      case 1:
        rc.key(core.Key.power);
      case 2:
        rc.key(core.Key.mute);
      case 3:
        rc.key(core.Key.home);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Timer done — ${_actions[_actionIndex].$1}'),
        duration: const Duration(seconds: 3),
      ));
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
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
        title: Text('Cast Timer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _timerDisplay(),
            const SizedBox(height: AppSpacing.md),
            if (!_running) ...[
              _presetsSection(),
              const SizedBox(height: AppSpacing.md),
              _actionSelector(),
              const SizedBox(height: AppSpacing.md),
            ],
            _controlButton(),
            const SizedBox(height: AppSpacing.lg),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _timerDisplay() {
    final progress = _running ? _ctrl.value : 0.0;
    final display = _running ? _fmtDuration(_remaining) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: hex(_running
                ? AppColors.primary
                : AppColors.surfaceContainerLow)
            .withValues(alpha: _running ? 0.08 : 1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(_running ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: _running ? 0.3 : 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            _running ? Icons.cast_connected : Icons.cast,
            size: 32,
            color: hex(_running ? AppColors.primary : AppColors.outline),
          ),
          const SizedBox(height: 8),
          Text(_running ? 'Casting will stop in' : 'Set Cast Duration',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline),
                  size: 11,
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                    color: hex(AppColors.primary),
                  ),
                ),
                Text(display,
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 32,
                        weight: FontWeight.w700)),
              ],
            ),
          ),
          if (_running) ...[
            const SizedBox(height: 8),
            Text('Action: ${_actions[_actionIndex].$1}',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primary),
                    size: 10,
                    weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _presetsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                      style: gfont(AppType.bodyMd,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 12)),
                ),
              );
            }),
          ),
        ],
      );

  Widget _actionSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When Timer Ends',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_actions.length, (i) {
            final a = _actions[i];
            final active = i == _actionIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => setState(() => _actionIndex = i),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(a.$2,
                          size: 18,
                          color: hex(
                              active ? AppColors.primary : AppColors.outline)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 12)),
                            Text(a.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline),
                                    size: 10)),
                          ],
                        ),
                      ),
                      Icon(
                        active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: hex(
                            active ? AppColors.primary : AppColors.outline),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _controlButton() => GestureDetector(
        onTap: _running ? _cancel : _start,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_running ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_running ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _running ? Icons.stop : Icons.play_arrow,
                size: 20,
                color: hex(_running ? AppColors.error : AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                _running ? 'Cancel Timer' : 'Start Cast Timer',
                style: gfont(AppType.bodyMd,
                    color: hex(_running ? AppColors.error : AppColors.primary),
                    weight: FontWeight.w600),
              ),
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
                'Auto-stop casting after a set duration. Choose what happens when the timer ends — stop casting, power off, mute, or go home. Timer runs locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
