import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvPlaylistScreen extends StatefulWidget {
  const TvPlaylistScreen({super.key});

  @override
  State<TvPlaylistScreen> createState() => _TvPlaylistScreenState();
}

class _TvPlaylistScreenState extends State<TvPlaylistScreen> {
  final List<_Playlist> _playlists = [
    _Playlist('Morning News', Icons.newspaper, AppColors.primary, [
      _Item('CNN', '203'),
      _Item('BBC World', '210'),
      _Item('Local News', '5'),
    ]),
    _Playlist('Kids', Icons.child_care, AppColors.signalEmerald, [
      _Item('Cartoon Network', '301'),
      _Item('Disney', '302'),
      _Item('Nickelodeon', '303'),
    ]),
    _Playlist('Sports Night', Icons.sports, AppColors.alertAmber, [
      _Item('ESPN', '400'),
      _Item('Fox Sports', '401'),
    ]),
  ];

  int _activeIdx = -1;
  int _playingItem = -1;
  bool _autoAdvance = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_playlists.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['playlists'] as List<dynamic>? ?? [];
        setState(() {
          _autoAdvance = data['autoAdvance'] as bool? ?? true;
          _playlists.clear();
          for (final p in list) {
            final m = p as Map<String, dynamic>;
            _playlists.add(_Playlist(
              m['name'] as String? ?? 'Playlist',
              Icons.playlist_play,
              m['color'] as int? ?? AppColors.primary,
              (m['items'] as List<dynamic>? ?? [])
                  .map((i) => _Item(
                      (i as Map<String, dynamic>)['name'] as String? ?? '',
                      i['ch'] as String? ?? ''))
                  .toList(),
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_playlists.json');
      await f.writeAsString(jsonEncode({
        'autoAdvance': _autoAdvance,
        'playlists': _playlists
            .map((p) => {
                  'name': p.name,
                  'icon': p.icon.codePoint,
                  'color': p.color,
                  'items': p.items
                      .map((i) => {'name': i.name, 'ch': i.channel})
                      .toList(),
                })
            .toList(),
      }));
    } catch (_) {}
  }

  void _tuneChannel(String ch) {
    final rc = RemoteScope.of(context);
    for (final d in ch.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    HapticFeedback.mediumImpact();
  }

  void _playPlaylist(int idx) {
    setState(() {
      _activeIdx = idx;
      _playingItem = 0;
    });
    if (_playlists[idx].items.isNotEmpty) {
      _tuneChannel(_playlists[idx].items[0].channel);
    }
  }

  void _playItem(int pIdx, int iIdx) {
    setState(() {
      _activeIdx = pIdx;
      _playingItem = iIdx;
    });
    _tuneChannel(_playlists[pIdx].items[iIdx].channel);
  }

  void _nextItem() {
    if (_activeIdx < 0) return;
    final pl = _playlists[_activeIdx];
    if (_playingItem < pl.items.length - 1) {
      setState(() => _playingItem++);
      _tuneChannel(pl.items[_playingItem].channel);
    }
  }

  void _prevItem() {
    if (_activeIdx < 0 || _playingItem <= 0) return;
    setState(() => _playingItem--);
    _tuneChannel(_playlists[_activeIdx].items[_playingItem].channel);
  }

  void _stopPlaylist() {
    setState(() {
      _activeIdx = -1;
      _playingItem = -1;
    });
    HapticFeedback.selectionClick();
  }

  void _addPlaylist() {
    setState(() {
      _playlists.add(_Playlist(
        'Playlist ${_playlists.length + 1}',
        Icons.playlist_play,
        AppColors.secondary,
        [],
      ));
    });
    _save();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Playlist',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _addPlaylist,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (_activeIdx >= 0) ...[
            _nowPlaying(),
            const SizedBox(height: AppSpacing.md),
          ],
          _optionsRow(),
          const SizedBox(height: AppSpacing.lg),
          ..._playlists.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _playlistCard(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.md),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.playlist_play,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Channel Playlists',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Create playlists of channels and auto-surf through them',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _nowPlaying() {
    final pl = _playlists[_activeIdx];
    final item =
        _playingItem >= 0 && _playingItem < pl.items.length
            ? pl.items[_playingItem]
            : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.play_circle,
                  size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Now Playing: ${pl.name}',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 13)),
              ),
              GestureDetector(
                onTap: _stopPlaylist,
                child: Icon(Icons.stop_circle,
                    size: 24, color: hex(AppColors.error)),
              ),
            ],
          ),
          if (item != null) ...[
            const SizedBox(height: 8),
            Text('${item.name} (CH ${item.channel})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500)),
            Text(
                '${_playingItem + 1} of ${pl.items.length}',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrlBtn(Icons.skip_previous, _prevItem),
              const SizedBox(width: 16),
              _ctrlBtn(Icons.skip_next, _nextItem),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hex(AppColors.primary).withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 22, color: hex(AppColors.primary)),
        ),
      );

  Widget _optionsRow() => Row(
        children: [
          Icon(Icons.loop, size: 16, color: hex(AppColors.outline)),
          const SizedBox(width: 6),
          Text('Auto-advance',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w500,
                  size: 12)),
          const Spacer(),
          Switch(
            value: _autoAdvance,
            activeThumbColor: hex(AppColors.signalEmerald),
            onChanged: (v) {
              setState(() => _autoAdvance = v);
              _save();
            },
          ),
        ],
      );

  Widget _playlistCard(int idx, _Playlist pl) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(pl.color).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: hex(pl.color).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(pl.icon, size: 20, color: hex(pl.color)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(pl.name,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 14)),
                ),
                GestureDetector(
                  onTap: () => _playPlaylist(idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hex(pl.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            size: 14, color: hex(pl.color)),
                        const SizedBox(width: 2),
                        Text('Play',
                            style: gfont(AppType.bodySm,
                                color: hex(pl.color),
                                weight: FontWeight.w600,
                                size: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pl.items.asMap().entries.map((e) {
              final playing = idx == _activeIdx && e.key == _playingItem;
              return GestureDetector(
                onTap: () => _playItem(idx, e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hex(playing
                            ? AppColors.signalEmerald
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: playing ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      if (playing)
                        Icon(Icons.graphic_eq,
                            size: 14,
                            color: hex(AppColors.signalEmerald)),
                      if (playing) const SizedBox(width: 6),
                      Text(e.value.name,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: playing
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 12)),
                      const Spacer(),
                      Text('CH ${e.value.channel}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ),
              );
            }),
            if (pl.items.isEmpty)
              Text('No channels yet',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
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
                'Create channel playlists for auto-surfing. '
                'Skip/prev to navigate, auto-advance optional. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Playlist {
  String name;
  IconData icon;
  int color;
  List<_Item> items;
  _Playlist(this.name, this.icon, this.color, this.items);
}

class _Item {
  String name;
  String channel;
  _Item(this.name, this.channel);
}
