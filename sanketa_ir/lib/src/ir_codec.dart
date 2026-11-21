/// IR encoders — compile an [IrCommand] into an [IrSignal].
///
/// Each protocol's timings follow its published spec. Durations are in
/// microseconds; every pattern starts with a mark (IR on) so it can go straight
/// to `ConsumerIrManager.transmit`. Bit order and modulation differ per family:
///   NEC / NEC-ext / Samsung : pulse-distance, LSB first (space encodes the bit)
///   Sony SIRC               : pulse-width,    LSB first (mark encodes the bit)
///   RC5                     : Manchester,     MSB first
library;

import 'ir_signal.dart';

class IrCodec {
  const IrCodec();

  IrSignal encode(IrCommand cmd) {
    if (cmd.carrierHzOverride != null && cmd.carrierHzOverride! <= 0) {
      throw ArgumentError.value(
          cmd.carrierHzOverride, 'carrierHzOverride', 'must be positive');
    }
    if (cmd.protocol == IrProtocol.raw) {
      final raw = cmd.raw;
      if (raw == null || raw.isEmpty || raw.any((duration) => duration <= 0)) {
        throw ArgumentError.value(
            raw, 'raw', 'must contain positive pulse durations');
      }
    }
    if (cmd.carrierHzOverride != null && cmd.protocol != IrProtocol.raw) {
      // Honour a carrier override by recompiling then swapping the carrier.
      final base = _encode(cmd);
      return IrSignal(
        carrierHz: cmd.carrierHzOverride!,
        pattern: base.pattern,
        repeat: base.repeat,
      );
    }
    return _encode(cmd);
  }

  IrSignal _encode(IrCommand cmd) => switch (cmd.protocol) {
        IrProtocol.nec => _nec(cmd.address, cmd.command),
        IrProtocol.necExtended =>
          _nec(cmd.address, cmd.command, extended: true),
        IrProtocol.samsung => _samsung(cmd.address, cmd.command),
        IrProtocol.sonySirc12 =>
          _sirc(cmd.address, cmd.command, addressBits: 5),
        IrProtocol.sonySirc15 =>
          _sirc(cmd.address, cmd.command, addressBits: 8),
        IrProtocol.sonySirc20 =>
          _sirc(cmd.address, cmd.command, addressBits: 13),
        IrProtocol.rc5 => _rc5(cmd.address, cmd.command, toggle: cmd.toggle),
        IrProtocol.raw => IrSignal(
            carrierHz: cmd.carrierHzOverride ?? 38000,
            pattern: List<int>.unmodifiable(cmd.raw ?? const <int>[]),
          ),
      };
}

// --- NEC family (and NEC-extended) -------------------------------------------
// 38 kHz. Header 9000/4500. Bit: 560 mark; space 560 (0) or 1690 (1).
// Standard NEC: address, ~address, command, ~command (all LSB first).
// Extended NEC: addrLow, addrHigh, command, ~command (address not complemented).
IrSignal _nec(int address, int command, {bool extended = false}) {
  const hdrMark = 9000, hdrSpace = 4500;
  const bitMark = 560, zeroSpace = 560, oneSpace = 1690;

  final bytes = extended
      ? [address & 0xFF, (address >> 8) & 0xFF, command & 0xFF, ~command & 0xFF]
      : [address & 0xFF, ~address & 0xFF, command & 0xFF, ~command & 0xFF];

  final pattern = <int>[hdrMark, hdrSpace];
  for (final b in bytes) {
    _appendPulseDistanceByte(pattern, b, bitMark, zeroSpace, oneSpace);
  }
  pattern.add(bitMark); // stop bit

  // NEC repeat: 9000 mark, 2250 space, 560 mark.
  return IrSignal(
    carrierHz: 38000,
    pattern: pattern,
    repeat: const [9000, 2250, bitMark],
  );
}

// --- Samsung -----------------------------------------------------------------
// 38 kHz. Header 4500/4500 (equal, unlike NEC). Same bit timings as NEC.
// Frame: custom(8), custom(8 repeated — NOT complemented), data(8), ~data(8).
IrSignal _samsung(int address, int command) {
  const hdrMark = 4500, hdrSpace = 4500;
  const bitMark = 560, zeroSpace = 560, oneSpace = 1690;

  final bytes = [
    address & 0xFF,
    address & 0xFF,
    command & 0xFF,
    ~command & 0xFF,
  ];

  final pattern = <int>[hdrMark, hdrSpace];
  for (final b in bytes) {
    _appendPulseDistanceByte(pattern, b, bitMark, zeroSpace, oneSpace);
  }
  pattern.add(bitMark);

  return IrSignal(
    carrierHz: 38000,
    pattern: pattern,
    repeat: List<int>.unmodifiable(pattern),
  );
}

// --- Sony SIRC (12 / 15 / 20-bit) --------------------------------------------
// 40 kHz. Header 2400 mark, 600 space. Bit: mark 1200 (1) / 600 (0), space 600.
// Command 7 bits then address N bits, both LSB first. Sony frames are meant to
// be sent 3× at ~45 ms; the transmitter/hold logic handles repetition.
IrSignal _sirc(int address, int command, {required int addressBits}) {
  const headerMark = 2400, gap = 600, oneMark = 1200, zeroMark = 600;

  final pattern = <int>[headerMark, gap];
  void appendBits(int value, int bits) {
    for (var i = 0; i < bits; i++) {
      final bit = (value >> i) & 1;
      pattern.add(bit == 1 ? oneMark : zeroMark);
      pattern.add(gap);
    }
  }

  appendBits(command, 7);
  appendBits(address, addressBits);

  return IrSignal(carrierHz: 40000, pattern: pattern);
}

// --- Philips RC5 -------------------------------------------------------------
// 36 kHz. Manchester, half-bit 889 µs. 14 bits, MSB first:
//   S1(=1), S2(=1), toggle, address(5), command(6).
// RC5 convention: logical 1 = space→mark, logical 0 = mark→space.
IrSignal _rc5(int address, int command, {required bool toggle}) {
  const half = 889;

  final bits = <int>[
    1, // start 1
    1, // start 2 (field bit; 1 for commands 0..63)
    toggle ? 1 : 0,
    ..._msbBits(address & 0x1F, 5),
    ..._msbBits(command & 0x3F, 6),
  ];

  // Emit Manchester half-bits, coalescing runs of the same level.
  final levels = <bool>[]; // true = mark (on)
  final durs = <int>[];
  void push(bool on, int d) {
    if (levels.isNotEmpty && levels.last == on) {
      durs[durs.length - 1] += d;
    } else {
      levels.add(on);
      durs.add(d);
    }
  }

  for (final bit in bits) {
    if (bit == 1) {
      push(false, half); // space then mark
      push(true, half);
    } else {
      push(true, half); // mark then space
      push(false, half);
    }
  }

  // Transmission begins at the first mark; a leading space is just pre-idle.
  final start = levels.first ? 0 : 1;
  final pattern = durs.sublist(start);

  return IrSignal(carrierHz: 36000, pattern: pattern);
}

// --- helpers -----------------------------------------------------------------

void _appendPulseDistanceByte(
  List<int> pattern,
  int b,
  int bitMark,
  int zeroSpace,
  int oneSpace,
) {
  for (var i = 0; i < 8; i++) {
    // LSB first
    final bit = (b >> i) & 1;
    pattern.add(bitMark);
    pattern.add(bit == 1 ? oneSpace : zeroSpace);
  }
}

List<int> _msbBits(int value, int bits) => [
      for (var i = bits - 1; i >= 0; i--) (value >> i) & 1,
    ];
