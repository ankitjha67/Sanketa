import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class RemoteBatteryScreen extends StatefulWidget {
  const RemoteBatteryScreen({super.key});

  @override
  State<RemoteBatteryScreen> createState() => _RemoteBatteryScreenState();
}

class _RemoteBatteryScreenState extends State<RemoteBatteryScreen> {
  int _batteryPct = 68;
  final bool _charging = false;
  bool _monitoring = false;
  Timer? _timer;
  final _rng = Random();

  int _alertThreshold = 20;
  bool _alertEnabled = true;

  final List<(String, int, String)> _history = [
    ('Today 2:30 PM', 68, 'Normal use'),
    ('Today 10:00 AM', 75, 'Normal use'),
    ('Yesterday 8:00 PM', 82, 'Normal use'),
    ('Yesterday 12:00 PM', 90, 'Fresh batteries'),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() => _monitoring = !_monitoring);
    if (_monitoring) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() {
          _batteryPct = (_batteryPct - _rng.nextInt(2)).clamp(0, 100);
          if (_batteryPct <= _alertThreshold && _alertEnabled) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text('Low battery: $_batteryPct%'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 3),
              ));
          }
        });
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  int get _batteryColor {
    if (_batteryPct > 50) return AppColors.signalEmerald;
    if (_batteryPct > 20) return AppColors.alertAmber;
    return AppColors.error;
  }

  String get _batteryStatus {
    if (_charging) return 'Charging';
    if (_batteryPct > 80) return 'Excellent';
    if (_batteryPct > 50) return 'Good';
    if (_batteryPct > 20) return 'Low';
    return 'Critical';
  }

  String get _estimatedLife {
    if (_batteryPct > 80) return '~3 weeks';
    if (_batteryPct > 50) return '~2 weeks';
    if (_batteryPct > 20) return '~5 days';
    return '~1-2 days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Battery',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _batteryGauge(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _monitorToggle(),
          const SizedBox(height: AppSpacing.md),
          _alertSettings(),
          const SizedBox(height: AppSpacing.md),
          _historyCard(),
          const SizedBox(height: AppSpacing.lg),
          _tipsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _batteryGauge() => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_batteryColor).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(_batteryColor).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              _batteryPct > 80
                  ? Icons.battery_full
                  : _batteryPct > 50
                      ? Icons.battery_5_bar
                      : _batteryPct > 20
                          ? Icons.battery_3_bar
                          : Icons.battery_1_bar,
              size: 56,
              color: hex(_batteryColor),
            ),
            const SizedBox(height: 8),
            Text('$_batteryPct%',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 42,
                    weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hex(_batteryColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(_batteryStatus,
                  style: gfont(AppType.bodySm,
                      color: hex(_batteryColor),
                      weight: FontWeight.w600,
                      size: 11)),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(child: _statTile('Est. Life', _estimatedLife, Icons.schedule)),
          const SizedBox(width: 8),
          Expanded(
              child: _statTile(
                  'Type', 'AAA x2', Icons.battery_charging_full)),
          const SizedBox(width: 8),
          Expanded(
              child: _statTile(
                  'Monitor', _monitoring ? 'On' : 'Off', Icons.monitor_heart)),
        ],
      );

  Widget _statTile(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.primary)),
            const SizedBox(height: 4),
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w700,
                    size: 12)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _monitorToggle() => GestureDetector(
        onTap: _toggleMonitoring,
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
              Icon(Icons.monitor_heart, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Monitoring',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Track battery level in real time',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_monitoring ? AppColors.primary : AppColors.outlineVariant)
                      .withValues(alpha: _monitoring ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _monitoring ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_monitoring ? AppColors.primary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _alertSettings() => Container(
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
              children: [
                Icon(Icons.notifications_active,
                    size: 18, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 8),
                Text('Low Battery Alert',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _alertEnabled = !_alertEnabled),
                  child: Icon(
                    _alertEnabled ? Icons.toggle_on : Icons.toggle_off,
                    size: 32,
                    color: hex(_alertEnabled ? AppColors.primary : AppColors.outline),
                  ),
                ),
              ],
            ),
            if (_alertEnabled) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alert at: $_alertThreshold%',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
              Slider(
                value: _alertThreshold.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                activeColor: hex(AppColors.alertAmber),
                inactiveColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                onChanged: (v) =>
                    setState(() => _alertThreshold = v.round()),
              ),
            ],
          ],
        ),
      );

  Widget _historyCard() => Container(
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
            Text('Battery History',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._history.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        h.$2 > 50
                            ? Icons.battery_5_bar
                            : h.$2 > 20
                                ? Icons.battery_3_bar
                                : Icons.battery_1_bar,
                        size: 14,
                        color: hex(h.$2 > 50
                            ? AppColors.signalEmerald
                            : h.$2 > 20
                                ? AppColors.alertAmber
                                : AppColors.error),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(h.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11)),
                      ),
                      Text('${h.$2}%',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline),
                              weight: FontWeight.w600,
                              size: 10)),
                    ],
                  ),
                )),
          ],
        ),
      );

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
                Text('Battery Tips',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ...[
              'Use rechargeable AAA batteries to save money',
              'Remove batteries if remote unused for weeks',
              'Clean battery contacts with a dry cloth',
              'Avoid mixing old and new batteries',
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
                'Monitor your TV remote battery level and get alerts before it dies. Set a custom low-battery threshold to always have replacement batteries ready.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
