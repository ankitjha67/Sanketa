import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';
import 'package:test/test.dart';

class FakeIrTransmitter implements IrTransmitter {
  FakeIrTransmitter({this.available = true});

  @override
  bool available;

  final List<IrSignal> sent = [];

  @override
  Future<void> transmit(IrSignal signal) async {
    sent.add(signal);
  }
}

void main() {
  test('capabilities: infrared transport, no text, wake from powerOn', () {
    final adapter = IrControlAdapter(
      codeset: sonyTvCodeset,
      transmitter: FakeIrTransmitter(),
    );
    final caps = adapter.capabilities();
    expect(adapter.transport, Transport.infrared);
    expect(caps.textMode, TextInjectionMode.none);
    expect(caps.canType, isFalse);
    expect(caps.wake, isTrue); // Sony codeset has powerOn
    expect(caps.supports(Key.volumeUp), isTrue);
    expect(caps.supports(Key.assistant), isFalse); // not in codeset
  });

  test('sendKey emits one signal at the protocol carrier', () async {
    final tx = FakeIrTransmitter();
    final adapter = IrControlAdapter(codeset: sonyTvCodeset, transmitter: tx);
    final res = await adapter.sendKey(Key.volumeUp);
    expect(res.ok, isTrue);
    expect(res.latency, isNotNull);
    expect(tx.sent, hasLength(1));
    expect(tx.sent.single.carrierHz, 40000); // Sony SIRC
  });

  test('power(on) emits the codeset PowerOn command', () async {
    final tx = FakeIrTransmitter();
    final adapter = IrControlAdapter(codeset: sonyTvCodeset, transmitter: tx);
    await adapter.power(on: true);
    const codec = IrCodec();
    final expected = codec.encode(sonyTvCodeset.keys[Key.powerOn]!);
    expect(tx.sent.single.pattern, expected.pattern);
  });

  test('unsupported key fails and emits nothing', () async {
    final tx = FakeIrTransmitter();
    final adapter = IrControlAdapter(codeset: sonyTvCodeset, transmitter: tx);
    final res = await adapter.sendKey(Key.assistant);
    expect(res.ok, isFalse);
    expect(tx.sent, isEmpty);
  });

  test('text injection is refused (assist mode is the path)', () async {
    final adapter = IrControlAdapter(
      codeset: sonyTvCodeset,
      transmitter: FakeIrTransmitter(),
    );
    final res = await adapter.sendText(const TextOp.insert('hi'));
    expect(res.ok, isFalse);
    expect(res.error, contains('assist'));
  });

  test('no emitter hardware → clean failure, not a crash', () async {
    final adapter = IrControlAdapter(
      codeset: sonyTvCodeset,
      transmitter: FakeIrTransmitter(available: false),
    );
    final res = await adapter.sendKey(Key.power);
    expect(res.ok, isFalse);
    expect(res.error, contains('no IR emitter'));
  });

  test('hold resends repeat frames until release, then stops', () async {
    final tx = FakeIrTransmitter();
    final adapter = IrControlAdapter(
      codeset: sonyTvCodeset,
      transmitter: tx,
      repeatInterval: const Duration(milliseconds: 20),
    );

    await adapter.sendKey(Key.volumeUp, press: PressType.holdStart);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await adapter.sendKey(Key.volumeUp, press: PressType.holdEnd);

    final atRelease = tx.sent.length;
    expect(atRelease, greaterThanOrEqualTo(3)); // initial + repeats over ~90ms

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(tx.sent.length, atRelease); // nothing more after release

    adapter.dispose();
  });
}
