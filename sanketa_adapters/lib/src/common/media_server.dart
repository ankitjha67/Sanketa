/// Ephemeral, LAN-bound, token-gated HTTP server for local media casting
/// (PRD NFR-10: "media server LAN-bound, tokened, ephemeral").
///
/// Serves exactly one local file at a time. The URL contains a random token so
/// other LAN devices cannot enumerate or access media without it. Range requests
/// are supported for video/audio seeking.
library;

import 'dart:io';
import 'dart:math';

class MediaServer {
  HttpServer? _server;
  String? _token;
  String? _filePath;
  String? _mimeType;
  String? _servingUrl;

  bool get isRunning => _server != null;
  String? get servingUrl => _servingUrl;

  /// Start serving [filePath] on an ephemeral port. Binds to 0.0.0.0 so the
  /// renderer can reach it from anywhere on the LAN.
  ///
  /// Returns the full URL the renderer should fetch (includes the token).
  Future<String> serve({
    required String filePath,
    required String lanIp,
    String? mimeType,
  }) async {
    await stop();
    _filePath = filePath;
    _mimeType = mimeType ?? inferMime(filePath);
    _token = _generateToken();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _server!.port;
    _servingUrl = 'http://$lanIp:$port/$_token/media';

    _server!.listen(_handleRequest);
    return _servingUrl!;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.uri.pathSegments.length < 2 ||
          request.uri.pathSegments[0] != _token) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
        return;
      }

      final file = File(_filePath!);
      if (!file.existsSync()) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      final length = file.lengthSync();
      final range = request.headers.value('range');

      if (range != null && range.startsWith('bytes=')) {
        await _serveRange(request, file, length, range);
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.set('Content-Type', _mimeType ?? 'application/octet-stream')
          ..headers.set('Content-Length', '$length')
          ..headers.set('Accept-Ranges', 'bytes')
          ..headers.set('Access-Control-Allow-Origin', '*');
        await file.openRead().pipe(request.response);
      }
    } on Object {
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      } on Object {
        // Response may already be committed.
      }
    }
  }

  Future<void> _serveRange(
    HttpRequest request,
    File file,
    int length,
    String range,
  ) async {
    final spec = range.substring(6).split(',').first.trim();
    final parts = spec.split('-');
    final int start;
    final int end;
    if (parts.length != 2) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set('Content-Type', _mimeType ?? 'application/octet-stream')
        ..headers.set('Content-Length', '$length')
        ..headers.set('Accept-Ranges', 'bytes')
        ..headers.set('Access-Control-Allow-Origin', '*');
      await file.openRead().pipe(request.response);
      return;
    }
    final first = int.tryParse(parts[0]);
    final last = int.tryParse(parts[1]);
    if (first == null && last != null) {
      start = (length - last).clamp(0, length);
      end = length - 1;
    } else {
      start = first ?? 0;
      end = (last ?? (length - 1)).clamp(0, length - 1);
    }

    if (start >= length || start > end) {
      request.response
        ..statusCode = HttpStatus.requestedRangeNotSatisfiable
        ..headers.set('Content-Range', 'bytes */$length')
        ..close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.partialContent
      ..headers.set('Content-Type', _mimeType ?? 'application/octet-stream')
      ..headers.set('Content-Range', 'bytes $start-$end/$length')
      ..headers.set('Content-Length', '${end - start + 1}')
      ..headers.set('Accept-Ranges', 'bytes')
      ..headers.set('Access-Control-Allow-Origin', '*');
    await file.openRead(start, end + 1).pipe(request.response);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _servingUrl = null;
    _filePath = null;
    _token = null;
    _mimeType = null;
    await server?.close(force: true);
  }

  static String _generateToken() {
    final r = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String inferMime(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'application/octet-stream';
    final ext = path.substring(dot + 1).toLowerCase();
    return _mimeTypes[ext] ?? 'application/octet-stream';
  }

  static const _mimeTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'mkv': 'video/x-matroska',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'ts': 'video/mp2t',
    '3gp': 'video/3gpp',
    'mp3': 'audio/mpeg',
    'aac': 'audio/aac',
    'flac': 'audio/flac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    'wma': 'audio/x-ms-wma',
    'opus': 'audio/opus',
  };
}

/// Returns the IPv4 LAN address best suited to reach [targetHost].
///
/// When [targetHost] is given, the interface whose address shares the same
/// /24 subnet is preferred (covers the vast majority of home networks). If
/// no subnet match is found, VPN/tunnel interfaces are filtered out so the
/// media-server URL uses the WiFi address the TV can actually reach.
Future<String?> findLanIp({String? targetHost}) async {
  final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

  // Collect all non-loopback IPv4 addresses with their interface name.
  final candidates = <({String ip, String iface})>[];
  for (final iface in ifaces) {
    for (final addr in iface.addresses) {
      if (!addr.isLoopback) {
        candidates.add((ip: addr.address, iface: iface.name.toLowerCase()));
      }
    }
  }
  if (candidates.isEmpty) return null;

  // Prefer the address on the same /24 subnet as the target.
  if (targetHost != null) {
    final targetPrefix = _subnetPrefix(targetHost);
    if (targetPrefix != null) {
      for (final c in candidates) {
        if (_subnetPrefix(c.ip) == targetPrefix) return c.ip;
      }
    }
  }

  // Filter out common VPN/tunnel interfaces.
  final nonVpn = candidates.where((c) =>
      !c.iface.startsWith('tun') &&
      !c.iface.startsWith('ppp') &&
      !c.iface.startsWith('tap') &&
      !c.iface.startsWith('utun') &&
      !c.iface.startsWith('wg') &&
      !c.iface.startsWith('ipsec') &&
      !c.iface.contains('vpn'));
  if (nonVpn.isNotEmpty) return nonVpn.first.ip;

  return candidates.first.ip;
}

/// Returns the first three octets of an IPv4 address ("192.168.29").
String? _subnetPrefix(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}
