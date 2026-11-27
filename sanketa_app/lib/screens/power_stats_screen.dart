import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class PowerStatsScreen extends StatefulWidget {
  const PowerStatsScreen({super.key});

  @override
  State<PowerStatsScreen> createState() => _PowerStatsScreenState();
}

class _PowerStatsScreenState extends State<PowerStatsScreen> {
  int _viewIndex = 0;
  double _ratePerKwh = 8.0;
  final _rateCtrl = TextEditingController(text: '8.0');

  static const _viewLabels = ['Daily', 'Weekly', 'Monthly'];

  static const _dailyWatts = [85.0, 120.0, 95.0, 140.0, 110.0, 75.0, 130.0];
  static const _dailyLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _weeklyWatts = [680.0, 750.0, 620.0, 810.0];
  static const _weeklyLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];

  static const _monthlyWatts = [2800.0, 3100.0, 2650.0, 2900.0, 3200.0, 2500.0, 3050.0];
  static const _monthlyLabels = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  List<double> get _watts =>
      _viewIndex == 0 ? _dailyWatts : _viewIndex == 1 ? _weeklyWatts : _monthlyWatts;
  List<String> get _labels =>
      _viewIndex == 0 ? _dailyLabels : _viewIndex == 1 ? _weeklyLabels : _monthlyLabels;

  double get _totalWh => _watts.fold(0.0, (a, b) => a + b);
  double get _avgW => _totalWh / _watts.length;
  double get _costEstimate => (_totalWh / 1000) * _ratePerKwh;

  static const _tips = [
    'Enable eco mode to reduce standby power by up to 70%',
    'Use auto-brightness to adapt to room lighting',
    'Turn off Quick Start for lower standby consumption',
    'Set a sleep timer to avoid all-night power draw',
    'Lower backlight intensity for energy savings',
  ];

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Power Stats',
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
          _viewPicker(),
          const SizedBox(height: AppSpacing.lg),
          _currentReading(),
          const SizedBox(height: AppSpacing.lg),
          _barChart(),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          _standbyCard(),
          const SizedBox(height: AppSpacing.lg),
          _costCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Eco Tips',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._tips.map(_tipCard),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.bolt, size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Power Analytics',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Track your TV power usage and find ways to save energy',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _viewPicker() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          children: List.generate(_viewLabels.length, (i) {
            final sel = _viewIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _viewIndex = i);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? hex(AppColors.primary).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(_viewLabels[i],
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(sel
                              ? AppColors.primary
                              : AppColors.outline),
                          weight: sel ? FontWeight.w600 : FontWeight.w400,
                          size: 12)),
                ),
              ),
            );
          }),
        ),
      );

  Widget _currentReading() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('${_watts.last.round()}',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 48,
                    weight: FontWeight.w700)),
            Text('watts (current)',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 12)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hex(_watts.last <= 100
                        ? AppColors.signalEmerald
                        : _watts.last <= 130
                            ? AppColors.alertAmber
                            : AppColors.error)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(
                _watts.last <= 100
                    ? 'Low'
                    : _watts.last <= 130
                        ? 'Moderate'
                        : 'High',
                style: gfont(AppType.bodySm,
                    color: hex(_watts.last <= 100
                        ? AppColors.signalEmerald
                        : _watts.last <= 130
                            ? AppColors.alertAmber
                            : AppColors.error),
                    weight: FontWeight.w600,
                    size: 10),
              ),
            ),
          ],
        ),
      );

  Widget _barChart() {
    final maxW = _watts.reduce((a, b) => a > b ? a : b);
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
          Text('Usage',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 12)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_watts.length, (i) {
              final ratio = maxW > 0 ? _watts[i] / maxW : 0.0;
              final isHigh = _watts[i] > 120;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${_watts[i].round()}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                      const SizedBox(height: 4),
                      Container(
                        height: 100 * ratio,
                        decoration: BoxDecoration(
                          color: hex(isHigh
                                  ? AppColors.alertAmber
                                  : AppColors.signalEmerald)
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[i],
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() => Row(
        children: [
          _statBadge('${_totalWh.round()} Wh', 'Total', AppColors.primary),
          const SizedBox(width: 8),
          _statBadge('${_avgW.round()} W', 'Average', AppColors.secondary),
          const SizedBox(width: 8),
          _statBadge('${_watts.reduce((a, b) => a > b ? a : b).round()} W', 'Peak', AppColors.error),
        ],
      );

  Widget _statBadge(String value, String label, int color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: gfont(AppType.bodySm,
                      color: hex(color), weight: FontWeight.w700, size: 11)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
      );

  Widget _standbyCard() => Container(
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
            Text('Standby vs Active',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(6)),
                    ),
                    child: Center(
                        child: Text('Active 72%',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 10))),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(6)),
                    ),
                    child: Center(
                        child: Text('28%',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline),
                                weight: FontWeight.w600,
                                size: 10))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Standby draws ~0.5W. Consider unplugging when away.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
        ),
      );

  Widget _costCard() => Container(
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
            Text('Cost Estimate',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 13),
                    decoration: InputDecoration(
                      labelText: 'Rate per kWh',
                      labelStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.sm)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null && d >= 0) {
                        setState(() => _ratePerKwh = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${_costEstimate.toStringAsFixed(1)}',
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.signalEmerald),
                            size: 24,
                            weight: FontWeight.w700)),
                    Text('estimated cost',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _tipCard(String tip) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.eco,
                  color: hex(AppColors.signalEmerald), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tip,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: hex(AppColors.outline), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Power readings are simulated. Actual usage depends on your TV model and settings.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ),
          ],
        ),
      );
}
