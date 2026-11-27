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

class SleepFadeScreen extends StatefulWidget {
  const SleepFadeScreen({super.key});

  @override
  State<SleepFadeScreen> createState() => _SleepFadeScreenState();
}

class _SleepFadeScreenState extends State<SleepFadeScreen> {
  int _durationIndex = 1;
  double _startVolume = 80;
  bool _fading = false;
  int _elapsedSec = 0;
  Timer? _timer;

  static const _durations = [
    ('5 min', 5, Icons.bedtime, AppColors.primary),
    ('10 min', 10, Icons.nights_stay, AppColors.secondary),
    ('15 min', 15, Icons.dark_mode, AppColors.tertiary),
    ('30 min', 30, Icons.mode_night, AppColors.alertAmber),
  ];

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
    return File('${dir.path}/sleep_fade.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        setState(() {
          _durationIndex =
              (data['duration'] as num?)?.toInt().clamp(0, 3) ?? 1;
          _startVolume =
              (data['startVol'] as num?)?.toDouble().clamp(10, 100) ?? 80;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file;
      await f.writeAsString(jsonEncode({
        'duration': _durationIndex,
        'startVol': _startVolume,
      }));
    } catch (_) {}
  }

  int get _totalSec => _durations[_durationIndex].$2 * 60;

  double get _currentVolume {
    if (!_fading || _totalSec == 0) return _startVolume;
    final frac = (_elapsedSec / _totalSec).clamp(0.0, 1.0);
    return _startVolume * (1.0 - frac);
  }

  double get _progress {
    if (_totalSec == 0) return 0;
    return (_elapsedSec / _totalSec).clamp(0.0, 1.0);
  }

  void _startFade() {
    setState(() {
      _fading = true;
      _elapsedSec = 0;
    });
    _save();
    HapticFeedback.mediumImpact();

    // Calculate interval: send volume-down at regular intervals
    final stepsNeeded = _startVolume.round();
    final intervalMs =
        stepsNeeded > 0 ? ((_totalSec * 1000) / stepsNeeded).round() : 1000;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsedSec >= _totalSec) {
        _timer?.cancel();
        // Auto power-off at end
        final rc = RemoteScope.of(context);
        rc.key(core.Key.power);
        setState(() => _fading = false);
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('Fade complete — TV powered off'),
            duration: Duration(seconds: 3),
          ));
        return;
      }
      setState(() => _elapsedSec++);

      // Send volume-down at calculated intervals
      if (stepsNeeded > 0 &&
          _elapsedSec % (intervalMs ~/ 1000).clamp(1, _totalSec) == 0) {
        final rc = RemoteScope.of(context);
        rc.key(core.Key.volumeDown);
      }
    });
  }

  void _stopFade() {
    _timer?.cancel();
    setState(() {
      _fading = false;
      _elapsedSec = 0;
    });
    HapticFeedback.selectionClick();
  }

  void _selectDuration(int idx) {
    if (_fading) return;
    setState(() => _durationIndex = idx);
    _save();
    HapticFeedback.selectionClick();
  }

  String _fmtTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
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
        title: Text('Sleep Fade',
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
          _fadePreview(),
          const SizedBox(height: AppSpacing.lg),
          _volumeSlider(),
          const SizedBox(height: AppSpacing.lg),
          Text('Fade Duration',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _durationRow(),
          const SizedBox(height: AppSpacing.lg),
          _fadeCurveCard(),
          const SizedBox(height: AppSpacing.lg),
          _controlButton(),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.bedtime, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Gradual Sleep Fade',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Slowly reduce volume to zero before sleep, then auto power-off',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _fadePreview() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                    Text('${_currentVolume.round()}%',
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.onSurface),
                            size: 36,
                            weight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Time Left',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                    Text(
                        _fading
                            ? _fmtTime(_totalSec - _elapsedSec)
                            : _fmtTime(_totalSec),
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.onSurface),
                            size: 24,
                            weight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: LinearProgressIndicator(
                value: _fading ? _progress : 0,
                minHeight: 6,
                backgroundColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                valueColor:
                    AlwaysStoppedAnimation(hex(AppColors.tertiary)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_startVolume.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hex(_fading
                            ? AppColors.tertiary
                            : AppColors.outline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    _fading ? 'Fading...' : 'Ready',
                    style: gfont(AppType.bodySm,
                        color: hex(
                            _fading ? AppColors.tertiary : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9),
                  ),
                ),
                Text('0%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _volumeSlider() => Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Volume',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${_startVolume.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.tertiary),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            Slider(
              value: _startVolume,
              min: 10,
              max: 100,
              divisions: 18,
              activeColor: hex(AppColors.tertiary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: _fading
                  ? null
                  : (v) => setState(() => _startVolume = v),
              onChangeEnd: (_) => _save(),
            ),
          ],
        ),
      );

  Widget _durationRow() => Row(
        children: _durations.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _durationIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 3,
                  right: e.key == _durations.length - 1 ? 0 : 3),
              child: GestureDetector(
                onTap: () => _selectDuration(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                      Icon(p.$3, size: 18, color: hex(p.$4)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _fadeCurveCard() => Container(
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
            Text('Fade Curve Preview',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: _FadeCurvePainter(
                  startVol: _startVolume,
                  progress: _fading ? _progress : 0,
                  color: hex(AppColors.tertiary),
                  bgColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9)),
                Text(
                    '${_durations[_durationIndex].$2} min',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9)),
              ],
            ),
          ],
        ),
      );

  Widget _controlButton() => GestureDetector(
        onTap: _fading ? _stopFade : _startFade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_fading ? AppColors.alertAmber : AppColors.tertiary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_fading ? AppColors.alertAmber : AppColors.tertiary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  _fading ? Icons.stop : Icons.play_arrow,
                  size: 20,
                  color: hex(
                      _fading ? AppColors.alertAmber : AppColors.tertiary)),
              const SizedBox(width: 8),
              Text(_fading ? 'Stop Fade' : 'Start Fade',
                  style: gfont(AppType.bodyMd,
                      color: hex(
                          _fading ? AppColors.alertAmber : AppColors.tertiary),
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
                'Gradually lowers TV volume to zero over 5–30 minutes, then powers off automatically. Perfect for falling asleep to TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _FadeCurvePainter extends CustomPainter {
  _FadeCurvePainter({
    required this.startVol,
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  final double startVol;
  final double progress;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final curvePath = Path();
    for (var i = 0; i <= 50; i++) {
      final x = (i / 50) * size.width;
      final frac = i / 50;
      final vol = startVol * (1.0 - frac);
      final y = size.height - (vol / 100) * size.height;
      if (i == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }
    }
    canvas.drawPath(curvePath, bgPaint);

    if (progress > 0) {
      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final activePath = Path();
      final steps = (50 * progress).round().clamp(1, 50);
      for (var i = 0; i <= steps; i++) {
        final x = (i / 50) * size.width;
        final frac = i / 50;
        final vol = startVol * (1.0 - frac);
        final y = size.height - (vol / 100) * size.height;
        if (i == 0) {
          activePath.moveTo(x, y);
        } else {
          activePath.lineTo(x, y);
        }
      }
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FadeCurvePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.startVol != startVol;
}
