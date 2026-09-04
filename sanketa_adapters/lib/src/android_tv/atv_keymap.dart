/// Canonical [Key] → Android `KEYCODE_*` mapping for the remote protocol.
///
/// These are stable, documented Android key codes (android.view.KeyEvent), so
/// this mapping is correct and unit-tested. The remote protocol injects a
/// keycode plus a direction (short press vs. long-press start/end).
library;

import 'package:sanketa_core/sanketa_core.dart';

/// Direction of a key injection in the remote protocol.
enum AtvDirection { short, startLong, endLong }

AtvDirection atvDirectionFor(PressType press) => switch (press) {
      PressType.tap => AtvDirection.short,
      PressType.holdStart => AtvDirection.startLong,
      PressType.holdEnd => AtvDirection.endLong,
    };

/// android.view.KeyEvent constants.
const Map<Key, int> androidKeyCodes = {
  Key.power: 26, // KEYCODE_POWER
  Key.powerOn: 26,
  Key.powerOff: 26,
  Key.volumeUp: 24, // KEYCODE_VOLUME_UP
  Key.volumeDown: 25, // KEYCODE_VOLUME_DOWN
  Key.mute: 164, // KEYCODE_VOLUME_MUTE
  Key.up: 19, // KEYCODE_DPAD_UP
  Key.down: 20, // KEYCODE_DPAD_DOWN
  Key.left: 21, // KEYCODE_DPAD_LEFT
  Key.right: 22, // KEYCODE_DPAD_RIGHT
  Key.ok: 23, // KEYCODE_DPAD_CENTER
  Key.back: 4, // KEYCODE_BACK
  Key.home: 3, // KEYCODE_HOME
  Key.menu: 82, // KEYCODE_MENU
  Key.play: 126, // KEYCODE_MEDIA_PLAY
  Key.pause: 127, // KEYCODE_MEDIA_PAUSE
  Key.playPause: 85, // KEYCODE_MEDIA_PLAY_PAUSE
  Key.stop: 86, // KEYCODE_MEDIA_STOP
  Key.rewind: 89, // KEYCODE_MEDIA_REWIND
  Key.fastForward: 90, // KEYCODE_MEDIA_FAST_FORWARD
  Key.previous: 88, // KEYCODE_MEDIA_PREVIOUS
  Key.next: 87, // KEYCODE_MEDIA_NEXT
  Key.channelUp: 166, // KEYCODE_CHANNEL_UP
  Key.channelDown: 167, // KEYCODE_CHANNEL_DOWN
  Key.input: 178, // KEYCODE_TV_INPUT
  Key.info: 165, // KEYCODE_INFO
  Key.guide: 172, // KEYCODE_GUIDE
  Key.assistant: 219, // KEYCODE_ASSIST
  Key.search: 84, // KEYCODE_SEARCH
  Key.backspace: 67, // KEYCODE_DEL
  Key.enter: 66, // KEYCODE_ENTER
  Key.digit0: 7,
  Key.digit1: 8,
  Key.digit2: 9,
  Key.digit3: 10,
  Key.digit4: 11,
  Key.digit5: 12,
  Key.digit6: 13,
  Key.digit7: 14,
  Key.digit8: 15,
  Key.digit9: 16,
};
