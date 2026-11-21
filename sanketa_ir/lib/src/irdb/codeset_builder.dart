/// Builds [IrCodeset] instances from parsed IR signals.
///
/// Takes a list of [ParsedSignal] records (from any parser — Flipper, LIRC,
/// community captures) and resolves them into an [IrCodeset] by mapping button
/// names to canonical [Key] values and converting protocols.
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';
import 'brand_map.dart';
import 'flipper_ir_parser.dart';
import 'key_name_map.dart';
import 'lirc_parser.dart';

class CodesetBuilder {
  /// Build an [IrCodeset] from parsed signals, inferring brand/type from names.
  ///
  /// [id] is the unique codeset identifier (e.g. file path or hash).
  /// [brandName] is the brand string from directory structure or metadata.
  /// [category] is the device category (e.g. "TVs", "ACs").
  /// [modelName] is an optional display name for the codeset.
  static IrCodeset build({
    required String id,
    required String brandName,
    required String category,
    required List<ParsedSignal> signals,
    String? modelName,
  }) {
    final keys = <Key, IrCommand>{};

    for (final signal in signals) {
      final key = resolveKeyName(signal.name);
      if (key == null) continue;
      if (keys.containsKey(key)) continue;

      final command = _toCommand(signal);
      if (command != null) keys[key] = command;
    }

    return IrCodeset(
      id: id,
      brand: resolveBrand(brandName),
      deviceType: resolveDeviceType(category),
      name: modelName ?? '$brandName ${_cleanModelName(id)}',
      brandName: brandName,
      keys: keys,
    );
  }

  /// Build from a Flipper IRDB file using its directory path for metadata.
  ///
  /// Expected path structure: `<Category>/<Brand>/<Model>.ir`
  static IrCodeset? fromFlipperFile({
    required String relativePath,
    required String content,
  }) {
    final signals = parseFlipperIr(content);
    if (signals.isEmpty) return null;

    final parts = relativePath.replaceAll('\\', '/').split('/');
    if (parts.length < 3) return null;

    // Flipper IRDB permits optional series folders between brand and model:
    // <Category>/<Brand>/<Series...>/<Model>.ir. Metadata always comes from
    // the first two segments, not the two directories nearest the file.
    final category = parts[0];
    final brand = parts[1];
    if (tryResolveDeviceType(category) == null) return null;
    final fileName = parts.last.replaceAll('.ir', '');
    final pathHash =
        _fnv1a32(relativePath.toLowerCase()).toRadixString(16).padLeft(8, '0');
    final modelSlug = _slugify(fileName);
    final shortModel = modelSlug.length <= 48
        ? modelSlug
        : modelSlug.substring(0, 48).replaceFirst(RegExp(r'_+$'), '');

    return build(
      id: 'flipper_${_slugify(category)}_${_slugify(brand)}_${shortModel}_$pathHash',
      brandName: brand,
      category: category,
      signals: signals,
      modelName: _humanize(fileName),
    );
  }

  /// Build from a LIRC conf file.
  static List<IrCodeset> fromLircFile({
    required String content,
    String category = 'TVs',
    String? brandHint,
  }) {
    final remotes = parseLircConf(content);
    final result = <IrCodeset>[];
    for (final r in remotes) {
      final cs = build(
        id: 'lirc_${_slugify(r.name)}',
        brandName: brandHint ?? _guessBrandFromName(r.name),
        category: category,
        signals: r.signals,
        modelName: r.name,
      );
      if (cs.keys.isNotEmpty) result.add(cs);
    }
    return result;
  }

  /// Build from user-captured signals (community capture).
  static IrCodeset fromCapture({
    required String deviceName,
    required String brandName,
    required DeviceType deviceType,
    required Map<Key, ParsedSignal> capturedKeys,
  }) {
    final keys = <Key, IrCommand>{};
    for (final entry in capturedKeys.entries) {
      final cmd = _toCommand(entry.value);
      if (cmd != null) keys[entry.key] = cmd;
    }
    return IrCodeset(
      id: 'capture_${_slugify(deviceName)}_${DateTime.now().millisecondsSinceEpoch}',
      brand: resolveBrand(brandName),
      deviceType: deviceType,
      name: deviceName,
      brandName: brandName,
      keys: keys,
    );
  }
}

IrCommand? _toCommand(ParsedSignal signal) {
  if (signal.isParsed) {
    return IrCommand(
      protocol: signal.protocol!,
      address: signal.address ?? 0,
      command: signal.command ?? 0,
    );
  }
  if (signal.isRaw) {
    return IrCommand(
      protocol: IrProtocol.raw,
      raw: signal.rawData,
      carrierHzOverride: signal.frequency,
    );
  }
  return null;
}

String _slugify(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

int _fnv1a32(String value) {
  var hash = 0x811c9dc5;
  for (final byte in value.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

String _cleanModelName(String id) {
  final last = id.split(RegExp(r'[/\\]')).last;
  return last.replaceAll(RegExp(r'[_\-]+'), ' ').replaceAll('.ir', '').trim();
}

String _humanize(String fileName) =>
    fileName.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

String _guessBrandFromName(String name) {
  final parts = name.split(RegExp(r'[\s_\-]+'));
  return parts.isNotEmpty ? parts.first : 'Unknown';
}
