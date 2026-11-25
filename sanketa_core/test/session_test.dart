import 'dart:async';

import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

/// A minimal [ControlAdapter] for session-manager tests. Reports connection
/// state via callbacks so tests can control when connect/heartbeat succeed or
/// fail.
class _FakeAdapter extends ControlAdapter {
  bool connectShouldFail = false;
  bool heartbeatAlive = true;
  Completer<void>? connectGate;
  int connectCount = 0;
  int disconnectCount = 0;
  int heartbeatCount = 0;

  @override
  String get id => 'fake';
  @override
  BrandFamily get brandFamily => BrandFamily.other;
  @override
  Transport get transport => Transport.network;
  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints();

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: Key.values.toSet(),
        textMode: TextInjectionMode.live,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async =>
      const PairingResult.paired('token');

  @override
  Future<void> connect() async {
    connectCount++;
    await connectGate?.future;
    if (connectShouldFail) throw Exception('connect failed');
  }

  @override
  Future<void> disconnect() async => disconnectCount++;

  @override
  Future<bool> heartbeat() async {
    heartbeatCount++;
    return heartbeatAlive;
  }

  @override
  Future<CommandResult> sendKey(Key key,
          {PressType press = PressType.tap}) async =>
      const CommandResult.success();

  @override
  Future<CommandResult> sendText(TextOp op) async =>
      const CommandResult.success();

  @override
  Future<CommandResult> launchApp(AppRef app) async =>
      const CommandResult.success();

  @override
  Future<CommandResult> setInput(InputRef input) async =>
      const CommandResult.success();

  @override
  Future<CommandResult> power({required bool on}) async =>
      const CommandResult.success();

  @override
  Stream<StateDelta> readState() => const Stream.empty();

  @override
  Future<int?> getVolume() async => null;
  @override
  Future<bool?> getMuted() async => null;
  @override
  Future<PowerState?> getPowerState() async => null;
  @override
  Future<AppRef?> getCurrentApp() async => null;
}

const _device = Device(
  id: 'test-tv',
  brand: BrandFamily.other,
  type: DeviceType.tv,
  transport: Transport.network,
  friendlyName: 'Test TV',
);

void main() {
  group('SessionManager', () {
    late SessionManager manager;
    late _FakeAdapter adapter;

    setUp(() {
      adapter = _FakeAdapter();
      manager = SessionManager(
        heartbeatInterval: const Duration(milliseconds: 50),
        baseReconnectDelay: const Duration(milliseconds: 10),
        maxReconnectDelay: const Duration(milliseconds: 100),
        maxAttempts: 3,
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('start transitions through connecting → connected', () async {
      final phases = <SessionPhase>[];
      manager.state.listen((s) => phases.add(s.phase));

      await manager.start(adapter, _device);

      expect(phases, contains(SessionPhase.connecting));
      expect(phases.last, SessionPhase.connected);
      expect(adapter.connectCount, 1);
    });

    test('start with pairing transitions through pairing phase', () async {
      final phases = <SessionPhase>[];
      manager.state.listen((s) => phases.add(s.phase));

      await manager.start(adapter, _device,
          pairingContext: const PairingContext());

      expect(phases, contains(SessionPhase.pairing));
      expect(phases.last, SessionPhase.connected);
    });

    test('stop disconnects and emits disconnected', () async {
      await manager.start(adapter, _device);
      await manager.stop();

      expect(manager.snapshot.phase, SessionPhase.disconnected);
      expect(adapter.disconnectCount, 1);
    });

    test('snapshot reflects current state synchronously', () async {
      expect(manager.snapshot.phase, SessionPhase.disconnected);
      await manager.start(adapter, _device);
      expect(manager.snapshot.phase, SessionPhase.connected);
      expect(manager.snapshot.device?.id, 'test-tv');
    });

    test('connect failure triggers reconnect', () async {
      adapter.connectShouldFail = true;
      final phases = <SessionPhase>[];
      manager.state.listen((s) => phases.add(s.phase));

      await manager.start(adapter, _device);

      // Should attempt reconnect after connect failure
      expect(phases, contains(SessionPhase.reconnecting));
    });

    test('max attempts reached emits disconnected with error', () async {
      adapter.connectShouldFail = true;
      final snapshots = <SessionSnapshot>[];
      manager.state.listen(snapshots.add);

      await manager.start(adapter, _device);

      // Wait for reconnect attempts to exhaust
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final last = snapshots.last;
      expect(last.phase, SessionPhase.disconnected);
      expect(last.lastError, contains('reconnect'));
    });

    test('dispose closes the state stream', () async {
      await manager.dispose();
      // Stream should be closed — adding a listener should not receive events.
      var received = false;
      manager.state.listen((_) => received = true);
      // No new events should arrive since the controller is closed.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(received, isFalse);
    });

    test('double stop is safe', () async {
      await manager.start(adapter, _device);
      await manager.stop();
      await manager.stop(); // Should not throw.
      expect(manager.snapshot.phase, SessionPhase.disconnected);
    });

    test('stop invalidates a connection that completes later', () async {
      adapter.connectGate = Completer<void>();
      final start = manager.start(adapter, _device);
      await Future<void>.delayed(Duration.zero);

      final stop = manager.stop();
      adapter.connectGate!.complete();
      await Future.wait([start, stop]);

      expect(manager.snapshot.phase, SessionPhase.disconnected);
      expect(manager.adapter, isNull);
      expect(adapter.disconnectCount, greaterThanOrEqualTo(1));
    });

    test('snapshot retains the terminal reconnect error', () async {
      adapter.connectShouldFail = true;
      await manager.start(adapter, _device);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(manager.snapshot.phase, SessionPhase.disconnected);
      expect(manager.snapshot.lastError, contains('reconnect'));
    });
  });

  group('SessionSnapshot', () {
    test('isActive is true only when connected', () {
      expect(
        const SessionSnapshot(phase: SessionPhase.connected).isActive,
        isTrue,
      );
      expect(
        const SessionSnapshot(phase: SessionPhase.reconnecting).isActive,
        isFalse,
      );
    });

    test('isRecovering is true only when reconnecting', () {
      expect(
        const SessionSnapshot(phase: SessionPhase.reconnecting).isRecovering,
        isTrue,
      );
      expect(
        const SessionSnapshot(phase: SessionPhase.connected).isRecovering,
        isFalse,
      );
    });
  });
}
