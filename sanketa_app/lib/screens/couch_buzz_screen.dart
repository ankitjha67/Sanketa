import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class CouchBuzzScreen extends StatefulWidget {
  const CouchBuzzScreen({super.key});

  @override
  State<CouchBuzzScreen> createState() => _CouchBuzzScreenState();
}

class _CouchBuzzScreenState extends State<CouchBuzzScreen> {
  bool _loading = true;
  bool _enabled = false;
  int _intensityIndex = 1;
  final _alerts = <_AlertType>[
    _AlertType(name: 'Show starts', icon: Icons.play_circle, enabled: true),
    _AlertType(name: 'Ad break ends', icon: Icons.skip_next, enabled: true),
    _AlertType(name: 'Score update', icon: Icons.sports, enabled: false),
    _AlertType(name: 'Recording done', icon: Icons.fiber_manual_record, enabled: false),
    _AlertType(name: 'Timer finished', icon: Icons.alarm, enabled: true),
    _AlertType(name: 'Volume change', icon: Icons.volume_up, enabled: false),
  ];

  static const _intensities = <(String, int)>[
    ('Light', AppColors.outline),
    ('Medium', AppColors.primary),
    ('Strong', AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/couch_buzz.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? false;
        _intensityIndex = j['intensity'] as int? ?? 1;
        final saved = j['alerts'] as Map<String, dynamic>? ?? {};
        for (final a in _alerts) {
          if (saved.containsKey(a.name)) {
            a.enabled = saved[a.name] as bool? ?? a.enabled;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'intensity': _intensityIndex,
      'alerts': {for (final a in _alerts) a.name: a.enabled},
    }));
  }

  void _toggleAlert(int idx) {
    setState(() => _alerts[idx].enabled = !_alerts[idx].enabled);
    HapticFeedback.selectionClick();
    _save();
  }

  void _testBuzz() {
    switch (_intensityIndex) {
      case 0:
        HapticFeedback.lightImpact();
        break;
      case 2:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.mediumImpact();
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Buzz! (${_intensities[_intensityIndex].$1})'),
        duration: const Duration(seconds: 1),
      ));
  }

  int get _enabledCount => _alerts.where((a) => a.enabled).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Couch Buzz',
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
                _masterToggle(),
                const SizedBox(height: AppSpacing.lg),
                _intensitySelector(),
                const SizedBox(height: AppSpacing.md),
                _testButton(),
                const SizedBox(height: AppSpacing.lg),
                Text('Alert Types',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._alerts.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _alertCard(e.key, e.value),
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
            Text('Phone Vibration Alerts',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Get a buzz when something happens on your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => GestureDetector(
        onTap: () {
          setState(() => _enabled = !_enabled);
          HapticFeedback.mediumImpact();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.secondary
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_enabled
                      ? AppColors.secondary
                      : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_active,
                  size: 22,
                  color: hex(
                      _enabled ? AppColors.secondary : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buzz Alerts',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                        _enabled
                            ? '$_enabledCount alert types active'
                            : 'Tap to enable alerts',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(_enabled
                          ? AppColors.secondary
                          : AppColors.outline)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(
                            _enabled ? AppColors.secondary : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _intensitySelector() => Row(
        children: _intensities.asMap().entries.map((e) {
          final active = e.key == _intensityIndex;
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: e.key < _intensities.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _intensityIndex = e.key);
                  HapticFeedback.selectionClick();
                  _save();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(e.value.$2)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(e.value.$2)
                          .withValues(alpha: active ? 0.4 : 0.15),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(e.value.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(e.value.$2),
                            weight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            size: 11)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _testButton() => GestureDetector(
        onTap: _testBuzz,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.secondary).withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vibration, size: 18, color: hex(AppColors.secondary)),
              const SizedBox(width: 8),
              Text('Test Buzz',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.secondary),
                      weight: FontWeight.w600,
                      size: 13)),
            ],
          ),
        ),
      );

  Widget _alertCard(int idx, _AlertType alert) => GestureDetector(
        onTap: () => _toggleAlert(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(alert.enabled
                    ? AppColors.secondary
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: alert.enabled ? 0.06 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(alert.enabled
                      ? AppColors.secondary
                      : AppColors.outlineVariant)
                  .withValues(alpha: alert.enabled ? 0.25 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(alert.icon,
                  size: 20,
                  color: hex(alert.enabled
                      ? AppColors.secondary
                      : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(alert.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 13)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(alert.enabled
                          ? AppColors.secondary
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(alert.enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(alert.enabled
                            ? AppColors.secondary
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
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
                'Get vibration alerts on your phone for TV events. '
                'Choose alert types and intensity. All settings stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _AlertType {
  String name;
  IconData icon;
  bool enabled;
  _AlertType({required this.name, required this.icon, required this.enabled});
}
