import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenBurnFixScreen extends StatefulWidget {
  const ScreenBurnFixScreen({super.key});

  @override
  State<ScreenBurnFixScreen> createState() => _ScreenBurnFixScreenState();
}

class _ScreenBurnFixScreenState extends State<ScreenBurnFixScreen> {
  int _selectedPattern = 0;
  int _durationMin = 10;
  bool _running = false;
  int _elapsed = 0;
  Timer? _timer;

  static const _patterns = <(String, IconData, String, int)>[
    ('Color Wash', Icons.palette, 'Cycle RGB to exercise all subpixels',
        AppColors.primary),
    ('White Flood', Icons.wb_sunny, 'Full white to even out OLED wear',
        AppColors.alertAmber),
    ('Scrolling Bars', Icons.straighten, 'Moving bars to shift pixel usage',
        AppColors.signalEmerald),
    ('Noise Pattern', Icons.grain, 'Random noise for even pixel activation',
        AppColors.secondary),
    ('Checkerboard', Icons.grid_on, 'Alternating pattern to balance pixels',
        AppColors.tertiary),
  ];

  static const _durations = [5, 10, 15, 30, 60];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _elapsed = 0;
    });
    HapticFeedback.heavyImpact();

    final rc = RemoteScope.of(context);
    rc.type('screen_burn_fix:${_patterns[_selectedPattern].$1}');

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsed++);
      if (_elapsed >= _durationMin * 60) {
        t.cancel();
        _stop();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _running = false);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(_elapsed >= _durationMin * 60
              ? 'Screen refresh complete'
              : 'Screen refresh stopped'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  String _fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
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
        title: Text('Screen Burn Fix',
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
          if (_running) ...[
            _progressCard(),
            const SizedBox(height: AppSpacing.md),
            _stopButton(),
          ] else ...[
            _patternSelector(),
            const SizedBox(height: AppSpacing.lg),
            _durationSelector(),
            const SizedBox(height: AppSpacing.lg),
            _startButton(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _tipsCard(),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.monitor_heart,
                size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Screen Burn Fix',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Run pixel refresh patterns to reduce OLED burn-in and image retention',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _progressCard() {
    final total = _durationMin * 60;
    final progress = total > 0 ? _elapsed / total : 0.0;
    final pat = _patterns[_selectedPattern];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(pat.$4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(pat.$4).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(pat.$2, size: 40, color: hex(pat.$4)),
          const SizedBox(height: 8),
          Text(pat.$1,
              style: gfont(AppType.bodyMd,
                  color: hex(pat.$4), weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(_fmtTime(_elapsed),
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 32,
                  weight: FontWeight.w700)),
          Text('of ${_durationMin}m',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(hex(pat.$4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pattern',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          ..._patterns.asMap().entries.map((e) {
            final active = e.key == _selectedPattern;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedPattern = e.key);
                HapticFeedback.selectionClick();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: hex(e.value.$4)
                      .withValues(alpha: active ? 0.1 : 0.03),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(e.value.$4)
                          .withValues(alpha: active ? 0.4 : 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(e.value.$2, size: 22, color: hex(e.value.$4)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.$1,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: FontWeight.w600,
                                  size: 13)),
                          Text(e.value.$3,
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline), size: 10)),
                        ],
                      ),
                    ),
                    if (active)
                      Icon(Icons.check_circle,
                          size: 20, color: hex(e.value.$4)),
                  ],
                ),
              ),
            );
          }),
        ],
      );

  Widget _durationSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _durations.map((d) {
              final active = d == _durationMin;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _durationMin = d);
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
                      child: Text('${d}m',
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
        onTap: _start,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow,
                  size: 22, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Start Refresh',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _stopButton() => GestureDetector(
        onTap: _stop,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.error).withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text('Stop',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error),
                    weight: FontWeight.w600)),
          ),
        ),
      );

  Widget _tipsCard() => Container(
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
            Text('Prevention Tips',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: 8),
            _tip('Lower screen brightness to extend panel life'),
            _tip('Use screen savers or sleep timers'),
            _tip('Avoid static images for extended periods'),
            _tip('Run pixel refresh weekly for OLED TVs'),
          ],
        ),
      );

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.circle,
                  size: 5, color: hex(AppColors.outline)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface), size: 11)),
            ),
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
                'Pixel refresh patterns help reduce image retention on OLED '
                'and plasma TVs. Run periodically for best results. All local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
