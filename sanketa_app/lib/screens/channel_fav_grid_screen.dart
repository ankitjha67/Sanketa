import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelFavGridScreen extends StatefulWidget {
  const ChannelFavGridScreen({super.key});

  @override
  State<ChannelFavGridScreen> createState() => _ChannelFavGridScreenState();
}

class _ChannelFavGridScreenState extends State<ChannelFavGridScreen> {
  bool _loading = true;
  bool _editMode = false;

  List<_FavChannel> _channels = [];

  static final _defaults = <_FavChannel>[
    _FavChannel(number: '7', name: 'CNN', category: 'News', color: AppColors.error),
    _FavChannel(number: '12', name: 'ESPN', category: 'Sports', color: AppColors.signalEmerald),
    _FavChannel(number: '23', name: 'HBO', category: 'Movies', color: AppColors.secondary),
    _FavChannel(number: '31', name: 'Discovery', category: 'Docs', color: AppColors.tertiary),
    _FavChannel(number: '44', name: 'Cartoon Net', category: 'Kids', color: AppColors.alertAmber),
    _FavChannel(number: '55', name: 'Fox News', category: 'News', color: AppColors.primary),
    _FavChannel(number: '67', name: 'BBC World', category: 'News', color: AppColors.outline),
    _FavChannel(number: '78', name: 'MTV', category: 'Music', color: AppColors.secondary),
    _FavChannel(number: '89', name: 'Nat Geo', category: 'Docs', color: AppColors.signalEmerald),
    _FavChannel(number: '99', name: 'Comedy', category: 'Entertainment', color: AppColors.alertAmber),
    _FavChannel(number: '102', name: 'AMC', category: 'Movies', color: AppColors.error),
    _FavChannel(number: '115', name: 'Disney', category: 'Kids', color: AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_fav_grid.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _channels = list.map((e) {
          final j = e as Map<String, dynamic>;
          final name = j['name'] as String? ?? '';
          final def = _defaults.where((d) => d.name == name);
          return _FavChannel(
            number: j['number'] as String? ?? '',
            name: name,
            category: j['category'] as String? ?? '',
            color: def.isNotEmpty ? def.first.color : AppColors.outline,
          );
        }).toList();
      } else {
        _channels = List.of(_defaults);
      }
    } catch (_) {
      _channels = List.of(_defaults);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_channels
        .map((c) => {
              'number': c.number,
              'name': c.name,
              'category': c.category,
            })
        .toList()));
  }

  void _tune(_FavChannel ch) {
    final rc = RemoteScope.of(context);
    for (final d in ch.number.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to Ch ${ch.number} — ${ch.name}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _remove(int idx) {
    setState(() => _channels.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _reset() {
    setState(() {
      _channels = List.of(_defaults);
      _editMode = false;
    });
    HapticFeedback.mediumImpact();
    _save();
  }

  int _catColor(String cat) {
    switch (cat) {
      case 'News':
        return AppColors.error;
      case 'Sports':
        return AppColors.signalEmerald;
      case 'Movies':
        return AppColors.secondary;
      case 'Docs':
        return AppColors.tertiary;
      case 'Kids':
        return AppColors.alertAmber;
      case 'Music':
        return AppColors.secondary;
      case 'Entertainment':
        return AppColors.primary;
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
        title: Text('Fav Channels',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit,
                color: hex(_editMode ? AppColors.signalEmerald : AppColors.outline)),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _reset,
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
                _channelGrid(),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.star, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Favourite Grid',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Quick-access grid of your favourite channels',
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
                  'Favourites', '${_channels.length}', AppColors.alertAmber)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Categories',
                  '${_channels.map((c) => c.category).toSet().length}',
                  AppColors.secondary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
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

  Widget _channelGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.9,
        children: _channels
            .asMap()
            .entries
            .map((e) => _channelTile(e.key, e.value))
            .toList(),
      );

  Widget _channelTile(int idx, _FavChannel ch) => GestureDetector(
        onTap: _editMode ? () => _remove(idx) : () => _tune(ch),
        child: Container(
          decoration: BoxDecoration(
            color: hex(ch.color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(ch.color).withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              if (_editMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.remove_circle,
                      size: 18, color: hex(AppColors.error)),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hex(ch.color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(ch.number,
                            style: gfont(AppType.bodyMd,
                                color: hex(ch.color),
                                weight: FontWeight.w700,
                                size: 14)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(ch.name,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w500,
                            size: 10),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hex(_catColor(ch.category))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(ch.category,
                          style: gfont(AppType.bodySm,
                              color: hex(_catColor(ch.category)),
                              size: 7)),
                    ),
                  ],
                ),
              ),
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
                'Tap a channel to tune in. Use Edit mode to remove channels. '
                'Reset restores defaults. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _FavChannel {
  String number;
  String name;
  String category;
  int color;
  _FavChannel({
    required this.number,
    required this.name,
    required this.category,
    required this.color,
  });
}
