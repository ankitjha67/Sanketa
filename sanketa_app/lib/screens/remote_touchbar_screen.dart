import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteTouchbarScreen extends StatefulWidget {
  const RemoteTouchbarScreen({super.key});

  @override
  State<RemoteTouchbarScreen> createState() => _RemoteTouchbarScreenState();
}

class _RemoteTouchbarScreenState extends State<RemoteTouchbarScreen> {
  final List<_Slot> _slots = [
    _Slot('Mute', Icons.volume_off, 'mute'),
    _Slot('Home', Icons.home, 'home'),
    _Slot('Back', Icons.arrow_back, 'back'),
    _Slot('Power', Icons.power_settings_new, 'power'),
    _Slot('Menu', Icons.menu, 'menu'),
    _Slot('Vol +', Icons.volume_up, 'volumeUp'),
    _Slot('Vol -', Icons.volume_down, 'volumeDown'),
    _Slot('OK', Icons.check_circle, 'ok'),
  ];

  bool _locked = false;

  static const _keyMap = <String, core.Key>{
    'mute': core.Key.mute,
    'home': core.Key.home,
    'back': core.Key.back,
    'power': core.Key.power,
    'menu': core.Key.menu,
    'volumeUp': core.Key.volumeUp,
    'volumeDown': core.Key.volumeDown,
    'ok': core.Key.ok,
    'up': core.Key.up,
    'down': core.Key.down,
    'left': core.Key.left,
    'right': core.Key.right,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/touchbar_slots.json');
      if (await f.exists()) {
        final list =
            jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _slots.clear();
          for (final s in list) {
            final m = s as Map<String, dynamic>;
            _slots.add(_Slot(
              m['label'] as String? ?? 'Key',
              _iconForKey(m['key'] as String? ?? 'ok'),
              m['key'] as String? ?? 'ok',
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/touchbar_slots.json');
      await f.writeAsString(jsonEncode(_slots
          .map((s) => {
                'label': s.label,
                'icon': s.icon.codePoint,
                'key': s.keyName,
              })
          .toList()));
    } catch (_) {}
  }

  static IconData _iconForKey(String key) => switch (key) {
        'mute' => Icons.volume_off,
        'home' => Icons.home,
        'back' => Icons.arrow_back,
        'power' => Icons.power_settings_new,
        'menu' => Icons.menu,
        'volumeUp' => Icons.volume_up,
        'volumeDown' => Icons.volume_down,
        'ok' => Icons.check_circle,
        'up' => Icons.arrow_upward,
        'down' => Icons.arrow_downward,
        'left' => Icons.arrow_back,
        'right' => Icons.arrow_forward,
        _ => Icons.circle,
      };

  void _fire(String keyName) {
    final k = _keyMap[keyName];
    if (k != null) {
      RemoteScope.of(context).key(k);
      HapticFeedback.lightImpact();
    }
  }

  void _reorder(int oldIdx, int newIdx) {
    if (_locked) return;
    setState(() {
      if (newIdx > oldIdx) newIdx -= 1;
      final item = _slots.removeAt(oldIdx);
      _slots.insert(newIdx, item);
    });
    _save();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Touchbar',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              _locked ? Icons.lock : Icons.lock_open,
              color: hex(_locked ? AppColors.alertAmber : AppColors.outline),
            ),
            onPressed: () {
              setState(() => _locked = !_locked);
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _touchbar(),
          const SizedBox(height: AppSpacing.lg),
          _slotGrid(),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.space_bar, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Touch Bar',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Quick-access shortcuts bar. Drag to reorder, tap to fire.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _touchbar() => Container(
        height: 64,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: ReorderableListView(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: !_locked,
          onReorderItem: (oldIdx, newIdx) => _reorder(oldIdx, newIdx),
          proxyDecorator: (child, _, _) => Material(
            color: Colors.transparent,
            elevation: 4,
            child: child,
          ),
          children: _slots.asMap().entries.map((e) {
            return GestureDetector(
              key: ValueKey('slot_${e.key}_${e.value.keyName}'),
              onTap: () => _fire(e.value.keyName),
              child: Container(
                width: 56,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.value.icon,
                        size: 18, color: hex(AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(e.value.label,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            size: 8,
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _slotGrid() {
    final available = _keyMap.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Keys',
            style: gfont(AppType.bodyMd,
                color: hex(AppColors.onSurface),
                weight: FontWeight.w600,
                size: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: available.map((e) {
            return GestureDetector(
              onTap: () => _fire(e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
                ),
                child: Text(e.key,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 11)),
              ),
            );
          }).toList(),
        ),
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
                'Customizable touch bar with quick-access remote shortcuts. '
                'Drag to reorder, lock to prevent changes. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Slot {
  String label;
  IconData icon;
  String keyName;
  _Slot(this.label, this.icon, this.keyName);
}
