import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvWeatherScreen extends StatefulWidget {
  const TvWeatherScreen({super.key});

  @override
  State<TvWeatherScreen> createState() => _TvWeatherScreenState();
}

class _TvWeatherScreenState extends State<TvWeatherScreen> {
  int _dayIndex = 0;

  static const _days = <_WeatherDay>[
    _WeatherDay(day: 'Today', temp: 24, high: 28, low: 18, condition: 'Sunny', icon: Icons.wb_sunny, color: AppColors.alertAmber, humidity: 45, wind: 12),
    _WeatherDay(day: 'Tomorrow', temp: 22, high: 26, low: 16, condition: 'Partly Cloudy', icon: Icons.cloud, color: AppColors.outline, humidity: 55, wind: 15),
    _WeatherDay(day: 'Wednesday', temp: 19, high: 23, low: 14, condition: 'Rain', icon: Icons.water_drop, color: AppColors.primary, humidity: 80, wind: 22),
    _WeatherDay(day: 'Thursday', temp: 21, high: 25, low: 15, condition: 'Cloudy', icon: Icons.cloud_queue, color: AppColors.tertiary, humidity: 60, wind: 10),
    _WeatherDay(day: 'Friday', temp: 26, high: 30, low: 20, condition: 'Hot', icon: Icons.local_fire_department, color: AppColors.error, humidity: 35, wind: 8),
    _WeatherDay(day: 'Saturday', temp: 23, high: 27, low: 17, condition: 'Clear', icon: Icons.nights_stay, color: AppColors.secondary, humidity: 40, wind: 14),
    _WeatherDay(day: 'Sunday', temp: 20, high: 24, low: 15, condition: 'Thunderstorm', icon: Icons.flash_on, color: AppColors.signalEmerald, humidity: 90, wind: 30),
  ];

  _WeatherDay get _selected => _days[_dayIndex];

  void _castToTv() {
    final rc = RemoteScope.of(context);
    rc.type('${_selected.day}: ${_selected.temp}°C ${_selected.condition}');
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Weather sent to TV'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Weather',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _currentCard(),
          const SizedBox(height: AppSpacing.lg),
          _detailsRow(),
          const SizedBox(height: AppSpacing.md),
          _castButton(),
          const SizedBox(height: AppSpacing.lg),
          _forecastLabel(),
          const SizedBox(height: AppSpacing.sm),
          ..._days.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _dayCard(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _currentCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 32, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_selected.color).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(_selected.color).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(_selected.icon, size: 64, color: hex(_selected.color)),
            const SizedBox(height: 8),
            Text('${_selected.temp}°C',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 48,
                    weight: FontWeight.w700)),
            Text(_selected.condition,
                style: gfont(AppType.bodyMd,
                    color: hex(_selected.color),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${_selected.day}  H:${_selected.high}°  L:${_selected.low}°',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 12)),
          ],
        ),
      );

  Widget _detailsRow() => Row(
        children: [
          Expanded(
              child: _detailBadge(
                  'Humidity', '${_selected.humidity}%', Icons.opacity,
                  AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _detailBadge(
                  'Wind', '${_selected.wind} km/h', Icons.air,
                  AppColors.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _detailBadge(
                  'Feels', '${_selected.temp - 1}°C', Icons.thermostat,
                  AppColors.tertiary)),
        ],
      );

  Widget _detailBadge(String label, String value, IconData icon, int c) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: hex(c)),
            const SizedBox(height: 4),
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(c), weight: FontWeight.w600, size: 13)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _castButton() => GestureDetector(
        onTap: _castToTv,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cast, size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Cast to TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _forecastLabel() => Text('7-Day Forecast',
      style: gfont(AppType.bodyMd,
          color: hex(AppColors.onSurface),
          weight: FontWeight.w600,
          size: 13));

  Widget _dayCard(int idx, _WeatherDay day) {
    final active = idx == _dayIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _dayIndex = idx);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? day.color : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? day.color : AppColors.outlineVariant)
                .withValues(alpha: active ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(day.icon, size: 24, color: hex(day.color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day.day,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(day.condition,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Text('${day.high}°',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 14)),
            const SizedBox(width: 6),
            Text('${day.low}°',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 12)),
          ],
        ),
      ),
    );
  }

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
                'View weather forecast and cast it to your TV. '
                'Tap a day for details. All data is sample — no network calls.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _WeatherDay {
  final String day;
  final int temp;
  final int high;
  final int low;
  final String condition;
  final IconData icon;
  final int color;
  final int humidity;
  final int wind;
  const _WeatherDay({
    required this.day,
    required this.temp,
    required this.high,
    required this.low,
    required this.condition,
    required this.icon,
    required this.color,
    required this.humidity,
    required this.wind,
  });
}
