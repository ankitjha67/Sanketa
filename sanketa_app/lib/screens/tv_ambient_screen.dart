import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvAmbientScreen extends StatefulWidget {
  const TvAmbientScreen({super.key});

  @override
  State<TvAmbientScreen> createState() => _TvAmbientScreenState();
}

class _TvAmbientScreenState extends State<TvAmbientScreen> {
  bool _loading = true;
  bool _active = false;
  int _sceneIdx = 0;
  bool _showClock = true;
  bool _showWeather = true;
  double _brightness = 70;
  Timer? _clockTimer;
  String _time = '';

  static const _scenes = <(String, IconData, int, String)>[
    ('Fireplace', Icons.fireplace, AppColors.alertAmber, 'Warm cozy flames'),
    ('Aquarium', Icons.water, AppColors.primary, 'Tropical fish tank'),
    ('Starfield', Icons.star, AppColors.secondary, 'Deep space stars'),
    ('Rain', Icons.water_drop, AppColors.tertiary, 'Calming rainfall'),
    ('Aurora', Icons.gradient, AppColors.signalEmerald, 'Northern lights'),
    ('Candles', Icons.local_fire_department, AppColors.error, 'Flickering candles'),
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => _updateTime());
    _load();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _time = '$h:${now.minute.toString().padLeft(2, '0')} $ampm';
      });
    }
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_ambient.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _sceneIdx = j['sceneIdx'] as int? ?? 0;
        _showClock = j['showClock'] as bool? ?? true;
        _showWeather = j['showWeather'] as bool? ?? true;
        _brightness = (j['brightness'] as num?)?.toDouble() ?? 70;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'sceneIdx': _sceneIdx,
      'showClock': _showClock,
      'showWeather': _showWeather,
      'brightness': _brightness,
    }));
  }

  void _toggleAmbient() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    setState(() => _active = !_active);
    HapticFeedback.heavyImpact();
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_active ? 'Ambient mode on' : 'Ambient mode off'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Ambient TV',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.lg),
                _previewCard(),
                const SizedBox(height: AppSpacing.md),
                _activateButton(),
                const SizedBox(height: AppSpacing.lg),
                Text('Scene',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                _sceneGrid(),
                const SizedBox(height: AppSpacing.lg),
                _overlayToggles(),
                const SizedBox(height: AppSpacing.md),
                _brightnessSlider(),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.nightlight_round,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Ambient Display',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Turn your TV into a beautiful ambient display',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() {
    final scene = _scenes[_sceneIdx];
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(scene.$3).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          Center(
            child: Icon(scene.$2,
                size: 48,
                color: hex(scene.$3)
                    .withValues(alpha: _brightness / 100)),
          ),
          if (_showClock)
            Positioned(
              top: 8,
              right: 8,
              child: Text(_time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  )),
            ),
          if (_showWeather)
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  Icon(Icons.wb_sunny,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text('24°C',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      )),
                ],
              ),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hex(scene.$3).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(scene.$1,
                  style: TextStyle(
                    color: hex(scene.$3),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
          if (_active)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hex(AppColors.signalEmerald),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _activateButton() => GestureDetector(
        onTap: _toggleAmbient,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_active ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(_active ? AppColors.error : AppColors.signalEmerald)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_active ? Icons.stop : Icons.play_arrow,
                  size: 22,
                  color: hex(
                      _active ? AppColors.error : AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text(_active ? 'Stop Ambient' : 'Start Ambient',
                  style: gfont(AppType.bodyMd,
                      color: hex(_active
                          ? AppColors.error
                          : AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _sceneGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
        children: _scenes.asMap().entries.map((e) {
          final active = e.key == _sceneIdx;
          return GestureDetector(
            onTap: () {
              setState(() => _sceneIdx = e.key);
              HapticFeedback.selectionClick();
              _save();
            },
            child: Container(
              decoration: BoxDecoration(
                color: hex(e.value.$3)
                    .withValues(alpha: active ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(e.value.$3)
                      .withValues(alpha: active ? 0.5 : 0.15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(e.value.$2, size: 22, color: hex(e.value.$3)),
                  const SizedBox(height: 4),
                  Text(e.value.$1,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(e.value.$3),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _overlayToggles() => Column(
        children: [
          _toggleRow('Clock Overlay', Icons.access_time, _showClock, (v) {
            setState(() => _showClock = v);
            _save();
          }),
          const SizedBox(height: AppSpacing.sm),
          _toggleRow('Weather Overlay', Icons.wb_sunny, _showWeather, (v) {
            setState(() => _showWeather = v);
            _save();
          }),
        ],
      );

  Widget _toggleRow(
      String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(value
                  ? AppColors.signalEmerald
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: value ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(value
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant)
                .withValues(alpha: value ? 0.25 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: hex(
                    value ? AppColors.signalEmerald : AppColors.outline)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 13)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(value
                        ? AppColors.signalEmerald
                        : AppColors.outline)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(value ? 'ON' : 'OFF',
                  style: gfont(AppType.bodySm,
                      color: hex(value
                          ? AppColors.signalEmerald
                          : AppColors.outline),
                      weight: FontWeight.w700,
                      size: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brightnessSlider() => Container(
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
                Text('Brightness',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_brightness.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _brightness,
              min: 10,
              max: 100,
              activeColor: hex(AppColors.signalEmerald),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) {
                setState(() => _brightness = v);
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
                'Turn your TV into an ambient display. Choose scene, '
                'toggle clock/weather overlays. All preferences local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
