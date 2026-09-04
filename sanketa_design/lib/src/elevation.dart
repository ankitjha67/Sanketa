/// Elevation / depth tokens (design/DESIGN.md + the CSS in design/code.html).
///
/// Depth is a hybrid of physical extrusion (bevels, recesses) and optical
/// luminance (proximity glows). Each named effect is a list of shadow layers.
/// Flutter renders outer layers as `BoxShadow`; `inset` layers need a custom
/// painter / inner-shadow decoration (the app provides one).
library;

class ShadowSpec {
  const ShadowSpec({
    required this.dx,
    required this.dy,
    required this.blur,
    this.spread = 0,
    required this.colorArgb,
    this.inset = false,
  });

  final double dx;
  final double dy;
  final double blur;
  final double spread;
  final int colorArgb; // 0xAARRGGBB
  final bool inset;
}

class AppElevation {
  const AppElevation._();

  /// Chiseled convex remote key: top highlight + drop shadow.
  static const List<ShadowSpec> tactileButton = [
    ShadowSpec(dx: 0, dy: 4, blur: 8, colorArgb: 0x99000000), // 0.6 black
    ShadowSpec(dx: 0, dy: 1, blur: 0, colorArgb: 0x1FFFFFFF, inset: true), // 0.12 white top
  ];

  /// Pressed state: sinks in.
  static const List<ShadowSpec> tactileButtonPressed = [
    ShadowSpec(dx: 0, dy: 1, blur: 3, colorArgb: 0xCC000000),
    ShadowSpec(dx: 0, dy: 2, blur: 4, colorArgb: 0x66000000, inset: true),
  ];

  /// Concave well (D-pad chassis, rocker rail).
  static const List<ShadowSpec> hardwareRecess = [
    ShadowSpec(dx: 0, dy: 2, blur: 5, colorArgb: 0xCC000000, inset: true),
    ShadowSpec(dx: 0, dy: -1, blur: 1, colorArgb: 0x0DFFFFFF, inset: true),
  ];

  static const List<ShadowSpec> rockerWell = [
    ShadowSpec(dx: 0, dy: 2, blur: 6, colorArgb: 0xBF000000, inset: true),
    ShadowSpec(dx: 0, dy: 1, blur: 0, colorArgb: 0x0DFFFFFF),
  ];

  /// Active IR firing rim glow (beam cyan).
  static const List<ShadowSpec> irGlowActive = [
    ShadowSpec(dx: 0, dy: 0, blur: 18, colorArgb: 0x7300E5FF), // 0.45
    ShadowSpec(dx: 0, dy: 0, blur: 10, colorArgb: 0x4000E5FF, inset: true), // 0.25
  ];

  /// Power button glow (crimson).
  static const List<ShadowSpec> powerGlow = [
    ShadowSpec(dx: 0, dy: 0, blur: 16, colorArgb: 0x66EF4444), // 0.4
    ShadowSpec(dx: 0, dy: 1, blur: 0, colorArgb: 0x33FFFFFF, inset: true),
  ];

  /// D-pad OK center glow (beam cyan).
  static const List<ShadowSpec> dpadCenterGlow = [
    ShadowSpec(dx: 0, dy: 0, blur: 20, colorArgb: 0x5900E5FF), // 0.35
    ShadowSpec(dx: 0, dy: 1, blur: 2, colorArgb: 0x4DFFFFFF, inset: true),
  ];
}
