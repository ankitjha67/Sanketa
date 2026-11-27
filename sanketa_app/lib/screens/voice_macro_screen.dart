import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VoiceMacroScreen extends StatefulWidget {
  const VoiceMacroScreen({super.key});

  @override
  State<VoiceMacroScreen> createState() => _VoiceMacroScreenState();
}

class _VoiceMacroScreenState extends State<VoiceMacroScreen> {
  bool _loading = true;

  List<_VoiceMacro> _macros = [];

  static final _defaults = <_VoiceMacro>[
    _VoiceMacro(phrase: 'Turn off TV', keys: [core.Key.power], enabled: true),
    _VoiceMacro(phrase: 'Volume up', keys: [core.Key.volumeUp, core.Key.volumeUp, core.Key.volumeUp], enabled: true),
    _VoiceMacro(phrase: 'Volume down', keys: [core.Key.volumeDown, core.Key.volumeDown, core.Key.volumeDown], enabled: true),
    _VoiceMacro(phrase: 'Mute', keys: [core.Key.mute], enabled: true),
    _VoiceMacro(phrase: 'Go home', keys: [core.Key.home], enabled: true),
    _VoiceMacro(phrase: 'Go back', keys: [core.Key.back], enabled: true),
  ];

  static const _availableKeys = <(String, core.Key)>[
    ('Power', core.Key.power),
    ('Volume Up', core.Key.volumeUp),
    ('Volume Down', core.Key.volumeDown),
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
    return File('${dir.path}/voice_macros.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _macros = list.map((e) => _VoiceMacro.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _macros = _defaults.map((m) => _VoiceMacro(phrase: m.phrase, keys: List.of(m.keys), enabled: m.enabled)).toList();
      }
    } catch (_) {
      _macros = _defaults.map((m) => _VoiceMacro(phrase: m.phrase, keys: List.of(m.keys), enabled: m.enabled)).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_macros.map((m) => m.toJson()).toList()));
  }

  void _toggleEnabled(int idx) {
    setState(() => _macros[idx].enabled = !_macros[idx].enabled);
    HapticFeedback.selectionClick();
    _save();
  }

  void _testMacro(int idx) {
    final m = _macros[idx];
    if (!m.enabled || m.keys.isEmpty) return;
    final rc = RemoteScope.of(context);
    for (final k in m.keys) {
      rc.key(k);
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Fired: ${m.phrase}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _deleteMacro(int idx) {
    setState(() => _macros.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _showAddDialog() {
    final phraseCtrl = TextEditingController();
    final selectedKeys = <core.Key>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Voice Macro',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phraseCtrl,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 13),
                decoration: InputDecoration(
                  hintText: 'Voice phrase...',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Actions',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline),
                      weight: FontWeight.w600,
                      size: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableKeys.map((e) {
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedKeys.add(e.$2)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hex(AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                            color: hex(AppColors.primary)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(e.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.primary), size: 10)),
                    ),
                  );
                }).toList(),
              ),
              if (selectedKeys.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: selectedKeys.asMap().entries.map((e) {
                    final label = _availableKeys
                        .firstWhere((a) => a.$2 == e.value)
                        .$1;
                    return Chip(
                      label: Text(label,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 10)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setLocal(() => selectedKeys.removeAt(e.key)),
                      backgroundColor: hex(AppColors.surfaceContainerHigh),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () {
                  if (phraseCtrl.text.trim().isEmpty ||
                      selectedKeys.isEmpty) {
                    return;
                  }
                  setState(() {
                    _macros.add(_VoiceMacro(
                      phrase: phraseCtrl.text.trim(),
                      keys: List.of(selectedKeys),
                      enabled: true,
                    ));
                  });
                  _save();
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(AppColors.primary).withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text('Add Macro',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        title: Text('Voice Macro',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _showAddDialog,
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
                ..._macros.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _macroCard(e.key, e.value),
                    )),
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
            Icon(Icons.mic, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Voice Macros',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Trigger remote actions with voice phrases',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _macroCard(int idx, _VoiceMacro macro) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over,
                    size: 18,
                    color: hex(macro.enabled
                        ? AppColors.primary
                        : AppColors.outline)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('"${macro.phrase}"',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                ),
                GestureDetector(
                  onTap: () => _toggleEnabled(idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hex(macro.enabled
                              ? AppColors.signalEmerald
                              : AppColors.outline)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(macro.enabled ? 'ON' : 'OFF',
                        style: gfont(AppType.bodySm,
                            color: hex(macro.enabled
                                ? AppColors.signalEmerald
                                : AppColors.outline),
                            weight: FontWeight.w600,
                            size: 9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: macro.keys.map((k) {
                final label = _availableKeys
                    .firstWhere((a) => a.$2 == k,
                        orElse: () => ('?', core.Key.ok))
                    .$1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(label,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _testMacro(idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(AppColors.signalEmerald)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                          color: hex(AppColors.signalEmerald)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            size: 14,
                            color: hex(AppColors.signalEmerald)),
                        const SizedBox(width: 4),
                        Text('Test',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.signalEmerald),
                                weight: FontWeight.w600,
                                size: 10)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (idx >= _defaults.length)
                  GestureDetector(
                    onTap: () => _deleteMacro(idx),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: hex(AppColors.error)),
                  ),
              ],
            ),
          ],
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
                'Create voice phrases that trigger sequences of remote commands. '
                'All phrases are matched locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _VoiceMacro {
  String phrase;
  List<core.Key> keys;
  bool enabled;

  _VoiceMacro({
    required this.phrase,
    required this.keys,
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'keys': keys.map((k) => k.name).toList(),
        'enabled': enabled,
      };

  factory _VoiceMacro.fromJson(Map<String, dynamic> j) => _VoiceMacro(
        phrase: j['phrase'] as String? ?? '',
        keys: (j['keys'] as List?)
                ?.map((k) => core.Key.values.firstWhere(
                    (v) => v.name == k,
                    orElse: () => core.Key.ok))
                .toList() ??
            [],
        enabled: j['enabled'] as bool? ?? true,
      );
}
