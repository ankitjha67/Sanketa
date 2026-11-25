import 'dart:convert';

import 'package:sanketa_adapters/src/tizen/tizen_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

import 'support/fake_ws_channel.dart';

Map<String, dynamic> _params(String frame) =>
    (jsonDecode(frame) as Map)['params'] as Map<String, dynamic>;

void main() {
  test('pair reads the token from ms.channel.connect', () async {
    final ch = FakeWsChannel(emitAfterConnect: const [
      '{"event":"ms.channel.connect","data":{"token":"9999"}}',
    ]);
    final adapter = TizenAdapter(channel: ch);
    final res = await adapter.pair(const PairingContext());
    expect(res.isPaired, isTrue);
    expect(res.credential, '9999');
  });

  test('capabilities: network, live text, supports ok not star', () {
    final adapter = TizenAdapter(channel: FakeWsChannel());
    final caps = adapter.capabilities();
    expect(adapter.transport, Transport.network);
    expect(caps.textMode, TextInjectionMode.live);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.star), isFalse);
  });

  test('sendKey(ok) sends a Click SendRemoteKey with KEY_ENTER', () async {
    final ch = FakeWsChannel(emitAfterConnect: const [
      '{"event":"ms.channel.connect","data":{"token":"test"}}',
    ]);
    final adapter = TizenAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendKey(Key.ok);
    final p = _params(ch.sent.single);
    expect(p['TypeOfRemote'], 'SendRemoteKey');
    expect(p['Cmd'], 'Click');
    expect(p['DataOfCmd'], 'KEY_ENTER');
  });

  test('hold maps to Press then Release', () async {
    final ch = FakeWsChannel(emitAfterConnect: const [
      '{"event":"ms.channel.connect","data":{"token":"test"}}',
    ]);
    final adapter = TizenAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendKey(Key.volumeUp, press: PressType.holdStart);
    await adapter.sendKey(Key.volumeUp, press: PressType.holdEnd);
    expect(_params(ch.sent[0])['Cmd'], 'Press');
    expect(_params(ch.sent[1])['Cmd'], 'Release');
  });

  test('text insert sends SendInputString with base64', () async {
    final ch = FakeWsChannel(emitAfterConnect: const [
      '{"event":"ms.channel.connect","data":{"token":"test"}}',
    ]);
    final adapter = TizenAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendText(const TextOp.insert('hi'));
    final p = _params(ch.sent.single);
    expect(p['TypeOfRemote'], 'SendInputString');
    expect(p['Cmd'], base64.encode(utf8.encode('hi'))); // "aGk="
  });

  test('unsupported key fails, nothing sent', () async {
    final ch = FakeWsChannel(emitAfterConnect: const [
      '{"event":"ms.channel.connect","data":{"token":"test"}}',
    ]);
    final adapter = TizenAdapter(channel: ch);
    await adapter.connect();
    final res = await adapter.sendKey(Key.assistant);
    expect(res.ok, isFalse);
    expect(ch.sent, isEmpty);
  });

  test('commands fail when not connected', () async {
    final adapter = TizenAdapter(channel: FakeWsChannel());
    final res = await adapter.sendKey(Key.home);
    expect(res.ok, isFalse);
  });
}
