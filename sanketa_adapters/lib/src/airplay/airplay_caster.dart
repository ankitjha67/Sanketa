/// AirPlay 1 media-URL caster.
///
/// Speaks the plaintext HTTP subset of AirPlay that every AirPlay receiver
/// (Apple TV, Sony BRAVIA, Samsung, LG, Roku with AirPlay) understands for
/// media-URL playback. This is *not* screen mirroring (which needs AirPlay 2
/// pair-setup/verify) — it pushes an HTTP(S) URL to the receiver's media
/// player, identical to what iOS does with "Play on <device>" in Safari.
///
/// Default port: 7000 (mDNS `_airplay._tcp` announces the real port).
library;

import 'package:http/http.dart' as http;
import 'package:sanketa_core/sanketa_core.dart';

class AirPlayCaster implements MediaCaster {
  AirPlayCaster({
    required String host,
    int port = 7000,
    http.Client? client,
  })  : _base = Uri.http('$host:$port'),
        _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;

  @override
  Future<CastResult> castUri(
    String uri, {
    String? mimeType,
    String? title,
  }) async {
    try {
      final body = 'Content-Location: $uri\n'
          'Start-Position: 0\n';
      final resp = await _client
          .post(
            _base.replace(path: '/play'),
            headers: {
              'Content-Type': 'text/parameters',
              'User-Agent': 'Sanketa/1.0',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return const CastResult.success();
      }
      return CastResult.failure(
        'AirPlay rejected playback (HTTP ${resp.statusCode})',
      );
    } on Object catch (e) {
      return CastResult.failure('AirPlay error: $e');
    }
  }

  @override
  Future<CastResult> castPause() => _rateCommand(0);

  @override
  Future<CastResult> castResume() => _rateCommand(1);

  @override
  Future<CastResult> castStop() async {
    try {
      await _client
          .post(
            _base.replace(path: '/stop'),
            headers: {'User-Agent': 'Sanketa/1.0'},
          )
          .timeout(const Duration(seconds: 5));
      return const CastResult.success();
    } on Object catch (e) {
      return CastResult.failure('AirPlay stop error: $e');
    }
  }

  /// Query the receiver's playback-info plist for position/duration.
  Future<Map<String, String>?> playbackInfo() async {
    try {
      final resp = await _client
          .get(
            _base.replace(path: '/playback-info'),
            headers: {'User-Agent': 'Sanketa/1.0'},
          )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      return _parsePlist(resp.body);
    } on Object {
      return null;
    }
  }

  /// Quick connectivity check — GET /server-info should return 200.
  Future<bool> isReachable() async {
    try {
      final resp = await _client
          .get(
            _base.replace(path: '/server-info'),
            headers: {'User-Agent': 'Sanketa/1.0'},
          )
          .timeout(const Duration(seconds: 4));
      return resp.statusCode == 200;
    } on Object {
      return false;
    }
  }

  Future<CastResult> _rateCommand(num value) async {
    try {
      await _client
          .post(
            _base.replace(
              path: '/rate',
              queryParameters: {'value': value.toStringAsFixed(6)},
            ),
            headers: {'User-Agent': 'Sanketa/1.0'},
          )
          .timeout(const Duration(seconds: 5));
      return const CastResult.success();
    } on Object catch (e) {
      return CastResult.failure('AirPlay rate error: $e');
    }
  }

  /// Minimal plist-to-map parser (key/real and key/string pairs).
  static Map<String, String> _parsePlist(String xml) {
    final map = <String, String>{};
    final keyRe = RegExp(r'<key>([^<]+)</key>\s*<(real|string|integer)>([^<]+)<');
    for (final m in keyRe.allMatches(xml)) {
      map[m.group(1)!] = m.group(3)!;
    }
    return map;
  }
}
