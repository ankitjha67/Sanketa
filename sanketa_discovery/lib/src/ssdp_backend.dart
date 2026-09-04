/// SSDP / UPnP discovery backend.
///
/// Sends M-SEARCH datagrams to the SSDP multicast group and turns each response
/// into a [DiscoveredEndpoint]. Covers Roku (roku:ecp), DIAL, DLNA MediaRenderer,
/// and any UPnP device that answers `ssdp:all` (Samsung/LG/Sony/Vizio/Panasonic
/// all advertise here). Pure `dart:io`; no external dependency.
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
      yield* controller.stream;
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
