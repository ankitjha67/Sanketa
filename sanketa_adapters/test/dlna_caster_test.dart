import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer mockRenderer;
  late DlnaAdapter adapter;
  final soapLog = <String>[];

  setUp(() async {
    soapLog.clear();
    mockRenderer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockRenderer.listen((req) {
      final action = req.headers.value('soapaction') ?? '';
      final actionName = action.split('#').last.replaceAll('"', '');
      soapLog.add(actionName);

      req.response
        ..statusCode = 200
        ..headers.set('Content-Type', 'text/xml')
        ..write(
            '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
            '<s:Body><u:${actionName}Response '
            'xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">'
            '</u:${actionName}Response></s:Body></s:Envelope>')
        ..close();
    });

    final base = Uri.parse('http://127.0.0.1:${mockRenderer.port}');
    adapter = DlnaAdapter(
      avTransportControlUrl: base.replace(path: '/upnp/control/AVTransport'),
      renderingControlUrl:
          base.replace(path: '/upnp/control/RenderingControl'),
    );
  });

  tearDown(() async {
    await mockRenderer.close(force: true);
  });

  test('capabilities().canCast is true', () {
    expect(adapter.capabilities().canCast, isTrue);
  });

  test('adapter implements MediaCaster', () {
    expect(adapter, isA<MediaCaster>());
  });

  test('castUri sends SetAVTransportURI then Play', () async {
    final r = await adapter.castUri(
      'http://phone:8080/tok/media',
      mimeType: 'video/mp4',
      title: 'My Video',
    );

    expect(r.ok, isTrue);
    expect(soapLog, ['SetAVTransportURI', 'Play']);
  });

  test('castUri includes DIDL-Lite metadata', () async {
    final bodies = <String>[];
    await mockRenderer.close(force: true);

    mockRenderer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockRenderer.listen((req) async {
      bodies.add(await utf8.decoder.bind(req).join());
      final action = req.headers.value('soapaction') ?? '';
      final actionName = action.split('#').last.replaceAll('"', '');
      req.response
        ..statusCode = 200
        ..write('<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
            '<s:Body><u:${actionName}Response/></s:Body></s:Envelope>')
        ..close();
    });

    final base = Uri.parse('http://127.0.0.1:${mockRenderer.port}');
    adapter = DlnaAdapter(
      avTransportControlUrl: base.replace(path: '/av'),
      renderingControlUrl: base.replace(path: '/rc'),
    );

    await adapter.castUri(
      'http://phone:9999/tok/media',
      mimeType: 'image/jpeg',
      title: 'Sunset',
    );

    final setUriBody = bodies.first;
    expect(setUriBody, contains('DIDL-Lite'));
    expect(setUriBody, contains('object.item.imageItem.photo'));
    expect(setUriBody, contains('Sunset'));
    expect(setUriBody, contains('image/jpeg'));
  });

  test('castUri for audio uses audioItem class', () async {
    final bodies = <String>[];
    await mockRenderer.close(force: true);

    mockRenderer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockRenderer.listen((req) async {
      bodies.add(await utf8.decoder.bind(req).join());
      req.response
        ..statusCode = 200
        ..write('<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">'
            '<s:Body><u:Response/></s:Body></s:Envelope>')
        ..close();
    });

    final base = Uri.parse('http://127.0.0.1:${mockRenderer.port}');
    adapter = DlnaAdapter(
      avTransportControlUrl: base.replace(path: '/av'),
      renderingControlUrl: base.replace(path: '/rc'),
    );

    await adapter.castUri(
      'http://phone:9999/tok/media',
      mimeType: 'audio/mpeg',
      title: 'Track 1',
    );

    expect(bodies.first, contains('object.item.audioItem.musicTrack'));
  });

  test('castPause sends Pause', () async {
    final r = await adapter.castPause();
    expect(r.ok, isTrue);
    expect(soapLog, ['Pause']);
  });

  test('castResume sends Play', () async {
    final r = await adapter.castResume();
    expect(r.ok, isTrue);
    expect(soapLog, ['Play']);
  });

  test('castStop sends Stop', () async {
    final r = await adapter.castStop();
    expect(r.ok, isTrue);
    expect(soapLog, ['Stop']);
  });

  test('castUri returns failure on HTTP error', () async {
    await mockRenderer.close(force: true);
    mockRenderer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockRenderer.listen((req) {
      req.response
        ..statusCode = 500
        ..close();
    });

    final base = Uri.parse('http://127.0.0.1:${mockRenderer.port}');
    adapter = DlnaAdapter(
      avTransportControlUrl: base.replace(path: '/av'),
      renderingControlUrl: base.replace(path: '/rc'),
    );

    final r = await adapter.castUri('http://example.com/video.mp4');
    expect(r.ok, isFalse);
    expect(r.error, contains('rejected'));
  });

  test('full cast lifecycle: cast → pause → resume → stop', () async {
    var r = await adapter.castUri(
      'http://phone:8080/abc/media',
      mimeType: 'video/mp4',
      title: 'Lifecycle Test',
    );
    expect(r.ok, isTrue);

    r = await adapter.castPause();
    expect(r.ok, isTrue);

    r = await adapter.castResume();
    expect(r.ok, isTrue);

    r = await adapter.castStop();
    expect(r.ok, isTrue);

    expect(soapLog, [
      'SetAVTransportURI', 'Play', // cast
      'Pause', // pause
      'Play', // resume
      'Stop', // stop
    ]);
  });
}
