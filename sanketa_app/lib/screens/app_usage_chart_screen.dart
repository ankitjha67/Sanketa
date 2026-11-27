import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class AppUsageChartScreen extends StatefulWidget {
  const AppUsageChartScreen({super.key});

  @override
  State<AppUsageChartScreen> createState() => _AppUsageChartScreenState();
}

class _AppUsageChartScreenState extends State<AppUsageChartScreen> {
  bool _loading = true;
  int _periodIndex = 0;

  static const _periods = ['Today', '7 Days', '30 Days'];

  List<_AppUsage> _apps = [];

  static final _rng = Random(42);

  static final _defaultApps = <_AppUsage>[
    _AppUsage(name: 'Netflix', minutes: 145, color: AppColors.error, icon: Icons.play_circle),
    _AppUsage(name: 'YouTube', minutes: 112, color: AppColors.secondary, icon: Icons.smart_display),
    _AppUsage(name: 'Disney+', minutes: 68, color: AppColors.primary, icon: Icons.movie),
    _AppUsage(name: 'Settings', minutes: 23, color: AppColors.tertiary, icon: Icons.settings),
    _AppUsage(name: 'Prime Video', minutes: 56, color: AppColors.signalEmerald, icon: Icons.video_library),
    _AppUsage(name: 'Spotify', minutes: 89, color: AppColors.alertAmber, icon: Icons.music_note),
    _AppUsage(name: 'Plex', minutes: 34, color: AppColors.outline, icon: Icons.live_tv),
    _AppUsage(name: 'Browser', minutes: 18, color: AppColors.outlineVariant, icon: Icons.language),
  ];

  int get _totalMinutes => _apps.fold(0, (s, a) => s + a.minutes);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/app_usage_chart.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _apps = list
            .map((e) => _AppUsage.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _apps = List.of(_defaultApps);
      }
    } catch (_) {
      _apps = List.of(_defaultApps);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_apps.map((a) => a.toJson()).toList()));
  }

  void _changePeriod(int idx) {
    setState(() {
      _periodIndex = idx;
      for (final a in _apps) {
        final mult = idx == 0 ? 1 : idx == 1 ? 5 : 20;
        a.minutes = (_defaultApps
                    .firstWhere((d) => d.name == a.name,
                        orElse: () => _defaultApps.first)
                    .minutes *
                mult +
            _rng.nextInt(30 * mult));
      }
    });
    HapticFeedback.selectionClick();
    _save();
  }

  void _resetData() {
    setState(() {
      _apps = List.of(_defaultApps);
      _periodIndex = 0;
    });
    HapticFeedback.mediumImpact();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('App Usage',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _resetData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.lg),
                _periodChips(),
                const SizedBox(height: AppSpacing.md),
                _statsRow(),
                const SizedBox(height: AppSpacing.lg),
                _barChart(),
                const SizedBox(height: AppSpacing.lg),
                ..._apps.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _appCard(a),
                    )),
                const SizedBox(height: AppSpacing.lg),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Usage Stats',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Track how much time you spend in each TV app',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _periodChips() => Row(
        children: _periods.asMap().entries.map((e) {
          final active = e.key == _periodIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => _changePeriod(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.tertiary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.tertiary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(e.value,
                        style: gfont(AppType.bodySm,
                            color: hex(active
                                ? AppColors.tertiary
                                : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 11)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child:
                  _statBadge('Total', _formatTime(_totalMinutes), AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child:
                  _statBadge('Apps', '${_apps.length}', AppColors.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Top',
                  _apps.isNotEmpty
                      ? _apps.reduce((a, b) => a.minutes > b.minutes ? a : b).name
                      : '-',
                  AppColors.tertiary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 16, weight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Widget _barChart() {
    final maxMin = _apps.isEmpty
        ? 1
        : _apps.map((a) => a.minutes).reduce(max);
    return Container(
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
          Text('Usage by App',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: AppSpacing.md),
          ..._apps.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(a.name,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 10),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        child: LinearProgressIndicator(
                          value: a.minutes / maxMin,
                          minHeight: 14,
                          backgroundColor:
                              hex(AppColors.outlineVariant).withValues(alpha: 0.1),
                          color: hex(a.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(_formatTime(a.minutes),
                          textAlign: TextAlign.right,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _appCard(_AppUsage app) {
    final pct = _totalMinutes > 0
        ? (app.minutes / _totalMinutes * 100).toStringAsFixed(1)
        : '0';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(app.color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(app.icon, size: 20, color: hex(app.color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text(_formatTime(app.minutes),
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hex(app.color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text('$pct%',
                style: gfont(AppType.bodySm,
                    color: hex(app.color),
                    weight: FontWeight.w600,
                    size: 10)),
          ),
        ],
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
                'View how much time you spend in each TV app. '
                'Switch between daily, weekly, and monthly views. Data stored locally only.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _AppUsage {
  String name;
  int minutes;
  int color;
  IconData icon;

  _AppUsage({
    required this.name,
    required this.minutes,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'minutes': minutes,
        'color': color,
        'icon': icon.codePoint,
      };

  factory _AppUsage.fromJson(Map<String, dynamic> j) {
    final name = j['name'] as String? ?? '';
    final def = _AppUsageChartScreenState._defaultApps
        .where((d) => d.name == name);
    return _AppUsage(
      name: name,
      minutes: j['minutes'] as int? ?? 0,
      color: def.isNotEmpty ? def.first.color : AppColors.outline,
      icon: def.isNotEmpty ? def.first.icon : Icons.apps,
    );
  }
}
