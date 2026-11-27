import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelPipSwapScreen extends StatefulWidget {
  const ChannelPipSwapScreen({super.key});

  @override
  State<ChannelPipSwapScreen> createState() => _ChannelPipSwapScreenState();
}

class _ChannelPipSwapScreenState extends State<ChannelPipSwapScreen> {
  String _mainChannel = '203';
  String _pipChannel = '400';
  bool _pipActive = false;
  int _swapCount = 0;

  static const _quickChannels = <(String, String, int)>[
    ('CNN', '203', AppColors.primary),
    ('ESPN', '400', AppColors.signalEmerald),
    ('HBO', '500', AppColors.secondary),
    ('BBC', '210', AppColors.alertAmber),
    ('Discovery', '250', AppColors.tertiary),
    ('Disney', '302', AppColors.error),
  ];

  void _tuneMain(String ch) {
    final rc = RemoteScope.of(context);
    for (final d in ch.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    setState(() => _mainChannel = ch);
    HapticFeedback.mediumImpact();
  }

  void _tunePip(String ch) {
    RemoteScope.of(context).launch('pip:tune:$ch');
    setState(() => _pipChannel = ch);
    HapticFeedback.mediumImpact();
  }

  void _swap() {
    RemoteScope.of(context).launch('pip:swap');
    setState(() {
      final tmp = _mainChannel;
      _mainChannel = _pipChannel;
      _pipChannel = tmp;
      _swapCount++;
    });
    HapticFeedback.heavyImpact();
  }

  void _togglePip() {
    RemoteScope.of(context).launch('pip:${_pipActive ? 'off' : 'on'}');
    setState(() => _pipActive = !_pipActive);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('PiP Swap',
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
          _pipToggle(),
          const SizedBox(height: AppSpacing.lg),
          _dualView(),
          const SizedBox(height: AppSpacing.md),
          _swapButton(),
          const SizedBox(height: AppSpacing.lg),
          _channelPicker('Main Channel', _mainChannel, _tuneMain),
          const SizedBox(height: AppSpacing.md),
          _channelPicker('PiP Channel', _pipChannel, _tunePip),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.swap_horiz,
                size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('PiP Channel Swap',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Quick-swap main and PiP channels while watching two at once',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _pipToggle() => GestureDetector(
        onTap: _togglePip,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(_pipActive
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _pipActive ? 0.12 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(_pipActive
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant)
                    .withValues(alpha: _pipActive ? 0.4 : 0.2)),
          ),
          child: Center(
            child: Text(
              _pipActive ? 'PiP ON' : 'PiP OFF',
              style: gfont(AppType.bodyMd,
                  color: hex(
                      _pipActive ? AppColors.signalEmerald : AppColors.outline),
                  weight: FontWeight.w600,
                  size: 14),
            ),
          ),
        ),
      );

  Widget _dualView() => Row(
        children: [
          Expanded(child: _channelCard('Main', _mainChannel, AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: _channelCard('PiP', _pipChannel, AppColors.secondary)),
        ],
      );

  Widget _channelCard(String label, String ch, int c) {
    final name = _quickChannels
        .where((q) => q.$2 == ch)
        .map((q) => q.$1)
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: hex(c).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(c).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(c), weight: FontWeight.w600, size: 10)),
          const SizedBox(height: 4),
          Text('CH $ch',
              style: gfont(AppType.headlineMd,
                  color: hex(c), size: 24, weight: FontWeight.w700)),
          if (name != null)
            Text(name,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
        ],
      ),
    );
  }

  Widget _swapButton() => GestureDetector(
        onTap: _swap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.alertAmber).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(AppColors.alertAmber).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz,
                  size: 24, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 8),
              Text('Swap Channels',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.alertAmber),
                      weight: FontWeight.w600,
                      size: 14)),
            ],
          ),
        ),
      );

  Widget _channelPicker(
          String title, String selected, ValueChanged<String> onSelect) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickChannels.map((q) {
              final active = q.$2 == selected;
              return GestureDetector(
                onTap: () => onSelect(q.$2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active ? q.$3 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                        color: hex(active ? q.$3 : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2)),
                  ),
                  child: Text('${q.$1} (${q.$2})',
                      style: gfont(AppType.bodySm,
                          color: hex(active ? q.$3 : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _statsRow() => Row(
        children: [
          _stat('Main', 'CH $_mainChannel', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _stat('PiP', 'CH $_pipChannel', AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          _stat('Swaps', '$_swapCount', AppColors.alertAmber),
        ],
      );

  Widget _stat(String label, String val, int c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(c).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              Text(val,
                  style: gfont(AppType.bodyMd,
                      color: hex(c), size: 13, weight: FontWeight.w700)),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
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
                'Quick-swap main and PiP channels. Pick channels for each view '
                'and swap with one tap. All commands sent locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
