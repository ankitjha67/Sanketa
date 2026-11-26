import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _FavChannel {
  _FavChannel({required this.number, required this.name, this.category = ''});

  factory _FavChannel.fromJson(Map<String, dynamic> j) => _FavChannel(
        number: j['number'] as int,
        name: j['name'] as String,
        category: j['category'] as String? ?? '',
      );

  final int number;
  final String name;
  final String category;

  Map<String, dynamic> toJson() =>
      {'number': number, 'name': name, 'category': category};
}

class ChannelSortScreen extends StatefulWidget {
  const ChannelSortScreen({super.key});

  @override
  State<ChannelSortScreen> createState() => _ChannelSortScreenState();
}

class _ChannelSortScreenState extends State<ChannelSortScreen> {
  List<_FavChannel> _channels = [];
  bool _loading = true;
  bool _editing = false;

  static const _sampleChannels = [
    (2, 'CBS', 'News'),
    (5, 'NBC', 'News'),
    (7, 'ABC', 'News'),
    (11, 'FOX', 'Entertainment'),
    (13, 'PBS', 'Documentary'),
    (25, 'ESPN', 'Sports'),
    (30, 'CNN', 'News'),
    (42, 'Discovery', 'Documentary'),
    (50, 'HBO', 'Movies'),
    (75, 'Cartoon Network', 'Kids'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_sort.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _channels =
            list.map((j) => _FavChannel.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (_channels.isEmpty) _loadSamples();
    if (mounted) setState(() => _loading = false);
  }

  void _loadSamples() {
    _channels = _sampleChannels
        .map((s) => _FavChannel(number: s.$1, name: s.$2, category: s.$3))
        .toList();
    _save();
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_channels.map((c) => c.toJson()).toList()));
  }

  void _moveUp(int idx) {
    if (idx <= 0) return;
    setState(() {
      final item = _channels.removeAt(idx);
      _channels.insert(idx - 1, item);
    });
    HapticFeedback.selectionClick();
    _save();
  }

  void _moveDown(int idx) {
    if (idx >= _channels.length - 1) return;
    setState(() {
      final item = _channels.removeAt(idx);
      _channels.insert(idx + 1, item);
    });
    HapticFeedback.selectionClick();
    _save();
  }

  void _deleteChannel(int idx) {
    setState(() => _channels.removeAt(idx));
    _save();
  }

  void _tuneChannel(int number) {
    final rc = RemoteScope.of(context);
    final digits = number.toString();
    for (final d in digits.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to Ch $number'),
        duration: const Duration(seconds: 1),
      ));
  }

  int _categoryColor(String cat) {
    switch (cat) {
      case 'News':
        return AppColors.primary;
      case 'Sports':
        return AppColors.signalEmerald;
      case 'Movies':
        return AppColors.secondary;
      case 'Entertainment':
        return AppColors.alertAmber;
      case 'Documentary':
        return AppColors.tertiary;
      case 'Kids':
        return AppColors.error;
      default:
        return AppColors.outline;
    }
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
        title: Text('Channel Sort',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _editing = !_editing),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _editing ? Icons.check : Icons.edit,
                size: 20,
                color: hex(_editing ? AppColors.signalEmerald : AppColors.outline),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Favorites (${_channels.length})',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
              if (_editing)
                Text('Drag to reorder',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          if (_channels.isEmpty)
            _emptyState()
          else
            ..._channels.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _channelRow(e.value, e.key),
                )),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.sort, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Organize Your Channels',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Reorder your favorite channels so the most-watched are at the top',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _channelRow(_FavChannel ch, int idx) {
    final catColor = _categoryColor(ch.category);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: hex(catColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Center(
              child: Text('${idx + 1}',
                  style: gfont(AppType.bodySm,
                      color: hex(catColor),
                      weight: FontWeight.w700,
                      size: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ch ${ch.number} — ${ch.name}',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                if (ch.category.isNotEmpty)
                  Text(ch.category,
                      style: gfont(AppType.bodySm,
                          color: hex(catColor), size: 9)),
              ],
            ),
          ),
          if (_editing) ...[
            GestureDetector(
              onTap: () => _moveUp(idx),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.arrow_upward,
                    size: 16, color: hex(AppColors.primary)),
              ),
            ),
            GestureDetector(
              onTap: () => _moveDown(idx),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.arrow_downward,
                    size: 16, color: hex(AppColors.primary)),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteChannel(idx),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: hex(AppColors.error)),
              ),
            ),
          ] else
            GestureDetector(
              onTap: () => _tuneChannel(ch.number),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Tune',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.playlist_add, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No favorite channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add channels from the Channel Guide',
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
                'Reorder your favorite channels by priority. Tap Edit to move channels up or down, or remove them. Tap Tune to switch to any channel instantly.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
