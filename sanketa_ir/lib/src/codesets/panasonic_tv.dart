/// Panasonic TV codeset — NEC-extended protocol.
///
/// Panasonic TVs typically use NEC-extended with address 0x0040 (Panasonic
/// manufacturer code). These are compatible with N2QAYB-series remotes.
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';

const panasonicTvCodeset = IrCodeset(
  id: 'panasonic_tv_nec_ext',
  brand: BrandFamily.panasonic,
  deviceType: DeviceType.tv,
  name: 'Panasonic TV',
  keys: {
    Key.power: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x3D),
    Key.volumeUp: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x20),
    Key.volumeDown: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x21),
    Key.mute: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x32),
    Key.channelUp: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x34),
    Key.channelDown: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x35),
    Key.input: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0xA0),
    Key.up: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x52),
    Key.down: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x53),
    Key.left: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x54),
    Key.right: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x55),
    Key.ok: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x49),
    Key.back: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x2B),
    Key.home: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0xD5),
    Key.menu: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x06),
    Key.exit: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0xCB),
    Key.info: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x39),
    Key.guide: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0xE2),
    Key.digit0: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x0A),
    Key.digit1: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x01),
    Key.digit2: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x02),
    Key.digit3: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x03),
    Key.digit4: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x04),
    Key.digit5: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x05),
    Key.digit6: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x06),
    Key.digit7: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x07),
    Key.digit8: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x08),
    Key.digit9: IrCommand(protocol: IrProtocol.necExtended, address: 0x0040, command: 0x09),
  },
);
