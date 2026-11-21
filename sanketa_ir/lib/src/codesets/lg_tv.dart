/// LG TV codeset — NEC protocol, address 0x04.
///
/// LG TVs use NEC encoding with device address 4. These are the standard
/// LG remote codes compatible with AKB-series remotes.
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';

const lgTvCodeset = IrCodeset(
  id: 'lg_tv_nec_addr4',
  brand: BrandFamily.webOs,
  deviceType: DeviceType.tv,
  name: 'LG TV (NEC)',
  keys: {
    Key.power: IrCommand(protocol: IrProtocol.nec, address: 4, command: 8),
    Key.volumeUp: IrCommand(protocol: IrProtocol.nec, address: 4, command: 2),
    Key.volumeDown: IrCommand(protocol: IrProtocol.nec, address: 4, command: 3),
    Key.mute: IrCommand(protocol: IrProtocol.nec, address: 4, command: 9),
    Key.channelUp: IrCommand(protocol: IrProtocol.nec, address: 4, command: 0),
    Key.channelDown: IrCommand(protocol: IrProtocol.nec, address: 4, command: 1),
    Key.input: IrCommand(protocol: IrProtocol.nec, address: 4, command: 11),
    Key.up: IrCommand(protocol: IrProtocol.nec, address: 4, command: 64),
    Key.down: IrCommand(protocol: IrProtocol.nec, address: 4, command: 65),
    Key.left: IrCommand(protocol: IrProtocol.nec, address: 4, command: 7),
    Key.right: IrCommand(protocol: IrProtocol.nec, address: 4, command: 6),
    Key.ok: IrCommand(protocol: IrProtocol.nec, address: 4, command: 68),
    Key.back: IrCommand(protocol: IrProtocol.nec, address: 4, command: 40),
    Key.home: IrCommand(protocol: IrProtocol.nec, address: 4, command: 67),
    Key.menu: IrCommand(protocol: IrProtocol.nec, address: 4, command: 67),
    Key.exit: IrCommand(protocol: IrProtocol.nec, address: 4, command: 91),
    Key.info: IrCommand(protocol: IrProtocol.nec, address: 4, command: 170),
    Key.guide: IrCommand(protocol: IrProtocol.nec, address: 4, command: 171),
    Key.play: IrCommand(protocol: IrProtocol.nec, address: 4, command: 176),
    Key.pause: IrCommand(protocol: IrProtocol.nec, address: 4, command: 186),
    Key.stop: IrCommand(protocol: IrProtocol.nec, address: 4, command: 177),
    Key.rewind: IrCommand(protocol: IrProtocol.nec, address: 4, command: 143),
    Key.fastForward: IrCommand(protocol: IrProtocol.nec, address: 4, command: 142),
    Key.digit0: IrCommand(protocol: IrProtocol.nec, address: 4, command: 16),
    Key.digit1: IrCommand(protocol: IrProtocol.nec, address: 4, command: 17),
    Key.digit2: IrCommand(protocol: IrProtocol.nec, address: 4, command: 18),
    Key.digit3: IrCommand(protocol: IrProtocol.nec, address: 4, command: 19),
    Key.digit4: IrCommand(protocol: IrProtocol.nec, address: 4, command: 20),
    Key.digit5: IrCommand(protocol: IrProtocol.nec, address: 4, command: 21),
    Key.digit6: IrCommand(protocol: IrProtocol.nec, address: 4, command: 22),
    Key.digit7: IrCommand(protocol: IrProtocol.nec, address: 4, command: 23),
    Key.digit8: IrCommand(protocol: IrProtocol.nec, address: 4, command: 24),
    Key.digit9: IrCommand(protocol: IrProtocol.nec, address: 4, command: 25),
    Key.red: IrCommand(protocol: IrProtocol.nec, address: 4, command: 114),
    Key.green: IrCommand(protocol: IrProtocol.nec, address: 4, command: 113),
    Key.yellow: IrCommand(protocol: IrProtocol.nec, address: 4, command: 99),
    Key.blue: IrCommand(protocol: IrProtocol.nec, address: 4, command: 97),
  },
);
