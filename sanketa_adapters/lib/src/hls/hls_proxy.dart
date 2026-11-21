/// LAN-bound, token-gated HLS proxy that strips ad segments from IPTV streams.
///
/// Fetches HLS manifests from the original source, runs them through
/// [HlsFilter] from sanketa_core (SCTE-35, CUE-OUT/CUE-IN, DATERANGE,
/// OATCLS/ASSET markers), rewrites relative segment URLs to absolute, and
/// serves the cleaned manifest to the TV. Non-manifest requests (TS segments,
/// init maps) are reverse-proxied unchanged.
///
/// Security: binds to 0.0.0.0 for LAN reachability, but every request must
/// include a random token in the path (same pattern as MediaServer).
/// No DRM circumvention — only unencrypted ad-insertion markers are stripped.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sanketa_core/sanketa_core.dart' as core;

class HlsProxyServer {
  HlsProxyServer();

  HttpServer? _server;
  final _client = HttpClient();
  final _filter = const core.HlsFilter();
  String _token = '';
  String _lanIp = '';

  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;

  /// Start the proxy. Returns the base URL prefix that includes the token.
  Future<String> start(String lanIp) async {
    await stop();
    _lanIp = lanIp;
    _token = _generateToken();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleRequest);
    return _baseUrl;
  }

  String get _baseUrl => 'http://$_lanIp:${_server!.port}/$_token';

  /// Rewrite a stream URL to go through this proxy with ad filtering.
  String proxyUrl(String originalUrl) {
    return '$_baseUrl/hls?url=${Uri.encodeComponent(originalUrl)}';
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    _client.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      if (segments.isEmpty || segments.first != _token) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
        return;
      }

      final urlParam = request.uri.queryParameters['url'];
      if (urlParam == null || urlParam.isEmpty) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Missing url parameter')
          ..close();
        return;
      }

      final uri = Uri.parse(urlParam);
      final proxyReq = await _client.getUrl(uri);
      final proxyResp = await proxyReq.close();

      request.response.statusCode = proxyResp.statusCode;
      for (final header in ['content-type', 'cache-control']) {
        final value = proxyResp.headers.value(header);
        if (value != null) {
          request.response.headers.set(header, value);
        }
      }
      request.response.headers.set('Access-Control-Allow-Origin', '*');

      if (_isHlsManifest(urlParam, proxyResp)) {
        final body = await proxyResp.transform(utf8.decoder).join();
        final filtered = _filter.filterManifest(body);
        final rewritten = _rewriteUrls(filtered, uri);
        request.response.write(rewritten);
      } else {
        await proxyResp.pipe(request.response);
        return;
      }
    } on Object {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Proxy error');
    }
    await request.response.close();
  }

  bool _isHlsManifest(String url, HttpClientResponse resp) {
    final ct = resp.headers.contentType?.mimeType ?? '';
    return ct.contains('mpegurl') ||
        ct.contains('x-mpegURL') ||
        url.endsWith('.m3u8') ||
        url.contains('.m3u8?');
  }

  String _rewriteUrls(String manifest, Uri baseUri) {
    final lines = manifest.split('\n');
    final output = <String>[];
    for (final line in lines) {
      if (line.isEmpty || line.startsWith('#')) {
        if (line.startsWith('#EXT-X-MAP:URI="')) {
          output.add(_rewriteMapUri(line, baseUri));
        } else {
          output.add(line);
        }
        continue;
      }
      final resolved = baseUri.resolve(line);
      if (line.endsWith('.m3u8') || line.contains('.m3u8?')) {
        output.add(proxyUrl(resolved.toString()));
      } else {
        output.add(resolved.toString());
      }
    }
    return output.join('\n');
  }

  String _rewriteMapUri(String line, Uri baseUri) {
    final match = RegExp(r'URI="([^"]+)"').firstMatch(line);
    if (match == null) return line;
    final resolved = baseUri.resolve(match.group(1)!);
    return line.replaceFirst(match.group(1)!, resolved.toString());
  }

  static String _generateToken() {
    final rng = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
