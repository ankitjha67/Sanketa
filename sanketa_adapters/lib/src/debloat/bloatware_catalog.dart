library;

import 'dart:convert';

class BloatwareEntry {
  const BloatwareEntry({
    required this.package,
    required this.brands,
    required this.category,
    required this.name,
    required this.description,
    required this.safeToDisable,
    required this.severity,
  });

  factory BloatwareEntry.fromJson(Map<String, dynamic> json) {
    return BloatwareEntry(
      package: json['package'] as String,
      brands: (json['brands'] as List).cast<String>(),
      category: json['category'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      safeToDisable: json['safe_to_disable'] as bool,
      severity: json['severity'] as String,
    );
  }

  final String package;
  final List<String> brands;
  final String category;
  final String name;
  final String description;
  final bool safeToDisable;
  final String severity;

  bool matchesBrand(String brand) {
    final lower = brand.toLowerCase();
    return brands.contains('all_android_tv') ||
        brands.any((b) => b.toLowerCase() == lower);
  }

  int get severityRank {
    switch (severity) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }
}

class BloatwareMatch {
  const BloatwareMatch({
    required this.entry,
    required this.installed,
    required this.enabled,
  });

  final BloatwareEntry entry;
  final bool installed;
  final bool enabled;
}

class BloatwareCatalog {
  BloatwareCatalog(this._entries);

  factory BloatwareCatalog.fromJson(String jsonStr) {
    final list = (jsonDecode(jsonStr) as List)
        .map((e) => BloatwareEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return BloatwareCatalog(list);
  }

  final List<BloatwareEntry> _entries;

  List<BloatwareEntry> get all => List.unmodifiable(_entries);

  List<BloatwareEntry> forBrand(String brand) {
    return _entries.where((e) => e.matchesBrand(brand)).toList()
      ..sort((a, b) => b.severityRank.compareTo(a.severityRank));
  }

  List<BloatwareMatch> matchInstalled(
    List<String> installedPackages,
    List<String> disabledPackages,
    String brand,
  ) {
    final installedSet = installedPackages.toSet();
    final disabledSet = disabledPackages.toSet();
    final brandEntries = forBrand(brand);
    return brandEntries
        .where((e) => installedSet.contains(e.package))
        .map((e) => BloatwareMatch(
              entry: e,
              installed: true,
              enabled: !disabledSet.contains(e.package),
            ))
        .toList();
  }

  int countAds(List<BloatwareMatch> matches) =>
      matches.where((m) => m.entry.category == 'ads' && m.enabled).length;

  int countTelemetry(List<BloatwareMatch> matches) =>
      matches.where((m) => m.entry.category == 'telemetry' && m.enabled).length;

  int countBloatware(List<BloatwareMatch> matches) =>
      matches.where((m) => m.enabled).length;
}
