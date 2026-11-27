import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class GestureLibraryScreen extends StatefulWidget {
  const GestureLibraryScreen({super.key});

  @override
  State<GestureLibraryScreen> createState() => _GestureLibraryScreenState();
}

class _GestureLibraryScreenState extends State<GestureLibraryScreen> {
  int _categoryIndex = 0;
  int _expandedIndex = -1;

  static const _categories = ['All', 'Swipe', 'Tap', 'Hold', 'Shake'];

  static const _gestures = <(String, String, String, String, IconData)>[
    ('Swipe Up', 'Navigate Up', 'Swipe', 'Move selection up in menus and lists', Icons.arrow_upward),
    ('Swipe Down', 'Navigate Down', 'Swipe', 'Move selection down in menus and lists', Icons.arrow_downward),
    ('Swipe Left', 'Navigate Left', 'Swipe', 'Move selection left or go back', Icons.arrow_back),
    ('Swipe Right', 'Navigate Right', 'Swipe', 'Move selection right or go forward', Icons.arrow_forward),
    ('Single Tap', 'OK / Select', 'Tap', 'Confirm selection or press OK', Icons.touch_app),
    ('Double Tap', 'Back', 'Tap', 'Go back to previous screen', Icons.undo),
    ('Triple Tap', 'Home', 'Tap', 'Return to the home screen', Icons.home),
    ('Long Press', 'Menu', 'Hold', 'Open the context menu', Icons.menu),
    ('Two-Finger Tap', 'Play/Pause', 'Tap', 'Toggle playback of current media', Icons.play_arrow),
    ('Pinch In', 'Volume Down', 'Hold', 'Decrease the volume', Icons.volume_down),
    ('Pinch Out', 'Volume Up', 'Hold', 'Increase the volume', Icons.volume_up),
    ('Shake', 'Mute', 'Shake', 'Toggle mute on the TV', Icons.volume_off),
    ('Shake Twice', 'Power', 'Shake', 'Toggle TV power on/off', Icons.power_settings_new),
    ('Twist Left', 'Channel Down', 'Shake', 'Go to previous channel', Icons.skip_previous),
    ('Twist Right', 'Channel Up', 'Shake', 'Go to next channel', Icons.skip_next),
  ];

  List<(String, String, String, String, IconData)> get _filtered {
    if (_categoryIndex == 0) return _gestures;
    final cat = _categories[_categoryIndex];
    return _gestures.where((g) => g.$3 == cat).toList();
  }

  static const _categoryColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.signalEmerald,
    AppColors.alertAmber,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Gesture Library',
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
          _categoryBar(),
          const SizedBox(height: AppSpacing.md),
          Text('${_filtered.length} Gestures',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._filtered.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _gestureCard(e.value, e.key),
              )),
          const SizedBox(height: AppSpacing.lg),
          _quickRef(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.gesture, size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Learn All Gestures',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Browse and learn every gesture shortcut available in Sanketa',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _categoryBar() => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _categoryIndex;
            return GestureDetector(
              onTap: () => setState(() {
                _categoryIndex = i;
                _expandedIndex = -1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: hex(active ? _categoryColors[i] : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? _categoryColors[i] : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Center(
                  child: Text(_categories[i],
                      style: gfont(AppType.bodySm,
                          color: hex(active ? _categoryColors[i] : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          },
        ),
      );

  Widget _gestureCard(
      (String, String, String, String, IconData) gesture, int idx) {
    final expanded = idx == _expandedIndex;
    final catIdx = _categories.indexOf(gesture.$3);
    final gColor = catIdx >= 0 ? _categoryColors[catIdx] : AppColors.outline;

    return GestureDetector(
      onTap: () => setState(
          () => _expandedIndex = expanded ? -1 : idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(expanded ? gColor : AppColors.surfaceContainerLow)
              .withValues(alpha: expanded ? 0.06 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(expanded ? gColor : AppColors.outlineVariant)
                .withValues(alpha: expanded ? 0.3 : 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hex(gColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(gesture.$5, size: 18, color: hex(gColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gesture.$1,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 13)),
                      Text(gesture.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: hex(gColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(gesture.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(gColor),
                          weight: FontWeight.w600,
                          size: 9)),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: hex(AppColors.outline),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(gesture.$4,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickRef() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on,
                    size: 14, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: 6),
                Text('Quick Reference',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 8),
            ...[
              'Swipe = D-pad navigation',
              'Tap = OK, Double-tap = Back',
              'Long press = Menu',
              'Shake = Mute toggle',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Text('  •  ',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      Expanded(
                        child: Text(tip,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 10)),
                      ),
                    ],
                  ),
                )),
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
                'Browse all available gesture shortcuts. Tap any gesture to see a detailed description of what it does and how to perform it.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
