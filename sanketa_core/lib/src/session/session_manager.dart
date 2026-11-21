/// Session lifecycle manager with heartbeat and exponential-backoff reconnect
/// (FR-3.2).
///
/// The [SessionManager] wraps a [ControlAdapter] and handles the full
/// connection lifecycle: connect → heartbeat → detect failure → backoff →
/// reconnect. Callers listen to the [state] stream for phase transitions and
/// never need to manage timers or retry logic themselves.
///
/// Privacy: the manager never logs command payloads or text. It observes only
/// the session envelope (connected/disconnected/latency), matching the control-
/// plane zero-calls rule (PRD §14.1).
library;

import 'dart:async';

import '../adapter/control_adapter.dart';
import '../model/device.dart';
import '../model/pairing.dart';
import 'session_state.dart';

class SessionManager {
  SessionManager({
    this.heartbeatInterval = const Duration(seconds: 15),
    this.maxReconnectDelay = const Duration(seconds: 60),
    this.baseReconnectDelay = const Duration(seconds: 2),
    this.maxAttempts = 10,
  });

  final Duration heartbeatInterval;
  final Duration maxReconnectDelay;
  final Duration baseReconnectDelay;
  final int maxAttempts;

  ControlAdapter? _adapter;
  Device? _device;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  int _generation = 0;
  SessionPhase _phase = SessionPhase.disconnected;
  bool _disposed = false;
  bool _heartbeatInFlight = false;
  String? _lastError;

  final _stateController =
      StreamController<SessionSnapshot>.broadcast(sync: true);

  /// Emits a [SessionSnapshot] on every phase transition.
  Stream<SessionSnapshot> get state => _stateController.stream;

  /// The most recent snapshot, available synchronously.
  SessionSnapshot get snapshot => SessionSnapshot(
        phase: _phase,
        device: _device,
        attempt: _attempt,
        lastError: _lastError,
      );

  /// The adapter currently bound to this session (null when disconnected).
  ControlAdapter? get adapter => _adapter;

  /// The device this session is connected to (null when disconnected).
  Device? get device => _device;

  /// Bind an adapter, optionally pair, and open the connection.
  ///
  /// Stops any existing session first. If [pairingContext] is provided and
  /// pairing fails, the session moves to [SessionPhase.disconnected] with the
  /// error on the snapshot.
  Future<void> start(
    ControlAdapter adapter,
    Device device, {
    PairingContext? pairingContext,
  }) async {
    if (_disposed) throw StateError('SessionManager is disposed');
    await stop();
    if (_disposed) return;
    final generation = ++_generation;
    _adapter = adapter;
    _device = device;
    _attempt = 0;

    _emit(SessionPhase.connecting);

    try {
      if (pairingContext != null) {
        _emit(SessionPhase.pairing);
        final result = await adapter.pair(pairingContext);
        if (!_isCurrent(generation, adapter)) return;
        if (!result.isPaired) {
          final error = result.error ?? 'Pairing failed';
          _emit(SessionPhase.disconnected, error: error);
          await _releaseFailedAdapter(adapter, generation);
          return;
        }
      }

      await adapter.connect();
      if (!_isCurrent(generation, adapter)) {
        await _safeDisconnect(adapter);
        return;
      }
      _attempt = 0;
      _emit(SessionPhase.connected);
      _startHeartbeat(generation);
    } catch (e) {
      if (!_isCurrent(generation, adapter)) return;
      _emit(SessionPhase.disconnected, error: e.toString());
      _scheduleReconnect(generation);
    }
  }

  /// Disconnect and release resources. Safe to call multiple times.
  Future<void> stop() async {
    ++_generation;
    _cancelTimers();
    final a = _adapter;
    _adapter = null;
    _device = null;
    _attempt = 0;
    _heartbeatInFlight = false;
    await _safeDisconnect(a);
    if (_phase != SessionPhase.disconnected) {
      _emit(SessionPhase.disconnected);
    } else {
      _lastError = null;
    }
  }

  /// Permanently shut down this manager. No further calls are valid.
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------

  void _emit(SessionPhase phase, {String? error}) {
    if (_disposed) return;
    _phase = phase;
    _lastError = error;
    _stateController.add(SessionSnapshot(
      phase: phase,
      device: _device,
      attempt: _attempt,
      lastError: error,
    ));
  }

  void _cancelTimers() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startHeartbeat(int generation) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      final adapter = _adapter;
      if (!_isCurrent(generation, adapter) ||
          _phase != SessionPhase.connected ||
          _heartbeatInFlight) {
        return;
      }
      _heartbeatInFlight = true;
      try {
        final alive = await adapter!.heartbeat();
        if (_isCurrent(generation, adapter) && !alive) {
          _heartbeatTimer?.cancel();
          _scheduleReconnect(generation);
        }
      } catch (_) {
        if (_isCurrent(generation, adapter)) {
          _heartbeatTimer?.cancel();
          _scheduleReconnect(generation);
        }
      } finally {
        _heartbeatInFlight = false;
      }
    });
  }

  void _scheduleReconnect(int generation) {
    if (_disposed ||
        generation != _generation ||
        _adapter == null ||
        _reconnectTimer?.isActive == true) {
      return;
    }
    if (_attempt >= maxAttempts) {
      _emit(SessionPhase.disconnected,
          error: 'Could not reconnect after $maxAttempts attempts');
      return;
    }

    _emit(SessionPhase.reconnecting);
    _attempt++;

    final delay = _backoffDelay(_attempt);
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      final adapter = _adapter;
      if (!_isCurrent(generation, adapter) ||
          _phase != SessionPhase.reconnecting) {
        return;
      }
      try {
        await adapter!.connect();
        if (!_isCurrent(generation, adapter)) {
          await _safeDisconnect(adapter);
          return;
        }
        _attempt = 0;
        _emit(SessionPhase.connected);
        _startHeartbeat(generation);
      } catch (_) {
        if (_isCurrent(generation, adapter)) _scheduleReconnect(generation);
      }
    });
  }

  bool _isCurrent(int generation, ControlAdapter? adapter) =>
      !_disposed && generation == _generation && identical(adapter, _adapter);

  Future<void> _releaseFailedAdapter(
    ControlAdapter adapter,
    int generation,
  ) async {
    await _safeDisconnect(adapter);
    if (!_isCurrent(generation, adapter)) return;
    _adapter = null;
    _device = null;
  }

  Future<void> _safeDisconnect(ControlAdapter? adapter) async {
    if (adapter == null) return;
    try {
      await adapter.disconnect();
    } on Object {
      // Best-effort cleanup — stopping must remain safe and idempotent.
    }
  }

  Duration _backoffDelay(int attempt) {
    final ms =
        baseReconnectDelay.inMilliseconds * (1 << (attempt - 1).clamp(0, 10));
    return Duration(
        milliseconds: ms.clamp(0, maxReconnectDelay.inMilliseconds));
  }
}
