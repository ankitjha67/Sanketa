import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SportsScoreScreen extends StatefulWidget {
  const SportsScoreScreen({super.key});

  @override
  State<SportsScoreScreen> createState() => _SportsScoreScreenState();
}

class _SportsScoreScreenState extends State<SportsScoreScreen> {
  final _favourites = <int>{};
  bool _refreshing = false;

  static const _games = <({String home, String away, int homeScore, int awayScore, String period, int channel})>[
    (home: 'Lakers', away: 'Celtics', homeScore: 98, awayScore: 102, period: 'Q4 2:14', channel: 205),
    (home: 'Man Utd', away: 'Arsenal', homeScore: 1, awayScore: 2, period: '2nd Half', channel: 310),
    (home: 'India', away: 'Australia', homeScore: 287, awayScore: 194, period: '3rd Innings', channel: 401),
    (home: 'Federer', away: 'Nadal', homeScore: 6, awayScore: 4, period: 'Set 2', channel: 150),
    (home: 'Patriots', away: 'Chiefs', homeScore: 21, awayScore: 24, period: '3rd Qtr', channel: 220),
  ];

  void _tune(int channel) {
    final rc = RemoteScope.of(context);
    final digits = channel.toString().split('');
    for (final d in digits) {
      switch (d) {
        case '0': rc.key(core.Key.ok); break;
        case '1': rc.key(core.Key.up); break;
        case '2': rc.key(core.Key.down); break;
        case '3': rc.key(core.Key.left); break;
        case '4': rc.key(core.Key.right); break;
        case '5': rc.key(core.Key.menu); break;
        default: rc.key(core.Key.ok);
      }
    }
    rc.key(core.Key.ok);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to channel $channel'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _toggleFav(int idx) {
    setState(() {
      if (_favourites.contains(idx)) {
        _favourites.remove(idx);
      } else {
        _favourites.add(idx);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _refresh() {
    setState(() => _refreshing = true);
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _refreshing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Sports Score',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: _refreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: hex(AppColors.primary)))
                : Icon(Icons.refresh, color: hex(AppColors.primary)),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.lg),
          Text('Live Games',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_games.length, _gameCard),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.sports, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('Live Scores',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Follow live games and tune to channels with one tap',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _statBadge('${_games.length}', 'Games', AppColors.primary),
          const SizedBox(width: 8),
          _statBadge('${_favourites.length}', 'Favourites', AppColors.alertAmber),
          const SizedBox(width: 8),
          _statBadge(_refreshing ? '...' : 'Live', 'Status', AppColors.signalEmerald),
        ],
      );

  Widget _statBadge(String value, String label, int color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: gfont(AppType.bodyMd,
                      color: hex(color), weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
      );

  Widget _gameCard(int idx) {
    final g = _games[idx];
    final isFav = _favourites.contains(idx);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hex(AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(g.period,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.error),
                          weight: FontWeight.w600,
                          size: 10)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleFav(idx),
                  child: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: hex(isFav ? AppColors.alertAmber : AppColors.outline),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(g.home,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600)),
                      Text('${g.homeScore}',
                          style: gfont(AppType.headlineMd,
                              color: hex(AppColors.onSurface),
                              size: 32,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text('vs',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 12)),
                Expanded(
                  child: Column(
                    children: [
                      Text(g.away,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600)),
                      Text('${g.awayScore}',
                          style: gfont(AppType.headlineMd,
                              color: hex(AppColors.onSurface),
                              size: 32,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _tune(g.channel),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text('Tune to CH ${g.channel}',
                    textAlign: TextAlign.center,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: hex(AppColors.outline), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scores are simulated samples. Tap Tune to switch your TV to the game channel.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ),
          ],
        ),
      );
}
