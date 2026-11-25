import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';


class _ChannelEntry {
  _ChannelEntry({required this.number, required this.name, required this.category, this.isFavourite = false});

  factory _ChannelEntry.fromJson(Map<String, dynamic> j) => _ChannelEntry(
    number: j['number'] as int,
    name: j['name'] as String,
    category: j['category'] as String,
    isFavourite: j['isFavourite'] as bool? ?? false,
  );

  final int number;
  final String name;
  final String category;
  bool isFavourite;

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'category': category,
    'isFavourite': isFavourite,
  };
}

class ChannelGuideScreen extends StatefulWidget {
  const ChannelGuideScreen({super.key});

  @override
  State<ChannelGuideScreen> createState() => _ChannelGuideScreenState();
}

class _ChannelGuideScreenState extends State<ChannelGuideScreen> {
  List<_ChannelEntry> _channels = [];
  String _filter = 'All';
  bool _loading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _defaultChannels = <Map<String, dynamic>>[
    {'number': 1, 'name': 'News 24', 'category': 'News'},
    {'number': 2, 'name': 'Sports HD', 'category': 'Sports'},
    {'number': 3, 'name': 'Movie Zone', 'category': 'Movies'},
    {'number': 4, 'name': 'Kids TV', 'category': 'Kids'},
    {'number': 5, 'name': 'Discovery', 'category': 'Documentary'},
    {'number': 6, 'name': 'Music Hits', 'category': 'Music'},
    {'number': 7, 'name': 'Comedy Central', 'category': 'Entertainment'},
    {'number': 8, 'name': 'CNN', 'category': 'News'},
    {'number': 9, 'name': 'ESPN', 'category': 'Sports'},
    {'number': 10, 'name': 'HBO', 'category': 'Movies'},
    {'number': 11, 'name': 'Cartoon Network', 'category': 'Kids'},
    {'number': 12, 'name': 'National Geographic', 'category': 'Documentary'},
    {'number': 15, 'name': 'MTV', 'category': 'Music'},
    {'number': 20, 'name': 'BBC World', 'category': 'News'},
    {'number': 25, 'name': 'Fox Sports', 'category': 'Sports'},
    {'number': 30, 'name': 'AMC', 'category': 'Movies'},
    {'number': 35, 'name': 'Nickelodeon', 'category': 'Kids'},
    {'number': 40, 'name': 'History Channel', 'category': 'Documentary'},
    {'number': 50, 'name': 'Drama Plus', 'category': 'Entertainment'},
    {'number': 99, 'name': 'Local Access', 'category': 'Entertainment'},
  ];

  static const _categories = ['All', 'Favourites', 'News', 'Sports', 'Movies', 'Kids', 'Documentary', 'Music', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_guide.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _channels = list.map((j) => _ChannelEntry.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // ignore
    }
    if (_channels.isEmpty) {
      _channels = _defaultChannels.map(_ChannelEntry.fromJson).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_channels.map((c) => c.toJson()).toList()));
  }

  void _tune(int channelNumber) {
    final c = RemoteScope.of(context);
    final digits = channelNumber.toString().split('');
    for (final d in digits) {
      final key = switch (d) {
        '0' => core.Key.digit0,
        '1' => core.Key.digit1,
        '2' => core.Key.digit2,
        '3' => core.Key.digit3,
        '4' => core.Key.digit4,
        '5' => core.Key.digit5,
        '6' => core.Key.digit6,
        '7' => core.Key.digit7,
        '8' => core.Key.digit8,
        '9' => core.Key.digit9,
        _ => core.Key.digit0,
      };
      c.key(key);
    }
    c.key(core.Key.ok);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Tuning to channel $channelNumber'),
          duration: const Duration(seconds: 1),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  List<_ChannelEntry> get _filtered {
    var list = _channels;
    if (_filter == 'Favourites') {
      list = list.where((c) => c.isFavourite).toList();
    } else if (_filter != 'All') {
      list = list.where((c) => c.category == _filter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) || c.number.toString().contains(q)).toList();
    }
    return list;
  }

  void _toggleFavourite(int index) {
    final ch = _channels.firstWhere((c) => c.number == _filtered[index].number);
    setState(() => ch.isFavourite = !ch.isFavourite);
    _save();
  }

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
        title: Text('Channel Guide',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _searchBar(),
          _categoryFilter(),
          Expanded(child: _channelList()),
        ],
      ),
    );
  }

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: hex(AppColors.outline)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 14),
              decoration: InputDecoration(
                hintText: 'Search channels...',
                hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline), size: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
        ],
      ),
    ),
  );

  Widget _categoryFilter() => SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      children: _categories.map((cat) {
        final active = _filter == cat;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => _filter = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                    .withValues(alpha: active ? 0.25 : 1),
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.6 : 0.2),
                ),
              ),
              child: Text(cat,
                  style: gfont(AppType.bodySm,
                      color: hex(active ? AppColors.primary : AppColors.onSurface),
                      weight: active ? FontWeight.w600 : FontWeight.w400,
                      size: 11)),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _channelList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tv_off, size: 32, color: hex(AppColors.outline)),
            const SizedBox(height: 8),
            Text('No channels found',
                style: gfont(AppType.bodyMd, color: hex(AppColors.outline))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _channelRow(list[i], i),
    );
  }

  Widget _channelRow(_ChannelEntry ch, int index) => GestureDetector(
    onTap: () => _tune(ch.number),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Center(
              child: Text('${ch.number}',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 13, weight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.name,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 13)),
                Text(ch.category,
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleFavourite(index),
            child: Icon(
              ch.isFavourite ? Icons.star : Icons.star_border,
              size: 18,
              color: hex(ch.isFavourite ? AppColors.alertAmber : AppColors.outlineVariant),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.play_arrow, size: 16, color: hex(AppColors.primary)),
        ],
      ),
    ),
  );
}
