// Compile IR signals from the bundled Sony codeset and print what would hit the
// hardware — carrier, length, on-air duration, and the first timings.
//   dart run sanketa_ir/example/ir_compile.dart
// ignore_for_file: avoid_print
import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_ir/sanketa_ir.dart';

void main() {
  const codec = IrCodec();

  print('Sony TV (SIRC) — compiled signals:');
  for (final key in [Key.power, Key.volumeUp, Key.mute, Key.digit5]) {
    final cmd = sonyTvCodeset.keys[key]!;
    final sig = codec.encode(cmd);
    print('  ${key.name.padRight(11)} carrier=${sig.carrierHz}Hz  '
        'len=${sig.pattern.length}  onair=${sig.durationMicros}µs');
    print('      first: ${sig.pattern.take(10).toList()} ...');
  }

  final nec = codec.encode(
      const IrCommand(protocol: IrProtocol.nec, address: 0x04, command: 0x08));
  print('\nGeneric NEC 0x04/0x08: carrier=${nec.carrierHz}Hz  '
      'len=${nec.pattern.length}  onair=${nec.durationMicros}µs');
  print('  repeat frame: ${nec.repeat}');
}
