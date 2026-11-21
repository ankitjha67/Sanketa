/// Service providing IR codesets for device setup and matching.
///
/// The four hand-verified remotes are always available. The generated Flipper
/// IRDB catalog is loaded from assets, while full codesets are loaded lazily
/// only when the matching wizard tests one.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';

class IrDeviceEntry {
  IrDeviceEntry._({
    required this.id,
    required this.displayName,
    required this.brand,
    required this.brandName,
    required this.deviceType,
    required this.keyCount,
    required this.codeset,
    required this.source,
  });

  factory IrDeviceEntry.bundled(IrCodeset codeset, String source) =>
      IrDeviceEntry._(
        id: codeset.id,
        displayName: codeset.name ?? codeset.id,
        brand: codeset.brand,
        brandName: codeset.brandName ?? _familyLabel(codeset.brand),
        deviceType: codeset.deviceType,
        keyCount: codeset.keys.length,
        codeset: codeset,
        source: source,
      );

  factory IrDeviceEntry.catalog(CatalogEntry entry) => IrDeviceEntry._(
    id: entry.id,
    displayName: entry.name,
    brand: entry.brand,
    brandName: entry.brandName,
    deviceType: entry.deviceType,
    keyCount: entry.keyCount,
    codeset: null,
    source: entry.source == IrdbSource.kookong ? 'Kookong' : 'Flipper IRDB',
  );

  final String id;
  final String displayName;
  final BrandFamily brand;
  final String brandName;
  final DeviceType deviceType;
  final int keyCount;
  IrCodeset? codeset;
  final String source;
}

class IrDeviceService {
  IrDeviceService({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle,
      _usesRootBundle = bundle == null;

  static Future<List<CatalogEntry>>? _rootCatalogLoad;

  final AssetBundle _bundle;
  final bool _usesRootBundle;
  final List<IrDeviceEntry> _entries = [
    IrDeviceEntry.bundled(sonyTvCodeset, 'Bundled (Sony SIRC)'),
    IrDeviceEntry.bundled(samsungTvCodeset, 'Bundled (Samsung NEC)'),
    IrDeviceEntry.bundled(lgTvCodeset, 'Bundled (LG NEC)'),
    IrDeviceEntry.bundled(panasonicTvCodeset, 'Bundled (Panasonic NEC-ext)'),
  ];

  bool catalogLoaded = false;
  String? catalogError;

  List<IrDeviceEntry> get allEntries => List.unmodifiable(_entries);

  Future<void> initialize() async {
    if (catalogLoaded) return;
    try {
      final bundle = _usesRootBundle ? rootBundle : _bundle;
      final entries = _usesRootBundle
          ? await (_rootCatalogLoad ??= _loadAllCatalogs(rootBundle))
          : await _loadAllCatalogs(bundle);
      final existingIds = _entries.map((entry) => entry.id).toSet();
      _entries.addAll(
        entries
            .where((entry) => existingIds.add(entry.id))
            .map(IrDeviceEntry.catalog),
      );
      catalogLoaded = true;
      catalogError = null;
    } on Object catch (error) {
      catalogError = '$error';
    }
  }

  static Future<List<CatalogEntry>> _loadAllCatalogs(
    AssetBundle bundle,
  ) async {
    final entries = <CatalogEntry>[];
    entries.addAll(await _loadCatalog(bundle, 'assets/irdb/catalog.json'));
    try {
      entries.addAll(
        await _loadCatalog(bundle, 'assets/kookong/catalog.json'),
      );
    } on Object {
      // Kookong catalog may not be present yet.
    }
    return entries;
  }

  static Future<List<CatalogEntry>> _loadCatalog(
    AssetBundle bundle,
    String path,
  ) async {
    final content = await bundle.loadString(path);
    return IrdbCatalog.fromJson(content).entries;
  }

  Future<IrCodeset> loadCodeset(IrDeviceEntry entry) async {
    final cached = entry.codeset;
    if (cached != null) return cached;
    final path = entry.id.startsWith('kookong_')
        ? 'assets/kookong/codesets/${entry.id}.json'
        : 'assets/irdb/codesets/${entry.id}.json';
    final content = await _bundle.loadString(path);
    final json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('IR codeset asset is not a JSON object');
    }
    final codeset = SerializedCodeset.fromJson(json).toCodeset();
    if (codeset.keys.isEmpty) {
      throw const FormatException('IR codeset contains no supported keys');
    }
    entry.codeset = codeset;
    return codeset;
  }

  List<IrDeviceEntry> byDeviceType(DeviceType type) =>
      _rank(_entries.where((e) => e.deviceType == type));

  List<IrDeviceEntry> byBrand(BrandFamily brand, {DeviceType? deviceType}) =>
      _rank(
        _entries.where(
          (entry) =>
              entry.brand == brand &&
              (deviceType == null || entry.deviceType == deviceType),
        ),
      );

  List<IrDeviceEntry> byBrandName(String brandName, {DeviceType? deviceType}) =>
      _rank(
        _entries.where(
          (entry) =>
              entry.brandName.toLowerCase() == brandName.toLowerCase() &&
              (deviceType == null || entry.deviceType == deviceType),
        ),
      );

  List<BrandFamily> availableBrands({DeviceType? deviceType}) {
    final brands = _entries
        .where((entry) => deviceType == null || entry.deviceType == deviceType)
        .map((entry) => entry.brand)
        .toSet()
        .toList();
    brands.sort((a, b) => a.name.compareTo(b.name));
    return brands;
  }

  List<String> availableBrandNames({DeviceType? deviceType}) {
    final brands = _entries
        .where((entry) => deviceType == null || entry.deviceType == deviceType)
        .map((entry) => entry.brandName)
        .toSet()
        .toList();
    brands.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return brands;
  }

  List<DeviceType> get availableDeviceTypes =>
      _entries.map((e) => e.deviceType).toSet().toList();

  IrDeviceEntry? findById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<IrDeviceEntry> search(String query) {
    final q = query.toLowerCase();
    return _rank(
      _entries.where((e) {
        final name = e.displayName.toLowerCase();
        final brandName = e.brandName.toLowerCase();
        return name.contains(q) || brandName.contains(q);
      }),
    );
  }

  List<IrDeviceEntry> _rank(Iterable<IrDeviceEntry> entries) {
    final ranked = entries.toList();
    ranked.sort((a, b) {
      final bundled =
          (b.source.startsWith('Bundled') ? 1 : 0) -
          (a.source.startsWith('Bundled') ? 1 : 0);
      if (bundled != 0) return bundled;
      final keys = b.keyCount.compareTo(a.keyCount);
      return keys != 0 ? keys : a.displayName.compareTo(b.displayName);
    });
    return ranked;
  }
}

String _familyLabel(BrandFamily family) => switch (family) {
  BrandFamily.bravia => 'Sony',
  BrandFamily.tizen => 'Samsung',
  BrandFamily.webOs => 'LG',
  BrandFamily.panasonic => 'Panasonic',
  _ => family.name,
};
