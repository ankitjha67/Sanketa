import 'package:flutter/services.dart';

/// Centralised haptic feedback for the remote control UI (FR-5.3).
///
/// Every tap, long-press, and swipe gesture routes through this service so the
/// user can enable, disable, or configure the feedback intensity globally from
/// Settings. Zero network calls; runs entirely on the local device.
class HapticService {
  HapticService._();
  static final instance = HapticService._();

  bool _enabled = true;
  HapticIntensity _intensity = HapticIntensity.medium;

  bool get enabled => _enabled;
  HapticIntensity get intensity => _intensity;

  void setEnabled(bool v) => _enabled = v;
  void setIntensity(HapticIntensity v) => _intensity = v;

  /// Light tap — d-pad arrows, minor toggles.
  void tap() {
    if (!_enabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.selectionClick();
      case HapticIntensity.medium:
        HapticFeedback.lightImpact();
      case HapticIntensity.heavy:
        HapticFeedback.mediumImpact();
    }
  }

  /// Confirm action — OK / enter / power toggle.
  void confirm() {
    if (!_enabled) return;
    switch (_intensity) {
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  /// Error / failure — connection lost, command failed.
  void error() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Long-press started — hold key, context menu.
  void longPress() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Swipe gesture — touchpad swipe / channel scroll.
  void swipe() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }
}

enum HapticIntensity { light, medium, heavy }
