import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _TvApp {
  _TvApp({required this.name, required this.iconCode, this.category = 'Other', this.isFavourite = false});

  factory _TvApp.fromJson(Map<String, dynamic> j) => _TvApp(
    name: j['name'] as String,
    iconCode: j['icon'] as int,
    category: j['category'] as String? ?? 'Other',
    isFavourite: j['isFavourite'] as bool? ?? false,
  );

  final String name;
  final int iconCode;
  final String category;
  bool isFavourite;

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': iconCode,
    'category': category,
    'isFavourite': isFavourite,
  };
}

class TvAppManagerScreen extends StatefulWidget {
  const TvAppManagerScreen({super.key});

  @override
  State<TvAppManagerScreen> createState() => _TvAppManagerScreenState();
}

class _TvAppManagerScreenState extends State<TvAppManagerScreen> {
  late List<_TvApp> _apps;
  String _filter = 'All';
  bool _loading = true;

  static const _categories = ['All', 'Favourites', 'Streaming', 'Music', 'Games', 'Utility', 'Other'];

  @override
  void initState() {
    super.initState();
    _apps = _defaultApps();
    _load();
  }

  List<_TvApp> _defaultApps() => [
    _TvApp(name: 'Netflix', iconCode: Icons.movie.codePoint, category: 'Streaming', isFavourite: true),
    _TvApp(name: 'YouTube', iconCode: Icons.play_circle.codePoint, category: 'Streaming', isFavourite: true),
    _TvApp(name: 'Prime Video', iconCode: Icons.video_library.codePoint, category: 'Streaming'),
    _TvApp(name: 'Disney+', iconCode: Icons.star.codePoint, category: 'Streaming'),
    _TvApp(name: 'Spotify', iconCode: Icons.music_note.codePoint, category: 'Music'),
    _TvApp(name: 'Apple Music', iconCode: Icons.library_music.codePoint, category: 'Music'),
    _TvApp(name: 'Plex', iconCode: Icons.perm_media.codePoint, category: 'Streaming'),
    _TvApp(name: 'Twitch', iconCode: Icons.live_tv.codePoint, category: 'Streaming'),
    _TvApp(name: 'Steam Link', iconCode: Icons.games.codePoint, category: 'Games'),
    _TvApp(name: 'GeForce NOW', iconCode: Icons.videogame_asset.codePoint, category: 'Games'),
    _TvApp(name: 'Browser', iconCode: Icons.language.codePoint, category: 'Utility'),
    _TvApp(name: 'File Manager', iconCode: Icons.folder.codePoint, category: 'Utility'),
    _TvApp(name: 'Settings', iconCode: Icons.settings.codePoint, category: 'Utility'),
    _TvApp(name: 'App Store', iconCode: Icons.store.codePoint, category: 'Utility'),
  ];

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_apps.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _apps = list.map((j) => _TvApp.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_apps.map((a) => a.toJson()).toList()));
  }

  List<_TvApp> get _filtered {
    if (_filter == 'All') return _apps;
    if (_filter == 'Favourites') return _apps.where((a) => a.isFavourite).toList();
    return _apps.where((a) => a.category == _filter).toList();
  }

  void _toggleFav(int globalIndex) {
    setState(() => _apps[globalIndex].isFavourite = !_apps[globalIndex].isFavourite);
    _save();
  }

  void _launchApp(String name) {
    RemoteScope.of(context).launch(name);
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
        title: Text('TV Apps',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text('${_apps.length} apps',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _categoryChips(),
          Expanded(child: _appGrid()),
        ],
      ),
    );
  }

  Widget _categoryChips() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final active = _filter == c;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.6 : 0.2),
                  ),
                ),
                child: Text(c,
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 11)),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _appGrid() {
    final apps = _filtered;
    if (apps.isEmpty) {
      return Center(
        child: Text('No apps in this category',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: apps.length,
      itemBuilder: (_, i) {
        final app = apps[i];
        final globalIndex = _apps.indexOf(app);
        return _appTile(app, globalIndex);
      },
    );
  }

  Widget _appTile(_TvApp app, int globalIndex) => GestureDetector(
    onTap: () => _launchApp(app.name),
    onLongPress: () => _toggleFav(globalIndex),
    child: Container(
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(app.icon, size: 26, color: hex(AppColors.primary)),
              if (app.isFavourite)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Icon(Icons.star, size: 10, color: hex(AppColors.alertAmber)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 9)),
          Text(app.category,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 7)),
        ],
      ),
    ),
  );
}
