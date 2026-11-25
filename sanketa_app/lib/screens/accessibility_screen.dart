import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _largeButtons = false;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _hapticFeedback = true;
  bool _screenReader = false;
  bool _boldText = false;
  double _buttonScale = 1.0;
  String _colorMode = 'Normal';
  bool _loading = true;

  static const _colorModes = ['Normal', 'Deuteranopia', 'Protanopia', 'Tritanopia'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/accessibility.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _largeButtons = j['largeButtons'] as bool? ?? false;
        _highContrast = j['highContrast'] as bool? ?? false;
        _reducedMotion = j['reducedMotion'] as bool? ?? false;
        _hapticFeedback = j['hapticFeedback'] as bool? ?? true;
        _screenReader = j['screenReader'] as bool? ?? false;
        _boldText = j['boldText'] as bool? ?? false;
        _buttonScale = (j['buttonScale'] as num?)?.toDouble() ?? 1.0;
        _colorMode = j['colorMode'] as String? ?? 'Normal';
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'largeButtons': _largeButtons,
      'highContrast': _highContrast,
      'reducedMotion': _reducedMotion,
      'hapticFeedback': _hapticFeedback,
      'screenReader': _screenReader,
      'boldText': _boldText,
      'buttonScale': _buttonScale,
      'colorMode': _colorMode,
    }));
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
        title: Text('Accessibility',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _displaySection(),
          const SizedBox(height: AppSpacing.lg),
          _interactionSection(),
          const SizedBox(height: AppSpacing.lg),
          _visionSection(),
          const SizedBox(height: AppSpacing.lg),
          _buttonSizeSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_highContrast ? AppColors.onSurface : AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(
        color: hex(_highContrast ? AppColors.onSurface : AppColors.outlineVariant)
            .withValues(alpha: _highContrast ? 1 : 0.15),
        width: _highContrast ? 2 : 1,
      ),
    ),
    child: Column(
      children: [
        Text('Preview',
            style: gfont(AppType.bodyMd,
                color: hex(_highContrast ? AppColors.surface : AppColors.onSurface),
                weight: _boldText ? FontWeight.w700 : FontWeight.w600,
                size: 14)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _previewButton(Icons.power_settings_new, 'Power'),
            const SizedBox(width: 8),
            _previewButton(Icons.volume_up, 'Volume'),
            const SizedBox(width: 8),
            _previewButton(Icons.home, 'Home'),
          ],
        ),
      ],
    ),
  );

  Widget _previewButton(IconData icon, String label) {
    final size = 48.0 * _buttonScale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hex(_highContrast ? AppColors.primary : AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: _highContrast
                ? Border.all(color: hex(AppColors.onPrimary), width: 2)
                : null,
          ),
          child: Icon(icon,
              size: 20 * _buttonScale,
              color: hex(_highContrast ? AppColors.onPrimary : AppColors.onSurface)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: gfont(AppType.bodySm,
                color: hex(_highContrast ? AppColors.surface : AppColors.onSurface),
                weight: _boldText ? FontWeight.w700 : FontWeight.w400,
                size: 10)),
      ],
    );
  }

  Widget _displaySection() => _section('Display', [
    _toggleRow(Icons.format_bold, 'Bold Text', 'Makes all text heavier for readability', _boldText, (v) {
      setState(() => _boldText = v);
      _save();
    }),
    const SizedBox(height: 8),
    _toggleRow(Icons.contrast, 'High Contrast', 'Increases contrast between elements', _highContrast, (v) {
      setState(() => _highContrast = v);
      _save();
    }),
  ]);

  Widget _interactionSection() => _section('Interaction', [
    _toggleRow(Icons.vibration, 'Haptic Feedback', 'Vibrate on button press', _hapticFeedback, (v) {
      setState(() => _hapticFeedback = v);
      _save();
    }),
    const SizedBox(height: 8),
    _toggleRow(Icons.animation, 'Reduced Motion', 'Minimise animations', _reducedMotion, (v) {
      setState(() => _reducedMotion = v);
      _save();
    }),
    const SizedBox(height: 8),
    _toggleRow(Icons.record_voice_over, 'Screen Reader Hints', 'Enhanced labels for TalkBack/VoiceOver', _screenReader, (v) {
      setState(() => _screenReader = v);
      _save();
    }),
    const SizedBox(height: 8),
    _toggleRow(Icons.open_with, 'Large Buttons', 'Increase touch target size', _largeButtons, (v) {
      setState(() {
        _largeButtons = v;
        _buttonScale = v ? 1.4 : 1.0;
      });
      _save();
    }),
  ]);

  Widget _visionSection() => _section('Colour Vision', [
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _colorModes.map((mode) {
        final active = _colorMode == mode;
        return GestureDetector(
          onTap: () {
            setState(() => _colorMode = mode);
            _save();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                  .withValues(alpha: active ? 0.25 : 1),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                    .withValues(alpha: active ? 0.6 : 0.2),
              ),
            ),
            child: Text(mode,
                style: gfont(AppType.bodySm,
                    color: hex(active ? AppColors.primary : AppColors.onSurface),
                    weight: active ? FontWeight.w600 : FontWeight.w400,
                    size: 11)),
          ),
        );
      }).toList(),
    ),
  ]);

  Widget _buttonSizeSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Button Scale',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('1x', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: hex(AppColors.primary),
                  inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                  thumbColor: hex(AppColors.primary),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _buttonScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  onChanged: (v) {
                    setState(() => _buttonScale = v);
                    _save();
                  },
                ),
              ),
            ),
            Text('1.6x', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
        Center(
          child: Text('${_buttonScale.toStringAsFixed(1)}x',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12, weight: FontWeight.w700)),
        ),
      ],
    ),
  );

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  Widget _toggleRow(IconData icon, String label, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
                  Text(subtitle, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: hex(value ? AppColors.primary : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hex(value ? AppColors.onPrimary : AppColors.outline),
                    shape: BoxShape.circle,
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
            'Adjust the remote app to suit your needs. These settings affect the app interface only, not the TV itself. All preferences are saved locally.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
