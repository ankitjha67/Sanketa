import 'dart:io';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('MediaServer', () {
    late MediaServer server;
    late File tempFile;
    late String tempDir;

    setUp(() async {
      server = MediaServer();
      tempDir = Directory.systemTemp
          .createTempSync('sanketa_media_server_test_')
          .path;
      tempFile = File('$tempDir/test_video.mp4');
      tempFile.writeAsBytesSync(List.generate(1024, (i) => i % 256));
    });

    tearDown(() async {
      await server.stop();
      try {
        Directory(tempDir).deleteSync(recursive: true);
      } on Object {
        // cleanup
      }
    });

    test('serves file with correct MIME type', () async {
      final url = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );

      expect(url, contains('127.0.0.1'));
      expect(url, endsWith('/media'));
      expect(server.isRunning, isTrue);

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      expect(res.statusCode, HttpStatus.ok);
      expect(res.headers.contentType?.mimeType, 'video/mp4');
      expect(res.headers.value('content-length'), '1024');
      expect(res.headers.value('accept-ranges'), 'bytes');

      final body = <int>[];
      await res.listen(body.addAll).asFuture<void>();
      expect(body.length, 1024);
      client.close();
    });

    test('rejects requests with wrong token', () async {
      final url = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );

      final uri = Uri.parse(url);
      final badUrl = uri.replace(
        pathSegments: ['wrong_token', 'media'],
      );

      final client = HttpClient();
      final req = await client.getUrl(badUrl);
      final res = await req.close();
      expect(res.statusCode, HttpStatus.forbidden);
      client.close();
    });

    test('supports range requests for seeking', () async {
      final url = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('range', 'bytes=100-199');
      final res = await req.close();

      expect(res.statusCode, HttpStatus.partialContent);
      expect(res.headers.value('content-range'), 'bytes 100-199/1024');
      expect(res.headers.value('content-length'), '100');

      final body = <int>[];
      await res.listen(body.addAll).asFuture<void>();
      expect(body.length, 100);
      expect(body.first, 100 % 256);
      client.close();
    });

    test('rejects out-of-range requests', () async {
      final url = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('range', 'bytes=2000-3000');
      final res = await req.close();
      expect(res.statusCode, HttpStatus.requestedRangeNotSatisfiable);
      client.close();
    });

    test('stop shuts down the server', () async {
      await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );
      expect(server.isRunning, isTrue);
      expect(server.servingUrl, isNotNull);

      await server.stop();
      expect(server.isRunning, isFalse);
      expect(server.servingUrl, isNull);
    });

    test('serve replaces a previous session', () async {
      final url1 = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );

      final tempFile2 = File('$tempDir/test_audio.mp3');
      tempFile2.writeAsBytesSync([1, 2, 3]);

      final url2 = await server.serve(
        filePath: tempFile2.path,
        lanIp: '127.0.0.1',
      );

      expect(url2, isNot(url1));

      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url2));
      final res = await req.close();
      expect(res.statusCode, HttpStatus.ok);
      expect(res.headers.contentType?.mimeType, 'audio/mpeg');

      final body = <int>[];
      await res.listen(body.addAll).asFuture<void>();
      expect(body, [1, 2, 3]);
      client.close();
    });

    test('each serve generates a unique token', () async {
      final url1 = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );
      await server.stop();
      final url2 = await server.serve(
        filePath: tempFile.path,
        lanIp: '127.0.0.1',
      );
      expect(url1, isNot(url2));
    });
  });

  group('MediaServer.inferMime', () {
    test('maps common image extensions', () {
      expect(MediaServer.inferMime('photo.jpg'), 'image/jpeg');
      expect(MediaServer.inferMime('photo.jpeg'), 'image/jpeg');
      expect(MediaServer.inferMime('image.png'), 'image/png');
      expect(MediaServer.inferMime('anim.gif'), 'image/gif');
      expect(MediaServer.inferMime('shot.webp'), 'image/webp');
      expect(MediaServer.inferMime('snap.heic'), 'image/heic');
    });

    test('maps common video extensions', () {
      expect(MediaServer.inferMime('clip.mp4'), 'video/mp4');
      expect(MediaServer.inferMime('movie.mkv'), 'video/x-matroska');
      expect(MediaServer.inferMime('vid.avi'), 'video/x-msvideo');
      expect(MediaServer.inferMime('take.mov'), 'video/quicktime');
      expect(MediaServer.inferMime('stream.webm'), 'video/webm');
    });

    test('maps common audio extensions', () {
      expect(MediaServer.inferMime('song.mp3'), 'audio/mpeg');
      expect(MediaServer.inferMime('track.flac'), 'audio/flac');
      expect(MediaServer.inferMime('beat.wav'), 'audio/wav');
      expect(MediaServer.inferMime('tune.m4a'), 'audio/mp4');
      expect(MediaServer.inferMime('pod.ogg'), 'audio/ogg');
    });

    test('returns octet-stream for unknown extensions', () {
      expect(
          MediaServer.inferMime('file.xyz'), 'application/octet-stream');
      expect(MediaServer.inferMime('noext'), 'application/octet-stream');
    });

    test('is case-insensitive', () {
      expect(MediaServer.inferMime('photo.JPG'), 'image/jpeg');
      expect(MediaServer.inferMime('video.MP4'), 'video/mp4');
    });
  });

  group('findLanIp', () {
    test('returns a non-loopback address or null', () async {
      final ip = await findLanIp();
      if (ip != null) {
        expect(ip, isNot('127.0.0.1'));
        expect(ip.split('.').length, 4);
      }
    });
  });
}
