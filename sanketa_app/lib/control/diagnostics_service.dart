import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

class DiagnosticsReport {
  const DiagnosticsReport({required this.text, required this.filePath});
  final String text;
  final String filePath;
}

class DiagnosticsService {
  /// Generate a diagnostics report from the current app state.
  static Future<DiagnosticsReport> generateReport({
    required String appVersion,
    required bool isConnected,
    required String? deviceName,
    required String adapterId,
    required core.Transport transport,
    required String? host,
    required Map<String, bool> capabilities,
    required List<String> actionLog,
    String? connectionError,
    Map<String, String>? checkResults,
  }) async {
    final buf = StringBuffer();

    buf.writeln('=== Sanketa Diagnostics Report ===');
    buf.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    buf.writeln();

    // Platform info
    buf.writeln('--- Platform ---');
    buf.writeln('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    buf.writeln('Dart: ${Platform.version}');
    buf.writeln('Debug mode: $kDebugMode');
    buf.writeln();

    // App info
    buf.writeln('--- App ---');
    buf.writeln('Version: $appVersion');
    buf.writeln();

    // Connection info
    buf.writeln('--- Connection ---');
    buf.writeln('Connected: $isConnected');
    buf.writeln('Device: ${deviceName ?? "none"}');
    buf.writeln('Adapter: $adapterId');
    buf.writeln('Transport: ${transport.name}');
    buf.writeln('Host: ${host ?? "n/a"}');
    if (connectionError != null) {
      buf.writeln('Last error: $connectionError');
    }
    buf.writeln();

    // Capabilities
    buf.writeln('--- Capabilities ---');
    for (final entry in capabilities.entries) {
      buf.writeln('${entry.key}: ${entry.value ? "YES" : "no"}');
    }
    buf.writeln();

    // Connection Doctor results
    if (checkResults != null && checkResults.isNotEmpty) {
      buf.writeln('--- Connection Doctor ---');
      for (final entry in checkResults.entries) {
        buf.writeln('${entry.key}: ${entry.value}');
      }
      buf.writeln();
    }

    // Recent action log (last 50)
    if (actionLog.isNotEmpty) {
      buf.writeln('--- Recent Actions (last 50) ---');
      final recent = actionLog.length > 50
          ? actionLog.sublist(actionLog.length - 50)
          : actionLog;
      for (final a in recent) {
        buf.writeln(a);
      }
      buf.writeln();
    }

    buf.writeln('=== End Report ===');

    final text = buf.toString();
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/sanketa_diagnostics_$ts.txt');
    await file.writeAsString(text);

    return DiagnosticsReport(text: text, filePath: file.path);
  }
}
