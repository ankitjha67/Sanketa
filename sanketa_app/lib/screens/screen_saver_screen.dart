import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenSaverScreen extends StatefulWidget {
  const ScreenSaverScreen({super.key});

  @override
  State<ScreenSaverScreen> createState() => _ScreenSaverScreenState();
}

class _ScreenSaverScreenState extends State<ScreenSaverScreen> {
  int _selectedStyle = 0;
  double _timeoutMin = 5;
  bool _previewing = false;

  static const _styles = [
    ('Clock', Icons.access_time, 'Large analog clock with date overlay'),
    ('Photos', Icons.photo_library, 'Slideshow of saved photos'),
    ('Bubbles', Icons.bubble_chart, 'Floating color bubbles animation'),
    ('Starfield', Icons.star, 'Drifting stars in deep space'),
    ('Blank', Icons.tv_off, 'Screen goes dark to save energy'),
  ];

  static const _styleColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.signalEmerald,
    AppColors.outline,
  ];

  void _applySettings() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            '${_styles[_selectedStyle].$1} screensaver set (${_timeoutMin.round()} min)'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _preview() {
    setState(() => _previewing = true);
    HapticFeedback.selectionClick();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _previewing = false);
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
        title: Text('Screen Saver',
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
          _styleSelector(),
          const SizedBox(height: AppSpacing.lg),
          _timeoutSlider(),
          const SizedBox(height: AppSpacing.lg),
          _previewButton(),
          const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.wallpaper, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Screen Saver',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Choose a screensaver style and set when it activates after idle',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _styleSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Style',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(_styles.length, (i) {
            final s = _styles[i];
            final selected = _selectedStyle == i;
            final c = _styleColors[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedStyle = i);
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? hex(c).withValues(alpha: 0.1)
                        : hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: selected
                          ? hex(c).withValues(alpha: 0.5)
                          : hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(s.$2,
                          size: 28,
                          color: selected
                              ? hex(c)
                              : hex(AppColors.outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 13)),
                            const SizedBox(height: 2),
                            Text(s.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline),
                                    size: 11)),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle,
                            size: 20, color: hex(c)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _timeoutSlider() => Container(
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
                Text('Activation Timeout',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.tertiary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('${_timeoutMin.round()} min',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.tertiary),
                          weight: FontWeight.w600,
                          size: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.tertiary),
                inactiveTrackColor:
                    hex(AppColors.tertiary).withValues(alpha: 0.15),
                thumbColor: hex(AppColors.tertiary),
                trackHeight: 4,
              ),
              child: Slider(
                value: _timeoutMin,
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (v) {
                  setState(() => _timeoutMin = v);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 min',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                Text('30 min',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _previewButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _previewing ? null : _preview,
          icon: _previewing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: hex(AppColors.tertiary),
                  ),
                )
              : Icon(Icons.play_arrow, color: hex(AppColors.tertiary)),
          label: Text(
            _previewing ? 'Previewing...' : 'Preview',
            style: gfont(AppType.bodyMd,
                color: hex(AppColors.tertiary), weight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: hex(AppColors.tertiary)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        ),
      );

  Widget _applyButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _applySettings,
          icon: const Icon(Icons.check, size: 18),
          label: Text('Apply Settings',
              style: gfont(AppType.bodyMd,
                  color: Colors.white, weight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: hex(AppColors.tertiary),
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
            _tipRow('Blank mode uses the least power'),
            _tipRow('Shorter timeouts protect OLED panels'),
            _tipRow('Press any key to exit the screensaver'),
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
