/// Maps external IR database button names to the canonical [Key] enum.
///
/// Flipper Zero IRDB, LIRC, and community-captured remotes all use their own
/// naming conventions. This map normalises them into a single vocabulary so
/// every source feeds into the same [IrCodeset] model.
library;

import 'package:sanketa_core/sanketa_core.dart';

/// Resolve an external button name to a canonical [Key], or `null` if unmapped.
///
/// Matching is case-insensitive and collapses spaces, hyphens, and underscores
/// into a single canonical form before lookup.
Key? resolveKeyName(String name) {
  final norm = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '_');
  return _map[norm];
}

const _map = <String, Key>{
  // Power
  'power': Key.power,
  'power_on': Key.powerOn,
  'power_off': Key.powerOff,
  'on': Key.powerOn,
  'off': Key.powerOff,
  'standby': Key.power,
  'key_power': Key.power,
  'key_power2': Key.power,
  'key_suspend': Key.powerOff,
  'key_wakeup': Key.powerOn,

  // Volume
  'vol_up': Key.volumeUp,
  'vol_dn': Key.volumeDown,
  'vol_down': Key.volumeDown,
  'volume_up': Key.volumeUp,
  'volume_down': Key.volumeDown,
  'vol+': Key.volumeUp,
  'vol-': Key.volumeDown,
  'key_volumeup': Key.volumeUp,
  'key_volumedown': Key.volumeDown,
  'mute': Key.mute,
  'key_mute': Key.mute,

  // D-pad / navigation
  'up': Key.up,
  'down': Key.down,
  'left': Key.left,
  'right': Key.right,
  'ok': Key.ok,
  'select': Key.ok,
  'enter': Key.ok,
  'back': Key.back,
  'return': Key.back,
  'home': Key.home,
  'menu': Key.menu,
  'exit': Key.exit,
  'key_up': Key.up,
  'key_down': Key.down,
  'key_left': Key.left,
  'key_right': Key.right,
  'key_ok': Key.ok,
  'key_select': Key.ok,
  'key_enter': Key.ok,
  'key_back': Key.back,
  'key_home': Key.home,
  'key_menu': Key.menu,
  'key_exit': Key.exit,

  // Media transport
  'play': Key.play,
  'pause': Key.pause,
  'play_pause': Key.playPause,
  'playpause': Key.playPause,
  'stop': Key.stop,
  'rewind': Key.rewind,
  'fast_rewind': Key.rewind,
  'rew': Key.rewind,
  'rwd': Key.rewind,
  'fast_forward': Key.fastForward,
  'fastforward': Key.fastForward,
  'ff': Key.fastForward,
  'fwd': Key.fastForward,
  'prev': Key.previous,
  'previous': Key.previous,
  'next': Key.next,
  'record': Key.record,
  'rec': Key.record,
  'key_play': Key.play,
  'key_pause': Key.pause,
  'key_playpause': Key.playPause,
  'key_stop': Key.stop,
  'key_rewind': Key.rewind,
  'key_fastforward': Key.fastForward,
  'key_previous': Key.previous,
  'key_next': Key.next,
  'key_record': Key.record,

  // Channel
  'ch_next': Key.channelUp,
  'ch_prev': Key.channelDown,
  'ch_up': Key.channelUp,
  'ch_dn': Key.channelDown,
  'ch_down': Key.channelDown,
  'channel_up': Key.channelUp,
  'channel_down': Key.channelDown,
  'ch+': Key.channelUp,
  'ch-': Key.channelDown,
  'key_channelup': Key.channelUp,
  'key_channeldown': Key.channelDown,

  // Source / input
  'input': Key.input,
  'source': Key.input,
  'key_switchvideomode': Key.input,

  // Digits
  '0': Key.digit0,
  '1': Key.digit1,
  '2': Key.digit2,
  '3': Key.digit3,
  '4': Key.digit4,
  '5': Key.digit5,
  '6': Key.digit6,
  '7': Key.digit7,
  '8': Key.digit8,
  '9': Key.digit9,
  'key_0': Key.digit0,
  'key_1': Key.digit1,
  'key_2': Key.digit2,
  'key_3': Key.digit3,
  'key_4': Key.digit4,
  'key_5': Key.digit5,
  'key_6': Key.digit6,
  'key_7': Key.digit7,
  'key_8': Key.digit8,
  'key_9': Key.digit9,

  // Info / guide / options
  'info': Key.info,
  'guide': Key.guide,
  'epg': Key.guide,
  'options': Key.options,
  'subtitle': Key.subtitle,
  'subtitles': Key.subtitle,
  'audio': Key.audioTrack,
  'audio_track': Key.audioTrack,
  'key_info': Key.info,
  'key_program': Key.guide,
  'key_subtitle': Key.subtitle,
  'key_audio': Key.audioTrack,

  // Colour keys
  'red': Key.red,
  'green': Key.green,
  'yellow': Key.yellow,
  'blue': Key.blue,
  'key_red': Key.red,
  'key_green': Key.green,
  'key_yellow': Key.yellow,
  'key_blue': Key.blue,

  // Backspace / enter (text)
  'backspace': Key.backspace,
  'delete': Key.backspace,
  'key_backspace': Key.backspace,
  'key_delete': Key.backspace,
  'ent': Key.enter,

  // Search / assistant
  'search': Key.search,
  'key_search': Key.search,

  // Sleep
  'sleep': Key.power,

  // Kookong function names
  'navigate_up': Key.up,
  'navigate_down': Key.down,
  'navigate_left': Key.left,
  'navigate_right': Key.right,
  'ok/select': Key.ok,
  'select(enter)': Key.ok,
  'homepage': Key.home,
  'last': Key.back,
  'display': Key.info,
  'livetv': Key.home,
  'popmenu': Key.menu,
  'eject': Key.stop,
  'page_up': Key.channelUp,
  'page_down': Key.channelDown,
  'page up': Key.channelUp,
  'page down': Key.channelDown,
  'tools': Key.options,
  'apps': Key.home,
  'tv': Key.input,
  'sound_mode': Key.audioTrack,
  'picture_mode': Key.options,
  'sound mode': Key.audioTrack,
  'picture mode': Key.options,

  // AC / climate buttons (raw-IR per-button remotes)
  'mode': Key.acMode,
  'swing': Key.acSwing,
  'temperature_up': Key.acTemperatureUp,
  'temperature_down': Key.acTemperatureDown,
  'wind_speed': Key.acFanSpeed,
};
