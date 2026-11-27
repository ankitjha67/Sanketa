import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvSubtitleSyncScreen extends StatefulWidget {
  const TvSubtitleSyncScreen({super.key});

  @override
  State<TvSubtitleSyncScreen> createState() => _TvSubtitleSyncScreenState();
}

class _TvSubtitleSyncScreenState extends State<TvSubtitleSyncScreen> {
  double _offsetMs = 0;
  bool _subtitlesOn = true;
  int _fontSize = 1;
  int _position = 2;

  static const _fontSizes = ['Small', 'Medium', 'Large', 'Extra Large'];
  static const _positions = ['Top', 'Center', 'Bottom'];
  static const _presets = <(String, double)>[
    ('-500ms', -500),
    ('-200ms', -200),
    ('-100ms', -100),
    ('0ms', 0),
    ('+100ms', 100),
    ('+200ms', 200),
    ('+500ms', 500),
  ];

  void _applyOffset(double ms) {
    setState(() => _offsetMs = ms);
    RemoteScope.of(context).launch('subtitle:offset:${ms.round()}');
    HapticFeedback.selectionClick();
  }

  void _nudge(double delta) {
    setState(() => _offsetMs = (_offsetMs + delta).clamp(-2000, 2000));
    RemoteScope.of(context).launch('subtitle:offset:${_offsetMs.round()}');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Subtitle Sync',
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
          _toggleRow(),
          const SizedBox(height: AppSpacing.lg),
          _offsetDisplay(),
          const SizedBox(height: AppSpacing.md),
          _nudgeButtons(),
          const SizedBox(height: AppSpacing.md),
          _presetChips(),
          const SizedBox(height: AppSpacing.lg),
          _fontSizeSelector(),
          const SizedBox(height: AppSpacing.md),
          _positionSelector(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.subtitles,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Subtitle Sync',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Fine-tune subtitle timing, size, and position',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _toggleRow() => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(_subtitlesOn
                  ? AppColors.signalEmerald
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: _subtitlesOn ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(_subtitlesOn
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.subtitles,
                size: 20,
                color: hex(_subtitlesOn
                    ? AppColors.signalEmerald
                    : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Subtitles',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 13)),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _subtitlesOn = !_subtitlesOn);
                RemoteScope.of(context)
                    .launch('subtitle:${_subtitlesOn ? 'on' : 'off'}');
                HapticFeedback.selectionClick();
              },
              child: Icon(
                _subtitlesOn ? Icons.toggle_on : Icons.toggle_off,
                size: 32,
                color: hex(_subtitlesOn
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant),
              ),
            ),
          ],
        ),
      );

  Widget _offsetDisplay() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('Offset',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
            const SizedBox(height: 4),
            Text(
              '${_offsetMs >= 0 ? '+' : ''}${_offsetMs.round()}ms',
              style: gfont(AppType.headlineMd,
                  color: hex(_offsetMs == 0
                      ? AppColors.signalEmerald
                      : AppColors.primary),
                  size: 32,
                  weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _offsetMs == 0
                  ? 'In sync'
                  : _offsetMs > 0
                      ? 'Subtitles delayed'
                      : 'Subtitles ahead',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _nudgeButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _nudge(-50),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.error).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text('-50ms',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.error),
                          weight: FontWeight.w600,
                          size: 13)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _applyOffset(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color:
                        hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
              ),
              child: Text('Reset',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600,
                      size: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _nudge(50),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color:
                          hex(AppColors.primary).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text('+50ms',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600,
                          size: 13)),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _presetChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _presets.map((p) {
            final active = _offsetMs.round() == p.$2.round();
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _applyOffset(p.$2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                        color: hex(active
                                ? AppColors.primary
                                : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2)),
                  ),
                  child: Text(p.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _fontSizeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Size',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _fontSizes.asMap().entries.map((e) {
              final active = e.key == _fontSize;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _fontSize = e.key);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.secondary
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.secondary
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text(e.value,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.secondary
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 9)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _positionSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Position',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          Row(
            children: _positions.asMap().entries.map((e) {
              final active = e.key == _position;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _position = e.key);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active
                              ? AppColors.alertAmber
                              : AppColors.surfaceContainerLow)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: hex(active
                                  ? AppColors.alertAmber
                                  : AppColors.outlineVariant)
                              .withValues(alpha: active ? 0.4 : 0.2)),
                    ),
                    child: Center(
                      child: Text(e.value,
                          style: gfont(AppType.bodySm,
                              color: hex(active
                                  ? AppColors.alertAmber
                                  : AppColors.onSurface),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 11)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
                'Fine-tune subtitle timing with ms offset, change size and '
                'position. Use presets or nudge buttons. All local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
