/// Amazon Fire TV adapter — Android TV remote with Fire-specific keys.
///
/// Fire TV runs Fire OS (a fork of Android), so the underlying protocol is
/// Android TV Remote Service (ATVRS) on port 6466/6467. This thin wrapper
/// delegates to [AndroidTvAdapter] and adds Fire-specific keys that map to
/// Fire OS keycodes not in the generic Android keymap (PRD FR-3.5 / NFR-14).
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../android_tv/android_tv_adapter.dart';
import '../android_tv/atv_channel.dart';

class FireTvAdapter implements ControlAdapter {
  FireTvAdapter({required AtvChannel channel})
      : _inner = AndroidTvAdapter(channel: channel);

  final AndroidTvAdapter _inner;

  @override
  String get id => 'fire_tv';

  @override
  BrandFamily get brandFamily => BrandFamily.fireTv;

  @override
  Transport get transport => Transport.network;

  @override
  DiscoveryHints get discoveryHints => const DiscoveryHints(
        mdnsServiceTypes: ['_amzn-wplay._tcp', '_androidtvremote2._tcp'],
        probePorts: [6466, 6467],
      );

  @override
  CapabilityMap capabilities() {
    final base = _inner.capabilities();
    return CapabilityMap(
      keys: {...base.keys, Key.menu},
      textMode: base.textMode,
      wake: false,
      volumeReadback: base.volumeReadback,
      appLaunch: true,
      inputList: false,
      stateReadback: base.stateReadback,
    );
  }

  @override
  Future<PairingResult> pair(PairingContext context) => _inner.pair(context);

  @override
  Future<void> connect() => _inner.connect();

  @override
  Future<void> disconnect() => _inner.disconnect();

  @override
  Future<bool> heartbeat() => _inner.heartbeat();

  @override
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap}) =>
      _inner.sendKey(key, press: press);

  @override
  Future<CommandResult> sendText(TextOp op) => _inner.sendText(op);

  @override
  Future<CommandResult> launchApp(AppRef app) => _inner.launchApp(app);

  @override
  Future<CommandResult> setInput(InputRef input) => _inner.setInput(input);

  @override
  Future<CommandResult> power({required bool on}) => _inner.power(on: on);

  @override
  Stream<StateDelta> readState() => _inner.readState();
}
