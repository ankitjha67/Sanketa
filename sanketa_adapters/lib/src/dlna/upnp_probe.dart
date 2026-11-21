/// Probes a device's UPnP description to extract DLNA AVTransport and
/// RenderingControl URLs, enabling casting to any MediaRenderer.
///
/// The SSDP discovery layer captures the `location` URL pointing to the
/// device description XML, but does not parse it. This probe does the
/// fetch-and-parse step so the adapter factory can instantiate a
/// [DlnaAdapter] with the correct control URLs.
library;

import 'package:http/http.dart' as http;

class UpnpServiceUrls {
  const UpnpServiceUrls({
    required this.avTransportControlUrl,
    required this.renderingControlUrl,
  });

  final Uri avTransportControlUrl;
  final Uri renderingControlUrl;
}

class UpnpProbe {
  UpnpProbe({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetch and parse a UPnP device description to extract DLNA control URLs.
  ///
  /// [locationUrl] is the SSDP LOCATION header value pointing at the
  /// device description XML.
  Future<UpnpServiceUrls?> probe(String locationUrl) async {
    try {
      final location = Uri.parse(locationUrl);
      final res = await _client
          .get(location)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      return _parseDescription(res.body, location);
    } on Object {
      return null;
    }
  }

  /// Probe a host by trying common UPnP description endpoints. Useful when
  /// the SSDP location was not captured (e.g. manual-add-by-IP).
  Future<UpnpServiceUrls?> probeHost(String host) async {
    for (final path in _commonPaths) {
      final url = 'http://$host$path';
      final result = await probe(url);
      if (result != null) return result;
    }
    return null;
  }

  UpnpServiceUrls? _parseDescription(String xml, Uri base) {
    Uri? avUrl;
    Uri? rcUrl;

    final services = _extractServices(xml);
    for (final svc in services) {
      final type = _tagValue(svc, 'serviceType');
      final controlUrl = _tagValue(svc, 'controlURL');
      if (type == null || controlUrl == null) continue;

      if (type.contains('AVTransport')) {
        avUrl = base.resolve(controlUrl);
      } else if (type.contains('RenderingControl')) {
        rcUrl = base.resolve(controlUrl);
      }
    }

    if (avUrl == null || rcUrl == null) return null;
    return UpnpServiceUrls(
      avTransportControlUrl: avUrl,
      renderingControlUrl: rcUrl,
    );
  }

  List<String> _extractServices(String xml) {
    final result = <String>[];
    final re = RegExp(r'<service>(.*?)</service>', dotAll: true);
    for (final m in re.allMatches(xml)) {
      result.add(m.group(1)!);
    }
    return result;
  }

  String? _tagValue(String xml, String tag) {
    final re = RegExp('<$tag>(.*?)</$tag>');
    return re.firstMatch(xml)?.group(1)?.trim();
  }

  static const _commonPaths = [
    ':52323/dmr.xml',
    ':8008/ssdp/device-desc.xml',
    ':49152/description.xml',
    ':1900/description.xml',
    ':8443/dmr.xml',
    ':60606/upnp/desc/aios_device/aios_device.xml',
  ];
}
