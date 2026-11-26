import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvShortcutsScreen extends StatefulWidget {
  const TvShortcutsScreen({super.key});

  @override
  State<TvShortcutsScreen> createState() => _TvShortcutsScreenState();
}

class _TvShortcutsScreenState extends State<TvShortcutsScreen> {
  List<(String, String, int)> _shortcuts = [];
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  int _selectedIcon = 0;

  static const _icons = <(IconData, String)>[
    (Icons.play_arrow, 'Play'),
    (Icons.movie, 'Movie'),
    (Icons.music_note, 'Music'),
    (Icons.sports_esports, 'Game'),
    (Icons.web, 'Web'),
    (Icons.settings, 'Settings'),
    (Icons.cast, 'Cast'),
    (Icons.photo, 'Photo'),
  ];

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.alertAmber,
    AppColors.error,
    AppColors.signalEmerald,
    AppColors.tertiary,
  ];

  static const _sampleShortcuts = <(String, String, int)>[
    ('Netflix', 'Netflix', 0),
    ('YouTube', 'YouTube', 1),
    ('Prime Video', 'Amazon Prime Video', 2),
    ('Disney+', 'Disney Plus', 3),
    ('Settings', 'TV Settings', 5),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_shortcuts.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _shortcuts = list.map((j) {
          final m = j as Map<String, dynamic>;
          return (m['name'] as String, m['action'] as String, m['icon'] as int);
        }).toList();
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(
        _shortcuts.map((s) => {'name': s.$1, 'action': s.$2, 'icon': s.$3}).toList()));
  }

  void _addShortcut() {
    if (_nameCtrl.text.trim().isEmpty || _actionCtrl.text.trim().isEmpty) return;
    if (_shortcuts.length >= 20) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Maximum 20 shortcuts')));
      return;
    }
    setState(() => _shortcuts.add(
          (_nameCtrl.text.trim(), _actionCtrl.text.trim(), _selectedIcon)));
    _nameCtrl.clear();
    _actionCtrl.clear();
    _save();
  }

  void _delete(int i) {
    setState(() => _shortcuts.removeAt(i));
    _save();
  }

  void _launch(int i) {
    final rc = RemoteScope.of(context);
    rc.launch(_shortcuts[i].$2);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Launching: ${_shortcuts[i].$1}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _quickFill() {
    setState(() {
      _shortcuts = List.of(_sampleShortcuts);
    });
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
        title: Text('TV Shortcuts',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _addForm(),
          const SizedBox(height: AppSpacing.md),
          if (_shortcuts.isEmpty)
            _emptyState()
          else ...[
            Text('Shortcuts (${_shortcuts.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_shortcuts.length, (i) => _shortcutTile(i)),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.rocket_launch, size: 36, color: hex(AppColors.alertAmber)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Launch',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.alertAmber), weight: FontWeight.w600)),
                  Text('One-tap shortcuts to launch TV apps',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _addForm() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Shortcut',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _actionCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'App / action',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(_icons.length, (i) {
                final active = i == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Icon(_icons[i].$1, size: 16,
                        color: hex(active ? AppColors.primary : AppColors.outline)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _addShortcut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(AppColors.primary).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Center(
                        child: Text('Add Shortcut',
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.primary), weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _quickFill,
                  child: Text('Quick fill',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _shortcutTile(int i) {
    final s = _shortcuts[i];
    final color = _colors[i % _colors.length];
    final icon = s.$3 < _icons.length ? _icons[s.$3].$1 : Icons.apps;
    return GestureDetector(
      onTap: () => _launch(i),
      onLongPress: () => _delete(i),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(color).withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: hex(color)),
            const SizedBox(height: 6),
            Text(s.$1,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 10)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.rocket_launch, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No shortcuts yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add app shortcuts for one-tap launching.',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Create custom shortcuts to quickly launch apps on your TV. Tap to launch, long-press to delete. All shortcuts saved locally on your phone.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
