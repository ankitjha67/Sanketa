import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _FloatingConfig {
  _FloatingConfig({
    this.enabled = false,
    this.opacity = 0.85,
    this.size = 1.0,
    this.position = 'bottom-right',
    this.buttons = const ['power', 'volUp', 'volDown', 'mute', 'ok'],
    this.autoHideSeconds = 0,
    this.theme = 'dark',
  });

  factory _FloatingConfig.fromJson(Map<String, dynamic> j) => _FloatingConfig(
    enabled: j['enabled'] as bool? ?? false,
    opacity: (j['opacity'] as num?)?.toDouble() ?? 0.85,
    size: (j['size'] as num?)?.toDouble() ?? 1.0,
    position: j['position'] as String? ?? 'bottom-right',
    buttons: (j['buttons'] as List?)?.cast<String>() ?? ['power', 'volUp', 'volDown', 'mute', 'ok'],
    autoHideSeconds: j['autoHideSeconds'] as int? ?? 0,
    theme: j['theme'] as String? ?? 'dark',
  );

  bool enabled;
  double opacity;
  double size;
  String position;
  List<String> buttons;
  int autoHideSeconds;
  String theme;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'opacity': opacity,
    'size': size,
    'position': position,
    'buttons': buttons,
    'autoHideSeconds': autoHideSeconds,
    'theme': theme,
  };
}

class FloatingRemoteScreen extends StatefulWidget {
  const FloatingRemoteScreen({super.key});

  @override
  State<FloatingRemoteScreen> createState() => _FloatingRemoteScreenState();
}

class _FloatingRemoteScreenState extends State<FloatingRemoteScreen> {
  var _config = _FloatingConfig();
  bool _loading = true;
  final bool _hasOverlayPermission = false;

