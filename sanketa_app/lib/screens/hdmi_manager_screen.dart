import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class HdmiInput {
  HdmiInput({
    required this.port,
    required this.name,
    this.icon,
    this.deviceType = 'generic',
  });

  final int port;
  String name;
  final String? icon;
  String deviceType;

  Map<String, dynamic> toJson() => {
    'port': port,
    'name': name,
    'deviceType': deviceType,
    if (icon != null) 'icon': icon,
  };

  factory HdmiInput.fromJson(Map<String, dynamic> j) => HdmiInput(
    port: j['port'] as int,
    name: j['name'] as String,
    icon: j['icon'] as String?,
    deviceType: j['deviceType'] as String? ?? 'generic',
  );
}

class HdmiManagerScreen extends StatefulWidget {
  const HdmiManagerScreen({super.key});

  @override
  State<HdmiManagerScreen> createState() => _HdmiManagerScreenState();
}

class _HdmiManagerScreenState extends State<HdmiManagerScreen> {
  List<HdmiInput> _inputs = [];
  bool _loading = true;
  int? _activePort;

  static const _deviceTypes = <String, (String, IconData)>{
    'generic': ('Generic', Icons.settings_input_hdmi),
    'console': ('Game Console', Icons.sports_esports),
    'streaming': ('Streaming Device', Icons.cast),
    'bluray': ('Blu-ray Player', Icons.album),
    'soundbar': ('Soundbar / AVR', Icons.speaker),
    'pc': ('Computer', Icons.computer),
    'cable': ('Cable / Satellite', Icons.tv),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/hdmi_inputs.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['inputs'] as List;
        _inputs = list.map((e) => HdmiInput.fromJson(e as Map<String, dynamic>)).toList();
        _activePort = data['activePort'] as int?;
      } else {
        _inputs = List.generate(4, (i) => HdmiInput(
          port: i + 1,
          name: 'HDMI ${i + 1}',
        ));
      }
    } on Object {
      _inputs = List.generate(4, (i) => HdmiInput(
        port: i + 1,
        name: 'HDMI ${i + 1}',
      ));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'inputs': _inputs.map((i) => i.toJson()).toList(),
      'activePort': _activePort,
    }));
  }

  void _switchTo(HdmiInput input) {
    final c = RemoteScope.of(context);
    c.key(core.Key.input);
    final digitKey = core.Key.values.firstWhere(
      (k) => k.name == 'digit${input.port}',
      orElse: () => core.Key.ok,
    );
    c.key(digitKey);
    setState(() => _activePort = input.port);
    _save();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Switching to ${input.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _renameInput(int index) {
    final ctrl = TextEditingController(text: _inputs[index].name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLowest),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Rename HDMI ${_inputs[index].port}',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: 'e.g. PlayStation, Apple TV',
            hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
            isDense: true,
            filled: true,
            fillColor: hex(AppColors.surfaceContainerHigh),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _inputs[index].name = name);
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Save',
                style: gfont(AppType.bodySm, color: hex(AppColors.primaryContainer), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _changeDeviceType(int index) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Type',
                  style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              ..._deviceTypes.entries.map((e) => GestureDetector(
                onTap: () => Navigator.pop(ctx, e.key),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(e.value.$2, size: 20, color: hex(AppColors.onSurface)),
                      const SizedBox(width: 12),
                      Text(e.value.$1, style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface))),
                      if (_inputs[index].deviceType == e.key) ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: hex(AppColors.primary)),
                      ],
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    ).then((type) {
      if (type != null && mounted) {
        setState(() => _inputs[index].deviceType = type);
        _save();
      }
    });
  }

  void _addPort() {
    final nextPort = _inputs.isEmpty ? 1 : _inputs.map((i) => i.port).reduce((a, b) => a > b ? a : b) + 1;
    if (nextPort > 8) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Maximum 8 HDMI ports supported.'),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
      return;
    }
    setState(() => _inputs.add(HdmiInput(port: nextPort, name: 'HDMI $nextPort')));
    _save();
  }

  void _removePort(int index) {
    setState(() => _inputs.removeAt(index));
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
        title: Text('HDMI Inputs',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addPort,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _inputs.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _inputs.length) return _quickSwitch();
                return _inputTile(_inputs[i], i);
              },
            ),
    );
  }

  Widget _inputTile(HdmiInput input, int index) {
    final isActive = _activePort == input.port;
    final deviceInfo = _deviceTypes[input.deviceType] ?? _deviceTypes['generic']!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _switchTo(input),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: panel(
            fill: isActive ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: isActive ? 0.4 : 0.15,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hex(isActive ? AppColors.primaryContainer : AppColors.outlineVariant)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: isActive
                      ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4), width: 1.5)
                      : null,
                ),
                child: Icon(deviceInfo.$2, size: 20,
                    color: hex(isActive ? AppColors.primary : AppColors.outline)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(input.name,
                            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text('ACTIVE',
                                style: gfont(AppType.labelMonoSm,
                                    color: hex(AppColors.signalEmerald), size: 8)),
                          ),
                        ],
                      ],
                    ),
                    Text('Port ${input.port} · ${deviceInfo.$1}',
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _renameInput(index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.edit, size: 14, color: hex(AppColors.outlineVariant)),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _changeDeviceType(index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.category, size: 14, color: hex(AppColors.outlineVariant)),
                ),
              ),
              if (_inputs.length > 1)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _removePort(index),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 14, color: hex(AppColors.outlineVariant)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickSwitch() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
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
              'Tap an input to switch. Rename and tag device types to remember what\'s plugged in where.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
