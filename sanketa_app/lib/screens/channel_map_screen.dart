import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelMapScreen extends StatefulWidget {
  const ChannelMapScreen({super.key});

  @override
  State<ChannelMapScreen> createState() => _ChannelMapScreenState();
}

class _ChannelMapScreenState extends State<ChannelMapScreen> {
  int _categoryIndex = 0;

  static const _categories = [
    'All',
    'News',
    'Sports',
    'Movies',
    'Kids',
    'Music',
    'Docs',
    'Local',
  ];

  static const _categoryIcons = [
    Icons.grid_view,
    Icons.newspaper,
    Icons.sports_soccer,
    Icons.movie,
    Icons.child_care,
    Icons.music_note,
    Icons.science,
    Icons.location_city,
  ];

  static const _categoryColors = [
    AppColors.primary,
    AppColors.error,
    AppColors.signalEmerald,
    AppColors.secondary,
    AppColors.alertAmber,
    AppColors.tertiary,
    AppColors.primary,
    AppColors.signalEmerald,
  ];

  static const _channels = <(int, String, String)>[
    (1, 'CNN', 'News'),
    (2, 'BBC', 'News'),
    (3, 'Fox News', 'News'),
    (4, 'MSNBC', 'News'),
    (5, 'ESPN', 'Sports'),
    (6, 'Fox Sports', 'Sports'),
    (7, 'NBA TV', 'Sports'),
    (8, 'NFL Network', 'Sports'),
    (10, 'HBO', 'Movies'),
    (11, 'Showtime', 'Movies'),
    (12, 'AMC', 'Movies'),
    (13, 'TCM', 'Movies'),
    (15, 'Disney Jr', 'Kids'),
    (16, 'Cartoon Network', 'Kids'),
    (17, 'Nickelodeon', 'Kids'),
    (20, 'MTV', 'Music'),
    (21, 'VH1', 'Music'),
    (22, 'CMT', 'Music'),
    (25, 'Discovery', 'Docs'),
    (26, 'Nat Geo', 'Docs'),
    (27, 'History', 'Docs'),
    (30, 'ABC Local', 'Local'),
    (31, 'CBS Local', 'Local'),
    (32, 'NBC Local', 'Local'),
  ];

  List<(int, String, String)> get _filtered {
    if (_categoryIndex == 0) return _channels;
    final cat = _categories[_categoryIndex];
    return _channels.where((c) => c.$3 == cat).toList();
  }

  void _tuneChannel(int ch) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    final digits = ch.toString().split('');
    for (final d in digits) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to channel $ch'),
        duration: const Duration(seconds: 1),
      ));
  }

  int _colorForCategory(String cat) {
    final idx = _categories.indexOf(cat);
    return idx >= 0 ? _categoryColors[idx] : AppColors.outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Channel Map',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _categoryBar(),
          const SizedBox(height: AppSpacing.md),
          Text('${_filtered.length} Channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _channelGrid(),
          const SizedBox(height: AppSpacing.lg),
          _legendCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.map, size: 44, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Channel Map',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Visual overview of all available channels organized by category',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _categoryBar() => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _categoryIndex;
            return GestureDetector(
              onTap: () => setState(() => _categoryIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: hex(active ? _categoryColors[i] : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? _categoryColors[i] : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categoryIcons[i],
                        size: 14,
                        color: hex(active ? _categoryColors[i] : AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(_categories[i],
                        style: gfont(AppType.bodySm,
                            color: hex(active ? _categoryColors[i] : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 11)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _channelGrid() => GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _filtered.map((ch) {
          final cColor = _colorForCategory(ch.$3);
          return GestureDetector(
            onTap: () => _tuneChannel(ch.$1),
            child: Container(
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(cColor).withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hex(cColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Center(
                      child: Text('${ch.$1}',
                          style: gfont(AppType.bodyMd,
                              color: hex(cColor),
                              weight: FontWeight.w700,
                              size: 11)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(ch.$2,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 10)),
                  Text(ch.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 8)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _legendCard() => Container(
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
            Text('Legend',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: _categories.skip(1).toList().asMap().entries.map((e) {
                final color = _categoryColors[e.key + 1];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: hex(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(_categories[e.key + 1],
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface), size: 10)),
                  ],
                );
              }).toList(),
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
                'Browse all available channels organized by category. Tap any channel to tune in instantly. Filter by category to find what you want to watch.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
