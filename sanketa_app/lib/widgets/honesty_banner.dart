import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

/// FR-4.5: Field-state honesty banner.
///
/// Shown when the adapter is write-only and cannot confirm whether a command
/// actually changed the TV's state. PRD rule: "No raw error codes in primary
/// UI copy. Every failure has a named, human explanation and one actionable
/// next step."
class HonestyBanner extends StatelessWidget {
  const HonestyBanner({
    super.key,
    required this.label,
    this.reportsState = false,
  });

  final String label;
  final bool reportsState;

  @override
  Widget build(BuildContext context) {
    if (reportsState) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: hex(AppColors.tertiary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant)),
            ),
          ),
        ],
      ),
    );
  }
}
