import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundProfileScreen extends StatefulWidget {
  const SoundProfileScreen({super.key});

  @override
  State<SoundProfileScreen> createState() => _SoundProfileScreenState();
}

class _SoundProfileScreenState extends State<SoundProfileScreen> {
  int _activeIndex = 0;
  bool _loading = true;

  static const _profiles = <(String, IconData, int, List<(String, double)>)>[
    ('Movie', Icons.movie, AppColors.primary, [
      ('Bass', 0.7),
      ('Mid', 0.5),
      ('Treble', 0.4),
      ('Surround', 0.9),
      ('Dialogue', 0.6),
    ]),
    ('Music', Icons.music_note, AppColors.secondary, [
      ('Bass', 0.6),
      ('Mid', 0.7),
      ('Treble', 0.7),
      ('Surround', 0.5),
      ('Dialogue', 0.3),
    ]),
    ('News', Icons.newspaper, AppColors.tertiary, [
      ('Bass', 0.2),
      ('Mid', 0.5),
      ('Treble', 0.5),
      ('Surround', 0.1),
      ('Dialogue', 0.9),
    ]),
    ('Sports', Icons.sports_soccer, AppColors.signalEmerald, [
      ('Bass', 0.5),
      ('Mid', 0.6),
      ('Treble', 0.5),
      ('Surround', 0.8),
      ('Dialogue', 0.7),
    ]),
    ('Night', Icons.bedtime, AppColors.alertAmber, [
      ('Bass', 0.3),
      ('Mid', 0.4),
      ('Treble', 0.3),
      ('Surround', 0.2),
      ('Dialogue', 0.8),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/sound_profile.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _activeIndex = data['activeIndex'] as int? ?? 0;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({'activeIndex': _activeIndex}));
  }

  void _selectProfile(int idx) {
    HapticFeedback.selectionClick();
    setState(() => _activeIndex = idx);
    _save();

    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_profiles[idx].$1} profile applied'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    final active = _profiles[_activeIndex];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sound Profiles',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(active),
          const SizedBox(height: AppSpacing.md),
          Text('Profiles',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._profiles.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _profileCard(e.value, e.key),
              )),
          const SizedBox(height: AppSpacing.md),
          _eqDisplay(active),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, IconData, int, List<(String, double)>) profile) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(profile.$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(profile.$3).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(profile.$2, size: 48, color: hex(profile.$3)),
            const SizedBox(height: 8),
            Text('${profile.$1} Mode',
                style: gfont(AppType.bodyMd,
                    color: hex(profile.$3), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Optimized audio settings for ${profile.$1.toLowerCase()} content',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _profileCard(
      (String, IconData, int, List<(String, double)>) profile, int idx) {
    final isActive = idx == _activeIndex;
    return GestureDetector(
      onTap: () => _selectProfile(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(isActive ? profile.$3 : AppColors.surfaceContainerLow)
              .withValues(alpha: isActive ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(isActive ? profile.$3 : AppColors.outlineVariant)
                .withValues(alpha: isActive ? 0.4 : 0.15),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(profile.$3).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(profile.$2, size: 20, color: hex(profile.$3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(profile.$4.map((b) => '${b.$1}: ${(b.$2 * 100).round()}%').join(' · '),
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
            Icon(
              isActive ? Icons.check_circle : Icons.radio_button_off,
              size: 20,
              color: hex(isActive ? profile.$3 : AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eqDisplay((String, IconData, int, List<(String, double)>) profile) =>
      Container(
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
            Text('Equalizer: ${profile.$1}',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: profile.$4.map((band) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${(band.$2 * 100).round()}',
                              style: gfont(AppType.bodySm,
                                  color: hex(profile.$3),
                                  weight: FontWeight.w600,
                                  size: 9)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: FractionallySizedBox(
                              heightFactor: band.$2,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: hex(profile.$3).withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(band.$1,
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline), size: 8)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                'Switch between audio profiles optimized for different content. Each profile adjusts bass, mid, treble, surround, and dialogue levels for the best listening experience.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
