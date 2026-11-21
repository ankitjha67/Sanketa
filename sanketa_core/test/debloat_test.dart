import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  group('BloatCategory', () {
    test('fromJson parses known values', () {
      expect(BloatCategory.fromJson('ads'), BloatCategory.ads);
      expect(BloatCategory.fromJson('telemetry'), BloatCategory.telemetry);
      expect(BloatCategory.fromJson('google_unused'), BloatCategory.googleUnused);
      expect(BloatCategory.fromJson('oem_launcher'), BloatCategory.oemLauncher);
    });

    test('fromJson defaults unknown to bloatware', () {
      expect(BloatCategory.fromJson('foo'), BloatCategory.bloatware);
    });

    test('toJson round-trips', () {
      for (final cat in BloatCategory.values) {
        expect(BloatCategory.fromJson(cat.toJson()), cat);
      }
    });
  });

  group('BloatSeverity', () {
    test('fromJson parses known values', () {
      expect(BloatSeverity.fromJson('high'), BloatSeverity.high);
      expect(BloatSeverity.fromJson('medium'), BloatSeverity.medium);
      expect(BloatSeverity.fromJson('low'), BloatSeverity.low);
    });

    test('fromJson defaults unknown to low', () {
      expect(BloatSeverity.fromJson('critical'), BloatSeverity.low);
    });
  });

  group('BloatwareEntry', () {
    final json = {
      'package': 'com.example.ads',
      'brands': ['xiaomi', 'all_android_tv'],
      'category': 'ads',
      'name': 'Example Ads',
      'description': 'Advertisement SDK',
      'safe_to_disable': true,
      'severity': 'high',
    };

    test('fromJson creates correct entry', () {
      final entry = BloatwareEntry.fromJson(json);
      expect(entry.package, 'com.example.ads');
      expect(entry.brands, ['xiaomi', 'all_android_tv']);
      expect(entry.category, BloatCategory.ads);
      expect(entry.name, 'Example Ads');
      expect(entry.safeToDisable, isTrue);
      expect(entry.severity, BloatSeverity.high);
    });

    test('toJson round-trips', () {
      final entry = BloatwareEntry.fromJson(json);
      final out = entry.toJson();
      expect(out['package'], 'com.example.ads');
      expect(out['safe_to_disable'], true);
      expect(out['severity'], 'high');
      expect(out['category'], 'ads');
    });

    test('appliesToBrand matches specific brand', () {
      final entry = BloatwareEntry.fromJson({
        ...json,
        'brands': ['samsung'],
      });
      expect(entry.appliesToBrand('samsung'), isTrue);
      expect(entry.appliesToBrand('xiaomi'), isFalse);
    });

    test('appliesToBrand matches all_android_tv', () {
      final entry = BloatwareEntry.fromJson(json);
      expect(entry.appliesToBrand('sony'), isTrue);
    });
  });

  group('BloatwareDatabase', () {
    final db = BloatwareDatabase([
      BloatwareEntry.fromJson({
        'package': 'com.ads.a',
        'brands': ['all_android_tv'],
        'category': 'ads',
        'name': 'Ads A',
        'description': 'Ad tracker',
        'safe_to_disable': true,
        'severity': 'high',
      }),
      BloatwareEntry.fromJson({
        'package': 'com.xiaomi.b',
        'brands': ['xiaomi'],
        'category': 'telemetry',
        'name': 'Xiaomi Telemetry',
        'description': 'Usage reporting',
        'safe_to_disable': true,
        'severity': 'medium',
      }),
      BloatwareEntry.fromJson({
        'package': 'com.core.c',
        'brands': ['all_android_tv'],
        'category': 'bloatware',
        'name': 'Core Service',
        'description': 'System component',
        'safe_to_disable': false,
        'severity': 'low',
      }),
    ]);

    test('forBrand filters correctly', () {
      final xiaomi = db.forBrand('xiaomi');
      expect(xiaomi.length, 3);

      final samsung = db.forBrand('samsung');
      expect(samsung.length, 2);
    });

    test('byCategory filters correctly', () {
      expect(db.byCategory(BloatCategory.ads).length, 1);
      expect(db.byCategory(BloatCategory.telemetry).length, 1);
    });

    test('bySeverity filters correctly', () {
      expect(db.bySeverity(BloatSeverity.high).length, 1);
      expect(db.bySeverity(BloatSeverity.medium).length, 1);
      expect(db.bySeverity(BloatSeverity.low).length, 1);
    });

    test('safeOnly returns only safe entries', () {
      final safe = db.safeOnly;
      expect(safe.length, 2);
      expect(safe.every((e) => e.safeToDisable), isTrue);
    });

    test('forBrandSafe combines brand + safe filter', () {
      final safe = db.forBrandSafe('xiaomi');
      expect(safe.length, 2);
      expect(safe.every((e) => e.safeToDisable), isTrue);
    });

    test('fromJson parses list', () {
      final parsed = BloatwareDatabase.fromJson([
        {
          'package': 'com.test',
          'brands': ['all_android_tv'],
          'category': 'ads',
          'name': 'Test',
          'description': 'Test package',
          'safe_to_disable': true,
          'severity': 'low',
        },
      ]);
      expect(parsed.entries.length, 1);
    });
  });
}
