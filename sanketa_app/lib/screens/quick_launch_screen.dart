import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class QuickLaunchScreen extends StatefulWidget {
  const QuickLaunchScreen({super.key});

  @override
  State<QuickLaunchScreen> createState() => _QuickLaunchScreenState();
}

class _QuickLaunchScreenState extends State<QuickLaunchScreen> {
  static const _catalogue = <(String, String, IconData, int)>[
    ('Netflix', 'com.netflix.ninja', Icons.play_circle_filled, 0xFFE50914),
    ('YouTube', 'com.google.android.youtube.tv', Icons.smart_display, 0xFFFF0000),
    ('Prime Video', 'com.amazon.avod', Icons.video_library, 0xFF00A8E1),
    ('Disney+', 'com.disney.disneyplus', Icons.movie, 0xFF113CCF),
    ('HBO Max', 'com.hbo.hbonow', Icons.live_tv, 0xFF5822B4),
    ('Apple TV', 'com.apple.atve.sony.appletv', Icons.tv, 0xFF555555),
    ('Plex', 'com.plexapp.android', Icons.perm_media, 0xFFE5A00D),
    ('Spotify', 'com.spotify.tv.android', Icons.headphones, 0xFF1DB954),
    ('Twitch', 'tv.twitch.android.app', Icons.videocam, 0xFF9146FF),
    ('Hulu', 'com.hulu.plus', Icons.stream, 0xFF1CE783),
    ('Crunchyroll', 'com.crunchyroll.crunchyroid', Icons.animation, 0xFFF47521),
    ('Peacock', 'com.peacocktv.peacockandroid', Icons.ondemand_video, 0xFF000000),
  ];

  late List<int> _slots; // indices into _catalogue

  @override
  void initState() {
    super.initState();
    _slots = [0, 1, 2, 3]; // defaults: Netflix, YouTube, Prime, Disney+
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quick_launch.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        if (data.length == 4) {
          setState(() {
            _slots = data.cast<int>().map((i) => i.clamp(0, _catalogue.length - 1)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _file;
      await f.writeAsString(jsonEncode(_slots));
    } catch (_) {}
  }

  void _launch(int slot) {
    HapticFeedback.mediumImpact();
    final app = _catalogue[_slots[slot]];
    final rc = RemoteScope.of(context);
    rc.launch(app.$2);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Launching ${app.$1}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _editSlot(int slot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AppPicker(
        catalogue: _catalogue,
        current: _slots[slot],
        onSelect: (i) {
          Navigator.pop(ctx);
          HapticFeedback.selectionClick();
          setState(() => _slots[slot] = i);
          _save();
        },
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
        title: Text('Quick Launch',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _slotGrid(),
          const SizedBox(height: AppSpacing.md),
          _catalogueSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.rocket_launch,
                size: 40, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 10),
            Text('Quick Launch Shortcuts',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w700,
                    size: 18)),
            const SizedBox(height: 4),
            Text('Tap a slot to launch, long-press to remap',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _slotGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: List.generate(4, (i) {
          final app = _catalogue[_slots[i]];
          return GestureDetector(
            onTap: () => _launch(i),
            onLongPress: () => _editSlot(i),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(app.$4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: Color(app.$4).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(app.$3, size: 28, color: Color(app.$4)),
                  const SizedBox(height: 6),
                  Text(app.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Slot ${i + 1}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          );
        }),
      );

  Widget _catalogueSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Catalogue',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap any app to quick-launch it directly',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
          const SizedBox(height: 8),
          ..._catalogue.map((app) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final rc = RemoteScope.of(context);
                    rc.launch(app.$2);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text('Launching ${app.$1}'),
                        duration: const Duration(seconds: 2),
                      ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                          color: hex(AppColors.outlineVariant)
                              .withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(app.$3, size: 20, color: Color(app.$4)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(app.$1,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: FontWeight.w500,
                                  size: 13)),
                        ),
                        Icon(Icons.launch,
                            size: 14,
                            color: hex(AppColors.outline)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
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
                'Configure 4 quick-launch shortcuts for your favourite TV apps. Tap a slot to launch the app, long-press to remap it to a different app from the catalogue.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _AppPicker extends StatelessWidget {
  const _AppPicker({
    required this.catalogue,
    required this.current,
    required this.onSelect,
  });

  final List<(String, String, IconData, int)> catalogue;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose App',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 16)),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: catalogue.length,
              itemBuilder: (_, i) {
                final app = catalogue[i];
                final selected = i == current;
                return ListTile(
                  leading: Icon(app.$3,
                      color: selected
                          ? Color(app.$4)
                          : hex(AppColors.outline)),
                  title: Text(app.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          size: 14)),
                  trailing: selected
                      ? Icon(Icons.check_circle,
                          size: 18, color: hex(AppColors.signalEmerald))
                      : null,
                  onTap: () => onSelect(i),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
