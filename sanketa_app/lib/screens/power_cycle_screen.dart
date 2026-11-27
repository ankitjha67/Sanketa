import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class PowerCycleScreen extends StatefulWidget {
  const PowerCycleScreen({super.key});

  @override
  State<PowerCycleScreen> createState() => _PowerCycleScreenState();
}

class _PowerCycleScreenState extends State<PowerCycleScreen> {
  int _delaySec = 10;
  bool _cycling = false;
  int _countdown = 0;
  _Phase _phase = _Phase.idle;
  Timer? _timer;

  static const _presets = [5, 10, 15, 30, 60];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCycle() {
    if (_cycling) return;
    setState(() {
      _cycling = true;
      _phase = _Phase.powerOff;
      _countdown = 0;
    });
    HapticFeedback.heavyImpact();

    RemoteScope.of(context).key(core.Key.power);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.waiting;
        _countdown = _delaySec;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          _powerOn();
        }
      });
    });
  }

  void _powerOn() {
    if (!mounted) return;
    setState(() => _phase = _Phase.powerOn);
    RemoteScope.of(context).key(core.Key.power);
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _cycling = false;
      });
    });
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _cycling = false;
      _phase = _Phase.idle;
      _countdown = 0;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Power Cycle',
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
          _statusCard(),
          const SizedBox(height: AppSpacing.lg),
          if (!_cycling) ...[
            _delaySelector(),
            const SizedBox(height: AppSpacing.lg),
            _startButton(),
          ] else
            _cancelButton(),
          const SizedBox(height: AppSpacing.lg),
          _stepsCard(),
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
            Icon(Icons.restart_alt, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('Power Cycle TV',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Power off, wait, then power on. Fixes frozen TVs.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statusCard() {
    int color;
    IconData icon;
    String label;

    switch (_phase) {
      case _Phase.idle:
        color = AppColors.outlineVariant;
        icon = Icons.power_settings_new;
        label = 'Ready';
      case _Phase.powerOff:
        color = AppColors.error;
        icon = Icons.power_off;
        label = 'Powering Off...';
      case _Phase.waiting:
        color = AppColors.alertAmber;
        icon = Icons.timer;
        label = 'Waiting $_countdown s';
      case _Phase.powerOn:
        color = AppColors.signalEmerald;
        icon = Icons.power;
        label = 'Powering On...';
      case _Phase.done:
        color = AppColors.signalEmerald;
        icon = Icons.check_circle;
        label = 'Cycle Complete';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(color).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: hex(color)),
          const SizedBox(height: 8),
          Text(label,
              style: gfont(AppType.headlineMd,
                  color: hex(color),
                  size: 18,
                  weight: FontWeight.w700)),
          if (_phase == _Phase.waiting)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  value: 1 - (_countdown / _delaySec),
                  backgroundColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                  valueColor:
                      AlwaysStoppedAnimation(hex(AppColors.alertAmber)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _delaySelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wait Time',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _presets.map((s) {
              final active = s == _delaySec;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _delaySec = s);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text('${s}s',
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.primary
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              size: 12)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _startButton() => GestureDetector(
        onTap: _startCycle,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(AppColors.error).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.error).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restart_alt,
                  size: 22, color: hex(AppColors.error)),
              const SizedBox(width: 8),
              Text('Start Power Cycle',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _cancelButton() => GestureDetector(
        onTap: _cancel,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text('Cancel',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
          ),
        ),
      );

  Widget _stepsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: 8),
            _step(1, 'Send power-off command', _phase.index >= 1),
            _step(2, 'Wait selected duration', _phase.index >= 2),
            _step(3, 'Send power-on command', _phase.index >= 3),
            _step(4, 'TV restarts fresh', _phase.index >= 4),
          ],
        ),
      );

  Widget _step(int n, String text, bool done) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hex(done
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant)
                    .withValues(alpha: 0.15),
              ),
              child: Center(
                child: done
                    ? Icon(Icons.check,
                        size: 12, color: hex(AppColors.signalEmerald))
                    : Text('$n',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline),
                            size: 10,
                            weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Text(text,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 12)),
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
                'Power cycle your TV to fix freezes or connection issues. '
                'Sends power-off, waits, then power-on. No data leaves your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

enum _Phase { idle, powerOff, waiting, powerOn, done }
