import 'dart:convert';

import 'package:sanketa_adapters/src/webos/webos_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

import 'support/fake_ws_channel.dart';

void main() {
  test('pair registers and captures the client-key', () async {
    final ch = FakeWsChannel(autoReplies: const {
      '"type":"register"':
          '{"type":"registered","payload":{"client-key":"abc123"}}',
    });
    final adapter = WebosAdapter(channel: ch);
    final res = await adapter.pair(const PairingContext());
    expect(res.isPaired, isTrue);
    expect(res.credential, 'abc123');
  });

  test('capabilities: network, live text (IME), app launch', () {
    final adapter = WebosAdapter(channel: FakeWsChannel());
    final caps = adapter.capabilities();
    expect(caps.textMode, TextInjectionMode.live);
    expect(caps.appLaunch, isTrue);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.volumeUp), isTrue);
  });

  test('D-pad keys go as pointer-socket button events', () async {
    final ch = FakeWsChannel();
    final adapter = WebosAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendKey(Key.ok);
    expect(ch.sent.single, contains('name:ENTER'));
    expect(ch.sent.single, startsWith('type:button'));
  });

  test('volume goes as an SSAP request', () async {
    final ch = FakeWsChannel();
    final adapter = WebosAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendKey(Key.volumeUp);
    final data = jsonDecode(ch.sent.single) as Map;
    expect(data['type'], 'request');
    expect(data['uri'], 'ssap://audio/volumeUp');
  });

  test('text insert uses the IME insertText SSAP', () async {
    final ch = FakeWsChannel();
    final adapter = WebosAdapter(channel: ch);
    await adapter.connect();
    await adapter.sendText(const TextOp.insert('hello'));
    final data = jsonDecode(ch.sent.single) as Map;
    expect(data['uri'], 'ssap://com.webos.service.ime/insertText');
    expect((data['payload'] as Map)['text'], 'hello');
  });

  test('launchApp uses system.launcher/launch', () async {
    final ch = FakeWsChannel();
    final adapter = WebosAdapter(channel: ch);
    await adapter.connect();
    await adapter.launchApp(const AppRef(id: 'youtube.leanback.v4'));
    final data = jsonDecode(ch.sent.single) as Map;
    expect(data['uri'], 'ssap://system.launcher/launch');
    expect((data['payload'] as Map)['id'], 'youtube.leanback.v4');
  });

  test('unsupported key fails, nothing sent', () async {
    final ch = FakeWsChannel();
    final adapter = WebosAdapter(channel: ch);
    await adapter.connect();
    final res = await adapter.sendKey(Key.star);
    expect(res.ok, isFalse);
    expect(ch.sent, isEmpty);
  });
}
