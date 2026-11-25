import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class FavouriteChannel {
  FavouriteChannel({
    required this.name,
    required this.number,
    this.icon,
  });

  final String name;
  final int number;
  final String? icon;

  Map<String, dynamic> toJson() => {
    'name': name,
    'number': number,
    if (icon != null) 'icon': icon,
  };

  factory FavouriteChannel.fromJson(Map<String, dynamic> j) => FavouriteChannel(
    name: j['name'] as String,
    number: j['number'] as int,
    icon: j['icon'] as String?,
  );
}

class FavouriteChannelsScreen extends StatefulWidget {
  const FavouriteChannelsScreen({super.key});

  @override
  State<FavouriteChannelsScreen> createState() => _FavouriteChannelsScreenState();
}

class _FavouriteChannelsScreenState extends State<FavouriteChannelsScreen> {
  List<FavouriteChannel> _channels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/favourite_channels.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _channels = list.map((e) => FavouriteChannel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on Object {
      // First launch or corrupt file — start empty.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_channels.map((c) => c.toJson()).toList()));
  }

  void _addChannel() {
    final nameCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLowest),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Add Favourite',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Channel name (e.g. BBC One)',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                isDense: true,
                filled: true,
                fillColor: hex(AppColors.surfaceContainerHigh),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Channel number (e.g. 101)',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                isDense: true,
                filled: true,
                fillColor: hex(AppColors.surfaceContainerHigh),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final num = int.tryParse(numCtrl.text.trim());
              if (name.isNotEmpty && num != null && num > 0) {
                setState(() => _channels.add(FavouriteChannel(name: name, number: num)));
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Add',
                style: gfont(AppType.bodySm, color: hex(AppColors.primaryContainer), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _tuneToChannel(FavouriteChannel ch) {
    final c = RemoteScope.of(context);
    final digits = ch.number.toString();
    for (final d in digits.split('')) {
      final key = core.Key.values.firstWhere(
        (k) => k.name == 'digit$d',
        orElse: () => core.Key.ok,
      );
      c.key(key);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Tuning to ${ch.name} (CH ${ch.number})'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _removeChannel(int index) {
    setState(() => _channels.removeAt(index));
    _save();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _channels.removeAt(oldIndex);
      _channels.insert(newIndex, item);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Favourite Channels',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addChannel,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : _channels.isEmpty
              ? _emptyState()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _channels.length,
                  onReorderItem: (oldIndex, newIndex) => _reorder(oldIndex, newIndex),
                  itemBuilder: (ctx, i) => _channelTile(_channels[i], i),
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border_rounded, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No favourite channels yet',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add your most-watched channels for one-tap tuning.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _addChannel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Add Channel',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _channelTile(FavouriteChannel ch, int index) => Padding(
    key: ValueKey('$index-${ch.number}'),
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      onTap: () => _tuneToChannel(ch),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: panel(radius: AppRadii.md, borderOpacity: 0.2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child: Text(
                  '${ch.number}',
                  style: gfont(AppType.headlineMd, color: hex(AppColors.primary), size: 16, weight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.name,
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                  Text('CH ${ch.number}',
                      style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _removeChannel(index),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, size: 16, color: hex(AppColors.outlineVariant)),
              ),
            ),
            Icon(Icons.drag_handle, size: 18, color: hex(AppColors.outlineVariant)),
          ],
        ),
      ),
    ),
  );
}
