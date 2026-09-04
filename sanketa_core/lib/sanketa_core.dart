/// SANKETA core — the platform-agnostic control contract and its domain models.
///
/// Public surface of the `sanketa_core` package. Every brand adapter depends on
/// this and nothing above it depends on any brand. See PRD §13.3 and CONTEXT.md
/// §8 for the architecture, and the ControlAdapter doc comment for the design
/// rules the contract enforces.
library sanketa_core;

export 'src/adapter/control_adapter.dart';
export 'src/discovery/device_registry.dart';
export 'src/discovery/discovered_endpoint.dart';
export 'src/discovery/discovery_backend.dart';
export 'src/discovery/discovery_engine.dart';
export 'src/discovery/endpoint_classifier.dart';
export 'src/model/capabilities.dart';
export 'src/model/device.dart';
export 'src/model/keys.dart';
export 'src/model/pairing.dart';
export 'src/model/text.dart';
