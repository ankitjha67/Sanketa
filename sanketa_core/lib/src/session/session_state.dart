/// Session lifecycle phases and snapshots (FR-3.2).
///
/// The [SessionPhase] tracks where a connection to a device currently sits in
/// the lifecycle: discovery → pairing → connected, with reconnection on
/// failure. [SessionSnapshot] carries the phase plus metadata for the UI to
/// render status without polling.
library;

import '../model/device.dart';

/// Where the control session sits right now.
enum SessionPhase {
  /// No adapter is bound or the session was explicitly stopped.
  disconnected,

  /// The adapter is establishing a transport-level link.
  connecting,

  /// Platform-native auth is in progress (PIN, on-TV allow prompt, PSK).
  pairing,

  /// Fully connected, heartbeat running, commands accepted.
  connected,

  /// Link dropped, exponential-backoff reconnect in progress.
  reconnecting,
}

/// Immutable snapshot of the session at a single point in time. The
/// [SessionManager] emits one on every phase transition.
class SessionSnapshot {
  const SessionSnapshot({
    required this.phase,
    this.device,
    this.attempt = 0,
    this.lastError,
  });

  final SessionPhase phase;
  final Device? device;

  /// Reconnect attempt number (0 when connected or disconnected).
  final int attempt;

  /// Human-readable error from the last failed transition. Developer-facing;
  /// the UI maps this to a named copy + actionable next step (PRD §12.6).
  final String? lastError;

  bool get isActive => phase == SessionPhase.connected;
  bool get isRecovering => phase == SessionPhase.reconnecting;
}
