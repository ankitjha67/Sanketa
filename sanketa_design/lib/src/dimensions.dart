/// Spacing and radius tokens (design/DESIGN.md).
library;

/// Spacing scale, in logical pixels (rem × 16).
class AppSpacing {
  const AppSpacing._();
  static const double space2xs = 2; // 0.125rem
  static const double xs = 4; // 0.25rem
  static const double sm = 8; // 0.5rem
  static const double md = 12; // 0.75rem
  static const double base = 16; // 1rem
  static const double lg = 20; // 1.25rem
  static const double xl = 24; // 1.5rem
  static const double space2xl = 32; // 2rem
  static const double space3xl = 48; // 3rem

  /// Minimum touch target for remote triggers (48px), enforced regardless of
  /// icon size for single-handed use in unlit rooms.
  static const double touchTargetMin = 48;
}

/// Corner radii, in logical pixels.
class AppRadii {
  const AppRadii._();
  static const double sm = 4; // 0.25rem
  static const double base = 8; // 0.5rem  (DEFAULT)
  static const double md = 12; // 0.75rem
  static const double lg = 16; // 1rem
  static const double xl = 24; // 1.5rem  (remote outer shell)
  static const double full = 9999; // pills
}
