import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_discovery/sanketa_discovery.dart';
import 'package:test/test.dart';

void main() {
  const rokuResponse = 'HTTP/1.1 200 OK\r\n'
      'Cache-Control: max-age=3600\r\n'
      'ST: roku:ecp\r\n'
      'USN: uuid:roku:ecp:P0A070000007\r\n'
      'Server: Roku UPnP/1.0 MiniUPnPd/1.4\r\n'
      'Location: http://192.168.1.60:8060/\r\n'
      '\r\n';

  const dlnaResponse = 'HTTP/1.1 200 OK\r\n'
      'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
      'USN: uuid:9ab0c000-f668-11de-9976-00265529e5a0::urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
      'SERVER: Linux/3.14 UPnP/1.0 GUPnP/1.0\r\n'
      'LOCATION: http://192.168.1.90:8200/rootDesc.xml\r\n'
      '\r\n';

  test('parses a Roku ECP response into a classified-ready endpoint', () {
    final ep = parseSsdpResponse(rokuResponse, '192.168.1.60');
    expect(ep, isNotNull);
    expect(ep!.searchTarget, 'roku:ecp');
    expect(ep.usn, contains('uuid:roku:ecp'));
    expect(ep.server, contains('Roku'));
    expect(ep.host, '192.168.1.60');
    expect(ep.dedupeKey, 'net:192.168.1.60'); // IP-keyed for cross-method merge

    // End-to-end: the classifier recognises it as a full-remote Roku.
    final c = const EndpointClassifier().classify(ep);
    expect(c.brand, BrandFamily.roku);
    expect(c.badges, contains(CapabilityBadge.keyboard));
  });

  test('parses a generic DLNA MediaRenderer (case-insensitive headers)', () {
    final ep = parseSsdpResponse(dlnaResponse, '192.168.1.90');
    expect(ep, isNotNull);
    expect(ep!.searchTarget, contains('MediaRenderer'));
    final c = const EndpointClassifier().classify(ep);
    expect(c.brand, BrandFamily.dlna);
    expect(c.deviceType, DeviceType.mediaRenderer);
  });

  test('non-SSDP payloads return null', () {
    expect(parseSsdpResponse('garbage not a datagram', '1.2.3.4'), isNull);
    expect(parseSsdpResponse('', '1.2.3.4'), isNull);
    // A 200 with no identifying headers is not useful.
    expect(parseSsdpResponse('HTTP/1.1 200 OK\r\n\r\n', '1.2.3.4'), isNull);
  });
}
