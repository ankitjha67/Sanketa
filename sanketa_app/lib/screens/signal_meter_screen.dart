import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class SignalMeterScreen extends StatefulWidget {
  const SignalMeterScreen({super.key});

  @override
  State<SignalMeterScreen> createState() => _SignalMeterScreenState();
}

class _SignalMeterScreenState extends State<SignalMeterScreen> {
  Timer? _timer;
  final _rng = Random();

  int _wifiStrength = 72;
  int _irSignal = 85;
  int _latency = 24;
  bool _monitoring = false;

  final List<int> _wifiHistory = [];
  final List<int> _latencyHistory = [];

  static const _maxHistory = 20;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() => _monitoring = !_monitoring);
    if (_monitoring) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _wifiStrength = (_wifiStrength + _rng.nextInt(11) - 5).clamp(0, 100);
      _irSignal = (_irSignal + _rng.nextInt(7) - 3).clamp(0, 100);
      _latency = (_latency + _rng.nextInt(9) - 4).clamp(1, 200);
      _wifiHistory.add(_wifiStrength);
      _latencyHistory.add(_latency);
      if (_wifiHistory.length > _maxHistory) _wifiHistory.removeAt(0);
      if (_latencyHistory.length > _maxHistory) _latencyHistory.removeAt(0);
    });
  }

  String _quality(int pct) {
    if (pct >= 80) return 'Excellent';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Fair';
    return 'Poor';
  }

  int _qualityColor(int pct) {
    if (pct >= 80) return AppColors.signalEmerald;
    if (pct >= 60) return AppColors.primary;
    if (pct >= 40) return AppColors.alertAmber;
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
        title: Text('Signal Meter',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _gaugeCard('Wi-Fi Signal', _wifiStrength, Icons.wifi),
          const SizedBox(height: AppSpacing.md),
          _gaugeCard('IR Signal', _irSignal, Icons.settings_remote),
          const SizedBox(height: AppSpacing.md),
          _latencyCard(),
          const SizedBox(height: AppSpacing.md),
          _monitorButton(),
          if (_wifiHistory.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _historyChart('Wi-Fi History', _wifiHistory),
          ],
          if (_latencyHistory.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _historyChart('Latency History', _latencyHistory),
          ],
          const SizedBox(height: AppSpacing.lg),
          _tipsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _gaugeCard(String label, int pct, IconData icon) {
    final qColor = _qualityColor(pct);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(qColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 24, color: hex(qColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 6,
                          backgroundColor:
                              hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(hex(qColor)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$pct%',
                        style: gfont(AppType.bodyMd,
                            color: hex(qColor),
                            weight: FontWeight.w700,
                            size: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_quality(pct),
                    style: gfont(AppType.bodySm,
                        color: hex(qColor),
                        weight: FontWeight.w600,
                        size: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _latencyCard() {
    final lColor = _latency < 50
        ? AppColors.signalEmerald
        : _latency < 100
            ? AppColors.alertAmber
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(lColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(Icons.speed, size: 24, color: hex(lColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latency',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${_latency}ms',
                        style: gfont(AppType.headlineMd,
                            color: hex(lColor),
                            weight: FontWeight.w700,
                            size: 22)),
                    const SizedBox(width: 8),
                    Text(_latency < 50 ? 'Fast' : _latency < 100 ? 'OK' : 'Slow',
                        style: gfont(AppType.bodySm,
                            color: hex(lColor),
                            weight: FontWeight.w600,
                            size: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monitorButton() => GestureDetector(
        onTap: _toggleMonitoring,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_monitoring ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_monitoring ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _monitoring ? Icons.stop : Icons.monitor_heart,
                size: 20,
                color: hex(_monitoring ? AppColors.error : AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(_monitoring ? 'Stop Monitoring' : 'Start Monitoring',
                  style: gfont(AppType.bodyMd,
                      color: hex(_monitoring ? AppColors.error : AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _historyChart(String label, List<int> data) {
    final maxVal = data.reduce(max).toDouble().clamp(1, 999);
    return Container(
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
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 11)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map((v) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: FractionallySizedBox(
                            heightFactor: (v / maxVal).clamp(0.05, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: hex(_qualityColor(v)).withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2)),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Text('Tips for Better Signal',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ...[
              'Move closer to the TV for better IR signal',
              'Ensure no obstacles between phone and TV',
              'Stay on the same Wi-Fi network as the TV',
              'Restart your router if latency is high',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('  •  ',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      Expanded(
                        child: Text(tip,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 10)),
                      ),
                    ],
                  ),
                )),
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
                'Monitor your connection quality in real time. Check Wi-Fi, IR signal strength, and response latency to diagnose remote control issues.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
