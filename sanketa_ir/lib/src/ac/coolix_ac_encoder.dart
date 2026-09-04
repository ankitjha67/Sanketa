/// Coolix AC encoder — a widely-cloned generic AC protocol.
///
/// Coolix carries 24 bits of state, transmitted as 3 bytes each followed by its
/// complement (48 bits on the wire) with pulse-distance timing at 38 kHz. The
/// **power-off code (0xB27BE0) and the temperature gray-code table are the
/// documented, verified parts** (asserted in tests). The exact placement of the
/// mode/fan fields within the ON frame is FLAGGED for Phase 0 validation against
/// a real unit — like every other on-device wire detail in this codebase.
library;

import '../ir_signal.dart';
import 'ac_encoder.dart';
import 'ac_state.dart';

class CoolixAcEncoder implements AcEncoder {
  const CoolixAcEncoder();

  @override
  String get protocol => 'coolix';

  @override
  int get minTempC => 17;

  @override
  int get maxTempC => 30;

  /// Documented Coolix power-off command.
  static const int offCode = 0xB27BE0;

  /// Documented Coolix temperature gray-code for 17..30 °C (bits 4-7).
  static const List<int> tempGray = [
    0x0, 0x1, 0x3, 0x2, 0x6, 0x7, 0x5, 0x4, //
    0xC, 0xD, 0x9, 0x8, 0xA, 0xB,
  ];

  /// Assemble the 24-bit state word. OFF is exact; ON-frame field placement is
  /// FLAGGED for Phase 0.
  int buildCode(AcState s) {
    if (!s.power) return offCode;
    var code = 0xB20000; // fixed prefix for a "normal" command
    final t = s.tempC.clamp(minTempC, maxTempC) - minTempC;
    code |= tempGray[t] << 4; // temperature nibble (bits 4-7) — documented
    code |= _modeBits(s.mode) << 2; // FLAGGED placement
    code |= _fanBits(s.fan) << 13; // FLAGGED placement
    if (s.swing) code |= 0x1; // FLAGGED
    return code & 0xFFFFFF;
  }

  @override
  IrSignal encode(AcState state) => _timing(buildCode(state));

  int _modeBits(AcMode m) => switch (m) {
        AcMode.cool => 0,
        AcMode.dry => 1,
        AcMode.auto => 2,
        AcMode.heat => 3,
        AcMode.fan => 2,
      };

  int _fanBits(AcFan f) => switch (f) {
        AcFan.auto => 0,
        AcFan.low => 1,
        AcFan.medium => 2,
        AcFan.high => 3,
      };

  IrSignal _timing(int code) {
    const hdrMark = 4692, hdrSpace = 4416;
    const bitMark = 552, oneSpace = 1656, zeroSpace = 552;

    final p = <int>[hdrMark, hdrSpace];
    for (final shift in [16, 8, 0]) {
      final b = (code >> shift) & 0xFF;
      _appendByteMsb(p, b, bitMark, zeroSpace, oneSpace);
      _appendByteMsb(p, (~b) & 0xFF, bitMark, zeroSpace, oneSpace); // inverse
    }
    p.add(bitMark); // lead-out mark
    return IrSignal(carrierHz: 38000, pattern: p);
  }

  void _appendByteMsb(List<int> p, int b, int mark, int zero, int one) {
    for (var i = 7; i >= 0; i--) {
      final bit = (b >> i) & 1;
      p.add(mark);
      p.add(bit == 1 ? one : zero);
    }
  }
}
