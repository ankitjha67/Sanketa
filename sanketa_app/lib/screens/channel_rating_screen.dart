import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class ChannelRatingScreen extends StatefulWidget {
  const ChannelRatingScreen({super.key});

  @override
  State<ChannelRatingScreen> createState() => _ChannelRatingScreenState();
}

class _ChannelRatingScreenState extends State<ChannelRatingScreen> {
  final List<_Rating> _ratings = [
    _Rating('CNN', '203', 4, 'Great coverage'),
    _Rating('ESPN', '400', 5, 'Best sports'),
    _Rating('HBO', '500', 5, 'Quality movies'),
    _Rating('Discovery', '250', 3, 'Decent docs'),
    _Rating('Disney', '302', 4, 'Kids love it'),
    _Rating('MTV', '350', 2, 'Too many ads'),
    _Rating('Fox Sports', '401', 3, 'Ok for football'),
    _Rating('BBC World', '210', 4, 'Reliable news'),
  ];

  int _sortMode = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/channel_ratings.json');
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _ratings.clear();
          for (final r in list) {
            final m = r as Map<String, dynamic>;
            _ratings.add(_Rating(
              m['name'] as String? ?? '',
              m['ch'] as String? ?? '',
              m['stars'] as int? ?? 3,
              m['note'] as String? ?? '',
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/channel_ratings.json');
      await f.writeAsString(jsonEncode(_ratings
          .map((r) => {
                'name': r.name,
                'ch': r.channel,
                'stars': r.stars,
                'note': r.note,
              })
          .toList()));
    } catch (_) {}
  }

  void _setRating(int idx, int stars) {
    setState(() => _ratings[idx].stars = stars);
    _save();
    HapticFeedback.selectionClick();
  }

  void _sortByRating() {
    setState(() {
      _sortMode = _sortMode == 1 ? 0 : 1;
      if (_sortMode == 1) {
        _ratings.sort((a, b) => b.stars.compareTo(a.stars));
      }
    });
    HapticFeedback.mediumImpact();
  }

  double get _avgRating {
    if (_ratings.isEmpty) return 0;
    return _ratings.fold(0, (s, r) => s + r.stars) / _ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Channel Ratings',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              _sortMode == 1 ? Icons.sort : Icons.sort_by_alpha,
              color: hex(AppColors.primary),
            ),
            onPressed: _sortByRating,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          ..._ratings.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ratingCard(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.star, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Channel Ratings',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Rate your channels and sort by favorites',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _stat('Channels', '${_ratings.length}', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat('Avg', _avgRating.toStringAsFixed(1), AppColors.alertAmber),
          const SizedBox(width: AppSpacing.sm),
          _stat(
              '5-Star',
              '${_ratings.where((r) => r.stars == 5).length}',
              AppColors.signalEmerald),
        ],
      );

  Widget _stat(String label, String val, int c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(c).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Text(val,
                  style: gfont(AppType.headlineMd,
                      color: hex(c), size: 18, weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _ratingCard(int idx, _Rating r) {
    final clr = r.stars >= 4
        ? AppColors.signalEmerald
        : r.stars >= 3
            ? AppColors.alertAmber
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(clr).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(clr).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text('CH ${r.channel}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (s) {
                  return GestureDetector(
                    onTap: () => _setRating(idx, s + 1),
                    child: Icon(
                      s < r.stars ? Icons.star : Icons.star_border,
                      size: 22,
                      color: hex(AppColors.alertAmber),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.note,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
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
                'Rate channels 1-5 stars and add notes. '
                'Sort by rating to find your favorites. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Rating {
  String name;
  String channel;
  int stars;
  String note;
  _Rating(this.name, this.channel, this.stars, this.note);
}
