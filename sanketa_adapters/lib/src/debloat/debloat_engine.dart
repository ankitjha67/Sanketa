library;

import 'dart:async';

import '../adb/adb_client.dart';
import 'bloatware_catalog.dart';

enum DebloatAction { disable, restore }

class DebloatResult {
  const DebloatResult({
    required this.action,
    required this.succeeded,
    required this.failed,
  });

  final DebloatAction action;
  final List<String> succeeded;
  final List<String> failed;

  int get total => succeeded.length + failed.length;
}

class DeviceProfile {
  const DeviceProfile({
    required this.model,
    required this.brand,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdkLevel,
  });

  final String model;
  final String brand;
  final String manufacturer;
  final String androidVersion;
  final String sdkLevel;

  String get brandKey {
    final lower = '${brand.toLowerCase()} ${manufacturer.toLowerCase()}';
    if (lower.contains('xiaomi') || lower.contains('redmi')) return 'xiaomi';
    if (lower.contains('sony')) return 'sony';
    if (lower.contains('hisense')) return 'hisense';
    if (lower.contains('tcl')) return 'tcl';
    if (lower.contains('philips')) return 'philips';
    if (lower.contains('amazon') || lower.contains('fire')) return 'fire_tv';
    if (lower.contains('haier')) return 'haier';
    return 'all_android_tv';
  }
}

class DebloatScanResult {
  const DebloatScanResult({
    required this.profile,
    required this.matches,
    required this.totalInstalled,
  });

  final DeviceProfile profile;
  final List<BloatwareMatch> matches;
  final int totalInstalled;

  int get adsFound =>
      matches.where((m) => m.entry.category == 'ads' && m.enabled).length;

  int get telemetryFound =>
      matches.where((m) => m.entry.category == 'telemetry' && m.enabled).length;

  int get bloatwareFound =>
      matches
          .where((m) =>
              m.entry.category == 'bloatware' && m.enabled)
          .length;

  int get safeToDisableCount =>
      matches
          .where((m) => m.entry.safeToDisable && m.enabled)
          .length;
}

class DebloatEngine {
  DebloatEngine({required this.adbClient, required this.catalog});

  final AdbClient adbClient;
  final BloatwareCatalog catalog;

  Future<DeviceProfile> getDeviceProfile() async {
    final props = await adbClient.getDeviceProps();
    return DeviceProfile(
      model: props['ro.product.model'] ?? 'Unknown',
      brand: props['ro.product.brand'] ?? 'Unknown',
      manufacturer: props['ro.product.manufacturer'] ?? 'Unknown',
      androidVersion: props['ro.build.version.release'] ?? '?',
      sdkLevel: props['ro.build.version.sdk'] ?? '?',
    );
  }

  Future<DebloatScanResult> scan() async {
    final profile = await getDeviceProfile();
    final allPkgs = await adbClient.listPackages();
    final disabledPkgs = await adbClient.listPackages(disabledOnly: true);
    final matches = catalog.matchInstalled(allPkgs, disabledPkgs, profile.brandKey);
    return DebloatScanResult(
      profile: profile,
      matches: matches,
      totalInstalled: allPkgs.length,
    );
  }

  Future<DebloatResult> speedUp() async {
    final scanResult = await scan();
    final toDisable = scanResult.matches
        .where((m) => m.entry.safeToDisable && m.enabled)
        .map((m) => m.entry.package)
        .toList();
    return _disablePackages(toDisable);
  }

  Future<DebloatResult> disableSelected(List<String> packages) async {
    return _disablePackages(packages);
  }

  Future<DebloatResult> restoreSelected(List<String> packages) async {
    return _restorePackages(packages);
  }

  Future<DebloatResult> restoreAll() async {
    final disabledPkgs = await adbClient.listPackages(disabledOnly: true);
    final brandEntries = catalog.all.map((e) => e.package).toSet();
    final toRestore =
        disabledPkgs.where((p) => brandEntries.contains(p)).toList();
    return _restorePackages(toRestore);
  }

  Future<DebloatResult> _disablePackages(List<String> packages) async {
    final succeeded = <String>[];
    final failed = <String>[];
    for (final pkg in packages) {
      try {
        final ok = await adbClient.disablePackage(pkg);
        (ok ? succeeded : failed).add(pkg);
      } on Object {
        failed.add(pkg);
      }
    }
    return DebloatResult(
      action: DebloatAction.disable,
      succeeded: succeeded,
      failed: failed,
    );
  }

  Future<DebloatResult> _restorePackages(List<String> packages) async {
    final succeeded = <String>[];
    final failed = <String>[];
    for (final pkg in packages) {
      try {
        final ok = await adbClient.enablePackage(pkg);
        (ok ? succeeded : failed).add(pkg);
      } on Object {
        failed.add(pkg);
      }
    }
    return DebloatResult(
      action: DebloatAction.restore,
      succeeded: succeeded,
      failed: failed,
    );
  }
}
