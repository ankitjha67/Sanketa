import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _InputEntry {
  _InputEntry({required this.port, required this.label, this.icon = Icons.settings_input_hdmi});
  final String port;
  String label;
  final IconData icon;

  Map<String, dynamic> toJson() => {'port': port, 'label': label};
}

class InputRenameScreen extends StatefulWidget {
  const InputRenameScreen({super.key});

  @override
  State<InputRenameScreen> createState() => _InputRenameScreenState();
}

class _InputRenameScreenState extends State<InputRenameScreen> {
  late List<_InputEntry> _inputs;
  bool _loading = true;

  static final _defaultInputs = [
    _InputEntry(port: 'HDMI 1', label: 'HDMI 1', icon: Icons.settings_input_hdmi),
    _InputEntry(port: 'HDMI 2', label: 'HDMI 2', icon: Icons.settings_input_hdmi),
    _InputEntry(port: 'HDMI 3', label: 'HDMI 3', icon: Icons.settings_input_hdmi),
    _InputEntry(port: 'HDMI 4', label: 'HDMI 4', icon: Icons.settings_input_hdmi),
    _InputEntry(port: 'USB', label: 'USB', icon: Icons.usb),
    _InputEntry(port: 'AV', label: 'AV', icon: Icons.settings_input_composite),
    _InputEntry(port: 'Antenna', label: 'Antenna', icon: Icons.settings_input_antenna),
  ];

  static const _quickLabels = [
    'PlayStation', 'Xbox', 'Nintendo', 'Blu-ray', 'Soundbar',
    'Apple TV', 'Fire Stick', 'Chromecast', 'Cable Box', 'PC',
  ];

  @override
  void initState() {
    super.initState();
    _inputs = _defaultInputs.map((d) => _InputEntry(port: d.port, label: d.label, icon: d.icon)).toList();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/input_rename.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        for (final j in list) {
          final m = j as Map<String, dynamic>;
          final port = m['port'] as String;
          final label = m['label'] as String;
          final match = _inputs.where((i) => i.port == port);
          if (match.isNotEmpty) {
            match.first.label = label;
          }
        }
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_inputs.map((i) => i.toJson()).toList()));
  }

  void _editLabel(int index) {
    final ctrl = TextEditingController(text: _inputs[index].label);
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rename ${_inputs[index].port}',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: _inputs[index].port,
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  setState(() => _inputs[index].label = v.trim());
                  _save();
                }
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickLabels.map((l) => GestureDetector(
                onTap: () {
                  setState(() => _inputs[index].label = l);
                  _save();
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
                  ),
                  child: Text(l,
                      style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 10)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAll() {
    setState(() {
      for (var i = 0; i < _inputs.length; i++) {
        _inputs[i].label = _defaultInputs[i].label;
      }
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
        title: Text('Rename Inputs',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _resetAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.restart_alt, size: 20, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ..._inputs.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _inputCard(e.value, e.key),
          )),
          const SizedBox(height: AppSpacing.md),
          _switchButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _inputCard(_InputEntry input, int index) => GestureDetector(
    onTap: () => _editLabel(index),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(input.icon, size: 18, color: hex(AppColors.primary)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(input.label,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
              if (input.label != input.port)
                Text(input.port,
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit, size: 14, color: hex(AppColors.outline)),
        ],
      ),
    ),
  );

  Widget _switchButton() => GestureDetector(
    onTap: () => RemoteScope.of(context).key(core.Key.input),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz, size: 16, color: hex(AppColors.onSurface)),
          const SizedBox(width: 8),
          Text('Switch Input on TV',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
        ],
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
            'Give your TV inputs friendly names. Tap an input to rename it, or choose a quick label. These names are stored locally on this phone.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
