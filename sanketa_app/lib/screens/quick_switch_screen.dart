import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _SwitchItem {
  _SwitchItem({
    required this.label,
    required this.type,
    this.pinned = false,
  });

  final String label;
  final String type; // 'app' or 'channel'
  bool pinned;

  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type,
        'pinned': pinned,
      };

  factory _SwitchItem.fromJson(Map<String, dynamic> j) => _SwitchItem(
        label: j['label'] as String,
        type: j['type'] as String,
        pinned: j['pinned'] as bool? ?? false,
      );
}

class QuickSwitchScreen extends StatefulWidget {
  const QuickSwitchScreen({super.key});

  @override
  State<QuickSwitchScreen> createState() => _QuickSwitchScreenState();
}

class _QuickSwitchScreenState extends State<QuickSwitchScreen> {
  List<_SwitchItem> _items = [];
  String _lastChannel = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quick_switch.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['items'] as List? ?? [];
        _items =
            list.map((e) => _SwitchItem.fromJson(e as Map<String, dynamic>)).toList();
        _lastChannel = data['lastChannel'] as String? ?? '';
      }
    } on Object {
      // First launch — seed defaults.
    }
    if (_items.isEmpty) {
      _items = [
        _SwitchItem(label: 'YouTube', type: 'app', pinned: true),
        _SwitchItem(label: 'Netflix', type: 'app', pinned: true),
        _SwitchItem(label: 'Ch 7 News', type: 'channel'),
        _SwitchItem(label: 'Disney+', type: 'app'),
        _SwitchItem(label: 'Ch 12 Sports', type: 'channel'),
        _SwitchItem(label: 'Prime Video', type: 'app'),
        _SwitchItem(label: 'Ch 3 Movies', type: 'channel'),
        _SwitchItem(label: 'Spotify', type: 'app'),
      ];
      _lastChannel = '7';
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'items': _items.map((i) => i.toJson()).toList(),
      'lastChannel': _lastChannel,
    }));
  }

  List<_SwitchItem> get _sorted {
    final pinned = _items.where((i) => i.pinned).toList();
    final rest = _items.where((i) => !i.pinned).toList();
    return [...pinned, ...rest];
  }

  void _switchTo(_SwitchItem item) {
    final rc = RemoteScope.of(context);
    if (item.type == 'channel') {
      final digits = item.label.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        rc.type(digits);
        _lastChannel = digits;
      }
    } else {
      rc.launch(item.label);
    }
    HapticFeedback.mediumImpact();
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switching to ${item.label}'),
        duration: const Duration(seconds: 1),
      ));
  }

  void _togglePin(_SwitchItem item) {
    setState(() => item.pinned = !item.pinned);
    _save();
    HapticFeedback.selectionClick();
  }

  void _remove(_SwitchItem item) {
    setState(() => _items.remove(item));
    _save();
    HapticFeedback.selectionClick();
  }

  void _lastChannelTap() {
    if (_lastChannel.isEmpty) return;
    final rc = RemoteScope.of(context);
    rc.type(_lastChannel);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to channel $_lastChannel'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Switch',
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
          _lastChannelCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent (${_items.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._sorted.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(item.label),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: hex(AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.delete,
                        size: 20, color: hex(AppColors.error)),
                  ),
                  onDismissed: (_) => _remove(item),
                  child: _itemCard(item),
                ),
              )),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.swap_horizontal_circle,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Fast Switch',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Quickly switch between recent apps and channels',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _lastChannelCard() => GestureDetector(
        onTap: _lastChannelTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.history, size: 22, color: hex(AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Channel',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text(
                      _lastChannel.isEmpty
                          ? 'No channel history yet'
                          : 'Channel $_lastChannel',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Tune',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _itemCard(_SwitchItem item) {
    final isChannel = item.type == 'channel';
    return GestureDetector(
      onTap: () => _switchTo(item),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(item.pinned
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant)
                .withValues(alpha: item.pinned ? 0.3 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isChannel ? Icons.tv : Icons.apps,
              size: 20,
              color: hex(isChannel ? AppColors.tertiary : AppColors.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 12)),
                  Text(isChannel ? 'Channel' : 'App',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _togglePin(item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(item.pinned
                          ? AppColors.signalEmerald
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: item.pinned ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: hex(item.pinned
                      ? AppColors.signalEmerald
                      : AppColors.outline),
                ),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border:
              Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap to switch, pin favourites to the top, swipe left to remove. Use Last Channel to quickly tune back.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
