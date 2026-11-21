import 'package:sanketa_adapters/src/fire_tv/fire_tv_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

import 'support/fake_atv_channel.dart';

void main() {
  test('id is fire_tv and brand is fireTv', () {
    final adapter = FireTvAdapter(channel: FakeAtvChannel());
    expect(adapter.id, 'fire_tv');
    expect(adapter.brandFamily, BrandFamily.fireTv);
    expect(adapter.transport, Transport.network);
  });

  test('capabilities include menu key (Fire-specific) and live text', () {
    final adapter = FireTvAdapter(channel: FakeAtvChannel());
    final caps = adapter.capabilities();
    expect(caps.supports(Key.menu), isTrue);
    expect(caps.supports(Key.ok), isTrue);
    expect(caps.supports(Key.home), isTrue);
    expect(caps.supports(Key.volumeUp), isTrue);
    expect(caps.textMode, TextInjectionMode.live);
    expect(caps.appLaunch, isTrue);
    expect(caps.wake, isTrue);
  });

  test('discoveryHints include amzn-wplay mDNS and ATVRS ports', () {
    final adapter = FireTvAdapter(channel: FakeAtvChannel());
    final hints = adapter.discoveryHints;
    expect(hints.mdnsServiceTypes, contains('_amzn-wplay._tcp'));
    expect(hints.mdnsServiceTypes, contains('_androidtvremote2._tcp'));
    expect(hints.probePorts, contains(6466));
    expect(hints.probePorts, contains(6467));
  });

  test('pair succeeds when channel connects', () async {
    final ch = FakeAtvChannel();
    final adapter = FireTvAdapter(channel: ch);
    final res = await adapter.pair(const PairingContext());
    expect(res.isPaired, isTrue);
  });

  test('sendKey sends to channel when connected', () async {
    final ch = FakeAtvChannel();
    final adapter = FireTvAdapter(channel: ch);
    await adapter.connect();
    final res = await adapter.sendKey(Key.ok);
    expect(res.ok, isTrue);
    expect(ch.sentRaw, isNotEmpty);
  });

  test('heartbeat reflects channel state', () async {
    final ch = FakeAtvChannel();
    final adapter = FireTvAdapter(channel: ch);
    expect(await adapter.heartbeat(), isFalse);
    await adapter.connect();
    expect(await adapter.heartbeat(), isTrue);
  });
}
