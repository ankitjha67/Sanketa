/// HLS live-stream HTTP server for screen mirroring.
///
/// Serves an ever-updating .m3u8 playlist and the MPEG-TS segments produced by
/// the native screen-capture service. Also serves the WebSocket receiver page
/// for low-latency MSE playback. Binds to 0.0.0.0 so the TV can reach it
/// from the LAN.
library;

import 'dart:io';


import 'mirror_receiver_page.dart';

class LiveStreamServer {
  LiveStreamServer({required String segmentDir})
      : _segmentDir = Directory(segmentDir);

  final Directory _segmentDir;
  HttpServer? _server;
  int? _wsPort;

  bool get isRunning => _server != null;
  int get port => _server?.port ?? 0;

  /// Start serving. Returns the full m3u8 URL the Cast receiver should load.
  Future<String> start(String lanIp, {int? wsPort}) async {
    await stop();
    _wsPort = wsPort;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final p = _server!.port;
    _server!.listen(_handleRequest);
    return 'http://$lanIp:$p/live/stream.m3u8';
  }

  String receiverUrl(String lanIp) {
    final p = _server?.port ?? 0;
    final ws = _wsPort ?? 0;
    return 'http://$lanIp:$p/receiver?ws=$ws&host=$lanIp';
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _wsPort = null;
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      request.response.headers.set('Access-Control-Allow-Origin', '*');

      final path = request.uri.path;
      if (path == '/receiver') {
        await _serveReceiver(request);
      } else if (path == '/live/stream.m3u8') {
        await _servePlaylist(request);
      } else if (path.startsWith('/live/seg_') && path.endsWith('.ts')) {
        final fileName = path.substring('/live/'.length);
        await _serveSegment(request, fileName);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
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

  Future<void> _serveReceiver(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(mirrorReceiverHtml)
      ..close();
  }

  Future<void> _servePlaylist(HttpRequest request) async {
    final segments = _listSegments();

    if (segments.isEmpty) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8')
        ..write('#EXTM3U\n#EXT-X-VERSION:6\n#EXT-X-TARGETDURATION:1\n'
            '#EXT-X-MEDIA-SEQUENCE:0\n')
        ..close();
      return;
    }

    final window = segments.length > 6
        ? segments.sublist(segments.length - 6)
        : segments;

    final firstIndex = _segmentIndex(window.first);

    final buf = StringBuffer()
      ..writeln('#EXTM3U')
      ..writeln('#EXT-X-VERSION:6')
      ..writeln('#EXT-X-TARGETDURATION:1')
      ..writeln('#EXT-X-MEDIA-SEQUENCE:$firstIndex')
      ..writeln('#EXT-X-START:TIME-OFFSET=-2.0,PRECISE=YES');

    for (final seg in window) {
      buf
        ..writeln('#EXTINF:1.000,')
        ..writeln(seg);
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType =
          ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8')
      ..headers.set('Cache-Control', 'no-cache, no-store')
      ..write(buf.toString())
      ..close();
  }

  Future<void> _serveSegment(HttpRequest request, String fileName) async {
    final file = File('${_segmentDir.path}/$fileName');
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
        ..headers.set('Content-Type', 'video/mp2t')
        ..headers.set('Content-Length', '$length')
        ..headers.set('Accept-Ranges', 'bytes');
      await file.openRead().pipe(request.response);
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
      request.response..statusCode = HttpStatus.ok..headers.set('Accept-Ranges', 'bytes');
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

    if (start >= length || end >= length || start > end) {
      request.response
        ..statusCode = HttpStatus.requestedRangeNotSatisfiable
        ..headers.set('Content-Range', 'bytes */$length')
        ..close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.partialContent
      ..headers.set('Content-Type', 'video/mp2t')
      ..headers.set('Content-Range', 'bytes $start-$end/$length')
      ..headers.set('Content-Length', '${end - start + 1}')
      ..headers.set('Accept-Ranges', 'bytes');
    await file.openRead(start, end + 1).pipe(request.response);
  }

  /// Returns sorted segment file names present in the directory,
  /// excluding the segment currently being written.
  List<String> _listSegments() {
    if (!_segmentDir.existsSync()) return const [];

    String? inProgress;
    final latestFile = File('${_segmentDir.path}/latest.txt');
    if (latestFile.existsSync()) {
      final idx = int.tryParse(latestFile.readAsStringSync().trim());
      if (idx != null) {
        inProgress = 'seg_${idx.toString().padLeft(6, '0')}.ts';
      }
    }

    final names = <String>[];
    for (final entity in _segmentDir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('seg_') && name.endsWith('.ts')) {
        if (name != inProgress) {
          names.add(name);
        }
      }
    }
    names.sort();
    return names;
  }

  static final _indexRe = RegExp(r'seg_(\d+)\.ts$');

  static int _segmentIndex(String fileName) {
    final match = _indexRe.firstMatch(fileName);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }
}
