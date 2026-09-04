/// OmniBeam typography tokens (design/DESIGN.md).
///
/// Plus Jakarta Sans for layout/navigation; JetBrains Mono for hardware payloads
/// (frequency readouts, connectivity metadata). Weights run one tier heavier than
/// day-mode to avoid optical thinning on the near-black canvas.
library;

class TypeSpec {
  const TypeSpec({
    required this.family,
    required this.sizePx,
    required this.weight,
    required this.heightPx,
    this.letterSpacingEm = 0,
  });

  final String family;
  final double sizePx;
  final int weight; // 400..800
  final double heightPx;
  final double letterSpacingEm;

  /// Line-height as a multiple of font size (Flutter `TextStyle.height`).
  double get heightMultiple => heightPx / sizePx;

  /// Letter spacing in logical pixels (Flutter `TextStyle.letterSpacing`).
  double get letterSpacingPx => letterSpacingEm * sizePx;
}

class AppFonts {
  const AppFonts._();
  static const String sans = 'Plus Jakarta Sans';
  static const String mono = 'JetBrains Mono';
}

class AppType {
  const AppType._();

  static const headlineXl = TypeSpec(
      family: AppFonts.sans, sizePx: 36, weight: 800, heightPx: 44, letterSpacingEm: -0.02);
  static const headlineXlMobile = TypeSpec(
      family: AppFonts.sans, sizePx: 28, weight: 800, heightPx: 34, letterSpacingEm: -0.02);
  static const headlineLg = TypeSpec(
      family: AppFonts.sans, sizePx: 24, weight: 700, heightPx: 32, letterSpacingEm: -0.01);
  static const headlineMd =
      TypeSpec(family: AppFonts.sans, sizePx: 20, weight: 600, heightPx: 28);
  static const bodyLg =
      TypeSpec(family: AppFonts.sans, sizePx: 16, weight: 400, heightPx: 24);
  static const bodyMd =
      TypeSpec(family: AppFonts.sans, sizePx: 14, weight: 400, heightPx: 20);
  static const bodySm =
      TypeSpec(family: AppFonts.sans, sizePx: 12, weight: 400, heightPx: 16);
  static const labelMonoLg = TypeSpec(
      family: AppFonts.mono, sizePx: 14, weight: 600, heightPx: 18, letterSpacingEm: 0.05);
  static const labelMonoSm = TypeSpec(
      family: AppFonts.mono, sizePx: 11, weight: 500, heightPx: 14, letterSpacingEm: 0.08);
}
