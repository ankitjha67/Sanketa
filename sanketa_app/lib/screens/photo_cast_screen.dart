import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class PhotoCastScreen extends StatefulWidget {
  const PhotoCastScreen({super.key});

  @override
  State<PhotoCastScreen> createState() => _PhotoCastScreenState();
}

class _PhotoCastScreenState extends State<PhotoCastScreen> {
  int _selectedIndex = -1;
  bool _casting = false;
  bool _slideshow = false;
  int _intervalIndex = 1;

  static const _intervals = [
    ('3 seconds', 3),
    ('5 seconds', 5),
    ('10 seconds', 10),
    ('15 seconds', 15),
    ('30 seconds', 30),
    ('60 seconds', 60),
  ];

  static const _transitions = [
    'Fade',
    'Slide',
    'Zoom',
    'None',
  ];
  int _transIndex = 0;

  static const _samplePhotos = [
    ('Family Dinner', 'IMG_2024_001.jpg', '3.2 MB', Icons.photo),
    ('Beach Sunset', 'IMG_2024_015.jpg', '4.1 MB', Icons.landscape),
    ('Birthday Party', 'IMG_2024_032.jpg', '2.8 MB', Icons.cake),
    ('Mountain Hike', 'IMG_2024_044.jpg', '5.6 MB', Icons.terrain),
    ('City Skyline', 'IMG_2024_058.jpg', '3.9 MB', Icons.location_city),
    ('Pet Portrait', 'IMG_2024_071.jpg', '2.1 MB', Icons.pets),
    ('Garden Flowers', 'IMG_2024_089.jpg', '3.4 MB', Icons.local_florist),
    ('Cooking', 'IMG_2024_102.jpg', '2.5 MB', Icons.restaurant),
  ];

  void _cast(int index) {
    setState(() {
      _selectedIndex = index;
      _casting = true;
    });
    final rc = RemoteScope.of(context);
    rc.launch('Gallery');
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Casting "${_samplePhotos[index].$1}" to TV'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _stopCast() {
    setState(() {
      _casting = false;
      _selectedIndex = -1;
      _slideshow = false;
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
        title: Text('Photo Cast',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_casting) ...[
            _castingCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          _slideshowToggle(),
          const SizedBox(height: AppSpacing.md),
          if (_slideshow) ...[
            _intervalPicker(),
            const SizedBox(height: AppSpacing.sm),
            _transitionPicker(),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Phone Gallery',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: List.generate(_samplePhotos.length, (i) => _photoTile(i)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _castingCard() => Container(
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
                Icon(Icons.cast_connected,
                    size: 20, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _slideshow
                        ? 'Slideshow playing on TV'
                        : 'Casting to TV',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_selectedIndex >= 0) ...[
              const SizedBox(height: 8),
              Text(_samplePhotos[_selectedIndex].$1,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface))),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _stopCast,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Stop Casting',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600,
                        size: 11)),
              ),
            ),
          ],
        ),
      );

  Widget _slideshowToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.slideshow, size: 20, color: hex(AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Slideshow Mode',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  Text('Auto-advance through photos',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            Switch(
              value: _slideshow,
              activeTrackColor: hex(AppColors.primary),
              onChanged: (v) => setState(() => _slideshow = v),
            ),
          ],
        ),
      );

  Widget _intervalPicker() => Container(
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
            Text('Slide Duration',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_intervals.length, (i) {
                final active = i == _intervalIndex;
                return GestureDetector(
                  onTap: () => setState(() => _intervalIndex = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active
                                ? AppColors.primary
                                : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Text(_intervals[i].$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active
                                ? AppColors.primary
                                : AppColors.onSurface),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            size: 11)),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _transitionPicker() => Container(
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
            Text('Transition Effect',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(_transitions.length, (i) {
                final active = i == _transIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _transIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: hex(active
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh)
                              .withValues(alpha: active ? 0.15 : 1),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: hex(active
                                    ? AppColors.primary
                                    : AppColors.outlineVariant)
                                .withValues(alpha: active ? 0.5 : 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(_transitions[i],
                              style: gfont(AppType.bodySm,
                                  color: hex(active
                                      ? AppColors.primary
                                      : AppColors.onSurface),
                                  weight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  size: 10)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );

  Widget _photoTile(int index) {
    final photo = _samplePhotos[index];
    final selected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _cast(index),
      child: Container(
        decoration: BoxDecoration(
          color: hex(selected
                  ? AppColors.primary
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: selected ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(selected ? AppColors.primary : AppColors.outlineVariant)
                .withValues(alpha: selected ? 0.5 : 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(photo.$4,
                size: 32,
                color: hex(selected ? AppColors.primary : AppColors.outline)),
            const SizedBox(height: 6),
            Text(photo.$1,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 11)),
            Text(photo.$3,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
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
                'Cast photos from your phone to the TV via DLNA. Slideshow mode auto-advances through selected photos. Photos stay on your phone and are streamed over your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
