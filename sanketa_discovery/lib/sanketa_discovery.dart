/// SANKETA network discovery backends.
///
/// Real implementations of the `sanketa_core` `DiscoveryBackend` contract. Wire
/// any combination of these into a `DiscoveryEngine`; each finds devices a
/// different way, and the engine merges them into one de-duplicated list.
library sanketa_discovery;

export 'src/mdns_backend.dart';
export 'src/probe_backend.dart';
export 'src/ssdp_backend.dart';
