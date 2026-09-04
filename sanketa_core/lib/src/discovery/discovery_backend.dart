/// The discovery backend contract — one interface per discovery method.
///
/// The engine runs every registered backend in parallel and merges their hits.
/// Adding a method (a new SSDP target set, an mDNS service, a probe list) is a
/// new backend behind this interface and touches no core code — the same
/// zero-core-change rule the adapters follow (NFR-14).
library;

import 'discovered_endpoint.dart';

abstract interface class DiscoveryBackend {
  DiscoverySource get source;

  /// Emit endpoints as they are found, completing at or before [timeout].
  /// Implementations must never throw into the stream for a single bad
  /// response; the engine tolerates a backend failing, but a well-behaved
  /// backend swallows per-hit parse errors and keeps listening.
  Stream<DiscoveredEndpoint> search(Duration timeout);
}
