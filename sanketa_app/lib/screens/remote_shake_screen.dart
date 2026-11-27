import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RemoteShakeScreen extends StatefulWidget {
  const RemoteShakeScreen({super.key});

  @override
  State<RemoteShakeScreen> createState() => _RemoteShakeScreenState();
}

class _RemoteShakeScreenState extends State<RemoteShakeScreen> {
  bool _enabled = true;
  bool _loading = true;
  int _shakeCount = 0;
  int _actionIdx = 0;
  double _sensitivity = 60;

  static const _actions = <(String, IconData, int, core.Key)>[
    ('Mute', Icons.volume_off, AppColors.primary, core.Key.mute),
    ('Power', Icons.power_settings_new, AppColors.error, core.Key.power),
    ('Play/Pause', Icons.play_arrow, AppColors.signalEmerald, core.Key.ok),
    ('Home', Icons.home, AppColors.alertAmber, core.Key.home),
    ('Back', Icons.arrow_back, AppColors.secondary, core.Key.back),
    ('Menu', Icons.menu, AppColors.tertiary, core.Key.menu),
  ];

  static const _patterns = <(String, IconData, int, String)>[
    ('Single Shake', Icons.vibration, AppColors.primary, '1 quick shake'),
    ('Double Shake', Icons.edgesensor_high, AppColors.signalEmerald, '2 rapid shakes'),
    ('Twist', Icons.rotate_right, AppColors.alertAmber, 'Rotate wrist'),
    ('Chop', Icons.swipe_down, AppColors.secondary, 'Quick chop down'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_shake.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? true;
        _actionIdx = j['actionIdx'] as int? ?? 0;
        _sensitivity = (j['sensitivity'] as num?)?.toDouble() ?? 60;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'actionIdx': _actionIdx,
      'sensitivity': _sensitivity,
    }));
  }

  void _simulateShake() {
    if (!_enabled) return;
    final action = _actions[_actionIdx];
    final rc = RemoteScope.of(context);
    rc.key(action.$4);
    setState(() => _shakeCount++);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Shake → ${action.$1}'),
        duration: const Duration(seconds: 1),
      ));
  }

  void _toggleEnabled() {
    setState(() => _enabled = !_enabled);
    HapticFeedback.selectionClick();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Shake Control',
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
                const SizedBox(height: AppSpacing.md),
                _enableToggle(),
                const SizedBox(height: AppSpacing.md),
                _shakeButton(),
                const SizedBox(height: AppSpacing.md),
                Text('Shake Action',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                _actionGrid(),
                const SizedBox(height: AppSpacing.md),
                _sensitivitySlider(),
                const SizedBox(height: AppSpacing.md),
                _statsRow(),
                const SizedBox(height: AppSpacing.lg),
                Text('Shake Patterns',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                ..._patterns.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _patternCard(p),
                    )),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.vibration, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Shake to Control',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Shake your phone to trigger TV actions',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _enableToggle() => GestureDetector(
        onTap: _toggleEnabled,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_enabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.vibration,
                  size: 22,
                  color: hex(
                      _enabled ? AppColors.signalEmerald : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Shake Detection',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_enabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _shakeButton() => GestureDetector(
        onTap: _simulateShake,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.alertAmber
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_enabled
                      ? AppColors.alertAmber
                      : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.25 : 0.2),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_android,
                    size: 32,
                    color: hex(
                        _enabled ? AppColors.alertAmber : AppColors.outline)),
                const SizedBox(height: 4),
                Text(_enabled ? 'Tap to Simulate Shake' : 'Disabled',
                    style: gfont(AppType.bodySm,
                        color: hex(
                            _enabled ? AppColors.alertAmber : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
          ),
        ),
      );

  Widget _actionGrid() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.2,
        children: _actions.asMap().entries.map((e) {
          final active = e.key == _actionIdx;
          return GestureDetector(
            onTap: () {
              setState(() => _actionIdx = e.key);
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

  Widget _sensitivitySlider() => Container(
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
                Text('Sensitivity',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_sensitivity.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _sensitivity,
              min: 10,
              max: 100,
              activeColor: hex(AppColors.alertAmber),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) {
                setState(() => _sensitivity = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Shakes', '$_shakeCount', AppColors.alertAmber)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Action', _actions[_actionIdx].$1, AppColors.primary)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 18, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _patternCard((String, IconData, int, String) p) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(p.$3).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(p.$3).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(p.$2, size: 20, color: hex(p.$3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(p.$4,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
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
                'Shake phone to trigger TV actions. Choose action, '
                'adjust sensitivity. Tap button to test. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
