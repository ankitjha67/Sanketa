import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvThemeScreen extends StatefulWidget {
  const TvThemeScreen({super.key});

  @override
  State<TvThemeScreen> createState() => _TvThemeScreenState();
}

class _TvThemeScreenState extends State<TvThemeScreen> {
  bool _loading = true;
  int _themeIdx = 0;
  int _fontIdx = 0;
  double _uiScale = 100;

  static const _themes = <(String, IconData, int, int, int)>[
    ('Dark Mode', Icons.dark_mode, AppColors.primary, 0xFF1E1E2E, 0xFFE0E0E0),
    ('Light Mode', Icons.light_mode, AppColors.alertAmber, 0xFFFFFBFE, 0xFF1C1B1F),
    ('AMOLED Black', Icons.phone_android, AppColors.outline, 0xFF000000, 0xFFFFFFFF),
    ('Ocean Blue', Icons.water, AppColors.secondary, 0xFF0D1B2A, 0xFF89CFF0),
    ('Forest Green', Icons.park, AppColors.signalEmerald, 0xFF1B2D1B, 0xFFA8D5A8),
    ('Warm Sunset', Icons.wb_twilight, AppColors.error, 0xFF2D1B1B, 0xFFFFB088),
  ];

  static const _fonts = <(String, int)>[
    ('System Default', AppColors.primary),
    ('Rounded', AppColors.signalEmerald),
    ('Monospace', AppColors.alertAmber),
    ('Serif', AppColors.secondary),
    ('Condensed', AppColors.tertiary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_theme.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _themeIdx = j['themeIdx'] as int? ?? 0;
        _fontIdx = j['fontIdx'] as int? ?? 0;
        _uiScale = (j['uiScale'] as num?)?.toDouble() ?? 100;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'themeIdx': _themeIdx,
      'fontIdx': _fontIdx,
      'uiScale': _uiScale,
    }));
  }

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.heavyImpact();
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Theme applied to TV'),
        duration: Duration(seconds: 2),
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
        title: Text('TV Theme',
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
                const SizedBox(height: AppSpacing.lg),
                Text('Theme',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                _themeGrid(),
                const SizedBox(height: AppSpacing.lg),
                Text('Font Style',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                _fontChips(),
                const SizedBox(height: AppSpacing.lg),
                _scaleSlider(),
                const SizedBox(height: AppSpacing.lg),
                _applyButton(),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.palette, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('TV Theme Manager',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Customize your TV interface appearance',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() {
    final theme = _themes[_themeIdx];
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Color(theme.$4),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(theme.$3).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(theme.$5),
                ),
              ),
              const SizedBox(width: 6),
              Text('TV Preview',
                  style: TextStyle(
                    color: Color(theme.$5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              Text(theme.$1,
                  style: TextStyle(
                    color: Color(theme.$5).withValues(alpha: 0.6),
                    fontSize: 10,
                  )),
            ],
          ),
          const Spacer(),
          Text('Sample text in ${_fonts[_fontIdx].$1}',
              style: TextStyle(
                color: Color(theme.$5),
                fontSize: 14 * (_uiScale / 100),
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) => Container(
                  width: 24,
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Color(theme.$5).withValues(alpha: i < 3 ? 0.6 : 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _themeGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.2,
        children: _themes.asMap().entries.map((e) {
          final active = e.key == _themeIdx;
          return GestureDetector(
            onTap: () {
              setState(() => _themeIdx = e.key);
              HapticFeedback.selectionClick();
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
                  Icon(e.value.$2,
                      size: 22, color: hex(e.value.$3)),
                  const SizedBox(height: 4),
                  Text(e.value.$1,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(e.value.$3),
                          weight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          size: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _fontChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _fonts.asMap().entries.map((e) {
            final active = e.key == _fontIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _fontIdx = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(e.value.$2)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$2)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Text(e.value.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(e.value.$2),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _scaleSlider() => Container(
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
                Text('UI Scale',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_uiScale.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.tertiary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _uiScale,
              min: 75,
              max: 150,
              activeColor: hex(AppColors.tertiary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) => setState(() => _uiScale = v),
            ),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.tertiary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.tertiary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 20, color: hex(AppColors.tertiary)),
              const SizedBox(width: 8),
              Text('Apply Theme',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.tertiary),
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
                'Customize your TV interface. Choose theme, font, and scale. '
                'All preferences stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
