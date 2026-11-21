/// Maps Kookong IR SDK function IDs to canonical [Key] enum values.
///
/// The Kookong SDK (used by many Chinese IR remote apps) assigns numeric IDs to
/// IR functions. While the Kookong *code database* is encrypted in native code
/// (impractical to extract), the function-ID-to-name mapping from
/// `KookongAllKey.json` is readable and useful for normalising key names across
/// sources. This map covers the IDs that correspond to our canonical Key enum.
///
/// Source: `assets/KookongAllKey.json` from the IR Remote APK, which contains
/// 6,303 entries with multilingual labels. Only the subset mappable to our Key
/// vocabulary is retained here.
library;

import 'package:sanketa_core/sanketa_core.dart';

/// Resolve a Kookong function ID to a canonical [Key], or `null` if unmapped.
Key? kookongIdToKey(int id) => _kookongMap[id];

/// Resolve a Kookong English function name to a canonical [Key].
Key? kookongNameToKey(String name) {
  final norm = name.trim().toUpperCase();
  return _kookongNameMap[norm];
}

const _kookongMap = <int, Key>{
  1: Key.power,       // POWER
  12: Key.mute,       // MUTE
  14: Key.volumeUp,   // VOL+
  15: Key.volumeDown, // VOL-
  16: Key.channelUp,  // CH+
  17: Key.channelDown, // CH-
  40: Key.up,         // UP
  41: Key.down,       // DOWN
  42: Key.left,       // LEFT
  43: Key.right,      // RIGHT
  44: Key.ok,         // OK/ENTER
  45: Key.menu,       // MENU
  47: Key.back,       // BACK/RETURN
  48: Key.exit,       // EXIT
  49: Key.home,       // HOME
  50: Key.input,      // SOURCE/INPUT
  51: Key.info,       // INFO/DISPLAY
  52: Key.guide,      // EPG/GUIDE
  60: Key.play,       // PLAY
  61: Key.pause,      // PAUSE
  62: Key.stop,       // STOP
  63: Key.rewind,     // REW
  64: Key.fastForward, // FF
  65: Key.record,     // REC
  66: Key.previous,   // PREV
  67: Key.next,       // NEXT
  70: Key.digit0,     // 0
  71: Key.digit1,     // 1
  72: Key.digit2,     // 2
  73: Key.digit3,     // 3
  74: Key.digit4,     // 4
  75: Key.digit5,     // 5
  76: Key.digit6,     // 6
  77: Key.digit7,     // 7
  78: Key.digit8,     // 8
  79: Key.digit9,     // 9
  80: Key.red,        // RED
  81: Key.green,      // GREEN
  82: Key.yellow,     // YELLOW
  83: Key.blue,       // BLUE
  90: Key.subtitle,   // SUBTITLE
  91: Key.audioTrack, // AUDIO
};

const _kookongNameMap = <String, Key>{
  'POWER': Key.power,
  'MUTE': Key.mute,
  'VOL+': Key.volumeUp,
  'VOL-': Key.volumeDown,
  'CH+': Key.channelUp,
  'CH-': Key.channelDown,
  'UP': Key.up,
  'DOWN': Key.down,
  'LEFT': Key.left,
  'RIGHT': Key.right,
  'OK': Key.ok,
  'ENTER': Key.ok,
  'MENU': Key.menu,
  'BACK': Key.back,
  'RETURN': Key.back,
  'EXIT': Key.exit,
  'HOME': Key.home,
  'SOURCE': Key.input,
  'INPUT': Key.input,
  'INFO': Key.info,
  'DISPLAY': Key.info,
  'EPG': Key.guide,
  'GUIDE': Key.guide,
  'PLAY': Key.play,
  'PAUSE': Key.pause,
  'STOP': Key.stop,
  'REW': Key.rewind,
  'REWIND': Key.rewind,
  'FF': Key.fastForward,
  'FAST_FORWARD': Key.fastForward,
  'REC': Key.record,
  'RECORD': Key.record,
  'PREV': Key.previous,
  'PREVIOUS': Key.previous,
  'NEXT': Key.next,
  'RED': Key.red,
  'GREEN': Key.green,
  'YELLOW': Key.yellow,
  'BLUE': Key.blue,
  'SUBTITLE': Key.subtitle,
  'AUDIO': Key.audioTrack,
};
