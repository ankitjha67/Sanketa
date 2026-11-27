import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SoundModeScreen extends StatefulWidget {
  const SoundModeScreen({super.key});

  @override
  State<SoundModeScreen> createState() => _SoundModeScreenState();
}

class _SoundModeScreenState extends State<SoundModeScreen> {
  int _selectedMode = 0;
  bool _applied = false;

  static const _modes = [
    (
      'Standard',
      Icons.equalizer,
      'Balanced audio for everyday viewing',
      AppColors.primary,
    ),
    (
      'Movie',
      Icons.movie,
      'Enhanced bass and surround for cinema feel',
      AppColors.secondary,
    ),
    (
      'Music',
      Icons.music_note,
      'Clear mids and highs for music playback',
      AppColors.tertiary,
    ),
    (
      'Sports',
      Icons.sports_soccer,
      'Amplified commentary and crowd atmosphere',
      AppColors.signalEmerald,
    ),
    (
      'Game',
      Icons.sports_esports,
      'Low-latency audio with spatial effects',
      AppColors.alertAmber,
    ),
    (
      'Night',
      Icons.nightlight_round,
      'Compressed dynamic range for quiet listening',
      AppColors.outline,
    ),
  ];

  void _applyMode() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _applied = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_modes[_selectedMode].$1} mode applied'),
        duration: const Duration(seconds: 2),
      ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _applied = false);
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
        title: Text('Sound Mode',
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
          _currentModeDisplay(),
          const SizedBox(height: AppSpacing.lg),
          Text('Sound Modes',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(_modes.length, (i) => _modeTile(i)),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.surround_sound,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Sound Mode',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Switch between audio profiles optimized for different content types',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _currentModeDisplay() {
    final mode = _modes[_selectedMode];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(mode.$4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border:
            Border.all(color: hex(mode.$4).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hex(mode.$4).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(mode.$2, size: 28, color: hex(mode.$4)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Mode',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                const SizedBox(height: 2),
                Text(mode.$1,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w700,
                        size: 18)),
                const SizedBox(height: 2),
                Text(mode.$3,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile(int i) {
    final mode = _modes[i];
    final selected = _selectedMode == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMode = i);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? hex(mode.$4).withValues(alpha: 0.1)
                : hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected
                  ? hex(mode.$4).withValues(alpha: 0.5)
                  : hex(AppColors.outlineVariant).withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hex(mode.$4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(mode.$2,
                    size: 22,
                    color: selected
                        ? hex(mode.$4)
                        : hex(AppColors.outline)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.$1,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    const SizedBox(height: 2),
                    Text(mode.$3,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    size: 20, color: hex(mode.$4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _applyButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _applied ? null : _applyMode,
          icon: _applied
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.volume_up, size: 18),
          label: Text(
            _applied
                ? 'Applied'
                : 'Apply ${_modes[_selectedMode].$1} Mode',
            style: gfont(AppType.bodyMd,
                color: Colors.white, weight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hex(_modes[_selectedMode].$4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        ),
      );

  Widget _infoCard() => Container(
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
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Text('Tips',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            _tipRow('Night mode reduces loud peaks for late-night viewing'),
            _tipRow('Game mode minimizes audio processing latency'),
            _tipRow('Movie mode works best with surround sound setups'),
          ],
        ),
      );

  Widget _tipRow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('  •  ',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
            Expanded(
              child: Text(text,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
            ),
          ],
        ),
      );
}
