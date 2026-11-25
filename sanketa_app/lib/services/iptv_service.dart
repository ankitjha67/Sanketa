import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;

/// Manages IPTV playlist fetching, parsing, caching, and favorites.
class IptvService extends ChangeNotifier {
  HttpClient _http = _freshClient();

  static HttpClient _freshClient() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 10);

  List<core.IptvChannel> _channels = [];
  List<core.IptvChannel> get channels => _channels;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  String? _currentSourceId;
  String? get currentSourceId => _currentSourceId;

  final Set<String> _favoriteUrls = {};
  Set<String> get favoriteUrls => _favoriteUrls;

  bool _disposed = false;

  IptvService() {
    unawaited(_loadFavorites());
  }

  Map<String, List<core.IptvChannel>> get groupedChannels {
    final map = <String, List<core.IptvChannel>>{};
    for (final ch in _channels) {
      final group = ch.groupTitle ?? 'Uncategorized';
      (map[group] ??= []).add(ch);
    }
    return map;
  }

  List<core.IptvChannel> get favoriteChannels =>
      _channels.where((c) => _favoriteUrls.contains(c.url)).toList();

  List<core.IptvChannel> search(String query) {
    if (query.isEmpty) return _channels;
    final q = query.toLowerCase();
    return _channels
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.groupTitle?.toLowerCase().contains(q) ?? false) ||
            (c.tvgCountry?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> loadSource(core.IptvSource source) async {
    if (_disposed) return;
    _loading = true;
    _error = null;
    _currentSourceId = source.id;
    _channels = [];
    notifyListeners();

    try {
      final cached = await _readCache(source.id);
      if (cached != null && !_disposed) {
        _channels = cached;
        _loading = false;
        notifyListeners();
        unawaited(_refreshFromNetwork(source));
        return;
      }

      await _fetchAndParse(source);
    } on Object catch (e) {
      if (!_disposed) {
        _error = _humanError(e);
        if (e is SocketException || e is HttpException) {
          _http.close(force: true);
          _http = _freshClient();
        }
        assert(() { debugPrint('[IPTV] Load error: $e'); return true; }());
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchAndParse(core.IptvSource source) async {
    final content = await _fetchUrl(source.url);
    if (_disposed || _currentSourceId != source.id) return;
    final playlist = const core.M3uParser().parse(content);
    _channels = playlist.channels;
    _error = _channels.isEmpty ? 'No channels found in this playlist.' : null;
    unawaited(_writeCache(source.id, content));
    if (!_disposed) notifyListeners();
  }

  Future<void> _refreshFromNetwork(core.IptvSource source) async {
    try {
      final content = await _fetchUrl(source.url);
      if (_disposed || _currentSourceId != source.id) return;
      final playlist = const core.M3uParser().parse(content);
      if (playlist.channels.isNotEmpty) {
        _channels = playlist.channels;
        unawaited(_writeCache(source.id, content));
        if (!_disposed) notifyListeners();
      }
    } on Object {
      // Silently use cache — background refresh failure is not user-facing.
    }
  }

  static String _humanError(Object e) {
    final msg = e.toString().toLowerCase();
    if (e is SocketException) {
      final code = e.osError?.errorCode ?? 0;
      // EAI_NONAME / host-not-found / ENETUNREACH
      if (msg.contains('no address') ||
          msg.contains('name or service not known') ||
          msg.contains('host not found') ||
          msg.contains('getaddrinfo') ||
          code == 8 ||
          code == 7) {
        return 'DNS lookup failed — your VPN or ad-blocker may be '
            'blocking network access. Try disabling it temporarily.';
      }
      if (msg.contains('connection refused')) {
        return 'Connection refused by the server. Try again later.';
      }
      if (msg.contains('network is unreachable') || code == 101) {
        return 'Network unreachable. Check your Wi-Fi or mobile data.';
      }
      if (msg.contains('timed out') || msg.contains('timeout')) {
        return 'Connection timed out. Your network may be slow, '
            'or a VPN/ad-blocker could be interfering.';
      }
    }
    if (e is HttpException) {
      return 'Server returned an error. Try again in a moment.';
    }
    if (msg.contains('timed out') || msg.contains('timeout')) {
      return 'Request timed out. Check your connection or try '
          'disabling any VPN/ad-blocker.';
    }
    return 'Could not load channels. Check your internet connection.';
  }

  Future<String> _fetchUrl(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('Only HTTP(S) URLs are allowed');
    }
    final request = await _http.getUrl(uri);
    request.headers.set('User-Agent', 'Sanketa/1.0');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final bytes = await response.fold<List<int>>(
        <int>[], (prev, chunk) => prev..addAll(chunk));
    // Limit to 50MB
    if (bytes.length > 50 * 1024 * 1024) {
      throw StateError('Playlist exceeds 50MB limit');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  void toggleFavorite(core.IptvChannel channel) {
    if (_favoriteUrls.contains(channel.url)) {
      _favoriteUrls.remove(channel.url);
    } else {
      _favoriteUrls.add(channel.url);
    }
    notifyListeners();
    unawaited(_saveFavorites());
  }

  bool isFavorite(core.IptvChannel channel) =>
      _favoriteUrls.contains(channel.url);

  Future<Directory> get _cacheDir async {
    final dir = await getApplicationSupportDirectory();
    final iptv = Directory('${dir.path}/iptv_cache');
    if (!iptv.existsSync()) iptv.createSync(recursive: true);
    return iptv;
  }

  Future<void> _writeCache(String sourceId, String content) async {
    try {
      final dir = await _cacheDir;
      final safe = sourceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await File('${dir.path}/$safe.m3u').writeAsString(content);
    } on Object {
      // Cache write failure is non-critical.
    }
  }

  Future<List<core.IptvChannel>?> _readCache(String sourceId) async {
    try {
      final dir = await _cacheDir;
      final safe = sourceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/$safe.m3u');
      if (!file.existsSync()) return null;
      final age = DateTime.now().difference(file.lastModifiedSync());
      if (age.inHours > 24) return null;
      final content = await file.readAsString();
      return const core.M3uParser().parse(content).channels;
    } on Object {
      return null;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/iptv_favorites.json');
      if (file.existsSync()) {
        final data = jsonDecode(await file.readAsString());
        if (data is List) {
          _favoriteUrls.addAll(data.cast<String>());
          if (!_disposed) notifyListeners();
        }
      }
    } on Object {
      // Favorites load failure is non-critical.
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/iptv_favorites.json');
      await file.writeAsString(jsonEncode(_favoriteUrls.toList()));
    } on Object {
      // Favorites save failure is non-critical.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _http.close(force: true);
    super.dispose();
  }
}
