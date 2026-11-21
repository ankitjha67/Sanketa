/// Samsung TV codeset — NEC protocol, address 0x07.
///
/// Samsung TVs use NEC encoding with a fixed device address of 7. The command
/// codes below are the published Samsung remote codes used across their TV
/// lineup (compatible with BN59-series remotes).
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';

const samsungTvCodeset = IrCodeset(
  id: 'samsung_tv_nec_addr7',
  brand: BrandFamily.tizen,
  deviceType: DeviceType.tv,
  name: 'Samsung TV (NEC)',
  keys: {
    Key.power: IrCommand(protocol: IrProtocol.nec, address: 7, command: 2),
    Key.volumeUp: IrCommand(protocol: IrProtocol.nec, address: 7, command: 7),
    Key.volumeDown: IrCommand(protocol: IrProtocol.nec, address: 7, command: 11),
    Key.mute: IrCommand(protocol: IrProtocol.nec, address: 7, command: 15),
    Key.channelUp: IrCommand(protocol: IrProtocol.nec, address: 7, command: 18),
    Key.channelDown: IrCommand(protocol: IrProtocol.nec, address: 7, command: 16),
    Key.input: IrCommand(protocol: IrProtocol.nec, address: 7, command: 1),
    Key.up: IrCommand(protocol: IrProtocol.nec, address: 7, command: 96),
    Key.down: IrCommand(protocol: IrProtocol.nec, address: 7, command: 97),
    Key.left: IrCommand(protocol: IrProtocol.nec, address: 7, command: 101),
    Key.right: IrCommand(protocol: IrProtocol.nec, address: 7, command: 98),
    Key.ok: IrCommand(protocol: IrProtocol.nec, address: 7, command: 104),
    Key.back: IrCommand(protocol: IrProtocol.nec, address: 7, command: 88),
    Key.home: IrCommand(protocol: IrProtocol.nec, address: 7, command: 121),
    Key.menu: IrCommand(protocol: IrProtocol.nec, address: 7, command: 26),
    Key.exit: IrCommand(protocol: IrProtocol.nec, address: 7, command: 45),
    Key.info: IrCommand(protocol: IrProtocol.nec, address: 7, command: 31),
    Key.guide: IrCommand(protocol: IrProtocol.nec, address: 7, command: 79),
    Key.digit0: IrCommand(protocol: IrProtocol.nec, address: 7, command: 17),
    Key.digit1: IrCommand(protocol: IrProtocol.nec, address: 7, command: 4),
    Key.digit2: IrCommand(protocol: IrProtocol.nec, address: 7, command: 5),
    Key.digit3: IrCommand(protocol: IrProtocol.nec, address: 7, command: 6),
    Key.digit4: IrCommand(protocol: IrProtocol.nec, address: 7, command: 8),
    Key.digit5: IrCommand(protocol: IrProtocol.nec, address: 7, command: 9),
    Key.digit6: IrCommand(protocol: IrProtocol.nec, address: 7, command: 10),
    Key.digit7: IrCommand(protocol: IrProtocol.nec, address: 7, command: 12),
    Key.digit8: IrCommand(protocol: IrProtocol.nec, address: 7, command: 13),
    Key.digit9: IrCommand(protocol: IrProtocol.nec, address: 7, command: 14),
    Key.red: IrCommand(protocol: IrProtocol.nec, address: 7, command: 108),
    Key.green: IrCommand(protocol: IrProtocol.nec, address: 7, command: 20),
    Key.yellow: IrCommand(protocol: IrProtocol.nec, address: 7, command: 21),
    Key.blue: IrCommand(protocol: IrProtocol.nec, address: 7, command: 22),
  },
);
