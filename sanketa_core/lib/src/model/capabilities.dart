/// Transport, brand identity, discovery hints, and the capability map.
///
/// The [CapabilityMap] is the single source of truth the UI reads to decide what
/// to render (PRD FR-3.5). No widget branches on brand; it branches on
/// capability. This is what lets "add a brand" touch zero core code (NFR-14).
library;

import 'keys.dart';
import 'text.dart';

/// The physical/logical path a command travels.
enum Transport {
  /// Native network protocol over the LAN (WebSocket/TLS/HTTP).
  network,

  /// Phone IR blaster (Android ConsumerIrManager). Fully offline (NFR-8).
  infrared,

  /// External WiFi-to-IR bridge (BroadLink-class), FR-8.
  bridge,
}

/// Coarse brand family for telemetry and adapter routing. This labels the
/// *protocol family*, not a marketing brand; UI never reads it.
enum BrandFamily {
  androidTv,
  tizen,
  webOs,
  roku,
  bravia,
  fireTv,
  vizio,
  panasonic,
  philips,
  hisense,
  tcl,
  appleTv,
  dlna,
  genericIr,
  other,
}

/// What an adapter tells the discovery engine to look for (PRD §13.3
/// `discoveryHints()`). Merged and de-duplicated across all adapters by the
/// discovery engine (FR-1.1).
class DiscoveryHints {
  const DiscoveryHints({
    this.mdnsServiceTypes = const [],
    this.ssdpTargets = const [],
    this.probePorts = const [],
  });

  /// mDNS/Bonjour service types, e.g. `_androidtvremote2._tcp`, `_googlecast._tcp`.
  final List<String> mdnsServiceTypes;

  /// SSDP search targets (ST) / URNs, e.g. `roku:ecp`, `urn:dial-multiscreen-org:...`.
  final List<String> ssdpTargets;

  /// TCP ports to probe for brands that advertise poorly (PRD §13.2).
  final List<int> probePorts;
}

/// Everything an adapter can and cannot do. Immutable; produced by
/// `ControlAdapter.capabilities()`.
class CapabilityMap {
  const CapabilityMap({
    required this.keys,
    required this.textMode,
    this.wake = false,
    this.volumeReadback = false,
    this.appLaunch = false,
    this.inputList = false,
    this.stateReadback = false,
  });

  /// Keys the target actually accepts. The remote UI renders only these.
  final Set<Key> keys;

  /// Live / bulk / none — drives the keyboard surface (FR-4.1).
  final TextInjectionMode textMode;

  /// Power-on from standby is feasible (WoL/WoWLAN or protocol-native).
  final bool wake;

  /// Volume level / mute state can be read back (else UI omits state claims).
  final bool volumeReadback;

  /// App launching supported (FR-6).
  final bool appLaunch;

  /// Input/source list can be enumerated from the device.
  final bool inputList;

  /// Any state readback stream is available (`readState()` emits).
  final bool stateReadback;

  bool supports(Key key) => keys.contains(key);

  bool get canType => textMode != TextInjectionMode.none;
}
