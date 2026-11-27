import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ParentalReportScreen extends StatefulWidget {
  const ParentalReportScreen({super.key});

  @override
  State<ParentalReportScreen> createState() => _ParentalReportScreenState();
}

class _ParentalReportScreenState extends State<ParentalReportScreen> {
  double _screenTimeLimit = 4;
  bool _overLimitAlert = true;

  static const _dailyHours = [2.5, 3.0, 1.5, 4.0, 3.5, 2.0, 3.8];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const _topChannels = [
    ('Cartoon Network', 5.2, AppColors.primary),
    ('Disney Channel', 4.1, AppColors.secondary),
    ('Netflix Kids', 3.5, AppColors.tertiary),
    ('YouTube Kids', 3.0, AppColors.signalEmerald),
    ('Nickelodeon', 2.5, AppColors.alertAmber),
  ];

  double get _totalHours =>
      _dailyHours.fold(0.0, (sum, h) => sum + h);

  double get _dailyAverage => _totalHours / 7;

  String get _mostWatched => _topChannels.first.$1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Parental Report',
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
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          Text('Weekly Usage',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _barChart(),
          const SizedBox(height: AppSpacing.lg),
          Text('Top Channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._topChannels.asMap().entries.map(_channelRow),
          const SizedBox(height: AppSpacing.lg),
          _limitSlider(),
          const SizedBox(height: AppSpacing.md),
          _alertToggle(),
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
            Icon(Icons.family_restroom,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Weekly Viewing Report',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Monitor screen time, top channels, and set daily viewing limits',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${_totalHours.toStringAsFixed(1)}h', 'Total'),
            Container(
              height: 30,
              width: 1,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
            _stat('${_dailyAverage.toStringAsFixed(1)}h', 'Daily Avg'),
            Container(
              height: 30,
              width: 1,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
            _stat(_mostWatched, 'Most Watched'),
          ],
        ),
      );

  Widget _stat(String value, String label) => Flexible(
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w700,
                    size: 15)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
        ),
      );

  Widget _barChart() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        height: 200,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _dailyHours.asMap().entries.map((e) {
            final h = e.value;
            final overLimit = h > _screenTimeLimit;
            final barColor = overLimit ? AppColors.alertAmber : AppColors.primary;
            final fraction = h / 5.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${h.toStringAsFixed(1)}h',
                        style: gfont(AppType.bodySm,
                            color: hex(barColor),
                            weight: FontWeight.w600,
                            size: 9)),
                    const SizedBox(height: 4),
                    Container(
                      height: 120 * fraction.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: hex(barColor).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_dayLabels[e.key],
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _channelRow(MapEntry<int, (String, double, int)> entry) {
    final c = entry.value;
    final rank = entry.key + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hex(c.$3).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Center(
                child: Text('$rank',
                    style: gfont(AppType.bodySm,
                        color: hex(c.$3),
                        weight: FontWeight.w700,
                        size: 10)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(c.$1,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 13)),
            ),
            Text('${c.$2.toStringAsFixed(1)}h',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w600,
                    size: 11)),
          ],
        ),
      ),
    );
  }

  Widget _limitSlider() => Container(
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
                Text('Daily Screen Time Limit',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('${_screenTimeLimit.toStringAsFixed(1)}h',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _screenTimeLimit,
              min: 0.5,
              max: 8,
              divisions: 15,
              activeColor: hex(AppColors.signalEmerald),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) {
                setState(() => _screenTimeLimit = v);
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
      );

  Widget _alertToggle() => GestureDetector(
        onTap: () {
          setState(() => _overLimitAlert = !_overLimitAlert);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_overLimitAlert
                    ? AppColors.alertAmber
                    : AppColors.outline)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_overLimitAlert
                      ? AppColors.alertAmber
                      : AppColors.outline)
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _overLimitAlert
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                size: 24,
                color: hex(_overLimitAlert
                    ? AppColors.alertAmber
                    : AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Over-Limit Alert',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                      _overLimitAlert
                          ? 'Notified when daily limit is exceeded'
                          : 'No alerts for screen time overages',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                    ),
                  ],
                ),
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
                'Weekly viewing report with daily breakdown, top channels and screen time limits. All data is stored locally on this device.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
