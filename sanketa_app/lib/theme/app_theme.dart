import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import 'tokens_x.dart';

/// The OmniBeam dark theme, seeded from the beam-cyan primary.
ThemeData sanketaDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: hex(AppColors.primaryContainer),
    brightness: Brightness.dark,
  ).copyWith(
    surface: hex(AppColors.surface),
    onSurface: hex(AppColors.onSurface),
    primary: hex(AppColors.primaryContainer),
    onPrimary: hex(AppColors.onPrimaryContainer),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: hex(AppColors.background),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
