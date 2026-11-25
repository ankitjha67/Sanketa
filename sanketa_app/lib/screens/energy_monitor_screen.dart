import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class EnergyMonitorScreen extends StatefulWidget {
  const EnergyMonitorScreen({super.key});

  @override
  State<EnergyMonitorScreen> createState() => _EnergyMonitorScreenState();
}

class _EnergyMonitorScreenState extends State<EnergyMonitorScreen> {
  int _tvWattage = 120;
  double _hoursPerDay = 5;
  double _electricityRate = 0.12;
  String _currency = '\$';
  bool _loading = true;

  static const _wattagePresets = <(String, int)>[
    ('32" LED', 40),
    ('43" LED', 65),
    ('50" LED', 80),
    ('55" OLED', 120),
    ('65" QLED', 150),
    ('75" Mini LED', 200),
    ('85" QLED', 280),
    ('Projector', 350),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/energy_monitor.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _tvWattage = j['tvWattage'] as int? ?? 120;
        _hoursPerDay = (j['hoursPerDay'] as num?)?.toDouble() ?? 5;
        _electricityRate = (j['electricityRate'] as num?)?.toDouble() ?? 0.12;
        _currency = j['currency'] as String? ?? '\$';
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'tvWattage': _tvWattage,
      'hoursPerDay': _hoursPerDay,
      'electricityRate': _electricityRate,
      'currency': _currency,
    }));
  }

  double get _dailyKwh => (_tvWattage * _hoursPerDay) / 1000;
  double get _monthlyKwh => _dailyKwh * 30;
  double get _yearlyKwh => _dailyKwh * 365;
  double get _monthlyCost => _monthlyKwh * _electricityRate;
  double get _yearlyCost => _yearlyKwh * _electricityRate;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Energy',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _summaryCards(),
          const SizedBox(height: AppSpacing.lg),
          _tvSizeSection(),
          const SizedBox(height: AppSpacing.lg),
          _usageSection(),
          const SizedBox(height: AppSpacing.lg),
          _rateSection(),
          const SizedBox(height: AppSpacing.lg),
          _costBreakdown(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _summaryCards() => Row(
    children: [
      _statCard('Daily', '${_dailyKwh.toStringAsFixed(2)} kWh', AppColors.primary),
      const SizedBox(width: 8),
      _statCard('Monthly', '$_currency${_monthlyCost.toStringAsFixed(2)}', AppColors.signalEmerald),
      const SizedBox(width: 8),
      _statCard('Yearly', '$_currency${_yearlyCost.toStringAsFixed(0)}', AppColors.alertAmber),
    ],
  );

  Widget _statCard(String label, String value, int color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(color).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: gfont(AppType.bodySm, color: hex(color), size: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: gfont(AppType.bodyMd, color: hex(color), weight: FontWeight.w700, size: 13),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _tvSizeSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TV Type',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('$_tvWattage W',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _wattagePresets.map((p) {
            final active = _tvWattage == p.$2;
            return GestureDetector(
              onTap: () { setState(() => _tvWattage = p.$2); _save(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.6 : 0.2),
                  ),
                ),
                child: Text('${p.$1} (${p.$2}W)',
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 10)),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _usageSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Daily Usage',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_hoursPerDay.toStringAsFixed(1)} hrs',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.primary),
            inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
            thumbColor: hex(AppColors.primary),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: _hoursPerDay,
            min: 0.5,
            max: 24,
            divisions: 47,
            onChanged: (v) { setState(() => _hoursPerDay = v); _save(); },
          ),
        ),
      ],
    ),
  );

  Widget _rateSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Electricity Rate',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('$_currency${_electricityRate.toStringAsFixed(2)} / kWh',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.primary),
            inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
            thumbColor: hex(AppColors.primary),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: _electricityRate,
            min: 0.01,
            max: 0.50,
            divisions: 49,
            onChanged: (v) { setState(() => _electricityRate = v); _save(); },
          ),
        ),
      ],
    ),
  );

  Widget _costBreakdown() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cost Breakdown',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _costRow('Daily energy', '${_dailyKwh.toStringAsFixed(2)} kWh'),
        _costRow('Monthly energy', '${_monthlyKwh.toStringAsFixed(1)} kWh'),
        _costRow('Yearly energy', '${_yearlyKwh.toStringAsFixed(0)} kWh'),
        Divider(height: 16, thickness: 0.5, color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        _costRow('Monthly cost', '$_currency${_monthlyCost.toStringAsFixed(2)}'),
        _costRow('Yearly cost', '$_currency${_yearlyCost.toStringAsFixed(0)}'),
      ],
    ),
  );

  Widget _costRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        const Spacer(),
        Text(value, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 11)),
      ],
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Estimate your TV power consumption and running costs. Select your TV type, adjust daily usage hours, and set your local electricity rate.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
