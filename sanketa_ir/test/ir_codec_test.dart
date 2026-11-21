import 'package:sanketa_ir/sanketa_ir.dart';
import 'package:test/test.dart';

/// Decode a pulse-distance frame (NEC/Samsung) back into its bytes, so we can
/// assert the encoder produced the right bits (LSB first, space encodes bit).
List<int> _decodePulseDistance(List<int> pattern, int numBytes) {
  final bytes = <int>[];
  var idx = 2; // skip header mark + space
  for (var b = 0; b < numBytes; b++) {
    var value = 0;
    for (var i = 0; i < 8; i++) {
      final space = pattern[idx + 1];
      if (space > 1000) value |= 1 << i; // long space = 1
      idx += 2;
    }
    bytes.add(value);
  }
  return bytes;
}

/// Decode a Sony SIRC frame's bits (LSB first, mark encodes bit).
List<int> _decodeSirc(List<int> pattern, int totalBits) {
  final bits = <int>[];
  var idx = 2; // skip header mark + gap
  for (var i = 0; i < totalBits; i++) {
    bits.add(pattern[idx] > 900 ? 1 : 0);
    idx += 2;
  }
  return bits;
}

int _fromBitsLsb(List<int> bits) {
  var v = 0;
  for (var i = 0; i < bits.length; i++) {
    v |= bits[i] << i;
  }
  return v;
}

void main() {
  const codec = IrCodec();

  group('NEC', () {
    test('carrier, header, length, and a repeat frame', () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.nec, address: 0x04, command: 0x08));
      expect(s.carrierHz, 38000);
      expect(s.pattern.take(2).toList(), [9000, 4500]);
      expect(s.pattern.length, 67); // 2 header + 32*2 + 1 stop
      expect(s.repeat, isNotNull);
      expect(s.repeat!.first, 9000);
    });

    test('encodes address, ~address, command, ~command (LSB first)', () {
      const addr = 0x04, cmd = 0x08;
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.nec, address: addr, command: cmd));
      final bytes = _decodePulseDistance(s.pattern, 4);
      expect(bytes[0], addr);
      expect(bytes[1], (~addr) & 0xFF);
      expect(bytes[2], cmd);
      expect(bytes[3], (~cmd) & 0xFF);
    });

    test('extended NEC sends 16-bit address uncomplemented', () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.necExtended, address: 0x20DF, command: 0x10));
      final bytes = _decodePulseDistance(s.pattern, 4);
      expect(bytes[0], 0xDF); // addr low
      expect(bytes[1], 0x20); // addr high
      expect(bytes[2], 0x10);
      expect(bytes[3], (~0x10) & 0xFF);
    });
  });

  group('Samsung', () {
    test('equal 4500/4500 header and customer-code-twice framing', () {
      const addr = 0x07, cmd = 0x02;
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.samsung, address: addr, command: cmd));
      expect(s.carrierHz, 38000);
      expect(s.pattern.take(2).toList(), [4500, 4500]);
      final bytes = _decodePulseDistance(s.pattern, 4);
      expect(bytes[0], addr);
      expect(bytes[1], addr); // repeated, not complemented
      expect(bytes[2], cmd);
      expect(bytes[3], (~cmd) & 0xFF);
      expect(s.repeatFrame, s.pattern);
    });
  });

  group('Sony SIRC', () {
    test('12-bit: carrier 40k, header, 7 command + 5 address bits', () {
      const addr = 1, cmd = 21; // Sony TV power
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.sonySirc12, address: addr, command: cmd));
      expect(s.carrierHz, 40000);
      expect(s.pattern.take(2).toList(), [2400, 600]);
      expect(s.pattern.length, 2 + 12 * 2);

      final bits = _decodeSirc(s.pattern, 12);
      expect(_fromBitsLsb(bits.sublist(0, 7)), cmd);
      expect(_fromBitsLsb(bits.sublist(7, 12)), addr);
    });

    test('20-bit variant carries 13 address bits', () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.sonySirc20, address: 0x1AB, command: 5));
      expect(s.pattern.length, 2 + 20 * 2);
      final bits = _decodeSirc(s.pattern, 20);
      expect(_fromBitsLsb(bits.sublist(0, 7)), 5);
      expect(_fromBitsLsb(bits.sublist(7, 20)), 0x1AB);
    });
  });

  group('RC5', () {
    test('36 kHz, all half-bit multiples, invariant total on-air time', () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.rc5, address: 0x05, command: 0x35));
      expect(s.carrierHz, 36000);
      for (final d in s.pattern) {
        expect(d % 889, 0, reason: 'every RC5 duration is a multiple of 889µs');
      }
      // 14 bits * 1778µs = 24892; the leading idle space (889) is dropped.
      expect(s.pattern.fold<int>(0, (a, b) => a + b), 24892 - 889);
    });

    test('toggle changes the waveform', () {
      final a = codec.encode(const IrCommand(
          protocol: IrProtocol.rc5, address: 5, command: 0x35, toggle: false));
      final b = codec.encode(const IrCommand(
          protocol: IrProtocol.rc5, address: 5, command: 0x35, toggle: true));
      expect(a.pattern, isNot(equals(b.pattern)));
    });
  });

  group('raw and overrides', () {
    test('raw passes the pattern through with its carrier', () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.raw,
          raw: [900, 900, 450, 1350],
          carrierHzOverride: 56000));
      expect(s.carrierHz, 56000);
      expect(s.pattern, [900, 900, 450, 1350]);
    });

    test('carrier override on a real protocol keeps timings, swaps carrier',
        () {
      final s = codec.encode(const IrCommand(
          protocol: IrProtocol.nec,
          address: 1,
          command: 2,
          carrierHzOverride: 56000));
      expect(s.carrierHz, 56000);
      expect(s.pattern.take(2).toList(), [9000, 4500]); // timings unchanged
    });

    test('rejects invalid raw signals and carrier overrides', () {
      expect(
        () => codec.encode(const IrCommand(protocol: IrProtocol.raw)),
        throwsArgumentError,
      );
      expect(
        () => codec.encode(const IrCommand(
            protocol: IrProtocol.raw, raw: [900, 0], carrierHzOverride: 38000)),
        throwsArgumentError,
      );
      expect(
        () => codec.encode(const IrCommand(
            protocol: IrProtocol.nec,
            address: 1,
            command: 2,
            carrierHzOverride: 0)),
        throwsArgumentError,
      );
    });
  });
}
