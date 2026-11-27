import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SubtitleStyleScreen extends StatefulWidget {
  const SubtitleStyleScreen({super.key});

  @override
  State<SubtitleStyleScreen> createState() => _SubtitleStyleScreenState();
}

class _SubtitleStyleScreenState extends State<SubtitleStyleScreen> {
  double _fontSize = 18;
  double _bgOpacity = 0.6;
  int _colorIndex = 0;
  bool _positionTop = false;
  bool _applied = false;

  static const _colors = [
    ('White', Colors.white),
    ('Yellow', Colors.yellow),
    ('Cyan', Colors.cyan),
    ('Green', Colors.green),
    ('Pink', Colors.pink),
    ('Orange', Colors.orange),
  ];

  void _applyStyle() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            'Subtitle style applied: ${_colors[_colorIndex].$1}, ${_fontSize.round()}px'),
        duration: const Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Subtitle Style',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _fontSizeSlider(),
          const SizedBox(height: AppSpacing.md),
          _bgOpacitySlider(),
          const SizedBox(height: AppSpacing.lg),
          _colorPicker(),
          const SizedBox(height: AppSpacing.lg),
          _positionToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _tipsCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.subtitles, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Subtitle Style',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Customize how subtitles appear on your TV screen',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _previewCard() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(Icons.play_circle_outline,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: _positionTop ? 12 : null,
              bottom: _positionTop ? null : 12,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: _bgOpacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'The quick brown fox jumps over the lazy dog',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _colors[_colorIndex].$2,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PREVIEW',
                    style: gfont(AppType.bodySm,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        size: 8)),
              ),
            ),
          ],
        ),
      );

  Widget _fontSizeSlider() => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Font Size',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('${_fontSize.round()}px',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600,
                          size: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor:
                    hex(AppColors.primary).withValues(alpha: 0.15),
                thumbColor: hex(AppColors.primary),
                trackHeight: 4,
              ),
              child: Slider(
                value: _fontSize,
                min: 10,
                max: 32,
                divisions: 22,
                onChanged: (v) {
                  setState(() => _fontSize = v);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10px',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Text('32px',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _bgOpacitySlider() => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Background Opacity',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('${(_bgOpacity * 100).round()}%',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600,
                          size: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor:
                    hex(AppColors.primary).withValues(alpha: 0.15),
                thumbColor: hex(AppColors.primary),
                trackHeight: 4,
              ),
              child: Slider(
                value: _bgOpacity,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (v) {
                  setState(() => _bgOpacity = v);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Text('100%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _colorPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text Color',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_colors.length, (i) {
              final c = _colors[i];
              final selected = _colorIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _colorIndex = i);
                  HapticFeedback.selectionClick();
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.$2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? hex(AppColors.primary)
                              : hex(AppColors.outlineVariant)
                                  .withValues(alpha: 0.3),
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: c.$2.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.black87)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(c.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 9)),
                  ],
                ),
              );
            }),
          ),
        ],
      );

  Widget _positionToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Position',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 12)),
                  const SizedBox(height: 2),
                  Text(_positionTop ? 'Top of screen' : 'Bottom of screen',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _positionTop = !_positionTop);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                      color: hex(AppColors.primary).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _positionTop
                          ? Icons.vertical_align_top
                          : Icons.vertical_align_bottom,
                      size: 16,
                      color: hex(AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(_positionTop ? 'Top' : 'Bottom',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.primary),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _applyButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _applied ? null : _applyStyle,
          icon: _applied
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(_applied ? 'Applied' : 'Apply Style',
              style: gfont(AppType.bodyMd,
                  color: Colors.white, weight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: hex(AppColors.primary),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        ),
      );

  Widget _tipsCard() => Container(
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
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Text('Tips',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            _tipRow('Yellow text with black background is most readable'),
            _tipRow('Larger fonts help when viewing from a distance'),
            _tipRow('Some apps may override these subtitle settings'),
          ],
        ),
      );

  Widget _tipRow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('  •  ',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            Expanded(
              child: Text(text,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
            ),
          ],
        ),
      );
}
