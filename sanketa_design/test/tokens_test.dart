import 'package:sanketa_design/sanketa_design.dart';
import 'package:test/test.dart';

void main() {
  group('colours match design/code.html Tailwind config', () {
    test('surfaces', () {
      expect(AppColors.background, 0xFF10131A);
      expect(AppColors.surfaceContainerLowest, 0xFF0B0E15);
      expect(AppColors.surfaceContainerHigh, 0xFF272A32);
    });
    test('beam cyan primary-container is the signature accent', () {
      expect(AppColors.primaryContainer, 0xFF00E5FF);
      expect(AppColors.beamCyan, 0xFF00E5FF);
    });
    test('semantic accents', () {
      expect(AppColors.streamViolet, 0xFF6366F1);
      expect(AppColors.signalEmerald, 0xFF10B981);
      expect(AppColors.alertCrimson, 0xFFEF4444);
    });
    test('brand marks for the app shortcut row', () {
      expect(AppColors.netflix, 0xFFE50914);
      expect(AppColors.disney, 0xFF113CCF);
    });
    test('every colour token is fully opaque (alpha 0xFF)', () {
      for (final c in [
        AppColors.background,
        AppColors.primaryContainer,
        AppColors.onSurface,
        AppColors.error,
        AppColors.streamViolet,
      ]) {
        expect((c >> 24) & 0xFF, 0xFF);
      }
    });
  });

  group('typography', () {
    test('headline-xl is 36/44 Plus Jakarta 800', () {
      expect(AppType.headlineXl.sizePx, 36);
      expect(AppType.headlineXl.heightPx, 44);
      expect(AppType.headlineXl.weight, 800);
      expect(AppType.headlineXl.family, 'Plus Jakarta Sans');
    });
    test('mono labels use JetBrains Mono with positive tracking', () {
      expect(AppType.labelMonoSm.family, 'JetBrains Mono');
      expect(AppType.labelMonoSm.letterSpacingEm, greaterThan(0));
    });
    test('heightMultiple converts px line-height to a ratio', () {
      expect(AppType.bodyMd.heightMultiple, closeTo(20 / 14, 1e-9));
    });
  });

  group('dimensions', () {
    test('touch target minimum is 48px', () {
      expect(AppSpacing.touchTargetMin, 48);
    });
    test('remote shell radius is 24px (xl)', () {
      expect(AppRadii.xl, 24);
    });
  });

  group('elevation', () {
    test('tactile button has an outer drop shadow and an inset highlight', () {
      const layers = AppElevation.tactileButton;
      expect(layers.any((s) => !s.inset), isTrue);
      expect(layers.any((s) => s.inset), isTrue);
    });
    test('IR glow uses beam cyan', () {
      expect(AppElevation.irGlowActive.first.colorArgb & 0x00FFFFFF, 0x00E5FF);
    });
  });
}
