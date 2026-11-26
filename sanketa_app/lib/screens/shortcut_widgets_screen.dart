import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ShortcutWidgetsScreen extends StatefulWidget {
  const ShortcutWidgetsScreen({super.key});

  @override
  State<ShortcutWidgetsScreen> createState() => _ShortcutWidgetsScreenState();
}

class _ShortcutWidgetsScreenState extends State<ShortcutWidgetsScreen> {
  List<int> _selectedActions = [0, 1, 2, 3];
  bool _loading = true;
  int _widgetStyle = 0;

  static const _actions = <(String, IconData, int)>[
    ('Power', Icons.power_settings_new, AppColors.error),
    ('Mute', Icons.volume_off, AppColors.alertAmber),
    ('Vol Up', Icons.volume_up, AppColors.primary),
    ('Vol Down', Icons.volume_down, AppColors.primary),
    ('Home', Icons.home, AppColors.signalEmerald),
    ('Back', Icons.arrow_back, AppColors.tertiary),
    ('Play', Icons.play_arrow, AppColors.secondary),
    ('Pause', Icons.pause, AppColors.secondary),
    ('YouTube', Icons.play_circle, AppColors.error),
    ('Netflix', Icons.movie, AppColors.error),
    ('Input', Icons.input, AppColors.outline),
    ('Menu', Icons.menu, AppColors.outline),
  ];

  static const _styles = ['Compact', 'Rounded', 'Minimal'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/shortcut_widgets.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedActions =
            (data['actions'] as List?)?.cast<int>() ?? [0, 1, 2, 3];
        _widgetStyle = data['style'] as int? ?? 0;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'actions': _selectedActions,
      'style': _widgetStyle,
    }));
  }

  void _toggleAction(int i) {
    setState(() {
      if (_selectedActions.contains(i)) {
        if (_selectedActions.length > 1) _selectedActions.remove(i);
      } else {
        if (_selectedActions.length < 6) _selectedActions.add(i);
      }
    });
    _save();
  }

  void _executeAction(int actionIndex) {
    final rc = RemoteScope.of(context);
    final action = _actions[actionIndex];
    switch (action.$1) {
      case 'Power':
        rc.key(core.Key.power);
      case 'Mute':
        rc.key(core.Key.mute);
      case 'Vol Up':
        rc.key(core.Key.volumeUp);
      case 'Vol Down':
        rc.key(core.Key.volumeDown);
      case 'Home':
        rc.key(core.Key.home);
      case 'Back':
        rc.key(core.Key.back);
      case 'Play':
        rc.key(core.Key.ok);
      case 'Pause':
        rc.key(core.Key.ok);
      case 'YouTube':
        rc.launch('YouTube');
      case 'Netflix':
        rc.launch('Netflix');
      case 'Input':
        rc.key(core.Key.menu);
      case 'Menu':
        rc.key(core.Key.menu);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent: ${action.$1}'),
        duration: const Duration(seconds: 1),
      ));
  }

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
        title: Text('Shortcut Widgets',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _styleSelector(),
          const SizedBox(height: AppSpacing.md),
          _actionPicker(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.widgets,
                size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Quick Action Widgets',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Configure home screen widgets for one-tap TV control actions',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Widget Preview',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap buttons to test actions',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedActions.map((i) {
                final a = _actions[i];
                final radius = _widgetStyle == 1
                    ? AppRadii.full
                    : _widgetStyle == 2
                        ? AppRadii.sm
                        : AppRadii.md;
                return GestureDetector(
                  onTap: () => _executeAction(i),
                  child: Container(
                    width: _widgetStyle == 2 ? 50 : 60,
                    height: _widgetStyle == 2 ? 50 : 60,
                    decoration: BoxDecoration(
                      color: hex(a.$3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                          color: hex(a.$3).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(a.$2,
                            size: _widgetStyle == 2 ? 18 : 22,
                            color: hex(a.$3)),
                        if (_widgetStyle != 2) ...[
                          const SizedBox(height: 2),
                          Text(a.$1,
                              style: gfont(AppType.bodySm,
                                  color: hex(a.$3),
                                  size: 8,
                                  weight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _styleSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Widget Style',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_styles.length, (i) {
              final active = i == _widgetStyle;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _styles.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _widgetStyle = i);
                      _save();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(active
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.5 : 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(_styles[i],
                            style: gfont(AppType.bodySm,
                                color: hex(active
                                    ? AppColors.primary
                                    : AppColors.onSurface),
                                weight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                size: 11)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );

  Widget _actionPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Actions (${_selectedActions.length}/6)',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_actions.length, (i) {
              final a = _actions[i];
              final selected = _selectedActions.contains(i);
              return GestureDetector(
                onTap: () => _toggleAction(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(selected ? a.$3 : AppColors.surfaceContainerHigh)
                        .withValues(alpha: selected ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(selected ? a.$3 : AppColors.outlineVariant)
                          .withValues(alpha: selected ? 0.5 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.$2,
                          size: 14,
                          color: hex(selected ? a.$3 : AppColors.outline)),
                      const SizedBox(width: 4),
                      Text(a.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(
                                  selected ? a.$3 : AppColors.onSurface),
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check,
                            size: 10, color: hex(a.$3)),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
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
                'Configure quick-access widgets with your most-used TV controls. Choose 1–6 actions and a visual style. Widget config is saved locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
