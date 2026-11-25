import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';


class _DashAction {
  _DashAction({required this.id, required this.label, required this.icon, required this.key});
  final String id;
  final String label;
  final IconData icon;
  final core.Key key;
}

final _allActions = <_DashAction>[
  _DashAction(id: 'power', label: 'Power', icon: Icons.power_settings_new, key: core.Key.power),
  _DashAction(id: 'mute', label: 'Mute', icon: Icons.volume_off, key: core.Key.mute),
  _DashAction(id: 'vol_up', label: 'Vol +', icon: Icons.volume_up, key: core.Key.volumeUp),
  _DashAction(id: 'vol_down', label: 'Vol -', icon: Icons.volume_down, key: core.Key.volumeDown),
  _DashAction(id: 'ch_up', label: 'Ch +', icon: Icons.arrow_upward, key: core.Key.channelUp),
  _DashAction(id: 'ch_down', label: 'Ch -', icon: Icons.arrow_downward, key: core.Key.channelDown),
  _DashAction(id: 'home', label: 'Home', icon: Icons.home, key: core.Key.home),
  _DashAction(id: 'back', label: 'Back', icon: Icons.arrow_back, key: core.Key.back),
  _DashAction(id: 'menu', label: 'Menu', icon: Icons.menu, key: core.Key.menu),
  _DashAction(id: 'ok', label: 'OK', icon: Icons.check_circle, key: core.Key.ok),
  _DashAction(id: 'play', label: 'Play', icon: Icons.play_arrow, key: core.Key.play),
  _DashAction(id: 'pause', label: 'Pause', icon: Icons.pause, key: core.Key.pause),
  _DashAction(id: 'stop', label: 'Stop', icon: Icons.stop, key: core.Key.stop),
  _DashAction(id: 'info', label: 'Info', icon: Icons.info, key: core.Key.info),
  _DashAction(id: 'guide', label: 'Guide', icon: Icons.grid_view, key: core.Key.guide),
  _DashAction(id: 'input', label: 'Input', icon: Icons.input, key: core.Key.input),
  _DashAction(id: 'rewind', label: 'Rewind', icon: Icons.fast_rewind, key: core.Key.rewind),
  _DashAction(id: 'ff', label: 'Forward', icon: Icons.fast_forward, key: core.Key.fastForward),
];

class QuickDashboardScreen extends StatefulWidget {
  const QuickDashboardScreen({super.key});

  @override
  State<QuickDashboardScreen> createState() => _QuickDashboardScreenState();
}

class _QuickDashboardScreenState extends State<QuickDashboardScreen> {
  List<String> _gridIds = ['power', 'mute', 'vol_up', 'vol_down', 'home', 'back', 'play', 'input', 'guide'];
  bool _editing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quick_dashboard.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final ids = (j['gridIds'] as List?)?.cast<String>();
        if (ids != null && ids.isNotEmpty) {
          _gridIds = ids;
        }
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({'gridIds': _gridIds}));
  }

  _DashAction? _actionById(String id) {
    for (final a in _allActions) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _send(core.Key key) {
    RemoteScope.of(context).key(key);
  }

  void _replaceTile(int index) {
    final available = _allActions.where((a) => !_gridIds.contains(a.id)).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Replace Action',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((a) => GestureDetector(
                onTap: () {
                  setState(() => _gridIds[index] = a.id);
                  _save();
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, size: 14, color: hex(AppColors.onSurface)),
                      const SizedBox(width: 6),
                      Text(a.label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11)),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
        title: Text('Quick Dash',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _editing = !_editing),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_editing ? 'Done' : 'Edit',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(child: _buildGrid()),
            if (_editing) ...[
              const SizedBox(height: AppSpacing.md),
              _resetButton(),
            ],
            const SizedBox(height: AppSpacing.md),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() => GridView.count(
    crossAxisCount: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1,
    children: List.generate(_gridIds.length, (i) {
      final action = _actionById(_gridIds[i]);
      if (action == null) return const SizedBox();
      return _gridTile(action, i);
    }),
  );

  Widget _gridTile(_DashAction action, int index) => GestureDetector(
    onTap: _editing ? () => _replaceTile(index) : () => _send(action.key),
    child: Container(
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(_editing ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: _editing ? 0.5 : 0.15),
          width: _editing ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, size: 28,
                    color: hex(_editing ? AppColors.primary : AppColors.onSurface)),
                const SizedBox(height: 6),
                Text(action.label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
              ],
            ),
          ),
          if (_editing)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: hex(AppColors.primary),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horiz, size: 10, color: hex(AppColors.onPrimary)),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _resetButton() => GestureDetector(
    onTap: () {
      setState(() {
        _gridIds = ['power', 'mute', 'vol_up', 'vol_down', 'home', 'back', 'play', 'input', 'guide'];
      });
      _save();
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Center(
        child: Text('Reset to Defaults',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), weight: FontWeight.w500)),
      ),
    ),
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
            _editing
                ? 'Tap any tile to replace it with a different action.'
                : 'Your personalised quick action grid. Tap Edit to customise.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
