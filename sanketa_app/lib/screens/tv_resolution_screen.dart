import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvResolutionScreen extends StatefulWidget {
  const TvResolutionScreen({super.key});

  @override
  State<TvResolutionScreen> createState() => _TvResolutionScreenState();
}

class _TvResolutionScreenState extends State<TvResolutionScreen> {
  int _resIndex = 2;
  int _rateIndex = 1;
  bool _hdr = false;
  bool _loading = true;

  static const _resolutions = <(String, String, int)>[
    ('720p', '1280 x 720', AppColors.outline),
    ('1080p', '1920 x 1080', AppColors.signalEmerald),
    ('4K', '3840 x 2160', AppColors.primary),
    ('8K', '7680 x 4320', AppColors.secondary),
  ];

  static const _rates = <(String, int)>[
    ('24 Hz', AppColors.outline),
    ('30 Hz', AppColors.alertAmber),
    ('60 Hz', AppColors.signalEmerald),
    ('120 Hz', AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_resolution.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _resIndex = data['resIndex'] as int? ?? 2;
        _rateIndex = data['rateIndex'] as int? ?? 1;
        _hdr = data['hdr'] as bool? ?? false;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'resIndex': _resIndex,
      'rateIndex': _rateIndex,
      'hdr': _hdr,
    }));
  }

  void _apply() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    _save();
    final res = _resolutions[_resIndex];
    final rate = _rates[_rateIndex];
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Applied: ${res.$1} @ ${rate.$1}${_hdr ? " HDR" : ""}'),
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
        title: Text('TV Resolution',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _currentCard(),
          const SizedBox(height: AppSpacing.md),
          _resolutionPicker(),
          const SizedBox(height: AppSpacing.md),
          _refreshRatePicker(),
          const SizedBox(height: AppSpacing.md),
          _hdrToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _currentCard() {
    final res = _resolutions[_resIndex];
    final rate = _rates[_rateIndex];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(res.$3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(res.$3).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.tv, size: 48, color: hex(res.$3)),
          const SizedBox(height: 8),
          Text(res.$1,
              style: gfont(AppType.bodyMd,
                  color: hex(res.$3),
                  weight: FontWeight.w700,
                  size: 24)),
          Text(res.$2,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(rate.$2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(rate.$1,
                    style: gfont(AppType.bodySm,
                        color: hex(rate.$2),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
              if (_hdr) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hex(AppColors.alertAmber).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('HDR',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.alertAmber),
                          weight: FontWeight.w700,
                          size: 10)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _resolutionPicker() => Container(
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
            Text('Resolution',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _resolutions.asMap().entries.map((e) {
                final active = e.key == _resIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _resIndex = e.key);
                      _save();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(active ? e.value.$3 : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: hex(active ? e.value.$3 : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.5 : 0.2),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(e.value.$1,
                              style: gfont(AppType.bodyMd,
                                  color: hex(active ? e.value.$3 : AppColors.onSurface),
                                  weight: active ? FontWeight.w700 : FontWeight.w500,
                                  size: 13)),
                          Text(e.value.$2,
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline),
                                  size: 8)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _refreshRatePicker() => Container(
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
            Text('Refresh Rate',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _rates.asMap().entries.map((e) {
                final active = e.key == _rateIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _rateIndex = e.key);
                      _save();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(active ? e.value.$2 : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: hex(active ? e.value.$2 : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.5 : 0.2),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(e.value.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? e.value.$2 : AppColors.onSurface),
                                weight: active ? FontWeight.w700 : FontWeight.w500,
                                size: 11)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _hdrToggle() => GestureDetector(
        onTap: () {
          setState(() => _hdr = !_hdr);
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
              Icon(Icons.hdr_on, size: 20, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HDR Mode',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('High Dynamic Range for richer colors',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_hdr ? AppColors.alertAmber : AppColors.outlineVariant)
                      .withValues(alpha: _hdr ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _hdr ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_hdr ? AppColors.alertAmber : AppColors.outline),
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
              Text('Apply Resolution',
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
                'Change TV display resolution and refresh rate. Higher resolution means sharper images. Higher refresh rate means smoother motion. Enable HDR for richer colors on supported content.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
