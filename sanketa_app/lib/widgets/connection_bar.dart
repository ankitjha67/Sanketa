import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

/// The device connection + fast-mode bar at the top of the remote.
class ConnectionBar extends StatelessWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(fill: AppColors.surfaceContainerLow, radius: AppRadii.md),
      child: Row(children: [
        const PulseDot(),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Connected to Living Room TV',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('IP + Ultra-Fast IR Blaster Dual Link',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: c.submit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: panel(fill: AppColors.surfaceContainerHigh, radius: AppRadii.base, borderOpacity: 0.4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search, size: 16, color: hex(AppColors.primaryContainer)),
              const SizedBox(width: 6),
              Text('Search on TV',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }
}
