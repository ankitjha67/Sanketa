import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AspectRatioScreen extends StatefulWidget {
  const AspectRatioScreen({super.key});

  @override
  State<AspectRatioScreen> createState() => _AspectRatioScreenState();
}

class _AspectRatioScreenState extends State<AspectRatioScreen> {
  String _selected = '16:9';
  bool _overscan = false;
  bool _loading = true;

  static const _ratios = <(String, String, double, int)>[
    ('16:9', 'Standard widescreen', 16 / 9, AppColors.primary),
    ('4:3', 'Classic/retro content', 4 / 3, AppColors.tertiary),
    ('21:9', 'Cinemascope/ultrawide', 21 / 9, AppColors.secondary),
    ('1:1', 'Square format', 1, AppColors.signalEmerald),
    ('Auto', 'Match source content', 16 / 9, AppColors.alertAmber),
    ('Zoom', 'Fill screen (crop edges)', 16 / 9, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/aspect_ratio.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selected = j['selected'] as String? ?? '16:9';
        _overscan = j['overscan'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'selected': _selected,
      'overscan': _overscan,
    }));
  }

  void _apply(String ratio) {
    setState(() => _selected = ratio);
    _save();
    RemoteScope.of(context).key(core.Key.menu);
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
        title: Text('Aspect Ratio',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Aspect Ratios',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._ratios.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ratioCard(r.$1, r.$2, r.$3, r.$4),
          )),
          const SizedBox(height: AppSpacing.md),
          _overscanToggle(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final current = _ratios.firstWhere((r) => r.$1 == _selected, orElse: () => _ratios.first);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(current.$4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(current.$4).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160 / current.$3,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: hex(current.$4).withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(current.$1,
                  style: gfont(AppType.headlineMd, color: hex(current.$4), size: 20, weight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Text(current.$2,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
      ),
    );
  }

  Widget _ratioCard(String name, String desc, double ratio, int color) {
    final active = _selected == name;
    return GestureDetector(
      onTap: () => _apply(name),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? color : AppColors.surfaceContainerLow).withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(active ? color : AppColors.outlineVariant).withValues(alpha: active ? 0.4 : 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40 / ratio,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: hex(color).withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
                  Text(desc,
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, size: 18, color: hex(color)),
          ],
        ),
      ),
    );
  }

  Widget _overscanToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.crop_free, size: 20, color: hex(AppColors.outline)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overscan Compensation',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
              Text('Shrink image to show hidden edges',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() => _overscan = !_overscan);
            _save();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: hex(_overscan ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: _overscan ? 1 : 0.3),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _overscan ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hex(_overscan ? AppColors.onPrimary : AppColors.outline),
                ),
              ),
            ),
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
            'Set the display aspect ratio for your TV content. Use Auto to let the TV match the source, or force a specific ratio for letterboxed/stretched content. Overscan compensation reveals edges that some TVs crop.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
