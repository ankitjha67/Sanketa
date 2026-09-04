/// Device registry — merges classified endpoints into a de-duplicated device
/// list and streams changes to the UI (PRD §13.2 core domain; FR-1.1 dedupe).
library;

import 'dart:async';

import '../model/capabilities.dart';
import '../model/device.dart';
import 'discovered_endpoint.dart';
import 'endpoint_classifier.dart';

class DeviceRegistry {
  DeviceRegistry({EndpointClassifier classifier = const EndpointClassifier()})
      : _classifier = classifier;

  final EndpointClassifier _classifier;
  final Map<String, DiscoveredDevice> _byKey = {};
  final StreamController<List<DiscoveredDevice>> _changes =
      StreamController<List<DiscoveredDevice>>.broadcast();

  /// Snapshot of everything found so far.
  List<DiscoveredDevice> get devices => List.unmodifiable(_byKey.values);

  /// Emits the full device list every time it changes.
  Stream<List<DiscoveredDevice>> get changes => _changes.stream;

  /// Classify one endpoint and merge it into the device list. Merging unions
  /// badges and sources and keeps the richest brand guess, so a device seen via
  /// both SSDP and mDNS collapses to a single entry.
  void ingest(DiscoveredEndpoint endpoint) {
    final c = _classifier.classify(endpoint);
    final key = endpoint.dedupeKey;
    final prior = _byKey[key];

    final badges = <CapabilityBadge>{...?prior?.badges, ...c.badges};
    final sources = <DiscoverySource>{...?prior?.sources, endpoint.source};

    // Keep the most specific brand: never let a later generic hit (other/dlna)
    // overwrite a confident brand we already have.
    final brand = _pickBrand(prior?.device.brand, c.brand);
    final adapterId = c.confident ? (c.adapterId ?? prior?.adapterId) : prior?.adapterId ?? c.adapterId;

    final device = Device(
      id: key,
      brand: brand,
      type: c.deviceType,
      transport: Transport.network,
      friendlyName: endpoint.friendlyName ?? prior?.device.friendlyName,
      model: prior?.device.model,
      host: endpoint.host,
      port: endpoint.port ?? prior?.device.port,
      roomId: prior?.device.roomId,
      capabilities: prior?.device.capabilities,
    );

    _byKey[key] = DiscoveredDevice(
      device: device,
      badges: badges,
      sources: sources,
      adapterId: adapterId,
      confident: (prior?.confident ?? false) || c.confident,
    );
    _changes.add(devices);
  }

  void clear() {
    _byKey.clear();
    _changes.add(devices);
  }

  Future<void> dispose() => _changes.close();

  BrandFamily _pickBrand(BrandFamily? prior, BrandFamily incoming) {
    if (prior == null || prior == BrandFamily.other) return incoming;
    if (incoming == BrandFamily.other) return prior;
    return incoming; // both specific: latest wins (rare; refined at pair time)
  }
}
