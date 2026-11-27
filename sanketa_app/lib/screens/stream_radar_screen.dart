import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class StreamRadarScreen extends StatefulWidget {
  const StreamRadarScreen({super.key});

  @override
  State<StreamRadarScreen> createState() => _StreamRadarScreenState();
}

class _StreamRadarScreenState extends State<StreamRadarScreen> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Movies', 'Shows', 'Docs'];

  static final _items = <_StreamItem>[
    _StreamItem(
        title: 'The Last Frontier',
        service: 'Netflix',
        type: 'Movie',
        genre: 'Sci-Fi',
        rating: 8.2,
        isNew: true),
    _StreamItem(
        title: 'Code Breakers S2',
        service: 'Prime Video',
        type: 'Show',
        genre: 'Thriller',
        rating: 7.8,
        isNew: true),
    _StreamItem(
        title: 'Ocean Deep',
        service: 'Disney+',
        type: 'Doc',
        genre: 'Nature',
        rating: 9.1,
        isNew: true),
    _StreamItem(
        title: 'Midnight Riders',
        service: 'Hulu',
        type: 'Movie',
        genre: 'Action',
        rating: 7.4,
        isNew: false),
    _StreamItem(
        title: 'The Kitchen S5',
        service: 'Netflix',
        type: 'Show',
        genre: 'Comedy',
        rating: 8.0,
        isNew: false),
    _StreamItem(
        title: 'Mars Colony',
        service: 'Apple TV+',
        type: 'Doc',
        genre: 'Science',
        rating: 8.5,
        isNew: true),
    _StreamItem(
        title: 'Shadow Game',
        service: 'Prime Video',
        type: 'Movie',
        genre: 'Mystery',
        rating: 7.9,
        isNew: false),
    _StreamItem(
        title: 'City Beats S3',
        service: 'Hulu',
        type: 'Show',
        genre: 'Drama',
        rating: 8.3,
        isNew: true),
    _StreamItem(
        title: 'Wild Planet',
        service: 'Disney+',
        type: 'Doc',
        genre: 'Nature',
        rating: 8.7,
        isNew: false),
    _StreamItem(
        title: 'Zero Hour',
        service: 'Netflix',
        type: 'Movie',
        genre: 'Thriller',
        rating: 7.6,
        isNew: true),
  ];

  List<_StreamItem> get _filtered {
    if (_filterIndex == 0) return _items;
    final type = _filters[_filterIndex].substring(
        0, _filters[_filterIndex].length - 1);
    return _items.where((i) => i.type == type).toList();
  }

  int _serviceColor(String service) {
    switch (service) {
      case 'Netflix':
        return AppColors.error;
      case 'Prime Video':
        return AppColors.primary;
      case 'Disney+':
        return AppColors.tertiary;
      case 'Hulu':
        return AppColors.signalEmerald;
      case 'Apple TV+':
        return AppColors.secondary;
      default:
        return AppColors.outline;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
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

  void _openItem(_StreamItem item) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Opening ${item.title} on ${item.service}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final newCount = _items.where((i) => i.isNew).length;
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Stream Radar',
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
          _statsRow(newCount),
          const SizedBox(height: AppSpacing.md),
          _filterChips(),
          const SizedBox(height: AppSpacing.md),
          if (_filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('No content in this category',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 12)),
              ),
            )
          else
            ..._filtered.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _itemCard(item),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.radar, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('New Content Alerts',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Discover new releases across your streaming services',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow(int newCount) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  Text('${_items.length}',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.primary),
                          size: 20,
                          weight: FontWeight.w700)),
                  Text('Total',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  Text('$newCount',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.signalEmerald),
                          size: 20,
                          weight: FontWeight.w700)),
                  Text('New',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.secondary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  Text('5',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.secondary),
                          size: 20,
                          weight: FontWeight.w700)),
                  Text('Services',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _filterChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.asMap().entries.map((e) {
            final active = e.key == _filterIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filterIndex = e.key);
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
                  child: Text(e.value,
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

  Widget _itemCard(_StreamItem item) => GestureDetector(
        onTap: () => _openItem(item),
        child: Container(
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
                  color: hex(_serviceColor(item.service))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(_typeIcon(item.type),
                    size: 20,
                    color: hex(_serviceColor(item.service))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.title,
                              overflow: TextOverflow.ellipsis,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: FontWeight.w600,
                                  size: 13)),
                        ),
                        if (item.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: hex(AppColors.signalEmerald)
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text('NEW',
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.signalEmerald),
                                    weight: FontWeight.w700,
                                    size: 7)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hex(_serviceColor(item.service))
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text(item.service,
                              style: gfont(AppType.bodySm,
                                  color: hex(_serviceColor(item.service)),
                                  size: 8)),
                        ),
                        const SizedBox(width: 6),
                        Text(item.genre,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 10)),
                        const SizedBox(width: 6),
                        Icon(Icons.star, size: 10, color: hex(AppColors.secondary)),
                        const SizedBox(width: 2),
                        Text('${item.rating}',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.secondary), size: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: hex(AppColors.outline)),
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
                'Stream Radar shows new and trending content across your '
                'streaming services. Tap an item to open it on your TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _StreamItem {
  final String title;
  final String service;
  final String type;
  final String genre;
  final double rating;
  final bool isNew;

  _StreamItem({
    required this.title,
    required this.service,
    required this.type,
    required this.genre,
    required this.rating,
    required this.isNew,
  });
}
