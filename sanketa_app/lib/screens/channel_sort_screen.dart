import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class ChannelSortScreen extends StatefulWidget {
  const ChannelSortScreen({super.key});

  @override
  State<ChannelSortScreen> createState() => _ChannelSortScreenState();
}

class _ChannelSortScreenState extends State<ChannelSortScreen> {
  final List<_Channel> _channels = [
    _Channel('CNN', '203', 'News', true),
    _Channel('BBC World', '210', 'News', true),
    _Channel('ESPN', '400', 'Sports', true),
    _Channel('Fox Sports', '401', 'Sports', true),
    _Channel('Discovery', '250', 'Documentary', true),
    _Channel('HBO', '500', 'Movies', true),
    _Channel('Disney', '302', 'Kids', true),
    _Channel('Cartoon Network', '301', 'Kids', true),
    _Channel('MTV', '350', 'Music', false),
    _Channel('National Geographic', '260', 'Documentary', true),
  ];

  int _sortMode = 0;

  static const _sortModes = ['Custom', 'Name A-Z', 'Number', 'Category'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/channel_sort.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['channels'] as List<dynamic>? ?? [];
        setState(() {
          _sortMode = data['sort'] as int? ?? 0;
          _channels.clear();
          for (final c in list) {
            final m = c as Map<String, dynamic>;
            _channels.add(_Channel(
              m['name'] as String? ?? '',
              m['num'] as String? ?? '',
              m['cat'] as String? ?? '',
              m['vis'] as bool? ?? true,
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/channel_sort.json');
      await f.writeAsString(jsonEncode({
        'sort': _sortMode,
        'channels': _channels
            .map((c) => {
                  'name': c.name,
                  'num': c.number,
                  'cat': c.category,
                  'vis': c.visible,
                })
            .toList(),
      }));
    } catch (_) {}
  }

  void _reorder(int old, int next) {
    if (next > old) next -= 1;
    setState(() {
      final item = _channels.removeAt(old);
      _channels.insert(next, item);
    });
    _save();
    HapticFeedback.selectionClick();
  }

  void _toggleVisible(int idx) {
    setState(() => _channels[idx].visible = !_channels[idx].visible);
    _save();
    HapticFeedback.selectionClick();
  }

  void _applySortMode(int mode) {
    setState(() {
      _sortMode = mode;
      switch (mode) {
        case 1:
          _channels.sort((a, b) => a.name.compareTo(b.name));
        case 2:
          _channels.sort((a, b) {
            final an = int.tryParse(a.number) ?? 0;
            final bn = int.tryParse(b.number) ?? 0;
            return an.compareTo(bn);
          });
        case 3:
          _channels.sort((a, b) => a.category.compareTo(b.category));
        default:
          break;
      }
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final visCount = _channels.where((c) => c.visible).length;
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: _heroCard(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: _sortModeRow(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _statRow(visCount),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _channels.length,
              onReorderItem: (old, next) => _reorder(old, next),
              itemBuilder: (ctx, idx) => _channelTile(idx, _channels[idx]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _infoCard(),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.sort, size: 36, color: hex(AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sort & Organize',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.secondary),
                          weight: FontWeight.w600)),
                  Text(
                    'Reorder channels, hide unwanted, sort by name/number/category',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sortModeRow() => Row(
        children: _sortModes.asMap().entries.map((e) {
          final active = e.key == _sortMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => _applySortMode(e.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.2)),
                ),
                child: Center(
                  child: Text(e.value,
                      style: gfont(AppType.bodySm,
                          color: hex(
                              active ? AppColors.primary : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _statRow(int vis) => Row(
        children: [
          _stat('Total', '${_channels.length}', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat('Visible', '$vis', AppColors.signalEmerald),
          const SizedBox(width: AppSpacing.sm),
          _stat('Hidden', '${_channels.length - vis}', AppColors.outlineVariant),
        ],
      );

  Widget _stat(String label, String val, int c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: hex(c).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Text(val,
                  style: gfont(AppType.bodyMd,
                      color: hex(c), weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _channelTile(int idx, _Channel ch) => Container(
        key: ValueKey('ch_${idx}_${ch.number}'),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hex(ch.visible
                  ? AppColors.surfaceContainerLow
                  : AppColors.outlineVariant)
              .withValues(alpha: ch.visible ? 1 : 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_handle,
                size: 18, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Center(
                child: Text(ch.number,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.name,
                      style: gfont(AppType.bodySm,
                          color: hex(ch.visible
                              ? AppColors.onSurface
                              : AppColors.outline),
                          weight: FontWeight.w600,
                          size: 12)),
                  Text(ch.category,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleVisible(idx),
              child: Icon(
                ch.visible ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: hex(ch.visible
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant),
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
                'Sort and organize your channel lineup. Drag to reorder, '
                'toggle visibility, sort by name/number/category. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Channel {
  String name;
  String number;
  String category;
  bool visible;
  _Channel(this.name, this.number, this.category, this.visible);
}
