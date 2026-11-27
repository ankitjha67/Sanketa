import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvTimerScreen extends StatefulWidget {
  const TvTimerScreen({super.key});

  @override
  State<TvTimerScreen> createState() => _TvTimerScreenState();
}

class _TvTimerScreenState extends State<TvTimerScreen> {
  int _selectedMin = 0;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;

  static const _presets = <(int, String, IconData, int)>[
    (15, '15 min', Icons.timer, AppColors.signalEmerald),
    (30, '30 min', Icons.timer, AppColors.primary),
    (45, '45 min', Icons.timer, AppColors.secondary),
    (60, '1 hour', Icons.hourglass_bottom, AppColors.tertiary),
    (90, '1.5 hrs', Icons.hourglass_bottom, AppColors.alertAmber),
    (120, '2 hours', Icons.hourglass_bottom, AppColors.error),
  ];

  static const _actions = <(String, IconData, core.Key, int)>[
    ('Power Off', Icons.power_settings_new, core.Key.power, AppColors.error),
    ('Mute', Icons.volume_off, core.Key.mute, AppColors.secondary),
    ('Go Home', Icons.home, core.Key.home, AppColors.primary),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_selectedMin == 0) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _remaining = _selectedMin * 60;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        final rc = RemoteScope.of(context);
        rc.key(core.Key.power);
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Timer done — TV powered off'),
            duration: Duration(seconds: 2),
          ));
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = 0;
    });
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_selectedMin == 0) return 0;
    return 1 - (_remaining / (_selectedMin * 60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Timer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _countdownCard(),
          const SizedBox(height: AppSpacing.md),
          _presetGrid(),
          const SizedBox(height: AppSpacing.md),
          _controlButton(),
          const SizedBox(height: AppSpacing.md),
          _quickActions(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _countdownCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_running ? AppColors.primary : AppColors.surfaceContainerHigh)
              .withValues(alpha: _running ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: hex(_running ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _running ? _progress : 0,
                      strokeWidth: 6,
                      color: hex(AppColors.primary),
                      backgroundColor:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                    ),
                  ),
                  Text(
                    _running ? _timeStr : '—:—',
                    style: gfont(AppType.headlineMd,
                        color: hex(_running
                            ? AppColors.primary
                            : AppColors.outline),
                        size: 28,
                        weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _running
                  ? 'TV will power off when timer ends'
                  : 'Select a duration below',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _presetGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.5,
        children: _presets.map((p) {
          final active = _selectedMin == p.$1 && !_running;
          return GestureDetector(
            onTap: _running
                ? null
                : () => setState(() => _selectedMin = p.$1),
            child: Container(
              decoration: BoxDecoration(
                color: hex(active ? p.$4 : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? p.$4 : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.4 : 0.15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(p.$3,
                      size: 20,
                      color: hex(active ? p.$4 : AppColors.outline)),
                  const SizedBox(height: 4),
                  Text(p.$2,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? p.$4 : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ],
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
              Icon(_running ? Icons.stop : Icons.play_arrow,
                  size: 20,
                  color: hex(_running ? AppColors.error : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_running ? 'Cancel Timer' : 'Start Timer',
                  style: gfont(AppType.bodyMd,
                      color: hex(_running ? AppColors.error : AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _quickActions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _actions.map((a) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final rc = RemoteScope.of(context);
                    rc.key(a.$3);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: hex(a.$4).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border:
                          Border.all(color: hex(a.$4).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(a.$2, size: 22, color: hex(a.$4)),
                        const SizedBox(height: 4),
                        Text(a.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(a.$4),
                                weight: FontWeight.w500,
                                size: 9)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
                'Set a countdown timer to automatically power off your TV. Choose from preset durations or use quick actions. The timer runs on your phone — no TV app needed.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
