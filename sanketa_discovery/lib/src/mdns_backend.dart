/// mDNS / Bonjour discovery backend.
///
/// Resolves the service types the network adapters advertise interest in —
/// Android TV remote (`_androidtvremote2._tcp`), Google Cast (`_googlecast._tcp`),
/// and AirPlay (`_airplay._tcp`) — into addressable endpoints. These are the
/// devices SSDP misses, so mDNS is required for real cross-brand coverage.
///
/// NOTE: exercised against a real LAN (needs multicast on 224.0.0.251:5353); the
/// parsing/mapping is analyzer-checked here, live round-trips are validated via
/// `example/discover.dart`. Uses the Dart-team `multicast_dns` package.
library;

import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:sanketa_core/sanketa_core.dart';

/// Binds the mDNS socket with a fallback for platforms that reject `reusePort`
/// (Windows, some Android builds). On Android and Windows, `reusePort` is
/// skipped upfront to avoid noisy runtime stderr messages in logcat / debug
/// console. On other platforms, tries with `reusePort` first; on failure
/// retries without it.
Future<RawDatagramSocket> _crossPlatformBind(
  dynamic host,
  int port, {
  bool reuseAddress = true,
  bool reusePort = true,
  int ttl = 255,
}) async {
  final useReusePort = reusePort && !Platform.isAndroid && !Platform.isWindows;
  try {
    return await RawDatagramSocket.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: useReusePort,
      ttl: ttl,
    );
  } on SocketException {
    return RawDatagramSocket.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: false,
      ttl: ttl,
    );
  }
}

class MdnsBackend implements DiscoveryBackend {
  MdnsBackend({List<String>? serviceTypes, MDnsClient? client})
      : serviceTypes = serviceTypes ?? _defaultServices,
        _client =
            client ?? MDnsClient(rawDatagramSocketFactory: _crossPlatformBind);

  static const List<String> _defaultServices = [
    '_androidtvremote2._tcp',
    '_googlecast._tcp',
    '_airplay._tcp',
  ];

  final List<String> serviceTypes;
  final MDnsClient _client;

  @override
  DiscoverySource get source => DiscoverySource.mdns;

  @override
  Stream<DiscoveredEndpoint> search(Duration timeout) async* {
    final stopwatch = Stopwatch()..start();
    try {
      await _client.start();
    } on Object {
      // multicast_dns cannot join the mDNS group on Windows desktop
      // (WSAENOPROTOOPT / errno 10042). This is a dev-host limitation only —
      // the join succeeds on Android/iOS, the real targets — so degrade to no
      // mDNS results here rather than surfacing a spurious backend failure.
      // On any other platform a start() failure is real: let it propagate.
      if (Platform.isWindows) return;
      rethrow;
    }
    try {
      for (final rawType in serviceTypes) {
        var remaining = timeout - stopwatch.elapsed;
        if (remaining <= Duration.zero) return;
        final type = rawType.endsWith('.local') ? rawType : '$rawType.local';
        final ptrStream = _client
            .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(type))
            .timeout(remaining, onTimeout: (sink) => sink.close());

        await for (final ptr in ptrStream) {
          remaining = timeout - stopwatch.elapsed;
          if (remaining <= Duration.zero) return;
          final serviceStream = _client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
              )
              .timeout(remaining, onTimeout: (sink) => sink.close());
          await for (final srv in serviceStream) {
            String? ip;
            remaining = timeout - stopwatch.elapsed;
            if (remaining <= Duration.zero) return;
            final addressStream = _client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target),
                )
                .timeout(remaining, onTimeout: (sink) => sink.close());
            await for (final addr in addressStream) {
              ip = addr.address.address;
              break;
            }
            yield DiscoveredEndpoint(
              source: DiscoverySource.mdns,
              host: ip ?? srv.target,
              port: srv.port,
              usn: ptr.domainName,
              searchTarget: rawType,
              friendlyName: _instanceName(ptr.domainName),
            );
          }
        }
      }
    } finally {
      _client.stop();
    }
  }

  String _instanceName(String domainName) {
    final dot = domainName.indexOf('.');
    return dot > 0 ? domainName.substring(0, dot) : domainName;
  }
}
