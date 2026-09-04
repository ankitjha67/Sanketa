// A tiny runnable demo against a real Roku on your LAN.
//   dart run sanketa_adapters/example/roku_ping.dart <roku-ip> [port]
// It pairs (confirms ECP reachability) and presses Home, printing latency.
// ignore_for_file: avoid_print
import 'package:sanketa_adapters/sanketa_adapters.dart';
import 'package:sanketa_core/sanketa_core.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('usage: dart run example/roku_ping.dart <roku-ip> [port]');
    return;
  }
  final host = args[0];
  final port = args.length > 1 ? int.parse(args[1]) : 8060;

  final roku = RokuAdapter(host: host, port: port);
  final paired = await roku.pair(const PairingContext());
  print('pair: ${paired.status}'
      '${paired.error != null ? ' (${paired.error})' : ''}');

  if (paired.isPaired) {
    final res = await roku.sendKey(Key.home);
    print('Home -> ok=${res.ok} latency=${res.latency?.inMilliseconds}ms');

    final caps = roku.capabilities();
    print('text mode: ${caps.textMode.name}; keys: ${caps.keys.length}');
  }
  roku.close();
}
