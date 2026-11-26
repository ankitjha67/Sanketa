import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Layout {
  _Layout({required this.name, required this.code, required this.flag, this.enabled = false});

  final String name;
  final String code;
  final String flag;
  bool enabled;
}

class KeyboardLayoutsScreen extends StatefulWidget {
  const KeyboardLayoutsScreen({super.key});

  @override
  State<KeyboardLayoutsScreen> createState() => _KeyboardLayoutsScreenState();
}

class _KeyboardLayoutsScreenState extends State<KeyboardLayoutsScreen> {
  final _layouts = [
    _Layout(name: 'English (US)', code: 'en-US', flag: 'US', enabled: true),
    _Layout(name: 'English (UK)', code: 'en-GB', flag: 'GB'),
    _Layout(name: 'Hindi', code: 'hi-IN', flag: 'IN'),
    _Layout(name: 'Spanish', code: 'es-ES', flag: 'ES'),
    _Layout(name: 'French', code: 'fr-FR', flag: 'FR'),
    _Layout(name: 'German', code: 'de-DE', flag: 'DE'),
    _Layout(name: 'Japanese', code: 'ja-JP', flag: 'JP'),
    _Layout(name: 'Korean', code: 'ko-KR', flag: 'KR'),
    _Layout(name: 'Chinese (Simplified)', code: 'zh-CN', flag: 'CN'),
    _Layout(name: 'Arabic', code: 'ar-SA', flag: 'SA'),
    _Layout(name: 'Russian', code: 'ru-RU', flag: 'RU'),
    _Layout(name: 'Portuguese', code: 'pt-BR', flag: 'BR'),
    _Layout(name: 'Italian', code: 'it-IT', flag: 'IT'),
    _Layout(name: 'Thai', code: 'th-TH', flag: 'TH'),
    _Layout(name: 'Turkish', code: 'tr-TR', flag: 'TR'),
  ];

  bool _autoSwitch = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/keyboard_layouts.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _autoSwitch = j['autoSwitch'] as bool? ?? true;
        final enabled = (j['enabled'] as List?)?.cast<String>() ?? [];
        for (final l in _layouts) {
          l.enabled = enabled.contains(l.code);
        }
        if (!_layouts.any((l) => l.enabled)) _layouts[0].enabled = true;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'autoSwitch': _autoSwitch,
      'enabled': _layouts.where((l) => l.enabled).map((l) => l.code).toList(),
    }));
  }

  List<_Layout> get _filtered {
    if (_search.isEmpty) return _layouts;
    final q = _search.toLowerCase();
    return _layouts.where((l) =>
        l.name.toLowerCase().contains(q) || l.code.toLowerCase().contains(q)).toList();
  }

  int get _enabledCount => _layouts.where((l) => l.enabled).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Keyboard Layouts',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _headerCard(),
          const SizedBox(height: AppSpacing.md),
          _autoSwitchToggle(),
          const SizedBox(height: AppSpacing.md),
          _searchBar(),
          const SizedBox(height: 8),
          ..._filtered.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _layoutRow(l),
          )),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(Icons.keyboard, size: 24, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_enabledCount Layouts Active',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Switch between languages while typing on TV',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _autoSwitchToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.swap_horiz, size: 20, color: hex(AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Auto-Switch Layout',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Match phone keyboard language automatically',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        Switch(
          value: _autoSwitch,
          activeTrackColor: hex(AppColors.primary),
          onChanged: (v) {
            setState(() => _autoSwitch = v);
            _save();
          },
        ),
      ],
    ),
  );

  Widget _searchBar() => TextField(
    onChanged: (v) => setState(() => _search = v),
    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13),
    decoration: InputDecoration(
      hintText: 'Search languages...',
      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5), size: 12),
      prefixIcon: Icon(Icons.search, size: 18, color: hex(AppColors.outline)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
  );

  Widget _layoutRow(_Layout l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    decoration: BoxDecoration(
      color: hex(l.enabled ? AppColors.primary : AppColors.surfaceContainerLow)
          .withValues(alpha: l.enabled ? 0.04 : 1),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(
        color: hex(l.enabled ? AppColors.primary : AppColors.outlineVariant)
            .withValues(alpha: l.enabled ? 0.15 : 0.1),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: hex(AppColors.outline).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Center(
            child: Text(l.flag,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 10, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.name,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface),
                      weight: l.enabled ? FontWeight.w600 : FontWeight.w400, size: 12)),
              Text(l.code,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Switch(
            value: l.enabled,
            activeTrackColor: hex(AppColors.primary),
            onChanged: (v) {
              if (!v && _enabledCount <= 1) return;
              setState(() => l.enabled = v);
              _save();
            },
          ),
        ),
      ],
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
            'Enable multiple keyboard layouts to switch languages while typing on your TV. At least one layout must stay active.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
