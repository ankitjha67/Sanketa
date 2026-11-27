import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenSplitScreen extends StatefulWidget {
  const ScreenSplitScreen({super.key});

  @override
  State<ScreenSplitScreen> createState() => _ScreenSplitScreenState();
}

class _ScreenSplitScreenState extends State<ScreenSplitScreen> {
  int _layout = 0;
  int _sourceA = 0;
  int _sourceB = 1;

  static const _layouts = <(String, IconData, String)>[
    ('Side by Side', Icons.view_column, '50/50 split'),
    ('Picture in Picture', Icons.picture_in_picture, 'Main + corner'),
    ('Top & Bottom', Icons.view_agenda, 'Stacked split'),
    ('Focus + Mini', Icons.view_sidebar, '70/30 split'),
  ];

  static const _sources = <(String, IconData, int)>[
    ('HDMI 1', Icons.settings_input_hdmi, AppColors.primary),
    ('HDMI 2', Icons.settings_input_hdmi, AppColors.secondary),
    ('Tuner', Icons.tv, AppColors.signalEmerald),
    ('AV', Icons.input, AppColors.alertAmber),
    ('USB', Icons.usb, AppColors.tertiary),
    ('Streaming', Icons.wifi, AppColors.error),
  ];

  void _apply() {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${_layouts[_layout].$1} applied'),
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
        title: Text('Screen Split',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.md),
          _layoutPicker(),
          const SizedBox(height: AppSpacing.md),
          _sourcePicker('Source A', _sourceA, (v) => setState(() => _sourceA = v)),
          const SizedBox(height: 8),
          _sourcePicker('Source B', _sourceB, (v) => setState(() => _sourceB = v)),
          const SizedBox(height: AppSpacing.md),
          _applyButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
        height: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: _buildLayoutPreview(),
      );

  Widget _buildLayoutPreview() {
    final a = _sources[_sourceA];
    final b = _sources[_sourceB];
    switch (_layout) {
      case 0:
        return Row(
          children: [
            Expanded(child: _previewPane(a.$1, a.$3)),
            const SizedBox(width: 4),
            Expanded(child: _previewPane(b.$1, b.$3)),
          ],
        );
      case 1:
        return Stack(
          children: [
            _previewPane(a.$1, a.$3),
            Positioned(
              right: 8,
              bottom: 8,
              width: 60,
              height: 40,
              child: _previewPane(b.$1, b.$3),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            Expanded(child: _previewPane(a.$1, a.$3)),
            const SizedBox(height: 4),
            Expanded(child: _previewPane(b.$1, b.$3)),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(flex: 7, child: _previewPane(a.$1, a.$3)),
            const SizedBox(width: 4),
            Expanded(flex: 3, child: _previewPane(b.$1, b.$3)),
          ],
        );
    }
  }

  Widget _previewPane(String label, int color) => Container(
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: hex(color).withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(color),
                  weight: FontWeight.w600,
                  size: 9)),
        ),
      );

  Widget _layoutPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layout',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: _layouts.asMap().entries.map((e) {
              final l = e.value;
              final active = e.key == _layout;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _layout = e.key),
                  child: Container(
                    margin: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.12 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(l.$2,
                            size: 20,
                            color: hex(active ? AppColors.primary : AppColors.outline)),
                        const SizedBox(height: 4),
                        Text(l.$1,
                            textAlign: TextAlign.center,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 7)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _sourcePicker(String label, int selected, ValueChanged<int> onChanged) =>
      Container(
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
            Text(label,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _sources.asMap().entries.map((e) {
                final s = e.value;
                final active = e.key == selected;
                return GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(active ? s.$3 : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.12 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? s.$3 : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.$2, size: 14, color: hex(active ? s.$3 : AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(s.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? s.$3 : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400,
                                size: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _applyButton() => GestureDetector(
        onTap: _apply,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.splitscreen, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Apply Split',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
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
                'Split your TV screen to show two sources at once. Choose a layout (side-by-side, PiP, stacked, or focus), select sources, and apply. Great for watching the game while keeping news on.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
