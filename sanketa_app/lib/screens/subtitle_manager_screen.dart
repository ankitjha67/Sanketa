import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class SubtitleManagerScreen extends StatefulWidget {
  const SubtitleManagerScreen({super.key});

  @override
  State<SubtitleManagerScreen> createState() => _SubtitleManagerScreenState();
}

class _SubtitleManagerScreenState extends State<SubtitleManagerScreen> {
  bool _enabled = false;
  String _language = 'English';
  String _size = 'Medium';
  String _style = 'Default';
  String _position = 'Bottom';
  double _opacity = 0.8;
  bool _background = true;
  bool _loading = true;

  static const _languages = [
    'English', 'Spanish', 'French', 'German', 'Portuguese',
    'Italian', 'Japanese', 'Korean', 'Chinese', 'Hindi',
    'Arabic', 'Russian', 'Dutch', 'Swedish', 'Thai',
  ];

  static const _sizes = ['Small', 'Medium', 'Large', 'Extra Large'];
  static const _styles = ['Default', 'Monospaced', 'Serif', 'Casual', 'Cursive'];
  static const _positions = ['Top', 'Bottom'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/subtitle_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? false;
        _language = j['language'] as String? ?? 'English';
        _size = j['size'] as String? ?? 'Medium';
        _style = j['style'] as String? ?? 'Default';
        _position = j['position'] as String? ?? 'Bottom';
        _opacity = (j['opacity'] as num?)?.toDouble() ?? 0.8;
        _background = j['background'] as bool? ?? true;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'language': _language,
      'size': _size,
      'style': _style,
      'position': _position,
      'opacity': _opacity,
      'background': _background,
    }));
  }

  void _applySettings() {
    final c = RemoteScope.of(context);
    c.key(core.Key.menu);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Opening TV subtitle settings'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
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
        title: Text('Subtitles',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _masterToggle(),
          const SizedBox(height: AppSpacing.lg),
          _languageSection(),
          const SizedBox(height: AppSpacing.lg),
          _appearanceSection(),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Center(
            child: Icon(Icons.tv, size: 32, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          alignment: _position == 'Top' ? Alignment.topCenter : Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _background
                  ? Colors.black.withValues(alpha: _opacity)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _enabled ? 'Sample subtitle text' : 'Subtitles off',
              style: TextStyle(
                color: _enabled
                    ? Colors.white.withValues(alpha: _opacity)
                    : Colors.grey,
                fontSize: _sizeToFontSize(),
                fontFamily: _styleToFamily(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  double _sizeToFontSize() => switch (_size) {
    'Small' => 11,
    'Medium' => 14,
    'Large' => 17,
    'Extra Large' => 20,
    _ => 14,
  };

  String? _styleToFamily() => switch (_style) {
    'Monospaced' => 'monospace',
    'Serif' => 'serif',
    'Casual' => 'sans-serif',
    _ => null,
  };

  Widget _masterToggle() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() => _enabled = !_enabled);
      _save();
    },
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
      child: Row(
        children: [
          Icon(Icons.subtitles,
              size: 20, color: hex(_enabled ? AppColors.primary : AppColors.outline)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subtitles / Closed Captions',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                Text(_enabled ? 'On' : 'Off',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 24,
            decoration: BoxDecoration(
              color: hex(_enabled ? AppColors.primary : AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: _enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hex(_enabled ? AppColors.onPrimary : AppColors.outline),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _languageSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _languages.map((lang) {
            final active = _language == lang;
            return GestureDetector(
              onTap: () {
                setState(() => _language = lang);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.6 : 0.2),
                  ),
                ),
                child: Text(lang,
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 11)),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _appearanceSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _optionRow('Size', _sizes, _size, (v) {
          setState(() => _size = v);
          _save();
        }),
        const SizedBox(height: 10),
        _optionRow('Style', _styles, _style, (v) {
          setState(() => _style = v);
          _save();
        }),
        const SizedBox(height: 10),
        _optionRow('Position', _positions, _position, (v) {
          setState(() => _position = v);
          _save();
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.opacity, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            SizedBox(width: 56, child: Text('Opacity', style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11))),
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
                  value: _opacity,
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  onChanged: (v) {
                    setState(() => _opacity = v);
                    _save();
                  },
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text('${(_opacity * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 10)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _toggleRow(Icons.format_color_fill, 'Background box', _background, (v) {
          setState(() => _background = v);
          _save();
        }),
      ],
    ),
  );

  Widget _optionRow(String label, List<String> options, String value, ValueChanged<String> onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: options.map((opt) {
              final active = value == opt;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: active
                        ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(opt,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)))),
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

  Widget _applyButton() => GestureDetector(
    onTap: _applySettings,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subtitles, size: 16, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Open TV Subtitle Settings',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
        ],
      ),
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
            'Subtitle preferences are saved locally for quick recall. Use "Open TV Subtitle Settings" to navigate your TV\'s native caption menu.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
