import 'package:sanketa_core/sanketa_core.dart';

/// A no-hardware [ControlAdapter] for running the UI: it records each command so
/// the screen can show a live "sent to TV" log, and reports full capabilities so
/// every control renders. Swapping in a real adapter (Roku, Android TV, IR, …)
/// changes nothing above this contract — that is the whole point of the design.
class DemoAdapter implements ControlAdapter {
  DemoAdapter(this.onAction);

  final void Function(String action) onAction;

  @override
  String get id => 'demo';

  @override
  BrandFamily get brandFamily => BrandFamily.androidTv;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints();

  @override
  CapabilityMap capabilities() => CapabilityMap(
        keys: Key.values.toSet(),
        textMode: TextInjectionMode.live,
        wake: true,
        appLaunch: true,
        inputList: true,
        volumeReadback: true,
        stateReadback: false,
      );

  @override
  Future<PairingResult> pair(PairingContext context) async =>
      const PairingResult.paired('demo');

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> heartbeat() async => true;

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) async {
    onAction('key · ${key.name}${press == PressType.tap ? '' : ' (${press.name})'}');
    return const CommandResult.success();
  }

  @override
  Future<CommandResult> sendText(TextOp op) async {
    onAction('text · ${op.kind.name}');
    return const CommandResult.success();
  }

  @override
  Future<CommandResult> launchApp(AppRef app) async {
    onAction('launch · ${app.name ?? app.id}');
    return const CommandResult.success();
  }

  @override
  Future<CommandResult> setInput(InputRef input) async {
    onAction('input · ${input.id}');
    return const CommandResult.success();
  }

  @override
  Future<CommandResult> power({required bool on}) async {
    onAction('power · ${on ? 'on' : 'off'}');
    return const CommandResult.success();
  }

  @override
  Stream<StateDelta> readState() => const Stream<StateDelta>.empty();
}
