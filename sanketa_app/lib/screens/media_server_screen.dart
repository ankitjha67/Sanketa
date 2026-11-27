import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class MediaServerScreen extends StatefulWidget {
  const MediaServerScreen({super.key});

  @override
  State<MediaServerScreen> createState() => _MediaServerScreenState();
}

class _MediaServerScreenState extends State<MediaServerScreen> {
  int _tabIndex = 0;
  bool _serverRunning = false;

  static const _tabs = ['Videos', 'Music', 'Photos'];

  static const _videos = <(String, String, String)>[
    ('Holiday Trip 2024', '1:23:45', '2.3 GB'),
    ('Birthday Party', '45:12', '1.1 GB'),
    ('Concert Recording', '1:52:30', '3.7 GB'),
    ('Vacation Clips', '28:40', '820 MB'),
    ('Family Reunion', '1:05:00', '2.0 GB'),
  ];

  static const _music = <(String, String, String)>[
    ('Chill Playlist', '42 tracks', '380 MB'),
    ('Workout Mix', '28 tracks', '260 MB'),
    ('Road Trip', '35 tracks', '310 MB'),
    ('Classical', '20 tracks', '450 MB'),
    ('Party Hits', '50 tracks', '480 MB'),
  ];

  static const _photos = <(String, String, String)>[
    ('Vacation 2024', '342 photos', '1.8 GB'),
    ('Family Album', '156 photos', '890 MB'),
    ('Screenshots', '89 photos', '120 MB'),
    ('Wallpapers', '45 photos', '350 MB'),
    ('Camera Roll', '1,240 photos', '8.2 GB'),
  ];

  void _toggleServer() {
    HapticFeedback.mediumImpact();
    setState(() => _serverRunning = !_serverRunning);
  }

  void _castItem(String name) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.launch(name);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Casting: $name'),
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
        title: Text('Media Server',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _serverToggle(),
          const SizedBox(height: AppSpacing.md),
          _tabBar(),
          const SizedBox(height: AppSpacing.md),
          _mediaList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _serverToggle() => GestureDetector(
        onTap: _toggleServer,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.surfaceContainerLow)
                .withValues(alpha: _serverRunning ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outlineVariant)
                  .withValues(alpha: _serverRunning ? 0.3 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outline)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _serverRunning ? Icons.dns : Icons.dns_outlined,
                  size: 24,
                  color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DLNA Media Server',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                      _serverRunning ? 'Running — discoverable on LAN' : 'Tap to start serving media',
                      style: gfont(AppType.bodySm,
                          color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outline),
                          size: 11),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: _serverRunning ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _serverRunning ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(_serverRunning ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tabBar() => Row(
        children: _tabs.asMap().entries.map((e) {
          final active = e.key == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = e.key),
              child: Container(
                margin: EdgeInsets.only(right: e.key < 2 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.4 : 0.2),
                  ),
                ),
                child: Center(
                  child: Text(e.value,
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _mediaList() {
    final items = _tabIndex == 0
        ? _videos
        : _tabIndex == 1
            ? _music
            : _photos;
    final icons = [Icons.videocam, Icons.music_note, Icons.photo];
    final colors = [AppColors.primary, AppColors.secondary, AppColors.tertiary];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => _castItem(item.$1),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hex(colors[_tabIndex]).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(icons[_tabIndex],
                        size: 18, color: hex(colors[_tabIndex])),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 11)),
                        Text('${item.$2}  •  ${item.$3}',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 10)),
                      ],
                    ),
                  ),
                  Icon(Icons.cast, size: 16, color: hex(AppColors.primary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
                'Serve media from your phone to any TV on the network. Start the DLNA server, browse your library, and tap to cast. All media stays on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
