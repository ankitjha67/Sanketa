/// The casting contract — any adapter that can push media to a renderer.
///
/// Not all [ControlAdapter]s can cast (IR remotes, for example, cannot). This
/// is a separate interface so adapters opt in only when they support it.
/// The casting engine (FR-7.1) checks `adapter is MediaCaster` to decide
/// whether the Cast tab is functional for the current device.
library;

/// The outcome of a cast operation.
class CastResult {
  const CastResult._({required this.ok, this.error});
  const CastResult.success() : this._(ok: true);
  const CastResult.failure(String error) : this._(ok: false, error: error);

  final bool ok;
  final String? error;
}

/// Any adapter that can push a media URI to its target implements this.
abstract interface class MediaCaster {
  /// Send a media URL to the renderer and begin playback.
  Future<CastResult> castUri(String uri, {String? mimeType, String? title});

  /// Pause the current cast session.
  Future<CastResult> castPause();

  /// Resume a paused cast session.
  Future<CastResult> castResume();

  /// Stop the current cast and release the renderer.
  Future<CastResult> castStop();
}
