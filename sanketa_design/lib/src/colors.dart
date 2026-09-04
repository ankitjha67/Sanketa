/// OmniBeam colour tokens, as 0xAARRGGBB ints (Flutter wraps them in `Color`).
///
/// The authoritative values are the Tailwind config in design/code.html (what
/// the mockup actually renders with). Semantic accent aliases at the bottom name
/// the roles the design prose calls out (Beam Cyan, Stream Violet, …).
library;

class AppColors {
  const AppColors._();

  // --- Surfaces (deep, cinema-grade dark) ---
  static const int background = 0xFF10131A;
  static const int surface = 0xFF10131A;
  static const int surfaceDim = 0xFF10131A;
  static const int surfaceBright = 0xFF363941;
  static const int surfaceContainerLowest = 0xFF0B0E15;
  static const int surfaceContainerLow = 0xFF191B23;
  static const int surfaceContainer = 0xFF1D1F27;
  static const int surfaceContainerHigh = 0xFF272A32;
  static const int surfaceContainerHighest = 0xFF32353D;
  static const int surfaceVariant = 0xFF32353D;

  // --- Foregrounds ---
  static const int onSurface = 0xFFE1E2EC;
  static const int onSurfaceVariant = 0xFFBAC9CC;
  static const int onBackground = 0xFFE1E2EC;
  static const int inverseSurface = 0xFFE1E2EC;
  static const int inverseOnSurface = 0xFF2D3038;
  static const int outline = 0xFF849396;
  static const int outlineVariant = 0xFF3B494C;

  // --- Primary (Beam Cyan) ---
  static const int primary = 0xFFC3F5FF;
  static const int onPrimary = 0xFF00363D;
  static const int primaryContainer = 0xFF00E5FF; // beam cyan
  static const int onPrimaryContainer = 0xFF00626E;
  static const int inversePrimary = 0xFF006875;
  static const int surfaceTint = 0xFF00DAF3;
  static const int primaryFixed = 0xFF9CF0FF;
  static const int primaryFixedDim = 0xFF00DAF3;
  static const int onPrimaryFixed = 0xFF001F24;
  static const int onPrimaryFixedVariant = 0xFF004F58;

  // --- Secondary (Stream Violet) ---
  static const int secondary = 0xFFC0C1FF;
  static const int onSecondary = 0xFF1000A9;
  static const int secondaryContainer = 0xFF3131C0;
  static const int onSecondaryContainer = 0xFFB0B2FF;
  static const int secondaryFixed = 0xFFE1E0FF;
  static const int secondaryFixedDim = 0xFFC0C1FF;
  static const int onSecondaryFixed = 0xFF07006C;
  static const int onSecondaryFixedVariant = 0xFF2F2EBE;

  // --- Tertiary (Signal Emerald) ---
  static const int tertiary = 0xFFA8FFD2;
  static const int onTertiary = 0xFF003824;
  static const int tertiaryContainer = 0xFF5BE9AD;
  static const int onTertiaryContainer = 0xFF006645;
  static const int tertiaryFixed = 0xFF6FFBBE;
  static const int tertiaryFixedDim = 0xFF4EDEA3;
  static const int onTertiaryFixed = 0xFF002113;
  static const int onTertiaryFixedVariant = 0xFF005236;

  // --- Error / alerts ---
  static const int error = 0xFFFFB4AB;
  static const int onError = 0xFF690005;
  static const int errorContainer = 0xFF93000A;
  static const int onErrorContainer = 0xFFFFDAD6;

  // --- Semantic accents (design prose + CSS effect colours) ---
  static const int beamCyan = 0xFF00E5FF; // IR transmit / active
  static const int streamViolet = 0xFF6366F1; // Wi-Fi / cast protocols
  static const int signalEmerald = 0xFF10B981; // heartbeat / verified
  static const int alertAmber = 0xFFF59E0B; // packet drops / warnings
  static const int alertCrimson = 0xFFEF4444; // power-off / destructive

  // --- Streaming brand marks (app shortcut row) ---
  static const int netflix = 0xFFE50914;
  static const int youTube = 0xFFFF0000;
  static const int prime = 0xFF00A8E1;
  static const int disney = 0xFF113CCF;
}
