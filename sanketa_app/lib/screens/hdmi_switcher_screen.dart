import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class HdmiSwitcherScreen extends StatefulWidget {
  const HdmiSwitcherScreen({super.key});

  @override
  State<HdmiSwitcherScreen> createState() => _HdmiSwitcherScreenState();
}

class _HdmiSwitcherScreenState extends State<HdmiSwitcherScreen> {
  int _activePort = 0;
  bool _loading = true;

  final _ports = <(String, String, IconData, bool)>[
    ('HDMI 1', 'Cable Box', Icons.live_tv, true),
    ('HDMI 2', 'Game Console', Icons.sports_esports, true),
    ('HDMI 3', 'Streaming Stick', Icons.cast, true),
    ('HDMI 4', 'Blu-ray Player', Icons.album, false),
    ('AV', 'Legacy Input', Icons.settings_input_composite, false),
    ('Component', 'Not Connected', Icons.settings_input_component, false),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/hdmi_switcher.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _activePort = data['active'] as int? ?? 0;
        final labels = data['labels'] as List?;
        if (labels != null) {
          for (var i = 0; i < labels.length && i < _ports.length; i++) {
            final l = labels[i] as String;
            _ports[i] = (_ports[i].$1, l, _ports[i].$3, _ports[i].$4);
          }
        }
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'active': _activePort,
      'labels': _ports.map((p) => p.$2).toList(),
    }));
  }

  void _switchTo(int i) {
    setState(() => _activePort = i);
    _save();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switching to ${_ports[i].$1}: ${_ports[i].$2}'),
        duration: const Duration(seconds: 2),
      ));
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
        title: Text('HDMI Switch',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _portList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.settings_input_hdmi, size: 36, color: hex(AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active: ${_ports[_activePort].$1}',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary), weight: FontWeight.w600)),
                  Text(_ports[_activePort].$2,
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _portList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inputs (${_ports.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_ports.length, (i) {
            final p = _ports[i];
            final active = i == _activePort;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _switchTo(i),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.primary : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(p.$3, size: 22,
                          color: hex(active ? AppColors.primary : AppColors.outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600, size: 12)),
                            Text(p.$2,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline), size: 10)),
                          ],
                        ),
                      ),
                      if (p.$4)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: hex(active ? AppColors.signalEmerald : AppColors.outline),
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18, color: hex(active ? AppColors.primary : AppColors.outline)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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
                'Quickly switch between HDMI and AV inputs on your TV. Green dot indicates a connected device. Tap any input to switch. Labels saved locally.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
