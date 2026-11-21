/// M3U/M3U8 playlist parser with security validation.
///
/// Accepts only http/https stream URLs, sanitises channel names against XSS,
/// and enforces a configurable size limit to prevent OOM from hostile playlists.
library;

import 'iptv_models.dart';

class M3uParser {
  const M3uParser({
    this.maxChannels = 50000,
    this.maxLineLength = 4096,
    this.allowNsfw = false,
  });

  final int maxChannels;
  final int maxLineLength;
  final bool allowNsfw;

  /// Parse a complete M3U string into an [IptvPlaylist].
  IptvPlaylist parse(String content) {
    if (content.isEmpty) return IptvPlaylist.empty;

    final lines = content.split(RegExp(r'\r?\n'));
    return _parseLines(lines);
  }

  /// Parse from an iterable of lines (for streaming large playlists).
  IptvPlaylist parseLines(Iterable<String> lines) => _parseLines(lines);

  IptvPlaylist _parseLines(Iterable<String> lines) {
    final channels = <IptvChannel>[];
    String? headerTvgUrl;
    String? currentExtinf;
    String? currentVlcUserAgent;
    String? currentVlcReferrer;

    for (final rawLine in lines) {
      if (channels.length >= maxChannels) break;

      final line = rawLine.length > maxLineLength
          ? rawLine.substring(0, maxLineLength)
          : rawLine;
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Header line: #EXTM3U
      if (trimmed.startsWith('#EXTM3U')) {
        headerTvgUrl = _extractQuoted(trimmed, 'url-tvg') ??
            _extractQuoted(trimmed, 'x-tvg-url');
        continue;
      }

      // Channel info line: #EXTINF
      if (trimmed.startsWith('#EXTINF:')) {
        currentExtinf = trimmed;
        continue;
      }

      // VLC options
      if (trimmed.startsWith('#EXTVLCOPT:')) {
        final value = trimmed.substring('#EXTVLCOPT:'.length).trim();
        if (value.startsWith('http-user-agent=')) {
          currentVlcUserAgent = value.substring('http-user-agent='.length);
        } else if (value.startsWith('http-referrer=')) {
          currentVlcReferrer = value.substring('http-referrer='.length);
        }
        continue;
      }

      // Skip other directives
      if (trimmed.startsWith('#')) continue;

      // This is a URL line — validate and create channel
      if (!_isValidStreamUrl(trimmed)) {
        currentExtinf = null;
        currentVlcUserAgent = null;
        currentVlcReferrer = null;
        continue;
      }

      final channel = _buildChannel(
        url: trimmed,
        extinf: currentExtinf,
        userAgent: currentVlcUserAgent,
        referrer: currentVlcReferrer,
      );

      if (channel != null && (allowNsfw || !channel.isNsfw)) {
        channels.add(channel);
      }

      currentExtinf = null;
      currentVlcUserAgent = null;
      currentVlcReferrer = null;
    }

    return IptvPlaylist(
      channels: channels,
      tvgUrl: headerTvgUrl,
    );
  }

  /// Only http:// and https:// are accepted — no file://, rtsp://, udp://, etc.
  bool _isValidStreamUrl(String url) {
    final lower = url.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    // Reject URLs with embedded credentials (user:pass@host)
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.userInfo.isNotEmpty) return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  IptvChannel? _buildChannel({
    required String url,
    String? extinf,
    String? userAgent,
    String? referrer,
  }) {
    if (extinf == null) {
      // Bare URL with no #EXTINF — use host as name
      final uri = Uri.tryParse(url);
      final name = uri?.host ?? 'Unknown';
      return IptvChannel(name: _sanitize(name), url: url);
    }

    // Parse #EXTINF:-1 tvg-id="..." tvg-name="..." ... group-title="...",Channel Name
    final attrs = _parseExtinfAttributes(extinf);
    final name = _extractChannelName(extinf);
    if (name.isEmpty) return null;

    final isNsfw = (attrs['group-title'] ?? '').toLowerCase().contains('xxx') ||
        (attrs['group-title'] ?? '').toLowerCase().contains('adult') ||
        (attrs['tvg-name'] ?? '').toLowerCase().contains('xxx');

    return IptvChannel(
      name: _sanitize(name),
      url: url,
      groupTitle: attrs['group-title'],
      tvgId: attrs['tvg-id'],
      tvgName: attrs['tvg-name'],
      tvgLogo: _validateLogoUrl(attrs['tvg-logo']),
      tvgCountry: attrs['tvg-country'],
      tvgLanguage: attrs['tvg-language'],
      tvgUrl: attrs['tvg-url'],
      catchup: attrs['catchup'],
      catchupSource: attrs['catchup-source'],
      userAgent: userAgent,
      referrer: referrer,
      isNsfw: isNsfw,
    );
  }

  /// Extract the channel name after the last comma in #EXTINF line.
  String _extractChannelName(String extinf) {
    // #EXTINF:-1 ...attributes...,Channel Name
    final commaIdx = extinf.indexOf(',');
    if (commaIdx < 0 || commaIdx >= extinf.length - 1) return '';
    return extinf.substring(commaIdx + 1).trim();
  }

  /// Parse key="value" pairs from #EXTINF attributes.
  Map<String, String> _parseExtinfAttributes(String extinf) {
    final attrs = <String, String>{};
    // Match key="value" patterns
    final re = RegExp(r'([\w-]+)="([^"]*)"');
    for (final match in re.allMatches(extinf)) {
      attrs[match.group(1)!.toLowerCase()] = match.group(2)!;
    }
    return attrs;
  }

  /// Extract a quoted attribute value from a directive line.
  String? _extractQuoted(String line, String key) {
    final pattern = RegExp('$key="([^"]*)"', caseSensitive: false);
    return pattern.firstMatch(line)?.group(1);
  }

  /// Strip HTML tags and trim to prevent XSS if names are rendered in webview.
  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[<>&"\x00-\x1F]'), '')
        .trim();
  }

  /// Logo URLs must be http/https only.
  String? _validateLogoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return url;
    }
    return null;
  }
}
