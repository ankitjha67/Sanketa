library;

/// Installed package on the TV.
class AdbPackage {
  const AdbPackage({
    required this.packageName,
    required this.enabled,
    this.label,
    this.category,
  });

  final String packageName;
  final bool enabled;
  final String? label;
  final String? category;
}

/// TV memory stats from `dumpsys meminfo`.
class TvMemoryStats {
  const TvMemoryStats({
    required this.totalKb,
    required this.freeKb,
    required this.usedKb,
  });

  final int totalKb;
  final int freeKb;
  final int usedKb;

  double get usedPercent =>
      totalKb > 0 ? (usedKb / totalKb) * 100.0 : 0.0;
}

/// TV CPU stats from `top`.
class TvCpuStats {
  const TvCpuStats({
    required this.userPercent,
    required this.systemPercent,
    required this.idlePercent,
  });

  final double userPercent;
  final double systemPercent;
  final double idlePercent;

  double get totalUsed => userPercent + systemPercent;
}

/// TV storage stats from `df`.
class TvStorageStats {
  const TvStorageStats({
    required this.totalKb,
    required this.usedKb,
    required this.availableKb,
    required this.mountPoint,
  });

  final int totalKb;
  final int usedKb;
  final int availableKb;
  final String mountPoint;

  double get usedPercent =>
      totalKb > 0 ? (usedKb / totalKb) * 100.0 : 0.0;
}

/// A running process on the TV.
class TvProcess {
  const TvProcess({
    required this.pid,
    required this.name,
    required this.cpuPercent,
    required this.memKb,
  });

  final int pid;
  final String name;
  final double cpuPercent;
  final int memKb;
}

/// An installed app on the TV (for the launcher).
class TvApp {
  const TvApp({
    required this.packageName,
    required this.label,
    this.versionName,
    this.isSystem = false,
  });

  final String packageName;
  final String label;
  final String? versionName;
  final bool isSystem;
}
