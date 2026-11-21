import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('TvMemoryStats', () {
    test('computes usedPercent correctly', () {
      const stats = TvMemoryStats(totalKb: 4000000, freeKb: 1000000, usedKb: 3000000);
      expect(stats.usedPercent, closeTo(75.0, 0.01));
    });

    test('usedPercent is 0 when totalKb is 0', () {
      const stats = TvMemoryStats(totalKb: 0, freeKb: 0, usedKb: 0);
      expect(stats.usedPercent, 0.0);
    });
  });

  group('TvCpuStats', () {
    test('totalUsed sums user and system', () {
      const stats = TvCpuStats(userPercent: 15.5, systemPercent: 8.3, idlePercent: 76.2);
      expect(stats.totalUsed, closeTo(23.8, 0.01));
    });
  });

  group('TvStorageStats', () {
    test('computes usedPercent correctly', () {
      const stats = TvStorageStats(
        totalKb: 16000000,
        usedKb: 12000000,
        availableKb: 4000000,
        mountPoint: '/data',
      );
      expect(stats.usedPercent, closeTo(75.0, 0.01));
    });

    test('usedPercent is 0 when totalKb is 0', () {
      const stats = TvStorageStats(
        totalKb: 0,
        usedKb: 0,
        availableKb: 0,
        mountPoint: '/',
      );
      expect(stats.usedPercent, 0.0);
    });
  });

  group('TvProcess', () {
    test('stores all fields', () {
      const proc = TvProcess(pid: 1234, name: 'com.example.app', cpuPercent: 12.5, memKb: 50000);
      expect(proc.pid, 1234);
      expect(proc.name, 'com.example.app');
      expect(proc.cpuPercent, 12.5);
      expect(proc.memKb, 50000);
    });
  });

  group('TvApp', () {
    test('stores required fields', () {
      const app = TvApp(packageName: 'com.example', label: 'Example');
      expect(app.packageName, 'com.example');
      expect(app.label, 'Example');
      expect(app.isSystem, false);
      expect(app.versionName, isNull);
    });

    test('system flag defaults to false', () {
      const app = TvApp(packageName: 'com.android.shell', label: 'Shell', isSystem: true);
      expect(app.isSystem, true);
    });
  });

  group('AdbPackage', () {
    test('stores fields correctly', () {
      const pkg = AdbPackage(packageName: 'com.test', enabled: true, label: 'Test');
      expect(pkg.packageName, 'com.test');
      expect(pkg.enabled, true);
      expect(pkg.label, 'Test');
      expect(pkg.category, isNull);
    });
  });
}
