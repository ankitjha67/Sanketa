import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetSlot {
  _WidgetSlot(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
  bool enabled = false;
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  late final List<_WidgetSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = [
      _WidgetSlot('power', 'Power Toggle', Icons.power_settings_new),
      _WidgetSlot('volume', 'Volume Controls', Icons.volume_up),
      _WidgetSlot('mute', 'Mute Toggle', Icons.volume_off),
      _WidgetSlot('channel', 'Channel Up/Down', Icons.swap_vert),
      _WidgetSlot('home', 'Home Button', Icons.home),
      _WidgetSlot('source', 'Input Source', Icons.input),
    ];
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Home Screen Widgets',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _previewCard(),
              const SizedBox(height: AppSpacing.md),
              _slotsCard(),
              const SizedBox(height: AppSpacing.md),
              _quickSettingsCard(),
              const SizedBox(height: AppSpacing.md),
              _infoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: panel(
            borderColor: AppColors.primaryContainer, borderOpacity: 0.3),
        child: Column(
          children: [
            Text('Widget Preview',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final s in _slots.where((s) => s.enabled))
                    _previewBtn(s.icon, s.label),
                  if (_slots.every((s) => !s.enabled))
                    Text('Select controls below',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outlineVariant))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _previewBtn(IconData icon, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 20, color: hex(AppColors.primaryContainer)),
          ),
          const SizedBox(height: 4),
          Text(label.split(' ').first,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant), size: 9)),
        ],
      );

  Widget _slotsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Widget Controls',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Choose what appears on your home screen widget',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.md),
            for (final s in _slots) _slotToggle(s),
          ],
        ),
      );

  Widget _slotToggle(_WidgetSlot s) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => s.enabled = !s.enabled);
          _save();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(s.icon, size: 20, color: hex(AppColors.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(s.label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface))),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(s.enabled
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: s.enabled ? 1 : 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment:
                      s.enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: s.enabled
                          ? hex(AppColors.surface)
                          : hex(AppColors.outlineVariant),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _quickSettingsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Settings Tile',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'A mute toggle tile is available in your quick settings panel. '
              'Pull down your notification shade and edit tiles to add it.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.volume_off,
                    size: 18, color: hex(AppColors.tertiary)),
                const SizedBox(width: AppSpacing.sm),
                Text('Sanketa Mute',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(AppColors.tertiary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text('Android only',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.tertiary),
                          size: 10,
                          weight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration:
            panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 18, color: hex(AppColors.outlineVariant)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Home screen widgets require the native platform channel. '
                'Available once the Android/iOS widget plugin is installed.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  Future<void> _load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/widget_config.json');
      if (!f.existsSync()) return;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final enabled = (data['enabled'] as List?)?.cast<String>() ?? [];
      for (final s in _slots) {
        s.enabled = enabled.contains(s.id);
      }
      if (mounted) setState(() {});
    } on Object {
      // first launch
    }
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/widget_config.json');
      final enabled = _slots.where((s) => s.enabled).map((s) => s.id).toList();
      await f.writeAsString(jsonEncode({'enabled': enabled}));
    } on Object {
      // non-critical
    }
  }
}
