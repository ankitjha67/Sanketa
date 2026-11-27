import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SceneModeScreen extends StatefulWidget {
  const SceneModeScreen({super.key});

  @override
  State<SceneModeScreen> createState() => _SceneModeScreenState();
}

class _SceneModeScreenState extends State<SceneModeScreen> {
  int _selectedIndex = 0;
  bool _autoDetect = false;
  bool _loading = true;

  static const _modes = <(String, IconData, int, String, List<(String, String)>)>[
    ('Standard', Icons.tv, AppColors.outline, 'Balanced picture for everyday viewing', [
      ('Brightness', '50%'),
      ('Contrast', '50%'),
      ('Color', '50%'),
      ('Sharpness', '50%'),
    ]),
    ('Movie', Icons.movie, AppColors.tertiary, 'Warm tones, low brightness for cinema', [
      ('Brightness', '35%'),
      ('Contrast', '60%'),
      ('Color', '55%'),
      ('Sharpness', '30%'),
    ]),
    ('Sports', Icons.sports_soccer, AppColors.signalEmerald, 'Vivid colors, smooth motion for sports', [
      ('Brightness', '65%'),
      ('Contrast', '55%'),
      ('Color', '70%'),
      ('Sharpness', '60%'),
    ]),
    ('Game', Icons.sports_esports, AppColors.primary, 'Low input lag, enhanced response time', [
      ('Brightness', '55%'),
      ('Contrast', '50%'),
      ('Color', '60%'),
      ('Sharpness', '65%'),
    ]),
    ('Vivid', Icons.brightness_7, AppColors.alertAmber, 'Maximum brightness, saturated colors', [
      ('Brightness', '80%'),
      ('Contrast', '70%'),
      ('Color', '80%'),
      ('Sharpness', '55%'),
    ]),
    ('Night', Icons.nights_stay, AppColors.secondary, 'Dim, warm light for dark rooms', [
      ('Brightness', '20%'),
      ('Contrast', '40%'),
      ('Color', '40%'),
      ('Sharpness', '25%'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/scene_mode.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedIndex = data['selectedIndex'] as int? ?? 0;
        _autoDetect = data['autoDetect'] as bool? ?? false;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'selectedIndex': _selectedIndex,
      'autoDetect': _autoDetect,
    }));
  }

  void _apply() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_modes[_selectedIndex].$1} mode applied'),
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

    final mode = _modes[_selectedIndex];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Scene Mode',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(mode),
          const SizedBox(height: AppSpacing.md),
          _modeGrid(),
          const SizedBox(height: AppSpacing.md),
          _settingsPreview(mode),
          const SizedBox(height: AppSpacing.md),
          _autoDetectToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, IconData, int, String, List<(String, String)>) m) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(m.$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(m.$3).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(m.$2, size: 48, color: hex(m.$3)),
            const SizedBox(height: 8),
            Text(m.$1,
                style: gfont(AppType.bodyMd,
                    color: hex(m.$3), weight: FontWeight.w700, size: 18)),
            const SizedBox(height: 4),
            Text(m.$4,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _modeGrid() => GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _modes.asMap().entries.map((e) {
          final m = e.value;
          final active = e.key == _selectedIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = e.key);
              _save();
            },
            child: Container(
              decoration: BoxDecoration(
                color: hex(active ? m.$3 : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? m.$3 : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.5 : 0.15),
                  width: active ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(m.$2,
                      size: 24,
                      color: hex(active ? m.$3 : AppColors.outline)),
                  const SizedBox(height: 4),
                  Text(m.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? m.$3 : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _settingsPreview(
          (String, IconData, int, String, List<(String, String)>) m) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Picture Settings',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...m.$5.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w500,
                              size: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(m.$3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(s.$2,
                            style: gfont(AppType.bodySm,
                                color: hex(m.$3),
                                weight: FontWeight.w600,
                                size: 10)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _autoDetectToggle() => GestureDetector(
        onTap: () {
          setState(() => _autoDetect = !_autoDetect);
          _save();
        },
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
              Icon(Icons.auto_awesome,
                  size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto Detect',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Automatically switch mode by content',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_autoDetect
                          ? AppColors.signalEmerald
                          : AppColors.outlineVariant)
                      .withValues(alpha: _autoDetect ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _autoDetect
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_autoDetect
                          ? AppColors.signalEmerald
                          : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Mode',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
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
                'Scene modes optimize picture settings for different content types. Each mode adjusts brightness, contrast, color, and sharpness. Enable auto-detect for automatic switching.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
