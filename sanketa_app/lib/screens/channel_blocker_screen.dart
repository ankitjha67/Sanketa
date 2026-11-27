import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ChannelBlockerScreen extends StatefulWidget {
  const ChannelBlockerScreen({super.key});

  @override
  State<ChannelBlockerScreen> createState() => _ChannelBlockerScreenState();
}

class _ChannelBlockerScreenState extends State<ChannelBlockerScreen> {
  final _blocked = <(int, String)>[];
  final _numCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = true;

  static const _quickChannels = <(int, String)>[
    (99, 'Shopping Network'),
    (120, 'Adult Swim'),
    (145, 'Pay-Per-View'),
    (200, 'Infomercials'),
    (250, 'Televangelism'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_blocker.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List;
        for (final item in data) {
          final m = item as Map<String, dynamic>;
          _blocked.add((m['ch'] as int, m['name'] as String));
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(
        _blocked.map((b) => {'ch': b.$1, 'name': b.$2}).toList()));
  }

  void _addChannel() {
    final num = int.tryParse(_numCtrl.text.trim());
    final name = _nameCtrl.text.trim();
    if (num == null || name.isEmpty) return;
    if (_blocked.any((b) => b.$1 == num)) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Channel already blocked'),
          duration: Duration(seconds: 1),
        ));
      return;
    }
    if (_blocked.length >= 50) return;
    setState(() => _blocked.add((num, name)));
    _numCtrl.clear();
    _nameCtrl.clear();
    _save();
    HapticFeedback.lightImpact();
  }

  void _quickAdd(int ch, String name) {
    if (_blocked.any((b) => b.$1 == ch)) return;
    if (_blocked.length >= 50) return;
    setState(() => _blocked.add((ch, name)));
    _save();
    HapticFeedback.lightImpact();
  }

  void _remove(int idx) {
    setState(() => _blocked.removeAt(idx));
    _save();
  }

  void _clearAll() {
    setState(() => _blocked.clear());
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
        title: Text('Channel Blocker',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_blocked.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.delete_sweep,
                    size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _addForm(),
          const SizedBox(height: AppSpacing.md),
          _quickAddSection(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _blockedList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.block, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('Channel Blocker',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Hide unwanted channels from your TV guide',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _addForm() => Container(
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
            Text('Block a Channel',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _numCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Ch #',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Channel name',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addChannel(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addChannel,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hex(AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(Icons.block,
                        size: 18, color: hex(AppColors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _quickAddSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Block',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickChannels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final ch = _quickChannels[i];
                final alreadyBlocked = _blocked.any((b) => b.$1 == ch.$1);
                return GestureDetector(
                  onTap: alreadyBlocked ? null : () => _quickAdd(ch.$1, ch.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: hex(alreadyBlocked
                              ? AppColors.error
                              : AppColors.surfaceContainerHigh)
                          .withValues(alpha: alreadyBlocked ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(alreadyBlocked
                                ? AppColors.error
                                : AppColors.outlineVariant)
                            .withValues(alpha: alreadyBlocked ? 0.3 : 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(ch.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(alreadyBlocked
                                  ? AppColors.error
                                  : AppColors.onSurface),
                              weight: alreadyBlocked
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _statsRow() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Blocked', '${_blocked.length}'),
            _statItem('Remaining', '${50 - _blocked.length}'),
          ],
        ),
      );

  Widget _statItem(String label, String value) => Column(
        children: [
          Text(value,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.error),
                  weight: FontWeight.w700,
                  size: 16)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _blockedList() {
    if (_blocked.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Center(
          child: Text('No channels blocked',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 12)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blocked Channels',
            style: gfont(AppType.bodyMd,
                color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 6),
        ..._blocked.asMap().entries.map((e) {
          final ch = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: hex(AppColors.error).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hex(AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Center(
                      child: Text('${ch.$1}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.error),
                              weight: FontWeight.w700,
                              size: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(ch.$2,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w500,
                            size: 12)),
                  ),
                  GestureDetector(
                    onTap: () => _remove(e.key),
                    child: Icon(Icons.close,
                        size: 16, color: hex(AppColors.error)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
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
                'Block channels you don\'t want to see in your TV guide. Blocked channels can be unblocked at any time. Up to 50 channels can be blocked.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
