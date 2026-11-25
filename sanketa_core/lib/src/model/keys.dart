/// Remote keys and press semantics.
///
/// This is the *canonical* key vocabulary. Adapters map these onto each
/// platform's native codes; the UI renders only the keys an adapter declares in
/// its [CapabilityMap] (PRD FR-3.5: "users never press dead buttons"). Platform-
/// idiomatic keys (Roku star/replay, Fire TV menu, Android TV assistant) live in
/// the same enum and are surfaced only where supported — capability flags drive
/// the UI, never brand names.
library;

/// Every logical key a remote surface can emit.
enum Key {
  // Power
  power, // toggle
  powerOn,
  powerOff,

  // Volume
  volumeUp,
  volumeDown,
  mute,

  // D-pad / navigation
  up,
  down,
  left,
  right,
  ok, // select / enter-on-focus
  back,
  home,
  menu,
  exit,

  // Media transport
  play,
  pause,
  playPause,
  stop,
  rewind,
  fastForward,
  previous,
  next,
  record,

  // Channel
  channelUp,
  channelDown,

  // Source / input
  input,

  // Digits
  digit0,
  digit1,
  digit2,
  digit3,
  digit4,
  digit5,
  digit6,
  digit7,
  digit8,
  digit9,

  // Info / guide / options
  info,
  guide,
  options,
  subtitle,
  audioTrack,

  // Colour keys (teletext / app shortcuts on many platforms)
  red,
  green,
  yellow,
  blue,

  // Text-editing keys (distinct from TextOp: these are raw remote keys)
  backspace,
  enter,

  // AC / climate (raw-IR per-button, not full-state AcEncoder)
  acMode,
  acSwing,
  acTemperatureUp,
  acTemperatureDown,
  acFanSpeed,

  // Broadcast / teletext
  teletext,
  source, // explicit source/input toggle (alias semantics: same as input on some platforms)

  // Platform-idiomatic (surfaced only where the adapter declares support)
  star, // Roku *
  instantReplay, // Roku replay
  assistant, // Android TV / Google TV
  search,
  keyboard, // opens the platform's on-screen keyboard where that is the flow
}

/// How a key press is delivered. Hold is modelled as an explicit start/end pair
/// so adapters can emit repeat frames for the duration (PRD FR-2.4: volume-hold
/// ramp; NFR-2 for IR timing).
enum PressType {
  tap,
  holdStart,
  holdEnd,
}
