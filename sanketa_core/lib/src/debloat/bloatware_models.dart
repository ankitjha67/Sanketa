/// Bloatware database models for the TV Debloat feature.
///
/// Each [BloatwareEntry] represents one Android package that can be disabled
/// via `pm disable-user --user 0 <package>` over ADB. The operation is fully
/// reversible with `pm enable <package>` — no root required.
library;

enum BloatCategory {
  ads,
  telemetry,
  bloatware,
  googleUnused,
  oemLauncher;

  static BloatCategory fromJson(String value) => switch (value) {
        'ads' => ads,
        'telemetry' => telemetry,
        'bloatware' => bloatware,
        'google_unused' => googleUnused,
        'oem_launcher' => oemLauncher,
        _ => bloatware,
      };

  String toJson() => switch (this) {
        ads => 'ads',
        telemetry => 'telemetry',
        bloatware => 'bloatware',
        googleUnused => 'google_unused',
        oemLauncher => 'oem_launcher',
      };
}

enum BloatSeverity {
  high,
  medium,
  low;

  static BloatSeverity fromJson(String value) => switch (value) {
        'high' => high,
        'medium' => medium,
        'low' => low,
        _ => low,
      };

  String toJson() => name;
}

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

  final String package;
  final List<String> brands;
  final BloatCategory category;
  final String name;
  final String description;
  final bool safeToDisable;
  final BloatSeverity severity;

  factory BloatwareEntry.fromJson(Map<String, dynamic> json) => BloatwareEntry(
        package: json['package'] as String,
        brands: (json['brands'] as List<dynamic>).cast<String>(),
        category: BloatCategory.fromJson(json['category'] as String),
        name: json['name'] as String,
        description: json['description'] as String,
        safeToDisable: json['safe_to_disable'] as bool,
        severity: BloatSeverity.fromJson(json['severity'] as String),
      );

  Map<String, dynamic> toJson() => {
        'package': package,
        'brands': brands,
        'category': category.toJson(),
        'name': name,
        'description': description,
        'safe_to_disable': safeToDisable,
        'severity': severity.toJson(),
      };

  bool appliesToBrand(String brand) =>
      brands.contains(brand) || brands.contains('all_android_tv');
}

class BloatwareDatabase {
  BloatwareDatabase(this.entries);

  final List<BloatwareEntry> entries;

  factory BloatwareDatabase.fromJson(List<dynamic> json) => BloatwareDatabase(
        json
            .map((e) => BloatwareEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<BloatwareEntry> forBrand(String brand) =>
      entries.where((e) => e.appliesToBrand(brand)).toList();

  List<BloatwareEntry> byCategory(BloatCategory category) =>
      entries.where((e) => e.category == category).toList();

  List<BloatwareEntry> bySeverity(BloatSeverity severity) =>
      entries.where((e) => e.severity == severity).toList();

  List<BloatwareEntry> get safeOnly =>
      entries.where((e) => e.safeToDisable).toList();

  List<BloatwareEntry> forBrandSafe(String brand) =>
      entries.where((e) => e.appliesToBrand(brand) && e.safeToDisable).toList();
}
