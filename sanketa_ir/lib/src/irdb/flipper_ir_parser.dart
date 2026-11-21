/// Parses Flipper Zero `.ir` files into [ParsedSignal] records.
///
/// The Flipper IR file format (Version 1) is line-oriented plain text:
///
/// ```
/// Filetype: IR signals file
/// Version: 1
/// # comment
/// name: Power
/// type: parsed
/// protocol: NEC
/// address: 04 00 00 00
/// command: 08 00 00 00
/// #
/// name: Vol_up
/// type: raw
/// frequency: 38000
/// duty_cycle: 0.330000
/// data: 9024 4512 564 564 ...
/// ```
///
/// `parsed` entries give protocol + address + command (4-byte LE hex ints).
/// `raw` entries give carrier frequency + mark/space microsecond timings.
///
/// This parser is source-agnostic: it produces [ParsedSignal] records that
/// [CodesetBuilder] converts into [IrCodeset] instances.
library;

import '../ir_signal.dart';

class ParsedSignal {
  const ParsedSignal({
    required this.name,
    this.protocol,
    this.address,
    this.command,
    this.frequency,
    this.rawData,
  });

  final String name;
  final IrProtocol? protocol;
  final int? address;
  final int? command;
  final int? frequency;
  final List<int>? rawData;

  bool get isParsed => protocol != null && protocol != IrProtocol.raw;
  bool get isRaw => rawData != null;
}

/// Parse a Flipper `.ir` file's text content into a list of signals.
List<ParsedSignal> parseFlipperIr(String content) {
  final signals = <ParsedSignal>[];
  final lines = content.split('\n');

  String? name;
  String? type;
  String? protocolStr;
  String? addressHex;
  String? commandHex;
  int? frequency;
  List<int>? rawData;

  void flush() {
    if (name == null) return;
    if (type == 'parsed' && protocolStr != null) {
      final proto = _mapProtocol(protocolStr!);
      final addr = addressHex != null ? _parseFlipperHex(addressHex!) : null;
      final cmd = commandHex != null ? _parseFlipperHex(commandHex!) : null;
      if (proto != null && addr != null && cmd != null) {
        signals.add(ParsedSignal(
          name: name!,
          protocol: proto,
          address: addr,
          command: cmd,
        ));
      }
    } else if (type == 'raw' &&
        rawData != null &&
        rawData!.isNotEmpty &&
        rawData!.every((duration) => duration > 0) &&
        (frequency == null || frequency! > 0)) {
      signals.add(ParsedSignal(
        name: name!,
        protocol: IrProtocol.raw,
        frequency: frequency ?? 38000,
        rawData: rawData,
      ));
    }
    name = null;
    type = null;
    protocolStr = null;
    addressHex = null;
    commandHex = null;
    frequency = null;
    rawData = null;
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed == '#') continue;
    if (trimmed.startsWith('#')) continue;
    if (trimmed.startsWith('Filetype:') || trimmed.startsWith('Version:')) {
      continue;
    }

    final colonIdx = trimmed.indexOf(':');
    if (colonIdx < 0) continue;
    final key = trimmed.substring(0, colonIdx).trim().toLowerCase();
    final value = trimmed.substring(colonIdx + 1).trim();

    switch (key) {
      case 'name':
        flush();
        name = value;
      case 'type':
        type = value.toLowerCase();
      case 'protocol':
        protocolStr = value;
      case 'address':
        addressHex = value;
      case 'command':
        commandHex = value;
      case 'frequency':
        frequency = int.tryParse(value);
      case 'data':
        final values = value
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .map(int.tryParse)
            .toList();
        rawData = values.every((duration) => duration != null && duration > 0)
            ? values.cast<int>()
            : null;
    }
  }
  flush();
  return signals;
}

/// Parse Flipper's 4-byte little-endian hex integer format.
/// `"04 00 00 00"` → 4, `"A4 00 00 00"` → 164.
int? _parseFlipperHex(String hex) {
  final bytes = hex.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (bytes.isEmpty || bytes.length > 4) return null;
  var result = 0;
  for (var i = 0; i < bytes.length; i++) {
    final byte = int.tryParse(bytes[i], radix: 16);
    if (byte == null || byte < 0 || byte > 0xff) return null;
    result |= byte << (i * 8);
  }
  return result;
}

/// Map Flipper protocol name to our [IrProtocol], or `null` if unsupported.
IrProtocol? _mapProtocol(String flipperProtocol) =>
    switch (flipperProtocol.toUpperCase()) {
      'NEC' => IrProtocol.nec,
      'NECEXT' || 'NEC42' || 'NEC42EXT' || 'NECF' => IrProtocol.necExtended,
      'SAMSUNG32' || 'SAMSUNG' => IrProtocol.samsung,
      'SIRC' => IrProtocol.sonySirc12,
      'SIRC15' => IrProtocol.sonySirc15,
      'SIRC20' => IrProtocol.sonySirc20,
      'RC5' || 'RC5X' => IrProtocol.rc5,
      _ => null,
    };
