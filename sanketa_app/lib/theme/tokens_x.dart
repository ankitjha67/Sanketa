import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanketa_design/sanketa_design.dart';

/// Flutter adapters over the pure-Dart [sanketa_design] tokens.

Color hex(int argb) => Color(argb);

FontWeight fontWeight(int w) => FontWeight.values[(w ~/ 100) - 1];

/// A [TextStyle] from a [TypeSpec], using the correct Google Font family.
TextStyle gfont(TypeSpec s, {Color? color, double? size, FontWeight? weight}) {
  final base = TextStyle(
    fontSize: size ?? s.sizePx,
    fontWeight: weight ?? fontWeight(s.weight),
    height: s.heightMultiple,
    letterSpacing: s.letterSpacingPx,
    color: color,
  );
  return s.family == AppFonts.mono
      ? GoogleFonts.jetBrainsMono(textStyle: base)
      : GoogleFonts.plusJakartaSans(textStyle: base);
}

/// The outer (non-inset) layers of an elevation spec as Flutter [BoxShadow]s.
/// (Flutter has no native inset shadow; inset layers are approximated by fills
/// and borders in the widgets.)
List<BoxShadow> outerShadows(List<ShadowSpec> specs) => [
      for (final s in specs)
        if (!s.inset)
          BoxShadow(
            color: Color(s.colorArgb),
            offset: Offset(s.dx, s.dy),
            blurRadius: s.blur,
            spreadRadius: s.spread,
          ),
    ];
