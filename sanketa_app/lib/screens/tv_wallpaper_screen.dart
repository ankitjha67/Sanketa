import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvWallpaperScreen extends StatefulWidget {
  const TvWallpaperScreen({super.key});

  @override
  State<TvWallpaperScreen> createState() => _TvWallpaperScreenState();
}

class _TvWallpaperScreenState extends State<TvWallpaperScreen> {
  int _selectedIndex = 0;
  bool _clockOverlay = true;
  bool _loading = true;

  static const _wallpapers = <(String, IconData, int, String)>[
    ('Nebula', Icons.auto_awesome, AppColors.primary, 'Deep space nebula with stars'),
    ('Sunset', Icons.wb_twilight, AppColors.alertAmber, 'Golden sunset over ocean'),
    ('Forest', Icons.forest, AppColors.signalEmerald, 'Misty morning forest'),
    ('Mountains', Icons.landscape, AppColors.tertiary, 'Snow-capped mountain peaks'),
    ('Ocean', Icons.water, AppColors.secondary, 'Calm blue ocean waves'),
    ('City', Icons.location_city, AppColors.primary, 'City skyline at night'),
    ('Abstract', Icons.blur_circular, AppColors.error, 'Flowing abstract colors'),
    ('Fireplace', Icons.local_fire_department, AppColors.alertAmber, 'Cozy fireplace ambiance'),
    ('Aquarium', Icons.set_meal, AppColors.signalEmerald, 'Tropical fish aquarium'),
    ('Aurora', Icons.nights_stay, AppColors.tertiary, 'Northern lights display'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_wallpaper.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _selectedIndex = data['selectedIndex'] as int? ?? 0;
        _clockOverlay = data['clockOverlay'] as bool? ?? true;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'selectedIndex': _selectedIndex,
      'clockOverlay': _clockOverlay,
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
        content: Text('${_wallpapers[_selectedIndex].$1} wallpaper applied'),
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

    final active = _wallpapers[_selectedIndex];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Wallpaper',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(active),
          const SizedBox(height: AppSpacing.md),
          _wallpaperGrid(),
          const SizedBox(height: AppSpacing.md),
          _clockToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard((String, IconData, int, String) wp) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: hex(wp.$3).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(wp.$3).withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(wp.$2, size: 64, color: hex(wp.$3).withValues(alpha: 0.5)),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wp.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(wp.$3), weight: FontWeight.w700)),
                  Text(wp.$4,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            if (_clockOverlay)
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surface).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('12:00',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w700,
                          size: 12)),
                ),
              ),
          ],
        ),
      );

  Widget _wallpaperGrid() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wallpapers',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _wallpapers.asMap().entries.map((e) {
              final wp = e.value;
              final active = e.key == _selectedIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = e.key);
                  _save();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: hex(wp.$3).withValues(alpha: active ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? wp.$3 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.5 : 0.15),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(wp.$2,
                          size: 24,
                          color: hex(wp.$3)
                              .withValues(alpha: active ? 1 : 0.5)),
                      const SizedBox(height: 4),
                      Text(wp.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.onSurface
                                  : AppColors.outline),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _clockToggle() => GestureDetector(
        onTap: () {
          setState(() => _clockOverlay = !_clockOverlay);
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
              Icon(Icons.schedule, size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clock Overlay',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('Show clock on wallpaper',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_clockOverlay
                          ? AppColors.signalEmerald
                          : AppColors.outlineVariant)
                      .withValues(alpha: _clockOverlay ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _clockOverlay
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_clockOverlay
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
              Icon(Icons.wallpaper, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Wallpaper',
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
                'Set ambient wallpapers for your TV when idle. Choose from scenic, abstract, and cozy themes. Enable clock overlay to show time.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
