/// The canonical IR representation (PRD §13.4) and its compiled output.
///
/// An [IrCommand] is what a codeset stores: a protocol family plus parameters.
/// [IrCodec] compiles it into an [IrSignal] — a carrier frequency and a timing
/// pattern in microseconds — which is exactly the shape Android's
/// `ConsumerIrManager.transmit(carrierHz, pattern)` wants. Keeping the stored
/// form abstract (protocol + params) rather than raw timings is what lets one
/// small codeset cover a brand and what keeps emission sub-100 ms (FR-2.4): the
/// pattern is pre-baked once at save time.
library;

/// Supported IR protocol families. Raw/Pronto is the escape hatch for codesets
/// that do not fit a known family (PRD §13.4).
enum IrProtocol {
  nec,
  necExtended,
  samsung,
  sonySirc12,
  sonySirc15,
  sonySirc20,
  rc5,
  raw,
}

/// A single stored IR command: protocol family + parameters.
class IrCommand {
  const IrCommand({
    required this.protocol,
    this.address = 0,
    this.command = 0,
    this.toggle = false,
    this.raw,
    this.carrierHzOverride,
  });

  final IrProtocol protocol;

  /// Device/system address (interpretation is per-protocol).
  final int address;

  /// Command / function code.
  final int command;

  /// RC5/RC6 toggle bit; flips on each distinct press.
  final bool toggle;

  /// For [IrProtocol.raw]: an explicit mark/space pattern in microseconds.
  final List<int>? raw;

  /// Optional carrier override in Hz (defaults per protocol).
  final int? carrierHzOverride;

  IrCommand withToggle(bool value) => IrCommand(
        protocol: protocol,
        address: address,
        command: command,
        toggle: value,
        raw: raw,
        carrierHzOverride: carrierHzOverride,
      );
}

/// A compiled, emittable IR signal.
class IrSignal {
  const IrSignal({
    required this.carrierHz,
    required this.pattern,
    this.repeat,
  });

  /// Carrier frequency in Hz (e.g. 38000 for NEC, 40000 for Sony, 36000 RC5).
  final int carrierHz;

  /// Alternating on/off durations in microseconds, starting with an ON (mark).
  final List<int> pattern;

  /// The frame to resend while a key is held (NEC repeat frame, or the whole
  /// frame for protocols without a dedicated repeat). Null ⇒ resend [pattern].
  final List<int>? repeat;

  /// Total on-air time of one frame, in microseconds.
  int get durationMicros => pattern.fold(0, (sum, d) => sum + d);

  /// The frame actually used for held-key repeats.
  List<int> get repeatFrame => repeat ?? pattern;
}
