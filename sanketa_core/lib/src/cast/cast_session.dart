/// The state of an active media-casting session (FR-7.1).
///
/// Immutable snapshot — the UI rebuilds from `RemoteController.castSession`.
/// Privacy: file paths are local display names only; no path ever leaves the
/// device (PRD §14.1).
library;

enum CastPhase {
  idle,
  loading,
  playing,
  paused,
  error,
}

class CastSession {
  const CastSession({
    this.phase = CastPhase.idle,
    this.fileName,
    this.mimeType,
    this.error,
  });

  final CastPhase phase;

  /// Display name of the file being cast (basename, no full path).
  final String? fileName;
  final String? mimeType;
  final String? error;

  bool get isActive =>
      phase == CastPhase.playing ||
      phase == CastPhase.paused ||
      phase == CastPhase.loading;

  CastSession copyWith({
    CastPhase? phase,
    String? fileName,
    String? mimeType,
    String? error,
  }) =>
      CastSession(
        phase: phase ?? this.phase,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        error: error,
      );

  static const idle = CastSession();
}
