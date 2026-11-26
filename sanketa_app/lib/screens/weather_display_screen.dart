import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class WeatherDisplayScreen extends StatefulWidget {
  const WeatherDisplayScreen({super.key});

  @override
  State<WeatherDisplayScreen> createState() => _WeatherDisplayScreenState();
}

class _WeatherDisplayScreenState extends State<WeatherDisplayScreen> {
  String _city = '';
  bool _loading = true;
  int _unitIndex = 0;

  static const _units = ['°C', '°F'];

  static const _forecast = <(String, IconData, int, int, String)>[
    ('Mon', Icons.wb_sunny, 32, 24, 'Clear'),
    ('Tue', Icons.cloud, 28, 22, 'Cloudy'),
    ('Wed', Icons.grain, 26, 20, 'Rain'),
    ('Thu', Icons.wb_sunny, 30, 23, 'Sunny'),
    ('Fri', Icons.cloud_queue, 29, 21, 'Partly cloudy'),
  ];

  static const _details = <(String, String, IconData)>[
    ('Humidity', '65%', Icons.water_drop),
    ('Wind', '12 km/h', Icons.air),
    ('UV Index', '6 (High)', Icons.wb_sunny),
    ('Visibility', '10 km', Icons.visibility),
    ('Pressure', '1013 hPa', Icons.speed),
    ('Dew Point', '19°C', Icons.thermostat),
  ];

  final _cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/weather_city.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _city = data['city'] as String? ?? '';
        _unitIndex = data['unit'] as int? ?? 0;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({'city': _city, 'unit': _unitIndex}));
  }

  void _setCity() {
    final c = _cityCtrl.text.trim();
    if (c.isEmpty) return;
    setState(() => _city = c);
    _cityCtrl.clear();
    _save();
  }

  void _toggleUnit() {
    setState(() => _unitIndex = (_unitIndex + 1) % _units.length);
    _save();
  }

  int _convert(int celsius) {
    if (_unitIndex == 0) return celsius;
    return (celsius * 9 / 5 + 32).round();
  }

  void _sendToTv() {
    final rc = RemoteScope.of(context);
    final summary =
        '$_city: ${_convert(30)}${_units[_unitIndex]}, Clear skies';
    rc.type(summary);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Weather summary sent to TV'),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child:
                CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Weather',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _toggleUnit,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(_units[_unitIndex],
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_city.isEmpty) ...[
            _setCitySection(),
          ] else ...[
            _currentWeather(),
            const SizedBox(height: AppSpacing.md),
            _forecastRow(),
            const SizedBox(height: AppSpacing.md),
            _detailsGrid(),
            const SizedBox(height: AppSpacing.md),
            _sendButton(),
            const SizedBox(height: AppSpacing.md),
            _changeCitySection(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _setCitySection() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 12),
            Text('Set Your City',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Enter your city to see the weather dashboard',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface)),
                    decoration: InputDecoration(
                      hintText: 'City name',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline)
                              .withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.md)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _setCity(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _setCity,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          hex(AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.check,
                        size: 20, color: hex(AppColors.primary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _currentWeather() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hex(AppColors.primary).withValues(alpha: 0.12),
              hex(AppColors.tertiary).withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(_city,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Icon(Icons.wb_sunny, size: 56, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('${_convert(30)}${_units[_unitIndex]}',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 48,
                    weight: FontWeight.w700)),
            Text('Clear skies',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
                'H: ${_convert(32)}° L: ${_convert(24)}°',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _forecastRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('5-Day Forecast',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _forecast[i];
                return Container(
                  width: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline),
                              size: 10,
                              weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Icon(f.$2,
                          size: 20, color: hex(AppColors.alertAmber)),
                      const SizedBox(height: 4),
                      Text(
                          '${_convert(f.$3)}°/${_convert(f.$4)}°',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              size: 10,
                              weight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _detailsGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _details.map((d) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(d.$3,
                        size: 16, color: hex(AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(d.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline),
                            size: 9)),
                    Text(d.$2,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            size: 10,
                            weight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _sendButton() => GestureDetector(
        onTap: _city.isNotEmpty ? _sendToTv : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cast, size: 18, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Send Summary to TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _changeCitySection() => Container(
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
            Text('Change City',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface)),
                    decoration: InputDecoration(
                      hintText: 'New city name',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline)
                              .withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.md)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _setCity(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _setCity,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          hex(AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.check,
                        size: 20, color: hex(AppColors.primary)),
                  ),
                ),
              ],
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
                'Weather dashboard with sample data. Send a weather summary to your TV as typed text. No external API calls are made — all data is illustrative. City preference is stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
