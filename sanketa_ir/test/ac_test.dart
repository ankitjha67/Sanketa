import 'package:sanketa_ir/sanketa_ir.dart';
import 'package:test/test.dart';

class FakeIrTransmitter implements IrTransmitter {
  FakeIrTransmitter({this.available = true});
  @override
  bool available;
  final List<IrSignal> sent = [];
  @override
  Future<void> transmit(IrSignal signal) async => sent.add(signal);
}

void main() {
  const enc = CoolixAcEncoder();

  group('Coolix encoder', () {
    test('power-off yields the documented 0xB27BE0 code', () {
      expect(enc.buildCode(const AcState(power: false)), 0xB27BE0);
    });

    test('temperature uses the documented gray-code nibble (bits 4-7)', () {
      for (var t = 17; t <= 30; t++) {
        final code = enc.buildCode(AcState(tempC: t));
        expect((code >> 4) & 0xF, CoolixAcEncoder.tempGray[t - 17]);
      }
    });

    test('temperature clamps to 17..30', () {
      expect((enc.buildCode(const AcState(tempC: 5)) >> 4) & 0xF,
          CoolixAcEncoder.tempGray[0]); // 17
      expect((enc.buildCode(const AcState(tempC: 40)) >> 4) & 0xF,
          CoolixAcEncoder.tempGray[13]); // 30
    });

    test('encoded frame: 38 kHz, header, 48-bit structure', () {
      final sig = enc.encode(const AcState());
      expect(sig.carrierHz, 38000);
      expect(sig.pattern.take(2).toList(), [4692, 4416]);
      // 2 header + 6 bytes*8 bits*2 + 1 lead-out = 99
      expect(sig.pattern.length, 99);
    });

    test('distinct states produce distinct frames', () {
      final a = enc.encode(const AcState(tempC: 20));
      final b = enc.encode(const AcState(tempC: 26));
      expect(a.pattern, isNot(equals(b.pattern)));
    });
  });

  group('IrAcController', () {
    test('temp up/down mutate state and emit a full frame each', () async {
      final tx = FakeIrTransmitter();
      final ac = IrAcController(
          encoder: enc, transmitter: tx, initial: const AcState(tempC: 24));
      await ac.tempUp();
      expect(ac.state.tempC, 25);
      await ac.tempDown();
      await ac.tempDown();
      expect(ac.state.tempC, 23);
      expect(tx.sent, hasLength(3)); // one frame per action
    });

    test('temp clamps at the encoder max', () async {
      final tx = FakeIrTransmitter();
      final ac = IrAcController(
          encoder: enc, transmitter: tx, initial: const AcState(tempC: 30));
      await ac.tempUp();
      expect(ac.state.tempC, 30);
    });

    test('power off emits the OFF code', () async {
      final tx = FakeIrTransmitter();
      final ac = IrAcController(encoder: enc, transmitter: tx);
      await ac.setPower(on: false);
      expect(ac.state.power, isFalse);
      expect(tx.sent.single.pattern, enc.encode(const AcState(power: false)).pattern);
    });

    test('no emitter → clean failure, state unchanged', () async {
      final ac = IrAcController(
        encoder: enc,
        transmitter: FakeIrTransmitter(available: false),
        initial: const AcState(tempC: 24),
      );
      final res = await ac.tempUp();
      expect(res.ok, isFalse);
      expect(ac.state.tempC, 24); // not mutated on failed emit
    });
  });
}
