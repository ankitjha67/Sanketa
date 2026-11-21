import 'dart:io';

import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('UpnpProbe.probe', () {
    late HttpServer mockServer;
    late String baseUrl;

    setUp(() async {
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://127.0.0.1:${mockServer.port}';
    });

    tearDown(() async {
      await mockServer.close(force: true);
    });

    test('parses a standard DLNA device description', () async {
      mockServer.listen((req) {
        req.response
          ..statusCode = 200
          ..headers.set('Content-Type', 'text/xml')
          ..write(_sonyBraviaDescription)
          ..close();
      });

      final probe = UpnpProbe();
      final urls = await probe.probe('$baseUrl/dmr.xml');

      expect(urls, isNotNull);
      expect(urls!.avTransportControlUrl.path,
          '/upnp/control/AVTransport');
      expect(urls.renderingControlUrl.path,
          '/upnp/control/RenderingControl');
      expect(urls.avTransportControlUrl.host, '127.0.0.1');
    });

    test('parses Samsung-style description with nested paths', () async {
      mockServer.listen((req) {
        req.response
          ..statusCode = 200
          ..headers.set('Content-Type', 'text/xml')
          ..write(_samsungDescription)
          ..close();
      });

      final probe = UpnpProbe();
      final urls = await probe.probe('$baseUrl/description.xml');

      expect(urls, isNotNull);
      expect(urls!.avTransportControlUrl.path,
          '/upnp/control/AVTransport1');
      expect(urls.renderingControlUrl.path,
          '/upnp/control/RenderingControl1');
    });

    test('returns null when no AVTransport service is found', () async {
      mockServer.listen((req) {
        req.response
          ..statusCode = 200
          ..headers.set('Content-Type', 'text/xml')
          ..write(_noAvTransportDescription)
          ..close();
      });

      final probe = UpnpProbe();
      final urls = await probe.probe('$baseUrl/dmr.xml');
      expect(urls, isNull);
    });

    test('returns null on HTTP error', () async {
      mockServer.listen((req) {
        req.response
          ..statusCode = 404
          ..close();
      });

      final probe = UpnpProbe();
      final urls = await probe.probe('$baseUrl/dmr.xml');
      expect(urls, isNull);
    });

    test('returns null on connection failure', () async {
      await mockServer.close(force: true);
      final probe = UpnpProbe();
      final urls = await probe.probe('http://127.0.0.1:1/dmr.xml');
      expect(urls, isNull);
    });

    test('resolves relative control URLs against the location base', () async {
      mockServer.listen((req) {
        req.response
          ..statusCode = 200
          ..headers.set('Content-Type', 'text/xml')
          ..write(_relativeUrlDescription)
          ..close();
      });

      final probe = UpnpProbe();
      final urls = await probe.probe('$baseUrl/device/dmr.xml');

      expect(urls, isNotNull);
      expect(urls!.avTransportControlUrl.toString(),
          startsWith('http://127.0.0.1:'));
      expect(urls.avTransportControlUrl.path, '/control/AVTransport');
    });
  });
}

const _sonyBraviaDescription = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>BRAVIA 2 II</friendlyName>
    <manufacturer>Sony Corporation</manufacturer>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
        <controlURL>/upnp/control/AVTransport</controlURL>
        <eventSubURL>/upnp/event/AVTransport</eventSubURL>
        <SCPDURL>/AVTransportSCPD.xml</SCPDURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
        <controlURL>/upnp/control/RenderingControl</controlURL>
        <eventSubURL>/upnp/event/RenderingControl</eventSubURL>
        <SCPDURL>/RenderingControlSCPD.xml</SCPDURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>
        <controlURL>/upnp/control/ConnectionManager</controlURL>
      </service>
    </serviceList>
  </device>
</root>
''';

const _samsungDescription = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>[TV] Samsung 55"</friendlyName>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/upnp/control/AVTransport1</controlURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <controlURL>/upnp/control/RenderingControl1</controlURL>
      </service>
    </serviceList>
  </device>
</root>
''';

const _noAvTransportDescription = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
        <controlURL>/upnp/control/ConnectionManager</controlURL>
      </service>
    </serviceList>
  </device>
</root>
''';

const _relativeUrlDescription = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/control/AVTransport</controlURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <controlURL>/control/RenderingControl</controlURL>
      </service>
    </serviceList>
  </device>
</root>
''';
