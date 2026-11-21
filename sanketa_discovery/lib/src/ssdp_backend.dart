/// SSDP / UPnP discovery backend.
///
/// Sends M-SEARCH datagrams to the SSDP multicast group and turns each response
/// into a [DiscoveredEndpoint]. Covers Roku (roku:ecp), DIAL, DLNA MediaRenderer,
/// and any UPnP device that answers `ssdp:all` (Samsung/LG/Sony/Vizio/Panasonic
/// all advertise here). Pure `dart:io`; no external dependency.
///
/// When a response carries a LOCATION URL, the backend fetches the UPnP device
/// description XML to extract `<friendlyName>` and `<modelName>` so the UI shows
/// human-readable device names instead of raw IP addresses.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sanketa_core/sanketa_core.dart';

class SsdpBackend implements DiscoveryBackend {
  SsdpBackend({List<String>? searchTargets})
      : searchTargets = searchTargets ?? _defaultTargets;

  /// Broad by design: `ssdp:all` surfaces everything, and the specific targets
  /// nudge devices that only answer their own ST.
  static const List<String> _defaultTargets = [
    'ssdp:all',
    'roku:ecp',
    'urn:dial-multiscreen-org:service:dial:1',
    'urn:schemas-upnp-org:device:MediaRenderer:1',
  ];

  final List<String> searchTargets;

  static const String _group = '239.255.255.250';
  static const int _ssdpPort = 1900;

  @override
  DiscoverySource get source => DiscoverySource.ssdp;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) async* {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.multicastHops = 4;

    final controller = StreamController<DiscoveredEndpoint>();
    final seen = <String>{};
    final _upnpCache = <String, _UpnpInfo?>{};

    final sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final text = utf8.decode(datagram.data, allowMalformed: true);
      final endpoint = parseSsdpResponse(text, datagram.address.address);
      if (endpoint == null) return;
      final key = '${endpoint.dedupeKey}|${endpoint.searchTarget ?? ''}';
      if (seen.add(key) && !controller.isClosed) {
        controller.add(endpoint);
      }
    });

    final target = InternetAddress.tryParse(_group)!;
    for (final st in searchTargets) {
      socket.send(utf8.encode(_mSearch(st)), target, _ssdpPort);
    }

    final timer = Timer(timeout, () {
      if (!controller.isClosed) controller.close();
    });

    try {
      await for (final e in controller.stream) {
        if (e.friendlyName != null || e.location == null) {
          yield e;
          continue;
        }
        // Fetch UPnP description once per host for the friendly name.
        if (!_upnpCache.containsKey(e.host)) {
          _upnpCache[e.host] = await _fetchUpnpInfo(e.location!);
        }
        final info = _upnpCache[e.host];
        if (info != null) {
          yield DiscoveredEndpoint(
            source: e.source,
            host: e.host,
            port: e.port,
            usn: e.usn,
            searchTarget: e.searchTarget,
            location: e.location,
            server: e.server,
            friendlyName: info.friendlyName,
            attributes: {
              ...e.attributes,
              if (info.modelName != null) 'model': info.modelName!,
              if (info.manufacturer != null) 'manufacturer': info.manufacturer!,
              if (info.applicationUrl != null)
                'application-url': info.applicationUrl!,
            },
          );
        } else {
          yield e;
        }
      }
    } finally {
      timer.cancel();
      await sub.cancel();
      socket.close();
    }
  }

  String _mSearch(String st) => 'M-SEARCH * HTTP/1.1\r\n'
      'HOST: $_group:$_ssdpPort\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 2\r\n'
      'ST: $st\r\n'
      '\r\n';
}

/// Parse an SSDP response (or NOTIFY) into a [DiscoveredEndpoint]. Pure and
/// side-effect free so it can be unit-tested without a socket. Returns null for
/// anything that is not an SSDP message.
DiscoveredEndpoint? parseSsdpResponse(String raw, String host) {
  final lines = const LineSplitter().convert(raw);
  if (lines.isEmpty) return null;
  final first = lines.first.toUpperCase();
  final isResponse = first.startsWith('HTTP/1.1') || first.startsWith('HTTP/1.0');
  final isNotify = first.startsWith('NOTIFY');
  if (!isResponse && !isNotify) return null;

  final headers = <String, String>{};
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim().toLowerCase();
    final value = line.substring(idx + 1).trim();
    if (key.isNotEmpty) headers[key] = value;
  }

  // A bare 200 with no identifying header is not useful.
  if (headers['usn'] == null &&
      headers['st'] == null &&
      headers['nt'] == null &&
      headers['location'] == null) {
    return null;
  }

  return DiscoveredEndpoint(
    source: DiscoverySource.ssdp,
    host: host,
    usn: headers['usn'],
    searchTarget: headers['st'] ?? headers['nt'],
    location: headers['location'],
    server: headers['server'],
    attributes: headers,
  );
}

class _UpnpInfo {
  _UpnpInfo({
    this.friendlyName,
    this.modelName,
    this.manufacturer,
    this.applicationUrl,
  });
  final String? friendlyName;
  final String? modelName;
  final String? manufacturer;
  final String? applicationUrl;
}

Future<_UpnpInfo?> _fetchUpnpInfo(String locationUrl) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 2);
  try {
    final req = await client.getUrl(Uri.parse(locationUrl));
    final resp = await req.close().timeout(const Duration(seconds: 2));
    if (resp.statusCode != 200) return null;
    final appUrl = resp.headers.value('Application-URL');
    final body = await resp.transform(utf8.decoder).join();
    final name = _xmlField(body, 'friendlyName');
    final model = _xmlField(body, 'modelName');
    final mfr = _xmlField(body, 'manufacturer');
    if (name == null && model == null && appUrl == null) return null;
    return _UpnpInfo(
      friendlyName: name,
      modelName: model,
      manufacturer: mfr,
      applicationUrl: appUrl,
    );
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

String? _xmlField(String xml, String tag) {
  final open = '<$tag>';
  final close = '</$tag>';
  final start = xml.indexOf(open);
  if (start < 0) return null;
  final valStart = start + open.length;
  final end = xml.indexOf(close, valStart);
  if (end < 0) return null;
  final value = xml.substring(valStart, end).trim();
  return value.isEmpty ? null : value;
}
