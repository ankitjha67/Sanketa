/// Targeted TCP-probe discovery backend.
///
/// For brands that advertise poorly (or not at all), probe known control ports
/// directly (PRD FR-1.1). A successful TCP connect is a strong signal the
/// service is present. Also the mechanism behind manual-add-by-IP (FR-1.3).
library;

import 'dart:async';
import 'dart:io';

import 'package:sanketa_core/sanketa_core.dart';

/// A host:port worth probing, with optional hints the classifier can use.
class ProbeCandidate {
  const ProbeCandidate(this.host, this.port, {this.searchTarget, this.server});
  final String host;
  final int port;
  final String? searchTarget;
  final String? server;
}

class ProbeBackend implements DiscoveryBackend {
  ProbeBackend(
    this.candidates, {
    this.connectTimeout = const Duration(milliseconds: 400),
  });

  final List<ProbeCandidate> candidates;
  final Duration connectTimeout;

  @override
  DiscoverySource get source => DiscoverySource.probe;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) async* {
    for (final candidate in candidates) {
      Socket? socket;
      try {
        socket = await Socket.connect(
          candidate.host,
          candidate.port,
          timeout: connectTimeout,
        );
        yield DiscoveredEndpoint(
          source: DiscoverySource.probe,
          host: candidate.host,
          port: candidate.port,
          searchTarget: candidate.searchTarget,
          server: candidate.server,
        );
      } on Object {
        // Connection refused / filtered / timed out → service not present.
      } finally {
        socket?.destroy();
      }
    }
  }
}
