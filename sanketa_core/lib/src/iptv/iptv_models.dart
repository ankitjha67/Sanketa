/// IPTV data models — channels, playlists, categories, and catalog sources.
///
/// All models are immutable value objects with no external dependencies.
/// Channel URLs are validated at parse time (see [M3uParser]) — only http/https
/// schemes are accepted.
library;

/// A single IPTV channel parsed from an M3U playlist.
class IptvChannel {
  const IptvChannel({
    required this.name,
    required this.url,
    this.groupTitle,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.tvgCountry,
    this.tvgLanguage,
    this.tvgUrl,
    this.catchup,
    this.catchupSource,
    this.userAgent,
    this.referrer,
    this.isNsfw = false,
  });

  final String name;

  /// Stream URL — guaranteed http:// or https:// by the parser.
  final String url;

  final String? groupTitle;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? tvgCountry;
  final String? tvgLanguage;
  final String? tvgUrl;
  final String? catchup;
  final String? catchupSource;

  /// Custom user-agent for this stream (from #EXTVLCOPT:http-user-agent).
  final String? userAgent;

  /// Custom referrer for this stream (from #EXTVLCOPT:http-referrer).
  final String? referrer;

  final bool isNsfw;

  @override
  String toString() => 'IptvChannel($name, $url)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IptvChannel && other.url == url && other.name == name;

  @override
  int get hashCode => Object.hash(name, url);
}

/// A parsed M3U playlist containing channels.
class IptvPlaylist {
  const IptvPlaylist({
    required this.channels,
    this.name,
    this.tvgUrl,
  });

  final List<IptvChannel> channels;
  final String? name;

  /// EPG guide URL from the `#EXTM3U` header (`url-tvg` or `x-tvg-url`).
  final String? tvgUrl;

  /// Group channels by their `groupTitle` into categories.
  List<IptvCategory> get categories {
    final map = <String, List<IptvChannel>>{};
    for (final ch in channels) {
      final group = ch.groupTitle ?? 'Uncategorized';
      (map[group] ??= []).add(ch);
    }
    return [
      for (final entry in map.entries)
        IptvCategory(name: entry.key, channels: entry.value),
    ];
  }

  /// Search channels by name (case-insensitive substring).
  List<IptvChannel> search(String query) {
    if (query.isEmpty) return channels;
    final q = query.toLowerCase();
    return channels.where((ch) => ch.name.toLowerCase().contains(q)).toList();
  }

  static const empty = IptvPlaylist(channels: []);
}

/// A category/group of channels.
class IptvCategory {
  const IptvCategory({required this.name, required this.channels});
  final String name;
  final List<IptvChannel> channels;

  @override
  String toString() => 'IptvCategory($name, ${channels.length} channels)';
}

/// A predefined playlist source (e.g. from iptv-org).
class IptvSource {
  const IptvSource({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    this.type = IptvSourceType.category,
  });

  final String id;
  final String name;
  final String url;
  final String? description;
  final IptvSourceType type;

  @override
  String toString() => 'IptvSource($id, $name)';
}

/// How a predefined source is organized.
enum IptvSourceType { category, country, language, region }
