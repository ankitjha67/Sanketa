import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AmbientLightScreen extends StatefulWidget {
  const AmbientLightScreen({super.key});

  @override
  State<AmbientLightScreen> createState() => _AmbientLightScreenState();
}

class _AmbientLightScreenState extends State<AmbientLightScreen> {
  bool _on = true;
  int _colorIndex = 0;
  int _modeIndex = 0;
  double _brightness = 0.7;

  static const _colors = <(String, int, int)>[
    ('White', 0xFFFFFFFF, AppColors.onSurface),
    ('Warm', 0xFFFFD54F, AppColors.alertAmber),
    ('Red', 0xFFEF5350, AppColors.error),
    ('Blue', 0xFF42A5F5, AppColors.primary),
    ('Green', 0xFF66BB6A, AppColors.signalEmerald),
    ('Purple', 0xFFAB47BC, AppColors.tertiary),
    ('Cyan', 0xFF26C6DA, AppColors.secondary),
    ('Orange', 0xFFFF7043, AppColors.alertAmber),
  ];

  static const _modes = <(String, IconData, String, int)>[
    ('Static', Icons.circle, 'Solid colour', AppColors.primary),
    ('Breathing', Icons.air, 'Fade in/out', AppColors.secondary),
    ('Rainbow', Icons.auto_awesome, 'Colour cycle', AppColors.tertiary),
    ('Music Sync', Icons.music_note, 'React to audio', AppColors.signalEmerald),
  ];

  void _apply() {
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    final mode = _modes[_modeIndex].$1;
    final color = _colors[_colorIndex].$1;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_on
            ? 'Ambient light: $mode ($color) at ${(_brightness * 100).round()}%'
            : 'Ambient light turned off'),
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
        title: Text('Ambient Light',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _toggleRow(),
          const SizedBox(height: AppSpacing.md),
          _colorPicker(),
          const SizedBox(height: AppSpacing.md),
          _brightnessSlider(),
          const SizedBox(height: AppSpacing.md),
          _modeSelector(),
          const SizedBox(height: AppSpacing.md),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 180,
              height: 110,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _on
                      ? Color(_colors[_colorIndex].$2)
                          .withValues(alpha: _brightness)
                      : hex(AppColors.outline).withValues(alpha: 0.3),
                  width: _on ? 4 : 2,
                ),
                boxShadow: _on
                    ? [
                        BoxShadow(
                          color: Color(_colors[_colorIndex].$2)
                              .withValues(alpha: _brightness * 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.tv,
                  size: 36,
                  color: hex(_on ? AppColors.onSurface : AppColors.outline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _on
                  ? '${_colors[_colorIndex].$1} • ${_modes[_modeIndex].$1}'
                  : 'Ambient light off',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _toggleRow() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hex(_on ? AppColors.signalEmerald : AppColors.surfaceContainerLow)
              .withValues(alpha: _on ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(_on ? AppColors.signalEmerald : AppColors.outlineVariant)
                .withValues(alpha: _on ? 0.3 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.light_mode,
                size: 20,
                color: hex(_on ? AppColors.signalEmerald : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Ambient Light',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _on = !_on);
              },
              child: Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: hex(_on ? AppColors.signalEmerald : AppColors.outline)
                      .withValues(alpha: _on ? 1 : 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surface),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _colorPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Colour',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_colors.length, (i) {
              final c = _colors[i];
              final active = _colorIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _colorIndex = i);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(c.$2).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? hex(AppColors.onSurface)
                          : Colors.transparent,
                      width: active ? 3 : 0,
                    ),
                  ),
                  child: active
                      ? const Icon(Icons.check, size: 18, color: Colors.black87)
                      : null,
                ),
              );
            }),
          ),
        ],
      );

  Widget _brightnessSlider() => Container(
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
                Text('Brightness',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const Spacer(),
                Text('${(_brightness * 100).round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                thumbColor: hex(AppColors.primary),
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _brightness,
                onChanged: (v) => setState(() => _brightness = v),
                min: 0.1,
                max: 1.0,
              ),
            ),
          ],
        ),
      );

  Widget _modeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mode',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.5,
            children: List.generate(_modes.length, (i) {
              final m = _modes[i];
              final active = _modeIndex == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _modeIndex = i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: hex(active ? m.$4 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: hex(active ? m.$4 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(m.$2,
                          size: 18,
                          color: hex(active ? m.$4 : AppColors.outline)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$1,
                                style: gfont(AppType.bodySm,
                                    color:
                                        hex(active ? m.$4 : AppColors.onSurface),
                                    weight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    size: 11)),
                            Text(m.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline), size: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
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
              Icon(Icons.check_circle,
                  size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Settings',
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
                'Control your TV ambient backlight or LED strip. Pick a colour, set brightness, and choose a lighting mode. Music Sync reacts to audio output from the TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
