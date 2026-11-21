import 'dart:convert';
import 'dart:io';

import 'package:sanketa_adapters/src/dlna/dlna_adapter.dart';
import 'package:sanketa_core/sanketa_core.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<({String action, String body})> soap;
  late DlnaAdapter adapter;

  setUp(() async {
    soap = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      final action = req.headers.value('soapaction') ?? '';
      soap.add((action: action, body: body));
      // Answer the RenderingControl queries the adapter reads back.
      if (action.contains('GetVolume')) {
        req.response.write('<CurrentVolume>20</CurrentVolume>');
      } else if (action.contains('GetMute')) {
        req.response.write('<CurrentMute>0</CurrentMute>');
      }
      await req.response.close();
    });
    final base = 'http://127.0.0.1:${server.port}';
    adapter = DlnaAdapter(
      avTransportControlUrl: Uri.parse('$base/AVTransport/control'),
      renderingControlUrl: Uri.parse('$base/RenderingControl/control'),
    );
  });

  tearDown(() => server.close(force: true));

  test('capabilities: media transport + volume, NO d-pad, NO text (FR-3.5)',
      () {
    final caps = adapter.capabilities();
    expect(caps.textMode, TextInjectionMode.none);
    expect(caps.supports(Key.play), isTrue);
    expect(caps.supports(Key.volumeUp), isTrue);
    expect(caps.supports(Key.up), isFalse); // no d-pad on a renderer
    expect(caps.volumeReadback, isTrue);
  });

  test('play sends AVTransport Play', () async {
    await adapter.sendKey(Key.play);
    expect(soap.single.action, contains('AVTransport:1#Play'));
    expect(soap.single.body, contains('<Speed>1</Speed>'));
  });

  test('stop sends AVTransport Stop', () async {
    await adapter.sendKey(Key.stop);
    expect(soap.single.action, contains('#Stop'));
  });

  test('volumeUp reads volume then sets it +step', () async {
    await adapter.sendKey(Key.volumeUp); // step 5, current 20 -> 25
    expect(soap[0].action, contains('GetVolume'));
    expect(soap[1].action, contains('SetVolume'));
    expect(soap[1].body, contains('<DesiredVolume>25</DesiredVolume>'));
  });

  test('mute reads then flips mute state', () async {
    await adapter.sendKey(Key.mute); // current 0 -> 1
    expect(soap[0].action, contains('GetMute'));
    expect(soap[1].body, contains('<DesiredMute>1</DesiredMute>'));
  });

  test('playUri sets the URI then plays', () async {
    await adapter.playUri('http://phone/video.mp4');
    expect(soap[0].action, contains('SetAVTransportURI'));
    expect(soap[0].body, contains('http://phone/video.mp4'));
    expect(soap[1].action, contains('#Play'));
  });

  test('text and d-pad are refused', () async {
    expect((await adapter.sendText(const TextOp.insert('x'))).ok, isFalse);
    expect((await adapter.sendKey(Key.up)).ok, isFalse);
  });
}
