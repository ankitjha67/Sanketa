import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Bookmark {
  _Bookmark({
    required this.title,
    required this.service,
    this.season = '',
    this.episode = '',
    this.notes = '',
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory _Bookmark.fromJson(Map<String, dynamic> j) => _Bookmark(
        title: j['title'] as String,
        service: j['service'] as String,
        season: j['season'] as String? ?? '',
        episode: j['episode'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        addedAt:
            DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );

  final String title;
  final String service;
  final String season;
  final String episode;
  final String notes;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'service': service,
        'season': season,
        'episode': episode,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
      };

  String get progressStr {
    if (season.isEmpty && episode.isEmpty) return '';
    if (season.isNotEmpty && episode.isNotEmpty) return 'S$season E$episode';
    if (season.isNotEmpty) return 'Season $season';
    return 'Episode $episode';
  }
}

class ContentBookmarksScreen extends StatefulWidget {
  const ContentBookmarksScreen({super.key});

  @override
  State<ContentBookmarksScreen> createState() =>
      _ContentBookmarksScreenState();
}

class _ContentBookmarksScreenState extends State<ContentBookmarksScreen> {
  List<_Bookmark> _bookmarks = [];
  bool _loading = true;
  int _filterIndex = 0;
  final _titleCtrl = TextEditingController();
  final _seasonCtrl = TextEditingController();
  final _episodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _serviceIndex = 0;

  static const _services = [
    ('All', Icons.apps, AppColors.outline),
    ('Netflix', Icons.movie, AppColors.error),
    ('YouTube', Icons.play_circle, AppColors.error),
    ('Prime', Icons.shopping_bag, AppColors.primary),
    ('Disney+', Icons.castle, AppColors.tertiary),
    ('Apple TV', Icons.apple, AppColors.onSurface),
    ('Other', Icons.tv, AppColors.secondary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _seasonCtrl.dispose();
    _episodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/content_bookmarks.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _bookmarks = list
            .map((j) => _Bookmark.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(
        jsonEncode(_bookmarks.map((b) => b.toJson()).toList()));
  }

  void _addBookmark() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _bookmarks.insert(
        0,
        _Bookmark(
          title: title,
          service: _services[_serviceIndex + 1].$1,
          season: _seasonCtrl.text.trim(),
          episode: _episodeCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        ),
      );
      if (_bookmarks.length > 100) {
        _bookmarks = _bookmarks.sublist(0, 100);
      }
    });
    _titleCtrl.clear();
    _seasonCtrl.clear();
    _episodeCtrl.clear();
    _notesCtrl.clear();
    _save();
  }

  void _delete(int index) {
    setState(() => _bookmarks.removeAt(index));
    _save();
  }

  void _watchNow(_Bookmark b) {
    final rc = RemoteScope.of(context);
    rc.launch(b.service);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Launching ${b.service}'),
        duration: const Duration(seconds: 2),
      ));
  }

  List<_Bookmark> get _filtered {
    if (_filterIndex == 0) return _bookmarks;
    final service = _services[_filterIndex].$1;
    return _bookmarks.where((b) => b.service == service).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
        title: Text('Bookmarks',
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
          _addSection(),
          const SizedBox(height: AppSpacing.md),
          _filterBar(),
          const SizedBox(height: AppSpacing.md),
          if (_filtered.isEmpty)
            _emptyState()
          else ...[
            Text('${_filtered.length} Bookmarks',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._filtered.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child:
                      _bookmarkCard(e.value, _bookmarks.indexOf(e.value)),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
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
            Icon(Icons.bookmark,
                size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Content Bookmarks',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Save shows and movies to watch later. Track your progress across streaming services.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _addSection() => Container(
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
            Text('Add Bookmark',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: _inputDecor('Show or movie name'),
            ),
            const SizedBox(height: 8),
            _serviceSelector(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seasonCtrl,
                    keyboardType: TextInputType.number,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface)),
                    decoration: _inputDecor('Season'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _episodeCtrl,
                    keyboardType: TextInputType.number,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface)),
                    decoration: _inputDecor('Episode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: _inputDecor('Notes (optional)'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addBookmark,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Add Bookmark',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: gfont(AppType.bodySm,
            color: hex(AppColors.outline).withValues(alpha: 0.5)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
              color:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );

  Widget _serviceSelector() => SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _services.length - 1,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final s = _services[i + 1];
            final active = i == _serviceIndex;
            return GestureDetector(
              onTap: () => setState(() => _serviceIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active ? s.$3 : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? s.$3 : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.$2,
                        size: 12,
                        color: hex(active ? s.$3 : AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(s.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? s.$3 : AppColors.onSurface),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            size: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _filterBar() => SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _services.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final s = _services[i];
            final active = i == _filterIndex;
            final count = i == 0
                ? _bookmarks.length
                : _bookmarks.where((b) => b.service == s.$1).length;
            return GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Center(
                  child: Text('${s.$1} ($count)',
                      style: gfont(AppType.bodySm,
                          color: hex(
                              active ? AppColors.primary : AppColors.outline),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              ),
            );
          },
        ),
      );

  Widget _bookmarkCard(_Bookmark b, int index) {
    final sIdx =
        _services.indexWhere((s) => s.$1 == b.service);
    final sColor = sIdx >= 0 ? _services[sIdx].$3 : AppColors.outline;
    final sIcon = sIdx >= 0 ? _services[sIdx].$2 : Icons.tv;

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Text(b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
              ),
              GestureDetector(
                onTap: () => _watchNow(b),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 12, color: hex(AppColors.primary)),
                      const SizedBox(width: 2),
                      Text('Watch',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.primary),
                              size: 9,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(sIcon, size: 10, color: hex(sColor)),
              const SizedBox(width: 4),
              Text(b.service,
                  style: gfont(AppType.bodySm,
                      color: hex(sColor),
                      size: 9,
                      weight: FontWeight.w600)),
              if (b.progressStr.isNotEmpty) ...[
                Text('  ·  ${b.progressStr}',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary), size: 9)),
              ],
              Text('  ·  ${_timeAgo(b.addedAt)}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
              const Spacer(),
              GestureDetector(
                onTap: () => _delete(index),
                child:
                    Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
              ),
            ],
          ),
          if (b.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(b.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.bookmark_border,
              size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No bookmarks yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              'Save shows and movies you want to watch later across all your streaming services.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
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
                'Bookmark shows and movies across streaming services. Track season and episode progress. Tap Watch to launch the service on your TV. All bookmarks are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
