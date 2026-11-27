import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class WatchLaterScreen extends StatefulWidget {
  const WatchLaterScreen({super.key});

  @override
  State<WatchLaterScreen> createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  bool _loading = true;
  String _filter = 'All';

  List<_WatchItem> _items = [];

  static final _defaults = <_WatchItem>[
    _WatchItem(title: 'Dune: Part Three', category: 'Movie', service: 'Netflix', added: '2026-11-27'),
    _WatchItem(title: 'Severance S3', category: 'Show', service: 'Apple TV+', added: '2026-11-26'),
    _WatchItem(title: 'Our Planet III', category: 'Doc', service: 'Netflix', added: '2026-11-25'),
    _WatchItem(title: 'The Batman Returns', category: 'Movie', service: 'HBO Max', added: '2026-11-24'),
    _WatchItem(title: 'Ted Lasso S4', category: 'Show', service: 'Apple TV+', added: '2026-11-23'),
    _WatchItem(title: 'Formula 1: DTS S6', category: 'Doc', service: 'Netflix', added: '2026-11-22'),
  ];

  static const _filters = ['All', 'Movie', 'Show', 'Doc'];

  List<_WatchItem> get _filtered =>
      _filter == 'All' ? _items : _items.where((i) => i.category == _filter).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/watch_later.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _items = list
            .map((e) => _WatchItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _items = _defaults
            .map((d) => _WatchItem(
                title: d.title,
                category: d.category,
                service: d.service,
                added: d.added))
            .toList();
      }
    } catch (_) {
      _items = _defaults
          .map((d) => _WatchItem(
              title: d.title,
              category: d.category,
              service: d.service,
              added: d.added))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_items.map((i) => i.toJson()).toList()));
  }

  void _play(_WatchItem item) {
    final rc = RemoteScope.of(context);
    rc.launch(item.title);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Playing: ${item.title}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _remove(int idx) {
    setState(() => _items.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _clearAll() {
    setState(() => _items.clear());
    HapticFeedback.mediumImpact();
    _save();
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Movie':
        return Icons.movie;
      case 'Show':
        return Icons.tv;
      case 'Doc':
        return Icons.description;
      default:
        return Icons.play_circle;
    }
  }

  int _catColor(String cat) {
    switch (cat) {
      case 'Movie':
        return AppColors.primary;
      case 'Show':
        return AppColors.secondary;
      case 'Doc':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  int _serviceColor(String service) {
    switch (service) {
      case 'Netflix':
        return AppColors.error;
      case 'Apple TV+':
        return AppColors.secondary;
      case 'HBO Max':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Watch Later',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: hex(AppColors.error)),
              onPressed: _clearAll,
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
                _statsRow(),
                const SizedBox(height: AppSpacing.md),
                _filterChips(),
                const SizedBox(height: AppSpacing.md),
                if (_filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(Icons.bookmark_border,
                              size: 40, color: hex(AppColors.outline)),
                          const SizedBox(height: 8),
                          Text('No items in your queue',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline), size: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  ..._filtered.asMap().entries.map((e) {
                    final realIdx = _items.indexOf(e.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _itemCard(realIdx, e.value),
                    );
                  }),
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
            Icon(Icons.bookmark, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Watch Queue',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Save shows and movies to watch later',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Total', '${_items.length}', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Movies',
                  '${_items.where((i) => i.category == "Movie").length}',
                  AppColors.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Shows',
                  '${_items.where((i) => i.category == "Show").length}',
                  AppColors.tertiary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(c).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 20, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _itemCard(int idx, _WatchItem item) => Container(
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
                color: hex(_catColor(item.category)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(_catIcon(item.category),
                  size: 20, color: hex(_catColor(item.category))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
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
                          color: hex(_serviceColor(item.service))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(item.service,
                            style: gfont(AppType.bodySm,
                                color: hex(_serviceColor(item.service)),
                                size: 8)),
                      ),
                      const SizedBox(width: 6),
                      Text(item.added,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 9)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _play(item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Icon(Icons.play_arrow,
                    size: 16, color: hex(AppColors.primary)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _remove(idx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Icon(Icons.close,
                    size: 14, color: hex(AppColors.error)),
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
                'Save movies, shows, and documentaries to your watch queue. '
                'Tap play to start watching on your TV. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _WatchItem {
  String title;
  String category;
  String service;
  String added;

  _WatchItem({
    required this.title,
    required this.category,
    required this.service,
    required this.added,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'service': service,
        'added': added,
      };

  factory _WatchItem.fromJson(Map<String, dynamic> j) => _WatchItem(
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? 'Movie',
        service: j['service'] as String? ?? '',
        added: j['added'] as String? ?? '',
      );
}
