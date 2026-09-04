/// Air-conditioner state (PRD FR-2.5).
///
/// AC IR is *stateful*: unlike a TV where each key is one code, an AC transmits
/// its whole state — power, mode, temperature, fan, swing — in every frame. So
/// the model is a full state object, and each user action mutates it and re-emits
/// the complete frame. Because IR is one-way the app mirrors this state
/// best-effort with a "state may drift" disclaimer.
library;

enum AcMode { auto, cool, dry, fan, heat }

enum AcFan { auto, low, medium, high }

class AcState {
  const AcState({
    this.power = true,
    this.mode = AcMode.cool,
    this.tempC = 24,
    this.fan = AcFan.auto,
    this.swing = false,
  });

  final bool power;
  final AcMode mode;
  final int tempC;
  final AcFan fan;
  final bool swing;

  AcState copyWith({
    bool? power,
    AcMode? mode,
    int? tempC,
    AcFan? fan,
    bool? swing,
  }) =>
      AcState(
        power: power ?? this.power,
        mode: mode ?? this.mode,
        tempC: tempC ?? this.tempC,
        fan: fan ?? this.fan,
        swing: swing ?? this.swing,
      );

  @override
  String toString() =>
      'AcState(power: $power, mode: ${mode.name}, ${tempC}C, fan: ${fan.name}, swing: $swing)';
}
