import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _InputPort {
  _InputPort({
    required this.id,
    required this.defaultName,
    this.customName = '',
    this.iconIndex = 0,
  });

  factory _InputPort.fromJson(Map<String, dynamic> j) => _InputPort(
        id: j['id'] as String,
        defaultName: j['defaultName'] as String,
        customName: j['customName'] as String? ?? '',
        iconIndex: j['iconIndex'] as int? ?? 0,
      );

  final String id;
  final String defaultName;
  String customName;
  int iconIndex;

  String get displayName => customName.isNotEmpty ? customName : defaultName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'defaultName': defaultName,
        'customName': customName,
        'iconIndex': iconIndex,
      };
}

class InputLabelerScreen extends StatefulWidget {
  const InputLabelerScreen({super.key});

  @override
  State<InputLabelerScreen> createState() => _InputLabelerScreenState();
}

class _InputLabelerScreenState extends State<InputLabelerScreen> {
  late List<_InputPort> _ports;
  bool _loading = true;
  int? _editingIndex;
  final _nameCtrl = TextEditingController();

  static const _icons = <(IconData, String)>[
    (Icons.tv, 'TV'),
    (Icons.videogame_asset, 'Console'),
    (Icons.computer, 'PC'),
    (Icons.speaker, 'Soundbar'),
    (Icons.cast, 'Chromecast'),
    (Icons.movie, 'Blu-ray'),
    (Icons.cable, 'Cable Box'),
    (Icons.router, 'Streaming'),
  ];

  static final _defaultPorts = [
    _InputPort(id: 'hdmi1', defaultName: 'HDMI 1'),
    _InputPort(id: 'hdmi2', defaultName: 'HDMI 2'),
    _InputPort(id: 'hdmi3', defaultName: 'HDMI 3'),
    _InputPort(id: 'hdmi4', defaultName: 'HDMI 4'),
    _InputPort(id: 'av', defaultName: 'AV'),
    _InputPort(id: 'component', defaultName: 'Component'),
    _InputPort(id: 'usb', defaultName: 'USB'),
  ];

  @override
  void initState() {
    super.initState();
    _ports = _defaultPorts.map((p) => _InputPort(
          id: p.id,
          defaultName: p.defaultName,
        )).toList();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/input_labels.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        final saved = list
            .map((j) => _InputPort.fromJson(j as Map<String, dynamic>))
            .toList();
        for (final s in saved) {
          final idx = _ports.indexWhere((p) => p.id == s.id);
          if (idx >= 0) {
            _ports[idx].customName = s.customName;
            _ports[idx].iconIndex = s.iconIndex;
          }
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_ports.map((p) => p.toJson()).toList()));
  }

  void _startEditing(int idx) {
    setState(() {
      _editingIndex = idx;
      _nameCtrl.text = _ports[idx].customName;
    });
  }

  void _saveEdit() {
    if (_editingIndex == null) return;
    setState(() {
      _ports[_editingIndex!].customName = _nameCtrl.text.trim();
      _editingIndex = null;
    });
    _save();
  }

  void _cancelEdit() {
    setState(() => _editingIndex = null);
  }

  void _setIcon(int portIdx, int iconIdx) {
    setState(() => _ports[portIdx].iconIndex = iconIdx);
    _save();
  }

  void _resetAll() {
    setState(() {
      for (final p in _ports) {
        p.customName = '';
        p.iconIndex = 0;
      }
    });
    _save();
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
        title: Text('Input Labeler',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _resetAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.restart_alt,
                  size: 20, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          Text('TV Inputs (${_ports.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._ports.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _editingIndex == e.key
                    ? _editCard(e.value, e.key)
                    : _portCard(e.value, e.key),
              )),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.label, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Name Your Inputs',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Give each HDMI and AV input a friendly name and icon',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _portCard(_InputPort port, int idx) => GestureDetector(
        onTap: () => _startEditing(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(_icons[port.iconIndex].$1,
                    size: 20, color: hex(AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(port.displayName,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    if (port.customName.isNotEmpty)
                      Text(port.defaultName,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Icon(Icons.edit, size: 16, color: hex(AppColors.outline)),
            ],
          ),
        ),
      );

  Widget _editCard(_InputPort port, int idx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editing ${port.defaultName}',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600,
                    size: 11)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              maxLength: 20,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'e.g. PlayStation, Apple TV...',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline).withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.3)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _saveEdit(),
            ),
            const SizedBox(height: 8),
            Text('Icon',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 10)),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final active = i == port.iconIndex;
                  return GestureDetector(
                    onTap: () => _setIcon(idx, i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hex(active
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.5 : 0.2),
                        ),
                      ),
                      child: Icon(_icons[i].$1,
                          size: 16,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.outline)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _cancelEdit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Cancel',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline),
                            weight: FontWeight.w600,
                            size: 11)),
                  ),
                ),
                GestureDetector(
                  onTap: _saveEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text('Save',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600,
                            size: 11)),
                  ),
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
                'Give your TV inputs friendly names like "PlayStation" or "Apple TV" so the whole family knows which input to choose. Labels are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
