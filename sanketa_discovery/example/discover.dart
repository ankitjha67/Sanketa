// Scan your real LAN and print every controllable device found, from any brand.
//   dart run sanketa_discovery/example/discover.dart
// ignore_for_file: avoid_print
import 'package:sanketa_core/sanketa_core.dart';
import 'package:sanketa_discovery/sanketa_discovery.dart';

Future<void> main() async {
  final engine = DiscoveryEngine(
    backends: [SsdpBackend(), MdnsBackend()],
  );

  print('Scanning LAN (SSDP + mDNS) for ~6s ...\n');
  final result = await engine.scan();

  if (result.devices.isEmpty) {
    print(result.apIsolationSuspected
        ? 'No devices found, but the gateway is reachable — this looks like '
            'AP/client isolation (common on hotel/guest WiFi, or a router '
            'setting). Devices cannot see each other on this network.'
        : 'No devices found. (${result.backendsFailed}/${result.backendsRun} '
            'backends errored.)');
    return;
  }

  print('Found ${result.devices.length} device(s):\n');
  for (final d in result.devices) {
    final badges = d.badges.map((b) => b.name).join(', ');
    final via = d.sources.map((s) => s.name).join('+');
    print('  ${d.device.brand.name.padRight(11)} '
        '${(d.device.host ?? '?').padRight(16)} '
        'via $via  [$badges]  adapter=${d.adapterId ?? '—'}');
  }
}
