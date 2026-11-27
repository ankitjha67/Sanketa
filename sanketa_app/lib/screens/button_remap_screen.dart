import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ButtonRemapScreen extends StatefulWidget {
  const ButtonRemapScreen({super.key});

  @override
  State<ButtonRemapScreen> createState() => _ButtonRemapScreenState();
}

class _ButtonRemapScreenState extends State<ButtonRemapScreen> {
  static const _buttons = [
    ('Power', Icons.power_settings_new, core.Key.power),
    ('Vol Up', Icons.volume_up, core.Key.volumeUp),
    ('Vol Down', Icons.volume_down, core.Key.volumeDown),
    ('Mute', Icons.volume_off, core.Key.mute),
    ('OK', Icons.check_circle, core.Key.ok),
    ('Back', Icons.arrow_back, core.Key.back),
    ('Home', Icons.home, core.Key.home),
    ('Menu', Icons.menu, core.Key.menu),
    ('Up', Icons.arrow_upward, core.Key.up),
    ('Down', Icons.arrow_downward, core.Key.down),
  ];

  static const _actions = [
    ('Power', core.Key.power),
    ('Volume Up', core.Key.volumeUp),
    ('Volume Down', core.Key.volumeDown),
    ('Mute', core.Key.mute),
    ('OK / Select', core.Key.ok),
    ('Back', core.Key.back),
    ('Home', core.Key.home),
    ('Menu', core.Key.menu),
    ('Up', core.Key.up),
    ('Down', core.Key.down),
    ('Left', core.Key.left),
    ('Right', core.Key.right),
  ];

  late List<int> _mappings;
  late List<bool> _custom;

  @override
  void initState() {
    super.initState();
    _mappings = List.generate(_buttons.length, (i) => i < _actions.length ? i : 0);
    _custom = List.filled(_buttons.length, false);
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/button_remap.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final m = data['mappings'] as List;
        final c = data['custom'] as List;
        for (var i = 0; i < _buttons.length && i < m.length; i++) {
          _mappings[i] = m[i] as int;
          _custom[i] = c[i] as bool;
        }
      }
    } on Object {
      // First launch — keep defaults.
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'mappings': _mappings,
      'custom': _custom,
    }));
  }

  void _resetAll() {
    setState(() {
      for (var i = 0; i < _buttons.length; i++) {
        _mappings[i] = i < _actions.length ? i : 0;
        _custom[i] = false;
      }
    });
    _save();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('All buttons reset to default'),
        duration: Duration(seconds: 2),
      ));
  }

  void _preview(int idx) {
    final rc = RemoteScope.of(context);
    final actionKey = _actions[_mappings[idx]].$2;
    rc.key(actionKey);
    HapticFeedback.mediumImpact();
  }

  void _pickAction(int btnIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Assign Action',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._actions.asMap().entries.map((e) {
            final active = _mappings[btnIdx] == e.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _mappings[btnIdx] = e.key;
                  _custom[btnIdx] = true;
                });
                _save();
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(active
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.4 : 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value.$1,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 13)),
                    ),
                    if (active)
                      Icon(Icons.check,
                          size: 18, color: hex(AppColors.primary)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Button Remap',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: hex(AppColors.outline)),
            onPressed: _resetAll,
            tooltip: 'Reset All',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          ..._buttons.asMap().entries.expand((e) => [
                _buttonRow(e.key),
                const SizedBox(height: 8),
              ]),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.swap_horiz, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Remap Buttons',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Reassign remote buttons to custom actions',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _buttonRow(int idx) {
    final btn = _buttons[idx];
    final actionName = _actions[_mappings[idx]].$1;
    final isCustom = _custom[idx];

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(isCustom ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: isCustom ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(btn.$2, size: 20, color: hex(AppColors.outline)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(btn.$1,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Row(
                  children: [
                    Icon(Icons.arrow_forward,
                        size: 10, color: hex(AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(actionName,
                        style: gfont(AppType.bodySm,
                            color: hex(isCustom
                                ? AppColors.primary
                                : AppColors.outline),
                            size: 10)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _preview(idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.play_arrow,
                  size: 16, color: hex(AppColors.signalEmerald)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _pickAction(idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child:
                  Icon(Icons.edit, size: 16, color: hex(AppColors.primary)),
            ),
          ),
        ],
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
                'Reassign any remote button to a different action. Tap the play icon to preview, or the edit icon to change the mapping.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
