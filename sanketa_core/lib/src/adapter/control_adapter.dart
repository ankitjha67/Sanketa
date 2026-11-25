/// The ControlAdapter contract — the single interface every controllable target
/// implements (PRD §13.3, "the moat").
///
/// Design rules that this contract exists to enforce:
///   1. Nothing above this interface knows brands exist. Callers speak in
///      [Key], [TextOp], [AppRef], [InputRef], [CapabilityMap] — never brand names.
///   2. Every quirk (firmware branches, retry policies, port fallbacks) lives
///      INSIDE an implementation, not in the core.
///   3. Adapters are stateless above their session object.
///   4. One conformance suite runs the identical script against every adapter
///      (PRD FR-3.1 AC: ≥95% of the declared command set before an adapter ships).
///   5. Adding a brand touches zero core code (NFR-14).
library;

import '../model/capabilities.dart';
import '../model/device.dart';
import '../model/keys.dart';
import '../model/pairing.dart';
import '../model/text.dart';

/// One interface, every brand. Implementations exist for Android TV, Tizen,
/// webOS, Roku, BRAVIA (MVP), then Fire TV, Vizio, Panasonic, Philips, Hisense,
/// TCL, generic DLNA, IR, and the BroadLink bridge (Phase 2).
abstract class ControlAdapter {
  // --- Metadata -------------------------------------------------------------

  /// Stable adapter identifier (e.g. `roku`, `android_tv`). Not user-facing.
  String get id;

  BrandFamily get brandFamily;

  Transport get transport;

  /// What the discovery engine should look for to find targets for this adapter.
  DiscoveryHints get discoveryHints;

  // --- Capability ------------------------------------------------------------

  /// The full capability map for the currently-bound target. Drives the UI.
  /// May reflect defaults before [connect]; refined once connected where the
  /// platform reports its own feature set (e.g. webOS input list).
  CapabilityMap capabilities();

  // --- Lifecycle -------------------------------------------------------------

  /// Drive the platform-native auth flow. Idempotent where already paired: a
  /// valid persisted credential should short-circuit to
  /// [PairingStatus.paired] without re-prompting.
  Future<PairingResult> pair(PairingContext context);

  /// Open the control session (persistent socket where the platform uses one).
  Future<void> connect();

  /// Close the session and release resources.
  Future<void> disconnect();

  /// Liveness probe for the session. Returns false if the link is dead so the
  /// SessionManager can trigger backoff/reconnect (PRD FR-3.2).
  Future<bool> heartbeat();

  // --- Commands --------------------------------------------------------------

  /// Emit a key. [press] models tap vs. hold-start/hold-end for repeat frames.
  Future<CommandResult> sendKey(Key key, {PressType press = PressType.tap});

  /// Apply a text operation to the TV's focused field. On
  /// [TextInjectionMode.none] adapters this throws [UnsupportedError]; callers
  /// gate on [CapabilityMap.canType] first (the UI already does via FR-4.1).
  Future<CommandResult> sendText(TextOp op);

  /// Foreground an app on the target (FR-6).
  Future<CommandResult> launchApp(AppRef app);

  /// Switch input/source (FR-6).
  Future<CommandResult> setInput(InputRef input);

  /// Power the device on/off. Power-on uses the platform's wake path
  /// (WoL/WoWLAN or protocol-native); only offered where `capabilities().wake`.
  Future<CommandResult> power({required bool on});

  // --- State -----------------------------------------------------------------

  /// Optional stream of state changes (volume, mute, current app, power).
  /// Write-only platforms return an empty stream and set
  /// `capabilities().stateReadback = false` so the UI makes no state claims
  /// (PRD FR-3.4).
  Stream<StateDelta> readState();

  // --- Readback queries (FR-3.4) -------------------------------------------

  /// Query current volume (0–100). Returns null if unsupported or offline.
  Future<int?> getVolume() async => null;

  /// Query mute state. Returns null if unsupported.
  Future<bool?> getMuted() async => null;

  /// Query power state. Returns null if unsupported.
  Future<PowerState?> getPowerState() async => null;

  /// Query currently active app. Returns null if unsupported.
  Future<AppRef?> getCurrentApp() async => null;
}
