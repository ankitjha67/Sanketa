import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ChannelFilterScreen extends StatefulWidget {
  const ChannelFilterScreen({super.key});

  @override
  State<ChannelFilterScreen> createState() => _ChannelFilterScreenState();
}

class _ChannelFilterScreenState extends State<ChannelFilterScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _categoryFilter = 'All';
  bool _loading = true;

  static const _categories = ['All', 'News', 'Sports', 'Entertainment', 'Shopping', 'Adult'];

  final _channels = <_ChEntry>[
    _ChEntry(num: 12, name: 'CNN', category: 'News'),
    _ChEntry(num: 45, name: 'ESPN', category: 'Sports'),
    _ChEntry(num: 78, name: 'QVC Shopping', category: 'Shopping'),
    _ChEntry(num: 99, name: 'Home Shopping', category: 'Shopping'),
    _ChEntry(num: 120, name: 'Adult Swim', category: 'Adult'),
    _ChEntry(num: 150, name: 'BBC World', category: 'News'),
    _ChEntry(num: 200, name: 'Infomercials+', category: 'Shopping'),
    _ChEntry(num: 250, name: 'Fox Sports', category: 'Sports'),
    _ChEntry(num: 310, name: 'Comedy Central', category: 'Entertainment'),
    _ChEntry(num: 400, name: 'HBO Late Night', category: 'Adult'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_filter.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final blocked = (data['blocked'] as List?)?.cast<int>() ?? [];
        final reasons = (data['reasons'] as Map?)?.cast<String, String>() ?? {};
        for (final ch in _channels) {
          if (blocked.contains(ch.num)) ch.blocked = true;
          if (reasons.containsKey('${ch.num}')) ch.reason = reasons['${ch.num}']!;
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final blocked = _channels.where((c) => c.blocked).map((c) => c.num).toList();
    final reasons = <String, String>{};
    for (final ch in _channels) {
      if (ch.reason.isNotEmpty) reasons['${ch.num}'] = ch.reason;
    }
    final f = await _file;
    await f.writeAsString(jsonEncode({'blocked': blocked, 'reasons': reasons}));
  }

  void _toggleBlock(int idx) {
    setState(() => _channels[idx].blocked = !_channels[idx].blocked);
    HapticFeedback.selectionClick();
    _save();
  }

  void _setReason(int idx, String reason) {
    setState(() => _channels[idx].reason = reason);
    _save();
  }

  List<_ChEntry> get _filtered {
    var list = _channels.toList();
    if (_categoryFilter != 'All') {
      list = list.where((c) => c.category == _categoryFilter).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              '${c.num}'.contains(q))
          .toList();
    }
    return list;
  }

  int get _blockedCount => _channels.where((c) => c.blocked).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Channel Filter',
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
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _searchBar(),
          const SizedBox(height: AppSpacing.md),
          _categoryChips(),
          const SizedBox(height: AppSpacing.lg),
          Text('Channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._filtered.asMap().entries.map((e) => _channelCard(
              _channels.indexOf(e.value), e.value)),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.block, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('Channel Filter',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Block channels from appearing in your TV guide',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _statBadge('$_blockedCount', 'Blocked', AppColors.error),
          const SizedBox(width: 8),
          _statBadge('${_channels.length - _blockedCount}', 'Visible', AppColors.signalEmerald),
          const SizedBox(width: 8),
          _statBadge('${_channels.length}', 'Total', AppColors.primary),
        ],
      );

  Widget _statBadge(String value, String label, int color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: gfont(AppType.bodyMd,
                      color: hex(color), weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
      );

  Widget _searchBar() => TextField(
        controller: _searchCtrl,
        style: gfont(AppType.bodySm,
            color: hex(AppColors.onSurface), size: 13),
        decoration: InputDecoration(
          hintText: 'Search channels...',
          hintStyle:
              gfont(AppType.bodySm, color: hex(AppColors.outline), size: 13),
          prefixIcon:
              Icon(Icons.search, color: hex(AppColors.outline), size: 20),
          filled: true,
          fillColor: hex(AppColors.surfaceContainerLow),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (v) => setState(() => _query = v),
      );

  Widget _categoryChips() => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final c = _categories[i];
            final sel = _categoryFilter == c;
            return GestureDetector(
              onTap: () {
                setState(() => _categoryFilter = c);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: hex(sel ? AppColors.primary : AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(c,
                    style: gfont(AppType.bodySm,
                        color: hex(
                            sel ? AppColors.onPrimary : AppColors.onSurface),
                        weight: sel ? FontWeight.w600 : FontWeight.w400,
                        size: 12)),
              ),
            );
          },
        ),
      );

  Widget _channelCard(int idx, _ChEntry ch) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(ch.blocked ? AppColors.error : AppColors.outlineVariant)
                    .withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('CH ${ch.num}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w700,
                            size: 10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ch.name,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                  ),
                  GestureDetector(
                    onTap: () => _toggleBlock(idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hex(ch.blocked
                                ? AppColors.error
                                : AppColors.signalEmerald)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(ch.blocked ? 'Blocked' : 'Visible',
                          style: gfont(AppType.bodySm,
                              color: hex(ch.blocked
                                  ? AppColors.error
                                  : AppColors.signalEmerald),
                              weight: FontWeight.w600,
                              size: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(ch.category,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ),
                  const Spacer(),
                  if (ch.blocked)
                    GestureDetector(
                      onTap: () => _showReasonSheet(idx),
                      child: Text(
                        ch.reason.isEmpty ? 'Add reason' : ch.reason,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  void _showReasonSheet(int idx) {
    final ctrl = TextEditingController(text: _channels[idx].reason);
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Block Reason',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 100,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                hintText: 'Why block this channel?',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _setReason(idx, ctrl.text.trim());
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text('Save',
                    textAlign: TextAlign.center,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: hex(AppColors.outline), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Blocked channels will be hidden from your TV guide. Settings saved locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _ChEntry {
  final int num;
  final String name;
  final String category;
  bool blocked = false;
  String reason = '';

  _ChEntry({
    required this.num,
    required this.name,
    required this.category,
  });
}
