import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenRotateScreen extends StatefulWidget {
  const ScreenRotateScreen({super.key});

  @override
  State<ScreenRotateScreen> createState() => _ScreenRotateScreenState();
}

class _ScreenRotateScreenState extends State<ScreenRotateScreen> {
  int _selectedRotation = 0;
  bool _autoRotate = false;
  bool _loading = true;

  static const _rotations = <(String, int, IconData)>[
    ('Normal (0°)', 0, Icons.stay_current_landscape),
    ('90° CW', 90, Icons.rotate_right),
    ('180° Flip', 180, Icons.flip),
    ('90° CCW', 270, Icons.rotate_left),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/screen_rotate.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final d = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedRotation = d['rotation'] as int? ?? 0;
        _autoRotate = d['auto'] as bool? ?? false;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'rotation': _selectedRotation,
      'auto': _autoRotate,
    }));
  }

  void _applyRotation(int i) {
    setState(() => _selectedRotation = i);
    _save();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Rotation set to ${_rotations[i].$1}'),
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
        title: Text('Screen Rotate',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _rotationList(),
          const SizedBox(height: AppSpacing.md),
          _autoToggle(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.screen_rotation, size: 36, color: hex(AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Rotation',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.secondary), weight: FontWeight.w600)),
                  Text('Current: ${_rotations[_selectedRotation].$1}',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _previewCard() => Container(
        height: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Transform.rotate(
            angle: _rotations[_selectedRotation].$2 * 3.14159 / 180,
            child: Container(
              width: 120,
              height: 70,
              decoration: BoxDecoration(
                color: hex(AppColors.secondary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: hex(AppColors.secondary).withValues(alpha: 0.4), width: 2),
              ),
              child: Center(
                child: Icon(Icons.tv, size: 30, color: hex(AppColors.secondary)),
              ),
            ),
          ),
        ),
      );

  Widget _rotationList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orientation',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_rotations.length, (i) {
            final r = _rotations[i];
            final active = i == _selectedRotation;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _applyRotation(i),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.secondary : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? AppColors.secondary : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(r.$3, size: 22,
                          color: hex(active ? AppColors.secondary : AppColors.outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600, size: 12)),
                      ),
                      Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18, color: hex(active ? AppColors.secondary : AppColors.outline)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _autoToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.screen_rotation_alt, size: 20, color: hex(AppColors.secondary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Auto-rotate with content',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
            ),
            Switch(
              value: _autoRotate,
              activeThumbColor: hex(AppColors.secondary),
              onChanged: (v) {
                setState(() => _autoRotate = v);
                _save();
              },
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
                'Rotate your TV display orientation. Useful for portrait-mounted TVs, digital signage, or vertically oriented content. Setting saved locally.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
