import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class CaptionStyleScreen extends StatefulWidget {
  const CaptionStyleScreen({super.key});

  @override
  State<CaptionStyleScreen> createState() => _CaptionStyleScreenState();
}

class _CaptionStyleScreenState extends State<CaptionStyleScreen> {
  int _fontIndex = 0;
  int _sizeIndex = 1;
  int _bgIndex = 0;
  int _colorIndex = 0;
  bool _bold = false;
  double _opacity = 0.7;

  static const _fonts = ['System', 'Serif', 'Mono', 'Rounded', 'Condensed'];
  static const _fontFamilies = [null, 'serif', 'monospace', null, null];

  static const _sizes = ['Small', 'Medium', 'Large', 'Extra Large'];
  static const _fontSizes = [12.0, 16.0, 20.0, 26.0];

  static const _bgColors = [
    ('Black', 0xFF000000),
    ('Dark Gray', 0xFF333333),
    ('Navy', 0xFF1A237E),
    ('Dark Green', 0xFF1B5E20),
    ('Transparent', 0x00000000),
  ];

  static const _textColors = [
    ('White', 0xFFFFFFFF),
    ('Yellow', 0xFFFFEB3B),
    ('Cyan', 0xFF00BCD4),
    ('Green', 0xFF4CAF50),
    ('Pink', 0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Caption Style',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _resetDefaults,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.restart_alt, size: 20, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _preview(),
          const SizedBox(height: AppSpacing.lg),
          _sectionLabel('Font'),
          const SizedBox(height: 6),
          _chipRow(_fonts, _fontIndex, (i) => setState(() => _fontIndex = i)),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel('Size'),
          const SizedBox(height: 6),
          _chipRow(_sizes, _sizeIndex, (i) => setState(() => _sizeIndex = i)),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel('Text Color'),
          const SizedBox(height: 6),
          _colorRow(_textColors.map((c) => c.$2).toList(), _colorIndex,
              (i) => setState(() => _colorIndex = i)),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel('Background'),
          const SizedBox(height: 6),
          _colorRow(_bgColors.map((c) => c.$2).toList(), _bgIndex,
              (i) => setState(() => _bgIndex = i)),
          const SizedBox(height: AppSpacing.md),
          _opacitySlider(),
          const SizedBox(height: AppSpacing.md),
          _boldToggle(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _preview() {
    final bgColor = Color(_bgColors[_bgIndex].$2).withValues(alpha: _opacity);
    final textColor = Color(_textColors[_colorIndex].$2);
    final fontSize = _fontSizes[_sizeIndex];
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        image: const DecorationImage(
          image: AssetImage('assets/images/icon.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'The quick brown fox jumps over the lazy dog.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: _bold ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: _fontFamilies[_fontIndex],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.surface).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('Preview',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: gfont(AppType.bodyMd,
          color: hex(AppColors.onSurface),
          weight: FontWeight.w600,
          size: 13));

  Widget _chipRow(List<String> items, int selected, ValueChanged<int> onTap) =>
      SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == selected;
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Center(
                  child: Text(items[i],
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          },
        ),
      );

  Widget _colorRow(List<int> colors, int selected, ValueChanged<int> onTap) =>
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: colors.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == selected;
            final c = Color(colors[i]);
            return GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? hex(AppColors.primary)
                        : hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                    width: active ? 3 : 1,
                  ),
                ),
                child: colors[i] == 0x00000000
                    ? Icon(Icons.block, size: 16, color: hex(AppColors.outline))
                    : null,
              ),
            );
          },
        ),
      );

  Widget _opacitySlider() => Container(
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
                Text('${(_opacity * 100).round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            Slider(
              value: _opacity,
              min: 0,
              max: 1,
              divisions: 10,
              activeColor: hex(AppColors.primary),
              inactiveColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _opacity = v),
            ),
          ],
        ),
      );

  Widget _boldToggle() => GestureDetector(
        onTap: () => setState(() => _bold = !_bold),
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
              Icon(Icons.format_bold, size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Bold Text',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_bold ? AppColors.primary : AppColors.outlineVariant)
                      .withValues(alpha: _bold ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _bold ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_bold ? AppColors.primary : AppColors.outline),
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
        onTap: () {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text('Caption style applied'),
              duration: Duration(seconds: 2),
            ));
        },
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
              Icon(Icons.check, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Style',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  void _resetDefaults() {
    setState(() {
      _fontIndex = 0;
      _sizeIndex = 1;
      _bgIndex = 0;
      _colorIndex = 0;
      _bold = false;
      _opacity = 0.7;
    });
  }

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
                'Customize how subtitles and closed captions appear on your TV. Adjust font, size, color, and background to match your viewing preference.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
