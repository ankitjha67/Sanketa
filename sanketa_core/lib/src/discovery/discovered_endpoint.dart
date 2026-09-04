/// Discovery data types — the raw output of any discovery method, and the
/// merged device view the UI consumes.
///
/// A [DiscoveredEndpoint] is one hit from one method (SSDP, mDNS, probe). The
/// [DeviceRegistry] classifies and merges these into [DiscoveredDevice]s so the
/// same physical device found by two methods appears once (PRD FR-1.1 dedupe AC).
library;

import '../model/device.dart';

/// Which discovery method produced a hit.
enum DiscoverySource { ssdp, mdns, probe, manual }

/// Pre-pairing capability hint shown as a badge on the discovery list
/// (PRD FR-1.1: brand + capability badges Control / Keyboard / Cast).
enum CapabilityBadge { control, keyboard, cast }

/// One raw discovery hit from one method.
class DiscoveredEndpoint {
  const DiscoveredEndpoint({
    required this.source,
    required this.host,
    this.port,
    this.usn,
    this.searchTarget,
    this.location,
    this.server,
    this.friendlyName,
    this.attributes = const {},
  });

  final DiscoverySource source;

  /// The device's address as seen on the wire (datagram sender / resolved A
  /// record). Normally an IP literal, which is what lets us merge methods.
  final String host;
  final int? port;

  /// SSDP USN (Unique Service Name) or, for mDNS, the service instance name.
  final String? usn;

  /// SSDP ST header or mDNS service type (e.g. `roku:ecp`, `_googlecast._tcp`).
  final String? searchTarget;

  /// SSDP LOCATION URL (device description document).
  final String? location;

  /// SSDP SERVER header — carries OS/brand hints ("Roku/…", "… WebOS …").
  final String? server;

  final String? friendlyName;

  /// Extra parsed headers / TXT records, lower-cased keys.
  final Map<String, String> attributes;

  /// Session-stable identity used to de-duplicate across methods. One physical
  /// device has one LAN IP, so IP is the most reliable cross-method key; we fall
  /// back to a USN-embedded uuid, then host:port.
  String get dedupeKey {
    if (_isIpLiteral(host)) return 'net:$host';
    final u = usn;
    if (u != null && u.isNotEmpty) return 'id:${_extractUuid(u) ?? u}';
    return 'net:$host:${port ?? ''}';
  }
}

/// A merged, classified device ready for the discovery list.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.device,
    required this.badges,
    required this.sources,
    this.adapterId,
    this.confident = true,
  });

  final Device device;

  /// Union of capability badges inferred across every method that saw it.
  final Set<CapabilityBadge> badges;

  /// Every discovery method that reported this device.
  final Set<DiscoverySource> sources;

  /// The `ControlAdapter.id` expected to control it, if recognised.
  final String? adapterId;

  /// False when classification fell back to a generic guess.
  final bool confident;
}

bool _isIpLiteral(String h) {
  if (h.contains(':')) return true; // IPv6
  final parts = h.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}

String? _extractUuid(String usn) {
  final i = usn.indexOf('uuid:');
  if (i < 0) return null;
  var rest = usn.substring(i + 5);
  final dbl = rest.indexOf('::');
  if (dbl >= 0) rest = rest.substring(0, dbl);
  return rest.isEmpty ? null : rest;
}
