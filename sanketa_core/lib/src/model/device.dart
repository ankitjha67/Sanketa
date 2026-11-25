/// Device identity, app/input references, and readable state.
///
/// Mirrors the data-model sketch in PRD §13.6: Household > Rooms > Devices, with
/// a device identity that is stable across IP changes (platform IDs / MAC where
/// available). Secrets are NOT stored here — the PairingVault holds those in
/// Keystore/Keychain and this layer keeps only references (CONTEXT.md §9.10).
library;

import 'capabilities.dart';

/// The type of appliance, which selects the remote layout (PRD FR-5.1).
enum DeviceType {
  tv,
  streamingStick,
  setTopBox,
  soundbar,
  airConditioner,
  projector,
  mediaRenderer, // DLNA-only render target
}

enum PowerState { on, standby, unknown }

/// A discovered or manually-added controllable device.
class Device {
  const Device({
    required this.id,
    required this.brand,
    required this.type,
    required this.transport,
    this.friendlyName,
    this.model,
    this.host,
    this.port,
    this.roomId,
    this.capabilities,
  });

  /// Stable identity across IP changes (platform id / MAC / serial). Never the IP.
  final String id;

  final BrandFamily brand;
  final DeviceType type;
  final Transport transport;

  final String? friendlyName;
  final String? model;

  /// Current network address, if a network target. May change; not identity.
  final String? host;
  final int? port;

  /// Room grouping (FR-9.1). Null until the user assigns one.
  final String? roomId;

  /// Cached capability map (may be null before first connect).
  final CapabilityMap? capabilities;

  String get displayName => friendlyName ?? model ?? id;
}

/// A launchable app on the target (PRD FR-6).
class AppRef {
  const AppRef({required this.id, this.name});
  final String id; // platform app id (e.g. Roku channel id, DIAL app name)
  final String? name;
}

/// A selectable input/source on the target.
class InputRef {
  const InputRef({required this.id, this.name});
  final String id; // e.g. "hdmi1", or platform-native token
  final String? name;
}

/// A partial state update streamed from `ControlAdapter.readState()`. Every
/// field is nullable: a write-only platform simply never populates it, and the
/// UI omits any claim it has no value for (PRD FR-3.4).
class StateDelta {
  const StateDelta({this.volume, this.muted, this.currentApp, this.power});
  final int? volume;
  final bool? muted;
  final AppRef? currentApp;
  final PowerState? power;
}

/// Snapshot of known TV state from readback queries (FR-3.4).
class TvState {
  const TvState({this.volume, this.muted, this.power, this.currentApp});
  final int? volume;
  final bool? muted;
  final PowerState? power;
  final AppRef? currentApp;
}