  static const _positions = ['top-left', 'top-right', 'bottom-left', 'bottom-right'];
  static const _themes = ['dark', 'light', 'glass'];
  static const _allButtons = {
    'power': ('Power', Icons.power_settings_new),
    'volUp': ('Vol +', Icons.volume_up),
    'volDown': ('Vol -', Icons.volume_down),
    'mute': ('Mute', Icons.volume_off),
    'ok': ('OK', Icons.radio_button_checked),
    'back': ('Back', Icons.arrow_back),
    'home': ('Home', Icons.home),
    'up': ('Up', Icons.arrow_upward),
    'down': ('Down', Icons.arrow_downward),
    'left': ('Left', Icons.arrow_back),
    'right': ('Right', Icons.arrow_forward),
    'play': ('Play', Icons.play_arrow),
    'pause': ('Pause', Icons.pause),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/floating_remote.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        _config = _FloatingConfig.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_config.toJson()));
  }

  void _toggleButton(String key) {
    setState(() {
      if (_config.buttons.contains(key)) {
        if (_config.buttons.length > 2) {
          _config.buttons = List.from(_config.buttons)..remove(key);
        }
      } else {
        if (_config.buttons.length < 8) {
          _config.buttons = List.from(_config.buttons)..add(key);
        }
      }
    });
    _save();
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
        title: Text('Floating Remote',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewSection(),
          const SizedBox(height: AppSpacing.md),
          _enableCard(),
          const SizedBox(height: AppSpacing.md),
          _positionPicker(),
          const SizedBox(height: AppSpacing.md),
          _appearanceCard(),
          const SizedBox(height: AppSpacing.md),
          _buttonPicker(),
          const SizedBox(height: AppSpacing.md),
          _behaviourCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewSection() => Container(
    height: 200,
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, size: 40, color: hex(AppColors.outline).withValues(alpha: 0.2)),
              const SizedBox(height: 4),
              Text('Other app content',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.3), size: 10)),
            ],
          ),
        ),
        Positioned(
          right: _config.position.contains('right') ? 12 : null,
          left: _config.position.contains('left') ? 12 : null,
          top: _config.position.contains('top') ? 12 : null,
          bottom: _config.position.contains('bottom') ? 12 : null,
          child: Opacity(
            opacity: _config.opacity,
            child: Transform.scale(
              scale: _config.size * 0.6,
              child: _miniRemotePreview(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _miniRemotePreview() {
    final bgColor = _config.theme == 'light'
        ? Colors.white.withValues(alpha: 0.95)
        : _config.theme == 'glass'
            ? hex(AppColors.surfaceContainerHigh).withValues(alpha: 0.7)
            : hex(AppColors.surfaceContainerHigh).withValues(alpha: 0.95);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _config.buttons.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniButton(_config.buttons[i]),
                  if (i + 1 < _config.buttons.length) ...[
                    const SizedBox(width: 4),
                    _miniButton(_config.buttons[i + 1]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniButton(String key) {
    final entry = _allButtons[key];
    if (entry == null) return const SizedBox.shrink();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(entry.$2, size: 14, color: hex(AppColors.primary)),
    );
  }

  Widget _enableCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.picture_in_picture_alt, size: 20, color: hex(AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable Floating Remote',
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                  Text('Shows a mini remote over other apps',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            Switch(
              value: _config.enabled,
              onChanged: (v) {
                setState(() => _config.enabled = v);
                _save();
              },
              activeThumbColor: hex(AppColors.primary),
              inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
          ],
        ),
        if (!_hasOverlayPermission && _config.enabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 14, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Overlay permission required. Tap to open settings.',
                      style: gfont(AppType.bodySm, color: hex(AppColors.alertAmber), size: 11)),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _positionPicker() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Position',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: _positions.map((p) {
            final sel = p == _config.position;
            final label = p.replaceAll('-', '\n');
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _config.position = p);
                  _save();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(sel ? AppColors.primary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: sel ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: sel ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4)) : null,
                  ),
                  child: Center(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(sel ? AppColors.primary : AppColors.outline),
                            size: 9,
                            weight: FontWeight.w500)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _appearanceCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _sliderRow('Opacity', _config.opacity, 0.3, 1.0,
            (v) { setState(() => _config.opacity = v); _save(); },
            '${(_config.opacity * 100).round()}%'),
        const SizedBox(height: 6),
        _sliderRow('Size', _config.size, 0.5, 1.5,
            (v) { setState(() => _config.size = v); _save(); },
            '${(_config.size * 100).round()}%'),
        const SizedBox(height: 10),
        Row(
          children: _themes.map((t) {
            final sel = t == _config.theme;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _config.theme = t);
                  _save();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(sel ? AppColors.primary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: sel ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: sel ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4)) : null,
                  ),
                  child: Center(
                    child: Text(t[0].toUpperCase() + t.substring(1),
                        style: gfont(AppType.bodySm,
                            color: hex(sel ? AppColors.primary : AppColors.outline),
                            size: 10,
                            weight: FontWeight.w600)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _sliderRow(String label, double val, double min, double max,
      ValueChanged<double> onChanged, String display) =>
      Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                thumbColor: hex(AppColors.primary),
                overlayColor: hex(AppColors.primary).withValues(alpha: 0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(value: val, min: min, max: max, onChanged: onChanged),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(display,
                textAlign: TextAlign.right,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 10)),
          ),
        ],
      );

  Widget _buttonPicker() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Buttons',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_config.buttons.length}/8',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _allButtons.entries.map((e) {
            final sel = _config.buttons.contains(e.key);
            return GestureDetector(
              onTap: () => _toggleButton(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(sel ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: sel ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: sel ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4)) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.$2,
                        size: 12,
                        color: hex(sel ? AppColors.primary : AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(e.value.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(sel ? AppColors.primary : AppColors.outline),
                            size: 10,
                            weight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _behaviourCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Behaviour',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _optionRow('Auto-hide after', _config.autoHideSeconds == 0 ? 'Never' : '${_config.autoHideSeconds}s', () {
          setState(() {
            _config.autoHideSeconds = switch (_config.autoHideSeconds) {
              0 => 5,
              5 => 10,
              10 => 30,
              _ => 0,
            };
          });
          _save();
        }),
      ],
    ),
  );

  Widget _optionRow(String label, String value, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Text(label,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13)),
        const Spacer(),
        Text(value,
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w600)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, size: 14, color: hex(AppColors.outline)),
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
            'The floating remote stays visible over other apps. Drag to reposition. Requires the "Display over other apps" Android permission. All controls run locally.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
