/// DIAL (DIscovery And Launch) client — Rung 2 app launching (FR-6).
///
/// DIAL is the standard behind "YouTube/Netflix on the TV" launch buttons. It is
/// not a full remote — just launch / stop / status of named apps via REST — so
/// it is a helper the app and casting layer use, not a ControlAdapter. The apps
/// base URL comes from the device's `Application-URL` header (discovery layer).
library;

import 'dart:async';

import 'package:http/http.dart' as http;

class DialResult {
  const DialResult({required this.ok, this.instanceUrl, this.error});
  final bool ok;

  /// The launched app instance URL (from the Location header), used to stop it.
  final String? instanceUrl;
  final String? error;
}

/// Normalise a user-facing app name ("NETFLIX", "prime", "Disney+") to the
/// registered DIAL app name the TV expects.
String dialAppName(String displayName) {
  switch (displayName.toLowerCase()) {
    case 'netflix':
      return 'Netflix';
    case 'youtube':
      return 'YouTube';
    case 'prime':
    case 'prime video':
    case 'amazon prime video':
      return 'AmazonInstantVideo';
    case 'disney+':
    case 'disneyplus':
      return 'DisneyPlus';
    case 'hulu':
      return 'Hulu';
    case 'spotify':
      return 'Spotify';
    default:
      return displayName;
  }
}

/// Map user-facing app names to deep-link URIs for ATVRS/ATV app launch.
///
/// ATVRS field 90 (appLinkLaunch) sends a URI that the TV resolves via
/// Android's verified-links / app-link mechanism. Web-style URLs work best
/// because installed apps register the matching domains. Intent URIs
/// (`intent:#Intent;…;end`) are not reliably handled by all ATVRS
/// implementations.
String? appDeepLink(String displayName) {
  switch (displayName.toLowerCase()) {
    case 'netflix':
      return 'https://www.netflix.com/title';
    case 'youtube':
      return 'https://www.youtube.com';
    case 'prime':
    case 'prime video':
    case 'amazon prime video':
      return 'https://app.primevideo.com';
    case 'disney+':
    case 'disneyplus':
      return 'https://www.disneyplus.com';
    case 'hulu':
      return 'https://www.hulu.com';
    case 'spotify':
      return 'https://open.spotify.com';
    case 'plex':
      return 'https://app.plex.tv';
    default:
      return null;
  }
}

class DialClient {
  DialClient({required Uri appsBaseUrl, http.Client? client})
      : _base = appsBaseUrl,
        _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;
  static const _timeout = Duration(seconds: 5);

  Uri _app(String appName) {
    final basePath = _base.path.endsWith('/') ? _base.path : '${_base.path}/';
    return _base.replace(path: '$basePath$appName');
  }

  /// Launch [appName] (e.g. "YouTube", "Netflix"), optionally with a launch
  /// payload (YouTube uses `v=<videoId>` to deep-link).
  Future<DialResult> launch(String appName, {String body = ''}) async {
    try {
      final res = await _client.post(
        _app(appName),
        headers: {'Content-Type': 'text/plain; charset=utf-8'},
        body: body,
      ).timeout(_timeout);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return DialResult(ok: true, instanceUrl: res.headers['location']);
      }
      return DialResult(ok: false, error: 'http ${res.statusCode}');
    } on TimeoutException {
      return const DialResult(
          ok: false, error: 'TV did not respond to DIAL launch');
    } on Object catch (e) {
      return DialResult(ok: false, error: '$e');
    }
  }

  /// Stop a running app instance (its `instanceUrl` from [launch], or by name).
  Future<DialResult> stop(String appName, {String? instanceUrl}) async {
    try {
      final url = instanceUrl != null ? Uri.parse(instanceUrl) : _app(appName);
      final res = await _client.delete(url).timeout(_timeout);
      return (res.statusCode >= 200 && res.statusCode < 300)
          ? const DialResult(ok: true)
          : DialResult(ok: false, error: 'http ${res.statusCode}');
    } on Object catch (e) {
      return DialResult(ok: false, error: '$e');
    }
  }

  /// Whether [appName] is installed/running (2xx from its GET).
  Future<bool> isAvailable(String appName) async {
    try {
      final res = await _client.get(_app(appName)).timeout(_timeout);
      return res.statusCode >= 200 && res.statusCode < 300;
    } on Object {
      return false;
    }
  }
}
