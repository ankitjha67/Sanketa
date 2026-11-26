import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvStorageScreen extends StatelessWidget {
  const TvStorageScreen({super.key});

  static const _categories = <(String, IconData, double, int, int)>[
    ('System', Icons.android, 4.2, AppColors.primary, AppColors.primary),
    ('Apps', Icons.apps, 3.8, AppColors.secondary, AppColors.secondary),
    ('Media', Icons.photo_library, 2.1, AppColors.alertAmber, AppColors.alertAmber),
    ('Cache', Icons.cached, 1.4, AppColors.tertiary, AppColors.tertiary),
    ('Other', Icons.folder, 0.8, AppColors.outline, AppColors.outline),
  ];

  static const _totalGb = 16.0;

  @override
  Widget build(BuildContext context) {
    final usedGb = _categories.fold<double>(0, (s, c) => s + c.$3);
    final freeGb = _totalGb - usedGb;
    final usedPct = (usedGb / _totalGb * 100).round();

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Storage',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _summaryCard(usedGb, freeGb, usedPct),
          const SizedBox(height: AppSpacing.md),
          _storageBar(usedGb),
          const SizedBox(height: AppSpacing.md),
          _categoryList(context),
          const SizedBox(height: AppSpacing.md),
          _actionButtons(context),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _summaryCard(double used, double free, int pct) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('Used', '${used.toStringAsFixed(1)} GB'),
            Container(width: 1, height: 40, color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            _stat('Free', '${free.toStringAsFixed(1)} GB'),
            Container(width: 1, height: 40, color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            _stat('Total', '${_totalGb.toStringAsFixed(0)} GB'),
          ],
        ),
      );

  Widget _stat(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.primary), size: 18, weight: FontWeight.w700)),
          Text(label,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _storageBar(double used) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storage Usage',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  ..._categories.map((c) {
                    final w = c.$3 / _totalGb;
                    return Flexible(
                      flex: (w * 1000).round(),
                      child: Container(color: hex(c.$4)),
                    );
                  }),
                  Flexible(
                    flex: ((_totalGb - used) / _totalGb * 1000).round(),
                    child: Container(
                        color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: _categories.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: hex(c.$4), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${c.$1} ${c.$3} GB',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface), size: 9)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _categoryList(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._categories.map((c) {
            final pct = (c.$3 / _totalGb * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(c.$2, size: 20, color: hex(c.$4)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$1,
                              style: gfont(AppType.bodyMd,
                                  color: hex(AppColors.onSurface),
                                  weight: FontWeight.w600, size: 12)),
                          Text('${c.$3} GB ($pct%)',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.outline), size: 10)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        child: LinearProgressIndicator(
                          value: c.$3 / _totalGb,
                          backgroundColor:
                              hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                          color: hex(c.$4),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );

  Widget _actionButtons(BuildContext context) => Column(
        children: [
          GestureDetector(
            onTap: () {
              final rc = RemoteScope.of(context);
              rc.key(core.Key.menu);
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(
                  content: Text('Opening TV storage settings'),
                  duration: Duration(seconds: 2),
                ));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(AppColors.primary).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 18, color: hex(AppColors.primary)),
                  const SizedBox(width: 8),
                  Text('Open TV Storage Settings',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary), weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View your TV internal storage breakdown by category. Open TV settings to clear cache, uninstall apps, or manage files. All data shown is sample data.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
