library;

import 'channel_catalog.dart';

class M3uParser {
  static List<IptvChannel> parse(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return const [];

    final channels = <IptvChannel>[];
    String? pendingName;
    String? pendingGroup;
    String? pendingLogo;
    String? pendingLanguage;
    String? pendingCountry;
    String? pendingTvgId;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        final attrs = _parseExtinfAttributes(line);
        pendingName = _extractDisplayName(line);
        pendingGroup = attrs['group-title'];
        pendingLogo = attrs['tvg-logo'];
        pendingLanguage = attrs['tvg-language'];
        pendingCountry = attrs['tvg-country'];
        pendingTvgId = attrs['tvg-id'];
        continue;
      }

      if (line.startsWith('#')) continue;

      if (pendingName != null && _isStreamUrl(line)) {
        channels.add(IptvChannel(
          name: pendingName,
          url: line,
          group: pendingGroup,
          logo: pendingLogo,
          language: pendingLanguage,
          country: pendingCountry,
          tvgId: pendingTvgId,
        ));
      }

      pendingName = null;
      pendingGroup = null;
      pendingLogo = null;
      pendingLanguage = null;
      pendingCountry = null;
      pendingTvgId = null;
    }

    return channels;
  }

  static Map<String, String> _parseExtinfAttributes(String line) {
    final attrs = <String, String>{};
    final regex = RegExp(r'([a-zA-Z\-]+)="([^"]*)"');
    for (final match in regex.allMatches(line)) {
      attrs[match.group(1)!.toLowerCase()] = match.group(2)!;
    }
    return attrs;
  }

  static String _extractDisplayName(String line) {
    final commaIdx = line.lastIndexOf(',');
    if (commaIdx < 0) return 'Unknown';
    final name = line.substring(commaIdx + 1).trim();
    return name.isEmpty ? 'Unknown' : name;
  }

  static bool _isStreamUrl(String line) {
    return line.startsWith('http://') ||
        line.startsWith('https://') ||
        line.startsWith('rtmp://') ||
        line.startsWith('rtsp://') ||
        line.startsWith('mms://');
  }
}
