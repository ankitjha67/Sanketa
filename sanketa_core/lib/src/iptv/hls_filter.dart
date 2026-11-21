/// HLS manifest rewriter that strips ad segments.
///
/// Detects and removes ad breaks signalled by:
/// - SCTE-35 markers (EXT-X-SCTE35, EXT-X-CUE-OUT, EXT-X-CUE-IN)
/// - EXT-X-DATERANGE with SCTE35 attributes
/// - EXT-OATCLS / EXT-X-ASSET ad-insertion markers
///
/// The filter rewrites the manifest in a single pass, emitting only the media
/// segments that are outside ad breaks. Discontinuity tags are preserved at
/// ad-break boundaries so players don't stall.
///
/// This is applied as a proxy layer in the media server: the original manifest
/// is fetched, filtered, and served to the TV. No DRM is circumvented — only
/// injected ad-insertion markers are stripped from the transport stream map.
library;

class HlsFilter {
  const HlsFilter();

  /// Rewrite an HLS manifest to remove ad segments.
  ///
  /// Returns the filtered manifest string. If no ad markers are found, returns
  /// the original unchanged.
  String filterManifest(String manifest) {
    if (manifest.isEmpty) return manifest;

    // Master playlists (contain #EXT-X-STREAM-INF) pass through unchanged —
    // ad filtering happens on media playlists only.
    if (manifest.contains('#EXT-X-STREAM-INF')) return manifest;

    final lines = manifest.split(RegExp(r'\r?\n'));
    final output = <String>[];
    var inAdBreak = false;
    var skipNextSegment = false;
    var adBreakDetected = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // --- SCTE-35 CUE-OUT: start of ad break ---
      if (_isCueOut(trimmed)) {
        inAdBreak = true;
        adBreakDetected = true;
        output.add('#EXT-X-DISCONTINUITY');
        continue;
      }

      // --- SCTE-35 CUE-IN: end of ad break ---
      if (_isCueIn(trimmed)) {
        inAdBreak = false;
        output.add('#EXT-X-DISCONTINUITY');
        continue;
      }

      // --- EXT-X-DATERANGE with SCTE35 attributes ---
      if (_isScte35DateRange(trimmed)) {
        adBreakDetected = true;
        if (_dateRangeIsAdStart(trimmed)) {
          inAdBreak = true;
          output.add('#EXT-X-DISCONTINUITY');
          continue;
        }
        if (_dateRangeIsAdEnd(trimmed)) {
          inAdBreak = false;
          output.add('#EXT-X-DISCONTINUITY');
          continue;
        }
        // SCTE-35 daterange without clear start/end — skip it
        continue;
      }

      // --- EXT-OATCLS / EXT-X-ASSET ad markers ---
      if (trimmed.startsWith('#EXT-OATCLS:') ||
          trimmed.startsWith('#EXT-X-ASSET:')) {
        adBreakDetected = true;
        skipNextSegment = true;
        continue;
      }

      // --- EXT-X-CUE (generic) ---
      if (trimmed.startsWith('#EXT-X-CUE:')) {
        adBreakDetected = true;
        final upper = trimmed.toUpperCase();
        if (upper.contains('TYPE=OUT') || upper.contains('BREAK')) {
          inAdBreak = true;
          output.add('#EXT-X-DISCONTINUITY');
        }
        continue;
      }

      // --- Skip segments during ad break ---
      if (inAdBreak) {
        // Still emit header tags that aren't segment-related
        if (trimmed.startsWith('#EXT-X-VERSION') ||
            trimmed.startsWith('#EXT-X-TARGETDURATION') ||
            trimmed.startsWith('#EXT-X-MEDIA-SEQUENCE') ||
            trimmed.startsWith('#EXT-X-PLAYLIST-TYPE') ||
            trimmed.startsWith('#EXTM3U') ||
            trimmed.startsWith('#EXT-X-ENDLIST')) {
          output.add(line);
        }
        continue;
      }

      // --- Skip one segment after OATCLS/ASSET marker ---
      if (skipNextSegment) {
        if (trimmed.startsWith('#EXTINF:')) {
          // Skip the EXTINF and the next URL line
          if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('#')) {
            i++; // skip the URL line too
          }
          skipNextSegment = false;
          continue;
        }
        if (!trimmed.startsWith('#')) {
          // Bare URL after marker
          skipNextSegment = false;
          continue;
        }
        // Other tags between marker and segment — pass through
      }

      output.add(line);
    }

    if (!adBreakDetected) return manifest;
    return output.join('\n');
  }

  /// Check if a line signals the start of an ad break.
  bool _isCueOut(String line) {
    final upper = line.toUpperCase();
    if (upper.startsWith('#EXT-X-CUE-OUT')) return true;
    if (upper.startsWith('#EXT-X-SCTE35:') && upper.contains('CUE=OUT')) {
      return true;
    }
    return false;
  }

  /// Check if a line signals the end of an ad break.
  bool _isCueIn(String line) {
    final upper = line.toUpperCase();
    if (upper.startsWith('#EXT-X-CUE-IN')) return true;
    if (upper.startsWith('#EXT-X-SCTE35:') && upper.contains('CUE=IN')) {
      return true;
    }
    return false;
  }

  /// Check if an EXT-X-DATERANGE contains SCTE-35 attributes.
  bool _isScte35DateRange(String line) {
    if (!line.toUpperCase().startsWith('#EXT-X-DATERANGE:')) return false;
    final upper = line.toUpperCase();
    return upper.contains('SCTE35') ||
        upper.contains('PLANNED-DURATION') && upper.contains('CLASS="AD"');
  }

  /// A DATERANGE that starts an ad break.
  bool _dateRangeIsAdStart(String line) {
    final upper = line.toUpperCase();
    return upper.contains('SCTE35-OUT') ||
        (upper.contains('CLASS="AD"') && !upper.contains('END-DATE'));
  }

  /// A DATERANGE that ends an ad break.
  bool _dateRangeIsAdEnd(String line) {
    final upper = line.toUpperCase();
    return upper.contains('SCTE35-IN') ||
        upper.contains('END-ON-NEXT=YES');
  }

  /// Check if a manifest contains any ad markers.
  bool hasAdMarkers(String manifest) {
    final upper = manifest.toUpperCase();
    return upper.contains('EXT-X-CUE-OUT') ||
        upper.contains('EXT-X-CUE-IN') ||
        upper.contains('EXT-X-SCTE35') ||
        upper.contains('EXT-OATCLS') ||
        upper.contains('EXT-X-ASSET') ||
        (upper.contains('EXT-X-DATERANGE') && upper.contains('SCTE35'));
  }
}
