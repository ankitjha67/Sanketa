import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvKaraokeScreen extends StatefulWidget {
  const TvKaraokeScreen({super.key});

  @override
  State<TvKaraokeScreen> createState() => _TvKaraokeScreenState();
}

class _TvKaraokeScreenState extends State<TvKaraokeScreen> {
  int _genreIndex = 0;
  int _selectedSong = -1;
  bool _micEnabled = true;
  bool _lyricsEnabled = true;
  bool _playing = false;

  static const _genres = <(String, int)>[
    ('All', AppColors.primary),
    ('Pop', AppColors.secondary),
    ('Rock', AppColors.error),
    ('Classics', AppColors.tertiary),
    ('Bollywood', AppColors.signalEmerald),
  ];

  static final _songs = <_Song>[
    _Song(title: 'Bohemian Rhapsody', artist: 'Queen', genre: 'Rock', duration: '5:55'),
    _Song(title: 'Shape of You', artist: 'Ed Sheeran', genre: 'Pop', duration: '3:53'),
    _Song(title: 'Hotel California', artist: 'Eagles', genre: 'Rock', duration: '6:30'),
    _Song(title: 'Blinding Lights', artist: 'The Weeknd', genre: 'Pop', duration: '3:20'),
    _Song(title: 'Tum Hi Ho', artist: 'Arijit Singh', genre: 'Bollywood', duration: '4:22'),
    _Song(title: 'Imagine', artist: 'John Lennon', genre: 'Classics', duration: '3:03'),
    _Song(title: 'Kal Ho Naa Ho', artist: 'Sonu Nigam', genre: 'Bollywood', duration: '5:21'),
    _Song(title: 'Sweet Child O Mine', artist: 'Guns N Roses', genre: 'Rock', duration: '5:56'),
    _Song(title: 'Levitating', artist: 'Dua Lipa', genre: 'Pop', duration: '3:23'),
    _Song(title: 'What a Wonderful World', artist: 'Louis Armstrong', genre: 'Classics', duration: '2:21'),
    _Song(title: 'Chaiyya Chaiyya', artist: 'Sukhwinder Singh', genre: 'Bollywood', duration: '6:28'),
    _Song(title: 'Yesterday', artist: 'The Beatles', genre: 'Classics', duration: '2:05'),
  ];

  List<_Song> get _filtered {
    if (_genreIndex == 0) return _songs;
    return _songs.where((s) => s.genre == _genres[_genreIndex].$1).toList();
  }

  void _playSong(int idx) {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    setState(() {
      _selectedSong = idx;
      _playing = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _stopSong() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.back);
    setState(() => _playing = false);
    HapticFeedback.selectionClick();
  }

  int _genreColor(String genre) {
    switch (genre) {
      case 'Pop':
        return AppColors.secondary;
      case 'Rock':
        return AppColors.error;
      case 'Classics':
        return AppColors.tertiary;
      case 'Bollywood':
        return AppColors.signalEmerald;
      default:
        return AppColors.primary;
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
        title: Text('TV Karaoke',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _controlsRow(),
          const SizedBox(height: AppSpacing.md),
          if (_playing && _selectedSong >= 0) ...[
            _nowPlayingCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          _genreChips(),
          const SizedBox(height: AppSpacing.md),
          ..._filtered.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _songCard(e.key, e.value),
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
            Icon(Icons.mic, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Sing Along',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Pick a song and sing along with lyrics on your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _controlsRow() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _micEnabled = !_micEnabled);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(_micEnabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(_micEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _micEnabled ? Icons.mic : Icons.mic_off,
                        size: 18,
                        color: hex(_micEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline)),
                    const SizedBox(width: 6),
                    Text('Mic',
                        style: gfont(AppType.bodySm,
                            color: hex(_micEnabled
                                ? AppColors.signalEmerald
                                : AppColors.outline),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _lyricsEnabled = !_lyricsEnabled);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(_lyricsEnabled
                          ? AppColors.primary
                          : AppColors.outline)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(_lyricsEnabled
                            ? AppColors.primary
                            : AppColors.outline)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.subtitles,
                        size: 18,
                        color: hex(_lyricsEnabled
                            ? AppColors.primary
                            : AppColors.outline)),
                    const SizedBox(width: 6),
                    Text('Lyrics',
                        style: gfont(AppType.bodySm,
                            color: hex(_lyricsEnabled
                                ? AppColors.primary
                                : AppColors.outline),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _nowPlayingCard() {
    final song = _songs[_selectedSong];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.secondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.secondary).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, size: 24, color: hex(AppColors.secondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Now Playing',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.secondary), size: 9)),
                Text(song.title,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text(song.artist,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _stopSong,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hex(AppColors.error).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stop, size: 20, color: hex(AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genreChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _genres.asMap().entries.map((e) {
            final active = e.key == _genreIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _genreIndex = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: hex(e.value.$2)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$2)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Text(e.value.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(e.value.$2),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _songCard(int idx, _Song song) {
    final realIdx = _songs.indexOf(song);
    final isPlaying = _playing && realIdx == _selectedSong;
    return GestureDetector(
      onTap: () => isPlaying ? _stopSong() : _playSong(realIdx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(isPlaying
                  ? AppColors.secondary
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: isPlaying ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(isPlaying
                    ? AppColors.secondary
                    : AppColors.outlineVariant)
                .withValues(alpha: isPlaying ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(_genreColor(song.genre)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                  isPlaying ? Icons.equalizer : Icons.music_note,
                  size: 20,
                  color: hex(_genreColor(song.genre))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Row(
                    children: [
                      Text(song.artist,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(_genreColor(song.genre))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(song.genre,
                            style: gfont(AppType.bodySm,
                                color: hex(_genreColor(song.genre)),
                                size: 8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(song.duration,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
            const SizedBox(width: 8),
            Icon(isPlaying ? Icons.stop_circle : Icons.play_circle,
                size: 24,
                color: hex(isPlaying
                    ? AppColors.error
                    : AppColors.secondary)),
          ],
        ),
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
                'Pick a song and sing along with lyrics displayed on your TV. '
                'Toggle mic and lyrics overlays for the best experience.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Song {
  final String title;
  final String artist;
  final String genre;
  final String duration;
  _Song(
      {required this.title,
      required this.artist,
      required this.genre,
      required this.duration});
}
