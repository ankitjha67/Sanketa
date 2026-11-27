import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class VibrateProfileScreen extends StatefulWidget {
  const VibrateProfileScreen({super.key});

  @override
  State<VibrateProfileScreen> createState() => _VibrateProfileScreenState();
}

class _VibrateProfileScreenState extends State<VibrateProfileScreen> {
  bool _loading = true;
  bool _enabled = true;

  static const _patterns = <(String, IconData)>[
    ('None', Icons.do_not_disturb),
    ('Light', Icons.spa),
    ('Medium', Icons.touch_app),
    ('Strong', Icons.vibration),
    ('Double', Icons.ads_click),
    ('Pulse', Icons.waves),
  ];

  static const _events = <String>['Key Press', 'Volume', 'Power'];

  // Map event name -> pattern index
  final Map<String, int> _eventPatterns = {};
  int _globalPattern = 2; // Medium default

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/vibrate_profiles.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? true;
        _globalPattern = j['globalPattern'] as int? ?? 2;
        final ep = j['eventPatterns'] as Map<String, dynamic>? ?? {};
        for (final e in _events) {
          _eventPatterns[e] = ep[e] as int? ?? _globalPattern;
        }
      } else {
        for (final e in _events) {
          _eventPatterns[e] = _globalPattern;
        }
      }
    } catch (_) {
      for (final e in _events) {
        _eventPatterns[e] = _globalPattern;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'globalPattern': _globalPattern,
      'eventPatterns': _eventPatterns,
    }));
  }

  void _toggleEnabled() {
    setState(() => _enabled = !_enabled);
    HapticFeedback.mediumImpact();
    _save();
  }

  void _selectGlobal(int idx) {
    setState(() => _globalPattern = idx);
    _fireHaptic(idx);
    _save();
  }

  void _selectEventPattern(String event, int idx) {
    setState(() => _eventPatterns[event] = idx);
    _fireHaptic(idx);
    _save();
  }

  void _fireHaptic(int idx) {
    switch (idx) {
      case 0:
        break;
      case 1:
        HapticFeedback.lightImpact();
      case 2:
        HapticFeedback.mediumImpact();
      case 3:
        HapticFeedback.heavyImpact();
      case 4:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 80), () {
          HapticFeedback.lightImpact();
        });
      case 5:
        HapticFeedback.selectionClick();
        Future.delayed(const Duration(milliseconds: 60), () {
          HapticFeedback.selectionClick();
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.selectionClick();
        });
    }
  }

  void _testCurrent() {
    _fireHaptic(_globalPattern);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Haptic: ${_patterns[_globalPattern].$1}'),
        duration: const Duration(seconds: 1),
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
        title: Text('Vibrate Profiles',
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
                const SizedBox(height: AppSpacing.lg),
                _enableToggle(),
                const SizedBox(height: AppSpacing.lg),
                Text('Default Pattern',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const SizedBox(height: 8),
                _patternGrid(),
                const SizedBox(height: AppSpacing.md),
                _testButton(),
                const SizedBox(height: AppSpacing.lg),
                Text('Per-Event Patterns',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._events.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _eventCard(e),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.vibration, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Haptic Profiles',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Customise vibration feedback for different remote events',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _enableToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.phonelink_ring,
                size: 20,
                color:
                    hex(_enabled ? AppColors.secondary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Haptic Feedback',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(_enabled ? 'Vibration active' : 'Vibration off',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _toggleEnabled,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_enabled
                          ? AppColors.secondary
                          : AppColors.outlineVariant)
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _enabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hex(
                          _enabled ? AppColors.secondary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _patternGrid() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _patterns.asMap().entries.map((e) {
          final active = e.key == _globalPattern;
          return GestureDetector(
            onTap: () => _selectGlobal(e.key),
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(active
                        ? AppColors.secondary
                        : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.15 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active
                          ? AppColors.secondary
                          : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.4 : 0.15),
                ),
              ),
              child: Column(
                children: [
                  Icon(e.value.$2,
                      size: 22,
                      color: hex(active
                          ? AppColors.secondary
                          : AppColors.outline)),
                  const SizedBox(height: 4),
                  Text(e.value.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _testButton() => GestureDetector(
        onTap: _testCurrent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.secondary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow,
                  size: 18, color: hex(AppColors.secondary)),
              const SizedBox(width: 6),
              Text('Test Pattern',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.secondary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _eventCard(String event) {
    final patIdx = _eventPatterns[event] ?? _globalPattern;
    return Container(
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
              Icon(
                event == 'Key Press'
                    ? Icons.touch_app
                    : event == 'Volume'
                        ? Icons.volume_up
                        : Icons.power_settings_new,
                size: 18,
                color: hex(AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(event,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600,
                      size: 13)),
              const Spacer(),
              GestureDetector(
                onTap: () => _fireHaptic(patIdx),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.signalEmerald)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text('Test',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.signalEmerald),
                          weight: FontWeight.w600,
                          size: 9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _patterns.asMap().entries.map((e) {
                final active = e.key == patIdx;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectEventPattern(event, e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: hex(active
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh)
                            .withValues(alpha: active ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.15),
                        ),
                      ),
                      child: Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.primary
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
                'Choose a haptic pattern for each type of remote event. '
                'All feedback runs locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
