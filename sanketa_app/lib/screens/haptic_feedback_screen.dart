import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class HapticFeedbackScreen extends StatefulWidget {
  const HapticFeedbackScreen({super.key});

  @override
  State<HapticFeedbackScreen> createState() => _HapticFeedbackScreenState();
}

class _HapticFeedbackScreenState extends State<HapticFeedbackScreen> {
  bool _enabled = true;
  int _intensityIndex = 1;
  final _patterns = <String, bool>{
    'D-pad navigation': true,
    'Volume change': true,
    'Button press': true,
    'Swipe gestures': false,
    'Long press': true,
    'Connection events': true,
  };

  static const _intensities = ['Light', 'Medium', 'Strong'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/haptic_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? true;
        _intensityIndex = j['intensity'] as int? ?? 1;
        final saved = j['patterns'] as Map<String, dynamic>?;
        if (saved != null) {
          for (final k in _patterns.keys) {
            if (saved.containsKey(k)) _patterns[k] = saved[k] as bool;
          }
        }
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'intensity': _intensityIndex,
      'patterns': _patterns,
    }));
  }

  void _testHaptic() {
    switch (_intensityIndex) {
      case 0:
        HapticFeedback.lightImpact();
      case 2:
        HapticFeedback.heavyImpact();
      default:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Haptic Feedback',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statusCard(),
          const SizedBox(height: AppSpacing.md),
          _masterToggle(),
          if (_enabled) ...[
            const SizedBox(height: AppSpacing.md),
            _intensitySelector(),
            const SizedBox(height: AppSpacing.md),
            _patternToggles(),
            const SizedBox(height: AppSpacing.md),
            _testButton(),
          ],
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_enabled ? AppColors.primary : AppColors.surfaceContainerLow).withValues(alpha: _enabled ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_enabled ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(
          _enabled ? Icons.vibration : Icons.do_not_disturb,
          size: 48,
          color: hex(_enabled ? AppColors.primary : AppColors.outline),
        ),
        const SizedBox(height: 8),
        Text(
          _enabled ? 'Haptics Active' : 'Haptics Off',
          style: gfont(AppType.bodyMd, color: hex(_enabled ? AppColors.primary : AppColors.onSurface), weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _enabled
              ? 'Intensity: ${_intensities[_intensityIndex]}'
              : 'No vibration feedback on remote actions',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
        ),
      ],
    ),
  );

  Widget _masterToggle() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.vibration, size: 20, color: hex(AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enable Haptic Feedback',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Vibrate on remote actions',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        Switch(
          value: _enabled,
          activeTrackColor: hex(AppColors.primary),
          onChanged: (v) {
            setState(() => _enabled = v);
            if (v) _testHaptic();
            _save();
          },
        ),
      ],
    ),
  );

  Widget _intensitySelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Intensity', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(_intensities.length, (i) {
            final active = i == _intensityIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _intensityIndex = i);
                    _testHaptic();
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                      child: Text(_intensities[i],
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              size: 12)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _patternToggles() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vibrate On', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._patterns.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(e.key,
                    style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 12)),
              ),
              SizedBox(
                height: 32,
                child: Switch(
                  value: e.value,
                  activeTrackColor: hex(AppColors.primary),
                  onChanged: (v) {
                    setState(() => _patterns[e.key] = v);
                    if (v) _testHaptic();
                    _save();
                  },
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );

  Widget _testButton() => GestureDetector(
    onTap: _testHaptic,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vibration, size: 18, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Test Vibration',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600, size: 13)),
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
            'Haptic feedback gives tactile confirmation when using the remote. Customize which actions vibrate and how strong the feedback feels.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
