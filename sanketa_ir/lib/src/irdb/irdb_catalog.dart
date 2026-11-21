/// The IRDB catalog — indexes available IR codesets and supports search.
///
/// At runtime, the catalog is loaded from a prebuilt JSON manifest (built
/// offline from the Flipper IRDB + LIRC + community captures). The app can
/// search by brand, device type, or model name to find matching codesets.
/// Full codeset data is loaded lazily when selected.
library;

import 'dart:convert';

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';
import 'key_name_map.dart';

/// A lightweight catalog entry (no key data, just metadata for search).
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.brand,
    required this.deviceType,
    required this.name,
    required this.source,
    required this.keyCount,
    this.sourceBrand,
  });

  final String id;
  final BrandFamily brand;
  final DeviceType deviceType;
  final String name;
  final IrdbSource source;
  final int keyCount;
  final String? sourceBrand;
  String get brandName => sourceBrand ?? brand.name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand.name,
        'deviceType': deviceType.name,
        'name': name,
        'source': source.name,
        'keyCount': keyCount,
        if (sourceBrand != null) 'brandName': sourceBrand,
      };

  factory CatalogEntry.fromJson(Map<String, dynamic> json) => CatalogEntry(
        id: json['id'] as String,
        brand: BrandFamily.values.firstWhere(
          (b) => b.name == json['brand'],
          orElse: () => BrandFamily.genericIr,
        ),
        deviceType: DeviceType.values.firstWhere(
          (d) => d.name == json['deviceType'],
          orElse: () => DeviceType.tv,
        ),
        name: json['name'] as String,
        source: IrdbSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => IrdbSource.flipperIrdb,
        ),
        keyCount: json['keyCount'] as int,
        sourceBrand: json['brandName'] as String?,
      );
}

enum IrdbSource {
  flipperIrdb,
  kookong,
  lirc,
  communityCapture,
  bundled,
}

/// Serializable representation of a full codeset (metadata + key data).
class SerializedCodeset {
  const SerializedCodeset({
    required this.entry,
    required this.keys,
  });

  final CatalogEntry entry;
  final Map<String, SerializedCommand> keys;

  Map<String, dynamic> toJson() => {
        ...entry.toJson(),
        'keys': keys.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory SerializedCodeset.fromJson(Map<String, dynamic> json) {
    final keysMap = (json['keys'] as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, SerializedCommand.fromJson(v as Map<String, dynamic>)),
    );
    return SerializedCodeset(
      entry: CatalogEntry.fromJson(json),
      keys: keysMap,
    );
  }

  IrCodeset toCodeset() {
    final resolvedKeys = <Key, IrCommand>{};
    for (final entry in keys.entries) {
      final key = resolveKeyName(entry.key);
      if (key != null) {
        resolvedKeys[key] = entry.value.toCommand();
      }
    }
    return IrCodeset(
      id: entry.id,
      brand: entry.brand,
      deviceType: entry.deviceType,
      name: entry.name,
      brandName: entry.brandName,
      keys: resolvedKeys,
    );
  }
}

class SerializedCommand {
  const SerializedCommand({
    required this.protocol,
    this.address = 0,
    this.command = 0,
    this.frequency,
    this.raw,
  });

  final String protocol;
  final int address;
  final int command;
  final int? frequency;
  final List<int>? raw;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'p': protocol,
      'a': address,
      'c': command,
    };
    if (frequency != null) m['f'] = frequency;
    if (raw != null) m['r'] = raw;
    return m;
  }

  factory SerializedCommand.fromJson(Map<String, dynamic> json) {
    final protocol = json['p'] as String;
    if (protocol == 'kk') {
      return SerializedCommand(
        protocol: 'raw',
        frequency: json['f'] as int?,
        raw: _expandKookong(
          (json['t'] as List).cast<int>(),
          json['d'] as String,
        ),
      );
    }
    return SerializedCommand(
      protocol: protocol,
      address: json['a'] as int? ?? 0,
      command: json['c'] as int? ?? 0,
      frequency: json['f'] as int?,
      raw: (json['r'] as List?)?.cast<int>(),
    );
  }

  IrCommand toCommand() => IrCommand(
        protocol: _parseProtocol(protocol),
        address: address,
        command: command,
        raw: raw,
        carrierHzOverride: frequency,
      );
}

