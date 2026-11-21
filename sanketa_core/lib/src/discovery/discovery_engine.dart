/// Discovery engine — runs all backends in parallel, merges into the registry,
/// and reports an outcome that distinguishes "nothing here" from "the network
/// is blocking us" (PRD FR-1.1 AC: detect AP/client isolation rather than
/// silently showing an empty list).
library;

import 'dart:async';

import 'device_registry.dart';
import 'discovered_endpoint.dart';
import 'discovery_backend.dart';

class ScanResult {
  const ScanResult({
    required this.devices,
    required this.apIsolationSuspected,
    required this.backendsRun,
    required this.backendsFailed,
  });

  final List<DiscoveredDevice> devices;

  /// True when zero devices were found but the gateway is reachable — the
  /// signature of AP/client isolation (hotel WiFi, a router setting). The UI
  /// turns this into a fix suggestion instead of an empty list.
  final bool apIsolationSuspected;

  final int backendsRun;
  final int backendsFailed;
}

class DiscoveryEngine {
  DiscoveryEngine({
    required this.backends,
    DeviceRegistry? registry,
    Future<bool> Function()? gatewayReachable,
  })  : registry = registry ?? DeviceRegistry(),
        _gatewayReachable = gatewayReachable;

  final List<DiscoveryBackend> backends;
  final DeviceRegistry registry;
  final Future<bool> Function()? _gatewayReachable;

  /// Live device list; the UI can bind to this to populate as results arrive.
  Stream<List<DiscoveredDevice>> get devices => registry.changes;

  /// Run one scan. One backend failing (an exception, no multicast route) never
  /// aborts the others.
  Future<ScanResult> scan({
    Duration timeout = const Duration(seconds: 6),
    bool clearPrevious = true,
  }) async {
    if (clearPrevious) registry.clear();
    final outcomes = await Future.wait(
      backends.map((backend) => _runBackend(backend, timeout)),
    );
    final failed = outcomes.where((didFail) => didFail).length;

    final found = registry.devices;
    var apIsolation = false;
    final gatewayCheck = _gatewayReachable; // local promotes; a field would not
    if (found.isEmpty && gatewayCheck != null) {
      try {
        apIsolation = await gatewayCheck();
      } on Object {
        apIsolation = false;
      }
    }

    return ScanResult(
      devices: found,
      apIsolationSuspected: apIsolation,
      backendsRun: backends.length,
      backendsFailed: failed,
    );
  }

  Future<bool> _runBackend(
    DiscoveryBackend backend,
    Duration timeout,
  ) async {
    final iterator = StreamIterator(backend.search(timeout));
    final stopwatch = Stopwatch()..start();
    try {
      while (true) {
        final remaining = timeout - stopwatch.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('scan timeout');
        final hasNext = await iterator.moveNext().timeout(remaining);
        if (!hasNext) return false;
        registry.ingest(iterator.current);
      }
    } on Object {
      return true;
    } finally {
      // Some async generators cannot finish cancellation until their current
      // I/O wait completes. Do not let that extend the public scan deadline;
      // cancellation still prevents any late endpoint from being ingested.
      unawaited(iterator.cancel());
    }
  }
}
