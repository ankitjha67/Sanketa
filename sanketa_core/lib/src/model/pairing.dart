/// Pairing and command-result types.
///
/// Pairing drives each platform's native auth flow (PRD FR-1.4): on-screen PIN,
/// on-TV allow prompt, pre-shared key, or no-auth-with-confirmation. The adapter
/// asks the UI for what it needs through [PairingContext] callbacks and returns a
/// [PairingResult]. Any returned [PairingResult.credential] is a handle to be
/// persisted in the PairingVault (Keystore/Keychain) — never written to the DB or
/// logs in plaintext (NFR-10, CONTEXT.md §9.10).
library;

/// Callbacks the UI provides so an adapter can complete platform-native auth
/// without knowing anything about the UI layer.
class PairingContext {
  const PairingContext({this.requestPin, this.notify});

  /// Prompt the user to type the PIN currently shown on the TV (Android TV,
  /// Vizio, Philips digest, BRAVIA PIN). Returns the entered code.
  final Future<String> Function()? requestPin;

  /// Surface a non-blocking instruction, e.g. "Approve SANKETA on your TV"
  /// (Samsung token grant, webOS allow prompt).
  final void Function(String message)? notify;
}

enum PairingStatus {
  paired,
  needsPin, // adapter needs the UI to call requestPin (should not happen if provided)
  needsUserConfirmation, // waiting on the on-TV allow prompt
  failed,
}

class PairingResult {
  const PairingResult({required this.status, this.credential, this.error});

  const PairingResult.paired(String credential)
      : this(status: PairingStatus.paired, credential: credential);

  const PairingResult.failed(String error)
      : this(status: PairingStatus.failed, error: error);

  final PairingStatus status;

  /// Opaque handle (token / client-key / cert alias) for the PairingVault.
  /// NOT the secret material itself where the platform lets us avoid holding it.
  final String? credential;

  /// Developer-facing reason. Never rendered raw to users (CONTEXT.md §9.8);
  /// the UI maps failure classes to human copy + one actionable next step.
  final String? error;

  bool get isPaired => status == PairingStatus.paired;
}

/// The result of a single command dispatch. Carries [latency] so command timing
/// is instrumentable from day one against NFR-1 (network p95 < 250 ms) and
/// NFR-2 (IR tap-to-emit < 100 ms).
class CommandResult {
  const CommandResult({required this.ok, this.error, this.latency});

  const CommandResult.success({Duration? latency})
      : this(ok: true, latency: latency);

  const CommandResult.failure(String error)
      : this(ok: false, error: error);

  final bool ok;

  /// Developer-facing only; never shown as a raw code in primary UI copy.
  final String? error;

  /// Measured tap-to-dispatch latency, when the adapter records it.
  final Duration? latency;
}