List<int> _expandKookong(List<int> timing, String dataHex) {
  // timing: [headerMark, headerSpace, bitMark, bit0Space, bit1Space, trailMark]
  final hm = timing[0];
  final hs = timing[1];
  final bm = timing[2];
  final b0s = timing[3];
  final b1s = timing[4];
  final tm = timing[5];

  final pattern = <int>[];
  if (hm > 0) {
    pattern.add(hm);
    pattern.add(hs);
  }

  for (var i = 0; i < dataHex.length; i += 2) {
    final end = (i + 2 <= dataHex.length) ? i + 2 : dataHex.length;
    final byteVal = int.parse(dataHex.substring(i, end), radix: 16);
    for (var bit = 7; bit >= 0; bit--) {
      pattern.add(bm);
      pattern.add(((byteVal >> bit) & 1) == 1 ? b1s : b0s);
    }
  }

  pattern.add(tm);
  return pattern;
}

IrProtocol _parseProtocol(String s) => switch (s) {
      'nec' => IrProtocol.nec,
      'necExtended' => IrProtocol.necExtended,
      'samsung' => IrProtocol.samsung,
      'sonySirc12' => IrProtocol.sonySirc12,
      'sonySirc15' => IrProtocol.sonySirc15,
      'sonySirc20' => IrProtocol.sonySirc20,
      'rc5' => IrProtocol.rc5,
      _ => IrProtocol.raw,
    };

/// The in-memory catalog, searchable by brand/type/name.
class IrdbCatalog {
  IrdbCatalog(this._entries);

  final List<CatalogEntry> _entries;

  /// Load from a JSON manifest string.
  factory IrdbCatalog.fromJson(String jsonStr) {
    final list = (jsonDecode(jsonStr) as List)
        .map((e) => CatalogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return IrdbCatalog(list);
  }

  /// All entries.
  List<CatalogEntry> get entries => List.unmodifiable(_entries);

  /// Total count.
  int get length => _entries.length;

  /// Search by device type.
  List<CatalogEntry> byDeviceType(DeviceType type) =>
      _entries.where((e) => e.deviceType == type).toList();

  /// Search by brand.
  List<CatalogEntry> byBrand(BrandFamily brand) =>
      _entries.where((e) => e.brand == brand).toList();

  /// Search by brand and device type.
  List<CatalogEntry> byBrandAndType(BrandFamily brand, DeviceType type) =>
      _entries.where((e) => e.brand == brand && e.deviceType == type).toList();

  /// Free-text search across name and brand.
  List<CatalogEntry> search(String query) {
    final q = query.toLowerCase();
    return _entries.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.brand.name.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q);
    }).toList();
  }

  /// Serialize the catalog to JSON.
  String toJson() => jsonEncode(_entries.map((e) => e.toJson()).toList());

  /// Add a new entry (e.g. from community capture).
  void addEntry(CatalogEntry entry) => _entries.add(entry);

  /// Create a catalog entry from an [IrCodeset].
  static CatalogEntry entryFromCodeset(IrCodeset cs, IrdbSource source) =>
      CatalogEntry(
        id: cs.id,
        brand: cs.brand,
        deviceType: cs.deviceType,
        name: cs.name ?? cs.id,
        source: source,
        keyCount: cs.keys.length,
        sourceBrand: cs.brandName,
      );

  /// Serialize a full codeset for storage/transmission.
  static SerializedCodeset serializeCodeset(
    IrCodeset cs,
    IrdbSource source,
  ) {
    final keys = <String, SerializedCommand>{};
    for (final entry in cs.keys.entries) {
      final cmd = entry.value;
      keys[entry.key.name] = SerializedCommand(
        protocol: cmd.protocol.name,
        address: cmd.address,
        command: cmd.command,
        frequency: cmd.carrierHzOverride,
        raw: cmd.raw,
      );
    }
    return SerializedCodeset(
      entry: entryFromCodeset(cs, source),
      keys: keys,
    );
  }
}
