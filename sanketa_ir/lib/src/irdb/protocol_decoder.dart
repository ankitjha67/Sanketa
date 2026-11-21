/// Decodes raw IR timing patterns back into protocol + address + command.
///
/// When a user captures an IR signal from their physical remote (community
/// capture flow), the phone records raw mark/space timings. This decoder
/// identifies the protocol and extracts the address/command so the signal
/// can be stored as a compact parsed entry rather than raw microsecond data.
library;

import '../ir_signal.dart';
import 'flipper_ir_parser.dart';

/// Attempt to decode a raw timing pattern into a parsed signal.
///
/// Returns a [ParsedSignal] with protocol/address/command set if decoding
/// succeeds, or a raw-type signal if no known protocol matches.
ParsedSignal decodeRawPattern({
  required String name,
  required int carrierHz,
  required List<int> pattern,
}) {
  if (carrierHz <= 0 ||
      pattern.length < 6 ||
      pattern.any((value) => value <= 0)) {
    return ParsedSignal(
        name: name,
        protocol: IrProtocol.raw,
        frequency: carrierHz,
        rawData: pattern);
  }

  final result = _tryNec(pattern) ??
      _trySamsung(pattern) ??
      _trySirc(pattern, carrierHz) ??
      _tryRc5(pattern, carrierHz);

  if (result != null) {
    return ParsedSignal(
      name: name,
      protocol: result.protocol,
      address: result.address,
      command: result.command,
    );
  }

  return ParsedSignal(
    name: name,
    protocol: IrProtocol.raw,
    frequency: carrierHz,
    rawData: pattern,
  );
}

class _DecodedResult {
  const _DecodedResult(this.protocol, this.address, this.command);
  final IrProtocol protocol;
  final int address;
  final int command;
}

bool _near(int actual, int expected, {int tolerance = 200}) =>
    (actual - expected).abs() <= tolerance;

_DecodedResult? _tryNec(List<int> p) {
  if (p.length < 67) return null;
  if (!_near(p[0], 9000, tolerance: 1000)) return null;
  if (!_near(p[1], 4500, tolerance: 1000)) return null;

  final bytes = <int>[];
  for (var byteIdx = 0; byteIdx < 4; byteIdx++) {
    var b = 0;
    for (var bit = 0; bit < 8; bit++) {
      final idx = 2 + byteIdx * 16 + bit * 2 + 1; // space index
      if (idx >= p.length) return null;
      if (p[idx] > 1000) b |= (1 << bit);
    }
    bytes.add(b);
  }

  if (bytes[2] == (~bytes[3] & 0xFF)) {
    if (bytes[0] == (~bytes[1] & 0xFF)) {
      return _DecodedResult(IrProtocol.nec, bytes[0], bytes[2]);
    }
    return _DecodedResult(
        IrProtocol.necExtended, bytes[0] | (bytes[1] << 8), bytes[2]);
  }
  return null;
}

_DecodedResult? _trySamsung(List<int> p) {
  if (p.length < 67) return null;
  if (!_near(p[0], 4500, tolerance: 800)) return null;
  if (!_near(p[1], 4500, tolerance: 800)) return null;
  if (_near(p[0], 9000, tolerance: 1000)) return null;

  final bytes = <int>[];
  for (var byteIdx = 0; byteIdx < 4; byteIdx++) {
    var b = 0;
    for (var bit = 0; bit < 8; bit++) {
      final idx = 2 + byteIdx * 16 + bit * 2 + 1;
      if (idx >= p.length) return null;
      if (p[idx] > 1000) b |= (1 << bit);
    }
    bytes.add(b);
  }

  if (bytes[0] == bytes[1] && bytes[2] == (~bytes[3] & 0xFF)) {
    return _DecodedResult(IrProtocol.samsung, bytes[0], bytes[2]);
  }
  return null;
}

_DecodedResult? _trySirc(List<int> p, int carrier) {
  if (carrier < 39000 || carrier > 41000) return null;
  if (p.length < 25) return null;
  if (!_near(p[0], 2400, tolerance: 400)) return null;
  if (!_near(p[1], 600, tolerance: 200)) return null;

  if ((p.length - 2).isOdd) return null;
  final totalBits = (p.length - 2) ~/ 2;
  if (totalBits != 12 && totalBits != 15 && totalBits != 20) return null;

  var value = 0;
  for (var i = 0; i < totalBits; i++) {
    final markIdx = 2 + i * 2;
    if (markIdx >= p.length) break;
    if (p[markIdx] > 900) value |= (1 << i);
  }

  final command = value & 0x7F;
  final addressBits = totalBits - 7;
  final address = (value >> 7) & ((1 << addressBits) - 1);

  final protocol = switch (totalBits) {
    12 => IrProtocol.sonySirc12,
    15 => IrProtocol.sonySirc15,
    20 => IrProtocol.sonySirc20,
    _ => throw StateError('validated SIRC bit count changed unexpectedly'),
  };

  return _DecodedResult(protocol, address, command);
}

_DecodedResult? _tryRc5(List<int> p, int carrier) {
  if (carrier < 35000 || carrier > 37000) return null;
  if (p.length < 10) return null;

  const half = 889;
  final bits = <int>[];
  var pos = 0;

  while (pos < p.length && bits.length < 14) {
    final dur = p[pos];
    final isDouble = _near(dur, half * 2, tolerance: 300);
    final isSingle = _near(dur, half, tolerance: 200);

    if (!isDouble && !isSingle) break;

    if (isSingle) {
      bits.add(pos.isEven ? 0 : 1);
      pos++;
    } else {
      bits.add(pos.isEven ? 0 : 1);
      bits.add(pos.isEven ? 0 : 1);
      pos++;
    }
  }

  if (bits.length != 14) return null;

  var address = 0;
  var command = 0;
  for (var i = 3; i < 8; i++) {
    address = (address << 1) | bits[i];
  }
  for (var i = 8; i < 14; i++) {
    command = (command << 1) | bits[i];
  }

  return _DecodedResult(IrProtocol.rc5, address, command);
}
