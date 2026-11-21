/// Parses LIRC remote configuration files into [ParsedSignal] records.
///
/// LIRC format (`lircd.conf`) defines remotes with timing parameters and
/// code tables:
///
/// ```
/// begin remote
///   name  Sony_TV
///   bits  12
///   flags SPACE_ENC|CONST_LENGTH
///   header 2400 600
///   one   1200  600
///   zero   600  600
///   gap   45000
///
///   begin codes
///     KEY_POWER    0x015
///     KEY_VOLUMEUP 0x012
///   end codes
/// end remote
/// ```
///
/// LIRC has dozens of timing modes. This parser handles the three most common:
///   SPACE_ENC (pulse-distance, like NEC/Samsung)
///   SPACE_FIRST (pulse-width, like Sony SIRC)
///   RC5 / RC6 (Manchester)
///
/// Where protocol detection succeeds, signals are stored as parsed commands.
/// Otherwise, the raw timing pattern is reconstructed from the LIRC parameters.
library;

import '../ir_signal.dart';
import 'flipper_ir_parser.dart';

/// A parsed LIRC remote definition containing its signals.
class LircRemote {
  const LircRemote({
    required this.name,
    required this.signals,
    this.brand,
  });

  final String name;
  final String? brand;
  final List<ParsedSignal> signals;
}

/// Parse a LIRC configuration file, which may contain multiple `begin remote`
/// blocks. Returns all remotes found.
List<LircRemote> parseLircConf(String content) {
  final remotes = <LircRemote>[];
  final lines = content.split('\n');

  var inRemote = false;
  var inCodes = false;
  String? remoteName;
  int? bits;
  String? flags;
  List<int>? header;
  List<int>? one;
  List<int>? zero;
  int? frequency;
  final codes = <String, int>{};

  void flush() {
    if (remoteName == null || codes.isEmpty || bits == null || bits! <= 0)
      return;

    final protocol = _detectProtocol(flags, bits, header, one, zero, frequency);
    final signals = <ParsedSignal>[];

    for (final entry in codes.entries) {
      if (protocol != null) {
        final addr = _extractAddress(entry.value, bits ?? 0, protocol);
        final cmd = _extractCommand(entry.value, bits ?? 0, protocol);
        signals.add(ParsedSignal(
          name: entry.key,
          protocol: protocol,
          address: addr,
          command: cmd,
        ));
      } else if (header != null &&
          one != null &&
          zero != null &&
          _validTimingPair(header!) &&
          _validTimingPair(one!) &&
          _validTimingPair(zero!) &&
          (frequency == null || frequency! > 0)) {
        final rawPattern =
            _buildRawPattern(entry.value, bits ?? 0, header!, one!, zero!);
        signals.add(ParsedSignal(
          name: entry.key,
          protocol: IrProtocol.raw,
          frequency: frequency ?? 38000,
          rawData: rawPattern,
        ));
      }
    }

    if (signals.isNotEmpty) {
      remotes.add(LircRemote(name: remoteName!, signals: signals));
    }
  }

  void reset() {
    inRemote = false;
    inCodes = false;
    remoteName = null;
    bits = null;
    flags = null;
    header = null;
    one = null;
    zero = null;
    frequency = null;
    codes.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    if (trimmed == 'begin remote') {
      inRemote = true;
      continue;
    }
    if (trimmed == 'end remote') {
      flush();
      reset();
      continue;
    }
    if (trimmed == 'begin codes') {
      inCodes = true;
      continue;
    }
    if (trimmed == 'end codes') {
      inCodes = false;
      continue;
    }

    if (!inRemote) continue;

    if (inCodes) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final codeName = parts[0];
        final codeValue = _parseHexOrDec(parts[1]);
        if (codeValue != null) codes[codeName] = codeValue;
      }
      continue;
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final key = parts[0].toLowerCase();
    switch (key) {
      case 'name':
        remoteName = parts.sublist(1).join(' ');
      case 'bits':
        bits = int.tryParse(parts[1]);
      case 'flags':
        flags = parts.sublist(1).join('|');
      case 'header':
        if (parts.length >= 3) {
          header = _parseTimingPair(parts[1], parts[2]);
        }
      case 'one':
        if (parts.length >= 3) {
          one = _parseTimingPair(parts[1], parts[2]);
        }
      case 'zero':
        if (parts.length >= 3) {
          zero = _parseTimingPair(parts[1], parts[2]);
        }
      case 'frequency':
        frequency = int.tryParse(parts[1]);
    }
  }

  return remotes;
}

List<int>? _parseTimingPair(String first, String second) {
  final a = int.tryParse(first);
  final b = int.tryParse(second);
  if (a == null || b == null || a <= 0 || b <= 0) return null;
  return [a, b];
}

bool _validTimingPair(List<int> pair) =>
    pair.length == 2 && pair[0] > 0 && pair[1] > 0;

int? _parseHexOrDec(String s) {
  if (s.startsWith('0x') || s.startsWith('0X')) {
    return int.tryParse(s.substring(2), radix: 16);
  }
  return int.tryParse(s);
}

IrProtocol? _detectProtocol(
  String? flags,
  int? bits,
  List<int>? header,
  List<int>? one,
  List<int>? zero,
  int? frequency,
) {
  if (flags == null) return null;
  final f = flags.toUpperCase();

  if (f.contains('RC5') || f.contains('MANCHESTER')) {
    return IrProtocol.rc5;
  }

  final freq = frequency ?? 38000;
  final headerMark = header?[0] ?? 0;

  if (f.contains('SPACE_ENC') || f.contains('PULSE_DIST')) {
    if (bits == 12 && freq >= 39000) return IrProtocol.sonySirc12;
    if (bits == 15 && freq >= 39000) return IrProtocol.sonySirc15;
    if (bits == 20 && freq >= 39000) return IrProtocol.sonySirc20;
    if (headerMark > 8000) return IrProtocol.nec;
    if (headerMark > 4000 && headerMark < 5000) return IrProtocol.samsung;
  }

  return null;
}

int _extractAddress(int code, int bits, IrProtocol protocol) {
  return switch (protocol) {
    IrProtocol.nec => code & 0xFF,
    IrProtocol.necExtended => code & 0xFFFF,
    IrProtocol.samsung => code & 0xFF,
    IrProtocol.sonySirc12 => (code >> 7) & 0x1F,
    IrProtocol.sonySirc15 => (code >> 7) & 0xFF,
    IrProtocol.sonySirc20 => (code >> 7) & 0x1FFF,
    IrProtocol.rc5 => (code >> 6) & 0x1F,
    IrProtocol.raw => 0,
  };
}

int _extractCommand(int code, int bits, IrProtocol protocol) {
  return switch (protocol) {
    IrProtocol.nec => (code >> 8) & 0xFF,
    IrProtocol.necExtended => (code >> 16) & 0xFF,
    IrProtocol.samsung => (code >> 8) & 0xFF,
    IrProtocol.sonySirc12 ||
    IrProtocol.sonySirc15 ||
    IrProtocol.sonySirc20 =>
      code & 0x7F,
    IrProtocol.rc5 => code & 0x3F,
    IrProtocol.raw => code,
  };
}

List<int> _buildRawPattern(
  int code,
  int bits,
  List<int> header,
  List<int> one,
  List<int> zero,
) {
  final pattern = <int>[header[0], header[1]];
  for (var i = bits - 1; i >= 0; i--) {
    final bit = (code >> i) & 1;
    if (bit == 1) {
      pattern.addAll(one);
    } else {
      pattern.addAll(zero);
    }
  }
  pattern.add(one[0]); // stop bit mark
  return pattern;
}
