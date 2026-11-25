import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class MotionControlScreen extends StatefulWidget {
  const MotionControlScreen({super.key});

  @override
  State<MotionControlScreen> createState() => _MotionControlScreenState();
}

class _MotionControlScreenState extends State<MotionControlScreen> {
  bool _enabled = false;
  double _sensitivity = 0.5;
  String _tiltAction = 'navigate';
  String _shakeAction = 'mute';
  String _flipAction = 'power';
  bool _hapticFeedback = true;
  bool _loading = true;

  static const _tiltActions = <(String, String, IconData)>[
    ('navigate', 'D-pad Navigation', Icons.gamepad),
    ('volume', 'Volume Control', Icons.volume_up),
    ('channel', 'Channel Surf', Icons.swap_vert),
  ];

  static const _gestureActions = <(String, String, IconData)>[
    ('mute', 'Mute', Icons.volume_off),
    ('power', 'Power', Icons.power_settings_new),
    ('play', 'Play/Pause', Icons.play_arrow),
    ('home', 'Home', Icons.home),
    ('back', 'Back', Icons.arrow_back),
    ('input', 'Input Switch', Icons.input),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/motion_control.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? false;
        _sensitivity = (j['sensitivity'] as num?)?.toDouble() ?? 0.5;
        _tiltAction = j['tiltAction'] as String? ?? 'navigate';
        _shakeAction = j['shakeAction'] as String? ?? 'mute';
        _flipAction = j['flipAction'] as String? ?? 'power';
        _hapticFeedback = j['hapticFeedback'] as bool? ?? true;
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
      'sensitivity': _sensitivity,
      'tiltAction': _tiltAction,
      'shakeAction': _shakeAction,
      'flipAction': _flipAction,
      'hapticFeedback': _hapticFeedback,
    }));
  }

  void _testMotion(String action) {
    final c = RemoteScope.of(context);
    final key = switch (action) {
      'mute' => core.Key.mute,
      'power' => core.Key.power,
      'play' => core.Key.play,
      'home' => core.Key.home,
      'back' => core.Key.back,
      'input' => core.Key.input,
      _ => core.Key.ok,
    };
    c.key(key);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Sent: $action'),
          duration: const Duration(seconds: 1),
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
        title: Text('Motion Control',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _masterToggle(),
          const SizedBox(height: AppSpacing.lg),
          _sensitivitySection(),
          const SizedBox(height: AppSpacing.lg),
          _tiltSection(),
          const SizedBox(height: AppSpacing.lg),
          _gestureSection('Shake Action', Icons.vibration, _shakeAction, (v) {
            setState(() => _shakeAction = v);
            _save();
          }),
          const SizedBox(height: AppSpacing.lg),
          _gestureSection('Flip Face-Down', Icons.flip, _flipAction, (v) {
            setState(() => _flipAction = v);
            _save();
          }),
          const SizedBox(height: AppSpacing.lg),
          _optionsSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _masterToggle() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() => _enabled = !_enabled);
      _save();
    },
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: panel(
        fill: _enabled ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
        radius: AppRadii.lg,
        borderOpacity: _enabled ? 0.3 : 0.15,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(_enabled ? AppColors.primary : AppColors.outline).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.motion_photos_on,
                size: 24, color: hex(_enabled ? AppColors.primary : AppColors.outline)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Motion Control',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                Text(_enabled ? 'Active — tilt and shake to control' : 'Tap to enable',
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

  Widget _sensitivitySection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sensitivity',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Low', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
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
                  value: _sensitivity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (v) {
                    setState(() => _sensitivity = v);
                    _save();
                  },
                ),
              ),
            ),
            Text('High', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ],
        ),
      ],
    ),
  );

  Widget _tiltSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tilt Action',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._tiltActions.map((a) {
          final active = _tiltAction == a.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () {
                setState(() => _tiltAction = a.$1);
                _save();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: active
                      ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(a.$3, size: 16, color: hex(active ? AppColors.primary : AppColors.outline)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(a.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400)),
                    ),
                    if (active) Icon(Icons.check, size: 16, color: hex(AppColors.primary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );

  Widget _gestureSection(String title, IconData titleIcon, String current, ValueChanged<String> onChanged) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, size: 16, color: hex(AppColors.outline)),
                const SizedBox(width: 8),
                Text(title,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _testMotion(current),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text('Test',
                        style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _gestureActions.map((a) {
                final active = current == a.$1;
                return GestureDetector(
                  onTap: () => onChanged(a.$1),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.$3, size: 12, color: hex(active ? AppColors.primary : AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(a.$2,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _optionsSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.vibration, 'Haptic Feedback', _hapticFeedback, (v) {
          setState(() => _hapticFeedback = v);
          _save();
        }),
      ],
    ),
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
            'Control your TV by tilting and shaking your phone. Requires accelerometer and gyroscope sensors. No data leaves the device.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
