import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _AppLimit {
  _AppLimit({
    required this.name,
    required this.icon,
    required this.color,
    this.limitMin = 60,
    this.usedMin = 0,
  });

  final String name;
  final IconData icon;
  final int color;
  int limitMin;
  int usedMin;
  bool enabled = true;

  Map<String, dynamic> toJson() => {
        'name': name,
        'limitMin': limitMin,
        'usedMin': usedMin,
        'enabled': enabled,
      };
}

class AppTimerScreen extends StatefulWidget {
  const AppTimerScreen({super.key});

  @override
  State<AppTimerScreen> createState() => _AppTimerScreenState();
}

class _AppTimerScreenState extends State<AppTimerScreen> {
  bool _notifyOverLimit = true;

  late final List<_AppLimit> _apps = [
    _AppLimit(name: 'YouTube', icon: Icons.play_circle, color: AppColors.error, usedMin: 45),
    _AppLimit(name: 'Netflix', icon: Icons.movie, color: AppColors.error, usedMin: 30),
    _AppLimit(name: 'Disney+', icon: Icons.star, color: AppColors.tertiary, usedMin: 20),
    _AppLimit(name: 'Prime Video', icon: Icons.video_library, color: AppColors.primary, usedMin: 55, limitMin: 60),
    _AppLimit(name: 'Twitch', icon: Icons.live_tv, color: AppColors.secondary, usedMin: 10),
    _AppLimit(name: 'Spotify', icon: Icons.music_note, color: AppColors.signalEmerald, usedMin: 15),
    _AppLimit(name: 'Games', icon: Icons.sports_esports, color: AppColors.alertAmber, usedMin: 40, limitMin: 45),
    _AppLimit(name: 'Browser', icon: Icons.language, color: AppColors.primaryContainer, usedMin: 5),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/app_timer.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _notifyOverLimit = data['notify'] as bool? ?? true;
        final list = data['apps'] as List? ?? [];
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          final idx = _apps.indexWhere((a) => a.name == m['name']);
          if (idx >= 0) {
            _apps[idx].limitMin = m['limitMin'] as int? ?? 60;
            _apps[idx].usedMin = m['usedMin'] as int? ?? 0;
            _apps[idx].enabled = m['enabled'] as bool? ?? true;
          }
        }
      }
    } on Object {
      // First launch — keep defaults.
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'notify': _notifyOverLimit,
      'apps': _apps.map((a) => a.toJson()).toList(),
    }));
  }

  void _resetDaily() {
    setState(() {
      for (final a in _apps) {
        a.usedMin = 0;
      }
    });
    _save();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Daily usage reset'),
        duration: Duration(seconds: 2),
      ));
  }

  void _pickLimit(int idx) {
    final limits = [15, 30, 45, 60, 90, 120, 180, 240];
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Set Limit for ${_apps[idx].name}',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: limits.map((m) {
              final active = _apps[idx].limitMin == m;
              return GestureDetector(
                onTap: () {
                  setState(() => _apps[idx].limitMin = m);
                  _save();
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Center(
                    child: Text(
                        m >= 60 ? '${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}' : '${m}m',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            size: 11)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('App Timer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: hex(AppColors.outline)),
            onPressed: _resetDaily,
            tooltip: 'Reset Daily',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _notifyToggle(),
          const SizedBox(height: AppSpacing.lg),
          Text('App Limits',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._apps.asMap().entries.expand((e) => [
                _appRow(e.key),
                const SizedBox(height: 8),
              ]),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.timer, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Usage Limits',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Set daily time limits for TV apps to manage screen time',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _notifyToggle() => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active,
                size: 18, color: hex(AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Over-Limit Notifications',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface), size: 13)),
            ),
            Switch(
              value: _notifyOverLimit,
              onChanged: (v) {
                setState(() => _notifyOverLimit = v);
                _save();
                HapticFeedback.selectionClick();
              },
              activeColor: hex(AppColors.primary),
            ),
          ],
        ),
      );

  Widget _appRow(int idx) {
    final app = _apps[idx];
    final pct = app.limitMin > 0 ? (app.usedMin / app.limitMin).clamp(0.0, 1.0) : 0.0;
    final over = app.usedMin >= app.limitMin;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(over ? AppColors.error : AppColors.outlineVariant)
              .withValues(alpha: over ? 0.3 : 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(app.icon, size: 20, color: hex(app.color)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text('${app.usedMin}m / ${app.limitMin}m',
                        style: gfont(AppType.bodySm,
                            color: hex(over
                                ? AppColors.error
                                : AppColors.outline),
                            size: 10)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _pickLimit(idx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text('${app.limitMin}m',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600,
                          size: 10)),
                ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: app.enabled,
                onChanged: (v) {
                  setState(() => app.enabled = v);
                  _save();
                  HapticFeedback.selectionClick();
                },
                activeColor: hex(AppColors.signalEmerald),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.15),
              color: hex(over ? AppColors.error : AppColors.signalEmerald),
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
          border:
              Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Set per-app daily usage limits. When a limit is reached, you\'ll be notified. Tap the limit badge to change it. Usage resets daily.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
