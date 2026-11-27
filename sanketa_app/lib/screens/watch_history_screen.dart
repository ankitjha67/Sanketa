import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  String _search = '';

  static const _colorCycle = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.signalEmerald,
    AppColors.alertAmber,
  ];

  List<Map<String, dynamic>> _entries = [
    {'name': 'CNN News', 'type': 'channel', 'duration': 45, 'time': '10:30 AM'},
    {'name': 'Netflix', 'type': 'app', 'duration': 120, 'time': '12:00 PM'},
    {'name': 'ESPN', 'type': 'channel', 'duration': 90, 'time': '2:00 PM'},
    {'name': 'YouTube', 'type': 'app', 'duration': 35, 'time': '4:15 PM'},
    {'name': 'HBO Max', 'type': 'app', 'duration': 60, 'time': '5:30 PM'},
    {'name': 'BBC World', 'type': 'channel', 'duration': 25, 'time': '7:00 PM'},
    {'name': 'Disney+', 'type': 'app', 'duration': 95, 'time': '8:00 PM'},
    {'name': 'Discovery', 'type': 'channel', 'duration': 40, 'time': '9:30 PM'},
    {'name': 'Prime Video', 'type': 'app', 'duration': 110, 'time': '10:00 PM'},
    {'name': 'Fox Sports', 'type': 'channel', 'duration': 55, 'time': '11:30 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/watch_history.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _entries = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/watch_history.json');
      await f.writeAsString(jsonEncode(_entries));
    } catch (_) {}
  }

  int get _totalMinutes =>
      _entries.fold(0, (sum, e) => sum + (e['duration'] as int));

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _entries;
    final q = _search.toLowerCase();
    return _entries
        .where((e) => (e['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  void _watchAgain(String name) {
    final rc = RemoteScope.of(context);
    rc.launch(name);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Launching $name'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _clearAll() {
    setState(() => _entries = []);
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Watch History',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_entries.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.delete_outline,
                    size: 22, color: hex(AppColors.outline)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _statsCard(),
          const SizedBox(height: AppSpacing.lg),
          _searchBar(),
          const SizedBox(height: AppSpacing.md),
          ..._filtered.asMap().entries.map(_entryCard),
          if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _search.isEmpty ? 'No watch history yet' : 'No results',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 12),
                ),
              ),
            ),
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
            Icon(Icons.history, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Viewing Log',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Track what you watch across channels and apps with timestamps',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsCard() => Container(
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
            _stat('${_entries.length}', 'Entries'),
            Container(
              height: 30,
              width: 1,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
            _stat('${(_totalMinutes / 60).toStringAsFixed(1)}h', 'Total Time'),
            Container(
              height: 30,
              width: 1,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
            _stat(
              _entries.isEmpty
                  ? '0m'
                  : '${(_totalMinutes / _entries.length).round()}m',
              'Avg Session',
            ),
          ],
        ),
      );

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w700,
                  size: 18)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _searchBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 13),
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _entryCard(MapEntry<int, Map<String, dynamic>> entry) {
    final e = entry.value;
    final color = _colorCycle[entry.key % _colorCycle.length];
    final isApp = e['type'] == 'app';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                isApp ? Icons.apps : Icons.tv,
                size: 18,
                color: hex(color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['name'] as String,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Row(
                    children: [
                      Text('${e['duration']}min',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      const SizedBox(width: 8),
                      Text(e['time'] as String,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _watchAgain(e['name'] as String),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Watch',
                    style: gfont(AppType.bodySm,
                        color: hex(color),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ),
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
                'Your viewing log stays on this device. Tap "Watch" to quickly relaunch a channel or app. Use search to filter entries.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
