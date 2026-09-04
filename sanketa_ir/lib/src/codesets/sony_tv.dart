/// A real Sony TV codeset using documented SIRC (12-bit) codes, device
/// address 1. These command values are the long-published Sony TV set — power,
/// volume, channel, mute and digits are canonical; a few navigation keys are
/// marked approximate and get corrected against hardware in Phase 0.
///
/// This ships as a bundled sample so the IR path is demonstrable before the full
/// codeset DB lands (OD-6). It is a genuine codeset, not a placeholder.
library;

import 'package:sanketa_core/sanketa_core.dart';

import '../ir_codeset.dart';
import '../ir_signal.dart';

/// Sony TV, SIRC 12-bit, address 1.
const sonyTvCodeset = IrCodeset(
  id: 'sony_tv_sirc12_addr1',
  brand: BrandFamily.bravia,
  deviceType: DeviceType.tv,
  name: 'Sony TV (SIRC)',
  keys: {
    // Canonical, well-documented SIRC TV codes:
    Key.power: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 21),
    Key.powerOn: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 46),
    Key.powerOff: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 47),
    Key.volumeUp: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 18),
    Key.volumeDown: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 19),
    Key.mute: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 20),
    Key.channelUp: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 16),
    Key.channelDown: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 17),
    Key.input: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 37),
    // Digits: SIRC maps "1"→0 … "9"→8, "0"→9.
    Key.digit1: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 0),
    Key.digit2: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 1),
    Key.digit3: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 2),
    Key.digit4: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 3),
    Key.digit5: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 4),
    Key.digit6: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 5),
    Key.digit7: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 6),
    Key.digit8: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 7),
    Key.digit9: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 8),
    Key.digit0: IrCommand(protocol: IrProtocol.sonySirc12, address: 1, command: 9),
  },
);
