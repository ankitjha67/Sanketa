library;

class IptvChannel {
  const IptvChannel({
    required this.name,
    required this.url,
    this.group,
    this.logo,
    this.language,
    this.country,
    this.tvgId,
  });

  final String name;
  final String url;
  final String? group;
  final String? logo;
  final String? language;
  final String? country;
  final String? tvgId;
}

enum ChannelSortOrder { name, group, country, language }

class ChannelCatalog {
  ChannelCatalog(List<IptvChannel> channels) : _channels = List.of(channels);

  final List<IptvChannel> _channels;

  int get length => _channels.length;

  List<IptvChannel> get all => List.unmodifiable(_channels);

  void addAll(List<IptvChannel> channels) {
    _channels.addAll(channels);
  }

  List<String> get groups {
    final g = <String>{};
    for (final c in _channels) {
      if (c.group != null && c.group!.isNotEmpty) g.add(c.group!);
    }
    final sorted = g.toList()..sort();
    return sorted;
  }

  List<String> get countries {
    final c = <String>{};
    for (final ch in _channels) {
      if (ch.country != null && ch.country!.isNotEmpty) c.add(ch.country!);
    }
    final sorted = c.toList()..sort();
    return sorted;
  }

  List<String> get languages {
    final l = <String>{};
    for (final ch in _channels) {
      if (ch.language != null && ch.language!.isNotEmpty) l.add(ch.language!);
    }
    final sorted = l.toList()..sort();
    return sorted;
  }

  List<IptvChannel> search(String query) {
    if (query.isEmpty) return all;
    final lower = query.toLowerCase();
    return _channels.where((c) {
      return c.name.toLowerCase().contains(lower) ||
          (c.group?.toLowerCase().contains(lower) ?? false) ||
          (c.country?.toLowerCase().contains(lower) ?? false) ||
          (c.language?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  List<IptvChannel> byGroup(String group) {
    return _channels.where((c) => c.group == group).toList();
  }

  List<IptvChannel> byCountry(String country) {
    return _channels.where((c) => c.country == country).toList();
  }

  List<IptvChannel> byLanguage(String language) {
    return _channels.where((c) => c.language == language).toList();
  }

  List<IptvChannel> sorted(ChannelSortOrder order) {
    final copy = List.of(_channels);
    switch (order) {
      case ChannelSortOrder.name:
        copy.sort((a, b) => a.name.compareTo(b.name));
      case ChannelSortOrder.group:
        copy.sort(
            (a, b) => (a.group ?? '').compareTo(b.group ?? ''));
      case ChannelSortOrder.country:
        copy.sort(
            (a, b) => (a.country ?? '').compareTo(b.country ?? ''));
      case ChannelSortOrder.language:
        copy.sort(
            (a, b) => (a.language ?? '').compareTo(b.language ?? ''));
    }
    return copy;
  }
}
