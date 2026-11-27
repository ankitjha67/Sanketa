import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class CastHistoryScreen extends StatefulWidget {
  const CastHistoryScreen({super.key});

  @override
  State<CastHistoryScreen> createState() => _CastHistoryScreenState();
}

class _CastHistoryScreenState extends State<CastHistoryScreen> {
  bool _loading = true;
  String _filter = 'All';

  List<_CastEntry> _entries = [];

  static final _defaults = <_CastEntry>[
    _CastEntry(title: 'Inception', type: 'Video', durationMin: 148, timestamp: '2026-11-27 20:30'),
    _CastEntry(title: 'Lofi Beats Playlist', type: 'Audio', durationMin: 62, timestamp: '2026-11-27 18:15'),
    _CastEntry(title: 'Holiday Photos', type: 'Photo', durationMin: 12, timestamp: '2026-11-27 15:00'),
    _CastEntry(title: 'Breaking Bad S5E16', type: 'Video', durationMin: 55, timestamp: '2026-11-26 21:00'),
    _CastEntry(title: 'Podcast: Tech Daily', type: 'Audio', durationMin: 45, timestamp: '2026-11-26 09:30'),
    _CastEntry(title: 'The Dark Knight', type: 'Video', durationMin: 152, timestamp: '2026-11-25 20:00'),
    _CastEntry(title: 'Vacation Album', type: 'Photo', durationMin: 8, timestamp: '2026-11-25 16:45'),
    _CastEntry(title: 'Chill Vibes Mix', type: 'Audio', durationMin: 90, timestamp: '2026-11-24 19:00'),
  ];

  static const _filters = ['All', 'Video', 'Audio', 'Photo'];

  int get _totalMinutes => _filtered.fold<int>(0, (s, e) => s + e.durationMin);

  List<_CastEntry> get _filtered =>
      _filter == 'All' ? _entries : _entries.where((e) => e.type == _filter).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cast_history.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _entries = list
            .map((e) => _CastEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _entries = _defaults
            .map((e) => _CastEntry(
                title: e.title,
                type: e.type,
                durationMin: e.durationMin,
                timestamp: e.timestamp))
            .toList();
      }
    } catch (_) {
      _entries = _defaults
          .map((e) => _CastEntry(
              title: e.title,
              type: e.type,
              durationMin: e.durationMin,
              timestamp: e.timestamp))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  void _castAgain(_CastEntry entry) {
    final rc = RemoteScope.of(context);
    rc.launch(entry.title);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Casting: ${entry.title}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _clearHistory() {
    setState(() => _entries.clear());
    HapticFeedback.mediumImpact();
    _save();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Video':
        return Icons.movie;
      case 'Audio':
        return Icons.music_note;
      case 'Photo':
        return Icons.photo;
      default:
        return Icons.cast;
    }
  }

  int _typeColor(String type) {
    switch (type) {
      case 'Video':
        return AppColors.primary;
      case 'Audio':
        return AppColors.secondary;
      case 'Photo':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  String _formatDuration(int min) {
    if (min < 60) return '${min}m';
    final h = min ~/ 60;
    final m = min % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Cast History',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: hex(AppColors.error)),
              onPressed: _clearHistory,
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
                _statsCard(),
                const SizedBox(height: AppSpacing.md),
                _filterChips(),
                const SizedBox(height: AppSpacing.md),
                if (_filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('No cast sessions found',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 12)),
                    ),
                  )
                else
                  ..._filtered.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _entryCard(e.value),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.cast_connected,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Cast Sessions',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'View your cast history and replay favourites',
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
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('${_entries.length}',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.primary),
                          size: 22,
                          weight: FontWeight.w700)),
                  Text('Sessions',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(_formatDuration(_totalMinutes),
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.secondary),
                          size: 22,
                          weight: FontWeight.w700)),
                  Text('Total Time',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _filterChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filter = f);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2),
                    ),
                  ),
                  child: Text(f,
                      style: gfont(AppType.bodySm,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _entryCard(_CastEntry entry) => Container(
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
                color: hex(_typeColor(entry.type)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(_typeIcon(entry.type),
                  size: 20, color: hex(_typeColor(entry.type))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(_typeColor(entry.type))
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(entry.type,
                            style: gfont(AppType.bodySm,
                                color: hex(_typeColor(entry.type)),
                                size: 9)),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatDuration(entry.durationMin),
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      const SizedBox(width: 6),
                      Text(entry.timestamp,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _castAgain(entry),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                      color: hex(AppColors.primary)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cast,
                        size: 12, color: hex(AppColors.primary)),
                    const SizedBox(width: 4),
                    Text('Cast',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600,
                            size: 9)),
                  ],
                ),
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
                'All cast sessions are logged locally. '
                'Tap "Cast" to replay any previous session on your TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _CastEntry {
  String title;
  String type;
  int durationMin;
  String timestamp;

  _CastEntry({
    required this.title,
    required this.type,
    required this.durationMin,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'durationMin': durationMin,
        'timestamp': timestamp,
      };

  factory _CastEntry.fromJson(Map<String, dynamic> j) => _CastEntry(
        title: j['title'] as String? ?? '',
        type: j['type'] as String? ?? 'Video',
        durationMin: j['durationMin'] as int? ?? 0,
        timestamp: j['timestamp'] as String? ?? '',
      );
}
