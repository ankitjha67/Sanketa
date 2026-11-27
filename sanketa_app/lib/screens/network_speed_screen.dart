import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class NetworkSpeedScreen extends StatefulWidget {
  const NetworkSpeedScreen({super.key});

  @override
  State<NetworkSpeedScreen> createState() => _NetworkSpeedScreenState();
}

class _NetworkSpeedScreenState extends State<NetworkSpeedScreen> {
  bool _testing = false;
  double _download = 0;
  double _upload = 0;
  int _ping = 0;
  int _jitter = 0;
  bool _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _run() {
    HapticFeedback.mediumImpact();
    setState(() {
      _testing = true;
      _done = false;
      _download = 0;
      _upload = 0;
      _ping = 0;
      _jitter = 0;
    });
    var step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      step++;
      if (step <= 5) {
        setState(() => _download = step * 18.5);
      } else if (step <= 10) {
        setState(() => _upload = (step - 5) * 4.2);
      } else if (step == 11) {
        setState(() {
          _ping = 14;
          _jitter = 3;
        });
      } else {
        t.cancel();
        setState(() {
          _testing = false;
          _done = true;
        });
      }
    });
  }

  String get _quality {
    if (!_done) return '';
    if (_download >= 80 && _ping <= 20) return 'Excellent';
    if (_download >= 40) return 'Good';
    if (_download >= 15) return 'Fair';
    return 'Poor';
  }

  int get _qualityColor {
    if (!_done) return AppColors.outline;
    if (_download >= 80 && _ping <= 20) return AppColors.signalEmerald;
    if (_download >= 40) return AppColors.primary;
    if (_download >= 15) return AppColors.alertAmber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Network Speed',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _speedGauge(),
          const SizedBox(height: AppSpacing.md),
          _metricsRow(),
          const SizedBox(height: AppSpacing.md),
          _startButton(),
          if (_done) ...[
            const SizedBox(height: AppSpacing.md),
            _qualityCard(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _speedGauge() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
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
                      value: _testing ? null : (_done ? 1.0 : 0),
                      strokeWidth: 6,
                      color: hex(_done ? _qualityColor : AppColors.primary),
                      backgroundColor:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _done
                            ? _download.toStringAsFixed(1)
                            : _testing
                                ? _download.toStringAsFixed(0)
                                : '—',
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.onSurface),
                            size: 28,
                            weight: FontWeight.w700),
                      ),
                      Text('Mbps',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(_testing ? 'Testing...' : _done ? 'Complete' : 'Tap Start',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _metricsRow() => Row(
        children: [
          _metric(Icons.download, 'Download',
              '${_download.toStringAsFixed(1)} Mbps', AppColors.primary),
          const SizedBox(width: 6),
          _metric(Icons.upload, 'Upload',
              '${_upload.toStringAsFixed(1)} Mbps', AppColors.secondary),
          const SizedBox(width: 6),
          _metric(Icons.speed, 'Ping', '$_ping ms', AppColors.signalEmerald),
          const SizedBox(width: 6),
          _metric(Icons.swap_vert, 'Jitter', '$_jitter ms', AppColors.alertAmber),
        ],
      );

  Widget _metric(IconData icon, String label, String val, int color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: hex(color).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: hex(color)),
              const SizedBox(height: 4),
              Text(val,
                  style: gfont(AppType.bodySm,
                      color: hex(color), weight: FontWeight.w700, size: 9)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 8)),
            ],
          ),
        ),
      );

  Widget _startButton() => GestureDetector(
        onTap: _testing ? null : _run,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_testing ? AppColors.outline : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_testing ? AppColors.outline : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_testing ? Icons.hourglass_top : Icons.speed,
                  size: 20,
                  color: hex(_testing ? AppColors.outline : AppColors.primary)),
              const SizedBox(width: 8),
              Text(_testing ? 'Testing...' : _done ? 'Run Again' : 'Start Test',
                  style: gfont(AppType.bodyMd,
                      color: hex(_testing ? AppColors.outline : AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _qualityCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(_qualityColor).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(_qualityColor).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi, size: 24, color: hex(_qualityColor)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connection Quality: $_quality',
                      style: gfont(AppType.bodyMd,
                          color: hex(_qualityColor), weight: FontWeight.w600)),
                  Text(
                    _download >= 40
                        ? 'Good for 4K streaming and gaming'
                        : _download >= 15
                            ? 'Suitable for HD streaming'
                            : 'May struggle with HD content',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10),
                  ),
                ],
              ),
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
                'Test your TV network speed. Measures download, upload, ping, and jitter. Results are simulated — actual speed depends on your network. All tests run locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
