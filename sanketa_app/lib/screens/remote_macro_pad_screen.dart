import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteMacroPadScreen extends StatefulWidget {
  const RemoteMacroPadScreen({super.key});

  @override
  State<RemoteMacroPadScreen> createState() => _RemoteMacroPadScreenState();
}

class _RemoteMacroPadScreenState extends State<RemoteMacroPadScreen> {
  bool _loading = true;

  List<_MacroPad> _pads = [];

  static final _defaults = <_MacroPad>[
    _MacroPad(label: 'Movie Night', icon: Icons.movie, color: AppColors.primary, keys: [core.Key.power, core.Key.volumeUp, core.Key.volumeUp]),
    _MacroPad(label: 'Mute All', icon: Icons.volume_off, color: AppColors.error, keys: [core.Key.mute]),
    _MacroPad(label: 'Go Home', icon: Icons.home, color: AppColors.secondary, keys: [core.Key.home]),
    _MacroPad(label: 'Vol Up x3', icon: Icons.volume_up, color: AppColors.signalEmerald, keys: [core.Key.volumeUp, core.Key.volumeUp, core.Key.volumeUp]),
    _MacroPad(label: 'Vol Down x3', icon: Icons.volume_down, color: AppColors.alertAmber, keys: [core.Key.volumeDown, core.Key.volumeDown, core.Key.volumeDown]),
    _MacroPad(label: 'Back+Home', icon: Icons.undo, color: AppColors.tertiary, keys: [core.Key.back, core.Key.home]),
    _MacroPad(label: 'Power Off', icon: Icons.power_settings_new, color: AppColors.outline, keys: [core.Key.power]),
    _MacroPad(label: 'Menu Open', icon: Icons.menu, color: AppColors.primary, keys: [core.Key.menu]),
    _MacroPad(label: 'OK Confirm', icon: Icons.check_circle, color: AppColors.signalEmerald, keys: [core.Key.ok]),
  ];

  static const _availableKeys = <(String, core.Key)>[
    ('Power', core.Key.power),
    ('Vol Up', core.Key.volumeUp),
    ('Vol Down', core.Key.volumeDown),
    ('Mute', core.Key.mute),
    ('OK', core.Key.ok),
    ('Back', core.Key.back),
    ('Home', core.Key.home),
    ('Menu', core.Key.menu),
    ('Up', core.Key.up),
    ('Down', core.Key.down),
    ('Left', core.Key.left),
    ('Right', core.Key.right),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/macro_pad.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _pads = list.map((e) {
          final j = e as Map<String, dynamic>;
          final label = j['label'] as String? ?? '';
          final def = _defaults.where((d) => d.label == label);
          final keyNames = (j['keys'] as List?)?.cast<String>() ?? [];
          return _MacroPad(
            label: label,
            icon: def.isNotEmpty ? def.first.icon : Icons.play_arrow,
            color: def.isNotEmpty ? def.first.color : AppColors.primary,
            keys: keyNames.map((n) {
              final match = _availableKeys.where((k) => k.$1 == n);
              return match.isNotEmpty ? match.first.$2 : core.Key.ok;
            }).toList(),
          );
        }).toList();
      } else {
        _pads = List.of(_defaults);
      }
    } catch (_) {
      _pads = List.of(_defaults);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    final data = _pads.map((p) {
      final keyNames = p.keys.map((k) {
        final match = _availableKeys.where((ak) => ak.$2 == k);
        return match.isNotEmpty ? match.first.$1 : 'OK';
      }).toList();
      return {'label': p.label, 'keys': keyNames};
    }).toList();
    await f.writeAsString(jsonEncode(data));
  }

  void _runMacro(_MacroPad pad) {
    final rc = RemoteScope.of(context);
    for (final k in pad.keys) {
      rc.key(k);
    }
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Running: ${pad.label}'),
        duration: const Duration(seconds: 1),
      ));
  }

  void _removePad(int idx) {
    setState(() => _pads.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _resetPads() {
    setState(() => _pads = List.of(_defaults));
    HapticFeedback.mediumImpact();
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
        title: Text('Macro Pad',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _resetPads,
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
                _padGrid(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.grid_view, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Quick Macros',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Tap a pad to run a sequence of remote commands instantly',
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
                  'Pads', '${_pads.length}', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Total Keys',
                  '${_pads.fold<int>(0, (s, p) => s + p.keys.length)}',
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

  Widget _padGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
        children: _pads.asMap().entries.map((e) => _padButton(e.key, e.value)).toList(),
      );

  Widget _padButton(int idx, _MacroPad pad) => GestureDetector(
        onTap: () => _runMacro(pad),
        onLongPress: () => _removePad(idx),
        child: Container(
          decoration: BoxDecoration(
            color: hex(pad.color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(pad.color).withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(pad.icon, size: 28, color: hex(pad.color)),
              const SizedBox(height: 6),
              Text(pad.label,
                  textAlign: TextAlign.center,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 10)),
              const SizedBox(height: 2),
              Text('${pad.keys.length} keys',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 8)),
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
                'Tap any pad to run its macro. Long-press to remove. '
                'Use Reset to restore defaults. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _MacroPad {
  String label;
  IconData icon;
  int color;
  List<core.Key> keys;
  _MacroPad({
    required this.label,
    required this.icon,
    required this.color,
    required this.keys,
  });
}
