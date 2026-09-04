import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

/// A softly pulsing status dot (connection beacon, "live" indicator).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = const Color(AppColors.primaryContainer), this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
      );
}

/// A framed surface panel (the recurring card look).
BoxDecoration panel({
  int fill = AppColors.surfaceContainerLow,
  double radius = AppRadii.md,
  int borderColor = AppColors.outlineVariant,
  double borderOpacity = 0.3,
  List<BoxShadow>? shadows,
}) =>
    BoxDecoration(
      color: hex(fill),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: hex(borderColor).withValues(alpha: borderOpacity)),
      boxShadow: shadows,
    );
