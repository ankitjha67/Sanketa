import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvBookmarkScreen extends StatefulWidget {
  const TvBookmarkScreen({super.key});

  @override
  State<TvBookmarkScreen> createState() => _TvBookmarkScreenState();
}

class _TvBookmarkScreenState extends State<TvBookmarkScreen> {
  final List<_Bookmark> _bookmarks = [];
  int _filter = -1;

  static const _categories = <(String, IconData, int)>[
    ('All', Icons.bookmarks, AppColors.primary),
    ('Shows', Icons.tv, AppColors.signalEmerald),
    ('Movies', Icons.movie, AppColors.alertAmber),
    ('Sports', Icons.sports, AppColors.error),
    ('News', Icons.newspaper, AppColors.secondary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_bookmarks.json');
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _bookmarks.clear();
          for (final b in list) {
            final m = b as Map<String, dynamic>;
            _bookmarks.add(_Bookmark(
              m['name'] as String? ?? '',
              m['channel'] as String? ?? '',
              m['cat'] as int? ?? 1,
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
      final f = File('${dir.path}/tv_bookmarks.json');
      await f.writeAsString(jsonEncode(_bookmarks
          .map((b) => {
                'name': b.name,
                'channel': b.channel,
                'cat': b.category,
                'note': b.note,
              })
          .toList()));
    } catch (_) {}
  }

  void _tuneChannel(String ch) {
    final rc = RemoteScope.of(context);
    for (final d in ch.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    HapticFeedback.mediumImpact();
  }

  void _addBookmark() {
    setState(() {
      _bookmarks.insert(0, _Bookmark('New Bookmark', '', 1, ''));
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  void _removeBookmark(int idx) {
    setState(() => _bookmarks.removeAt(idx));
    _save();
    HapticFeedback.mediumImpact();
  }

  List<_Bookmark> get _filtered =>
      _filter <= 0 ? _bookmarks : _bookmarks.where((b) => b.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Bookmarks',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _addBookmark,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _categoryChips(),
          const SizedBox(height: AppSpacing.md),
          _statRow(),
          const SizedBox(height: AppSpacing.lg),
          if (items.isEmpty)
            _emptyState()
          else
            ...items.asMap().entries.map((e) {
              final realIdx = _bookmarks.indexOf(e.value);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _bookmarkCard(realIdx, e.value),
              );
            }),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.bookmark, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('TV Bookmarks',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Save channels and shows for quick access later',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _categoryChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.asMap().entries.map((e) {
            final active = (_filter <= 0 && e.key == 0) || e.key == _filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filter = e.key == 0 ? -1 : e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2, size: 14, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _statRow() => Row(
        children: [
          _stat('Total', '${_bookmarks.length}', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat('Shows', '${_bookmarks.where((b) => b.category == 1).length}',
              AppColors.signalEmerald),
          const SizedBox(width: AppSpacing.sm),
          _stat('Movies', '${_bookmarks.where((b) => b.category == 2).length}',
              AppColors.alertAmber),
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

  Widget _bookmarkCard(int idx, _Bookmark b) {
    final cat = _categories[b.category.clamp(0, _categories.length - 1)];
    return GestureDetector(
      onTap: b.channel.isNotEmpty ? () => _tuneChannel(b.channel) : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(cat.$3).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(cat.$3).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(cat.$2, size: 22, color: hex(cat.$3)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  if (b.channel.isNotEmpty)
                    Text('CH ${b.channel}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  if (b.note.isNotEmpty)
                    Text(b.note,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removeBookmark(idx),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.bookmark_border,
                size: 48, color: hex(AppColors.outlineVariant)),
            const SizedBox(height: 8),
            Text('No bookmarks yet',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline), size: 13)),
            Text('Tap + to add one',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
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
                'Bookmark channels, shows, and content for quick access. '
                'Tap to tune. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Bookmark {
  String name;
  String channel;
  int category;
  String note;
  _Bookmark(this.name, this.channel, this.category, this.note);
}
