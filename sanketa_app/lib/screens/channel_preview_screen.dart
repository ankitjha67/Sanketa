import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelPreviewScreen extends StatefulWidget {
  const ChannelPreviewScreen({super.key});

  @override
  State<ChannelPreviewScreen> createState() => _ChannelPreviewScreenState();
}

class _ChannelPreviewScreenState extends State<ChannelPreviewScreen> {
  int _selectedIndex = 0;

  static const _channels = <(String, int, String, IconData, int, String)>[
    ('CNN', 100, 'News', Icons.article, AppColors.error, 'Breaking news coverage'),
    ('ESPN', 206, 'Sports', Icons.sports, AppColors.signalEmerald, 'Live basketball game'),
    ('HBO', 501, 'Movies', Icons.movie, AppColors.secondary, 'The Dark Knight'),
    ('Discovery', 278, 'Documentary', Icons.explore, AppColors.primary, 'Planet Earth III'),
    ('Nickelodeon', 299, 'Kids', Icons.child_care, AppColors.alertAmber, 'SpongeBob SquarePants'),
    ('MTV', 400, 'Music', Icons.music_note, AppColors.tertiary, 'Top 20 Countdown'),
    ('Fox Sports', 219, 'Sports', Icons.sports_soccer, AppColors.signalEmerald, 'NFL Sunday'),
    ('BBC', 110, 'News', Icons.public, AppColors.error, 'World news update'),
    ('AMC', 510, 'Movies', Icons.theaters, AppColors.secondary, 'The Walking Dead'),
    ('Cartoon Network', 296, 'Kids', Icons.animation, AppColors.alertAmber, 'Adventure Time'),
  ];

  void _tuneChannel(int index) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    final ch = _channels[index];
    final digits = ch.$2.toString();
    for (final d in digits.split('')) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    setState(() => _selectedIndex = index);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuned to ${ch.$1} (Ch ${ch.$2})'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final ch = _channels[_selectedIndex];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Channel Preview',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(ch),
          const SizedBox(height: AppSpacing.md),
          _channelList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard(
          (String, int, String, IconData, int, String) ch) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(ch.$5).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(ch.$5).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(ch.$4, size: 36, color: hex(ch.$5)),
                  const SizedBox(height: 4),
                  Text(ch.$6,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w500,
                          size: 11)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ch.$1,
                        style: gfont(AppType.bodyMd,
                            color: hex(ch.$5),
                            weight: FontWeight.w700,
                            size: 16)),
                    Text('Ch ${ch.$2}  •  ${ch.$3}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 11)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _tuneChannel(_selectedIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(ch.$5).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text('Watch',
                        style: gfont(AppType.bodySm,
                            color: hex(ch.$5),
                            weight: FontWeight.w600,
                            size: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _channelList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All Channels',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._channels.asMap().entries.map((e) {
            final ch = e.value;
            final active = e.key == _selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = e.key),
                onDoubleTap: () => _tuneChannel(e.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hex(active ? ch.$5 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: hex(active ? ch.$5 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.3 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: hex(ch.$5).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(ch.$4,
                            size: 18, color: hex(ch.$5)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ch.$1,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 11)),
                            Text('Ch ${ch.$2}  •  ${ch.$6}',
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline),
                                    size: 10)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hex(ch.$5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(ch.$3,
                            style: gfont(AppType.bodySm,
                                color: hex(ch.$5),
                                weight: FontWeight.w500,
                                size: 8)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
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
                'Preview what\'s playing on each channel before tuning. Tap a channel to preview, double-tap to tune in. The preview shows current program info for quick browsing.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
